local Debris = game:GetService("Debris")
local Event = game.ReplicatedStorage:WaitForChild("SystemEvents"):WaitForChild("RemoveRagdoll")

local collisionPartTemplate = Instance.new("Part")
collisionPartTemplate.Name = "CollisionPart"
collisionPartTemplate.TopSurface = Enum.SurfaceType.Smooth
collisionPartTemplate.BottomSurface = Enum.SurfaceType.Smooth
collisionPartTemplate.Size = Vector3.new(1, 1.5, 1)
collisionPartTemplate.Transparency = 1
collisionPartTemplate.CanCollide = true
collisionPartTemplate.CollisionGroup = "Players"
collisionPartTemplate.Massless = true

local attachmentData = {
	["Right Arm"] = CFrame.new(0, -0.5, 0),
	["Left Arm"] = CFrame.new(0, -0.5, 0),
	["Right Leg"] = CFrame.new(0, -0.5, 0),
	["Left Leg"] = CFrame.new(0, -0.5, 0),
}

local ragdollStates = {}
local module = {}


function module.disableRagdoll(character)
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not humanoid or not character:GetAttribute("IsRagdolled") then return end

	humanoid.PlatformStand = false

	for _, joint in ipairs(character:GetDescendants()) do
		if joint:IsA("Motor6D") then
			pcall(function()
				joint.Enabled = true
			end)
		end
	end

	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BallSocketConstraint")
			or obj:IsA("Attachment")
			or obj.Name == "SkillRagdollingSystem"
			or obj.Name == "SkillRagdollHeadConstraint"
			or obj.Name == "SkillRagdollHeadAttachment0"
			or obj.Name == "SkillRagdollHeadAttachment1"
		then
			pcall(function() obj:Destroy() end)
		end
	end

	pcall(function()
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)

	ragdollStates[character] = nil
	character:SetAttribute("IsRagdolled", false)
end




function module.enableRagdoll(character, duration)
	if not character or not duration then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end


	if character:GetAttribute("IsRagdolled") then
		local newId = tick()
		ragdollStates[character] = { id = newId }

		task.delay(duration, function()
			if ragdollStates[character] and ragdollStates[character].id == newId and character:GetAttribute("IsRagdolled") then
				pcall(function()
					module.disableRagdoll(character)
				end)
			end
		end)

		return
	end

	humanoid.PlatformStand = true
	character:SetAttribute("IsRagdolled", true)

	for _, joint in ipairs(character:GetDescendants()) do
		if joint:IsA("Motor6D") and joint.Name ~= "Root" and joint.Name ~= "Waist"and joint.Name ~= "Neck" then
			local part0, part1 = joint.Part0, joint.Part1
			if part0 and part1 then
				local ok = pcall(function()
					local attachment0 = Instance.new("Attachment")
					local attachment1 = Instance.new("Attachment")
					attachment0.Name = "SkillRagdollingSystem"
					attachment1.Name = "SkillRagdollingSystem"
					attachment0.Parent = part0
					attachment1.Parent = part1
					attachment0.CFrame = CFrame.new(joint.C0.Position)
					attachment1.CFrame = CFrame.new(joint.C1.Position)

					local ballSocket = Instance.new("BallSocketConstraint")
					ballSocket.Name = "SkillRagdollingSystem"
					ballSocket.Attachment0 = attachment0
					ballSocket.Attachment1 = attachment1
					ballSocket.Parent = part1

					joint.Enabled = false
				end)
			end
		end
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local attachment = Instance.new("Attachment")
		attachment.Name = "SkillRagdollingSystem"
		attachment.Parent = hrp

		local alignOrientation = Instance.new("AlignOrientation")
		alignOrientation.Name = "SkillRagdollingSystem"
		alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
		alignOrientation.MaxTorque = 10000
		alignOrientation.Responsiveness = 30
		alignOrientation.Attachment0 = attachment
		alignOrientation.Parent = hrp
	end

	local torso = character:FindFirstChild("Torso")
	local head = character:FindFirstChild("Head")

	if torso and head and not torso:FindFirstChild("SkillRagdollHeadConstraint") then
		local att0 = Instance.new("Attachment")
		att0.Name = "SkillRagdollHeadAttachment0"
		att0.Parent = torso
		att0.Position = Vector3.new(0, 1.5, 0)

		local att1 = Instance.new("Attachment")
		att1.Name = "SkillRagdollHeadAttachment1"
		att1.Parent = head
		att1.Position = Vector3.new(0, -0.5, 0)

		local socket = Instance.new("BallSocketConstraint")
		socket.Name = "SkillRagdollHeadConstraint"
		socket.Attachment0 = att0
		socket.Attachment1 = att1
		socket.LimitsEnabled = true
		socket.TwistLimitsEnabled = false
		socket.Parent = torso
	end


	for limbName, attachPos in pairs(attachmentData) do
		local limb = character:FindFirstChild(limbName)
		if limb then
			local collisionPart = collisionPartTemplate:Clone()
			collisionPart.Name = "SkillRagdollingSystem"
			collisionPart.Parent = character

			local weld = Instance.new("Weld")
			weld.Name = "SkillRagdollingSystem"
			weld.Part0 = limb
			weld.Part1 = collisionPart
			weld.C0 = attachPos
			weld.Parent = collisionPart
		end
	end

	local ragdollId = tick()
	ragdollStates[character] = { id = ragdollId }

	task.delay(duration, function()
		if ragdollStates[character] and ragdollStates[character].id == ragdollId and character:GetAttribute("IsRagdolled") then
			pcall(function()
				module.disableRagdoll(character)
			end)
		end
	end)
end


function module.enableDeathRagdoll(character)
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	if character:GetAttribute("DeathRagdolled") then return end
	character:SetAttribute("DeathRagdolled", true)

	if character:GetAttribute("IsRagdolled") then
		module.disableRagdoll(character)
	end

	if not character:GetAttribute("IsAPlayer") then
		game.Debris:AddItem(character,3)
	end
	

	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	humanoid.RequiresNeck = false

	humanoid.PlatformStand = true
	character:SetAttribute("IsRagdolled", true)

	for _, joint in ipairs(character:GetDescendants()) do
		if joint:IsA("Motor6D") then
			local p0, p1 = joint.Part0, joint.Part1
			if p0 and p1 then
				local a0 = Instance.new("Attachment", p0)
				local a1 = Instance.new("Attachment", p1)

				a0.Position = joint.C0.Position
				a1.Position = joint.C1.Position
				a0.Name = "SkillRagdollingSystem"
				a1.Name = "SkillRagdollingSystem"

				local socket = Instance.new("BallSocketConstraint")
				socket.Attachment0 = a0
				socket.Attachment1 = a1
				socket.Parent = p1
				socket.Name = "SkillRagdollingSystem"

				joint.Enabled = false
			end
		end
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local att = Instance.new("Attachment")
		att.Parent = hrp
		att.Name = "SkillRagdollingSystem"

		local align = Instance.new("AlignOrientation")
		align.Mode = Enum.OrientationAlignmentMode.OneAttachment
		align.MaxTorque = 100000
		align.Responsiveness = 200
		align.Attachment0 = att
		align.CFrame = hrp.CFrame
		align.Parent = hrp
		align.Name = "SkillRagdollingSystem"
	end

	local torso, head = character:FindFirstChild("Torso"), character:FindFirstChild("Head")
	if torso and head then
		local weld = Instance.new("Weld")
		weld.Part0 = torso
		weld.Part1 = head
		weld.C0 = CFrame.new(0, 1.5, 0)
		weld.Parent = torso
		weld.Name = "SkillRagdollingSystem"
	end

	for limbName, attachPos in pairs(attachmentData) do
		local limb = character:FindFirstChild(limbName)
		if limb then
			local collision = collisionPartTemplate:Clone()
			collision.Parent = character
			collision.Name = "SkillRagdollingSystem"

			local weld = Instance.new("Weld")
			weld.Part0 = limb
			weld.Part1 = collision
			weld.C0 = attachPos
			weld.Parent = collision
			weld.Name = "SkillRagdollingSystem"
		end
	end
end


Event.OnServerEvent:Connect(function(Player)
	local character = Player.Character
	if character then module.disableRagdoll(character) end
end)

return module
