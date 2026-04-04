local NpcDialogue = {}
NpcDialogue.__index = NpcDialogue

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = game:GetService("Players")

local LocalPlayer = PlayerService.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local Utilities = ReplicatedStorage:FindFirstChild("Utilities")
local CanvasGroup = require(Utilities:FindFirstChild("CanvasGroup"))

local Template = script:FindFirstChild("Template")
local tweenInfo = TweenInfo.new(0.5)

local screenGui

if not PlayerGui:FindFirstChild("ReseteableUIS") then
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ReseteableUIS"
	screenGui.Parent = PlayerGui

	local folder = Instance.new("Folder")
	folder.Name = "NPC"
	folder.Parent = screenGui
else
	screenGui = PlayerGui:FindFirstChild("ReseteableUIS")
end

function NpcDialogue.new()
	local self = setmetatable({}, NpcDialogue)
	self.object = Template:Clone()

	self.canva = CanvasGroup.new(self.object)
	self.labelCanva = CanvasGroup.new(self.object:FindFirstChild("TextLabels"))

	self.labelCanva:PreloadComponents()
	self.canva:PreloadComponents()

	self.object.Parent = screenGui:FindFirstChild("NPC")
	self.object.Visible = true
	
	self.NextEvent = Instance.new("BindableEvent")

	self:Close()
	return self
end

function NpcDialogue:Open()
	self.canva:TweenTransparency(0, tweenInfo):Play()
end

function NpcDialogue:Close()
	self.canva:TweenTransparency(1, tweenInfo):Play()
end

function NpcDialogue:setHeader(header: string)
	local headerText = self.object:FindFirstChild("HeaderText", true)
	if not header or not headerText then return end
	headerText.Text = header
end

function NpcDialogue:setBody(body: string)
	local bodyText = self.object:FindFirstChild("BodyText", true)
	if not body or not bodyText then return end
	bodyText.Text = body
end

function NpcDialogue:TweenTexts(transparency: number)
	local tween = self.labelCanva:TweenTransparency(transparency, tweenInfo)
	tween:Play()
	return tween
end

function NpcDialogue:Speak(header: string, body: string)
	local tween = self:TweenTexts(1)
	tween.Completed:Wait()

	self:setHeader(header)
	self:setBody(body)

	self:TweenTexts(0)
end

----------------------------------------------------------------
--  🔵  SECUENCIA AUTOMÁTICA (con tiempos configurables)
----------------------------------------------------------------
function NpcDialogue:SpeakInSequence(sequence: table, delayBetween: number)
	if not sequence or #sequence == 0 then return end

	return coroutine.resume(coroutine.create(function()
		for _, data in ipairs(sequence) do
			local header = data.Header or data[1]
			local body = data.Body or data[2]

			-- Fade out
			local tweenOut = self:TweenTexts(1)
			tweenOut.Completed:Wait()

			-- Cambiar textos
			self:setHeader(header)
			self:setBody(body)

			-- Fade in
			local tweenIn = self:TweenTexts(0)
			tweenIn.Completed:Wait()

			task.wait(delayBetween)
		end
	end))
end

----------------------------------------------------------------
--  🔵  SECUENCIA INTERACTIVA (avanza al presionar un botón)
----------------------------------------------------------------

-- Función externa para avanzar
function NpcDialogue:RequestNext()
	self.NextEvent:Fire()
end

function NpcDialogue:WaitForNext()
	self.NextEvent.Event:Wait()
end

function NpcDialogue:SpeakInSequenceInteractive(sequence: table)
	if not sequence or #sequence == 0 then return end

	return coroutine.resume(coroutine.create(function()
		for _, data in ipairs(sequence) do

			local header = data.Header or data[1]
			local body = data.Body or data[2]

			local tweenOut = self:TweenTexts(1)
			tweenOut.Completed:Wait()

			self:setHeader(header)
			self:setBody(body)

			local tweenIn = self:TweenTexts(0)
			tweenIn.Completed:Wait()

			-- Espera sin bucles
			self:WaitForNext()
		end
	end))
end

function NpcDialogue:Destroy()
	self.object:Destroy()
	self.object = nil
end

return NpcDialogue