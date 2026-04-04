local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local RENDER_NAME = "CameraSway"
local turn = 0

local function lerp(a, b, t)
	return a + (b - a) * t
end

RunService:BindToRenderStep(
	RENDER_NAME,
	Enum.RenderPriority.Camera.Value + 1,
	function(deltaTime)
		if not camera then return end

		local mouseDelta = UserInputService:GetMouseDelta()
		turn = lerp(turn, math.clamp(mouseDelta.X, -6, 6), 6 * deltaTime)

		camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, math.rad(turn))
	end
)

script.Destroying:Connect(function()
	RunService:UnbindFromRenderStep(RENDER_NAME)
end)
