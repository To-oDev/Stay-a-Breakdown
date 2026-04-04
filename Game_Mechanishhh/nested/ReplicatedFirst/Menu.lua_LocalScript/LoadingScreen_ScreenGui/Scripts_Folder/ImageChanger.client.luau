local TweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local ScreenGui = script:FindFirstAncestorOfClass("ScreenGui")
local Body = ScreenGui:WaitForChild("Body")

local Images = {
	"rbxassetid://125986255340061",
	"rbxassetid://102349659765755",
	"rbxassetid://112069124073563",
	"rbxassetid://72364383531804",
}

local function changeImage(i)
	local Image = Images[i]

	local tween = TweenService:Create(Body.Background, tweenInfo, {
		ImageColor3 = Color3.fromRGB(0, 0, 0)
	})

	tween:Play()
	tween.Completed:Wait()

	Body.Background.Image = Image

	TweenService:Create(Body.Background, tweenInfo, {
		ImageColor3 = Color3.fromRGB(104, 104, 104)
	}):Play()
end

task.spawn(function()
	while true do
		for i = 1, #Images do
			changeImage(i)
			task.wait(6)
		end
	end
end)