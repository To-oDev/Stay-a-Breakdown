local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = game:GetService("Players")

local Utilities = ReplicatedStorage:FindFirstChild("Utilities")
local ContextActionUtility = require(Utilities:FindFirstChild("ContextActionUtility"))

local ATTRIBUTE_NAME = "MouseLockActive"

local function toggleMouseLock(actionName, inputState: Enum.UserInputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		PlayerService.LocalPlayer:SetAttribute(ATTRIBUTE_NAME, not PlayerService.LocalPlayer:GetAttribute(ATTRIBUTE_NAME))
	end
end

ContextActionUtility:BindAction(ATTRIBUTE_NAME, toggleMouseLock, true, false, Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl)
ContextActionUtility:SetImage(ATTRIBUTE_NAME, "rbxassetid://130693955229922")