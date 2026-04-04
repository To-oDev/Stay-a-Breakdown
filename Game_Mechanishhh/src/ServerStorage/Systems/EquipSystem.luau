local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local UE = RS:WaitForChild("UISEvents")
local RSM = RS:WaitForChild("Modules")
local DBL = RSM:WaitForChild("DataBaseLibrarys")
local ReplicateEvent = UE:WaitForChild("ReplicateInventory")
local TeachingUpdate = UE:WaitForChild("TeachingUpdate")
local DataModules = SS:WaitForChild("DataModules")
local DataManager = require(DataModules:WaitForChild("DataManager"))
local DataSaver = require(DataModules:WaitForChild("DataSaver"))
local Handler = RS:WaitForChild("SystemAssets"):WaitForChild("SkillSystem"):WaitForChild("Handler")
local ISF =	require(RSM:WaitForChild("InventorySharedFunctions"))
local AIP = require(DBL:WaitForChild("ItemsLibrary"))
local WWM1 = require(DBL:WaitForChild("WeaponsWithM1"))
local SSS = require(SS:WaitForChild("Systems"):WaitForChild("SkillSystem"):WaitForChild("SkillSlotSystem"))
local ItemsProps = AIP.GetItemPropertys()

local module = {}

local Dictionary = {
	--En este diccionario agrego los nombres de stats que la neta me da weba explicar como funciona
	
}

local function AddStatsFromItem(Player,ItemStats,Type)
	for keyName,Value:number in pairs(ItemStats) do
		if Dictionary[keyName] then keyName = Dictionary[keyName] end
		
		if Player:GetAttribute(keyName) then
			if type(Value) == "number" and (Value > 0 or Value < 0) then
				local NewValue
				if Type == "Plus" then
					NewValue = Player:GetAttribute(keyName)+Value
				else
					NewValue = Player:GetAttribute(keyName)-Value
				end
				Player:SetAttribute(keyName,NewValue)
			end
		end
	end
end

local AcceptedItems = {Combat = true, Sword = true, Servant = true}
local ItemsToCheck = {"Servant","Combat","Sword"}

function module.AddToolOnPlayer(Player, equipment)
	if not Player.Character then
		Player.CharacterAdded:Wait()
	end
	
	DataSaver.GetPlayerData(Player)
		:andThen(function(PlayerProfile)
			local ItemID = Player:GetAttribute("Equipped" .. equipment)
			if not ItemID or ItemID == "" then return end

			local Inventory = PlayerProfile.Inventory.Data
			local ItemData = ISF.GetItem(Inventory, ItemID)
			local Item = ItemData and ItemData[3]
			if not Item then return end

			local PTable = ItemsProps[Item.PropertysID]
			if not PTable then return end
			
			
			
			
			local Tool
			Tool = Player.Character:FindFirstChildOfClass("Tool")
			if not Tool or not (Tool:GetAttribute("Type") == equipment) then
				Tool = nil
				for _, v in ipairs(Player.Backpack:GetChildren()) do
					if v:IsA("Tool") and v:GetAttribute("Type") == equipment then
						Tool = v
						break
					end
				end
			end
			if not Tool then
				Tool = Instance.new("Tool")
				Handler:Clone().Parent = Tool
			end

			local shinyValue = (Item.Stats and Item.Stats.Shiny) and Item.Stats.ShinySkin or nil

			Tool.Name = PTable.Name
			Tool.RequiresHandle = false
			Tool:SetAttribute("Name", PTable.Name)
			Tool:SetAttribute("ObjectID", ItemID)
			Tool:SetAttribute("Type", PTable.Type)
			Tool:SetAttribute("Shiny", shinyValue)
			Tool:SetAttribute("M1",WWM1.CheckForWeapon(PTable.Name))
			if PTable.Type == "Servant" then
				Player:SetAttribute("ServantName",shinyValue or PTable.Name)
			end
			
			Tool.Parent = Player.Backpack
			Tool.Handler.Enabled = true
			
			local ItemsData = PlayerProfile.ItemStats.Data.Teaching
			local toolName = PTable.Name
			local WeaponTeaching = ItemsData[toolName]
			if not WeaponTeaching then
				WeaponTeaching = {
					Exp = 0,
					ExpNeeded = 200,
					Level = 1,
				}
				ItemsData[toolName] = WeaponTeaching
			end
			

			SSS.ReplicateSkills(Player,ItemID)
			
			task.delay(3,function()
				TeachingUpdate:FireClient(Player,PTable.Type,WeaponTeaching.Exp,WeaponTeaching.ExpNeeded,WeaponTeaching.Level)
			end)
			Player.Character.Humanoid.Died:Connect(function()
				module.RemoveToolOnPlayer(Player, ItemID)
			end)
		end)
		:catch(function(err)
			warn("Error loading data:", err)
		end)
end

function module.RemoveToolOnPlayer(Player, ObjectID)
	if not Player or not ObjectID then return end
	local Char, Backpack = Player.Character, Player.Backpack
	if not Char or not Backpack then return end

	local function findToolWithID(container)
		for _, tool in ipairs(container:GetChildren()) do
			if tool:IsA("Tool") and tool:GetAttribute("ObjectID") == ObjectID then
				return tool
			end
		end
	end

	local Tool:Tool = findToolWithID(Char) or findToolWithID(Backpack)
	if not Tool then return end
	

	if Tool:IsDescendantOf(Char) and Tool:GetAttribute("ObjectID") == ObjectID then
		Tool.Parent = Backpack
	end
	task.delay(0.1,function()
		if Tool:GetAttribute("Type") == "Servant" then
			Player:SetAttribute("ServantName",nil)
		end
		Tool:Destroy()
	end)


end


function module.AddToolsOnStarterPlayer(Player)
	for _, equipment in ipairs(ItemsToCheck) do
		module.AddToolOnPlayer(Player, equipment)
	end
end

--local function GetOrCreateTeaching()
	--formula para la maestria
	--local NewMasteryExpNeeded = 200* ((Level + 1) ^ 1.4)
--end

function module.EquipItem(Player,ItemID)
	DataSaver.GetPlayerData(Player)
		:andThen(function(PlayerProfile)
			local Inventory = PlayerProfile.Inventory.Data
			
			local Item = ISF.GetItem(Inventory,ItemID)
			Item = Item[3]
			if not Item then return end
			local ItemProp = ItemsProps[Item.PropertysID]
			local Type = ItemProp.Type
			
			
			if not AcceptedItems[Type] then
				Item.Equipped = nil
				return
			end
			local LastEquipped = Player:GetAttribute("Equipped"..ItemProp.Type)
			
			if LastEquipped and LastEquipped ~= "" then
				local LastItem = ISF.GetItem(Inventory,LastEquipped)
				LastItem = LastItem[3]
				if not LastItem then return end
				LastItem.Equipped = false
				AddStatsFromItem(Player,LastItem.Stats,"Minus")
				DataManager.AddItem(Player,LastItem,1)
			end
			
			Item.Equipped = true
			
			DataManager.RemoveItem(Player,ItemID,1)
			AddStatsFromItem(Player,Item.Stats,"Plus")
			Player:SetAttribute("Equipped"..ItemProp.Type,ItemID)
			module.AddToolOnPlayer(Player,Type)
		end)
		:catch(function(err)
			warn("Error with data loading:", err)
		end)
end

function module.UnequipItem(Player,ItemID)
	DataSaver.GetPlayerData(Player)
		:andThen(function(PlayerProfile)
			local Inventory = PlayerProfile.Inventory.Data
			local Item = ISF.GetItem(Inventory,ItemID)
			Item = Item[3]
			if not Item then return end
			local ItemProp = ItemsProps[Item.PropertysID]
			local Type = ItemProp.Type
			DataManager.AddItem(Player,Item,1)
			Item.Equipped = false
			module.RemoveToolOnPlayer(Player,ItemID)
			ReplicateEvent:FireClient(Player,Item)
			Player:SetAttribute("Equipped"..ItemProp.Type,"")
		end)
		:catch(function(err)
			warn("Error with data loading:", err)
		end)
end

return module