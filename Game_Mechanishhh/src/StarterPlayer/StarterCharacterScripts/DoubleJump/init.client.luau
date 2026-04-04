local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local animator = humanoid:WaitForChild("Animator")

local CFSModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("SharedLocalScriptFuncts"))

local jumpAnim = animator:LoadAnimation(script:WaitForChild("DoubleJump"))

local DOUBLE_JUMP_POWER = 40
local WALL_JUMP_POWER = 42
local VELOCITY_DURATION = 0.18
local WALL_CHECK_DISTANCE = 3
local WALL_RESET_COOLDOWN = 0.5

local canDoubleJump = false
local lastWallReset = 0
local usedDoubleJump = false

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true
rayParams.CollisionGroup = "Players"
rayParams.FilterDescendantsInstances = { character }

local function applyVerticalVelocity(power)
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = Vector3.new(0, power, 0)
	bv.MaxForce = Vector3.new(0, math.huge, 0)
	bv.P = 1250
	bv.Parent = root

	task.delay(VELOCITY_DURATION, function()
		if bv then bv:Destroy() end
	end)
end

local function isNearWall()
	local directions = {
		root.CFrame.LookVector,
		-root.CFrame.LookVector,
		root.CFrame.RightVector,
		-root.CFrame.RightVector
	}

	for _, dir in ipairs(directions) do
		local result = Workspace:Raycast(root.Position, dir * WALL_CHECK_DISTANCE, rayParams)
		if result then
			return true
		end
	end

	return false
end

local function tryAirJump()
	if CFSModule.CFS(character) > 0 then return end
	if humanoid:GetState() == Enum.HumanoidStateType.Dead then return end

	local state = humanoid:GetState()
	if state ~= Enum.HumanoidStateType.Freefall then return end

	if canDoubleJump and not usedDoubleJump then
		usedDoubleJump = true
		jumpAnim:Play()
		applyVerticalVelocity(DOUBLE_JUMP_POWER)
	end
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode ~= Enum.KeyCode.Space then return end

	local now = tick()

	if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		if isNearWall() and now - lastWallReset >= WALL_RESET_COOLDOWN then
			lastWallReset = now
			usedDoubleJump = false
			jumpAnim:Play()
			applyVerticalVelocity(WALL_JUMP_POWER)
			return
		end

		tryAirJump()
	end
end)

humanoid.StateChanged:Connect(function(_, newState)
	if newState == Enum.HumanoidStateType.Landed then
		canDoubleJump = true
		usedDoubleJump = false
	elseif newState == Enum.HumanoidStateType.Jumping then
		canDoubleJump = true
	end
end)

script.Destroying:Connect(function()
	jumpAnim:Stop()
end)