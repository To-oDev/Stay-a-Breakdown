local ScreenGui = script:FindFirstAncestorOfClass("ScreenGui")
local Information = ScreenGui:WaitForChild("Information")
local Additional = ScreenGui:WaitForChild("Additional")
local Body = ScreenGui:WaitForChild("Body")

local connection
local transitioning = false
local DELAY_TIME = 3

local function disableAll(container: Instance?, blacklist: {string}?)
	if not container then return end
	blacklist = blacklist or {}

	for _,v in pairs(container:GetChildren()) do
		if v:IsA("GuiObject") then
			if not table.find(blacklist, v.Name) then
				v.Visible = false
			end
		end
	end
end

local function FadeIn()
	if transitioning then return end
	transitioning = true

	Additional.ShadowEffect.Visible = true

	task.delay(0.2, function()
		Additional.ShadowEffect:SetAttribute("Reverse", false)
		Additional.ShadowEffect:SetAttribute("Play", true)

		transitioning = false
	end)
end

local function FadeOut()
	if transitioning then return end
	transitioning = true

	Additional.ShadowEffect:SetAttribute("Reverse", true)
	Additional.ShadowEffect:SetAttribute("Play", true)

	task.delay(0.5, function()
		disableAll(Body)
		disableAll(Information)
		disableAll(Additional, {"ShadowEffect"})

		transitioning = false
		task.wait(0.2)
		FadeIn()
	end)
end

connection = ScreenGui:GetAttributeChangedSignal("Active"):Connect(function()
	local active = ScreenGui:GetAttribute("Active")

	if active then
		FadeIn()
		task.wait(DELAY_TIME)
		script.Parent.LoaderHandler.Enabled = true
	else
		FadeOut()
	end
end)