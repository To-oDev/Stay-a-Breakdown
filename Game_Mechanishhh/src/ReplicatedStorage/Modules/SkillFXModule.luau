local RS = game:GetService("ReplicatedStorage")
local Modules = RS:WaitForChild("Modules")
local FXModule = require(Modules:WaitForChild("FXModule"))
local SystemAssets = RS:WaitForChild("SystemAssets"):WaitForChild("SkillSystem")
local FX = SystemAssets:WaitForChild("FX")
local CFSModule = require(Modules:WaitForChild("SharedLocalScriptFuncts"))
local Anims = SystemAssets:WaitForChild("Animations")
local Servants = SystemAssets:WaitForChild("Servants")
local RockScript = require(Modules:WaitForChild("FXModule"))
local CameraShaker = require(Modules:WaitForChild("CameraShaker"))
local AnimationManager = require(Modules:WaitForChild("MysterysAnimationManager"))
local Debris = game:GetService("Debris")
local TS = game:GetService("TweenService")
local camera = workspace.CurrentCamera
local LocalPlayer = game.Players.LocalPlayer

--Guardado de funciones
local Instancenew = Instance.new
local Vectornew = Vector3.new




local function PlayOnRemoveSoundsManager(Sound,Parent)
	if not Parent then return end
	local SoundClone = Sound:Clone()
	SoundClone.Parent = Parent
	SoundClone:Destroy()
end

local function StopAnimation(h, animationName)
	for _, v in pairs(h:GetPlayingAnimationTracks()) do
		if v.Name == animationName then
			v:Stop()
		end
	end
end
-- Funcion para verificar si el jugador esta dentro del rango de distancia
local function IsInDistance(Object,Player,Distance)
	if not Object or not Player.Character:FindFirstChild("HumanoidRootPart") then return end
	return (Player.Character.HumanoidRootPart.Position - Object.Position).Magnitude <= Distance
end

local function ShakeCamera(TargetPlayer,Type, Name, Distance, Object,CustomTime)
		local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
			camera.CFrame = camera.CFrame * shakeCf
		end)
		camShake:Start()
		-- Limpiar los shakes antes de agregar uno nuevo
		camShake._camShakeInstances = {}
		--Detener el camShake después de 3 segundos si es que no pongo tiepo
		task.delay(CustomTime or 3, function()
			camShake:Stop()
		end)
	
		if Type == "Simple" then
			local Player = TargetPlayer and game.Players:GetPlayerFromCharacter(TargetPlayer)
			if not Player then return end
			if not (LocalPlayer == Player) then return end
			camShake:Shake(CameraShaker.Presets[Name])
		else
			if IsInDistance(Object,LocalPlayer,Distance) then
				camShake:Shake(CameraShaker.Presets[Name])
			end
		end
end



local function SetCameraSubject(TargetPlayer,Subject)
	local Player = TargetPlayer and game.Players:GetPlayerFromCharacter(TargetPlayer)
	if Player and Player == LocalPlayer then
		camera.CameraSubject = Subject
	end
end



local function CreateTexturedFakeArm(Character)
	local original = Character:FindFirstChild("Right Arm")
	if not original then return nil end

	local model = Instancenew("Model")
	model.Name = "FakeArm"

	local hum = Instancenew("Humanoid")
	hum.Health = 0
	hum.Parent = model

	local torso = Instancenew("Part")
	torso.Name = "Torso"
	torso.Size = Vectornew(2,2,1)
	torso.Position = Vectornew(0, -999, 0)
	torso.Anchored = true
	torso.Parent = model

	local arm = original:Clone()
	arm.Anchored = true
	arm.CanCollide = false
	arm.Massless = true
	arm.Parent = model

	local shirt = Character:FindFirstChildOfClass("Shirt")
	if shirt then
		local s = shirt:Clone()
		s.Parent = model
	end

	model.Parent = workspace
	return model, arm
end

local function SpawnPunchArm(positionCFrame,Character,HRP)
	local model, arm = CreateTexturedFakeArm(Character)
	if not arm then return end

	arm.CFrame = positionCFrame * CFrame.Angles(math.rad(90),0,0)

	local forwardPunch = HRP.CFrame.UpVector * -6
	forwardPunch = CFrame.new(forwardPunch.X, forwardPunch.Y, forwardPunch.Z)

	local tween = TS:Create(
		arm,
		TweenInfo.new(0.07, Enum.EasingStyle.Sine),
		{ CFrame = arm.CFrame * forwardPunch}
	)
	tween:Play()

	task.delay(0.07, function()
		if model then model:Destroy() end
	end)
end


local function MultiPunchVFX(duration, punchesPerSecond,Character,HRP)
	local interval = 1 / punchesPerSecond
	local endTime = tick() + duration
	while tick() < endTime and Character:GetAttribute("SkillName") == "Lance Barrage" do
		local radius = math.random(4,7)
		local angle = math.rad(math.random(0,360))
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local y = math.random(-1,3)
		local pos = HRP.CFrame * CFrame.new(x, y, z)

		SpawnPunchArm(pos,Character,HRP)
		task.wait(interval)
	end
end

local function DestroyFX(Char,Table,NotRemoveServant,FXBlackList)
	for i,v in ipairs(Char:GetDescendants()) do
		if (NotRemoveServant and v.Name == "ServantClone") or (FXBlackList and FXBlackList[v.Name]) then continue end
		if Table[v.Name] then
			if v:IsA("ParticleEmitter") then
				v.Enabled = false
				task.delay(2,function()
					v:Destroy()
				end)
			else
				v:Destroy()
			end
			
		end
	end
end


--Funciones para slash barrage
local function PlayAllFX(attach,hold,enabled,blacklist)
	if not attach then return end
	for i,v in ipairs(attach:GetDescendants()) do
		if v:IsA("ParticleEmitter") and ((not blacklist) or (blacklist and not (blacklist[v.Name] or blacklist[v.Parent.Name]))) then
			if hold then
				v.Enabled = enabled
			else
				v:Emit(v:GetAttribute("EmitCount") or 1)
			end
			
		end
	end
end
local PossibleOrientations = {
	Vectornew(0, 67.374, 0),Vectornew(2.317, 67.487, 5.57),Vectornew(0.603, 67.505, 6.779)
}
local PossibleOrientation2 = {
	Vectornew(14.9, 14.318, -64.941),Vectornew(14.9, 14.318, -64.941)
}
local PossibleOrientations3 = {
	Vectornew(3.775, -67.322, -178.424)
}
local function PlaySlashFX(player, FXFolder, possibleOrient,Number,Part,ExtraPos)
	local root = Part or player.HumanoidRootPart

	local Ground = FXFolder.GroundAttach.Attachment.GroundAttach:Clone()
	Ground.Name = "SkillEffect"
	Ground.Parent = root

	local Text = Number or ""
	local Up = FXFolder.UpAttach.Attachment["UpAttach"..Text]:Clone()
	Up.Name = "SkillEffect"
	Up.Parent = root
	if possibleOrient then
		if ExtraPos then
			Up.Orientation = Up.Orientation + possibleOrient[math.random(1, #possibleOrient)]
		else
			Up.Orientation = possibleOrient[math.random(1, #possibleOrient)]
		end
	end
	

	Debris:AddItem(Ground,1.5)
	Debris:AddItem(Up,1.5)
	PlayAllFX(Ground)
	PlayAllFX(Up)

	return Ground, Up
end
local function PlayRandomSound(folder, prefix, amount, root)
	PlayOnRemoveSoundsManager(folder[prefix .. tostring(math.random(1, amount))], root)
end
local function EmitCharge(AuraFX,Rate)
	for i,v in ipairs(AuraFX:GetChildren()) do
		if v.Name == "Aura" then
			v.Enabled = true
			v.Rate = Rate
		elseif v.Name == "Explosion" then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
	
end
local function SpawnSword(Sword)
	local found
	for _, v in ipairs(Sword:GetChildren()) do
		if v:IsA("BasePart") then
			local n = v.Name
			if (n ~= "Body" and n ~= "Handle") and v.Transparency == 1 then
				v.Transparency = v:GetAttribute("Transparency") or 0
				found = true
			end
		end
	end
	if found then
		FXModule.SwordEffects(Sword, "SpawnEffects")
	end
	return found
end
local function CloneEffects(Folder, Parent, Lifetime, UseAttachment,Hold)
	if not Folder or not Parent then return end
	if UseAttachment then
		local attachment = Instancenew("Attachment")
		attachment.Name = "SkillCastAttachment"
		attachment.Parent = Parent
		if not Hold then
			Debris:AddItem(attachment, 5)
		end
		Parent = attachment
	end

	for _, effect in ipairs(Folder:GetChildren()) do
		if not Parent then break end
		local clone = effect:Clone()
		clone.Parent = Parent

		if Lifetime then
			if effect:IsA("ParticleEmitter") then
				clone.Enabled = true
				task.delay(Lifetime, function()
					clone.Enabled = false
				end)
			end
		elseif Hold then
			if effect:IsA("ParticleEmitter") then
				clone.Enabled = true
			end
			clone.Name = "HoldEffectToDestroy"
		else
			if effect:IsA("ParticleEmitter") then
				local emitCount = clone:GetAttribute("EmitCount") or 1
				clone:Emit(emitCount)
			end
		end

		if not Hold then
			Debris:AddItem(clone, 3)
		end
	end
end
----------------
local AnimTable = {
	"Start",
	"Hold",
	"Connect",
	"Enemy",
	"Failed",
	"AttackAnimation",
	"Loop",
}

local EffectsTable = {
	HoldEffectToDestroy = true,
	SkillCastAttachment = true,
	SkillVelocityAttach = true,
	VelocityAttachment = true,
	SkillEffect = true,
	ServantClone = true,
}

local module = {
	["Mouse"] = {
		["Lock"] = function(Params)
			if Params.Player then
				CFSModule.ControlMouse(Params.Player,Params.Character,"Lock",Params.NotFall,Params.lookY)
			end
		end,
		["Unlock"] = function(Params)
			if Params.Player then
				CFSModule.ControlMouse(Params.Player,Params.Character,"Unlock",Params.NotFall)
			end
		end,
	},
	["StopAnims"] = {
		["Reset"] = function(Params)
			local Char = Params.Player
			if not Params.NotEffects then
				DestroyFX(Char,EffectsTable,Params.NotRemoveServant,Params.FXBlackList)
			end
			if not Params.NotAnims then
				RockScript.stopAnimations(AnimTable,Char)
			end
			
		end,
		["Equipment"] = function(Params)
			local Character = Params.Player
			local HRP = Character:FindFirstChild("HumanoidRootPart")
			if not HRP then return end
			if Params.Grimoire then
				local Grimoire = Character:FindFirstChild("GrimoireHandle")
				if Grimoire then
					Grimoire.GrimoireHandle.Part0 = nil
				end
			end
			if Params.Sword then
				local Sword = Character:FindFirstChild("ServantSwordModel")
				if Sword then
					SpawnSword(Sword)
				end
			end

		end,
		["Camera"] = function(Params)
			if Params.Type == true then
				SetCameraSubject(Params.Player, Params.Player.Head)
			else
				SetCameraSubject(Params.Player, Params.Player.Humanoid)
			end
			
		end,
	};
	["Slash Barrage"] = {
		["Start"] = function(Params)
			local Debris = game:GetService("Debris")

			local Character = Params.Player
			local root = Character and Character:FindFirstChild("HumanoidRootPart")
			if not root then return end
			if Character:GetAttribute("Stunned") then
				return
			end
			local MainFolder = FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal")
				or FX.HarturiaDragon.Normal
			local AnimsMainFolder = Anims.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or Anims.HarturiaDragon["Normal"]
			local FXFolder = MainFolder.SlashBarrage
			local SFXFolder = FXFolder.Sounds
			local Attachment = Instancenew("Attachment")
			
			local StartAnim = AnimationManager.GetTrack(Character.Humanoid.Animator,AnimsMainFolder.SlashBarrage.Start)
			StartAnim:Play()
			
			Attachment.Name = "SkillVelocityAttach"
			Attachment.Parent = root
			Debris:AddItem(Attachment, 5)
			task.delay(1.1, function()
				if not Attachment.Parent then return end
				if not Character.Parent then
					Attachment:Destroy()
					return
				end
				local currentRoot = Character:FindFirstChild("HumanoidRootPart")
				if currentRoot ~= root then
					Attachment:Destroy()
					return
				end
				if Character:GetAttribute("Stunned") then
					Attachment:Destroy()
					return
				end
				local LV = Instancenew("LinearVelocity")
				LV.Attachment0 = Attachment
				LV.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
				LV.ForceLimitMode = Enum.ForceLimitMode.PerAxis
				LV.MaxAxesForce = Vectornew(10000, 0, 10000)
				LV.VectorVelocity = Vectornew(0, 0, -500)
				LV.Parent = Attachment
				Debris:AddItem(LV, 4)
				task.wait(0.03)
				if not Attachment.Parent or not LV.Parent then return end
				if Character:GetAttribute("Stunned") then
					Attachment:Destroy()
					return
				end
				LV.MaxAxesForce = Vectornew(100000, 0, 100000)
				LV.VectorVelocity = Vectornew(0, 0, -50)
			end)
			PlayOnRemoveSoundsManager(SFXFolder.SlashStart, root)
		end,

		["Slash"] = function(Params)
			local MainFolder = FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or FX.HarturiaDragon["Normal"]
			local FXFolder = MainFolder.SlashBarrage
			local SFXFolder = FXFolder.Sounds
			local player = Params.Player
			local root = player and player:FindFirstChild("HumanoidRootPart")
			if not root then return end
			local Ground, Up = PlaySlashFX(player, FXFolder, PossibleOrientations)
			ShakeCamera(player, "Advanced", "SmoothHit", 40, root)
			PlayRandomSound(SFXFolder, "Slash", 3, root)
			PlayRandomSound(SFXFolder, "W", 3, root)
			PlayOnRemoveSoundsManager(SFXFolder.SlashStart2, root)
			RockScript.CreateCrater(player, nil, 20, 1.2, nil, nil, nil, 0.9, true, false, true, 0, 4)
		end,

		["SuperSlash"] = function(Params)
			local MainFolder = FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or FX.HarturiaDragon["Normal"]
			local FXFolder = MainFolder.SlashBarrage
			local SFXFolder = FXFolder.Sounds
			local player = Params.Player
			local root = player.HumanoidRootPart

			local Ground, Up2 = PlaySlashFX(player, FXFolder, PossibleOrientations,"2")

			ShakeCamera(player, "Advanced", "HeavyHit", 40, root)

			PlayOnRemoveSoundsManager(SFXFolder.Explosion1, root)
			PlayOnRemoveSoundsManager(SFXFolder.Explosion2, root)

			RockScript.CreateCrater(player, nil, 30, 1.8, nil, nil, nil, 0.9, true, false, true, 50, 12)
		end,
		["Hit"] = function(Params)
			local MainFolder = FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or FX.HarturiaDragon["Normal"]
			local FXFolder = MainFolder.SlashBarrage
			local SFXFolder = FXFolder.Sounds
			local player = Params.Player
			if not player then return end
			local root = player:FindFirstChild("HumanoidRootPart")
			if not root then return end
			PlayRandomSound(SFXFolder, "W", 3, root)
			PlayRandomSound(SFXFolder, "Hit", 2, root)
			local PunchFX = FXFolder.HitFX.Part.HeavyPunch:Clone()
			PunchFX.Parent = player.Torso
			Debris:AddItem(PunchFX,1.5)
			PlayAllFX(PunchFX)
		end,
	};
	["Double Note"] = {																																																																																																																																																						
		["Start"] = function(Params)
			local Character = Params.Player
			local Player = game.Players:GetPlayerFromCharacter(Character)
			local HRP = Character:FindFirstChild("HumanoidRootPart")
			if not HRP then return end
			local MainFolder = FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or FX.HarturiaDragon["Normal"]
			local AnimsMainFolder = Anims.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or Anims.HarturiaDragon["Normal"]
			local FXFolder = MainFolder.DoubleNote
			local SFX = FXFolder.Sounds
			local Anim = AnimsMainFolder.DoubleNote
			local Grimoire = Character:FindFirstChild("GrimoireHandle")
			if Grimoire then
				Grimoire.GrimoireHandle.Part0 = HRP
			end

			local StartAnim = AnimationManager.GetTrack(Character.Humanoid.Animator, AnimsMainFolder.DoubleNote.Player.Start)
			StartAnim:Play()
			
			local Servant = Servants[Params.Shiny or "Harturia Dragon"]:Clone()
			Servant.Name = "ServantClone"
			Servant.Parent = Character
			Debris:AddItem(Servant,6)

			local Attach = Instancenew("Attachment")
			Attach.Position = Vectornew(4.782, 0, 0)
			Attach.Parent = HRP

			local SRP = Servant:FindFirstChild("HumanoidRootPart")
			if not SRP then return end

			SRP.CFrame = Attach.WorldCFrame
			SRP.Anchored = true
			
			Servant.Humanoid.Animator:LoadAnimation(Anim.Servant.Start):Play()

			local Sword = Character:FindFirstChild("ServantSwordModel")
			if Sword then
				FXModule.SwordEffects(Sword, "DespawnEffects")
				for _, v in ipairs(Sword:GetChildren()) do
					if v:IsA("BasePart") then
						v.Transparency = 1
					end
				end
			end

			local SpawnAttach = FXFolder.ServantAttachs.Spawn:Clone()
			SpawnAttach.Parent = SRP

			PlayAllFX(SpawnAttach)
			PlayOnRemoveSoundsManager(SFX.Spawn, SRP)
			PlayOnRemoveSoundsManager(SFX.Spawn2, SRP)
			PlayOnRemoveSoundsManager(SFX.Spawn3, SRP)
			ShakeCamera(Character, "Advanced", "HeavyHit", 40, SRP)
		end,

		["Hold"] = function(Params)
			local Player = Params.Player
			
			local Servant = Player:FindFirstChild("ServantClone")
			if not Servant then return end

			local HRP = Servant:FindFirstChild("HumanoidRootPart")
			if not HRP then return end
			
			local MainFolder = FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or FX.HarturiaDragon["Normal"]
			local AnimsMainFolder = Anims.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or Anims.HarturiaDragon["Normal"]
			local FXFolder = MainFolder.DoubleNote
			local SFX = FXFolder.Sounds
			local Anim = AnimsMainFolder.DoubleNote


			local Grimoire = Player:FindFirstChild("GrimoireHandle")
			if Grimoire then
				Grimoire.GrimoireHandle.Part0 = nil
			end

			if Servant:GetAttribute("Connected") then return end

			Servant.Humanoid.Animator:LoadAnimation(Anim.Servant.Hold):Play()

			local HoldAttach = FXFolder.ServantAttachs.Loop:Clone()
			HoldAttach.Parent = HRP
			PlayAllFX(HoldAttach, true,true)

			local TargetPart = Params.Part

			local att0 = Instancenew("Attachment", HRP)
			att0.Orientation = Vectornew(0, 90, 0)

			local att1 = Instancenew("Attachment", TargetPart)

			local oratt = Instancenew("Attachment")
			oratt.Position = Vectornew(0, 0, -30)
			oratt.Parent = TargetPart

			local ap = Instancenew("AlignPosition")
			ap.Attachment0 = att0
			ap.Attachment1 = att1
			ap.MaxForce = 50000
			ap.Responsiveness = 100
			ap.Parent = HRP

			local ao = Instancenew("AlignOrientation")
			ao.AlignType = Enum.AlignType.PrimaryAxisLookAt
			ao.Attachment0 = att0
			ao.Attachment1 = oratt
			ao.MaxTorque = math.huge
			ao.MaxAngularVelocity = 100000
			ao.Responsiveness = 200
			ao.Parent = HRP

			HRP.Anchored = false
			HRP.AssemblyAngularVelocity = Vectornew()
			HRP.AssemblyLinearVelocity = Vectornew()
			HRP.CFrame = CFrame.lookAt(HRP.Position, TargetPart.Position)

			PlayOnRemoveSoundsManager(SFX["big explosion"], HRP)
			PlayOnRemoveSoundsManager(SFX.GroundSmash, HRP)
			ShakeCamera(Player, "Advanced", "HeavyHit", 40, HRP)

			RockScript.CreateCrater(Servant, nil, 30, 1.8, nil, nil, nil, 0.9, true, false, true, 50, 12)

			local Part = Instancenew("Part")
			Part.CFrame = HRP.CFrame
			Part.Anchored = true
			Part.Transparency = 1
			Part.CanCollide = false
			Part.Parent = workspace.Fx

			local Impulse = FXFolder.ServantAttachs.Impulse:Clone()
			Impulse.Parent = Part

			PlayAllFX(Impulse)
			HRP.CFrame = CFrame.lookAt(HRP.Position, TargetPart.Position)
		end,

		["ServantHit"] = function(Params)
			local Player = Params.Player
			local Root = Player:FindFirstChild("HumanoidRootPart")
			if not Root then return end
			
			local MainFolder = FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or FX.HarturiaDragon["Normal"]
			local AnimsMainFolder = Anims.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or Anims.HarturiaDragon["Normal"]
			local FXFolder = MainFolder.DoubleNote
			local SFX = FXFolder.Sounds
			local Anim = AnimsMainFolder.DoubleNote

			local TargetPart = Params.Part
			TargetPart.Anchored = true
			TargetPart.CFrame = Params.CFrame

			local Servant = Player:FindFirstChild("ServantClone")
			if not Servant then return end
			Servant:SetAttribute("Connected", true)

			local HRP = Servant:FindFirstChild("HumanoidRootPart")
			HRP.CFrame = TargetPart.CFrame
			if not HRP then return end

			local Animator = Servant.Humanoid.Animator
			StopAnimation(Animator, "Hold")

			local LoopFX = HRP:FindFirstChild("Loop")
			if LoopFX then
				LoopFX:Destroy()
			end

			Animator:LoadAnimation(Anim.Servant.Connect):Play()
			HRP.Anchored = true

			local Sword = Player:FindFirstChild("ServantSwordModel")

			task.delay(0.5, function()
				local Part2 = Instancenew("Part")
				Part2.Transparency = 1
				Part2.CanCollide = false
				Part2.Anchored = true
				Part2.CFrame = HRP.CFrame
				Part2.Parent = workspace.Fx

				PlayOnRemoveSoundsManager(SFX.Spawn, Part2)
				PlayOnRemoveSoundsManager(SFX.Attack1, Part2)
				PlayOnRemoveSoundsManager(SFX.Explosion2, Part2)
				PlayOnRemoveSoundsManager(SFX["big explosion"], Part2)

				PlaySlashFX(Servant, FXFolder, PossibleOrientations)

				ShakeCamera(Player, "Advanced", "HeavyHit", 60, Part2)
				RockScript.CreateCrater(Player, HRP.Position, 60, 1.8, nil, nil, nil, 0.9, true, false, true, 50, 25)

				task.delay(0.4, function()
					local SpawnAttach = FXFolder.ServantAttachs.Spawn:Clone()
					SpawnAttach.Parent = Part2
					PlayAllFX(SpawnAttach)

					if Sword then
						SpawnSword(Sword)
					end

					Servant:Destroy()
				end)
			end)
		end,

		["PlayerHold"] = function(Params)
			local Player = Params.Player
			local HRP = Player:FindFirstChild("HumanoidRootPart")
			if not HRP then return end
			local MainFolder = FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or FX.HarturiaDragon["Normal"]
			local AnimsMainFolder = Anims.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or Anims.HarturiaDragon["Normal"]
			local FXFolder = MainFolder.DoubleNote
			local SFX = FXFolder.Sounds
			local Anim = AnimsMainFolder.DoubleNote
			local Hum = Player.Humanoid
			local Animator = Hum.Animator

			local HoldAttach
			local LoopAnim = AnimationManager.GetTrack(Animator,Anim.Player.Connect)
			LoopAnim:Play()
			SetCameraSubject(Player, Player.Head)
			task.delay(1.6, function()
				LoopAnim = AnimationManager.GetTrack(Animator,Anim.Player.Hold)
				LoopAnim:Play()

				HoldAttach = FXFolder.ServantAttachs.Loop:Clone()
				HoldAttach.Parent = HRP

				PlayAllFX(HoldAttach, true,true)
				PlayOnRemoveSoundsManager(SFX["big explosion"], HRP)
				PlayOnRemoveSoundsManager(SFX.GroundSmash, HRP)

				ShakeCamera(Player, "Advanced", "HeavyHit", 40, HRP)
				RockScript.CreateCrater(Player, nil, 30, 1.8, nil, nil, nil, 0.9, true, false, true, 50, 12)

				local Part = Instancenew("Part")
				Part.CFrame = HRP.CFrame
				Part.Anchored = true
				Part.Transparency = 1
				Part.CanCollide = false
				Part.Parent = workspace.Fx

				local Impulse = FXFolder.ServantAttachs.Impulse:Clone()
				Impulse.Parent = Part

				PlayAllFX(Impulse)
			end)

			task.delay(1.6+Params.Timedelay, function()
				PlayOnRemoveSoundsManager(SFX.Spawn, HRP)
				PlayOnRemoveSoundsManager(SFX.Attack1, HRP)
				PlayOnRemoveSoundsManager(SFX.Explosion2, HRP)
				PlayOnRemoveSoundsManager(SFX["big explosion"], HRP)

				local Ground, Up = PlaySlashFX(Player, FXFolder, PossibleOrientations)
				ShakeCamera(Player, "Advanced", "HeavyHit", 60, HRP)
				RockScript.CreateCrater(Player, nil, 60, 1.8, nil, nil, nil, 0.9, true, false, true, 50, 25)

				LoopAnim:Stop()
				if HoldAttach then
					HoldAttach:Destroy()
				end
			end)
		end,

		["DoubleNoteHit"] = function(Params)
			local Enemy = Params.Enemy
			local Hum = Enemy:FindFirstChild("Humanoid")
			if not Hum then return end
			local AnimsMainFolder = Anims.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or Anims.HarturiaDragon["Normal"]
			local Anim = AnimsMainFolder.DoubleNote
			local Animator = Hum:FindFirstChild("Animator") or Hum
			
			local LoopAnim = AnimationManager.GetTrack(Params.Player.Humanoid.Animator,Anim.Player.Enemy)
			LoopAnim:Play()
			task.delay(0.47, function()
				local Track = AnimationManager.GetTrack(Animator,Anim.Enemy.Connect)
				Track:Play()
			end)
		end,

		["Slash"] = function(Params)
			local Player = Params.Player
			local Enemy = Params.Enemy
			local Torso = Player:FindFirstChild("Torso")
			local HRP = Player:FindFirstChild("HumanoidRootPart")
			if not Torso or not HRP then return end
			
			local MainFolder = FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or FX.HarturiaDragon["Normal"]
			local FXFolder = MainFolder.DoubleNote
			local SFX = FXFolder.Sounds

			PlayOnRemoveSoundsManager(SFX.Spawn, Torso)
			PlayOnRemoveSoundsManager(SFX.Attack1, Torso)
			PlayRandomSound(SFX, "Slash", 3, Torso)
			PlayRandomSound(SFX, "W", 3, Torso)

			local Ground, Up
			if Params.SlashType == "Slash" then
				PlayOnRemoveSoundsManager(SFX.IzunaSlam, HRP)
				PlayOnRemoveSoundsManager(SFX["big explosion"], Torso)
				Ground, Up = PlaySlashFX(Player, FXFolder, PossibleOrientations, "2",Player.Torso)
			else
				Ground, Up = PlaySlashFX(Player, FXFolder, PossibleOrientation2, "2",Player.Torso)
			end


			ShakeCamera(Player, "Advanced", "HeavyHit", 60, Torso)
			RockScript.CreateCrater(Player, nil, 60, 1.8, nil, nil, nil, 0.9, true, false, true, 50, 25)
			local Torso2 = Enemy and Enemy:FindFirstChild("Torso")
			if not Torso2 then return end
			PlayRandomSound(SFX, "W", 3, Torso2)
			PlayRandomSound(SFX, "Hit", 2, Torso2)

			local PunchFX = FXFolder.HitFX.Part.HeavyPunch:Clone()
			PunchFX.Parent = Torso2
			Debris:AddItem(PunchFX, 1.5)
			PlayAllFX(PunchFX)
		end,

		["EnemyHit"] = function(Params)
			local Enemy = Params.Enemy
			local Hum = Enemy:FindFirstChild("Humanoid")
			if not Hum then return end
			
			local MainFolder = FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or FX.HarturiaDragon["Normal"]
			local AnimsMainFolder = Anims.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or Anims.HarturiaDragon["Normal"]
			local FXFolder = MainFolder.DoubleNote
			local SFX = FXFolder.Sounds
			local Anim = AnimsMainFolder.DoubleNote

			local Animator = Hum:FindFirstChild("Animator") or Hum
			AnimationManager.GetTrack(Animator,Anim.Enemy.Start):Play()
			local Torso = Enemy:FindFirstChild("Torso")
			PlayRandomSound(SFX, "W", 3, Torso)
			PlayRandomSound(SFX, "Hit", 2, Torso)

			local PunchFX = FXFolder.HitFX.Part.HeavyPunch:Clone()
			PunchFX.Parent = Torso
			Debris:AddItem(PunchFX, 1.5)
			PlayAllFX(PunchFX)
		end,
	};
	["Sword Turret"] = {
		["Start"] = function(Params)
			local Character = Params.Player
			local Player = game.Players:GetPlayerFromCharacter(Character)
			local HRP = Character:FindFirstChild("HumanoidRootPart")
			if not HRP then return end
			------------
			local shinyName = Params.Shiny or "Normal"
			local FXBase = FX.HarturiaDragon:FindFirstChild(shinyName) or FX.HarturiaDragon.Normal
			local AnimBase = Anims.HarturiaDragon:FindFirstChild(shinyName) or Anims.HarturiaDragon.Normal
			local FXFolder = FXBase.SwordTurret
			local FXFolder2 = FXBase.SlashBarrage
			local FXFolder3 = FXBase.DoubleNote
			local SFX = FXFolder.Sounds
			local SFXFolder2 = FXFolder2.Sounds
			local SFX2 = FXFolder3.Sounds
			-----
			local Anim = AnimBase.SwordTurret
			local Grimoire = Character:FindFirstChild("GrimoireHandle")
			if Grimoire then
				Grimoire.GrimoireHandle.Part0 = HRP
			end
			local StartAnim = AnimationManager.GetTrack(Character.Humanoid.Animator,Anim.Player.Start)
			StartAnim:Play()
			local Servant = Servants[Params.Shiny or "Harturia Dragon"]:Clone()
			Servant.Name = "ServantClone"
			Servant.Parent = Character
			Debris:AddItem(Servant, 7)

			local SRP = Servant:FindFirstChild("HumanoidRootPart")
			if not SRP then
				Servant:Destroy()
				return
			end

			SRP.Anchored = true

			local Part = Instance.new("Part")
			Part.Massless = true
			Part.CanCollide = false
			Part.Transparency = 1
			Part.CastShadow = false
			Part.CFrame = HRP.CFrame + HRP.CFrame.LookVector * 7
			Part.Parent = Character

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = HRP
			weld.Part1 = Part
			weld.Parent = Part

			local oratt = Instance.new("Attachment")
			oratt.Position = Vector3.new(0, 0, -5)
			oratt.Parent = Part

			local att0 = Instance.new("Attachment")
			att0.Orientation = Vector3.new(0, 90, 0)
			att0.Parent = SRP

			local att1 = Instance.new("Attachment")
			att1.Parent = Part


			local ap = Instance.new("AlignPosition")
			ap.Attachment0 = att0
			ap.Attachment1 = att1
			ap.MaxForce = 50000
			ap.Responsiveness = 100
			ap.Parent = HRP

			local ao = Instance.new("AlignOrientation")
			ao.AlignType = Enum.AlignType.PrimaryAxisLookAt
			ao.Attachment0 = att0
			ao.Attachment1 = oratt
			ao.MaxTorque = math.huge
			ao.MaxAngularVelocity = 100000
			ao.Responsiveness = 200
			ao.Parent = HRP

			HRP.Anchored = false
			HRP.AssemblyAngularVelocity = Vector3.zero
			HRP.AssemblyLinearVelocity = Vector3.zero

			SRP.CFrame = Part.CFrame
			SRP.Anchored = false

			local humanoid = Servant:FindFirstChildOfClass("Humanoid")
			local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
			if not animator then return end

			local BarrageAnim = animator:LoadAnimation(Anim.Servant.Start)
			BarrageAnim:Play()


			local function SlashFX()
				ShakeCamera(Character, "Advanced", "HeavyHit", 40, SRP)
				PlayRandomSound(SFXFolder2, "Slash", 3, SRP)
				PlayRandomSound(SFXFolder2, "W", 3, SRP)
				PlayOnRemoveSoundsManager(SFXFolder2.SlashStart2, SRP)
				RockScript.CreateCrater(Character, nil, 20, 1.2, nil, nil, nil, 0.9, true, false, true, 0, 4)
			end

			local FxPart = FXFolder.FXPart:Clone()
			FxPart.Parent = Servant
			FxPart.FXPart.Part0 = SRP
			Debris:AddItem(FxPart, 7)

			local function cloneFX(folder, parent)
				for _, obj in ipairs(folder:GetChildren()) do
					obj:Clone().Parent = parent
				end
			end

			local function destroyEmitters(parent)
				for _, v in ipairs(parent:GetChildren()) do
					if v:IsA("ParticleEmitter") then
						v.Enabled = false
					elseif v:IsA("Attachment") then
						v:Destroy()
					end
				end
			end
			
			local ConnTable = {}

			ConnTable[#ConnTable+1] = BarrageAnim:GetMarkerReachedSignal("Slash1"):Connect(function()
				PlaySlashFX(Servant, FXFolder, PossibleOrientations, nil, nil, true)
				SlashFX()
			end)

			ConnTable[#ConnTable+1] = BarrageAnim:GetMarkerReachedSignal("Slash2"):Connect(function()
				PlaySlashFX(Servant, FXFolder, PossibleOrientations, "2", nil, true)
				SlashFX()
			end)

			ConnTable[#ConnTable+1] = BarrageAnim:GetMarkerReachedSignal("StartBarrage"):Connect(function()
				PlayOnRemoveSoundsManager(SFX.BarrageStart, SRP)
				PlayOnRemoveSoundsManager(SFX.BarrageStart2, SRP)

				ShakeCamera(Character, "Advanced", "Explosion2", 30, FxPart, 3)

				cloneFX(FXFolder.Slashes, FxPart)
				PlayAllFX(FxPart, true, true)

				for i = 1, 3 do
					task.delay(i - 1, function()
						RockScript.CreateCrater(Character, FxPart.Position, 40, 1.8, nil, nil, nil, 0.9, true, false, true, 50, 1)
					end)
				end
			end)

			ConnTable[#ConnTable+1] = BarrageAnim:GetMarkerReachedSignal("EndBarrage"):Connect(function()
				destroyEmitters(FxPart)

				cloneFX(FXFolder.Explosion, FxPart)
				PlayAllFX(FxPart)
				PlayOnRemoveSoundsManager(SFX.Sharp, SRP)

				task.delay(0.45, function()
					local Part2 = Instance.new("Part")
					Part2.Transparency = 1
					Part2.CanCollide = false
					Part2.Anchored = true
					Part2.CFrame = SRP.CFrame
					Part2.Parent = workspace.Fx
					Debris:AddItem(Part2, 2)

					PlayOnRemoveSoundsManager(SFX2.Spawn, Part2)
					PlayOnRemoveSoundsManager(SFX2.Attack1, Part2)
					PlayOnRemoveSoundsManager(SFX2["big explosion"], Part2)

					local SpawnAttach = FXFolder3.ServantAttachs.Spawn:Clone()
					SpawnAttach.Parent = Part2
					PlayAllFX(SpawnAttach)

					local Sword = Character:FindFirstChild("ServantSwordModel")
					if Sword then
						SpawnSword(Sword)
					end

					Servant:Destroy()

					ShakeCamera(Player, "Advanced", "HeavyHit", 60, Part2)
					RockScript.CreateCrater(Character, FxPart.Position, 60, 1.8, nil, nil, nil, 0.9, true, false, true, 50, 25)

					destroyEmitters(FxPart)
					cloneFX(FXFolder.Explosion2, FxPart)
					PlayAllFX(FxPart)

					PlayOnRemoveSoundsManager(SFX.Shared_Ambients_BigWorld_Explosions_Distant_01_wav, SRP)
					PlayOnRemoveSoundsManager(SFX["explosion sound effect"], SRP)
				end)
			end)

			task.delay(8, function()
				for _, conn in ipairs(ConnTable) do
					if conn.Connected then
						conn:Disconnect()
					end
				end
				table.clear(ConnTable)
			end)

			local Sword = Character:FindFirstChild("ServantSwordModel")
			if Sword then
				FXModule.SwordEffects(Sword, "DespawnEffects")
				for _, v in ipairs(Sword:GetChildren()) do
					if v:IsA("BasePart") then
						v.Transparency = 1
					end
				end
			end
			local SpawnAttach = FXFolder3.ServantAttachs.Spawn:Clone()
			SpawnAttach.Parent = SRP
			PlayAllFX(SpawnAttach)

			PlayOnRemoveSoundsManager(SFX2.Spawn, SRP)
			PlayOnRemoveSoundsManager(SFX2.Spawn2, SRP)
			PlayOnRemoveSoundsManager(SFX2.Spawn3, SRP)

			ShakeCamera(Character, "Advanced", "HeavyHit", 40, SRP)

			
			
		end,
		["HitEnemy"] = function(Params)
			local shiny = Params.Shiny or "Normal"
			local MainFolder = FX.HarturiaDragon:FindFirstChild(shiny) or FX.HarturiaDragon.Normal
			local AnimsMainFolder = Anims.HarturiaDragon:FindFirstChild(shiny) or Anims.HarturiaDragon.Normal
			local FXFolder = MainFolder.SlashBarrage
			local SFXFolder = FXFolder.Sounds
			local player = Params.Player
			if not player then return end

			local root = player:FindFirstChild("HumanoidRootPart")
			if not root then return end

			local humanoid = player:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end

			local animator = humanoid:FindFirstChildOfClass("Animator")
			if not animator then animator = humanoid end

			local anim = AnimsMainFolder.SwordTurret
			local track = AnimationManager.GetTrack(animator,anim.Enemy["Start"..math.random(1,2)])
			track:Play()
			PlayRandomSound(SFXFolder, "W", 3, root)
			PlayRandomSound(SFXFolder, "Hit", 2, root)
			local PunchFX = FXFolder.HitFX.Part.HeavyPunch:Clone()
			PunchFX.Parent = player.Torso
			Debris:AddItem(PunchFX, 1.5)
			PlayAllFX(PunchFX)

		end,
	};
	["Sword Explosion"] = {
		["Start"] = function(Params)
			local EnRootP = Params.Player:FindFirstChild("HumanoidRootPart")
			if not EnRootP then return end
			local MainFolder = FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or FX.HarturiaDragon["Normal"]
			local FXFolder = MainFolder.SwordExplosion
			local SFX = FXFolder.Sounds
			local AnimsMainFolder = Anims.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or Anims.HarturiaDragon["Normal"]
			local Animator = Params.Player.Humanoid.Animator
			local StartAnim = AnimationManager.GetTrack(Animator,AnimsMainFolder.SwordExplosion.Start)
			StartAnim:Play()
			local Sound1 = SFX.Wind:Clone()
			local Sound2 = SFX.HoldEffectToDestroy:Clone()
			Sound1.Name = "HoldEffectToDestroy"
			Sound1.Parent = EnRootP
			Sound2.Parent = EnRootP
			Sound1:Play()
			Sound2:Play()
			task.delay(.75,function()
				StartAnim:Stop()
				if (not Params.Player:GetAttribute("Stunned") and not Params.Player:GetAttribute("IsRagdolled")) and (Params.Player:GetAttribute("HoldingSkill") == "Sword Explosion") then
					StartAnim =  AnimationManager.GetTrack(Animator,AnimsMainFolder.SwordExplosion.Hold)
					StartAnim:Play()
				end
			end)

		end,
		["Charge"] = function(Params)
			local MainFolder = FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or FX.HarturiaDragon["Normal"]
			local FXFolder = MainFolder.SwordExplosion
			local SFX = FXFolder.Sounds
			local HRP = Params.Player:FindFirstChild("HumanoidRootPart")
			if not HRP then return end
			PlayOnRemoveSoundsManager(SFX.Punch,HRP)
			local AuraFX = HRP:FindFirstChild("SkillEffect") or FXFolder.Aura.SkillEffect:Clone()
			ShakeCamera(Params.Player, "Simple", "HeavyHit")
			
			if Params.Charge == 1 then
				AuraFX.Parent = HRP
				EmitCharge(AuraFX,5)
			elseif Params.Charge == 2 then
				EmitCharge(AuraFX,20)
			elseif Params.Charge > 2 then
				EmitCharge(AuraFX,40)
			end
		end,
		["Slash"] = function(Params)
			local Character = Params.Player
			local Player = game.Players:GetPlayerFromCharacter(Character)
			local HRP = Character:FindFirstChild("HumanoidRootPart")
			if not HRP then return end
			local MainFolder = FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or FX.HarturiaDragon["Normal"]
			local FXFolder = MainFolder.SwordExplosion
			local SFX = FXFolder.Sounds
			local AnimsMainFolder = Anims.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or Anims.HarturiaDragon["Normal"]
			local Anims = AnimsMainFolder.SwordExplosion
			PlayOnRemoveSoundsManager(SFX.Dash,HRP)
			local StartAnim = AnimationManager.GetTrack(Character.Humanoid.Animator, Anims.Connect)
			StartAnim:Play()
			task.delay(0.4,function()
				PlayOnRemoveSoundsManager(SFX.Sharp,HRP)
				PlayOnRemoveSoundsManager(SFX.GroundSmash,HRP)
				PlayOnRemoveSoundsManager(SFX.IzunaSlam,HRP)
				PlayOnRemoveSoundsManager(SFX.Slash1,HRP)
				RockScript.CreateCrater(Character, nil, 30, 1.2, nil, nil, nil, 0.9, true, false, true, 0, 1)
				ShakeCamera(Player, "Advanced", "HeavyHit", 30, HRP)
				PlaySlashFX(Character,FXFolder,nil)
			end)
		end,
		["Projectile"] = function(Params)
			local MainFolder = FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or FX.HarturiaDragon["Normal"]
			local FXFolder = MainFolder.SwordExplosion
			local HRP = Params.Player:FindFirstChild("HumanoidRootPart")
			local Part = Params.Part
			if not Part then return end
			local Slash = FXFolder.Slash:Clone()
			Slash.Parent = Part
			Slash.CFrame = Part.CFrame
			local weld = Instancenew("WeldConstraint",Slash)
			weld.Part0 = Part
			weld.Part1 = Slash
			local AuraFX = HRP:FindFirstChild("SkillEffect")
			if AuraFX then
				EmitCharge(AuraFX,0)
				task.delay(0.5,function()
					if AuraFX then
						AuraFX:Destroy()
					end
				end)
			end
			
		end,
		["Projectile_Explode"] = function(Params)
			local MainFolder = FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or FX.HarturiaDragon["Normal"]
			local FXFolder = MainFolder.SwordExplosion
			local SFX = FXFolder.Sounds
			local Part = Params.Part
			if not Part then return end
			if Part:FindFirstChild("Slash") then
				Part.Slash:Destroy()
			end
			for i,v in ipairs(FXFolder.Explosion:GetChildren()) do
				local Clone = v:Clone()
				Clone.Parent = Part
			end
			PlayOnRemoveSoundsManager(SFX.Sharp,Part)
			PlayOnRemoveSoundsManager(SFX.SuperExplosion,Part)
			PlayOnRemoveSoundsManager(SFX.SuperExplosion2,Part)
			RockScript.CreateCrater(nil, Part.Position, 60, 4, nil, nil, nil, 2, true, false, true, 0, 60)
			ShakeCamera(Params.Player, "Advanced", "HeavyHit", 120, Part)
			PlayAllFX(Part)
		end,
		["Massive_Explosion"] = function(Params)
			local MainFolder = FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or FX.HarturiaDragon["Normal"]
			local FXFolder = MainFolder.SwordExplosion
			local SFX = FXFolder.Sounds
			local Part = Params.Part
			local HRP = Params.Player:FindFirstChild("HumanoidRootPart")
			local VFXPart = FXFolder.VFXpart:Clone()
			VFXPart.Parent = workspace.Fx
			VFXPart.CFrame = Part.CFrame
			VFXPart.Weld.Part1 = Part
			Debris:AddItem(VFXPart,5)
			PlayOnRemoveSoundsManager(SFX.Sharp, VFXPart)
			PlayOnRemoveSoundsManager(SFX.SuperExplosion, VFXPart)
			local AuraFX = HRP:FindFirstChild("SkillEffect")
			if AuraFX then
				EmitCharge(AuraFX,0)
				task.delay(0.5,function()
					if AuraFX then
						AuraFX:Destroy()
					end
				end)
			end
			for _,v in ipairs(VFXPart:GetChildren()) do
				if v.Name == "Start" then
					v:Emit(v:GetAttribute("EmitCount"))
				end
			end

			local parts = {}
			local particles = {}

			for _,v in ipairs(VFXPart:GetChildren()) do
				if v:IsA("Part") then
					table.insert(parts, v)
				elseif v:IsA("ParticleEmitter") and v.Name ~= "Start" then
					table.insert(particles, v)
				end
			end

			for _,v in ipairs(parts) do
				RockScript.CreateCrater(nil, v.Position, 60, 4, nil, nil, nil, 1, true, false, true, 0, 15)
				ShakeCamera(Params.Player, "Advanced", "HeavyHit", 60, Part)
				PlayOnRemoveSoundsManager(SFX.UltimateSound, v)
				PlayOnRemoveSoundsManager(SFX.UltimateSound2, v)
				task.wait(0.1)
			end

			VFXPart.Anchored = true
			for _,v in ipairs(parts) do
				ShakeCamera(Params.Player, "Advanced", "HeavyHit", 70, Part)
				PlayOnRemoveSoundsManager(SFX.doomsday_missile_explosion, VFXPart)
			end

			for _,v in ipairs(particles) do
				v:Emit(v:GetAttribute("EmitCount"))
			end

		end,
	};
	["Excaliba"] = {
		["Start"] = function(Params)
			local Character = Params.Player
			local Player = game.Players:GetPlayerFromCharacter(Character)
			local HRP = Character:FindFirstChild("HumanoidRootPart")
			if not HRP then return end
			------------
			local FXFolder = (FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or FX.HarturiaDragon["Normal"]).Excaliba
			local SFX = FXFolder.Sounds

			-----ReciclandoXdddd
			local FXFolder2 = (FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or FX.HarturiaDragon["Normal"]).SlashBarrage
			local FXFolder3 = (FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or FX.HarturiaDragon["Normal"]).DoubleNote
			local SFX2 = FXFolder3.Sounds
			local SFXFolder2 = FXFolder2.Sounds
			-----
			local Anim = (Anims.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or Anims.HarturiaDragon["Normal"]).Excaliba
			local Grimoire = Character:FindFirstChild("GrimoireHandle")
			if Grimoire then
				Grimoire.GrimoireHandle.Part0 = HRP
			end
			ShakeCamera(Character, "Advanced", "Earthquake2", 60, HRP)
			local VfxPart2:Part = FXFolder.VfxPart2:Clone()
			VfxPart2.Parent = workspace.Fx
			VfxPart2.Weld.Part1 = HRP
			VfxPart2.Sparks.Enabled = true
			PlayAllFX(VfxPart2.wind1,true,true)
			local SwordAura
			local Highlight
			local Wind
			local Sword = Character:FindFirstChild("ServantSwordModel")
			task.delay(2.1,function()
				RockScript.CreateCrater(Character, HRP.Position, 60, 1.5, nil, nil, nil, 2, true, false, true, 0, 15)
				ShakeCamera(Character, "Advanced", "HeavyHit", 60, HRP)
				PlayAllFX(VfxPart2,true,false)
				PlayAllFX(VfxPart2.wind,true,true)
				for i,v in ipairs(FXFolder.MiniExplosion:GetChildren()) do
					local clone = v:Clone()
					clone.Parent = Character.Torso
					Debris:AddItem(clone,1)
				end
				PlayAllFX(Character.Torso)
				if not Sword or not Sword.Parent then return end
				SwordAura = FXFolder.SwordAura.Attachment:Clone()
				SwordAura.Parent = Sword.Handle
				Highlight = FXFolder.SwordAura.Highlight:Clone()
				Highlight.Parent = Sword
				Wind = FXFolder.SwordAura.Wind:Clone()
				Wind.Parent = Sword.Handle
				PlayAllFX(Wind)
			end)
			
			local Servant = Servants[Params.Shiny or "Harturia Dragon"]:Clone()
			Servant.Name = "ServantClone"
			Servant.Parent = Character
			Debris:AddItem(Servant,7)
			local SRP = Servant:FindFirstChild("HumanoidRootPart")
			if not SRP then return end
			SRP.Anchored = true
			local Part = Instancenew("Part",Character)
			Part.Massless = true
			Part.CanCollide = false
			Part.Transparency = 1
			Part.CastShadow = false
			Part.CFrame = HRP.CFrame+ HRP.CFrame.LookVector*7
			local weld = Instancenew("WeldConstraint",Part)
			weld.Part0 = HRP
			weld.Part1 = Part
			local oratt = Instancenew("Attachment",Part)
			oratt.Position = Vectornew(0, 0, -5)
			local att0 = Instancenew("Attachment", SRP)
			att0.Orientation = Vectornew(0, 90, 0)
			local att1 = Instancenew("Attachment", Part)


			local ap = Instancenew("AlignPosition")
			ap.Attachment0 = att0
			ap.Attachment1 = att1
			ap.MaxForce = 50000
			ap.Responsiveness = 100
			ap.Parent = HRP
			local ao = Instancenew("AlignOrientation")
			ao.AlignType = Enum.AlignType.PrimaryAxisLookAt
			ao.Attachment0 = att0
			ao.Attachment1 = oratt
			ao.MaxTorque = math.huge
			ao.MaxAngularVelocity = 100000
			ao.Responsiveness = 200
			ao.Parent = HRP
			HRP.Anchored = false
			HRP.AssemblyAngularVelocity = Vectornew()
			HRP.AssemblyLinearVelocity = Vectornew()
			SRP.CFrame = Part.CFrame
			SRP.Anchored = false
			local PlayerAnim = AnimationManager.GetTrack(Character.Humanoid.Animator,Anim.Player.Start)
			PlayerAnim:Play()
			local ServantAnim = Servant.Humanoid.Animator:LoadAnimation(Anim.Servant.Start)
			ServantAnim:Play()
			task.delay(1,function()
				PlaySlashFX(Servant, FXFolder2, PossibleOrientations3,"2")
				ShakeCamera(Character, "Advanced", "HeavyHit", 40, SRP)
				PlayRandomSound(SFXFolder2, "Slash", 3, SRP)
				PlayRandomSound(SFXFolder2, "W", 3, SRP)
				PlayOnRemoveSoundsManager(SFXFolder2.SlashStart2, SRP)
				RockScript.CreateCrater(Character, nil, 20, 1.2, nil, nil, nil, 0.9, true, false, true, 0, 4)
				task.wait(0.3)
				local Part2 = Instancenew("Part")
				Part2.Transparency = 1
				Part2.CanCollide = false
				Part2.Anchored = true
				Part2.CFrame = SRP.CFrame
				Part2.Parent = workspace.Fx
				Debris:AddItem(Part2,2)
				PlayOnRemoveSoundsManager(SFX2.Spawn, Part2)
				PlayOnRemoveSoundsManager(SFX2.Attack1, Part2)
				PlayOnRemoveSoundsManager(SFX2["big explosion"], Part2)
				local SpawnAttach = FXFolder3.ServantAttachs.Spawn:Clone()
				SpawnAttach.Parent = Part2
				PlayAllFX(SpawnAttach)
				if Sword then
					SpawnSword(Sword)
				end
				Servant:Destroy()
				ShakeCamera(Player, "Advanced", "HeavyHit", 60, Part2)
			end)
			
			
			if Sword then
				FXModule.SwordEffects(Sword, "DespawnEffects")
				for _, v in ipairs(Sword:GetChildren()) do
					if v:IsA("BasePart") then
						v.Transparency = 1
					end
				end
			end
			local SpawnAttach = FXFolder3.ServantAttachs.Spawn:Clone()
			SpawnAttach.Parent = SRP
			PlayAllFX(SpawnAttach)
			PlayOnRemoveSoundsManager(SFX2.Spawn, SRP)
			PlayOnRemoveSoundsManager(SFX2.Spawn2, SRP)
			PlayOnRemoveSoundsManager(SFX2.Spawn3, SRP)
			ShakeCamera(Character, "Advanced", "HeavyHit", 40, SRP)
			
			--Siguientes funciones
			PlayOnRemoveSoundsManager(SFX.Special.Hold1, HRP)
			PlayOnRemoveSoundsManager(SFX.Special.Charge, HRP)
			task.wait(5.1)
			for i,v in ipairs(FXFolder.MiniExplosion:GetChildren()) do
				local clone = v:Clone()
				clone.Parent = Character.Torso
				Debris:AddItem(clone,1.5)
			end
			PlayAllFX(Character.Torso)
			PlayAllFX(Wind)
			local swordAura:Part = FXFolder.Sword:Clone()
			swordAura.Parent = workspace.Fx
			swordAura.Sword.Part0 = Sword:FindFirstChild("Body")
			for i,v in ipairs(swordAura:GetDescendants()) do
				if v:IsA("ParticleEmitter") or v:IsA("Beam") then
					v.Enabled = true
				end
			end
			ShakeCamera(Character, "Advanced", "HeavyHit", 40, SRP)
			PlayOnRemoveSoundsManager(SFX.UltimateSound2, HRP)
			PlayOnRemoveSoundsManager(SFX.Special.Hold, HRP)
			PlayOnRemoveSoundsManager(SFX.Special.WindBurst2, HRP)
			task.wait(2.15)
			Wind:Destroy()
			SwordAura:Destroy()
			Highlight:Destroy()
			PlayAllFX(VfxPart2.wind,true,false)
			task.delay(1,function()
				VfxPart2:Destroy()
			end)
			
			
			PlayOnRemoveSoundsManager(SFX.Special.Stars, HRP)
			PlayOnRemoveSoundsManager(SFX.Special.PhotonCannon_AttackLaunch2, HRP)
			PlayOnRemoveSoundsManager(SFX.Special["Silent Glitcher - Server nuke charge"], HRP)
			Debris:AddItem(swordAura,2)
			for i,v in ipairs(swordAura:GetDescendants()) do
				if v:IsA("ParticleEmitter") or v:IsA("Beam") then
					v.Enabled = false
				end
			end
			
			
		end,
		["StartCamera"] = function(Params)
			local Character = Params.Character
			if not Character or not Character.Parent then return end

			local HRP = Character:FindFirstChild("HumanoidRootPart")
			if not HRP then return end

			local Camera = workspace.CurrentCamera

			
			local CinematicRig = SystemAssets.CinematicRig:Clone()
			CinematicRig.Parent = workspace:WaitForChild("Fx")

			local footOffset = CFrame.new(0, -4, 0)
			local backwardRotation = CFrame.Angles(0, math.rad(180), 0)
			CinematicRig:PivotTo(HRP.CFrame * footOffset * backwardRotation)

		
			local animSet = Anims.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal")
			if not animSet then
				animSet = Anims.HarturiaDragon:FindFirstChild("Normal")
			end

			local excaliba = animSet and animSet:FindFirstChild("Excaliba")
			local cinematicAnim = excaliba and excaliba:FindFirstChild("Cinematic")
			if not cinematicAnim then
				warn("No se encontró la animación Cinematic")
				return
			end

			local humanoid = CinematicRig:FindFirstChild("Humanoid")
			local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
			if not animator then
				warn("Animator no encontrado")
				return
			end
			
			local running = true
			local Anim = animator:LoadAnimation(cinematicAnim)
			Anim:Play()

			
			Camera.CameraType = Enum.CameraType.Scriptable
			Character:SetAttribute("InCinematic", true)

			
			task.spawn(function()
				while running and Character:GetAttribute("InCinematic") do
					task.wait()

					if not CinematicRig or not CinematicRig.Parent then break end
					local torso = CinematicRig:FindFirstChild("Torso")
					if not torso then break end
					local camPoint = torso:FindFirstChild("CameraPoint")
					if not camPoint then break end

					Camera.CFrame = camPoint.WorldCFrame
				end
			end)

			
			local function Cleanup()
				if not running then return end
				running = false
				Character:SetAttribute("InCinematic", nil)
				Camera.CameraType = Enum.CameraType.Custom

				if CinematicRig and CinematicRig.Parent then
					CinematicRig:Destroy()
				end
			end

			
			task.delay(15, Cleanup)


			Anim.Stopped:Connect(Cleanup)


			
		end,
		["HitEnemy"] = function(Params)
			local shiny = Params.Shiny or "Normal"
			local MainFolder = FX.HarturiaDragon:FindFirstChild(shiny) or FX.HarturiaDragon.Normal
			local AnimsMainFolder = Anims.HarturiaDragon:FindFirstChild(shiny) or Anims.HarturiaDragon.Normal
			local FXFolder = MainFolder.SlashBarrage
			local SFXFolder = FXFolder.Sounds
			local player = Params.Player
			if not player then return end

			local root = player:FindFirstChild("HumanoidRootPart")
			if not root then return end

			local humanoid = player:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end

			local animator = humanoid:FindFirstChildOfClass("Animator")
			if not animator then animator = humanoid end

			local anim = AnimsMainFolder.Excaliba
			local track = AnimationManager.GetTrack(animator,anim.Enemy.Start)
			track:Play()
			PlayRandomSound(SFXFolder, "W", 3, root)
			PlayRandomSound(SFXFolder, "Hit", 2, root)
			local PunchFX = FXFolder.HitFX.Part.HeavyPunch:Clone()
			PunchFX.Parent = player.Torso
			Debris:AddItem(PunchFX, 1.5)
			PlayAllFX(PunchFX)

		end,
		["Massive_Explosion"] = function(Params)
			local MainFolder = FX.HarturiaDragon:FindFirstChild(Params.Shiny or "Normal") or FX.HarturiaDragon["Normal"]
			local FXFolder = MainFolder.Excaliba
			local SFX = FXFolder.Sounds
			local Part = Params.Part
			local HRP = Part
			local Character = Params.Player
			local VFXPart = FXFolder.VFXpart:Clone()
			VFXPart.Parent = workspace.Fx
			VFXPart.CFrame = Part.CFrame
			VFXPart.Weld.Part1 = Part
			Debris:AddItem(VFXPart,5)
			PlayOnRemoveSoundsManager(SFX.Sharp, VFXPart)
			PlayOnRemoveSoundsManager(SFX.SuperExplosion, VFXPart)
			
			for _,v in ipairs(VFXPart:GetChildren()) do
				if v.Name == "Start" then
					v:Emit(v:GetAttribute("EmitCount"))
				end
			end

			local parts = {}
			local particles = {}
			
			for _,v in ipairs(VFXPart:GetChildren()) do
				if v:IsA("Part") then
					table.insert(parts, v)
				elseif v:IsA("ParticleEmitter") and v.Name ~= "Start" then
					table.insert(particles, v)
				end
			end


			VFXPart.Anchored = true
			for _,v in ipairs(particles) do
				v:Emit(70)
			end
			
			task.spawn(function()
				for _,v in ipairs(parts) do
					for i,b in ipairs(FXFolder.MiniExplosion:GetChildren()) do
						b:Clone().Parent = v
					end
					PlayOnRemoveSoundsManager(SFX.doomsday_missile_explosion, VFXPart)
					RockScript.CreateCrater(Character, v.Position+Vectornew(0,-2,0), 60, 4, nil, nil, nil, 6, true, false, true, 0, 60)
					ShakeCamera(Params.Player, "Advanced", "HeavyHit", 60, v)
					PlayOnRemoveSoundsManager(SFX.UltimateSound, v)
					PlayOnRemoveSoundsManager(SFX.UltimateSound2, v)
					PlayAllFX(v)
					task.wait(0.1)
				end
				table.clear(particles)
				table.clear(parts)
			end)

			task.wait(0.2)
			local firstExplosion:Model = FXFolder.FirstExplosion:Clone()
			Debris:AddItem(firstExplosion,3)
			firstExplosion.Anchored = true
			firstExplosion.Parent = workspace.Fx
			firstExplosion.CFrame = Params.SecondPart.CFrame * CFrame.new(0, -7, 0)
			local sizes = {
				Mesh1 = Vectornew(45.056, 21.436, 46.075),
				Mesh2 = Vectornew(76.176, 20.607, 84.195),
				Mesh3 = Vectornew(108.12, 17.813, 107.019),
				Mesh4 = Vectornew(89.382, 58.237, 93.107)
			}

			local duration = 0.4
			for name, targetSize in pairs(sizes) do
				local mesh = firstExplosion:FindFirstChild(name)
				local part = mesh and mesh.Parent  -- la parte donde está el mesh

				if mesh and part then
					local initialSize = mesh.Size
					local sizeChangeY = targetSize.Y - initialSize.Y
					local moveUp = sizeChangeY / 2

					local tweenMesh = TS:Create(
						mesh,
						TweenInfo.new(duration, Enum.EasingStyle.Linear),
						{ Size = targetSize, Transparency = 1 }
					)

					local tweenPart = TS:Create(
						part,
						TweenInfo.new(duration, Enum.EasingStyle.Linear),
						{ CFrame = part.CFrame * CFrame.new(0, moveUp, 0) }
					)

					tweenMesh:Play()
					tweenPart:Play()
				end
			end
			firstExplosion.Anchored = true
			PlayAllFX(firstExplosion,true,true)
			PlayOnRemoveSoundsManager(SFX.Special.Special, Params.SecondPart)
			if (LocalPlayer.Character.HumanoidRootPart.Position - Params.SecondPart.Position).Magnitude < 450 then
				local Lighting = game:GetService("Lighting")
				local Camera = workspace.CurrentCamera

				local cc = Camera:FindFirstChild("ExplosionCC") or Instancenew("ColorCorrectionEffect")
				cc.Name = "ExplosionCC"
				cc.Parent = Camera

				local at = Lighting:FindFirstChild("ExplosionAtmos") or Instancenew("Atmosphere")
				at.Name = "ExplosionAtmos"
				at.Parent = Lighting

				cc.Brightness = 0
				cc.Contrast = 0
				cc.Saturation = 0
				cc.TintColor = Color3.fromRGB(255,255,255)
				at.Density = 0

				local info1 = TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

				local t1 = TS:Create(cc, info1, {
					Brightness = -0.2,
					Contrast = 2,
					Saturation = -1,
					TintColor = Color3.fromRGB(255, 157, 0)
				})

				local t2 = TS:Create(at, info1, {
					Density = 0.55
				})

				t1:Play()
				t2:Play()

				t1.Completed:Connect(function()
					TS:Create(cc, TweenInfo.new(1), {
						Brightness = 0,
						Contrast = 0,
						Saturation = 0,
						TintColor = Color3.fromRGB(255,255,255)
					}):Play()

					TS:Create(at, TweenInfo.new(1), {
						Density = 0
					}):Play()

					task.wait(0.2)

					local info2 = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

					local t3 = TS:Create(cc, info2, {
						Brightness = -3,
						Contrast = 9,
						Saturation = -1.2,
						TintColor = Color3.fromRGB(255, 157, 0)
					})

					local t4 = TS:Create(at, info2, {
						Density = 0.55
					})

					t3:Play()
					t4:Play()

					t3.Completed:Connect(function()
						TS:Create(cc, TweenInfo.new(0.7), {
							Brightness = 0,
							Contrast = 0,
							Saturation = 0,
							TintColor = Color3.fromRGB(255,255,255)
						}):Play()

						TS:Create(at, TweenInfo.new(0.7), {
							Density = 0
						}):Play()
					end)
				end)
			end


			
			task.wait(1)
			PlayAllFX(firstExplosion,true,false)
			task.wait(0.3)
			PlayOnRemoveSoundsManager(SFX.Special.doomsday_missile_explosion, Params.SecondPart)
			PlayOnRemoveSoundsManager(SFX.Special.ShockIzuna, Params.SecondPart)
			PlayOnRemoveSoundsManager(SFX.Special["explosion sound effect"], Params.SecondPart)
			ShakeCamera(nil, "Advanced", "Explosion2", 450, Params.SecondPart)
			local secondExplosion:Model = FXFolder.SecondExplosion:Clone()
			secondExplosion.Anchored = true
			secondExplosion.Parent = workspace.Fx
			secondExplosion.CFrame = Params.SecondPart.CFrame * CFrame.new(0, -7, 0) * CFrame.Angles(0, 0, math.rad(90))
			RockScript.CreateCrater(Character, secondExplosion.Position, 120, 12, nil, nil, nil, 7, true, true, false, 0, 300)
			PlayAllFX(secondExplosion,true,true)
			for i,v in ipairs(secondExplosion:GetDescendants()) do
				if v:IsA("Beam") or v:IsA("PointLight") or v:IsA("SpotLight") then
					v.Enabled = true
				end
			end
			task.delay(6,function()
				for i,v in ipairs(secondExplosion:GetDescendants()) do
					if v:IsA("Beam") or v:IsA("PointLight") or v:IsA("SpotLight") then
						v.Enabled = false
					end
				end
				PlayAllFX(secondExplosion,true,false)
				task.wait(1)
				if secondExplosion then
					secondExplosion:Destroy()
				end
			end)

			local sizes = {
				Circle1 = Vectornew(115.445, 15.081, 115.445),
				Circle2 = Vectornew(164.658, 21.51, 164.658),
				Circle3 = Vectornew(82.826, 10.82, 82.826),
				Circle4 = Vectornew(571.099, 15.081, 484.878)
			}

			local duration = 2
			local order = { "Circle4","Circle2", "Circle3", "Circle1"}

			for i, name in ipairs(order) do
				local mesh = secondExplosion:FindFirstChild(name)
				if mesh then
				
						local tween = TS:Create(
							mesh,
							TweenInfo.new(duration, Enum.EasingStyle.Linear),
							{ Size = sizes[name], Transparency = 1 }
						)
						tween:Play()
				end
			end

		end,

	};
	
	----------------------LANCER SKILLSET
	-----------------------------------------------------------------------
	["Rotating Lance"] = {
		["Start"] = function(Params)
			local root = Params.Player.HumanoidRootPart
			local MainFolder = FX.KuShulan:FindFirstChild(Params.Shiny or "Normal") or FX.KuShulan["Normal"]
			local FXFolder = MainFolder.RotatingLance
			local SFXFolder = FXFolder.Sounds
			local Sparks = FXFolder.Sparks.Sparks

			local function createSpark(offset)
				local spark = Sparks:Clone()
				spark.Parent = root
				spark.Name = "SkillEffect"
				spark.Position = offset
				Debris:AddItem(spark, 3)
				return spark
			end

			local LeftSparks = createSpark(Vectornew(-2.192, -2.794, -2.124))
			local RightSparks = createSpark(Vectornew(2.364, -2.796, -2.217))

			local Sword = Params.Player:FindFirstChild("ServantSwordModel")
			if Sword then
				local SlashSparks = Sparks.Parent.Slashes:Clone()
				SlashSparks.Parent = Sword.Body
				SlashSparks.Name = "SkillEffect"
				Debris:AddItem(SlashSparks, 4)

				task.delay(1.17, function()
					PlayAllFX(SlashSparks, true, true)
					task.delay(1.73, function()
						PlayAllFX(SlashSparks, true, false)
					end)
				end)
			end

			task.delay(1.57, function()
				PlayAllFX(RightSparks, true, true)
				task.delay(0.21, function()
					PlayAllFX(RightSparks, true, false)
				end)
			end)

			task.delay(1.82, function()
				PlayAllFX(LeftSparks, true, true)
				task.delay(0.51, function()
					PlayAllFX(LeftSparks, true, false)
				end)
			end)

			task.delay(2.42, function()
				PlayAllFX(RightSparks, true, true)
				task.delay(0.25, function()
					PlayAllFX(RightSparks, true, false)
				end)
			end)

			PlayOnRemoveSoundsManager(SFXFolder["Air Dash (Fixed)"], root)
			PlayOnRemoveSoundsManager(SFXFolder["Dash"], root)
			PlayOnRemoveSoundsManager(SFXFolder["Wind Explosion"], root)

			CloneEffects(FXFolder.FirstKick, root, nil, true)
			ShakeCamera(nil, "Advanced", "HeavyHit", 40, root)

			local Attachment = Instancenew("Attachment")
			Attachment.Name = "SkillVelocityAttach"
			Attachment.Parent = root

			task.delay(0.1, function()
				local LV = Instancenew("LinearVelocity")
				LV.Attachment0 = Attachment
				LV.ForceLimitMode = Enum.ForceLimitMode.PerAxis
				LV.MaxAxesForce = Vectornew(0,0,25000)
				LV.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
				LV.VectorVelocity = Vectornew(0,0,-550)
				LV.Parent = Attachment

				task.wait(0.03)

				task.delay(3.8, function()
					if Attachment then Attachment:Destroy() end
				end)

				LV:Destroy()

				if Params.Player:GetAttribute("Stunned") then return end

				local LV2 = Instancenew("LinearVelocity")
				LV2.Attachment0 = Attachment
				LV2.ForceLimitMode = Enum.ForceLimitMode.PerAxis
				LV2.MaxAxesForce = Vectornew(0,0,25000)
				LV2.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
				LV2.VectorVelocity = Vectornew(0,0,-80)
				LV2.Parent = Attachment
			end)

			
		end,

		["Slash"] = function(Params)
			local MainFolder = FX.KuShulan:FindFirstChild(Params.Shiny or "Normal") or FX.KuShulan["Normal"]
			local FXFolder = MainFolder.RotatingLance
			local SFXFolder = FXFolder.Sounds
			local player = Params.Player
			local root = player.HumanoidRootPart
			
			local OrientationList = {
				Vectornew(8.826, -57.464, -176.29),
				Vectornew(37.555, -84.76, 15.89),
				Vectornew(44.459, -113.311, 160.797),
			}
			local Ground, Up = PlaySlashFX(player, FXFolder, nil)
			Up.Orientation = OrientationList[Params.SlashNumber or 3]
			ShakeCamera(player, "Advanced", "HeavyHit", 40, root)

			PlayRandomSound(SFXFolder, "Slash", 3, root)
			PlayRandomSound(SFXFolder, "W", 3, root)
			PlayOnRemoveSoundsManager(SFXFolder.SlashStart2, root)

			RockScript.CreateCrater(player, nil, 20, 1.2, nil, nil, nil, 0.9, true, false, true, 0, 4)
		end,
		["Barrage"] = function(Params)
			local MainFolder = FX.KuShulan:FindFirstChild(Params.Shiny or "Normal") or FX.KuShulan["Normal"]
			local FXFolder = MainFolder.RotatingLance
			local SFXFolder = FXFolder.Sounds
			local player = Params.Player
			local root = player.HumanoidRootPart


			PlayRandomSound(SFXFolder, "Slash", 3, root)
			PlayRandomSound(SFXFolder, "W", 3, root)
			PlayOnRemoveSoundsManager(SFXFolder.SlashStart2, root)
		end,

		["SuperSlash"] = function(Params)
			local MainFolder = FX.KuShulan:FindFirstChild(Params.Shiny or "Normal") or FX.KuShulan["Normal"]
			local FXFolder = MainFolder.RotatingLance
			local SFXFolder = FXFolder.Sounds
			local player = Params.Player
			local root = player.HumanoidRootPart

			local Ground, Up2 = PlaySlashFX(player, FXFolder, nil,"2")

			ShakeCamera(nil, "Advanced", "HeavyHit", 40, root)

			PlayOnRemoveSoundsManager(SFXFolder.Explosion1, root)
			PlayOnRemoveSoundsManager(SFXFolder.Explosion2, root)

			RockScript.CreateCrater(player, nil, 30, 1.8, nil, nil, nil, 0.9, true, false, true, 50, 12)
		end,
		["Hit"] = function(Params)
			local MainFolder = FX.KuShulan:FindFirstChild(Params.Shiny or "Normal") or FX.KuShulan["Normal"]
			local AnimsMainFolder = Anims.HarturiaDragon.Normal
			local FXFolder = MainFolder.RotatingLance
			local SFXFolder = FXFolder.Sounds
			local player = Params.Player
			if not player then return end
			local root = player:FindFirstChild("HumanoidRootPart")
			if not root then return end
			local humanoid = player:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end

			local animator = humanoid:FindFirstChildOfClass("Animator")
			if not animator then animator = humanoid end

			local anim = AnimsMainFolder.SwordTurret
			local track = AnimationManager.GetTrack(animator,anim.Enemy["Start"..math.random(1,2)])
			track:Play()
			PlayRandomSound(SFXFolder, "W", 3, root)
			PlayRandomSound(SFXFolder, "Hit", 2, root)
			local PunchFX = FXFolder.HitFX.Part.HeavyPunch:Clone()
			PunchFX.Parent = player.Torso
			Debris:AddItem(PunchFX,1.5)
			PlayAllFX(PunchFX)
		end,
	};
	["Lance Barrage"] = {
		["Start"] = function(Params)
			local HRP = Params.Player.HumanoidRootPart
			local Character = Params.Player
			local skillActive = Character:GetAttribute("SkillName") == "Lance Barrage"
			if not HRP or not skillActive then return end

			local MainFolder = FX.KuShulan:FindFirstChild(Params.Shiny or "Normal") or FX.KuShulan.Normal
			local FXFolder = MainFolder.LanceBarrage
			local SFXFolder = FXFolder.Sounds

			local Barrage = FXFolder.LanceBarrage:Clone()
			Barrage.Name = "SkillEffect"
			Barrage.Parent = HRP
			Barrage.Weld.Part1 = HRP
			Debris:AddItem(Barrage, 4)

			local Sound3 = SFXFolder.Sound2:Clone()
			local Sound1 = SFXFolder.Machinegun:Clone()
			local Sound2 = SFXFolder.Sound:Clone()

			Sound1.Name = "SkillEffect"
			Sound2.Name = "SkillEffect"
			Sound3.Name = "SkillEffect"

			Sound3.Parent = HRP
			Sound1.Parent = HRP
			Sound2.Parent = HRP

			ShakeCamera(Character, "Simple", "HeavyHit")
			Sound3:Play()


			task.delay(0.93, function()
				if not Character or Character:GetAttribute("SkillName") ~= "Lance Barrage" then return end

				task.spawn(function()
					MultiPunchVFX(2.65, 60, Character, HRP)
				end)

				ShakeCamera(nil, "Advanced", "Explosion2", 30, HRP, 3)

				Sound1:Play()
				Sound2:Play()
				PlayAllFX(Barrage, true, true)
			end)


			task.delay(3.58, function()
				if not HRP or not Barrage or Character:GetAttribute("SkillName") ~= "Lance Barrage" then return end

				Sound1:Stop()
				Sound2:Stop()
				Sound3:Stop()

				PlayAllFX(Barrage, true, false)

				local Slice = FXFolder.Attach.Slice:Clone()
				Slice.Parent = Barrage

				PlayAllFX(Barrage:FindFirstChild("Wind"))
				PlayAllFX(Slice)

				PlayOnRemoveSoundsManager(SFXFolder.Cannon, HRP)
				PlayOnRemoveSoundsManager(SFXFolder.Explosion2, HRP)
				ShakeCamera(nil, "Advanced", "HeavyHit", 30, HRP, 3)
				RockScript.CreateCrater(Character, nil, 30, 1.2, nil, nil, nil, 0.9, true, false, true, 0, 4)
			end)


		end,

	};
	["Spear Of God"] = {
		["Start"] = function(Params)
			local EnRootP = Params.Player:FindFirstChild("HumanoidRootPart")
			if not EnRootP then return end
			local MainFolder = FX.KuShulan:FindFirstChild(Params.Shiny or "Normal") or FX.KuShulan["Normal"]
			local FXFolder = MainFolder.SpearOfGod
			local AnimsMainFolder = Anims.KuShulan:FindFirstChild(Params.Shiny or "Normal") or Anims.KuShulan["Normal"]
			local SFX = FXFolder.Sounds
			local FXFolder = MainFolder.SpearOfGod
			local Animator = Params.Player.Humanoid.Animator
			local StartAnim = AnimationManager.GetTrack(Animator,AnimsMainFolder.SpearOfGod.Player.Charge.Start)
			StartAnim:Play()
			task.delay(.85,function()
				StartAnim:Stop()
			end)
		end,
		["Jump"] = function(Params)
			local EnRootP = Params.Player:FindFirstChild("HumanoidRootPart")
			if not EnRootP then return end
			local MainFolder = FX.KuShulan:FindFirstChild(Params.Shiny or "Normal") or FX.KuShulan["Normal"]
			local FXFolder = MainFolder.SpearOfGod
			local AnimsMainFolder = Anims.KuShulan:FindFirstChild(Params.Shiny or "Normal") or Anims.KuShulan["Normal"]
			local SFX = FXFolder.Sounds
			local Animator = Params.Player.Humanoid.Animator
			
				local StartAnim = AnimationManager.GetTrack(Animator,AnimsMainFolder.SpearOfGod.Player.Jumping.Start)
				StartAnim:Play()
				local Part = Instancenew("Part",workspace.Fx)
				Debris:AddItem(Part,3)
				Part.CFrame = EnRootP.CFrame
				Part.Anchored = true
				Part.CastShadow = false
				Part.CanCollide = false
				Part.CanQuery = false
				Part.Transparency = 1
				local AuraFX = FXFolder.Aura.HoldEffectToDestroy:Clone()
				AuraFX.Parent = Part
				task.delay(0.365,function()
					PlayAllFX(AuraFX)
					ShakeCamera(Params.Player, "Advanced", "HeavyHit",40,Part)
					PlayOnRemoveSoundsManager(SFX.Explosion,EnRootP)
					PlayOnRemoveSoundsManager(SFX.Teleport,EnRootP)
					RockScript.CreateCrater(nil, Part.Position, 40, 1.2, nil, nil, nil, 2, true, true, true, 0, 12)
					task.delay(0.1,function()
						local StartAnim = AnimationManager.GetTrack(Animator,AnimsMainFolder.SpearOfGod.Player.Aiming.Loop)
						StartAnim:Play()
					end)
				end)

		end,
		["Dive"] = function(Params)
			local EnRootP = Params.Player:FindFirstChild("HumanoidRootPart")
			if not EnRootP then return end
			local MainFolder = FX.KuShulan:FindFirstChild(Params.Shiny or "Normal") or FX.KuShulan["Normal"]
			local FXFolder = MainFolder.SpearOfGod
			local SFX = FXFolder.Sounds
			local Part = Instancenew("Part",workspace.Fx)
			local AnimsMainFolder = Anims.KuShulan:FindFirstChild(Params.Shiny or "Normal") or Anims.KuShulan["Normal"]
			local Animator = Params.Player.Humanoid.Animator
			Debris:AddItem(Part,3)
			Part.CFrame = EnRootP.CFrame
			Part.Orientation = Params.Player.Head.Orientation
			Part.Anchored = true
			Part.CastShadow = false
			Part.CanCollide = false
			Part.CanQuery = false
			Part.Transparency = 1
			local AuraFX = FXFolder.Aura.SkillCastAttachment:Clone()
			AuraFX.Parent = Part
			local StartAnim = AnimationManager.GetTrack(Animator,AnimsMainFolder.SpearOfGod.Player.Impulse.Start)
			StartAnim:Play()
			task.wait(0.45)
			local DiveFx = FXFolder.Dive:Clone()
			DiveFx.Name = "SkillEffect"
			DiveFx.Parent = EnRootP
			PlayAllFX(DiveFx,true,true)
			StartAnim:Stop()
			local StartAnim2 = AnimationManager.GetTrack(Animator,AnimsMainFolder.SpearOfGod.Player.Impulse.Loop)
			StartAnim2:Play()
			PlayAllFX(AuraFX)
			ShakeCamera(Params.Player, "Advanced", "HeavyHit",40,Part)
			PlayOnRemoveSoundsManager(SFX.Shot,EnRootP)
			PlayOnRemoveSoundsManager(SFX.BigExplosion,EnRootP)
		end,
		["Charge"] = function(Params)
			local MainFolder = FX.KuShulan:FindFirstChild(Params.Shiny or "Normal") or FX.KuShulan["Normal"]
			local FXFolder = MainFolder.SpearOfGod
			local SFX = FXFolder.Sounds
			local HRP = Params.Player:FindFirstChild("HumanoidRootPart")
			if not HRP then return end
			PlayOnRemoveSoundsManager(SFX.Punch,HRP)
			local AuraFX = HRP:FindFirstChild("SkillEffect") or FXFolder.Aura.SkillEffect:Clone()
			ShakeCamera(Params.Player, "Simple", "HeavyHit")
			if Params.Charge == 1 then
				AuraFX.Parent = HRP
				EmitCharge(AuraFX,5)
			elseif Params.Charge == 2 then
				EmitCharge(AuraFX,20)
			elseif Params.Charge > 2 then
				EmitCharge(AuraFX,40)
			end
		end,
		["Explosion"] = function(Params)
			local EnRootP = Params.Player:FindFirstChild("HumanoidRootPart")
			if not EnRootP then return end
			local MainFolder = FX.KuShulan:FindFirstChild(Params.Shiny or "Normal") or FX.KuShulan["Normal"]
			local FXFolder = MainFolder.SpearOfGod
			local AnimsMainFolder = Anims.KuShulan:FindFirstChild(Params.Shiny or "Normal") or Anims.KuShulan["Normal"]
			local SFX = FXFolder.Sounds
			local Animator = Params.Player.Humanoid.Animator
			PlayOnRemoveSoundsManager(SFX.GroundSmash,EnRootP)

			ShakeCamera(Params.Player, "Advanced", "HeavyHit",Params.Size+10,EnRootP)
			RockScript.CreateCrater(nil, EnRootP.Position, Params.Size, 3, nil, nil, nil, 2, true, false, true, 0, 24)
			if Params.Anim then
				local StartAnim = AnimationManager.GetTrack(Animator,AnimsMainFolder.SpearOfGod.Player.Connected.Failed)
				StartAnim:Play()
			end
		end,
		["Connected"] = function(Params)
			local Player = Params.Player
			local PlayerRootPart = Player:FindFirstChild("HumanoidRootPart")
			local EnRootP = Params.Enemy:FindFirstChild("HumanoidRootPart")
			if not EnRootP or not PlayerRootPart then return end
			local MainFolder = FX.KuShulan:FindFirstChild(Params.Shiny or "Normal") or FX.KuShulan["Normal"]
			local FXFolder = MainFolder.SpearOfGod
			local AnimsMainFolder = Anims.KuShulan:FindFirstChild(Params.Shiny or "Normal") or Anims.KuShulan["Normal"]
			local SFX = FXFolder.Sounds
			--
			local Animator = Player.Humanoid.Animator
			local Animator2 = Params.Enemy.Humanoid.Animator
			SetCameraSubject(Player, Player.Head)
			local StartAnim = AnimationManager.GetTrack(Animator,AnimsMainFolder.SpearOfGod.Player.Connected.Connected)
			StartAnim:Play()
			local StartAnim2 = AnimationManager.GetTrack(Animator2,AnimsMainFolder.SpearOfGod.Enemy.Connected)
			StartAnim2:Play()
			
			local Slash1 = FXFolder.EHRP:Clone()
			Slash1.Parent = EnRootP
			Debris:AddItem(Slash1,4)
			local Spins = FXFolder.RightArm:Clone()
			Spins.Parent = Player["Right Arm"]
			Debris:AddItem(Spins,4)
			local Uppercut = FXFolder.HRP:Clone()
			Uppercut.Parent = PlayerRootPart
			Debris:AddItem(Uppercut,4)
			local Uppercut2 = FXFolder.HRP2:Clone()
			Uppercut2.Parent = PlayerRootPart
			Debris:AddItem(Uppercut2,4)
			
			PlayAllFX(Slash1)
			PlayOnRemoveSoundsManager(SFX.Punch1,PlayerRootPart)
			PlayOnRemoveSoundsManager(SFX.Epic,PlayerRootPart)
			task.delay(0.68,function()
				PlayAllFX(Spins,true,true)
				ShakeCamera(Params.Player, "Advanced", "Explosion",40,PlayerRootPart)
				PlayOnRemoveSoundsManager(SFX.Spinning,Player.Torso)
				task.delay(0.95,function()
					PlayAllFX(Spins,true,false)
				end)
			end)
			task.delay(2.55,function()
				Slash1.Orientation = Vectornew(87.718, -1.194, -178.806)
				PlayAllFX(Slash1)
				ShakeCamera(Params.Player, "Simple", "HeavyHit")
				PlayOnRemoveSoundsManager(SFX.Punch2,PlayerRootPart)
			end)
			
			task.delay(3.08,function()
				PlayAllFX(Uppercut)
				PlayOnRemoveSoundsManager(SFX.Uppercut,EnRootP)
				ShakeCamera(Params.Player, "Advanced", "HeavyHit",50,PlayerRootPart)
				task.delay(0.1,function()
					RockScript.CreateCrater(nil, PlayerRootPart.Position, 40, 1.2, nil, nil, nil, 2, true, true, true, 0, 12)
					PlayAllFX(Uppercut2)
					PlayOnRemoveSoundsManager(SFX.GroundSmash,EnRootP)
				end)
			end)
		end,
	};
	
	----------------------Sasako SKILLSET
	-----------------------------------------------------------------------
	["Gyroscope Attack"] = {
		["Start"] = function(Params)
			local EnRootP = Params.Player:FindFirstChild("HumanoidRootPart")
			if not EnRootP then return end
			local MainFolder = FX.Sasako:FindFirstChild(Params.Shiny or "Normal") or FX.Sasako["Normal"]
			local FXFolder = MainFolder.GyroscopeAttack
			local AnimsMainFolder = Anims.Sasako:FindFirstChild(Params.Shiny or "Normal") or Anims.Sasako["Normal"]
			local SFX = FXFolder.Sounds
			local Animator = Params.Player.Humanoid.Animator
			
			local VFXPart = Instancenew("Part",workspace.Fx)
			VFXPart.Transparency = 1
			VFXPart.CanCollide = false
			VFXPart.CanQuery = false
			VFXPart.CastShadow = false
			VFXPart.Anchored = true
			VFXPart.CFrame = EnRootP.CFrame
			Debris:AddItem(VFXPart,2)
			
			SetCameraSubject(Params.Player, Params.Player.Head)
			local StartAnim = AnimationManager.GetTrack(Animator,AnimsMainFolder.GyroscopeAttack.Player.Start)
			StartAnim:Play()
			
			task.wait(0.7)
			local Dash = FXFolder.Dash:Clone()
			Dash.Parent = VFXPart
			local Dash2 = FXFolder.Batch:Clone()
			Dash2.Parent = VFXPart
			PlayOnRemoveSoundsManager(SFX.Laser,VFXPart)
			PlayOnRemoveSoundsManager(SFX.GroundSmash,VFXPart)
			PlayAllFX(Dash)
			PlayAllFX(Dash2)
		end,
		["Slash"] = function(Params)
			local EnRootP = Params.Player:FindFirstChild("HumanoidRootPart")
			if not EnRootP then return end
			local MainFolder = FX.Sasako:FindFirstChild(Params.Shiny or "Normal") or FX.Sasako["Normal"]
			local FXFolder = MainFolder.GyroscopeAttack
			local AnimsMainFolder = Anims.Sasako:FindFirstChild(Params.Shiny or "Normal") or Anims.Sasako["Normal"]
			local SFX = FXFolder.Sounds
			local Animator = Params.Player.Humanoid.Animator
			
			if Params.Connected then
				local Animator2 = Params.Connected:FindFirstChild("Animator") or Params.Connected
				if not Animator2 then return end
				local StartAnim = AnimationManager.GetTrack(Animator2,AnimsMainFolder.GyroscopeAttack.Enemy.Connected)
				StartAnim:Play()

				local StartAnim2 = AnimationManager.GetTrack(Animator,AnimsMainFolder.GyroscopeAttack.Player.Connected)
				StartAnim2:Play()
				task.delay(0.4,function()
					local Slashes = FXFolder.Slashes:Clone()
					Slashes.Parent = Params.Connected.Parent.Torso
					Debris:AddItem(Slashes,2)
					local Explosion = FXFolder.Explosion:Clone()
					Explosion.Parent = Params.Connected.Parent.Torso
					Debris:AddItem(Explosion,2)
					PlayAllFX(Slashes,true,true)
					PlayOnRemoveSoundsManager(SFX.Slashes,EnRootP)
					task.delay(0.42,function()
						PlayAllFX(Slashes,true,false)
						PlayAllFX(Explosion)
					end)
				end)
				task.delay(1.2,function()
					local Slash = FXFolder.EHRP:Clone()
					Slash.Parent = EnRootP
					Debris:AddItem(Slash,1)
					PlayAllFX(Slash)
					ShakeCamera(Params.Player, "Simple", "HeavyHit")
					PlayOnRemoveSoundsManager(SFX.Swing,EnRootP)
				end)
			else
				local StartAnim = AnimationManager.GetTrack(Animator,AnimsMainFolder.GyroscopeAttack.Player.Failed)
				StartAnim:Play()
			end
		end,
	};
	["Thousand Slashes"] = {
		["Start"] = function(Params)
			local EnRootP = Params.Player:FindFirstChild("HumanoidRootPart")
			if not EnRootP then return end
			local MainFolder = FX.Sasako:FindFirstChild(Params.Shiny or "Normal") or FX.Sasako["Normal"]
			local FXFolder = MainFolder.ThousandSlashes
			local AnimsMainFolder = Anims.Sasako:FindFirstChild(Params.Shiny or "Normal") or Anims.Sasako["Normal"]
			local SFX = FXFolder.Sounds
			local Animator = Params.Player.Humanoid.Animator
			
			local StartAnim:AnimationTrack = AnimationManager.GetTrack(Animator,AnimsMainFolder.ThousandSlashes.Start)
			StartAnim:Play()
			
			local OrientTable = {
				Vectornew(5.068, -16.721, -30.965),
				Vectornew(-13.971, -60.34, -11.761),
				Vectornew(0.035, -10.591, 6.143),
			}
			local CurrentSlash = 1
			
			local Slash = FXFolder.ThousandSlashesSlash:Clone()
			Slash.Parent = EnRootP
			local Slashes = FXFolder.Slashes:Clone()
			Slashes.Parent = workspace.Fx
			Slashes.Weld.Part0 = EnRootP
			local function PlaySlash()
				Slash.Orientation = OrientTable[CurrentSlash]
				PlayAllFX(Slashes,nil,nil,{A1 = true})
				PlayAllFX(Slash)
				PlayOnRemoveSoundsManager(SFX.Swing,EnRootP)
				PlayOnRemoveSoundsManager(SFX.SlashStart2,EnRootP)
				ShakeCamera(Params.Player, "Simple", "HeavyHit")
				task.delay(0.3,function()
					PlayOnRemoveSoundsManager(SFX.Slashes,EnRootP)
					PlayOnRemoveSoundsManager(SFX.Explosion,EnRootP)
					PlayAllFX(Slashes.A1)
					ShakeCamera(Params.Player, "Advanced", "HeavyHit",40,Slashes)
					RockScript.CreateCrater(nil, Slashes.Position, 30, 1.2, nil, nil, nil, 2, true, true, true, 0, 12)
				end)
				CurrentSlash += 1
			end
			
			local Con
			local Con2
			local function Disconnect()
				if Con  then
					Con:Disconnect()
				end
				if Con2  then
					Con2:Disconnect()
				end
			end
			Con = StartAnim:GetMarkerReachedSignal("Slash"):Connect(function()
				PlaySlash()
			end)
			Con2 = StartAnim.Stopped:Once(function()
				Disconnect()
			end)
			task.delay(6,function()
				Disconnect()
			end)

		end,
		["HitEnemy"] = function(Params)
			local shiny = Params.Shiny or "Normal"
			local MainFolder = FX.Sasako:FindFirstChild(shiny) or FX.Sasako.Normal
			local AnimsMainFolder = Anims.Sasako:FindFirstChild(shiny) or Anims.Sasako.Normal
			local FXFolder = MainFolder.ThousandSlashes
			local SFXFolder = FXFolder.Sounds
			local player = Params.Player
			if not player then return end

			local root = player:FindFirstChild("HumanoidRootPart")
			if not root then return end

			local humanoid = player:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end

			local animator = humanoid:FindFirstChildOfClass("Animator")
			if not animator then animator = humanoid end

			local anim = AnimsMainFolder.ThousandSlashes
			local track = AnimationManager.GetTrack(animator,anim.Enemy["Start"..math.random(1,2)])
			track:Play()
			PlayRandomSound(SFXFolder, "W", 3, root)
			PlayRandomSound(SFXFolder, "Hit", 2, root)
			local PunchFX = FXFolder.HitFX.Part.HeavyPunch:Clone()
			PunchFX.Parent = player.Torso
			Debris:AddItem(PunchFX, 1.5)
			PlayAllFX(PunchFX)

		end,
	};
	
	
	----------------------BASIC COMBAT SKILLSET
	-----------------------------------------------------------------------
	["Iron Fist"] = {
		["Start"] = function(Params)
			local Player = Params.Player
			local PlayerRootPart = Player:FindFirstChild("HumanoidRootPart")
			if not PlayerRootPart then return end
			local MainFolder = FX.BasicCombat:FindFirstChild(Params.Shiny or "Normal") or FX.BasicCombat["Normal"]
			local FXFolder = MainFolder.IronFist
			local AnimsMainFolder = Anims.BasicCombat:FindFirstChild(Params.Shiny or "Normal") or Anims.BasicCombat["Normal"]
			local SFX = FXFolder.Sounds
			local Animator = Player.Humanoid.Animator
			
			
			local StartAnim = AnimationManager.GetTrack(Animator,AnimsMainFolder.IronFist.Player.Start)
			StartAnim:Play()
			PlayOnRemoveSoundsManager(SFX.Air1,PlayerRootPart)
		end,
		["Connected"] = function(Params)
			local Player = Params.Player
			local Enemy = Params.Enemy
			local PlayerRootPart = Player:FindFirstChild("HumanoidRootPart")
			local EnRootP = Enemy:FindFirstChild("HumanoidRootPart")
			if not EnRootP or not PlayerRootPart then return end
			local MainFolder = FX.BasicCombat:FindFirstChild(Params.Shiny or "Normal") or FX.BasicCombat["Normal"]
			local FXFolder = MainFolder.IronFist
			local AnimsMainFolder = Anims.BasicCombat:FindFirstChild(Params.Shiny or "Normal") or Anims.BasicCombat["Normal"]
			local SFX = FXFolder.Sounds
			
			--
			local Animator = Player.Humanoid.Animator
			local Animator2 = Enemy:FindFirstChild("Humanoid") and Enemy.Humanoid:FindFirstChild("Animator") or Enemy:FindFirstChild("Humanoid")
			if not Animator or not Animator2 then return end
			
			local StartAnim = AnimationManager.GetTrack(Animator,AnimsMainFolder.IronFist.Player.Connected)
			StartAnim:Play()
			local StartAnim2 = AnimationManager.GetTrack(Animator2,AnimsMainFolder.IronFist.Enemy.Connected)
			StartAnim2:Play()
			local Punch = FXFolder.Punch:Clone()
			Debris:AddItem(Punch,2)
			Punch.Parent = Params.Enemy:FindFirstChild("Head")
			task.spawn(function()
				local function PunchFX(sound)
					PlayAllFX(Punch)
					ShakeCamera(Params.Player, "Simple", "HeavyHit")
					PlayOnRemoveSoundsManager(SFX.Air, EnRootP)
					PlayOnRemoveSoundsManager(sound, EnRootP)
				end

				task.wait(0.07)
				PunchFX(SFX.Punch1)

				task.wait(0.25)
				PunchFX(SFX.Punch2)

				task.wait(0.44)
				Punch.Parent = Enemy.Torso
				RockScript.CreateCrater(
					nil,
					PlayerRootPart.Position,
					12, 1,
					nil, nil, nil,
					2, true, true, true,
					0, 12
				)
				PunchFX(SFX.Uppercut)
			end)

		end,
	};
	["Burst Dash"] = {
		["Start"] = function(Params)
			local Player = Params.Player
			local PlayerRootPart = Player:FindFirstChild("HumanoidRootPart")
			if not PlayerRootPart then return end
			local MainFolder = FX.BasicCombat:FindFirstChild(Params.Shiny or "Normal") or FX.BasicCombat["Normal"]
			local FXFolder = MainFolder.BurstDash
			local AnimsMainFolder = Anims.BasicCombat:FindFirstChild(Params.Shiny or "Normal") or Anims.BasicCombat["Normal"]
			local SFX = FXFolder.Sounds
			local Animator = Player.Humanoid.Animator
			
			local StartParticles = FXFolder.Start:Clone()
			StartParticles.Parent = PlayerRootPart
			Debris:AddItem(StartParticles,2)
			local StartParticles2 = FXFolder.Loop:Clone()
			StartParticles2.Parent = PlayerRootPart
			Debris:AddItem(StartParticles2,2)
			
			task.delay(0.25,function()
				PlayAllFX(StartParticles2,true,true)
				task.delay(0.58,function()
					PlayAllFX(StartParticles2,true,false)
				end)
				RockScript.CreateCrater(nil,PlayerRootPart.Position,20, 1,nil, nil, nil,2, true, true, true,0, 12)
				ShakeCamera(Params.Player, "Advanced", "HeavyHit",20,PlayerRootPart)
				PlayOnRemoveSoundsManager(SFX.GroundSmash,PlayerRootPart)
				PlayAllFX(StartParticles)
			end)

			local StartAnim = AnimationManager.GetTrack(Animator,AnimsMainFolder.BurstDash.Start)
			StartAnim:Play()
			
		end,
	};
}

return module
