local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utilities = ReplicatedStorage:WaitForChild("Utilities")
local ContextActionUtility = require(Utilities:WaitForChild("ContextActionUtility"))
local CFSModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SharedLocalScriptFuncts"))

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local humanoid = character:WaitForChild("Humanoid")
local BaseSpeed = ReplicatedStorage:WaitForChild("SystemEvents"):WaitForChild("BaseSpeed")

local ACTION_NAME = "ToggleRunning"
local isRunning = humanoid:GetAttribute("Running") or false

local function handleShift(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then return end
	if CFSModule.CFS(character) == 1 then return end

	local running = humanoid:GetAttribute("Running")
	if not running then
		humanoid:SetAttribute("Running", true)
		BaseSpeed:InvokeServer("Run")
	else
		humanoid:SetAttribute("Running", false)
		BaseSpeed:InvokeServer("Walk")
	end
end

-- Actualizar variable local cuando cambie el atributo
humanoid:GetAttributeChangedSignal("Running"):Connect(function()
	isRunning = humanoid:GetAttribute("Running")
end)

-- Cancelar correr si hay algún estado especial (CFS)
game:GetService("RunService").Heartbeat:Connect(function()
	if CFSModule.CFS(character) > 0 and humanoid:GetAttribute("Running") then
		humanoid:SetAttribute("Running", false)
	end
end)

-- Configurar controles
ContextActionUtility:BindAction(
	ACTION_NAME,
	handleShift,
	true,
	false,
	Enum.KeyCode.LeftShift,
	Enum.KeyCode.RightShift
)

ContextActionUtility:SetImage(ACTION_NAME, "rbxassetid://112162455426129")
ContextActionUtility:SetTransparency(ACTION_NAME, 0.4)