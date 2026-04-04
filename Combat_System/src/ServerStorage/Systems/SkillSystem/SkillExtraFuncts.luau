local module = {}

local function createAttachment(parent)
	local a = Instance.new("Attachment")
	a.Name = "SkillGripAttach"
	a.Parent = parent
	return a
end

local function safeDisconnect(conn)
	if conn then
		conn:Disconnect()
	end
end


local function cleanupGrip(playerPart, enemyPart)
	if enemyPart and enemyPart.Parent then

		for _, bp in ipairs(enemyPart.Parent:GetDescendants()) do
			if bp:IsA("BasePart") then
				bp.CollisionGroup = "Players"
			end
		end

		if enemyPart:GetAttribute("CanceledAttach") then
			enemyPart:SetAttribute("CanceledAttach", nil)
			enemyPart.Anchored = false
		end
	end

	for _, obj in ipairs({"SkillGripPart", "SkillGripAttach"}) do
		local found = playerPart and playerPart:FindFirstChild(obj, true)
		while found do
			found:Destroy()
			found = playerPart:FindFirstChild(obj, true)
		end

		local found2 = enemyPart and enemyPart:FindFirstChild(obj, true)
		while found2 do
			found2:Destroy()
			found2 = enemyPart:FindFirstChild(obj, true)
		end
	end
end

function module.SetUpGrip(enable, playerPart, enemyPart, offset, lookAt)
	if not enable then
		return cleanupGrip(playerPart, enemyPart)
	end

	if not playerPart or not enemyPart then return end
	if not playerPart.Parent or not enemyPart.Parent then return end

	local playerHum = playerPart.Parent:FindFirstChild("Humanoid")
	local enemyHum = enemyPart.Parent:FindFirstChild("Humanoid")
	if not playerHum or not enemyHum then return end
	if playerHum.Health <= 0 or enemyHum.Health <= 0 then return end

	for _, bp in ipairs(enemyPart.Parent:GetDescendants()) do
		if bp:IsA("BasePart") then
			bp.CollisionGroup = "Special"
		end
	end

	local gripPart = Instance.new("Part")
	gripPart.Name = "SkillGripPart"
	gripPart.Size = Vector3.new(0.5, 0.5, 0.5)
	gripPart.Transparency = 1
	gripPart.CanCollide = false
	gripPart.CanQuery = false
	gripPart.Anchored = false
	gripPart.Massless = true
	gripPart.CFrame = playerPart.CFrame + (offset or Vector3.zero)
	gripPart.Parent = playerPart
	gripPart:SetNetworkOwner(nil)
	
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = gripPart
	weld.Part1 = playerPart
	weld.Parent = gripPart

	local plrAtt = createAttachment(gripPart)
	local enemyAtt = createAttachment(enemyPart)
	local lookAtt = createAttachment(playerPart)
	if lookAt then
		lookAtt.Position = lookAt
	end
	

	enemyAtt.Orientation = Vector3.new(0, 90, 0)

	local ap = Instance.new("AlignPosition")
	ap.Attachment0 = enemyAtt
	ap.Attachment1 = plrAtt
	ap.Responsiveness = 200
	ap.MaxForce = math.huge
	ap.Parent = enemyAtt

	local ao = Instance.new("AlignOrientation")
	ao.Attachment0 = enemyAtt
	ao.Attachment1 = lookAtt
	ao.AlignType = Enum.AlignType.PrimaryAxisLookAt
	ao.MaxTorque = math.huge
	ao.Responsiveness = 200
	ao.Parent = enemyAtt
	
	task.spawn(function()
		local t = 0
		local maxTime = 10

		while t < maxTime do
			if not enemyPart.Parent 
				or not playerPart.Parent 
				or not gripPart 
				or not gripPart.Parent 
			then
				break
			end
			if enemyPart:GetAttribute("CanceledAttach") then break end
			if not lookAtt or not lookAtt.Parent then break end
			local selfPos = enemyPart.Position
			local targetPos = lookAtt.WorldPosition
			enemyPart.CFrame = CFrame.lookAt(selfPos, targetPos)
			t += task.wait()
		end
	end)


	local c1, c2, c3

	c1 = playerHum.Died:Connect(function()
		enemyPart:SetAttribute("CanceledAttach", true)
		enemyPart.Anchored = true
		cleanupGrip(playerPart, enemyPart)
		safeDisconnect(c1); safeDisconnect(c2); safeDisconnect(c3)
	end)

	c2 = playerPart.Parent.AncestryChanged:Connect(function(_, parent)
		if not parent then
			enemyPart:SetAttribute("CanceledAttach", true)
			enemyPart.Anchored = true
			cleanupGrip(playerPart, enemyPart)
			safeDisconnect(c1); safeDisconnect(c2); safeDisconnect(c3)
		end
	end)

	c3 = gripPart.AncestryChanged:Connect(function(_, parent)
		if not parent then
			cleanupGrip(playerPart, enemyPart)
			safeDisconnect(c1); safeDisconnect(c2); safeDisconnect(c3)
		end
	end)

	return gripPart
end

return module
