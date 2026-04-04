local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local humanoid = character:WaitForChild("Humanoid")
local animator: Animator = humanoid:WaitForChild("Animator")
local rootPart = character:WaitForChild("HumanoidRootPart")

local CFSModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SharedLocalScriptFuncts"))
local Utilities = ReplicatedStorage:WaitForChild("Utilities")
local ContextActionUtility = require(Utilities:WaitForChild("ContextActionUtility"))
local getDirection = require(script:WaitForChild("getDirection"))

local Config = {
	DashSpeed = 140,
	MinEndSpeed = 25,
	DashRate = 3.2,
	DashCooldown = 0.42,
	DashDuration = 0.42,
}

local Animations = script:WaitForChild("Animations")
local dashAnimations = {}

for _, anim in ipairs(Animations:GetChildren()) do
	local track = animator:LoadAnimation(anim)
	track.Name = "DashAnim"
	dashAnimations[anim.Name] = track
end

local function playAnimation(action)
	local track = dashAnimations[action]
	if not track then return end

	for _, playing in ipairs(animator:GetPlayingAnimationTracks()) do
		if playing.Name == "DashAnim" then
			playing:Stop(0.1)
		end
	end

	track:Play(0.15)
end

local function getDashSpeed(t)
	local alpha = math.exp(-Config.DashRate * t)
	return Config.MinEndSpeed + (Config.DashSpeed - Config.MinEndSpeed) * alpha
end

local lastDashTime = 0
local isDashing = false
local dashConn: RBXScriptConnection?
local cleanupConn: RBXScriptConnection?

local function cleanupDash(LV: LinearVelocity?, att: Attachment?)
	if dashConn then
		dashConn:Disconnect()
		dashConn = nil
	end

	if cleanupConn then
		cleanupConn:Disconnect()
		cleanupConn = nil
	end

	if LV and LV.Parent then
		LV:Destroy()
	end

	if att and att.Parent then
		att:Destroy()
	end

	character:RemoveTag("DisableLand")
	isDashing = false
end

local function performDash()
	if isDashing then return end
	if CFSModule.CFS(character) > 0 then return end

	local now = os.clock()
	if now - lastDashTime < Config.DashCooldown then return end
	lastDashTime = now
	isDashing = true

	local moveDir = humanoid.MoveDirection.Magnitude > 0
		and humanoid.MoveDirection
		or rootPart.CFrame.LookVector

	moveDir = Vector3.new(moveDir.X, 0, moveDir.Z)
	if moveDir.Magnitude == 0 then
		isDashing = false
		return
	end

	moveDir = moveDir.Unit

	playAnimation(getDirection(humanoid, rootPart))
	character:AddTag("DisableLand")
	humanoid:SetAttribute("STAMINA_STATE", "Dash")

	local att = Instance.new("Attachment")
	att.Parent = rootPart

	local LV = Instance.new("LinearVelocity")
	LV.Attachment0 = att
	LV.RelativeTo = Enum.ActuatorRelativeTo.World
	LV.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	LV.MaxAxesForce = Vector3.new(20000, 0, 20000)
	LV.Parent = rootPart

	local startTime = os.clock()
	local smoothedDir = moveDir

	dashConn = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		if elapsed >= Config.DashDuration then
			cleanupDash(LV, att)
			return
		end

		local targetDir = humanoid.MoveDirection.Magnitude > 0
			and humanoid.MoveDirection
			or rootPart.CFrame.LookVector

		targetDir = Vector3.new(targetDir.X, 0, targetDir.Z)
		if targetDir.Magnitude > 0 then
			targetDir = targetDir.Unit
		end

		smoothedDir = smoothedDir:Lerp(targetDir, 0.18)
		LV.VectorVelocity = smoothedDir * getDashSpeed(elapsed)
	end)

	humanoid.Died:Once(function()
		cleanupDash(LV, att)
	end)

	cleanupConn = character.AncestryChanged:Once(function(_, parent)
		if not parent then
			cleanupDash(LV, att)
		end
	end)
end

local function onDashAction(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then return end
	performDash()
end

ContextActionUtility:BindAction("Dash", onDashAction, true, false, Enum.KeyCode.Q)
ContextActionUtility:SetImage("Dash", "rbxassetid://117790806364444")
ContextActionUtility:SetTransparency("Dash", 0.4)

script.Destroying:Connect(function()
	ContextActionUtility:DisableAction("Dash")
	isDashing = false
end)