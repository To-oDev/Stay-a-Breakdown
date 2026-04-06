--Services
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local TS = game:GetService("TweenService")
local DM = SS:WaitForChild("DataModules")
--Modules
local EnemyDrops = require(RS:WaitForChild("Modules"):WaitForChild("DataBaseLibrarys"):WaitForChild("EnemyDropsLibrary"))
local ItemLibrary = require(RS:WaitForChild("Modules"):WaitForChild("DataBaseLibrarys"):WaitForChild("ItemsLibrary"))
local DataManager = require(DM:WaitForChild("DataManager"))
local DataSaver = require(DM:WaitForChild("DataSaver"))
local HCS = require(SS:WaitForChild("Systems"):WaitForChild("HitCalculateService"))
local ISF = require(RS:WaitForChild("Modules"):WaitForChild("InventorySharedFunctions"))

--Events
local Event = RS:WaitForChild("SystemEvents"):WaitForChild("FXEvent")
local UE = RS:WaitForChild("UISEvents")
local ItemNotification = UE:WaitForChild("ShowItemAdded")
local TeachingUpdate = UE:WaitForChild("TeachingUpdate")
--Requirements
local AllPropertysTable = ItemLibrary.GetItemPropertys()
local MaxTeachingLevel = 600
local module = {}

local function AddTeachingExpByItem(ItemStats, TeachingName, expToAdd,Player,Source)
	if not ItemStats or not TeachingName or not expToAdd or expToAdd <= 0 then
		return
	end

	ItemStats.Teaching = ItemStats.Teaching or {}

	if not ItemStats.Teaching[TeachingName] then
		ItemStats.Teaching[TeachingName] = {
			Exp = 0,
			ExpNeeded = 200,
			Level = 1
		}
	end

	local Teaching = ItemStats.Teaching[TeachingName]

	local exp = math.floor((Teaching.Exp or 0) + expToAdd)
	local level = Teaching.Level or 1
	local expNeeded = Teaching.ExpNeeded or 200

	if level >= MaxTeachingLevel then
		Teaching.Level = MaxTeachingLevel
		Teaching.Exp = math.min(exp, expNeeded)
		Teaching.ExpNeeded = expNeeded
		return
	end

	while exp >= expNeeded and level < MaxTeachingLevel do
		exp -= expNeeded
		level += 1
		expNeeded = math.floor(200 * ((level + 1) ^ 1.4))
	end

	if level >= MaxTeachingLevel then
		level = MaxTeachingLevel
		exp = math.min(exp, expNeeded)
	end

	Teaching.Level = level
	Teaching.Exp = exp
	Teaching.ExpNeeded = expNeeded
	TeachingUpdate:FireClient(Player,Source,exp,expNeeded,level)

end


local function StatFunction(Player,drop,Source)
	local stat = Player:GetAttribute(drop.Name)
	if drop.Name == "TeachingExp" and Source then
		if Player:GetAttribute("Equipped"..Source) then
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
					
					AddTeachingExpByItem(ItemStats, TeachingName, drop.Amount,Player,Source)
				end
			end
		end
	elseif stat then
		local newValue = stat + drop.Amount
	end
end

local function rollChance(percentChance)
	local scale = 100000 
	return math.random(1, scale) <= (percentChance * scale / 100)
end


function module.CalculateReward(Player,Table,Source)
	if not Table then return end
	local drops = ItemLibrary.GetItemCopy(Table)
	if drops.MinimumDamage then
		drops.MinimumDamage = nil
	end
	
	if not drops then return end
	for _, drop in pairs(drops) do
		ItemLibrary.ApplyDropOverrides(drop.Item,drop)
		local CorrectDrop = drop.Item
		if CorrectDrop.Type ~= "Stat" then
			if drop.DropChance and rollChance(drop.DropChance) then
				DataManager.AddItem(Player, CorrectDrop)
			else
				DataManager.AddItem(Player,CorrectDrop)
				
			end
		else
			
			if drop.DropChance and rollChance(drop.DropChance) then
				StatFunction(Player,CorrectDrop,Source)
				ItemNotification:FireClient(Player,CorrectDrop.Name,nil,CorrectDrop.Amount)
			else
				StatFunction(Player,CorrectDrop,Source)
				ItemNotification:FireClient(Player,CorrectDrop.Name,nil,CorrectDrop.Amount)
			end
		end
	end
	
end


function module.RewardEnemy(Enemy)
	local enemyId = Enemy:GetAttribute("EnemyID")
	if not enemyId then return end

	local Folder = HCS.GetEnemyData(enemyId)
	if not Folder or not Folder.Players then return end

	local DropTable = EnemyDrops.GetEnemyDrops(Enemy.Name)
	if not DropTable then return end

	local MinimumDmg = DropTable.MinimumDamage

	for playerName, data in pairs(Folder.Players) do
		if MinimumDmg and data.DamageDealt < MinimumDmg then
			continue
		end

		local Player = game.Players:FindFirstChild(playerName)
		if not Player then
			continue
		end

		module.CalculateReward(Player, DropTable, data.LastHitSource)

		if Player.Character then
			Event:FireClient(Player, "SoulsFunction", Enemy)
		end
	end
end

return module
