local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local character = script.Parent

local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local head = character:WaitForChild("Head")

local RENDER_NAME = "CameraFollower"
local lastOffset = Vector3.zero

RunService:BindToRenderStep(
	RENDER_NAME,
	Enum.RenderPriority.Camera.Value + 1,
	function(deltaTime)
		if character:GetAttribute("InCinematic") or character:GetAttribute("CastingSkill") then
			return
		end

		local targetOffset =
			rootPart.CFrame:VectorToObjectSpace(
				(head.Position + Vector3.new(0, -1, 0)) - rootPart.Position
			)

		lastOffset = lastOffset:Lerp(targetOffset, math.clamp(deltaTime * 10, 0, 1))
		humanoid.CameraOffset = lastOffset
	end
)

script.Destroying:Connect(function()
	RunService:UnbindFromRenderStep(RENDER_NAME)
	humanoid.CameraOffset = Vector3.zero
end)
