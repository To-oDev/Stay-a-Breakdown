local RS = game:GetService("ReplicatedStorage")
local DBL = RS:WaitForChild("Modules"):WaitForChild("DataBaseLibrarys")
local SkillsLibrary = require(DBL:WaitForChild("SkillsLibrary"))
local DataSaver = require(game:GetService("ServerStorage"):WaitForChild("DataModules"):WaitForChild("DataSaver"))
local AIP = require(DBL:WaitForChild("ItemsLibrary"))
local ISF = require(DBL.Parent:WaitForChild("InventorySharedFunctions"))
local ItemPropertys = AIP.GetItemPropertys()
local RSS = RS:WaitForChild("UISEvents"):WaitForChild("RefreshSkillSlots")
local CooldownSystem = require(game:GetService("ServerStorage"):WaitForChild("Systems"):WaitForChild("CooldownSystem"))

local module = {}

function module.ReplicateSkills(Plr, ObjectID)
	if not Plr or not ObjectID then return end
	DataSaver.GetPlayerData(Plr)
		:andThen(function(PlayerProfile)
			local Inventory = PlayerProfile.Inventory.Data
			local Item = ISF.GetItem(Inventory,ObjectID)
			Item = Item[3]
			if not Item then return end
			local PTable = ItemPropertys[Item.PropertysID]
			local Type = PTable.Type
			local SkillTable = SkillsLibrary.GetSkillTable(Type,PTable.Name)
			if not SkillTable then return end
			CooldownSystem.SetOnCooldown(Plr,nil,nil,SkillTable,0.2)
			RSS:FireClient(Plr,SkillTable,Type,PTable,ObjectID)
		end)
		:catch(function(err)
			warn("Error with data loading:", err)
		end)
end

return module