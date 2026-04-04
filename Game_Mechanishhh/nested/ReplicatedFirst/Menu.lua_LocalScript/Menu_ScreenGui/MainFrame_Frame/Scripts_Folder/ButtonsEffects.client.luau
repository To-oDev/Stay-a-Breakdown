local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Utilities = ReplicatedStorage:WaitForChild("Utilities")
local CanvasGroup = require(Utilities:WaitForChild("CanvasGroup"))

local ScreenGui = script:FindFirstAncestorOfClass("ScreenGui") 
local MainFrame = ScreenGui:WaitForChild("MainFrame")

local Windows = MainFrame:WaitForChild("Windows")
local Body = MainFrame:WaitForChild("Body")

local Additional = MainFrame:WaitForChild("Additional")
local indicator = Additional:WaitForChild("Indicator")

local MenuSounds = SoundService:WaitForChild("MenuSounds")

local hoverTween = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local pressTween = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local openTween = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local closeTween = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
local indicatorTween = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local frameTween = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- 🔥 SCALE TWEENS
local frameOpenScaleTween = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local frameCloseScaleTween = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local openPosition = UDim2.new(0.85, 0, 0.5, 0)
local closePosition = UDim2.new(1.5, 0, 0.5, 0)

local currentFrame = nil
local currentButton = nil
local canvasGroups = {}
-- // UTILIDADES

local function tween(object, info, goal)
	local tw = TweenService:Create(object, info, goal)
	tw:Play()
	return tw
end

local function cambiarNombre(nombre)
	return nombre:gsub("Button", "Frame")
end

-- 🔥 Obtener / crear UIScale
local function getFrameScale(frame)
	local scale = frame:FindFirstChildOfClass("UIScale")

	if not scale then
		scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = frame
	end

	return scale
end

-- FRAME ANIMATION
local function toggleFrame(frame, open)
	if not frame then return end

	local scale = getFrameScale(frame)

	if open then
		scale.Scale = 0.9

		tween(scale, frameOpenScaleTween, {
			Scale = 1
		})

		tween(frame, openTween, {
			Position = openPosition
		})
		
		canvasGroups[frame.Name]:TweenTransparency(0, frameTween):Play()
	else
		tween(scale, frameCloseScaleTween, {
			Scale = 0.9
		})

		tween(frame, closeTween, {
			Position = closePosition
		})
		
		canvasGroups[frame.Name]:TweenTransparency(1, frameTween):Play()
	end
end

-- INDICATOR
local function moveIndicator(button)
	indicator.Visible = true

	tween(indicator, indicatorTween, {
		ImageTransparency = 0,
		Position = UDim2.new(
			button.Position.X.Scale,
			button.Position.X.Offset + button.AbsoluteSize.X * 0.6,
			button.Position.Y.Scale,
			button.Position.Y.Offset
		)
	})
end

local function hideIndicator()
	tween(indicator, indicatorTween, {
		ImageTransparency = 1
	})
end

-- BUTTON SCALE
local function scaleButton(button, scale)
	local uiScale = button:FindFirstChildOfClass("UIScale")

	if uiScale then
		tween(uiScale, hoverTween, {Scale = scale})
	end
end

-- HOVER
local function onButtonHover(button, imageColor3, textColor3)
	if not ScreenGui:GetAttribute("Active") then return end

	tween(button, hoverTween, {ImageColor3 = imageColor3})
	scaleButton(button, 1.07)

	if button:FindFirstChild("TextLabel") then
		tween(button.TextLabel, hoverTween, {
			TextColor3 = textColor3 or imageColor3
		})
	end

	if imageColor3 == Color3.fromRGB(47,47,47) then
		scaleButton(button, 1)
		hideIndicator()
	else
		moveIndicator(button)
	end
end

-- PRESS EFFECT
local function pressEffect(button)
	local uiScale = button:FindFirstChildOfClass("UIScale")
	if not uiScale then return end

	tween(uiScale, pressTween, {Scale = 0.92})
	task.wait(0.05)
	tween(uiScale, hoverTween, {Scale = 1.07})
end

-- BOTONES

for _, button in ipairs(Body:GetChildren()) do
	if not button:IsA("ImageButton") then continue end

	local frameButton = Windows:FindFirstChild(cambiarNombre(button.Name))
	
	if frameButton then
		canvasGroups[frameButton.Name] = CanvasGroup.new(frameButton)
	end
	
	button.MouseEnter:Connect(function()
		onButtonHover(button, Color3.fromRGB(152,152,152), Color3.fromRGB(255,255,255))
	end)

	button.MouseLeave:Connect(function()
		onButtonHover(button, Color3.fromRGB(47,47,47))
	end)

	button.InputBegan:Connect(function(input)
		local t = input.UserInputType

		if t == Enum.UserInputType.MouseButton1
			or t == Enum.UserInputType.Touch
			or t == Enum.UserInputType.Gamepad1 then

			pressEffect(button)
		end
	end)

	button.Activated:Connect(function()
		if button.Name == "PlayButton" then
			MenuSounds.PlayButton:Play()
			return
		end

		if currentFrame == frameButton then
			toggleFrame(frameButton, false)
			currentFrame = nil
			currentButton = nil
			MenuSounds.ButtonClick:Play()
			return
		end

		if currentFrame then
			toggleFrame(currentFrame, false)
		end

		toggleFrame(frameButton, true)

		currentFrame = frameButton
		currentButton = button

		MenuSounds.ButtonClick:Play()
	end)
end