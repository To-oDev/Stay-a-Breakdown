--Services
local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
--Folders
local SystemsFolder = SS:WaitForChild("Systems")
local ModulesFolder = RS:WaitForChild("Modules")
local SystemsAssets = RS:WaitForChild("SystemAssets"):WaitForChild("SkillSystem")
local SystemEvents = RS:WaitForChild("SystemEvents")
--Modules
local HitboxModule = require(SystemsFolder:WaitForChild("HitboxSystem"))
local SkillRagdoll = require(SystemsFolder:WaitForChild("RagdollSystem"))
local CFSModule = require(ModulesFolder:WaitForChild("SharedLocalScriptFuncts"))
local ClientAssets = SystemEvents:WaitForChild("GetClientAsset")
local SkillExtraFuncts = require(SystemsFolder:WaitForChild("SkillSystem"):WaitForChild("SkillExtraFuncts"))
local FXModule = require(ModulesFolder:WaitForChild("FXModule"))
local StunHandler = require(SystemsFolder:WaitForChild("StunSystem"))
local HCS = require(SystemsFolder:WaitForChild("HitCalculateService"))
local DataSaver = require(SS:WaitForChild("DataModules"):WaitForChild("DataSaver"))
local AnimationManager = require(ModulesFolder:WaitForChild("MysterysAnimationManager"))
--Events
local RemoteFunct = SystemEvents:WaitForChild("SkillServerInvoke")
local Event = SystemEvents:WaitForChild("FXManagerEvent")
local UIevent = RS:WaitForChild("UISEvents"):WaitForChild("ComboUI")
local Anims = SystemsAssets:WaitForChild("Animations")


local function FollowDamageAndCalculate(Value, Enemy, Player, Multiplier,Highlight,NotHighlight,ExtraUITime,Shake)
	if not Enemy or not Enemy:FindFirstChild("Humanoid") then return end
	if not Player or not Player:FindFirstChild("Humanoid") then return end
	local HighlightTime = Highlight or 0.2
	if NotHighlight then
		HighlightTime = nil
	end
	local statsOwner = game.Players:GetPlayerFromCharacter(Player)
	local PlrData = DataSaver.GetSyncPlayerData(statsOwner)
	if not PlrData then return end
	local singularityM = PlrData.SessionData.TotalServantMult

	local baseDamage = (Value and Value.Damage) or 1
	local totalDamage = (singularityM and (baseDamage * singularityM) * (Multiplier or 1)) or 1
	HCS.PWHEFolder(Player, Enemy, totalDamage, Value.Source)
	HCS.HandleHits(statsOwner,Enemy,HighlightTime,totalDamage,ExtraUITime)
		

end

local function FireAllClients(Plr,Character,Name,Function,Shiny,Part,Target,SlashType)
	Event:FireAllClients({
		Function = Function,
		Player = Plr,
		Character = Character,
		Enemy = Target,
		Name = Name,
		Shiny = Shiny,
		Part = Part,
		SlashType = SlashType,
		Module = "SkillManager",

	})
end
local function FireClient(Plr,Character,Name,Function,Shiny,lookY,NotFall)
	Event:FireClient(Plr,{
		Function = Function,
		Player = Plr,
		Character = Character,
		Name = Name,
		Shiny = Shiny,
		lookY = lookY,
		NotFall = NotFall,
		Module = "SkillManager",
	})
end

function SimpleSetupCharacter(Char,Mode,AR)
	if Mode == true then
		Char.Humanoid.WalkSpeed = 0
		Char.Humanoid.JumpPower = 0
		Char.Humanoid.AutoRotate = AR or false
	else
		local BS = Char:GetAttribute("BaseSpeed") or 16
		Char.Humanoid.WalkSpeed = BS
		Char.Humanoid.JumpPower = 50
		Char.Humanoid.AutoRotate = true
	end
	
end

function Knockback(Parent,Velocity)
	if not Parent or not Velocity then return end
	if Parent:FindFirstChild("KnockBackAttach") then
		Parent.KnockBackAttach:Destroy()
	end
	local KnockBackAttach = Instance.new("Attachment")
	KnockBackAttach.Name = "KnockBackAttach"
	KnockBackAttach.Parent = Parent
	local LinearVl = Instance.new("LinearVelocity")
	LinearVl.MaxForce = 100000
	LinearVl.Attachment0 = KnockBackAttach
	LinearVl.VectorVelocity = Velocity
	LinearVl.Parent = KnockBackAttach
	Debris:AddItem(KnockBackAttach,0.1)
end

local function ResetToBaseState(Character,Type)
	local Hum = Character:FindFirstChild("Humanoid")
	if not Hum then return end
	if Type == false then
		Hum.WalkSpeed = 0
		Hum.JumpPower = 0
		Character:SetAttribute("CastingSkill",true)
		Hum.AutoRotate = false
	else
		local BS = Character:GetAttribute("BaseSpeed") or 16
		Hum.WalkSpeed = BS
		Hum.JumpPower = 50
		Character:SetAttribute("CastingSkill",false)
		Character:SetAttribute("SkillName",nil)
		Hum.AutoRotate = true
		Character:SetAttribute("IFrame",nil)
	end
end


local function setupHitbox(part, blacklist, size, DetectionMode, offset)
	local hitbox = HitboxModule.CreateHitbox()
	hitbox.Visualizer = false
	hitbox.Size = size
	hitbox.Offset = offset or CFrame.new()
	hitbox.CFrame = part
	hitbox.DetectionMode = DetectionMode or "Default"

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = blacklist
	hitbox.OverlapParams = params

	return hitbox
end

local function SpearOfGodJump(rootPart,Params)
	local Character = rootPart and rootPart.Parent
	if not Character or not Character.Parent then return end

	if Character:GetAttribute("SpearOfGodJump") then return end
	Character:SetAttribute("SpearOfGodJump", true)
	
	FireAllClients(Character,nil,"Spear Of God","Jump",Params.Value.Shiny)

	task.delay(0.365, function()
		if not rootPart or not rootPart.Parent then return end

		local Attachpart = Instance.new("Part")
		Attachpart.Name = "SOG_Attach"
		Attachpart.Anchored = true
		Attachpart.CanCollide = false
		Attachpart.CanTouch = false
		Attachpart.CanQuery = false
		Attachpart.Transparency = 1
		Attachpart.CFrame = rootPart.CFrame * CFrame.new(0, 80, 0)
		Attachpart.Parent = workspace.Fx

		local a0 = Instance.new("Attachment")
		a0.Parent = rootPart

		local a1 = Instance.new("Attachment")
		a1.Parent = Attachpart

		local align = Instance.new("AlignPosition")
		align.Attachment0 = a0
		align.Attachment1 = a1
		align.MaxForce = 50000
		align.Responsiveness = 50
		align.ApplyAtCenterOfMass = true
		align.Parent = rootPart

		task.delay(0.05, function()
			if not rootPart or not rootPart.Parent then return end
			Character:SetAttribute("ReadyToDiveSOG", true)
			rootPart.CFrame = Attachpart.CFrame
		end)

		local Con1, Con2
		local cleaned = false

		local function Clean()
			if cleaned then return end
			cleaned = true

			if Con1 then Con1:Disconnect() end
			if Con2 then Con2:Disconnect() end

			if align then align:Destroy() end
			if a0 then a0:Destroy() end
			if Attachpart then Attachpart:Destroy() end

			if Character and Character.Parent then
				Character:SetAttribute("SpearOfGodJump", nil)
				Character:SetAttribute("SpearOfGodDelete", nil)
			end
		end

		Con1 = rootPart.AncestryChanged:Connect(function(_, parent)
			if not parent then
				Clean()
			end
		end)

		Con2 = Character:GetAttributeChangedSignal("SpearOfGodDelete"):Connect(function()
			if Character:GetAttribute("SpearOfGodDelete") then
				Clean()
			end
		end)
	end)

end

local function Valid(Character)
	return Character 
		and Character:FindFirstChild("HumanoidRootPart") 
		and CFSModule.CFS(Character, {"CastingSkill"},{"IFrame"}) ~= 1
		and Character.Humanoid.Health > 0
end
local function safeDelay(time, Character, callback)
	task.delay(time, function()
		if Valid(Character) then
			callback()
		end
	end)
end

local function Charge(Char,SkillName)
	if Char:GetAttribute("Charge") then
		local Value = Char:GetAttribute("Charge") + 1
		Char:SetAttribute("Charge",Value)
	else
		Char:SetAttribute("Charge",1)
	end
	Event:FireAllClients({
		Function = "Charge",
		Player = Char,
		Name = SkillName or "Sword Explosion",
		Module = "SkillManager",
		Charge = Char:GetAttribute("Charge") or 0,
	})
end

local function SetDamageCheckpoints(skillName, callback, delays, character)
	task.spawn(function()
		local getAttr = character.GetAttribute

		for i = 1, #delays do
			task.wait(delays[i])

			if not getAttr(character, "CastingSkill")
				or getAttr(character, "SkillName") ~= skillName then
				return
			end

			callback()
		end
	end)
end






local module = {
	["Slash Barrage"] = {
		["Start"] = function(Params)
			local Character = Params.Player
			local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
			local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
			if not HRP or not Humanoid or CFSModule.CFS(Character) == 1 then return end
			local SkillName = Params.Name
			local SkillValue = Params.Value
			local Shiny = SkillValue and SkillValue.Shiny
			local Plr = Players:GetPlayerFromCharacter(Character)
			if Plr then
				FireClient(Plr,Character,"Mouse","Lock")
			end
			ResetToBaseState(Character, false)
			Character:SetAttribute("SkillName", SkillName)
			safeDelay(1.1,Character,function()
				if Character:GetAttribute("SkillName") ~= SkillName then return end
				SimpleSetupCharacter(Character,false)
			end)
			
			
			local function processHit(Hit, HitHumanoid, isSuper)
				local Enemy = HitHumanoid and HitHumanoid.Parent
				local HasBarrage = Enemy and Enemy:GetAttribute("SlashBarrage")
				if not Enemy or Enemy:GetAttribute("IFrame") or (not isSuper and HasBarrage) then return end

				local targetRoot = HitHumanoid.RootPart
				
				HCS.StunNRemoveAnims(Enemy, 0, 1.5, nil, nil, true)
				FollowDamageAndCalculate(SkillValue, Enemy, Character, 0.33)
				FireAllClients(Character,nil,"Slash Barrage","Hit",Shiny)
				
				local ragdollDuration = isSuper and 2 or 1.52
				SkillRagdoll.enableRagdoll(Enemy, ragdollDuration)
				
				if not isSuper and not HasBarrage then
					Enemy:SetAttribute("SlashBarrage", true)
					task.delay(1.5, function()
						if Enemy and Enemy.Parent then
							Enemy:SetAttribute("SlashBarrage", nil)
						end
					end)
				end
				if targetRoot then
					local upForce = isSuper and 80 or 70
					local randRange = isSuper and 10 or 0
					Knockback(targetRoot, targetRoot.CFrame.UpVector * upForce + Vector3.new(math.random(randRange, randRange + 10), 0, math.random(randRange, randRange + 10)))
				end
			end
			FireAllClients(Character,nil,"Slash Barrage","Start",Shiny)
	
			local function Slash()
				if not Valid(Character) then return end
				local Hitbox = setupHitbox(HRP, {Character}, Vector3.new(30, 7.633, 30), "Default", CFrame.new(0, 0, -9))
				FireAllClients(Character,nil,"Slash Barrage","Slash",Shiny)
				Hitbox:Start()
				task.delay(0.1, function() Hitbox:Stop() end)
				Hitbox.Touched:Connect(function(Hit, hum)
					if hum.Health <= 0 then return end
					processHit(Hit, hum, false)
				end)
			end
			local DelayTable = {
				1.35,0.30,0.28,0.34,0.26,0.32,0.33,0.27,0.30,0.25,
			}
			SetDamageCheckpoints(SkillName,Slash,DelayTable,Character)
				
			local function SuperSlash()
				if not Valid(Character) then return end
				local Hitbox = setupHitbox(HRP, {Character}, Vector3.new(40, 7.633, 40), "Default", CFrame.new(0, 0, -9))
				FireAllClients(Character,nil,"Slash Barrage","SuperSlash",Shiny)
				Hitbox:Start()
				task.delay(0.1, function()
					Hitbox:Stop()
				end)
				Hitbox.Touched:Connect(function(Hit, hum)
					if hum.Health <= 0 then return end
					processHit(Hit, hum, true)
				end)
				if Plr then
					RemoteFunct:InvokeClient(Plr, SkillValue,true)
				end
			end
			local DelayTable2 = {
				4.55,
			}
			SetDamageCheckpoints(SkillName,SuperSlash,DelayTable2,Character)
			safeDelay(4.3,Character,function()
				if Character:GetAttribute("SkillName") ~= SkillName then return end
				SimpleSetupCharacter(Character,true)
			end)
			
		end;

		["End"] = function(Params)
			local Character = Params.Player
			if not Character or not Character.Parent then return end

			local Player = Players:GetPlayerFromCharacter(Character)
			if Player then
				FireClient(Player,Character,"Mouse","Unlock")
			end
			ResetToBaseState(Character, true)
			if not Params.Finished then
				safeDelay(0.3, Character, function()
					HCS.StunNRemoveAnims(Character, nil, nil, nil, nil, nil, true)
				end)
			end
		end,
	};
	["Double Note"] = {
		["Start"] = function(Params)
			local Character = Params.Player
			local Player = Players:GetPlayerFromCharacter(Character)
			local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
			local Hum = Character and Character:FindFirstChildOfClass("Humanoid")
			if not HRP or CFSModule.CFS(Character) == 1 or not Hum then return end
			local Value = Params.Value
			local Shiny = Value and Value.Shiny
			local SkillName = Params.Name	
			
			if Player then
				FireClient(Player,Character,"Mouse","Lock")
			end
			ResetToBaseState(Character,false)
			Hum.AutoRotate = true
			Character:SetAttribute("SkillName",SkillName)
			
			local Connected = false
			local finished = false
			local Part = Instance.new("Part")
			Part.Transparency = 1
			Part.CanCollide = false
			Part.Anchored = true
			Part.CastShadow = false
			Part.Parent = workspace.Fx
			Part.CFrame = HRP.CFrame
			Debris:AddItem(Part,9)
			FireAllClients(Character,nil,"Double Note","Start",Shiny)

			task.delay(1.2,function()
				if not HRP or CFSModule.CFS(Character,{"CastingSkill"}) == 1 then return end
				if Player then
					FireClient(Player,Character,"Mouse","Unlock")
				end
				Hum.AutoRotate = false
				local Hitbox = setupHitbox(Part,{Character},Vector3.new(24,6.36,24),"Default",CFrame.new(0,0,21))
				Hitbox:Start()
				Part.CFrame = HRP.CFrame
				Part.Anchored = false
				
				Part:SetNetworkOwner(nil)
				local A = Instance.new("Attachment", Part)
				local LV = Instance.new("LinearVelocity")
				LV.Attachment0 = A
				LV.RelativeTo = Enum.ActuatorRelativeTo.World
				LV.ForceLimitMode = Enum.ForceLimitMode.PerAxis
				LV.MaxAxesForce = Vector3.new(math.huge,math.huge,math.huge)
				LV.VectorVelocity = HRP.CFrame.LookVector * 200
				LV.Parent = A
				Debris:AddItem(A, 2)
				
				
				FireAllClients(Character,nil,"Double Note","Hold",Shiny,Part)

				Hitbox.Touched:Connect(function(_,Humanoid)
					if Connected then return end
					local Target = Humanoid.Parent
					if Humanoid.Health <= 0 or Target:GetAttribute("IFrame")  or CFSModule.CFS(Character,{"CastingSkill"}) == 1 then return end
					local THRP = Target:FindFirstChild("HumanoidRootPart")
					if not THRP then return end
					Connected = true
					
					Part.Anchored = true
					HCS.StunNRemoveAnims(Target,0,6.2,nil,nil,true)
					Character:SetAttribute("IFrame",1)
					Target:SetAttribute("IFrame",1)
					
					local dist = (HRP.Position - THRP.Position).Magnitude
					local maxDelay,midDelay,minDelay = 0.4,0.2,0
					local s,e = 40,4
					local t = dist >= s and maxDelay or (dist <= e and minDelay or (minDelay + (midDelay-minDelay)*((dist-e)/(s-e))))
					
					task.delay(6.3+t,function()
						if finished then return end
						if Humanoid and Character and Character.Parent then
							SkillExtraFuncts.SetUpGrip(false,HRP,Humanoid.RootPart)
							Character:SetAttribute("IFrame",nil)
							HCS.StunNRemoveAnims(Character)
							ResetToBaseState(Character,true)
						end
						if HRP and Humanoid then 
							Target:SetAttribute("IFrame",nil)
							SkillRagdoll.enableRagdoll(Target,2)
							Knockback(Humanoid.RootPart, HRP.CFrame.UpVector*70 + Vector3.new(math.random(0,10),0,math.random(0,10)))
						end
					end)
					
					task.delay(0.5,function()
						if not HRP or CFSModule.CFS(Character,{"CastingSkill"}) == 1 then return end
						
						FireAllClients(Character,nil,"Double Note","EnemyHit",Params.Value.Shiny,nil,Target)

						FollowDamageAndCalculate(Params.Value,Target,Character,0.5)
						if Humanoid.Health <= 0 then HCS.StunNRemoveAnims(Character,nil,nil,false,true,nil,true) ResetToBaseState(Character,true) return end
						local HB2 = setupHitbox(Part,{Character,Target},Vector3.new(25,6.36,25),"Default",CFrame.new(0,0,-12.5))
						HB2:Start()
						task.delay(0.2,function() HB2:Stop() end)
						HB2.Touched:Connect(function(_,Humanoid2)
							local T2 = Humanoid2.Parent
							if Humanoid2.Health <= 0  or T2:GetAttribute("IFrame") then return end
							HCS.StunNRemoveAnims(T2,0,1.5,nil,nil,true)
							SkillRagdoll.enableRagdoll(T2,1.5)
							Knockback(Humanoid2.RootPart, HRP.CFrame.UpVector*70 + Vector3.new(math.random(0,10),0,math.random(0,10)))
							FollowDamageAndCalculate(Params.Value,T2,Character,0.5)
						end)
					end)
					
					Event:FireAllClients({Function="ServantHit",Player=Character,Name="Double Note",Module="SkillManager",Part=Part,CFrame=Part.CFrame,Shiny = Params.Value.Shiny})
					Hitbox:Stop()
					SkillRagdoll.disableRagdoll(Target)


					THRP.CFrame = CFrame.lookAt(THRP.Position, HRP.Position)
					HRP.CFrame = CFrame.lookAt(HRP.Position, THRP.Position)

					task.delay(0.7,function()
						if not HRP or CFSModule.CFS(Character,{"CastingSkill"}) == 1 or Humanoid.Health <= 0 then return end
						HCS.StunNRemoveAnims(Character)
						Event:FireAllClients({Function="PlayerHold",Player=Character,Name="Double Note",Module="SkillManager",Timedelay=t,Shiny = Params.Value.Shiny})
					end)
					
					task.delay(2.3,function()
						if Humanoid.Health <= 0 then return end
						
					
						
						if not HRP or CFSModule.CFS(Character,{"CastingSkill"}) == 1 then return end

	
						local DamageCount = 4
						local function Damage()
							FollowDamageAndCalculate(Params.Value,Target,Character,1/DamageCount)
						end
						local DelayTable = {0.52, 0.88, 0.72, 0.95}
						SetDamageCheckpoints(Params.Name,Damage,DelayTable,Character)
							
						local function Slash()
							FireAllClients(Character,nil,"Double Note","Slash",Params.Value.Shiny,nil,Target,"Slash")
						end
						local DelayTable2 = {1.4, 0.72}
						SetDamageCheckpoints(Params.Name,Slash,DelayTable2,Character)
						
						local function SuperSlash()
							finished = true
							FireAllClients(Character,nil,"Double Note","Slash",Params.Value.Shiny,nil,Target,"SuperSlash")
							Event:FireAllClients({Function="Camera",Type=false,Player=Character,Name="StopAnims",Module="SkillManager",})
							SkillExtraFuncts.SetUpGrip(false,HRP,Humanoid.RootPart)
							Character:SetAttribute("IFrame",nil)
							Target:SetAttribute("IFrame",nil)
							SkillRagdoll.enableRagdoll(Target,2)
							Knockback(Humanoid.RootPart, HRP.CFrame.UpVector*70 + Vector3.new(math.random(0,10),0,math.random(0,10)))
							HCS.StunNRemoveAnims(Character,nil,nil,true,true,nil,true)
							ResetToBaseState(Character,true)
						end
						local DelayTable3 = {3.07}
						SetDamageCheckpoints(Params.Name,SuperSlash,DelayTable3,Character)
						FireAllClients(Character,nil,"Double Note","DoubleNoteHit",Params.Value.Shiny,nil,Target)
						
						local safeY = HRP.Position.Y
						local pos = Vector3.new(THRP.Position.X,safeY,THRP.Position.Z) - (HRP.CFrame.LookVector*3)
						TS:Create(HRP,TweenInfo.new(t,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{CFrame=CFrame.new(pos,THRP.Position)}):Play()
						
						task.delay(t,function()
							
							
							local LookPosition = Vector3.new(0,0,-8)
							SkillExtraFuncts.SetUpGrip(true,HRP,Humanoid.RootPart,HRP.CFrame.LookVector*3,LookPosition)

							HRP.AssemblyLinearVelocity = Vector3.new(0,0,0)
							HRP.AssemblyAngularVelocity = Vector3.new(0,0,0)
						end)
					end)
					
				end)

				task.delay(1.5,function()
					if Connected then return end
					Part.Anchored = true
					HCS.StunNRemoveAnims(Character,nil,nil,nil,nil,nil,true)
					Event:FireAllClients({
						Function="ServantHit",
						Player=Character,
						Name="Double Note",
						Module="SkillManager",
						Part=Part,
						CFrame=Part.CFrame,
						Shiny = Params.Value.Shiny
					})
					Hitbox:Stop()
					
					ResetToBaseState(Character,true)
				end)
			end)
		end
		
	};
	["Sword Turret"] = {
		["Start"] = function(Params)
			local Character = Params.Player
			local Players = game:GetService("Players")
			local Player = Players:GetPlayerFromCharacter(Character)

			local HRP = Character:FindFirstChild("HumanoidRootPart")
			if not HRP or CFSModule.CFS(Character) == 1 then return end

			local SkillName = Params.Name
			local SkillValue = Params.Value
			local Shiny = SkillValue and SkillValue.Shiny

			if Player then
				FireClient(Player,Character,"Mouse","Lock")
			end
			ResetToBaseState(Character, false)
			Character.Humanoid.AutoRotate = true
			Character:SetAttribute("SkillName", SkillName)

			local function processHit(HitHumanoid, isSuper, multiplier)
				if not HitHumanoid then return end

				local enemy = HitHumanoid.Parent
				if not enemy then return end
				if not Valid(Character) then return end
				if enemy:GetAttribute("IFrame") then return end

				HCS.StunNRemoveAnims(enemy, 0, 1.5, nil, nil, true)
				FollowDamageAndCalculate(SkillValue, enemy, Character, multiplier)
				
				FireAllClients(enemy,nil,"Sword Turret","HitEnemy",Shiny)

				if not isSuper then return end

				SkillRagdoll.enableRagdoll(enemy, 2)
				local root = HitHumanoid.RootPart
				if root then
					Knockback(root,root.CFrame.UpVector * 70 +Vector3.new(math.random(0,10), 0, math.random(0,10)))
				end
			end

			local function spawnHitbox(size, offset, isSuper, multiplier)
				local Hitbox = setupHitbox(HRP,{Character},size,"Default",offset)
				Hitbox:Start()
				task.delay(0.1, function()
					Hitbox:Stop()
				end)
				Hitbox.Touched:Connect(function(_, Humanoid)
					if Humanoid.Health <= 0 then return end
					processHit(Humanoid, isSuper, multiplier)
				end)
			end


			local function Slash()
				spawnHitbox(Vector3.new(28, 8.974, 28),CFrame.new(0, 0, -5),false,0.0625)
			end

			local function Barrage()
				spawnHitbox(Vector3.new(33.189, 16.793, 40),CFrame.new(0, 0, -18),false,0.0625)
			end

			local function Explosion()
				if Player then
					RemoteFunct:InvokeClient(Player, SkillValue, true)
				end
				spawnHitbox(Vector3.new(33.189, 16.793, 40),CFrame.new(0, 0, -18),true,0.2)
			end


			SetDamageCheckpoints(SkillName,Slash,{0.78, 0.32, 0.30, 0.12},Character)
			SetDamageCheckpoints(SkillName,Barrage,{1.68, 0.17, 0.20, 0.15, 0.22, 0.16,0.19, 0.20, 0.13, 0.15, 0.13, 0.22},Character)
			SetDamageCheckpoints(SkillName,Explosion,{3.9},Character)
			FireAllClients(Character,nil,"Sword Turret","Start",Shiny)

		end,
		["End"] = function(Params)
			local Character = Params.Player
			local Player = Players:GetPlayerFromCharacter(Character)
			if Player then
				Event:FireAllClients({Function = "Equipment",Grimoire = true,Sword = true, Player = Character,Name = "StopAnims",Module = "SkillManager",})
				FireClient(Player,Character,"Mouse","Unlock")
			end
			if not Character then return end
			ResetToBaseState(Character,true)
			if not Params.Finished then
				HCS.StunNRemoveAnims(Character)
			end
		end,
	};
	["Sword Explosion"] = {
		["Start"] = function(Params)
			local Character = Params.Player
			local Player = game.Players:GetPlayerFromCharacter(Character)
			if not Character or not Character:FindFirstChild("HumanoidRootPart") or CFSModule.CFS(Character) == 1 then return end
			Character:SetAttribute("CastingSkill",true)
			Character:SetAttribute("SkillName",Params.Name)
			if Player then
				FireClient(Player,Character,"Mouse","Lock",nil,true)
			end
			FireAllClients(Character,nil,"Sword Explosion","Start")
			SimpleSetupCharacter(Character,true,true)
			task.spawn(function()
				for i = 1, 3 do
					task.wait(1.7)
					if CFSModule.CFS(Character,{"CastingSkill"}) == 0 and Character:GetAttribute("CastingSkill") and Character:GetAttribute("SkillName") == "Sword Explosion" then
						Charge(Params.Player)
					else
						break
					end
				end
			end)
		end,
		["End"] = function(Params)
			local Character = Params.Player
			local rootPart = Character and Character:FindFirstChild("HumanoidRootPart")
			if not rootPart or CFSModule.CFS(Character, {"CastingSkill"}) == 1 then return end
			if Character:GetAttribute("SkillName") ~= "Sword Explosion" then return end
			local Player = game.Players:GetPlayerFromCharacter(Character)
			local PlrHumanoid = Character:FindFirstChildOfClass("Humanoid")
			PlrHumanoid.AutoRotate = false
			HCS.StunNRemoveAnims(Character,nil,nil,nil,nil,nil,nil,{SkillEffect = true})
			
			local Value = Params.Value
			local Shiny = Value and Value.Shiny
			FireAllClients(Character,nil,"Sword Explosion","Slash",Shiny)

			local Charges = Character:GetAttribute("Charge") or 0

			local function processHit(HitHumanoid, multiplier,NotSuper)
				local Enemy = HitHumanoid and HitHumanoid.Parent
				if not Enemy then return end
				if not Valid(Character) or Enemy:GetAttribute("IFrame") then return end
				HCS.StunNRemoveAnims(Enemy, 0, 1.5, nil, nil, true)
				multiplier = (multiplier or 1)+ (0.1 * (Charges))
				FollowDamageAndCalculate(Value, Enemy, Character, multiplier)
				FireAllClients(Enemy,nil,"Sword Turret","HitEnemy",Shiny)
				
				if NotSuper then return end
				SkillRagdoll.enableRagdoll(Enemy, 2)
				local root = Enemy:FindFirstChild("HumanoidRootPart")
				if root then
					Knockback(root, root.CFrame.UpVector * 70 + Vector3.new(math.random(0,10), 0, math.random(0,10)))
				end
			end

			Character:SetAttribute("SkillName", nil)
			Character:SetAttribute("Charge", nil)
			local rawMousePos
			if Player then
				rawMousePos = ClientAssets:InvokeClient(Player, "GetMouseHit")
			else
				rawMousePos = rootPart.Position + (rootPart.CFrame.LookVector * 3)
			end


			local rootPos = rootPart.Position
			local maxDistance = 300

			local delta = rawMousePos - rootPos
			local distance = delta.Magnitude

			local MousePos = (distance > maxDistance)
				and (rootPos + delta.Unit * maxDistance)
				or rawMousePos

			local Projectile = Instance.new("Part")
			Projectile.Size = Vector3.new(1,1,1)
			Projectile.Transparency = 1
			Projectile.CanCollide = false
			Projectile.CastShadow = false
			Projectile.Anchored = true
			Projectile.Massless = true
			Projectile.CFrame = rootPart.CFrame
			Projectile.Parent = workspace.Fx

			Debris:AddItem(Projectile, 2)

			local ProjA = Instance.new("Attachment")
			ProjA.Parent = Projectile

			local TargetA = Instance.new("Attachment")
			TargetA.WorldPosition = MousePos
			TargetA.Parent = workspace.Terrain

			Debris:AddItem(TargetA, 2)

			local AP = Instance.new("AlignPosition")
			AP.Attachment0 = ProjA
			AP.Attachment1 = TargetA
			AP.MaxForce = 1e9
			AP.MaxVelocity = 300
			AP.Responsiveness = 200
			AP.Enabled = false
			AP.Parent = Projectile

			Projectile.CFrame = CFrame.lookAt(rootPos, MousePos)

			if not Charges or Charges < 3 then

				task.delay(0.36, function()
					if Player then
						FireClient(Player, Character, "Mouse", "Unlock", nil, nil, true)
					end

					Projectile.Anchored = false
					AP.Enabled = true
					Projectile:SetNetworkOwner(nil)
					FireAllClients(Character,nil,"Sword Explosion","Projectile",Shiny,Projectile)
					local Hitbox = setupHitbox(Projectile,{Character},Vector3.new(24,24,24),"Default",CFrame.new())
					Hitbox:Start()
					local hitConn
					hitConn = Hitbox.Touched:Connect(function(_, Humanoid)
						if Humanoid.Health > 0 then
							processHit(Humanoid)
						end
					end)

					task.delay(2, function()
						if hitConn then hitConn:Disconnect() end
						Hitbox:Stop()
					end)

					local alive = true
					task.delay(2, function() alive = false end)

					task.spawn(function()
						while alive and Projectile.Parent do
							task.wait(0.1)

							if (Projectile.Position - MousePos).Magnitude < 7 then
								alive = false

								if hitConn then hitConn:Disconnect() end
								Hitbox:Stop()

								local ExplosionHitbox = setupHitbox(Projectile,{Character},Vector3.new(60,40,60),"Default",CFrame.new())

								local expConn
								expConn = ExplosionHitbox.Touched:Connect(function(_, Humanoid)
									if Humanoid.Health > 0 then
										processHit(Humanoid, 0.3)
									end
								end)

								ExplosionHitbox:Start()
								
								FireAllClients(Character,nil,"Sword Explosion","Projectile_Explode",Shiny,Projectile)

								task.delay(0.1, function()
									if expConn then expConn:Disconnect() end
									ExplosionHitbox:Stop()
								end)

								break
							end
						end
					end)
				end)

			else
				Projectile.Size = Vector3.new(3,1,3)
				Projectile.CFrame = CFrame.lookAt(rootPos, MousePos)

				task.delay(0.4, function()
					
					FireAllClients(Character,nil,"Sword Explosion","Massive_Explosion",Shiny,Projectile)

					if Player then
						FireClient(Player,Character,"Mouse","Unlock",nil,nil,true)
					end

					local function runHitbox(normal)
						local HB = setupHitbox(Projectile,{Character},Vector3.new(33.189, 32, 300),"Default",CFrame.new(0,8,-150))

						local conn
						conn = HB.Touched:Connect(function(_, Humanoid)
							if Humanoid.Health > 0 then
								processHit(Humanoid, nil, normal)
							end
						end)

						HB:Start()
						task.delay(0.3, function()
							if conn then conn:Disconnect() end
							HB:Stop()
						end)
					end

					runHitbox(true)
					task.delay(0.6, runHitbox)
				end)
			end

			SimpleSetupCharacter(Character, false)
			ResetToBaseState(Character, true)
			HCS.StunNRemoveAnims(Character, nil, nil, true, true)

		end,
	};
	["Excaliba"] = {
		["Start"] = function(Params)
			local Character = Params.Player
			local Player = Players:GetPlayerFromCharacter(Character)
			local HRP = Character:FindFirstChild("HumanoidRootPart")
			if not HRP or CFSModule.CFS(Character) == 1 or not Character:GetAttribute("IsUnbridled") then return end
			
			local Value = Params.Value
			local Shiny = Value and Value.Shiny
			ResetToBaseState(Character,false)
			Character:SetAttribute("SkillName",Params.Name)
			Character:SetAttribute("IFrame",3)
			Character:SetAttribute("InCinematic",true)
			
			
			FireAllClients(Character,nil,"Excaliba","Start",Shiny)

			local Connected
			task.delay(1,function()
				local Hitbox = setupHitbox(HRP, {Character}, Vector3.new(28, 8.974, 28), "HitOnce", CFrame.new(0, 0, -5))
				Hitbox:Start()
				task.delay(0.1,function() Hitbox:Stop() end)

				Hitbox.Touched:Connect(function(_,Humanoid)
					if Humanoid.Health <= 0 then return end
					if Humanoid.Parent:GetAttribute("IFrame") and Humanoid.Parent:GetAttribute("IFrame") > 1 then return end

					Connected = Humanoid
					Humanoid.AutoRotate = false
					SkillRagdoll.disableRagdoll(Humanoid.Parent)
					HCS.StunNRemoveAnims(Humanoid.Parent,0,10,nil,nil,true)

					local lookAt = CFrame.lookAt(Humanoid.RootPart.Position, HRP.Position)
					Humanoid.RootPart.CFrame = lookAt

					SkillExtraFuncts.SetUpGrip(true, HRP, Humanoid.RootPart, HRP.CFrame.LookVector * 8)
					SimpleSetupCharacter(Humanoid.Parent,true)
					
					FireAllClients(Humanoid.Parent,nil,"Excaliba","HitEnemy",Shiny)
				end)
			end)

			task.delay(2.18,function()
				if Player then
					FireClient(Player,Character,"Excaliba","StartCamera")
				end
				local EnemyPlayer = Connected and Players:GetPlayerFromCharacter(Connected.Parent)
				if EnemyPlayer then
					FireClient(EnemyPlayer,Character,"Excaliba","StartCamera")
				end
			end)

			local function processHit(HitHumanoid, mult, NotSuper)
				local Enemy = HitHumanoid and HitHumanoid.Parent
				if not Enemy then return end
				if Enemy:GetAttribute("IFrame") then return end

				if not Connected or HitHumanoid ~= Connected then
					HCS.StunNRemoveAnims(Enemy,0,1.5,nil,nil,true)
				end
				FollowDamageAndCalculate(Value,Enemy,Character,mult)
				
				FireAllClients(Enemy,nil,"Sword Turret","HitEnemy",Shiny)

				if NotSuper then return end

				SkillRagdoll.enableRagdoll(Enemy,3)
				local r = Enemy:FindFirstChild("HumanoidRootPart")
				if r then
					Knockback(r, r.CFrame.UpVector * 250 + Vector3.new(math.random(0,50),0,math.random(0,50)))
				end
			end

			local ExplosionPart = Instance.new("Part",workspace.Fx)
			ExplosionPart.Position = HRP.Position + HRP.CFrame.LookVector * 300
			ExplosionPart.Anchored = true
			ExplosionPart.CanCollide = false
			ExplosionPart.Massless = true
			ExplosionPart.CastShadow = false
			ExplosionPart.Transparency = 1
			Debris:AddItem(ExplosionPart,11)

			task.delay(7,function()
				Event:FireAllClients({
					Function="Massive_Explosion",
					Part=HRP,
					Player=Character,
					Name="Excaliba",
					Module="SkillManager",
					SecondPart=ExplosionPart,
				})

				local Hitbox2 = setupHitbox(HRP, {Character,Connected}, Vector3.new(33.189,32,300), "Default", CFrame.new(0,8,-150))
				Hitbox2:Start()

				if Connected then
					processHit(Connected,0.5,true)
				end

				Hitbox2.Touched:Connect(function(_,Humanoid)
					if Humanoid.Health > 0 then
						processHit(Humanoid,0.5,true)
					end
				end)

				task.delay(0.1,function() Hitbox2:Stop() end)

				task.wait(1.5)

				local ExplosionHitbox = setupHitbox(ExplosionPart,{Character,Connected},Vector3.new(120,250,120),"Default",CFrame.new(0,110,0))
				ExplosionHitbox:Start()
				task.delay(0.1,function() ExplosionHitbox:Stop() end)

				ExplosionHitbox.Touched:Connect(function(_,Humanoid)
					if Humanoid.Health > 0 then
						processHit(Humanoid)
					end
				end)

				if Connected then
					Connected.AutoRotate = true
					SkillExtraFuncts.SetUpGrip(false, HRP, Connected.RootPart)
					HCS.StunNRemoveAnims(Connected.Parent,20)

					local hrp = Connected.RootPart
					local dir = -hrp.CFrame.LookVector
					local dist = 110

					local params = RaycastParams.new()
					params.RespectCanCollide = true
					params.FilterType = Enum.RaycastFilterType.Exclude

					local result = workspace:Raycast(hrp.Position, dir * dist, params)

					task.delay(0.045,function()
						if result then
							hrp.CFrame = CFrame.new(result.Position, result.Position + hrp.CFrame.LookVector)
						else
							local t = hrp.Position + dir * dist
							hrp.CFrame = CFrame.new(t, t + hrp.CFrame.LookVector)
						end
						processHit(Connected,0.5)
					end)
				end
			end)

			task.delay(9.9,function()
				ResetToBaseState(Character,true)
				if Character then
					Event:FireAllClients({
						Function="Equipment",
						Grimoire=true,
						Sword=true,
						Player=Character,
						Name="StopAnims",
						Module="SkillManager",
					})
				end
			end)
		end,
	};
	["Rotating Lance"] = {
		["Start"] = function(Params)
			local Character = Params.Player
			if not Character or not Character:FindFirstChild("HumanoidRootPart") or CFSModule.CFS(Character) == 1 then 
				return 
			end

			local Humanoid = Character:FindFirstChildOfClass("Humanoid")
			if not Humanoid then return end

			local Plr = Players:GetPlayerFromCharacter(Character)
			if Plr then
				Event:FireAllClients({
					Function = "Lock",
					Player = Plr,
					Character = Character,
					Name = "Mouse",
					Module = "SkillManager",
				})
			end

			local HRP = Character.HumanoidRootPart
			Character:SetAttribute("CastingSkill", true)
			Character:SetAttribute("SkillName", Params.Name)

			local AnimData = Anims.KuShulan[Params.Shiny or "Normal"].RotatingLance
			local StartAnim = AnimationManager.GetTrack(Params.Player.Humanoid.Animator, AnimData.Start)
			StartAnim:Play()
			local SlashNumber = 1
			local function fireClient(funcName, target)
				Event:FireAllClients({
					Function = funcName,
					Player = target or Character,
					Name = "Rotating Lance",
					Module = "SkillManager",
					Shiny = Params.Value.Shiny,
					SlashNumber = SlashNumber
				})
			end

			local function applyHitConstraints(hitHumanoid, isSuper)
				if not Valid(Character) then return false end
				local p = hitHumanoid.Parent
				if not p or p:GetAttribute("IFrame") then return false end
				if not isSuper and p:GetAttribute("SlashBarrage") then return false end
				return true
			end
			
			
			
			local function applyBarrageDebuff(hitHumanoid)
				local p = hitHumanoid.Parent
				p:SetAttribute("SlashBarrage", true)
				task.delay(1.5, function()
					if hitHumanoid then
						p:SetAttribute("SlashBarrage", nil)
					end
				end)
			end

			local function processHit(hit, hitHumanoid, isSuper, noRagdoll)
				if not hitHumanoid or not hitHumanoid.Parent then return end
				if not applyHitConstraints(hitHumanoid, isSuper) then return end

				local parent = hitHumanoid.Parent
				local root = hitHumanoid.RootPart

				HCS.StunNRemoveAnims(parent, 0, 1.5, nil, nil, true)
				FollowDamageAndCalculate(Params.Value, parent, Params.Player, 0.2)
				fireClient("Hit", parent)

				if not noRagdoll then
					SkillRagdoll.enableRagdoll(parent, isSuper and 2 or 1.52)
				end

				if not isSuper then
					applyBarrageDebuff(hitHumanoid)
					Knockback(root, root.CFrame.UpVector * 30 + Vector3.new(math.random(0, 10), 0, math.random(0, 10)))
					return
				end

				local upForce = 80
				local randRange = 10
				Knockback(root, root.CFrame.UpVector * upForce + Vector3.new(
					math.random(randRange, randRange + 10), 
					0, 
					math.random(randRange, randRange + 10)
					))
			end

			fireClient("Start")

			local ConnTable = {}
			task.delay(6, function()
				for _, conn in ipairs(ConnTable) do
					if conn and conn.Connected then conn:Disconnect() end
				end
				table.clear(ConnTable)
			end)

			local function Slash()
				local Hitbox = setupHitbox(HRP, {Character}, Vector3.new(30, 7.633, 30), "Default", CFrame.new(0, 0, -9))
				fireClient("Slash", Character)
				SlashNumber += 1
				Hitbox:Start()
				task.delay(0.1, function() Hitbox:Stop() end)
				Hitbox.Touched:Connect(function(hit, Humanoid)
					if Humanoid.Health > 0 then
						processHit(hit, Humanoid, false)
					end
				end)
			end
			local function Barrage()
				local Hitbox = setupHitbox(HRP, {Character}, Vector3.new(25, 7.633, 25), "Default", CFrame.new(0, 0, -11))
				fireClient("Barrage", Character)
				Hitbox:Start()
				task.delay(0.1, function() Hitbox:Stop() end)
				Hitbox.Touched:Connect(function(_, Humanoid)
					if Humanoid and Humanoid.Parent and Humanoid.Health > 0 then
						if Valid(Character) and not Humanoid.Parent:GetAttribute("IFrame") then
							HCS.StunNRemoveAnims(Humanoid.Parent, 0, 1, nil, nil, true)
							FollowDamageAndCalculate(Params.Value, Humanoid.Parent, Params.Player, 0.02,1)
							fireClient("Hit", Humanoid.Parent)
						end
					end
				end)
			end
			local function SuperSlash()
				local Hitbox = setupHitbox(HRP, {Character}, Vector3.new(45, 10.633, 45), "Default", CFrame.new(0, 0, -9))
				fireClient("SuperSlash")
				Hitbox:Start()
				task.delay(0.1, function()
					Hitbox:Stop()
					
				end)
				RemoteFunct:InvokeClient(Plr, Params.Value,true)
				Hitbox.Touched:Connect(function(hit, Humanoid)
					if Humanoid.Health > 0 then

						processHit(hit, Humanoid, true)
					end
				end)
			end
			local DelayTable1 = {0.6,0.42,2.08}
			local DelayTable2 = {1.2,0.13,0.14,0.16,0.17,0.17,0.18,0.15,0.15,0.20}
			local DelayTable3 = {3.77}

			SetDamageCheckpoints(Params.Name,Slash,DelayTable1,Character)
			SetDamageCheckpoints(Params.Name,Barrage,DelayTable2,Character)
			SetDamageCheckpoints(Params.Name,SuperSlash,DelayTable3,Character)
		end;

		["End"] = function(Params)
			local Character = Params.Player
			local Player = Players:GetPlayerFromCharacter(Character)
			if Player then
				Event:FireAllClients({
					Function = "Unlock",
					Player = Player,
					Character = Character,
					Name = "Mouse",
					Module = "SkillManager",
				})
			end
			
			local function ResetCharacter()
				ResetToBaseState(Character, true)
				HCS.StunNRemoveAnims(Character, nil, nil, nil, nil, nil, true)
			end

			if Params.Finished then
				ResetToBaseState(Character, true)
			else
				safeDelay(0.3, Character, ResetCharacter)
			end

		end,
	};
	["Lance Barrage"] = {
		["Start"] = function(Params)
			local Character = Params.Player
			local Player = Players:GetPlayerFromCharacter(Character)
			local HRP = Character:FindFirstChild("HumanoidRootPart")
			if not HRP or CFSModule.CFS(Character) == 1 then return end
			if Player then
				Event:FireAllClients({Function="Lock",Player=Player,Character=Character,Name="Mouse",Module="SkillManager"})
			end

			ResetToBaseState(Character,false)
			Character.Humanoid.AutoRotate = true
			Character:SetAttribute("SkillName",Params.Name)
			local StartAnim = AnimationManager.GetTrack(Character.Humanoid.Animator,Anims.KuShulan[Params.Shiny or "Normal"].LanceBarrage.Start)
			StartAnim:Play()
			local ConnTable = {}
			task.delay(6, function()
				for _, conn in ipairs(ConnTable) do
					if conn and conn.Connected then
						conn:Disconnect()
					end
				end
				table.clear(ConnTable)
			end)
			local function processHit(HitHumanoid, isSuper,multiplier)
				if not HitHumanoid or not HitHumanoid.Parent then return end
				if not Valid(Character) or HitHumanoid.Parent:GetAttribute("IFrame") then return end
				HCS.StunNRemoveAnims(HitHumanoid.Parent, 0, 1.5, nil, nil, true)
				FollowDamageAndCalculate(Params.Value, HitHumanoid.Parent, Params.Player, multiplier)
				Event:FireAllClients({
					Function = "Hit",
					Player = HitHumanoid.Parent,
					Name = "Rotating Lance",
					Module = "SkillManager",
					Shiny = Params.Value.Shiny,
				})
				if isSuper then
					SkillRagdoll.enableRagdoll(HitHumanoid.Parent, 2)
					local root = HitHumanoid.RootPart
					if root then
						Knockback(root, root.CFrame.UpVector * 70 + Vector3.new(math.random(0,10), 0, math.random(0,10)))
					end
				end	
			end
			
			
			
			local function Barrage()
				local Hitbox = setupHitbox(HRP, {Character}, Vector3.new(33.189, 16.793, 33), "Default", CFrame.new(0, 0, -18))
				Hitbox:Start()
				task.delay(0.1, function() Hitbox:Stop() end)
				Hitbox.Touched:Connect(function(Hit, Humanoid)
					if Humanoid.Health <= 0 then return end
					processHit(Humanoid, false,0.077)
				end)
			end
			
			local function Explosion()
				local Hitbox = setupHitbox(HRP, {Character}, Vector3.new(33.189, 16.793, 44), "Default", CFrame.new(0, 0, -18))
				Hitbox:Start()
				task.delay(0.1, function() Hitbox:Stop() end)
				Hitbox.Touched:Connect(function(Hit, Humanoid)
					if Humanoid.Health <= 0 then return end
					processHit(Humanoid,true,0.077)
				end)
				RemoteFunct:InvokeClient(Player, Params.Value,true)
			
			end
			
			local DelayTable1 = {0.93,0.24,0.23,0.17,0.23,0.23,0.24,0.21,0.24,0.26,0.22,0.20}
			local DelayTable2 = {3.57}
			SetDamageCheckpoints(Params.Name,Barrage,DelayTable1,Character)
			SetDamageCheckpoints(Params.Name,Explosion,DelayTable2,Character)

			Event:FireAllClients({Function="Start",Player=Character,Name="Lance Barrage",Module="SkillManager",Shiny = Params.Value.Shiny})
		end,
		["End"] = function(Params)
			local Character = Params.Player
			local Player = Players:GetPlayerFromCharacter(Character)
			if Player then
				FireAllClients(Player,Character,"Mouse","Unlock")
			end
			ResetToBaseState(Character,true)
			if not Params.Finished then
				HCS.StunNRemoveAnims(Params.Player,nil,nil)
			end
		end,
	};
	["Spear Of God"] = {
		["Start"] = function(Params)
			local Character = Params.Player
			local Player = game.Players:GetPlayerFromCharacter(Character)
			if not Character or not Character:FindFirstChild("HumanoidRootPart") or CFSModule.CFS(Character) == 1 then return end
			local rootPart = Character.HumanoidRootPart
			Character.Humanoid.AutoRotate = false
			Character:SetAttribute("CastingSkill",true)
			Character:SetAttribute("SkillName",Params.Name)
			Character:SetAttribute("Charging",true)
			Event:FireAllClients({Function = "Start",Player = Character,Name = "Spear Of God",Module = "SkillManager",Shiny = Params.Value.Shiny})
			SimpleSetupCharacter(Character,true,true)
			
			task.delay(0.85,function()
				if Player and CFSModule.CFS(Character,{"CastingSkill"}) == 0 and Character:GetAttribute("CastingSkill") and Character:GetAttribute("SkillName") == "Spear Of God" and Character:GetAttribute("Charging") then
					SpearOfGodJump(rootPart,Params)
					task.delay(0.365,function()
						if Player and CFSModule.CFS(Character,{"CastingSkill"}) == 0 and Character:GetAttribute("CastingSkill") and Character:GetAttribute("SkillName") == "Spear Of God" and Character:GetAttribute("Charging") then
							Event:FireAllClients({Function="Lock",Player=Player,Character=Character,Name="Mouse",Module="SkillManager",nil,lookY = true})
						end
					end)
				end
				
			end)
			
			task.spawn(function()
				for i = 1, 3 do
					task.wait(1.7)
					if CFSModule.CFS(Character,{"CastingSkill"}) == 0 and Character:GetAttribute("CastingSkill") and Character:GetAttribute("SkillName") == "Spear Of God" and Character:GetAttribute("Charging") then
						Charge(Params.Player,"Spear Of God")
					else
						break
					end
				end
			end)
		end,
		["End"] = function(Params)
			local Character = Params.Player
			local Player = game.Players:GetPlayerFromCharacter(Character)
			if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
			if CFSModule.CFS(Character, {"CastingSkill"}) == 1 then return end
			if Character:GetAttribute("SkillName") ~= "Spear Of God" then return end
			local rootPart = Character.HumanoidRootPart
			local Charge = Character:GetAttribute("Charge") or 0
			Character:SetAttribute("Charging",nil)
			Character:SetAttribute("Charge", nil)
			if not Character:GetAttribute("SpearOfGodJump") then
				SpearOfGodJump(rootPart, Params)
			end
			
			local ready = Character:GetAttribute("ReadyToDiveSOG")
			local conn
			if not ready then
				conn = Character:GetAttributeChangedSignal("ReadyToDiveSOG"):Connect(function()
					if Character:GetAttribute("ReadyToDiveSOG") then
						ready = true
						conn:Disconnect()
					end
				end)
				task.delay(3, function()
					if not ready then
						ready = true
					end
					if conn then
						conn:Disconnect()
					end
				end)
				while not ready and task.wait() do end
			end
				HCS.StunNRemoveAnims(Character,nil,nil,nil,nil,nil,nil)
				Event:FireAllClients({Function = "Dive",Player = Character,Name = "Spear Of God",Module = "SkillManager",Shiny = Params.Value.Shiny,lookY = true})
				
				task.delay(0.45,function()
				Character:SetAttribute("SpearOfGodDelete", true)
				Character:SetAttribute("ReadyToDiveSOG", nil)
				if Player then
					Event:FireAllClients({Function = "Unlock", Player = Player, Character = Character, Name = "Mouse", Module = "SkillManager"})
				end
				local rawMousePos = ClientAssets:InvokeClient(Player, "GetMouseHit")

				local rootPos = rootPart.Position
				local maxDistance = 150 * (1+(Charge*0.33))

				local distance = (rawMousePos - rootPos).Magnitude
				local MousePos: Vector3

				if distance > maxDistance then
					local direction = (rawMousePos - rootPos).Unit
					MousePos = rootPos + direction * maxDistance
				else
					MousePos = rawMousePos
				end

				MousePos = Vector3.new(MousePos.X,rootPos.Y,MousePos.Z)

				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				rayParams.RespectCanCollide = true
				rayParams.CollisionGroup = "Players"

				local DOWN_MAX = 200
				local rayResult = workspace:Raycast(MousePos, Vector3.new(0,-DOWN_MAX,0), rayParams)

				local finalPos = (
					rayResult and rayResult.Position
						or Vector3.new(MousePos.X, -DOWN_MAX, MousePos.Z)
				)




				local direction = finalPos - rootPos
				local hrpRay = workspace:Raycast(rootPos, direction, rayParams)

				if hrpRay then


					local groundRay = workspace:Raycast(hrpRay.Position, Vector3.new(0,-200,0), rayParams)

					if groundRay then
						finalPos = groundRay.Position
					else
						finalPos = hrpRay.Position
					end
				end


				local markPart = Instance.new("Part")
				markPart.Size = Vector3.new(4,1,4)
				markPart.Anchored = true
				markPart.CanCollide = false
				markPart.Transparency = 1
				markPart.CastShadow = false
				markPart.CanQuery = false
				markPart.Position = finalPos+Vector3.new(0,4,0)
				markPart.Parent = workspace.Fx
				Debris:AddItem(markPart,6)
				local humanoid:Humanoid = Character:FindFirstChild("Humanoid")

				humanoid.AutoRotate = false
				local look = CFrame.lookAt(rootPart.Position, markPart.Position)
				rootPart.CFrame = look
				local rotatedCFrame = look * CFrame.Angles(math.rad(90), 0, math.rad(0))

				local att0 = Instance.new("Attachment")
				att0.Orientation = Vector3.new(0, 90, 0)
				att0.Parent = rootPart

				local att1 = Instance.new("Attachment")
				att1.Parent = markPart
				local lookatt = Instance.new("Attachment")
				lookatt.Parent = markPart

				local Pos = rootPart.CFrame.LookVector*2
				local newVector = Vector3.new(Pos.X,lookatt.Position.Y,Pos.Z)
				lookatt.Position += newVector

				local alignPos = Instance.new("AlignPosition")
				alignPos.Attachment0 = att0
				alignPos.Attachment1 = att1
				alignPos.MaxForce = 100000
				alignPos.MaxVelocity = 600 * (1+Charge*0.1)
				alignPos.ApplyAtCenterOfMass = true
				alignPos.Responsiveness = 70
				alignPos.Parent = rootPart

				local alignOri = Instance.new("AlignOrientation")
				alignOri.AlignType = Enum.AlignType.PrimaryAxisLookAt
				alignOri.Mode = Enum.OrientationAlignmentMode.TwoAttachment
				alignOri.Attachment0 = att0
				alignOri.Attachment1 = lookatt
				alignOri.MaxTorque = math.huge
				alignOri.Responsiveness = 200
				alignOri.Parent = rootPart







				task.spawn(function()
					while rootPart and markPart and Character do
						local dist = (rootPart.Position - (markPart.Position + Vector3.new(0,3,0))).Magnitude

						if dist < 13 then
							break
						end

						task.wait()
					end
					HCS.StunNRemoveAnims(Character,nil,nil,nil,nil,nil,nil)
					local Connected

					if alignPos then alignPos:Destroy() end
					if alignOri then alignOri:Destroy() end
					if att0 then att0:Destroy() end
					if lookatt then lookatt:Destroy() end
					if att1 then att1:Destroy() end


					local function applyKnockbackAndRagdoll(hum)
						HCS.StunNRemoveAnims(hum.Parent, 0, 1.5, nil, nil, true)
						SkillRagdoll.enableRagdoll(hum.Parent, 1.5)

						local hrp = hum.RootPart
						local randomXZ = Vector3.new(math.random(0,10), 0, math.random(0,10))
						Knockback(hrp, Vector3.new(0,1,0) * 70 + randomXZ)
					end

					local Hitbox = setupHitbox(markPart, {Character}, Vector3.new(16, 16.793, 16), "Default")
					Hitbox:Start()

					local HitboxSize = 33 * (1+0.33*Charge)
					local Hitbox2 = setupHitbox(markPart, {Character}, Vector3.new(HitboxSize, 16.793, HitboxSize), "Default")


					Hitbox2.Touched:Connect(function(hit,hum)
						if not hum or not hum.RootPart or hum.Health <= 0 or hum == Connected or hum.Parent:GetAttribute("IFrame") then return end
						applyKnockbackAndRagdoll(hum)
						FollowDamageAndCalculate(Params.Value,hum.Parent,Character,0.7)
					end)
					local DamageCount = 3
					Hitbox.Touched:Connect(function(hit, hum)
						if not hum or not hum.RootPart or hum.Health <= 0 or hum.Parent:GetAttribute("IFrame") then return end
						if not Connected then
							Connected = hum
							Character:SetAttribute("IFrame",1)
							hum.Parent:SetAttribute("IFrame",1)
							SkillRagdoll.disableRagdoll(hum.Parent)
							local lookPos = Vector3.new(0,0,-8)
							SkillExtraFuncts.SetUpGrip(true, rootPart, hum.RootPart, rootPart.CFrame.LookVector * 3, lookPos)

							local function Damage()
								FollowDamageAndCalculate(Params.Value,hum.Parent,Character,1/DamageCount)
							end
							local DelayTable = {0,2.55,0.6}

							SetDamageCheckpoints(Params.Name,Damage,DelayTable,Character)


							Event:FireAllClients({
								Function = "Connected",
								Player = Character,
								Enemy = hum.Parent,
								Name = "Spear Of God",
								Module = "SkillManager",
								Shiny = Params.Value.Shiny
							})


							task.delay(3.18, function()
								Event:FireAllClients({
									Function="Camera",
									Type=false,
									Player=Character,
									Name="StopAnims",
									Module="SkillManager",
								})
								if hum and hum.Parent then
									hum.Parent:SetAttribute("IFrame",nil)
								end
								
								SkillExtraFuncts.SetUpGrip(false, rootPart, hum.RootPart)
								applyKnockbackAndRagdoll(hum)
								ResetToBaseState(Character, true)
								Character:SetAttribute("SkillName", nil)
							end)
						end
					end)

					task.delay(0.01, function() 
						Hitbox:Stop() 
						Hitbox2:Start()
						task.delay(0.1,function()
							Hitbox2:Stop()
						end)
						Event:FireAllClients({Function = "Explosion",Player = Character,Name = "Spear Of God",Module = "SkillManager",Shiny = Params.Value.Shiny,Anim = not Connected,Size = HitboxSize})
						if not Connected then
							Character:SetAttribute("SkillName", nil)
							ResetToBaseState(Character,true)
						end
					end)
				end)
				end)

				
				
			

		end,
	};
	["Gyroscope Attack"] = {
		["Start"] = function(Params)
			local Character = Params.Player
			if not Character or not Character:FindFirstChild("HumanoidRootPart") or CFSModule.CFS(Character) == 1 then return end
			local Humanoid = Character:FindFirstChildOfClass("Humanoid")
			if not Humanoid then return end
			local HRP = Character.HumanoidRootPart
			local Player = Players:GetPlayerFromCharacter(Character)
			local Plr = Players:GetPlayerFromCharacter(Character)
			if Plr then
				Event:FireAllClients({
					Function = "Lock",
					Player = Plr,
					Character = Character,
					Name = "Mouse",
					Module = "SkillManager",
				})
			end
			Character:SetAttribute("SkillName", Params.Name)
			Character:SetAttribute("CastingSkill", true)
			Event:FireAllClients({Function = "Start",Player = Character,Name = "Gyroscope Attack",Module = "SkillManager",Shiny = Params.Value.Shiny})
			SimpleSetupCharacter(Character,true,true)
			task.delay(0.71,function()
				HCS.StunNRemoveAnims(Character,nil,nil,nil,nil,nil,nil)
				Humanoid.AutoRotate = false
				if Player then
					Event:FireAllClients({Function = "Unlock", Player = Player, Character = Character, Name = "Mouse", Module = "SkillManager"})
				end
				local Connected = nil
				local Hitbox = setupHitbox(HRP, {Character}, Vector3.new(16, 7.633, 40), "Default", CFrame.new(0, 0, -20))
				Hitbox:Start()
				Hitbox.Touched:Connect(function(hit,hum)
					if not hum or hum.Health <= 0 or hum.Parent:GetAttribute("IsRagdolled") or hum.Parent:GetAttribute("IFrame") then return end
					if not Connected then
						Connected = hum
						
					end
				end)

				task.delay(0.01,function()
					Hitbox:Stop()
					if Player then
						Event:FireAllClients({Function = "Unlock", Player = Player, Character = Character, Name = "Mouse", Module = "SkillManager", NotFall = true})
					end
					Event:FireAllClients({Function = "Slash",Player = Character,Name = "Gyroscope Attack",Module = "SkillManager",Shiny = Params.Value.Shiny,Connected = Connected})
					if not Connected then
						local rawMousePos = ClientAssets:InvokeClient(Player, "GetMouseHit")
						local HRP = Character.HumanoidRootPart
						local origin = HRP.Position

						local flatDir = Vector3.new(
							rawMousePos.X - origin.X,
							0,
							rawMousePos.Z - origin.Z
						)

						if flatDir.Magnitude < 0.1 then
							return
						end

						flatDir = flatDir.Unit

						HRP.CFrame = CFrame.lookAt(
							origin,
							origin + flatDir,
							Vector3.yAxis
						)

						local distance = 42

						local rayParams = RaycastParams.new()
						rayParams.FilterType = Enum.RaycastFilterType.Exclude
						rayParams.RespectCanCollide = true
						rayParams.CollisionGroup = "Players"
						rayParams.FilterDescendantsInstances = {Character}

						local result = workspace:Raycast(origin, HRP.CFrame.LookVector * distance, rayParams)

						if result then
							local hitPos = result.Position
							HRP.CFrame = CFrame.new(hitPos - HRP.CFrame.LookVector * 2, hitPos)
						else
							HRP.CFrame = HRP.CFrame + HRP.CFrame.LookVector * distance
						end


					else
						Connected.Parent:SetAttribute("IFrame",1)
						Character:SetAttribute("IFrame",1)
						local safeY = HRP.Position.Y
						local pos = Vector3.new(Connected.RootPart.Position.X,safeY,Connected.RootPart.Position.Z) - (HRP.CFrame.LookVector*3)
						HRP.CFrame = CFrame.new(pos,Connected.RootPart.Position)
						local LookPosition = Vector3.new(0,0,-8)
						SkillExtraFuncts.SetUpGrip(true,HRP,Connected.RootPart,nil,LookPosition)
						
						local DamageCount = 6
						local function Damage()
							FollowDamageAndCalculate(Params.Value,Connected.Parent,Character,1/DamageCount)
						end
						local DelayTable = {0.05,0.38,0.07,0.10,0.10,0.55}
						SetDamageCheckpoints(Params.Name,Damage,DelayTable,Character)
						
						task.wait(1.27)
						Connected.Parent:SetAttribute("IFrame",nil)
						SkillExtraFuncts.SetUpGrip(false,HRP,Connected.RootPart)
						
						HCS.StunNRemoveAnims(Connected.Parent, 0, 1.5, nil, nil, true)
						SkillRagdoll.enableRagdoll(Connected.Parent, 1.2)
						Knockback(Connected.RootPart, Connected.RootPart.CFrame.UpVector * 20 + HRP.CFrame.LookVector*-60)
					end
					ResetToBaseState(Character,true)
					Event:FireAllClients({
						Function="Camera",
						Type=false,
						Player=Character,
						Name="StopAnims",
						Module="SkillManager",
					})
				end)
			end)

		end,
	};
	["Thousand Slashes"] = {
		["Start"] = function(Params)
			local Character = Params.Player
			local Player = Players:GetPlayerFromCharacter(Character)
			local HRP = Character:FindFirstChild("HumanoidRootPart")
			if not HRP or CFSModule.CFS(Character) == 1 then return end
			if Player then
				Event:FireAllClients({Function="Lock",Player=Player,Character=Character,Name="Mouse",Module="SkillManager"})
			end

			ResetToBaseState(Character,false)
			Character.Humanoid.AutoRotate = true
			Character:SetAttribute("SkillName",Params.Name)
			local function processHit(HitHumanoid, multiplier)
				if not HitHumanoid or not HitHumanoid.Parent then return end
				if not Valid(Character) or HitHumanoid.Parent:GetAttribute("IFrame") then return end
				HCS.StunNRemoveAnims(HitHumanoid.Parent, 0, 1.5, nil, nil, true)
				FollowDamageAndCalculate(Params.Value, HitHumanoid.Parent, Params.Player, multiplier,1.5)
				Event:FireAllClients({
					Function = "HitEnemy",
					Player = HitHumanoid.Parent,
					Name = "Thousand Slashes",
					Module = "SkillManager",
					Shiny = Params.Value.Shiny
				})
				
			end
			
			
			local function Damage()
				local Hitbox = setupHitbox(HRP, {Character}, Vector3.new(28, 8.974, 28), "Default", CFrame.new(0, 0, -5))
				Hitbox:Start()
				task.delay(0.1,function()
					Hitbox:Stop()
				end)
				Hitbox.Touched:Connect(function(Hit,Humanoid)
					if Humanoid.Health <= 0 then return end
					processHit(Humanoid,0.33)
				end)
			end
			local DelayTable = {0.58,0.65,0.79}
			SetDamageCheckpoints(Params.Name,Damage,DelayTable,Character)
			safeDelay(2.02,Character,function()
				RemoteFunct:InvokeClient(Player, Params.Value,true)
			end)
			
			Event:FireAllClients({Function="Start",Player=Character,Name="Thousand Slashes",Module="SkillManager",Shiny = Params.Value.Shiny})

		end,
		["End"] = function(Params)
			local Character = Params.Player
			local Player = Players:GetPlayerFromCharacter(Character)
			if not Params.Finished then
				HCS.StunNRemoveAnims(Params.Player)
			end
			if Player then
				Event:FireAllClients({
					Function = "Unlock",
					Player = Player,
					Character = Character,
					Name = "Mouse",
					Module = "SkillManager",
				})
			end
			ResetToBaseState(Character,true)
		end,
	};
	["Iron Fist"] = {
		["Start"] = function(Params)
			local Character = Params.Player
			local Player = Players:GetPlayerFromCharacter(Character)
			local HRP = Character:FindFirstChild("HumanoidRootPart")
			if not HRP or CFSModule.CFS(Character) == 1 then return end
			if Player then
				Event:FireAllClients({Function="Lock",Player=Player,Character=Character,Name="Mouse",Module="SkillManager"})
			end
			ResetToBaseState(Character,false)
			Character.Humanoid.AutoRotate = true
			Character:SetAttribute("SkillName",Params.Name)
			Event:FireAllClients({Function="Start",Player=Character,Name="Iron Fist",Module="SkillManager",Shiny = Params.Value.Shiny})
			
			
			task.delay(0.28,function()
				if Player then
					Event:FireAllClients({
						Function = "Unlock",
						Player = Player,
						Character = Character,
						Name = "Mouse",
						Module = "SkillManager",
					})
				end
				local Connected
				local Hitbox = setupHitbox(HRP, {Character}, Vector3.new(9, 7, 10), "Default", CFrame.new(0, 0, -5))
				Hitbox:Start()
				Character.Humanoid.AutoRotate = false
				Character:SetAttribute("IFrame",1)
				task.delay(0.1,function()
					Hitbox:Stop()
					if not Connected then
						ResetToBaseState(Character,true)
					end
				end)
				Hitbox.Touched:Connect(function(Hit, Humanoid) 
					if Connected then return end
					if  Humanoid.Health<= 0 or Humanoid.Parent:GetAttribute("IFrame") then return end
					Connected = true 
					SkillRagdoll.disableRagdoll(Humanoid.Parent)
					Humanoid.Parent:SetAttribute("IFrame",1)
					HCS.StunNRemoveAnims(Character)
					SkillExtraFuncts.SetUpGrip(true, HRP, Humanoid.RootPart,HRP.CFrame.LookVector*1, Vector3.new(0,0, -8))
					Event:FireAllClients({Function="Connected",Player=Character,Enemy = Humanoid.Parent,Name="Iron Fist",Module="SkillManager",Shiny = Params.Value.Shiny})
					local DamageCount = 4
					local  function Damage()
						FollowDamageAndCalculate(Params.Value,Humanoid.Parent, Character, 1/DamageCount)
					end
					local DelayTable = {
						0,
						0.07,
						0.25,
						0.44
					}
					SetDamageCheckpoints(Params.Name,Damage,DelayTable,Character)
					task.delay(0.9,function()
						Humanoid.Parent:SetAttribute("IFrame",nil)
						SkillExtraFuncts.SetUpGrip(false, HRP, Humanoid.RootPart)	
						SkillRagdoll.enableRagdoll(Humanoid.Parent, 1.2)
						Knockback(Humanoid.RootPart,HRP.CFrame.LookVector*30 + HRP.CFrame.UpVector*20)
						ResetToBaseState(Character,true)
						
					end)
				end)
				
			end)
			
		end
		
	
	},
	["Burst Dash"] = {
		["Start"] = function(Params)
			local Character = Params.Player
			local Player = Players:GetPlayerFromCharacter(Character)
			local HRP = Character:FindFirstChild("HumanoidRootPart")
			if not HRP or CFSModule.CFS(Character) == 1 then return end
			
			ResetToBaseState(Character,false)
			local rawMousePos = ClientAssets:InvokeClient(Player, "GetMouseHit")
			local origin = HRP.Position

			local flatDir = Vector3.new(
				rawMousePos.X - origin.X,
				0,
				rawMousePos.Z - origin.Z
			)

			if flatDir.Magnitude < 0.1 then
				return
			end

			flatDir = flatDir.Unit

			HRP.CFrame = CFrame.lookAt(
				origin,
				origin + flatDir,
				Vector3.yAxis
			)
			
			
			
			Character:SetAttribute("SkillName",Params.Name)
			Event:FireAllClients({Function="Start",Player=Character,Name="Burst Dash",Module="SkillManager",Shiny = Params.Value.Shiny})
			
			
			task.delay(0.25,function()
				local va = Instance.new("Attachment",HRP)
				Debris:AddItem(va,1.1)
				local LinearVelocity = Instance.new("LinearVelocity")
				LinearVelocity.Attachment0 = va
				LinearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World

				local dir = va.WorldCFrame.LookVector * 1

				LinearVelocity.VectorVelocity = dir * 200
				LinearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
				LinearVelocity.MaxAxesForce = Vector3.new(30000, 0, 30000)

				LinearVelocity.Parent = va

				task.delay(0.1, function()
					if LinearVelocity.Parent then
						LinearVelocity.VectorVelocity = dir * 100
					end
				end)

				task.delay(0.58, function()
					if LinearVelocity.Parent then
						LinearVelocity.VectorVelocity = dir * 30
					end
				end)

				local Hitbox = setupHitbox(HRP, {Character}, Vector3.new(14, 8, 14), "Default", CFrame.new(0, 0, 0))
				Hitbox:Start()
				task.delay(0.68,function()
					Hitbox:Stop()
					task.delay(0.17,function()
						ResetToBaseState(Character,true)
					end)
				end)
				Hitbox.Touched:Connect(function(Hit,hum)
					if not hum or hum.Health <= 0 or hum.Parent:GetAttribute("IFrame") then return end
					Event:FireAllClients({
						Function = "Hit",
						Player = hum.Parent,
						Name = "Slash Barrage",
						Module = "SkillManager",
						Shiny = "Hasta"
					})
					FollowDamageAndCalculate(Params.Value,hum.Parent,Character)
					HCS.StunNRemoveAnims(hum.Parent, 0, 1.5, nil, nil, true)
					SkillRagdoll.enableRagdoll(hum.Parent, 1.5)
					local hrp = hum.RootPart
					
					Knockback(hrp, Vector3.new(0,1,0) * 40 + HRP.CFrame.LookVector*40)
				end)
			end)
			
			
			
			
		end,
	}
	
}

return module