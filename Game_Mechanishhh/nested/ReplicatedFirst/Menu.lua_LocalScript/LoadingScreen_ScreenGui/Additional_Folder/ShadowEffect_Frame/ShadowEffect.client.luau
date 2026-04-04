local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local MenuSounds = SoundService:WaitForChild("MenuSounds")

local ShadowEffect = script:FindFirstAncestorOfClass("Frame")
local UIGradient = ShadowEffect:WaitForChild("UIGradient")

local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function getOffset()
	local reverse = ShadowEffect:GetAttribute("Reverse")

	if reverse then
		return Vector2.new(-1, 0)
	else
		return Vector2.new(1, 0)
	end
end

local function AnimateShadowEffect()
	local offset = getOffset()

	local tween = TweenService:Create(UIGradient, tweenInfo, {
		Offset = offset
	})
	
	if not MenuSounds.LoadDisappear.IsPlaying and offset == Vector2.new(1, 0) then
		MenuSounds.LoadDisappear:Play()
	end
	
	tween:Play()
	tween.Completed:Wait()
end

ShadowEffect.Visible = true
ShadowEffect:GetAttributeChangedSignal("Play"):Connect(function()
	local play = ShadowEffect:GetAttribute("Play")
	if not play then return end
	
	AnimateShadowEffect()
	ShadowEffect:SetAttribute("Play", false)
end)