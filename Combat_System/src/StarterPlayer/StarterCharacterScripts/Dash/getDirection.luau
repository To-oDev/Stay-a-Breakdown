local lastFD = 1
local function getDirection(Humanoid, HumanoidRootPart)
	local moveDir = Humanoid.MoveDirection

	local lookCFrame = HumanoidRootPart.CFrame
	local forward = lookCFrame.LookVector
	local right = lookCFrame.RightVector

	local dotForward = forward:Dot(moveDir)
	local dotRight = right:Dot(moveDir)

	local verticalDir = ""
	local horizontalDir = ""

	if dotForward > 0.5 or (moveDir.Magnitude == 0) then
		if lastFD == 2 then
			lastFD = 1
		else
			lastFD+=1
		end
		verticalDir = "Forward"..tostring(lastFD)
	elseif dotForward < -0.5 then
		verticalDir = "Backward"
	end

	if dotRight > 0.5 then
		horizontalDir = "Right"
	elseif dotRight < -0.5 then
		horizontalDir = "Left"
	end

	if verticalDir ~= "" then
		return verticalDir
	elseif horizontalDir ~= "" then
		return horizontalDir
	end

	return "Unknown"
end

return getDirection