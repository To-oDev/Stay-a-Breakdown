local SE = game:GetService("ReplicatedStorage"):FindFirstChild("SystemEvents")
local UE = game:GetService("ReplicatedStorage"):FindFirstChild("UISEvents")
local EquipEvent = SE:FindFirstChild("EquipEvent")
local EquipTool = SE:FindFirstChild("EquipTool")
local VFXEvent = SE:FindFirstChild("FXEvent")
local ActivateTool = SE:FindFirstChild("ActivateTool")

local SystemFolder = game:GetService("ServerStorage"):FindFirstChild("Systems")
local CombatManager = require(SystemFolder:FindFirstChild("CombatSystem"))
local EquipSystem = require(SystemFolder:FindFirstChild("EquipSystem"))
local DataSaver = require(SystemFolder.Parent:WaitForChild("DataModules"):WaitForChild("DataSaver"))

EquipTool.OnServerEvent:Connect(function(Plr,Tool,Type)
	local PlrStats = DataSaver.GetSyncPlayerData(Plr)
	local Char = Plr.Character
	
	if Type then
		Char:SetAttribute("EquippedTool", Tool:GetAttribute("ObjectID"))
		Char:SetAttribute("EquippedToolType", Tool:GetAttribute("Type"))
		if Tool:GetAttribute("Type") == "Servant" then
			VFXEvent:FireAllClients("GrimoireReplicate", (Tool:GetAttribute("Shiny") or Tool:GetAttribute("Name")),"Equip",Plr)
			VFXEvent:FireAllClients("SwordReplicate",Char,(Tool:GetAttribute("Shiny") or Tool:GetAttribute("Name")))
		end
	else
		Char:SetAttribute("EquippedTool", nil)
		Char:SetAttribute("EquippedToolType", nil)
		if Tool:GetAttribute("Type") == "Servant" then
			VFXEvent:FireAllClients("GrimoireReplicate", nil,"Unequip",Plr)
			VFXEvent:FireAllClients("SwordUnreplicate",Char,Tool:GetAttribute("Type"))
		end
	end

	
end)

ActivateTool.OnServerEvent:Connect(function(Plr,Tool)
	local Character = Plr.Character
	local Humanoid = Character:FindFirstChild("Humanoid")
	if not Character or not Humanoid or not Plr then return end
	if Humanoid.Health <= 0 then return end
	local Combat = CombatManager.SetCombat()
	Combat.Character = Character
	Combat:Attack(Tool)
end)

EquipEvent.OnServerEvent:Connect(function(player,ItemID,Remove)
	if Remove then
		EquipSystem.UnequipItem(player,ItemID)
	else
		EquipSystem.EquipItem(player,ItemID)
	end
end)


