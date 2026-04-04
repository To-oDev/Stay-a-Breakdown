local RS = game:GetService("ReplicatedStorage")
local RemoteFunct = RS:WaitForChild("SystemEvents"):WaitForChild("Checkout")
local Event = RS:WaitForChild("UISEvents"):WaitForChild("ShowMessage")
local CooldownSystem = require(game:GetService("ServerStorage"):WaitForChild("Systems"):WaitForChild("CooldownSystem"))
local ItemLibrary = require(RS:WaitForChild("Modules"):WaitForChild("DataBaseLibrarys"):WaitForChild("ItemsLibrary"))
local DataSaver = require(game:GetService("ServerStorage"):WaitForChild("DataModules"):WaitForChild("DataSaver"))
local ISF = require(RS:WaitForChild("Modules"):WaitForChild("InventorySharedFunctions"))
local AllPropertysTable = ItemLibrary.GetItemPropertys()

RemoteFunct.OnServerInvoke = function(Player,Function,Params)
	
	if Function == "SetCooldown" then
		CooldownSystem.SetOnCooldown(Player,Params.Skill)
	elseif Function == "CheckCooldown" then
		return CooldownSystem.GetCooldown(Player,Params.Skill,Params.ID)
	elseif Function == "GetCooldown" then
		if not Params.Skill then return end
		local Skill = Params.Skill
		local Cooldown = Skill.Cooldown


		if Params.CostCheck then
			local Cost = Skill.Cost
			local Source = Skill.Source
			
			
			-----------
			
			local PlayerData = DataSaver.GetSyncPlayerData(Player)
			local Inventory = PlayerData.Inventory.Data
			local ItemID = Player:GetAttribute("Equipped"..Source)
			if not ItemID or not Inventory then return end
			local Item = ISF.GetItem(Inventory,ItemID)
			Item = Item[3]
			local PTable = AllPropertysTable[Item.PropertysID]
			if Item and PTable then
				local ItemStats = PlayerData.ItemStats.Data
				if ItemStats then
					local TeachingName = PTable.Name
					local Teaching = ItemStats.Teaching[TeachingName]
					if Teaching and Teaching.Level < Skill.Teaching then
						--return "Insufficient Teaching!"
					end
				end
			end
			
			
			if (Player:GetAttribute("Mana") - Cost) < 0 and not (Player.Character:GetAttribute("IsUnbridled")) then
				Event:FireClient(Player, "Warning", "Insufficient Mana!", "Warning", 3)
				return nil
			elseif Player.Character:GetAttribute("IsUnbridled") then
				return Cooldown
			else
				local newValue = Player:GetAttribute("Mana") - Cost
				Player:SetAttribute("Mana", newValue)

				return Cooldown
			end
		else
			return Cooldown
		end
	end
	
	
	
end