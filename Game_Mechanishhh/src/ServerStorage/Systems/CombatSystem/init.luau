--Services
local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--Folders
local CombatAssets = RS:WaitForChild("SystemAssets"):WaitForChild("CombatSystem")
local SystemEvents = RS:WaitForChild("SystemEvents")
local SystemsFolder = SS:WaitForChild("Systems")
local SwordConfigs = CombatAssets:WaitForChild("Configs")
local AllAnimsFolder = CombatAssets:WaitForChild("Animations")
local Modules = RS:WaitForChild("Modules")
--Modules
local DataSaver = require(SS:WaitForChild("DataModules"):WaitForChild("DataSaver"))
local combatTable = require(Modules:WaitForChild("CombatTable"))
local muchachoHitBox = require(SystemsFolder:WaitForChild("HitboxSystem"))
local hitService = require(script:WaitForChild("HitService"))
local SkillRagdoll = require(SystemsFolder:WaitForChild("RagdollSystem"))
local AnimationManager = require(Modules:WaitForChild("MysterysAnimationManager"))
--Events
local Shake =  SystemEvents:WaitForChild("FXManagerEvent")
local VFXEvent = SystemEvents:WaitForChild("FXEvent")



local module = {}
module.__index = module


local function MovementFunction(character, velocity, duration)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if root:FindFirstChild("VelocityAttachment") then
		root:FindFirstChild("VelocityAttachment"):Destroy()
	end
	local A1 = Instance.new("Attachment")
	A1.Name = "VelocityAttachment"
	A1.Parent = root
	A1.WorldPosition = root.AssemblyCenterOfMass
	local LV = Instance.new("LinearVelocity",A1)
	LV.Attachment0 = A1
	LV.MaxForce = 100000
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not character or not character.Parent then
			connection:Disconnect()
			A1:Destroy()
			return
		end
		LV.VectorVelocity = root.CFrame.LookVector * velocity
	end)
	task.delay(duration, function()
		if connection then connection:Disconnect() end
		A1:Destroy()
	end)
end


local function stopAnimations(animNames, chr)
	if not chr:FindFirstChild("Humanoid") then return end
	if not chr.Humanoid:FindFirstChild("Animator") then return end
	for _, animTrack in pairs(chr.Humanoid.Animator:GetPlayingAnimationTracks()) do
		if table.find(animNames, animTrack.Name) then
			animTrack:Stop(1)
			animTrack:Destroy()
		end
	end
end


local function SetCombo(CV, MaxCombo, SD, char, Input,ResetTime)
	
	local combo = CV.Combo

	if combo < MaxCombo then
		CV.Combo += 1		
		SD.CurrentCombo = CV.Combo

	else
		CV.Combo = 1
		SD.CurrentCombo = CV.Combo
		task.delay(ResetTime,function()
			local BS = char:GetAttribute("BaseSpeed") or 16
			char.Humanoid.WalkSpeed = BS
			char:SetAttribute("Attacking", false)
		end)
	end
end

--ComboReset Function Start
local function ComboReset(CV, oldcombo, MaxCombo, humanoid, SD, character, ResetTime)
	task.delay(ResetTime,function()
		if CV.Combo-1 == oldcombo and not CV.Attacking then
			local BS = character:GetAttribute("BaseSpeed") or 16
			character.Humanoid.WalkSpeed = BS
			character:SetAttribute("Attacking", false)
		end
	end)
	
	task.delay(0.7, function()
		local currentcombo = CV.Combo
		if oldcombo == MaxCombo then return end

		if currentcombo-1 == oldcombo and not CV.Attacking then
			CV.Combo = 1
			SD.CurrentCombo = CV.Combo
			character:SetAttribute("Attacking", false)
		end

	end)
end

function module.SetCombat()
	return setmetatable({
		Character = nil,
		Offset = CFrame.new(0,0,-8),
		ComboCooldown = 0.7,
	}, module)
end

local function SetEnemyEffects(hum, humanoid, rootpart,Anim,Ragdolled,Stun,VFXF)
	local hrp = hum.Parent.HumanoidRootPart
	if not (hum == humanoid) and not hum.Parent:GetAttribute("IsAPlayer") then
		for i,v in pairs(hrp:GetChildren()) do
			if v.Name == "LTA" then
				v:Destroy()
			end
		end
		local A1 = Instance.new("Attachment", hrp)
		A1.Name = "LTA"
		local AO = Instance.new("AlignOrientation", A1)
		AO.Mode = Enum.OrientationAlignmentMode.OneAttachment
		AO.Attachment0 = A1
		AO.MaxTorque = math.huge
		AO.Responsiveness = 1000
		AO.MaxAngularVelocity = math.huge
		local mousePosition = Vector3.new(rootpart.Position.X, hrp.Position.Y, rootpart.Position.Z)
		local newCFrame = CFrame.new(hrp.Position, mousePosition)
		AO.CFrame = CFrame.new(Vector3.zero, newCFrame.LookVector)
		game.Debris:AddItem(A1, 1.5)
		
	end

	if Ragdolled then
		SkillRagdoll.enableRagdoll(hum.Parent,Ragdolled.Value)
	else
		stopAnimations({"AttackAnimation"}, hum.Parent)
		local HitAnim = AllAnimsFolder:FindFirstChild(Anim.Value.."H") or AllAnimsFolder:FindFirstChild("GeneralHit")
		if hum and hum:FindFirstChild("Animator") then
			local HA = AnimationManager.GetTrack(hum.Animator,HitAnim)
			HA:Play(1)
		end
	end
	
	VFXEvent:FireAllClients("Attack",hum.Parent,nil,nil,nil,"HitFX",Stun,VFXF)
end

local function GetWeaponData(character,CV,Tool)
	local StatTable = {}
	local player = game.Players:GetPlayerFromCharacter(character) or character
	local PlrData = DataSaver.GetSyncPlayerData(player)
	local SessionData = PlrData.SessionData
	local CurrentCombo = SessionData.CurrentCombo
	local KB
	local HitBoxSize
	local StunDur
	local Movement
	local MovementTime
	local IFrame
	local IFrameTime
	local StopTime
	local Ragdoll = nil
	local ResetTime
	local CanMove


	local ConfigF = SwordConfigs:FindFirstChild(Tool:GetAttribute("Shiny") or Tool:GetAttribute("Name"))
	if not ConfigF then return end
	local AnimF = ConfigF.AnimsConfig
	local BaseStats = AnimF.Calibration

	local function GetStatValue(folder, statName, defaultValue)
		local stat = folder:FindFirstChild(statName)
		return stat and stat.Value or defaultValue
	end

	local MaxCombo = require(ConfigF.ExtraConfig).MaxCombo
	local CanMove = require(ConfigF.ExtraConfig).CanMove
	SessionData.MaxCombo = MaxCombo

	local AnimFolder = AnimF.Anims[tostring(CurrentCombo)]
	KB = GetStatValue(AnimFolder, "KnockBack", BaseStats.KnockBack.Value)
	HitBoxSize = GetStatValue(AnimFolder, "Hitbox", BaseStats.Hitbox.Value)
	StunDur = GetStatValue(AnimFolder, "StunDur", BaseStats.StunDur.Value)
	Movement = GetStatValue(AnimFolder, "Movement", BaseStats.Movement.Value)
	MovementTime = GetStatValue(AnimFolder, "MovementTime", BaseStats.MovementTime.Value)
	ResetTime = GetStatValue(AnimFolder,"ResetTime", BaseStats.ResetTime.Value)

	local IFrameFolder = AnimFolder:FindFirstChild("IFrame")
	if IFrameFolder then
		IFrame = IFrameFolder.Value
		IFrameTime = IFrameFolder:FindFirstChild("Time").Value
	else
		IFrame = nil
		IFrameTime = nil
	end
	local RF = AnimFolder:FindFirstChild("Ragdoll")
	if RF then
		Ragdoll = RF
	end

	local AnimInst = AllAnimsFolder:FindFirstChild(AnimFolder.Value)
	StopTime = AnimInst.Duration.Value
	
	local Source = Tool:GetAttribute("Type")
	local TotalDmg
	if Source == "Sword" then
		TotalDmg = SessionData.TotalSwordDmg
	elseif Source == "Servant" then
		TotalDmg = SessionData.TotalServantMult
	elseif Source == "Combat" then
		TotalDmg = SessionData.TotalMeleeDmg
	end
	
	StatTable = {
		KB = KB,
		Movement = Movement,
		MovementTime = MovementTime,
		IFrame = IFrame,
		TotalDmg = TotalDmg,
		IFrameTime = IFrameTime,
		StunDur = StunDur,
		HitBoxSize = HitBoxSize,
		MaxCombo = MaxCombo,
		CurrentCombo = CurrentCombo,
		StopTime = StopTime,
		Anim = AnimFolder,
		Ragdoll = Ragdoll,
		SD = SessionData,
		ResetTime = ResetTime,
		AnimInst = AnimInst,
		CanMove = CanMove,
		VFXF = require(ConfigF.FXConfig),
		Source = Source,
	}

	return StatTable
end




local function PlayEffects(AnimInst,Anim,CurrentCombo, humanoid, player, Movement, MT, hitbox, MaxCombo, CV,IFrame,IT,VFXF)
	local character = humanoid.Parent
	if not humanoid then return end
	if not character then return end
	
	-- Eliminar espadas existentes

	humanoid.Parent:SetAttribute("Attacking", true)
	stopAnimations({"AttackAnimation"}, character)
	
	local AnimInstClone = AnimInst:Clone()
	AnimInstClone.Name = "AttackAnimation"
	local AnimTrack = AnimationManager.GetTrack(humanoid:FindFirstChild("Animator"),AnimInstClone)
	AnimInstClone:Destroy()
	AnimTrack:Play(0.2)
	
	if IFrame then
		character:SetAttribute("IFrame",IFrame)
		task.delay(IT,function()
			character:SetAttribute("IFrame",nil)
		end)
	end

	local Con,Con2
	task.delay(2,function()
		if Con then
			Con:Disconnect()
		end
		if Con2 then
			Con2:Disconnect()
		end
	end)
	Con = AnimTrack:GetMarkerReachedSignal("Movement"):Connect(function()
		if player then
			VFXEvent:FireClient(player, "Movement", character, Movement, MT)
		else
			MovementFunction(character,Movement,MT)
		end
		
	end)

	Con2 = AnimTrack:GetMarkerReachedSignal("Hit"):Connect(function()
		hitbox:Start()
		local Special = (CurrentCombo == MaxCombo)
		if Special and player then
			local Params = {
				NameF = "Shake",
				Function = "Function",
				TargetPlayer = character,
				Type = "Simple",
				Object = nil,
				Distance = nil,
				Name = "SuperSlash1",
				CustomTime = nil,
				Module = "CameraManager"
			}
			Shake:FireClient(player,Params)
		elseif player then
			local Params = {
				NameF = "Shake",
				Function = "Function",
				TargetPlayer = character,
				Type = "Simple",
				Object = nil,
				Distance = nil,
				Name = "HeavyHit",
				CustomTime = nil,
				Module = "CameraManager"
			}
			Shake:FireClient(player,Params)
		end
		VFXEvent:FireAllClients("Attack", character, CurrentCombo, Anim, Special,nil,nil,VFXF)
		task.delay(0.1, function() hitbox:Stop() end)
	end)
end



function module:Attack(Tool)
	local character = self.Character
	local player = game.Players:GetPlayerFromCharacter(character)
	local humanoid = character:FindFirstChild("Humanoid")
	if not character or not humanoid then return end
	local CV = combatTable[character]
	if not CV then return end
	local attacking = CV.Attacking
	local StatTable = GetWeaponData(character,CV,Tool)
	if not StatTable then return end

	
	local MaxCombo = StatTable.MaxCombo
	local CurrentCombo = StatTable.CurrentCombo

	if CurrentCombo > MaxCombo or humanoid.Health <= 0 then return end
	if attacking or character:GetAttribute("IsRagdolled") or character:GetAttribute("Stunned") then return end

	local rootpart = humanoid.RootPart
	local hitbox = muchachoHitBox.CreateHitbox()
	hitbox.Size = StatTable.HitBoxSize
	hitbox.Offset = CFrame.new(0,0,-(StatTable.HitBoxSize.Z/2))
	hitbox.CFrame = rootpart
	hitbox.Visualizer = false
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	hitbox.OverlapParams = params

	CV.Attacking = true
	task.delay(StatTable.StopTime, function()
		if CurrentCombo == MaxCombo then
			task.wait(self.ComboCooldown)
		end
		ComboReset(CV, CurrentCombo, MaxCombo, humanoid, StatTable.SD, character,StatTable.ResetTime)
		CV.Attacking = nil
	end)

	hitbox.Touched:Connect(function(hit, hum)
		if hum.Health <= 0 or hum.Parent:GetAttribute("NPC") or hum.Parent:GetAttribute("IsRagdolled") or hum.Parent:GetAttribute("IFrame") then return end
		local KB = rootpart.CFrame.LookVector * StatTable.KB
		SetEnemyEffects(hum, humanoid, rootpart, StatTable.Anim, StatTable.Ragdoll, StatTable.StunDur,StatTable.VFXF)
		hitService.Hit(hum, StatTable.TotalDmg, StatTable.StunDur, KB, humanoid,CV,StatTable.Source)
	end)

	PlayEffects(StatTable.AnimInst,StatTable.Anim,CurrentCombo, humanoid, player, StatTable.Movement, StatTable.MovementTime, hitbox, StatTable.MaxCombo, CV, StatTable.IFrame, StatTable.IFrameTime,StatTable.VFXF)
	
	if not StatTable.CanMove then
		humanoid.WalkSpeed = 0
	end
	SetCombo(CV, MaxCombo, StatTable.SD, character, StatTable.ResetTime)
end


return module