local ReplicatedFirst = game:GetService("ReplicatedFirst")
local PlayerService = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

ReplicatedFirst:RemoveDefaultLoadingScreen()
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

local connection

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local player = PlayerService.LocalPlayer
local playerGui = player.PlayerGui

local loadingScreen = script:FindFirstChild("LoadingScreen")
loadingScreen.Parent = playerGui

local menuScreen = script:FindFirstChild("Menu")
playerGui:WaitForChild("UI").Enabled = false

connection = loadingScreen:GetAttributeChangedSignal("Active"):Connect(function()
	if not loadingScreen:GetAttribute("Active") then
		menuScreen.Parent = playerGui
		menuScreen:SetAttribute("Active", true)
		
		task.delay(3, function()
			connection:Disconnect()
			loadingScreen:Destroy()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
		end)
	end
end)

task.wait(0.1)
loadingScreen:SetAttribute("Active", true)