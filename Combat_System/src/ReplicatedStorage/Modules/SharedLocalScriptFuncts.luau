local Players = game.Players
local module = {}


PlayerEvents = {}


----------Desconexion de eventos de jugador
----------------------------------------------------------------------------
local PlayerEvents = {}  -- Tabla global para almacenar eventos de cada jugador
-- Función para desconectar los eventos del jugador cuando se va
local function PlayerRemoving()
	Players.PlayerRemoving:Connect(function(Plr)

		if PlayerEvents[Plr] then
			for _, event in pairs(PlayerEvents[Plr]) do
				event:Disconnect()
			end
			-- Limpio la tabla de eventos para ese jugador
			PlayerEvents[Plr] = nil
		end
	end)
end
PlayerRemoving()


function module.DisconnectPlayerEvents(EventTable, Player)
	-- Si el jugador no tiene una tabla de eventos, crear una
	if not PlayerEvents[Player] then
		PlayerEvents[Player] = {}
	end
	if typeof(EventTable) ~= "table" then return end

	for _, event in pairs(EventTable) do
		table.insert(PlayerEvents[Player], event)
	end
end

local flags = {"Stunned", "Attacking", "IsRagdolled", "CastingSkill", "CinematicMode", "IsCharging"}
function module.CFS(Character, blacklist)

	for _, flagName in pairs(flags) do
		local isFlagBlacklisted = blacklist and table.find(blacklist, flagName)
		if not isFlagBlacklisted and Character:GetAttribute(flagName) then
			return 1
		end

	end
	return 0
end

local lastActivation = {}
local taskRunning = {}

local function CreateLTSAA(Parent)
	local A1 = Instance.new("Attachment", Parent)
	A1.Name = "LTSAA"
	local AO = Instance.new("AlignOrientation", A1)
	AO.Mode = Enum.OrientationAlignmentMode.OneAttachment
	AO.Attachment0 = A1
	AO.MaxTorque = math.huge
	AO.Responsiveness = 70
	AO.MaxAngularVelocity = math.huge
	return A1,AO
end
local function DestroyLTSAA(LTSAA)
	if LTSAA then 
		LTSAA:Destroy()
	end
end

function module.ControlMouse(Player:Player, Character:Model, Type, NotFall, lookY) 
	local hrp = Character:FindFirstChild("HumanoidRootPart")
	if not hrp or not Player then return end

	local uis = game:GetService("UserInputService")
	local mouse = Player:GetMouse()

	local function ToggleFreeze(enable: boolean)
		local ap = hrp:FindFirstChild("NF_AlignPosition")

		if enable then
			if not ap then

				local att = Instance.new("Attachment")
				att.Name = "NF_Att"
				att.Parent = hrp
				
				ap = Instance.new("AlignPosition")
				ap.Name = "NF_AlignPosition"
				ap.Mode = Enum.PositionAlignmentMode.OneAttachment
				ap.MaxForce = 1e9
				ap.Responsiveness = 200
				ap.Parent = att
				ap.Attachment0 = att


				ap.Position = hrp.Position
			end
		else
			if ap then ap:Destroy() end
			local att = hrp:FindFirstChild("NF_Att")
			if att then att:Destroy() end
		end
	end

	local function GetVisibleMousePos()
		if not mouse or not mouse.Hit then return end
		local cam = workspace.CurrentCamera
		local origin = cam.CFrame.Position
		local direction = (mouse.Hit.Position - origin).Unit * 1000
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.CollisionGroup = "Players"
		params.RespectCanCollide = true

		local result = workspace:Raycast(origin, direction, params)

		if result then
			local part = result.Instance

			if part.Transparency > 0
				or part:IsA("Decal")
				or part:IsA("Texture")
				or part:IsA("BillboardGui")
				or part:GetAttribute("IgnoreMouse") == true
			then
				return mouse.Hit.Position
			end

			return result.Position
		end

		return mouse.Hit.Position
	end

	if Type == "Lock" then
		if hrp:FindFirstChild("LTSAA") then hrp.LTSAA:Destroy() end
		Character:SetAttribute("MouseLock", true)


		if NotFall then
			ToggleFreeze(true)
		end

		local A1, AO

		task.spawn(function()
			while Character:GetAttribute("MouseLock") and module.CFS(Character,{"CastingSkill"}) ~= 1 do
				task.wait(0.015)

				if uis.MouseBehavior == Enum.MouseBehavior.LockCenter and not lookY then
					Character:SetAttribute("MouseLock", nil)
					if hrp:FindFirstChild("LTSAA") then hrp.LTSAA:Destroy() end

					if NotFall then ToggleFreeze(false) end
					return
				end

				if not A1 or not AO then
					A1, AO = CreateLTSAA(hrp)
				end

				local mousePos = GetVisibleMousePos()
				if not mousePos then return end
				local lookAt = Vector3.new(mousePos.X, lookY and mousePos.Y or hrp.Position.Y, mousePos.Z)

				AO.CFrame = CFrame.lookAt(Vector3.zero, (lookAt - hrp.Position).Unit)

				if NotFall then
					local ap = hrp:FindFirstChild("NF_AlignPosition")
					if ap then
						ap.Position = hrp.Position
					end
				end
			end

			if A1 then A1:Destroy() end

			if NotFall then ToggleFreeze(false) end
		end)

	else
		Character:SetAttribute("MouseLock", nil)
		if hrp:FindFirstChild("LTSAA") then hrp.LTSAA:Destroy() end
		if NotFall then ToggleFreeze(false) end
		hrp.Parent.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		task.defer(function()
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero

			local cf = hrp.CFrame
			local _, y = cf:ToOrientation()
			Character:PivotTo(CFrame.new(cf.Position) * CFrame.Angles(0, y, 0))

			task.wait()
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end)



	end
end

function module.LookToMouse(Character, Mouse, duration)
	local uis = game:GetService("UserInputService")
	if uis.MouseBehavior == Enum.MouseBehavior.LockCenter then return end
	local hrp = Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	lastActivation[Character] = tick()

	local A1 = hrp:FindFirstChild("LTAA") or Instance.new("Attachment", hrp)
	A1.Name = "LTAA"
	local AO = A1:FindFirstChildOfClass("AlignOrientation") or Instance.new("AlignOrientation", A1)
	AO.Mode = Enum.OrientationAlignmentMode.OneAttachment
	AO.Attachment0 = A1
	AO.MaxTorque = math.huge
	AO.Responsiveness = 70
	AO.MaxAngularVelocity = math.huge

	if taskRunning[Character] then return end
	taskRunning[Character] = true

	Character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			lastActivation[Character] = nil
			taskRunning[Character] = nil
		end
	end)

	task.spawn(function()
		while tick() - lastActivation[Character] < duration and A1.Parent do
			task.wait(0.015)
			local mousePos = Mouse.Hit.Position
			local lookAt = Vector3.new(mousePos.X, hrp.Position.Y, mousePos.Z)
			AO.CFrame = CFrame.lookAt(Vector3.zero, (lookAt - hrp.Position).Unit)
		end

		if tick() - lastActivation[Character] >= duration then
			A1:Destroy()
			lastActivation[Character] = nil
		end

		taskRunning[Character] = nil
	end)
end

return module
