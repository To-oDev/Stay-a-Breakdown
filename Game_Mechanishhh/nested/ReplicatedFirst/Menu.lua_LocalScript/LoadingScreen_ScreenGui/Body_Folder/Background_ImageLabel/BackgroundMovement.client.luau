local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local image = script:FindFirstAncestorOfClass("ImageLabel")
local rectSize = image.ImageRectSize

local imageSize = Vector2.new(500, 500)

local maxOffsetX = imageSize.X - rectSize.X
local maxOffsetY = imageSize.Y - rectSize.Y

local centerOffset = Vector2.new(maxOffsetX / 100, maxOffsetY)

local targetOffset = centerOffset
local currentOffset = centerOffset

local smoothness = 0.08
local strength = 0.08

local function UpdateFromPercent(percentX, percentY)
	targetOffset = Vector2.new(
		maxOffsetX * (percentX - 0.5) * strength + centerOffset.X,
		maxOffsetY * (percentY - 0.5) * strength + centerOffset.Y
	)
end

UIS.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		local mousePos = UIS:GetMouseLocation()
		local screenSize = workspace.CurrentCamera.ViewportSize

		UpdateFromPercent(
			mousePos.X / screenSize.X,
			mousePos.Y / screenSize.Y
		)
	end

	if input.UserInputType == Enum.UserInputType.Touch then
		local touchPos = input.Position
		local screenSize = workspace.CurrentCamera.ViewportSize

		UpdateFromPercent(
			touchPos.X / screenSize.X,
			touchPos.Y / screenSize.Y
		)
	end
	
	if input.UserInputType == Enum.UserInputType.Gamepad1 
		and input.KeyCode == Enum.KeyCode.Thumbstick2 then
		local pos = input.Position

		local percentX = (pos.X + 1) / 2
		local percentY = (pos.Y + 1) / 2

		UpdateFromPercent(percentX, percentY)
	end
end)

RunService.RenderStepped:Connect(function()
	currentOffset = currentOffset:Lerp(targetOffset, smoothness)
	image.ImageRectOffset = currentOffset
end)