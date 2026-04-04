--Servicios
local RS = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Modules = RS:WaitForChild("Modules")
--Modulos
local RockScript = require(Modules:WaitForChild("CraterModule"))
local ShakeModule = require(Modules:WaitForChild("CameraFX"))
local AnimationManager = require(Modules:WaitForChild("MysterysAnimationManager"))
--Requerimientos y cosas extra
local SystemAssets = RS:WaitForChild("SystemAssets")
local LevelUPFXFolder = SystemAssets:WaitForChild("LevelUpSystem"):WaitForChild("FX")
local AuraSt = SystemAssets:WaitForChild("ChargeSystem"):WaitForChild("AuraStorage")
local AllGrimoireStorage = SystemAssets:WaitForChild("GrimoireSystem")
local AllGrimoireEffects = AllGrimoireStorage:WaitForChild("Effects")
local GrimoiresStorage = AllGrimoireStorage:WaitForChild("Grimoires")
local AllSwordsStorage = SystemAssets:WaitForChild("SwordSystem")
local SwordsStorage = AllSwordsStorage:WaitForChild("SwordsStorage")
local AllSwordsEffects = AllSwordsStorage:WaitForChild("Effects")
local EnemyStorage = SystemAssets:WaitForChild("EnemysStorage")

local AttackFolder = SystemAssets:WaitForChild("CombatSystem"):WaitForChild("FX")
local AllAnimsFolder = AttackFolder.Parent:WaitForChild("Animations")
local VFXFolder = AttackFolder:WaitForChild("SlashVFX")
local GVFXFolder = AttackFolder:WaitForChild("WindVFX")
local SFXFolder = AttackFolder:WaitForChild("SFX")
local AllHFX = AttackFolder:WaitForChild("HitFX")
--
local ChestsStorage = SystemAssets:WaitForChild("ChestsSystem")
local ChestAnims = ChestsStorage:WaitForChild("Anims")
local ChestFX = ChestsStorage:WaitForChild("FX")
local FXModule = {}

--Funcion para parar animaciones
function FXModule.stopAnimations(animNames,chr)
	if chr and chr:FindFirstChild("Humanoid") and chr.Humanoid:FindFirstChild("Animator") then
		for _, animTrack in pairs(chr.Humanoid.Animator:GetPlayingAnimationTracks()) do
			if table.find(animNames, animTrack.Name) then
				animTrack:Stop()
				animTrack:Destroy()
			end
		end
	end
end


-----------------------------------------------------
function FXModule.CreateCrater(Char,PositionR,RadiusR,RockSize,UGM,DC,DM,TBR,DFD,CFD,HD,RSI,MP)
	if Char and not Char:FindFirstChild("Torso") then return end
	local UpdatedSettings = {
		useGroundMaterial = UGM,
		debrisColor = DC,
		debrisMaterial = DM,
		timeBeforeRemoval = TBR,
		doFlyingDebris = DFD,
		centerFlyingDebris = CFD,
		hasDust = HD,
		rockSkipInterval = RSI,
		MaxParts = MP
	}
	RockScript:UpdateSettings(UpdatedSettings)
	RockScript.formCrater({
		Position = PositionR or Char.Torso.Position;
		Radius = RadiusR or 10;
		rockSize = RockSize or 2.5;
	})
end
------------------------------------------


--Grimoires
function FXModule.GrimoireEffects(Grimoire,Type)
	local EffectData = AllGrimoireEffects:FindFirstChild(Grimoire.Effects.Value)
	if not EffectData then return end
	local Part = Instance.new("Part")
	Part.Name = "GrimoireEffect"
	Part.Transparency = 1
	Part.CanCollide = false
	Part.Anchored = true
	Part.CFrame = Grimoire.CFrame
	Part.Parent = workspace.Fx
	local TypeData = EffectData:FindFirstChild(Type)
	if TypeData then
		for _, particle in pairs(TypeData:GetChildren()) do
			local Clone = particle:Clone()
			Clone.Parent = Part
			if Clone:IsA("ParticleEmitter") then
				local emitCount = Clone:GetAttribute("EmitCount")
				if emitCount then
					Clone:Emit(emitCount)
				end
			elseif Clone:IsA("Sound") then
				Clone:Play()
			end
		end
	end
	task.delay(2, function()
		Part:Destroy()
	end)
end

function FXModule.GrimoireReplicate(RequestedGrimoire,Type,Plr)
	local Character = Plr.Character or Plr.CharacterAdded:Wait()
	if Type == "Equip" then
		local Hrp = Character:FindFirstChild("HumanoidRootPart")
		if not Hrp then return end
		local Grimoire = GrimoiresStorage:FindFirstChild(RequestedGrimoire):FindFirstChild("GrimoireHandle"):Clone()
		if not Grimoire then return end
		Grimoire.Parent = Character
		Grimoire.CFrame = Hrp.CFrame
		Grimoire.Name = "GrimoireHandle"
		
		local HrpAttach = Grimoire.HrpAttach
		HrpAttach.Name = "GrimoireHandle"
		HrpAttach.Parent = Hrp
		local OrientAttach = Grimoire.OrientationAttach
		OrientAttach.Name = "GrimoireHandle"
		OrientAttach.Parent = Hrp
		FXModule.GrimoireEffects(Grimoire,"SpawnEffects")
	else
		for i,v in ipairs(Character:GetDescendants()) do
			if v.Name == "GrimoireHandle" then
				if v:FindFirstChild("Effects") then
					FXModule.GrimoireEffects(v,"DespawnEffects")
				end
				v:Destroy()

			end
		end 
	end
end

function FXModule.SwordEffects(Sword,Type)
	if not Sword or not Sword:FindFirstChild("Handle") then return end
	local EffectData = AllSwordsEffects:FindFirstChild(Sword.Handle.Effects.Value)
	if not EffectData then return end
	local TypeData = EffectData:FindFirstChild(Type)
	local Body = Sword.Body
	if Type == "DespawnEffects" then
		Body = Body:Clone()
		Body.Parent = workspace.Fx
		Body.Anchored = true
		game.Debris:AddItem(Body,3)
	end
	
	if TypeData then
		for _, particle in pairs(TypeData:GetChildren()) do
			local Clone = particle:Clone()
			Clone.Parent = Body
			if Clone:IsA("ParticleEmitter") then
				local emitCount = Clone:GetAttribute("EmitCount")
				if emitCount then
					Clone:Emit(emitCount or 1)
				end
			elseif Clone:IsA("Sound") then
				Clone:Play()
			end
			game.Debris:AddItem(Clone,2)
		end
	end
end

function FXModule.SwordReplicate(Character,SwordName)
	local Base = SwordsStorage:FindFirstChild(SwordName)
	if not Base then return end
	local Sword = Base:Clone()
	Sword.Parent = Character
	Sword.Name = "ServantSwordModel"
	Sword.Handle.Handle.Part0 = Character["Right Arm"]
	FXModule.SwordEffects(Sword,"SpawnEffects")
end
function FXModule.SwordUnreplicate(Character,Type)
	local Sword = Character:FindFirstChild(Type.."SwordModel")
	if Sword then
		FXModule.SwordEffects(Sword,"DespawnEffects")
		Sword:Destroy()
	end
end


--------------------------------------------------
function FXModule.LevelUp(Char)
	if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end
	local Effect = LevelUPFXFolder.LevelUPEffect.LvlUp:Clone()
	local Sound1 = LevelUPFXFolder.LevelUPEffect.First:Clone()
	local Sound2 = LevelUPFXFolder.LevelUPEffect.End:Clone()

	Sound1.Parent = Char.HumanoidRootPart
	Sound2.Parent = Char.HumanoidRootPart
	Effect.Parent = Char.HumanoidRootPart
	Sound1:Destroy()

	for _, v in pairs(Effect:GetChildren()) do
		if v.Name == "First" then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end


	task.delay(0.7, function()
		Sound2:Destroy()
		FXModule.CreateCrater(Char,nil,nil,1.6,nil,nil,nil,0.9,false,nil,false,0,10)
		for _, v in pairs(Effect:GetChildren()) do
			if v.Name ~= "First" then
				v:Emit(v:GetAttribute("EmitCount"))
			end
		end
	end)
end
-------------------------------------------------------------------------------------



--Funciones para las auras, no mover
function FXModule.AuraTrue(chr, Type, Aura)
	local rootPart = chr:WaitForChild("HumanoidRootPart")


	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {chr}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true
	raycastParams.RespectCanCollide = true

	local Raycast = workspace:Raycast(rootPart.Position, Vector3.new(0,-5,0), raycastParams)

	local function setupAura(AuraMain, Type, AnimName)
		local AuraInst = AuraMain:FindFirstChild(Type or "Human"):FindFirstChild("Aura"):Clone()
		local StartAnim:AnimationTrack = AnimationManager.GetTrack(chr.Humanoid.Animator,AuraMain:FindFirstChild("Config"):FindFirstChild(AnimName.."Start"))
		StartAnim:Play()
		local Con1
		StartAnim.Stopped:Connect(function()
			if Con1 then
				Con1:Disconnect()
			end
		end)
		Con1 = StartAnim:GetMarkerReachedSignal("End"):Connect(function()
			local existingAura = chr:FindFirstChild("Aura")
			if existingAura then
				if existingAura:FindFirstChild("Base") then
					existingAura:Destroy()
				end
			end
			if chr:FindFirstChild("Aura") then return end
			if not chr:GetAttribute("IsCharging") then return end
			FXModule.CreateCrater(chr,nil,20,2,nil,nil,nil,0.9,false,nil,false,6,20)
			local LoopAnim = AnimationManager.GetTrack(chr.Humanoid.Animator,AuraMain:FindFirstChild("Config"):FindFirstChild(AnimName.."Loop"))
			LoopAnim:Play()
			AuraInst.Parent = chr
			AuraInst.CanCollide = false
			AuraInst.CFrame = rootPart.CFrame
			AuraInst.Weld.Part1 = rootPart

			for _, v in pairs(AuraInst:GetDescendants()) do
				if (v:IsA("ParticleEmitter") or v:IsA("Beam")) and v.Name ~= "Ground" then
					v.Enabled = true
				elseif (v:IsA("ParticleEmitter") or v:IsA("Beam")) and v.Name == "Ground" and Raycast then
					v.Enabled = true
				elseif v:IsA("Sound") then
					v:Play()
				elseif v.Name == "3DEffect" then
					v.Parent = workspace.Fx
					v.Position = AuraInst.Position
					v.Transparency = 0
					Ts:Create(v, TweenInfo.new(v.Time.Value), {
						Size = Vector3.new(v.SizeV.Value.X, v.SizeV.Value.Y, v.SizeV.Value.Z),
						Transparency = v.TransparencyV.Value,
						Orientation = v.Orientation + Vector3.new(v.OrientV.Value.X, v.OrientV.Value.Y, v.OrientV.Value.Z)
					}):Play()
					game.Debris:AddItem(v, v.Life.Value)
				end
			end
			if AnimName == "Extasis" then
				for _, v in pairs(AuraInst:GetDescendants()) do
					if v.Name == "AuraExplosion" then
						local explosionClone = v:Clone()
						explosionClone.Parent = workspace.Fx
						explosionClone.Position = AuraInst.Position
						explosionClone.Transparency = 0
						Ts:Create(explosionClone, TweenInfo.new(0.5), {
							Size = Vector3.new(v.SizeV.Value.X * 1.4, v.SizeV.Value.Y * 1.4, v.SizeV.Value.Z * 1.4),
							Transparency = 1,
							Orientation = v.Orientation + Vector3.new(0, 360, 0)
						}):Play()
						game.Debris:AddItem(explosionClone, 1)
					end
				end
			end
		end)
		

		return AuraInst
	end

	if Type == "Normal" then
		if chr:FindFirstChild("Aura") then return end
		local AuraMain = (Aura and AuraSt:FindFirstChild(Aura)) or AuraSt:FindFirstChild("Human")
		setupAura(AuraMain, Type, "Charge")
		
	elseif Type == "Extasis" then

		local AuraMain = (Aura and AuraSt:FindFirstChild(Aura)) or AuraSt:FindFirstChild("Human")

		FXModule.stopAnimations({ "ChargeStart", "ExtasisStart","ChargeLoop", "ExtasisLoop" },chr)

		setupAura(AuraMain, Type, "Extasis")

		
	end
end

function FXModule.AuraFalse(chr)
	FXModule.stopAnimations({ "ChargeStart", "ExtasisStart","ChargeLoop", "ExtasisLoop" },chr)
	if chr:FindFirstChild("Aura") then
		local aura = chr:FindFirstChild("Aura")
		if aura:FindFirstChild("Weld") then
			aura:FindFirstChild("Weld"):Destroy()
		end
		aura.Anchored = true
		for i,v in pairs(aura:GetDescendants()) do
			if v:IsA("ParticleEmitter") then
				v.Enabled = false
			end
			if v:IsA("Beam") then
				v:Destroy()
			end
			if v.Name == "AuraExplosion" then
				v.Parent = workspace.Fx
				v.Position = aura.Position
				v.Transparency = 0
				Ts:Create(v, TweenInfo.new(v.Time.Value),{Size = Vector3.new(v.SizeV.Value.X,v.SizeV.Value.Y,v.SizeV.Value.Z), Transparency = v.TransparencyV.Value, Orientation = v.Orientation+Vector3.new(v.OrientV.Value.X,v.OrientV.Value.Y,v.OrientV.Value.Z)}):Play()
				game.Debris:AddItem(v,v.Life.Value)
			end
			if v:IsA("Sound") then
				v:Destroy()
			end
		end

		task.delay(.2, function()
			aura.Parent = workspace.Fx
			game.Debris:AddItem(aura,2)
		end)
	end
end

function FXModule.Unbridled(chr,Type,Aura)
	local function configureParticlesAndSounds(aura, isExplosion)
		for _, v in pairs(aura:GetDescendants()) do
			if v:IsA("ParticleEmitter") then
				v.Enabled = not isExplosion
			elseif v:IsA("Beam") and isExplosion then
				v:Destroy()
			elseif v.Name == "AuraExplosion" and isExplosion then
				v.Parent = workspace.Fx
				v.Position = aura.Position
				v.Transparency = 0
				Ts:Create(v, TweenInfo.new(v.Time.Value), {
					Size = Vector3.new(v.SizeV.Value.X * 2, v.SizeV.Value.Y * 5, v.SizeV.Value.Z * 2),
					Transparency = v.TransparencyV.Value,
					Orientation = v.Orientation + Vector3.new(v.OrientV.Value.X, v.OrientV.Value.Y, v.OrientV.Value.Z)
				}):Play()
				game.Debris:AddItem(v, v.Life.Value)
			elseif v:IsA("Sound") then
				if v.Name == "Unbridled" then
					v:Play()
				else
					v:Destroy()
				end
			end
		end
	end

	if Type == "Explosion" then
		FXModule.stopAnimations({ "ChargeStart", "ExtasisStart","ChargeLoop", "ExtasisLoop" },chr)
		FXModule.CreateCrater(chr,nil,50,4,nil,nil,nil,0.9,false,nil,false,0,40)
		local aura = chr:FindFirstChild("Aura")
		if aura then
			local AuraMain = game.ReplicatedStorage:WaitForChild("SystemAssets"):WaitForChild("ChargeSystem"):WaitForChild("AuraStorage"):WaitForChild(Aura)
			local Anim = AnimationManager.GetTrack(chr.Humanoid.Animator,AuraMain:WaitForChild("Config"):WaitForChild("ExplosionAnim"))
			Anim:Play()

			if aura:FindFirstChild("Weld") then
				aura:FindFirstChild("Weld"):Destroy()
			end

			aura.Anchored = true
			configureParticlesAndSounds(aura, true)

			if aura:FindFirstChild("Explosion") then
				for _, v in pairs(aura.Explosion:GetChildren()) do
					v:Emit(10)
				end
			end

			task.delay(0.2, function()
				aura.Parent = workspace.Fx
				game.Debris:AddItem(aura, 2)
			end)
		end

	elseif Type == "Add" then
		local AuraMain = game.ReplicatedStorage:WaitForChild("SystemAssets"):WaitForChild("ChargeSystem"):WaitForChild("AuraStorage"):WaitForChild(Aura)
		local AuraInst = AuraMain:WaitForChild("Unbridled"):WaitForChild("Aura")

		for _, v in pairs(AuraInst:GetChildren()) do
			local Clone = v:Clone()
			Clone.Name = "UnbridledAuraRemove"
			if v:IsA("ParticleEmitter") then
				for _, part in pairs(chr:GetChildren()) do
					if table.find({ "Right Arm", "Left Arm", "Right Leg", "Left Leg", "Torso", "Head" }, part.Name) then
						local Clone2 = Clone:Clone()
						Clone2.Parent = part
						Clone2.Enabled = true
					end
				end
				Clone:Destroy()
			elseif v:IsA("Sound") then
				Clone.Parent = chr:WaitForChild("Torso")
				Clone:Play()
			elseif v:IsA("Attachment") then
				Clone.Parent = chr:FindFirstChild(v.Name)
			end
		end

	elseif Type == "Remove" then
		for _, b in pairs(chr:GetDescendants()) do
			if b.Name == "UnbridledAuraRemove" then
				if b:IsA("ParticleEmitter") then
					b.Enabled = false
				elseif b:IsA("Sound") then
					Ts:Create(b, TweenInfo.new(1), { Volume = 0 }):Play()
				end
				task.delay(1, function()
					b:Destroy()
				end)
			end
		end
	end
end
---------------------------------------------------------------------------

function FXModule.Movement(character, velocity, duration)
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


--Efectos de highlight para los hits
function FXModule.Highlight(Player,Stun)
	if not Player then return end
	if Player:FindFirstChild("HitHighLightFX") then
		Player.HitHighLightFX:Destroy()
	end
	local Highlight = Instance.new("Highlight")
	Highlight.OutlineTransparency = 1
	Highlight.FillTransparency = 0.3
	Highlight.FillColor = Color3.fromRGB(255, 0, 0)
	Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	Highlight.Name = "HitHighLightFX"
	Highlight.Parent = Player
	Ts:Create(Highlight, TweenInfo.new(Stun,Enum.EasingStyle.Linear), {FillTransparency = 1}):Play()
	task.delay(Stun,function()
		if Highlight then 
			Highlight:Destroy()
		end
	end)
end


--Efectos para las espadas
function FXModule.Attack(Player,CurrentCombo,Anim,SpSound,Type,Stun,VFXF)	
	if not Type then
		local Rootpart = Player.HumanoidRootPart
		local AnimInst = AllAnimsFolder:FindFirstChild(Anim.Value)

		local VTU
		local VTUG
		local GroundAttachPart
		if GVFXFolder:FindFirstChild(VFXF["Gnd"]) then
			GroundAttachPart = Instance.new("Part",workspace.Fx)
			GroundAttachPart.Anchored = true
			GroundAttachPart.CanCollide = false
			GroundAttachPart.Transparency = 1
			GroundAttachPart.Massless = true
			GroundAttachPart.Position = Rootpart.Position + (Rootpart.CFrame.UpVector*-2.5)
			VTUG = GVFXFolder[VFXF["Gnd"]]:Clone()
			VTUG.Parent = GroundAttachPart
			VTUG.CFrame = GroundAttachPart.CFrame
		end

		if SpSound or VFXF[tostring(CurrentCombo)] then
			if SpSound then
				VTU = VFXF.USVFX and VFXFolder[VFXF.USVFX]:Clone()
			else
				VTU = VFXF[tostring(CurrentCombo)] and VFXFolder[VFXF[tostring(CurrentCombo)]]:Clone()
			end

		else
			VTU = VFXF["1"] and VFXFolder[VFXF["1"]]:Clone()
		end


		local Modifier = 1


		local AttachPart = Instance.new("Part",workspace.Fx)
		AttachPart.Anchored = false
		AttachPart.CanCollide = false
		AttachPart.Transparency = 1
		AttachPart.Massless = true
		local Weld = AnimInst.SPWeld:Clone()
		Weld.Parent = AttachPart
		Weld.Part0 = AttachPart
		Weld.Part1 = Rootpart
		if VTU then
			VTU.Parent = AttachPart
			VTU.CFrame = AttachPart.CFrame
			if VTU:FindFirstChild("PartAttachment") then
				VTU.PartAttachment.Parent = AttachPart
				for i,v in pairs(AttachPart.PartAttachment:GetChildren()) do
					v:Emit(1)
				end
			end
			if VTU:FindFirstChild("SlashAttachment") then
				for i,v in pairs(VTU.SlashAttachment:GetChildren()) do
					v:Emit(1)
				end
			end
			Ts:Create(VTU, TweenInfo.new(VTU.Time.Value), {
				Size = Vector3.new(VTU.SizeV.Value.X, VTU.SizeV.Value.Y, VTU.SizeV.Value.Z) * 
					Vector3.new(VTU.SizeMultiplier.Value.X, VTU.SizeMultiplier.Value.Y, VTU.SizeMultiplier.Value.Z),

				Position = VTU.Position + Rootpart.CFrame.LookVector * 1, 
				Transparency = 1,


				CFrame = VTU.CFrame * CFrame.Angles(0, math.rad(-VTU.OrientationV.Value.Y * Modifier), 0)
			}):Play()
			game.Debris:AddItem(AttachPart,VTU.Life.Value)
		end
		

		if not SpSound then
			local Sound = math.random(1,3)
			local Plays = SFXFolder:FindFirstChild(VFXF.SFX)["SW"..Sound]:Clone()
			Plays.Parent = AttachPart
			Plays:Play()
		else
			for i,v in pairs(SFXFolder:FindFirstChild(VFXF.SFX):GetChildren()) do
				if v.Name == "Special" then
					local Plays = v:Clone()
					Plays.Parent = AttachPart
					Plays:Play()
				end
			end


		end

		if VTUG then
			Ts:Create(VTUG, TweenInfo.new(VTUG.Time.Value), {
				Size = Vector3.new(VTUG.SizeV.Value.X, VTUG.SizeV.Value.Y, VTUG.SizeV.Value.Z),
				Transparency = VTUG.TransparencyV.Value
			}):Play()
		end
		game.Debris:AddItem(GroundAttachPart,VTUG.Life.Value)

	elseif Type == "HitFX" then
		local HFX = VFXF.HitFX
		
		local root = Player:WaitForChild("HumanoidRootPart", 1)
		local AttachPart = Instance.new("Attachment")
		
		if not root then
			AttachPart:Destroy()
			return 
		end
		
		AttachPart.Parent = root
		
		FXModule.Highlight(Player,Stun)

		local Sound = math.random(1,#AllHFX[HFX].Hits:GetChildren())
		local Plays = AllHFX[HFX].Hits[tostring(Sound)]:Clone()
		Plays.Parent = AttachPart
		Plays:Play()
		for i,v in pairs(AllHFX[HFX]:GetChildren()) do
			local clone = v:Clone()
			clone.Parent = AttachPart
			if clone:IsA("ParticleEmitter") then
				clone:Emit(clone:GetAttribute("EmitCount"))
			end
			if clone:IsA("Sound") then
				clone:Play()
			end
		end
		game.Debris:AddItem(AttachPart,3)
	end
end


--Efectos para los cofres
local AllGenerationZones = game.Workspace:WaitForChild("ChestGenerationZones")
local function CreateChestsFX(Zone)
	if not Zone or Zone:FindFirstChild("Chest") then return end
	local ZoneData = require(Zone:WaitForChild("Configuration",20))
	if not ZoneData then return end
	local Chest = ChestsStorage:FindFirstChild(ZoneData.ChestName):Clone()
	Chest:PivotTo(Zone.CFrame)
	Chest.Parent = Zone
	Chest.Name = "Chest"
end
function FXModule.CreateChests(desiredZone)
	if not desiredZone then
		for i,Zone in pairs(AllGenerationZones:GetChildren()) do
			CreateChestsFX(Zone)
		end
	else
		CreateChestsFX(desiredZone)
	end
	
end

local function CreateParticle(Character,Chest)
	local Particle = ChestFX.Particle:Clone()
	Particle.Parent = workspace.Fx
	Particle.CFrame = Chest.RootPart.CFrame
	local LV = Instance.new("LinearVelocity")
	LV.Parent = Particle.VelocityAttach
	LV.Attachment0 = Particle.VelocityAttach
	LV.VectorVelocity = Vector3.new(math.random(-10,10),20,math.random(-10,10))
	LV.MaxForce = 100000
	game.Debris:AddItem(LV,0.1)
	game.Debris:AddItem(Particle,6)
	task.delay(1.5,function()
		if not Character:FindFirstChild("HumanoidRootPart") then return end
		local PlayerAttach = Instance.new("Attachment")
		PlayerAttach.Parent = Character.HumanoidRootPart
		local AP = Instance.new("AlignPosition",Particle)
		AP.Attachment0 = Particle.VelocityAttach
		AP.Attachment1 = PlayerAttach
		AP.ApplyAtCenterOfMass = true
		AP.MaxForce = 1000
		AP.MaxVelocity = 60
		Particle.Particle.CanCollide = false
		Particle.Touched:Connect(function(part)
			if part:IsDescendantOf(Character) and Particle then
				Particle:Destroy()
			end
		end)
	end)
end
local function PlaySounds(Folder,Name,Chest)
	for i,v in pairs(Folder:GetChildren()) do
		if v.Name == Name then
			local Clone = v:Clone()
			Clone.Parent = Chest.RootPart
			Clone:Destroy()
		end
	end
end
local function SetParticles(Folder,AttachName,Chest)
	if not Chest then return end
	for i,v in pairs(Folder:GetChildren()) do
		if v.Name == AttachName then
			local Clone = v:Clone()
			Clone.Parent = Chest.RootPart
			game.Debris:AddItem(Clone,3)
			for i,b in pairs(Clone:GetChildren()) do
				if b.Name == "Hold" then
					b.Enabled = true
					task.delay(1,function()
						b.Enabled = false
					end)
				else
					b:Emit(5)
				end
			end

		end
	end
end
local function OpenChestFX(animController,Character,Params,SoundsFolder,Chest)
	if animController and animController:FindFirstChildOfClass("Animator") then
		local chestAnim = animController.Animator:LoadAnimation(ChestAnims:WaitForChild("Chest"))
		chestAnim:Play()
		PlaySounds(SoundsFolder,"Open",Chest)

		SetParticles(ChestFX.FXPart,"Open",Chest)
		if Chest.Base:FindFirstChild("ParticlePart") then
			Chest.Base.ParticlePart:Destroy()
		end
		Params.Name = "SuperSlash1"
		ShakeModule["Shake"]["Function"](Params)
		task.spawn(function()
			task.delay(0.8,function()
				Character.Humanoid.WalkSpeed = Character:GetAttribute("BaseSpeed") or 16
				Character.Humanoid.AutoRotate = true
			end)
			chestAnim:GetMarkerReachedSignal("PauseAnim"):Connect(function()
				chestAnim:AdjustWeight(1, 0)
				chestAnim:AdjustSpeed(0)
				local ParticleNumber = math.random(3,6)
				SetParticles(ChestFX.FXPart,"Reward",Chest)
				PlaySounds(SoundsFolder,"Reward",Chest)
				for i = 0, ParticleNumber, 1 do
					task.wait(1/ParticleNumber)
					CreateParticle(Character,Chest)
				end

			end)
		end)
	end
end

function FXModule.OpenChest(Player,ChestID,ChestInstance)
	--Poner las anims--------------------------------------------------------------------------------
	local Chest = ChestID and AllGenerationZones:FindFirstChild(ChestID) or ChestInstance
	if not Chest then return end
	local Con1
	if Chest:FindFirstChild("Chest") then
		Chest = Chest.Chest
	end
	local Opened
	local animController = Chest:FindFirstChild("AnimationController")
	local SoundsFolder = Chest:FindFirstChild("FXSounds") and ChestFX:FindFirstChild(Chest:FindFirstChild("FXSounds").Value.."Sounds") or ChestFX:FindFirstChild("CommonChestSounds")
	local Character = Player.Character
	local playerAnim = Character.Humanoid.Animator:LoadAnimation(ChestAnims:WaitForChild("Player"))
	playerAnim:Play()
	Character.Humanoid.WalkSpeed = 0
	Character.Humanoid.AutoRotate = false
	PlaySounds(SoundsFolder,"Swing",Chest)
	local Params = {
		TargetPlayer = Character,
		Name = "HeavyHit",
		Type = "Simple"
	}
	ShakeModule["Shake"]["Function"](Params)
	Con1 = playerAnim:GetMarkerReachedSignal("ChestPunched"):Connect(function()
		Opened = true
		OpenChestFX(animController,Character,Params,SoundsFolder,Chest)
	end)
	task.delay(2,function()
		if Con1 then
			if not Opened then
				OpenChestFX(animController,Character,Params,SoundsFolder,Chest)
			end
			Con1:Disconnect()
		end

	end)
	----------------------------------------------------------------------------------------------


end

local function IterateAndEmitEffect(Folder,Parent)
	for i,Particle in pairs(Folder:GetChildren()) do
		if Parent then
			Particle = Particle:Clone()
			Particle.Parent = Parent
			game.Debris:AddItem(Particle,1)
		end
		if Particle:IsA("ParticleEmitter") then
			Particle:Emit(7)
		else
			IterateAndEmitEffect(Particle)
		end
	end
end

local function createEffectPartFromCFrame(cframe, size)
	local tempPart = Instance.new("Part")
	tempPart.Size = size
	tempPart.CFrame = cframe
	tempPart.Anchored = true
	tempPart.CanCollide = false
	tempPart.Transparency = 1
	tempPart.Name = "EffectPart"
	tempPart.Parent = workspace
	return tempPart
end

function FXModule.EnemysSpawnEffects(Type,TargetPart, ...)
	if Type == "Spawn" then
		local Folder = EnemyStorage.FX:FindFirstChild("Spawn")
		IterateAndEmitEffect(Folder, TargetPart)
	else
		local Folder = EnemyStorage.FX:FindFirstChild("Despawn")
		
		local tempPart = createEffectPartFromCFrame(TargetPart[1], TargetPart[2])
		IterateAndEmitEffect(Folder, tempPart)
		
		task.delay(5, function()
			tempPart:Destroy()
		end)
	end
end

local activeSouls = 0
function FXModule.SoulsFunction(Char)
	if activeSouls >= 5 then return end
	local Hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not Char:FindFirstChild("Torso") or not Hrp or not Char:FindFirstChild("HumanoidRootPart") then return end
	if (Char.Torso.Position - Hrp.Position).Magnitude > 100 then return end
	local Soul = script.DSoul:Clone()
	task.delay(0.1,function()
		for i,v in pairs(Soul:GetDescendants()) do
			if v.Name == "FX" then
				for i,b in pairs(v:GetChildren()) do
					b.Enabled = true
				end
			end
		end
	end)

	Soul.Parent = workspace.Fx
	Soul.CFrame = Char.Torso.CFrame
	Soul.Anchored = true
	--Ts:Create(Soul, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {CFrame = Char.HumanoidRootPart.CFrame}):Play()
	activeSouls += 1
	task.wait(1)
	Soul.Anchored = false

	local Attachment1 = Instance.new("Attachment",Soul)
	Attachment1.Name = "SoulAttachment"
	local Attachment2 = Instance.new("Attachment",Hrp)
	Attachment2.Name = "SoulAttachment"
	local AP = Instance.new("AlignPosition")
	AP.Parent = Attachment1
	AP.Mode = Enum.PositionAlignmentMode.TwoAttachment
	AP.Attachment0 = Attachment1
	AP.Attachment1 = Attachment2
	AP.MaxForce = 100000
	AP.Responsiveness = 10



	Soul.Touched:Connect(function(Part)
		if Part == Hrp then
			Soul.CanTouch = false
			Soul.Transparency = 1
			for i,v in pairs(Soul:GetDescendants()) do
				if v.Name == "FX" then
					for i,b in pairs(v:GetChildren()) do
						b.Enabled = false
					end
				elseif v.Name == "Ring" then
					for i,b in pairs(v:GetChildren()) do
						b:Emit(3)
					end
				end
			end

			local sound =  Soul.AwardedSuscefully
			sound:Play()
			task.delay(2,function()
				if Soul then
					Soul:Destroy()
					activeSouls -= 1
				end
			end)
		end
	end)
	task.delay(10,function()
		if Soul then
			Soul:Destroy()
			activeSouls -= 1
		end
	end)
end
return FXModule