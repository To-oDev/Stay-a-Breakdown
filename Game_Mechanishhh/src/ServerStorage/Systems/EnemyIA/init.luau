local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GoodSignal = require(script:FindFirstChild("GoodSignal"))
local Maid = require(script:FindFirstChild("Maid"))

local random = Random.new()

local module = {}
module.__index = module

-- ======================
--  CONFIG DEFAULT
-- ======================
local DEFAULT_SETTINGS = {
	DESTROY_ON_DEATH = true,
	DEATH_DESTROY_DELAY = 0, -- ya no se usa, pero lo dejo por si luego quieres reactivar delays
	MAX_PARTS_PER_HEARTBEAT = 30,
	SEARCH_DELAY = 1,

	ATTACK_RADIUS = 20,
	ATTACK_RANGE = 3,
	COMBO_DELAY = 0.65,
	COMBO_RANDOM_OFFSET = 0.25,

	ATTACK_MIN_WALKSPEED = 8,
	ATTACK_MAX_WALKSPEED = 8,

	-- Rango de vista y FOV
	VIEW_RADIUS = 40,
	VIEW_FOV = 120,

	-- Comportamiento con poca vida (huir)
	LOW_HEALTH_ENABLED = true,
	LOW_HEALTH_THRESHOLD = 0.25,
	LOW_HEALTH_RETREAT_DISTANCE = 10,
	LOW_HEALTH_WALKSPEED_MULTIPLIER = 1.25,

	-- Persecución
	TARGET_LOSS_GRACE_TIME = 1.5,
	MAX_CHASE_DISTANCE = 80,

	-- Enrage
	ENRAGE_ON_LOW_HEALTH_ENABLED = false,
	ENRAGE_THRESHOLD = 0.15,
	ENRAGE_WALKSPEED_MULTIPLIER = 1.5,
	ENRAGE_ATTACK_SPEED_MULTIPLIER = 0.7,

	-- Tag de facción / tipo de NPC
	FACTION_TAG = "Enemy",
}

local function mergeSettings(customSettings: {}?)
	local settings = table.clone(DEFAULT_SETTINGS)

	if customSettings then
		for k, v in pairs(customSettings) do
			settings[k] = v
		end
	end

	return settings
end

-- ======================
--  LISTA GLOBAL DE NPCs
-- ======================
local ActiveNPCs = {}
local ActiveNPCCount = 0

local function registerNPC(self)
	ActiveNPCCount += 1
	ActiveNPCs[ActiveNPCCount] = self
	self._activeIndex = ActiveNPCCount
end

local function unregisterNPC(self)
	local index = self._activeIndex
	if not index then return end

	local last = ActiveNPCs[ActiveNPCCount]
	ActiveNPCs[index] = last
	ActiveNPCs[ActiveNPCCount] = nil
	ActiveNPCCount -= 1

	if last then
		last._activeIndex = index
	end

	self._activeIndex = nil
end

-- Un solo Heartbeat global
RunService.Heartbeat:Connect(function(dt)
	for i = 1, ActiveNPCCount do
		local npc = ActiveNPCs[i]
		if npc and not npc._destroyed then
			npc:onHeartbeat(dt)
		end
	end
end)

-- Constructor
function module.new(npcModel: Model, customSettings: {}?)
	assert(npcModel and npcModel:FindFirstChild("HumanoidRootPart"), "NPC model must have a HumanoidRootPart")

	local Character = npcModel
	local Head = Character:FindFirstChild("Head")
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	assert(Humanoid, "NPC model must have a Humanoid")
	assert(Head, "NPC model must have a Head")

	local AlignOrientation = HumanoidRootPart:FindFirstChildOfClass("AlignOrientation")
	if not AlignOrientation then
		AlignOrientation = Instance.new("AlignOrientation")
		AlignOrientation.Parent = HumanoidRootPart
	end

	local self = setmetatable({}, module)

	self.Settings = mergeSettings(customSettings)

	self.maid = Maid.new()
	self.maid.instance = Character

	self.maid.humanoid = Humanoid
	self.maid.head = Head
	self.maid.humanoidRootPart = HumanoidRootPart
	self.maid.alignOrientation = AlignOrientation

	-- Attachment en mundo para AlignOrientation
	local worldAttachment = Instance.new("Attachment")
	worldAttachment.Name = "SoldierWorldAttachment"
	worldAttachment.Parent = Workspace.Terrain

	self.maid.worldAttachment = worldAttachment
	AlignOrientation.Attachment1 = worldAttachment

	self.humanoid = Humanoid
	self.root = HumanoidRootPart
	self.character = Character

	-- Tag de facción / tipo de NPC
	self._factionTag = self.Settings.FACTION_TAG
	if self._factionTag then
		CollectionService:AddTag(Character, self._factionTag)
	end

	-- Cache de settings para performance
	self._viewRadius = self.Settings.VIEW_RADIUS or self.Settings.ATTACK_RADIUS
	self._viewRadiusSq = self._viewRadius * self._viewRadius

	local fov = self.Settings.VIEW_FOV or 360
	self._useFOV = fov < 360
	if self._useFOV then
		self._minDotFOV = math.cos(math.rad((fov * 0.5)))
	end

	self._attackRangePlusOne = (self.Settings.ATTACK_RANGE or 3) + 1
	self._maxChaseDistance = self.Settings.MAX_CHASE_DISTANCE or 0

	-- Overlap params para búsqueda de targets
	self._overlapParams = OverlapParams.new()
	self._overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	self._overlapParams.FilterDescendantsInstances = { Character }

	-- Raycast reutilizable
	self._raycastParams = RaycastParams.new()
	self._raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self._raycastIgnore = { self.character, nil }

	-- Estado de búsqueda
	self.target = nil
	self.newTarget = nil
	self.newTargetDistance = nil
	self.searchIndex = 0
	self.timeSearchEnded = 0
	self.searchRegion = nil
	self.searchParts = nil
	self.searchingForTargets = false

	-- Estado de combate
	self.lastAttackTime = 0
	self.attacking = false
	self.movingToAttack = false

	-- Flags
	self._destroyed = false
	self._lastSeenTargetTime = 0
	self._enraged = false

	-- ======================
	--  EVENTOS PRINCIPALES
	-- ======================
	self.attackEvent = GoodSignal.new()
	self.deathEvent = GoodSignal.new()

	-- ======================
	--  EVENTOS EXTRA
	-- ======================
	self.targetChanged = GoodSignal.new()
	self.targetLost = GoodSignal.new()
	self.enterAttackRange = GoodSignal.new()
	self.exitAttackRange = GoodSignal.new()
	self.startedMovingToTarget = GoodSignal.new()
	self.stoppedMovingToTarget = GoodSignal.new()
	self.healthChanged = GoodSignal.new()
	self.tookDamage = GoodSignal.new()

	self.enragedChanged = GoodSignal.new()

	-- Estados anteriores para detectar cambios
	self._lastTarget = nil
	self._lastInAttackRange = false
	self._lastMovingToAttack = false
	self._lastHealth = Humanoid.Health

	self:_initialize()
	registerNPC(self)

	return self
end

function module:isAlive()
	return self.humanoid.Health > 0 and self.humanoid:GetState() ~= Enum.HumanoidStateType.Dead
end

function module:isLowHealth()
	local ratio = self.humanoid.Health / self.humanoid.MaxHealth
	return ratio <= (self.Settings.LOW_HEALTH_THRESHOLD or 0.25)
end

function module:isEnraged()
	return self._enraged == true
end

-- Checa si un Instance puede ser atacado (incluye rango de vista + FOV + gracia de visión)
function module:isInstanceAttackable(targetInstance: Instance, isCurrentTarget: boolean?)
	if not targetInstance then return false end
	local targetParent = targetInstance.Parent
	if not targetParent then return false end

	local targetHumanoid = targetParent:FindFirstChildOfClass("Humanoid")
	local targetRoot = targetParent:FindFirstChild("HumanoidRootPart")
	if not targetHumanoid or not targetRoot then
		return false
	end

	local selfRoot = self.root
	local selfPos = selfRoot.Position
	local targetPos = targetInstance.Position
	local offset = targetPos - selfPos

	local distSq = offset.X * offset.X + offset.Y * offset.Y + offset.Z * offset.Z
	if distSq <= 0 then
		return false
	end

	-- Rango de vista
	if distSq > self._viewRadiusSq then
		return false
	end

	-- FOV
	if self._useFOV then
		local forward = selfRoot.CFrame.LookVector
		local dirToTarget = offset.Unit
		local dot = forward:Dot(dirToTarget)

		if dot < self._minDotFOV then
			return false
		end
	end

	if targetParent == self.character then
		return false
	end

	if not targetParent:IsDescendantOf(Workspace) then
		return false
	end

	if targetHumanoid.Health <= 0 or targetHumanoid:GetState() == Enum.HumanoidStateType.Dead then
		return false
	end

	-- Ignorar humanoides con el mismo tag de facción
	if self._factionTag and CollectionService:HasTag(targetParent, self._factionTag) then
		return false
	end

	-- Tag genérico "Ignore"
	if CollectionService:HasTag(targetParent, "Ignore") then
		return false
	end

	-- Raycast para línea de visión
	local rayDirection = (targetRoot.Position - selfPos)
	self._raycastIgnore[2] = targetParent
	self._raycastParams.FilterDescendantsInstances = self._raycastIgnore

	local result = Workspace:Raycast(selfPos, rayDirection, self._raycastParams)

	if result then
		local grace = self.Settings.TARGET_LOSS_GRACE_TIME or 0
		if isCurrentTarget and grace > 0 then
			if tick() - (self._lastSeenTargetTime or 0) <= grace then
				return true
			end
		end
		return false
	else
		if isCurrentTarget then
			self._lastSeenTargetTime = tick()
		end
	end

	return true
end

-- Alias con typo antiguo
module.isInstaceAttackable = module.isInstanceAttackable

function module:findTargets()
	if not self:isAlive() then
		self.target = nil
		return
	end

	local Settings = self.Settings
	local viewRadius = self._viewRadius

	if not self.searchingForTargets and (tick() - self.timeSearchEnded) >= Settings.SEARCH_DELAY then
		self.searchingForTargets = true

		local centerPosition = self.root.Position
		local size = Vector3.new(viewRadius, viewRadius, viewRadius) * 2
		local boxCFrame = CFrame.new(centerPosition)

		self.searchRegion = boxCFrame
		self.searchParts = Workspace:GetPartBoundsInBox(boxCFrame, size, self._overlapParams) or {}

		self.newTarget = nil
		self.newTargetDistance = nil
		self.searchIndex = 1
	end

	if self.searchingForTargets and self.searchParts then
		local checkedParts = 0
		local partsCount = #self.searchParts

		while self.searchIndex <= partsCount and checkedParts < Settings.MAX_PARTS_PER_HEARTBEAT do
			local currentPart = self.searchParts[self.searchIndex]
			if currentPart and self:isInstanceAttackable(currentPart) then
				local character = currentPart.Parent
				local targetRoot = character:FindFirstChild("HumanoidRootPart")
				if targetRoot then
					local distance = (targetRoot.Position - self.root.Position).Magnitude
					if not self.newTargetDistance or distance < self.newTargetDistance then
						self.newTarget = targetRoot
						self.newTargetDistance = distance
					end
				end
			end

			self.searchIndex += 1
			checkedParts += 1
		end

		if self.searchIndex > partsCount then
			local oldTarget = self.target
			self.target = self.newTarget
			self.searchingForTargets = false
			self.timeSearchEnded = tick()

			if oldTarget ~= self.target then
				self.targetChanged:Fire(self.target, oldTarget)
				if oldTarget and not self.target then
					self.targetLost:Fire(oldTarget)
				end
			end

			self._lastTarget = self.target
		end
	end
end

function module:runToTarget()
	local target = self.target
	if not target then return end

	local root = self.root
	local rootPos = root.Position
	local targetPos = target.Position
	local direction = (rootPos - targetPos)

	if direction.Magnitude < 0.001 then
		return
	end

	local targetPosition = targetPos + direction.Unit * (self.Settings.ATTACK_RANGE or 3)
	self.humanoid:MoveTo(targetPosition)

	if not self.movingToAttack then
		local wsMin = self.Settings.ATTACK_MIN_WALKSPEED or self.humanoid.WalkSpeed
		local wsMax = self.Settings.ATTACK_MAX_WALKSPEED or wsMin
		local speed = random:NextInteger(wsMin, wsMax)

		if self._enraged then
			speed = speed * (self.Settings.ENRAGE_WALKSPEED_MULTIPLIER or 1)
		end

		self.humanoid.WalkSpeed = speed
		self.movingToAttack = true

		if not self._lastMovingToAttack then
			self.startedMovingToTarget:Fire()
		end
		self._lastMovingToAttack = true
	end
end

-- Huida cuando tiene poca vida
function module:retreatFromTarget()
	local target = self.target
	if not target then return end

	local root = self.root
	local rootPos = root.Position
	local targetPos = target.Position
	local direction = (rootPos - targetPos)

	if direction.Magnitude < 0.001 then
		direction = root.CFrame.LookVector
	end

	local retreatDistance = self.Settings.LOW_HEALTH_RETREAT_DISTANCE or 10
	local retreatPosition = rootPos + direction.Unit * retreatDistance

	self.humanoid:MoveTo(retreatPosition)

	local multiplier = self.Settings.LOW_HEALTH_WALKSPEED_MULTIPLIER or 1
	self.humanoid.WalkSpeed = (self.Settings.ATTACK_MAX_WALKSPEED or 8) * multiplier
end

-- Forzar ataque manual
function module:ForceAttack()
	if self.target and not self.attacking then
		self:attack()
	end
end

function module:GetTarget()
	return self.target
end

function module:SetTarget(targetRoot: BasePart?)
	self.target = targetRoot
end

-- Enrage
function module:_updateEnrageState()
	local enabled = self.Settings.ENRAGE_ON_LOW_HEALTH_ENABLED
	if not enabled then
		if self._enraged then
			self._enraged = false
			self.enragedChanged:Fire(false)
		end
		return
	end

	local ratio = self.humanoid.Health / self.humanoid.MaxHealth
	local threshold = self.Settings.ENRAGE_THRESHOLD or 0.15
	local shouldEnrage = ratio <= threshold and self:isAlive()

	if shouldEnrage ~= self._enraged then
		self._enraged = shouldEnrage
		self.enragedChanged:Fire(self._enraged)
	end
end

function module:attack()
	self.lastAttackTime = tick()
	self.attackEvent:Fire()
end

function module:onHeartbeat(dt: number)
	if self._destroyed then return end
	if not self:isAlive() then return end

	self:_updateEnrageState()

	local target = self.target
	local root = self.root
	local humanoid = self.humanoid
	local Settings = self.Settings

	-- Orientar hacia el target
	if target then
		self.maid.alignOrientation.Enabled = true
		self.maid.worldAttachment.CFrame = CFrame.new(root.Position, target.Position)
	else
		self.maid.alignOrientation.Enabled = false
	end

	local inAttackRange = false

	if target then
		local distance = (target.Position - root.Position).Magnitude

		if self._maxChaseDistance > 0 and distance > self._maxChaseDistance then
			local oldTarget = target
			self.target = nil
			self.targetLost:Fire(oldTarget)
			self._lastTarget = nil
			return
		end

		-- Huida por poca vida (si no se usa enrage en low health)
		if Settings.LOW_HEALTH_ENABLED and not Settings.ENRAGE_ON_LOW_HEALTH_ENABLED then
			local healthRatio = humanoid.Health / humanoid.MaxHealth
			if Settings.LOW_HEALTH_THRESHOLD and healthRatio <= Settings.LOW_HEALTH_THRESHOLD then
				self:retreatFromTarget()
				return
			end
		end

		inAttackRange = distance <= self._attackRangePlusOne

		-- Entrar / salir de rango de ataque
		if inAttackRange ~= self._lastInAttackRange then
			if inAttackRange then
				self.enterAttackRange:Fire(target)
			else
				self.exitAttackRange:Fire(target)
			end
			self._lastInAttackRange = inAttackRange
		end

		if inAttackRange then
			if self.movingToAttack then
				self.movingToAttack = false
				if self._lastMovingToAttack then
					self.stoppedMovingToTarget:Fire()
				end
				self._lastMovingToAttack = false
			end

			local baseDelay = Settings.COMBO_DELAY or 0.65
			local offset = Settings.COMBO_RANDOM_OFFSET or 0
			local factor = baseDelay

			if offset > 0 then
				factor = baseDelay + random:NextNumber(-offset, offset)
				if factor < 0 then
					factor = 0
				end
			end

			if self._enraged then
				factor = factor * (Settings.ENRAGE_ATTACK_SPEED_MULTIPLIER or 0.7)
			end

			if not self.attacking and (tick() - self.lastAttackTime) > factor then
				self.character:SetAttribute("LastPunch", tick())
				self:attack()
			end
		else
			self:runToTarget()
		end
	else
		if self.movingToAttack or self._lastMovingToAttack then
			self.movingToAttack = false
			if self._lastMovingToAttack then
				self.stoppedMovingToTarget:Fire()
			end
			self._lastMovingToAttack = false
		end

		if self._lastInAttackRange then
			self._lastInAttackRange = false
		end
	end

	-- Validar que el target siga siendo atacable
	if self.target and not self:isInstanceAttackable(self.target, true) then
		local oldTarget = self.target
		self.target = nil
		self.targetLost:Fire(oldTarget)
		self._lastTarget = nil
	end

	if not self.target then
		self:findTargets()
	end
end

function module:died()
	if self._destroyed then return end

	self.deathEvent:Fire()
	
	-- Limpiar estado interno
	self.target = nil
	self.attacking = false
	self.newTarget = nil
	self.searchParts = nil
	self.searchingForTargets = false

	-- Destrucción inmediata de todo el NPC
	if self.Settings.DESTROY_ON_DEATH then
		task.wait(self.Settings.DEATH_DESTROY_DELAY or 0)
		self:destroy()
	end
end

function module:_initialize()
	self.maid.diedConnection = self.humanoid.Died:Connect(function()
		self:died()
	end)
end

function module:destroy()
	if self._destroyed then return end
	self._destroyed = true

	unregisterNPC(self)

	-- Limpia conexiones/instancias que maneja Maid (incluye el attachment en Terrain)
	self.maid:destroy()

	-- Asegurar que el modelo del NPC desaparece del workspace
	--if self.character and self.character.Parent then
		--self.character:Destroy()
	--end

	self.attackEvent:DisconnectAll()
	self.deathEvent:DisconnectAll()

	self.targetChanged:DisconnectAll()
	self.targetLost:DisconnectAll()
	self.enterAttackRange:DisconnectAll()
	self.exitAttackRange:DisconnectAll()
	self.startedMovingToTarget:DisconnectAll()
	self.stoppedMovingToTarget:DisconnectAll()
	self.healthChanged:DisconnectAll()
	self.tookDamage:DisconnectAll()

	self.enragedChanged:DisconnectAll()
end

return module