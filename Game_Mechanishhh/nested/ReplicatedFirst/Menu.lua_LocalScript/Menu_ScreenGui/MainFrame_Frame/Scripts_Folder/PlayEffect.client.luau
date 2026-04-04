local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

local player = PlayerService.LocalPlayer
local playerGui = player.PlayerGui

local MenuSounds = SoundService:WaitForChild("MenuSounds")
local menuSound = MenuSounds:WaitForChild("MenuSound")

local Utilities = ReplicatedStorage:WaitForChild("Utilities")
local CanvasGroup = require(Utilities:WaitForChild("CanvasGroup"))

local ScreenGui = script:FindFirstAncestorOfClass("ScreenGui")
local MainFrame = ScreenGui:WaitForChild("MainFrame")
local Body = MainFrame:WaitForChild("Body")

local playButton = Body:WaitForChild("PlayButton")
local canvasGroup = CanvasGroup.new(MainFrame, false)

local blur = script:WaitForChild("Blur")
local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

playButton.Activated:Once(function()
	local fadeTween = canvasGroup:TweenTransparency(1, tweenInfo)
	fadeTween:Play()

	blur.Parent = Lighting
	ScreenGui:SetAttribute("Active", false)

	local blurTween = TweenService:Create(
		blur,
		TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = 0}
	)
	blurTween:Play()

	fadeTween.Completed:Wait()
	blurTween.Completed:Wait()

	local soundTween = TweenService:Create(menuSound, tweenInfo, {Volume = 0})
	soundTween:Play()
	soundTween.Completed:Wait()

	menuSound:Stop()

	blur:Destroy()
	ScreenGui:Destroy()

	fadeTween:Destroy()
	blurTween:Destroy()
	soundTween:Destroy()
	ScreenGui:Destroy()
	playerGui:WaitForChild("UI").Enabled = true
end)