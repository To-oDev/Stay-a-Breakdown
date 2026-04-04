local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

local Systems = ServerStorage:WaitForChild("Systems")
local NPC = require(Systems:WaitForChild("EnemyIA"))

local SystemAssets = ReplicatedStorage:WaitForChild("SystemAssets")
local EnemysModelStorage = SystemAssets:WaitForChild("EnemysStorage"):WaitForChild("Models")

local RemoteEvent = ReplicatedStorage:WaitForChild("SystemEvents"):WaitForChild("FXEvent")
local ActivateTool = ReplicatedStorage:WaitForChild("SystemEvents"):FindFirstChild("ActivateTool")
local CombatManager = require(Systems:FindFirstChild("CombatSystem"))

local module = {}

-- Enemigos activos por zona
-- SpawnedEnemys[SpawnZone][SpawnPart] = EnemyModel
local SpawnedEnemys = {}

local DEFAULT_SETTINGS = {
	RAGDOLL_ENABLED = true,
	DESTROY_ON_DEATH = true,
	DEATH_DESTROY_DELAY = 5,
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

-- Utilidad: crea una parte temporal para efectos en un CFrame dado
local function createEffectPartFromCFrame(cframe, size)
	local tempPart = Instance.new("Part")
	tempPart.Size = size
	tempPart.CFrame = cframe
	tempPart.Anchored = true
	tempPart.CanCollide = false
	tempPart.Transparency = 1
	tempPart.Name = "EffectPart"
	tempPart.Parent = workspace
	
	print(size, cframe, tempPart)
	return tempPart
end

-- Spawnea un enemigo a partir de los datos de configuración
-- ModelNames: { "Bandit", "Pirate", ... }
-- level: número de nivel (no índice)
-- idTag: string para tag único de spawnPart
-- spawnZoneTag: string con el nombre de la zona
-- positionPart: la parte donde se va a spawnear
function module.SpawnEnemy(ModelNames, level, idTag, spawnZoneTag, _config, positionPart)
	if not ModelNames or #ModelNames == 0 then
		warn("[SpawnEnemy] ModelNames está vacío o es nil")
		return
	end

	if not positionPart or not positionPart.Position then
		warn("[SpawnEnemy] positionPart inválido")
		return
	end

	local randomIndex = math.random(1, #ModelNames)
	local modelName = ModelNames[randomIndex]
	local modelTemplate = EnemysModelStorage:FindFirstChild(modelName)

	if not modelTemplate then
		warn("[SpawnEnemy] No se encontró el modelo '", modelName, "' en EnemysModelStorage")
		return
	end

	local enemy = modelTemplate:Clone()
	local hrp = enemy:FindFirstChild("HumanoidRootPart")
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")

	if not hrp or not humanoid then
		warn("[SpawnEnemy] El modelo no tiene HumanoidRootPart o Humanoid:", modelName)
		enemy:Destroy()
		return
	end

	enemy.Parent = workspace:WaitForChild("SpawnedEnemysFolder")
	hrp.CFrame = CFrame.new(positionPart.Position + Vector3.new(0, 3, 0))

	enemy:SetAttribute("ID", HttpService:GenerateGUID(false))
	enemy:SetAttribute("Level", level)

	-- Tags para manejar grupos y despawns
	if spawnZoneTag then
		CollectionService:AddTag(enemy, spawnZoneTag)
	end

	if idTag then
		CollectionService:AddTag(enemy, idTag)
	end

	return enemy
end

-- Empieza a trackear un SpawnPart dentro de una zona
function module.TrackSpawnPart(SpawnPart, SpawnZone)
	if not SpawnPart or not SpawnZone then
		return
	end

	local parent = SpawnPart.Parent
	local grandParent = parent and parent.Parent

	local configScript =
		SpawnPart:FindFirstChild("Configuration")
		or (grandParent and grandParent:FindFirstChild("GeneralConfiguration"))

	if not configScript or SpawnPart:GetAttribute("Canceled") then
		return
	end

	local Config = require(configScript)

	-- SpawnTimes solo afecta cuando el módulo está dentro de la Part
	if Config.SpawnTimes and Config.SpawnTimes <= 0 then
		SpawnPart:SetAttribute("Canceled", true)
		return
	end

	if not SpawnZone:GetAttribute("EnemysSpawned") then
		return
	end

	SpawnedEnemys[SpawnZone] = SpawnedEnemys[SpawnZone] or {}

	-- Si ya hay un enemigo asociado a este SpawnPart, no hacemos nada
	if SpawnedEnemys[SpawnZone][SpawnPart] then
		return
	end

	-- Si el nombre es genérico, lo cambiamos a un GUID
	if SpawnPart.Name == "SpawnPart" then
		SpawnPart.Name = HttpService:GenerateGUID(false)
	end

	-- Elegir nivel
	local levelList = Config.Level
	local randomLevelIndex = math.random(1, #levelList)
	local chosenLevel = levelList[randomLevelIndex]

	-- Crear enemigo
	local enemy = module.SpawnEnemy(
		Config.PossibleEnemySpawns,
		chosenLevel,
		SpawnPart.Name,
		SpawnZone.Name,
		Config,
		SpawnPart
	)

	if not enemy then
		return
	end

	SpawnedEnemys[SpawnZone][SpawnPart] = enemy

	-- Efecto de spawn
	RemoteEvent:FireAllClients("EnemysSpawnEffects", "Spawn", SpawnPart)

	-- Consumir un spawn si la config lo usa
	if Config.SpawnTimes then
		Config.SpawnTimes -= 1
	end

	-- Inicializar IA
	local NPCChar = NPC.new(enemy, Config.Settings or DEFAULT_SETTINGS)
	
	NPCChar.attackEvent:Connect(function()	
		local Humanoid = enemy:FindFirstChild("Humanoid")
		if not enemy or not Humanoid then return end
		if Humanoid.Health <= 0 then return end
		local Combat = CombatManager.SetCombat()
		Combat.Character = enemy
		local Tool = enemy:FindFirstChildOfClass("Tool")
		Combat:Attack(Tool)
	end)
	
	-- Limpieza de conexiones y tabla
	local connectionDied
	local connectionAncestryChanged

	local function cleanup()
		if connectionDied then
			connectionDied:Disconnect()
			connectionDied = nil
		end

		if connectionAncestryChanged then
			connectionAncestryChanged:Disconnect()
			connectionAncestryChanged = nil
		end

		local zoneTable = SpawnedEnemys[SpawnZone]
		if zoneTable then
			zoneTable[SpawnPart] = nil

			-- Si esa zona ya no tiene spawns, limpiamos la tabla de la zona
			if next(zoneTable) == nil then
				SpawnedEnemys[SpawnZone] = nil
			end
		end
	end

	local humanoid = enemy:FindFirstChildOfClass("Humanoid")

	if humanoid then
		connectionDied = humanoid.Died:Connect(function()
			cleanup()

			-- Destruir el modelo después de un delay
			task.delay(3, function()
				if enemy and enemy.Parent then
					enemy:Destroy()
				end
			end)

			-- Respawn
			local respawnTime = Config.RespawnTime
			if respawnTime and respawnTime[1] and respawnTime[2] then
				local respawnDelay = math.random(respawnTime[1], respawnTime[2])

				task.delay(respawnDelay, function()
					if SpawnZone:GetAttribute("EnemysSpawned") then
						if not Config.CanRespawn then
							SpawnPart:SetAttribute("Canceled", true)
						else
							module.TrackSpawnPart(SpawnPart, SpawnZone)
						end
					end
				end)
			end
		end)
	end

	connectionAncestryChanged = enemy.AncestryChanged:Connect(function(_, parent)
		if not parent then
			cleanup()
		end
	end)
end

-- Deja de trackear una spawnpart (despawner de zona)
-- Deja de trackear una spawnpart (Ahora los regresa a casa en vez de matarlos)
function module.UnTrackSpawnPart(_SpawnPart, SpawnZone)
	if not SpawnZone then return end

	local zoneTable = SpawnedEnemys[SpawnZone]
	if zoneTable then
		for part, enemy in pairs(zoneTable) do
			if enemy and enemy.Parent then
				local hrp = enemy:FindFirstChild("HumanoidRootPart")
				if hrp then
					-- Los teletransportamos de vuelta a su parte de spawn
					hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)

					-- Opcional: Si quieres que dejen de seguir al jugador inmediatamente
					local humanoid = enemy:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid:MoveTo(hrp.Position) 
					end
				end
			end
		end
		-- NOTA: No borramos SpawnedEnemys[SpawnZone] = nil aquí 
		-- para que el sistema sepa que los enemigos siguen existiendo.
	end
end

-- Despawnea todos los enemigos con cierto tag (normalmente el nombre de la zona)
function module.DespawnEnemys(tag)
	if not tag then
		return
	end
	
	local enemies = CollectionService:GetTagged(tag)

	for _, enemy in ipairs(enemies) do
		local rootPart = enemy:FindFirstChild("HumanoidRootPart")
		local Humanoid = enemy:FindFirstChildOfClass("Humanoid")
		
		RemoteEvent:FireAllClients("EnemysSpawnEffects", "Despawn", {rootPart.CFrame, rootPart.Size})
		
		if Humanoid and Humanoid.Health then
			Humanoid.Health = 0 -- MI SISTEMA DE IA LO DESTRUYE AL MORIR Y LIMPIA CONECCIONES.
		end
	end
end

return module