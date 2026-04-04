local TweenService = game:GetService("TweenService")

local button = script.Parent
local buttonText = button:FindFirstChild("TextLabel")
local UIStroke = button:FindFirstChild("UIStroke")

local normalColor = button.BackgroundColor3
local h,s,v = normalColor:ToHSV()

local darkColor = Color3.fromHSV(h, s, v * 0.7)
local pressedColor = Color3.fromHSV(h, s, v * 0.55)

local textNormal = Color3.fromRGB(255,255,255)
local textDark = Color3.fromRGB(200,200,200)

local originalSize = button.Size
local pressedSize = originalSize - UDim2.fromOffset(4,4)

local hoverTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local pressTweenInfo = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local fadeTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

button.BackgroundColor3 = darkColor
buttonText.TextColor3 = textDark
UIStroke.Transparency = 1

local destroyed = false
local connections = {}

local function ShowButton()
	button.Visible = true

	TweenService:Create(button, fadeTweenInfo, {
		BackgroundTransparency = 0
	}):Play()

	TweenService:Create(buttonText, fadeTweenInfo, {
		TextTransparency = 0
	}):Play()

	TweenService:Create(UIStroke, fadeTweenInfo, {
		Transparency = 1
	}):Play()
end

local function HideButton()
	local fadeTween = TweenService:Create(button, fadeTweenInfo, {
		BackgroundTransparency = 1
	})

	TweenService:Create(buttonText, fadeTweenInfo, {
		TextTransparency = 1
	}):Play()

	TweenService:Create(UIStroke, fadeTweenInfo, {
		Transparency = 1
	}):Play()

	fadeTween:Play()
	fadeTween.Completed:Wait()

	button.Visible = false
end

local function UpdateActive()
	if destroyed then return end

	local active = button:GetAttribute("Active")

	if active then
		ShowButton()
	else
		HideButton()
	end
end

button:GetAttributeChangedSignal("Active"):Connect(UpdateActive)
UpdateActive()

local function disconnectAll()
	for _,conn in pairs(connections) do
		conn:Disconnect()
	end
	table.clear(connections)
end

connections.hoverEnter = button.MouseEnter:Connect(function()
	TweenService:Create(button, hoverTweenInfo, {
		BackgroundColor3 = normalColor
	}):Play()

	TweenService:Create(buttonText, hoverTweenInfo, {
		TextColor3 = textNormal
	}):Play()

	TweenService:Create(UIStroke, hoverTweenInfo, {
		Transparency = 0
	}):Play()
end)

connections.hoverLeave = button.MouseLeave:Connect(function()
	TweenService:Create(button, hoverTweenInfo, {
		BackgroundColor3 = darkColor
	}):Play()

	TweenService:Create(buttonText, hoverTweenInfo, {
		TextColor3 = textDark
	}):Play()

	TweenService:Create(UIStroke, hoverTweenInfo, {
		Transparency = 1
	}):Play()
end)

connections.click = button.MouseButton1Click:Connect(function()
	destroyed = true
	disconnectAll()

	TweenService:Create(button, pressTweenInfo, {
		BackgroundColor3 = pressedColor,
		Size = pressedSize
	}):Play()

	task.wait(0.08)

	local fadeTween = TweenService:Create(button, fadeTweenInfo, {
		BackgroundTransparency = 1,
	})

	TweenService:Create(buttonText, fadeTweenInfo, {
		TextTransparency = 1
	}):Play()

	TweenService:Create(UIStroke, fadeTweenInfo, {
		Transparency = 1
	}):Play()

	fadeTween:Play()
	fadeTween.Completed:Wait()

	button:Destroy()
end)