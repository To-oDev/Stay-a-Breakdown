local ScreenGui = script:FindFirstAncestorOfClass("ScreenGui")
local MainFrame = ScreenGui:FindFirstChildOfClass("Frame")
local Body = MainFrame:FindFirstChild("Body")

local Background = Body:FindFirstChild("Background")
local TileImage = Background:FindFirstChild("TileImage")

local tileImage = "rbxassetid://74074776971068"
local speed = 100

local direction = Vector2.new(-1, 0)

local function TweenCompleted(state)
	if not ScreenGui:GetAttribute("Active") then return end
	
	if state == Enum.TweenStatus.Completed then
		TileImage.Position = UDim2.new(0, 0, 0, 0)
		TileImage:TweenPosition(UDim2.new(direction.X, 0, direction.Y, 0), "Out", "Linear", speed, false, TweenCompleted)
	end
end

TileImage.Image = tileImage
TileImage.TileImage2.Image = tileImage

ScreenGui:GetAttributeChangedSignal("Active"):Connect(function()
	if ScreenGui:GetAttribute("Active") then
		TileImage:TweenPosition(UDim2.new(direction.X, 0, direction.Y, 0), "Out", "Linear", speed, false, TweenCompleted)
	end
end)