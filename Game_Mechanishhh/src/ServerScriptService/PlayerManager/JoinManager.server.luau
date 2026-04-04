local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local SystemFolder = SS:WaitForChild("Systems")
local SystemEvents = RS:WaitForChild("SystemEvents")
local Players = game:GetService("Players")
--Modulos 

local LevelSystem = require(SystemFolder:WaitForChild("LevelSystem"))
local StatSystem = require(SystemFolder:WaitForChild("StatSystem"))
local ChestSystem = require(SystemFolder:WaitForChild("ChestSystem"))
local ChargeManager = require(SystemFolder:WaitForChild("ChargeManager"))
local EquipSystem = require(SystemFolder:WaitForChild("EquipSystem"))
local DataModule = require(SS:WaitForChild("DataModules"):WaitForChild("DataSaver"))
local ISF = require(RS:WaitForChild("Modules"):WaitForChild("InventorySharedFunctions"))


local MAX_LEVEL = 600
local TeachingCons = {}
local function TeachingTracing(plr: Player)
	local conn
	conn = plr:GetAttributeChangedSignal("TeachingExp"):Connect(function()
		if not plr.Parent then
			if conn then conn:Disconnect() end
			return
		end

		local exp = plr:GetAttribute("TeachingExp")
		local level = plr:GetAttribute("TeachingLevel")
		local expNeeded = plr:GetAttribute("TeachingExpNeeded")

		if not exp or not level or not expNeeded then return end

		exp = math.floor(exp)

		if level >= MAX_LEVEL then
			plr:SetAttribute("TeachingLevel", MAX_LEVEL)
			plr:SetAttribute("TeachingExp", math.min(exp, expNeeded))
			plr:SetAttribute("TeachingExpNeeded", expNeeded)
			return
		end

		local leveledUp = false

		while exp >= expNeeded and level < MAX_LEVEL do
			exp -= expNeeded
			level += 1
			expNeeded = math.floor(200 * ((level + 1) ^ 1.4))
			leveledUp = true
		end

		if level >= MAX_LEVEL then
			level = MAX_LEVEL
			exp = math.min(exp, expNeeded)
		end

		if leveledUp then
			plr:SetAttribute("TeachingLevel", level)
			plr:SetAttribute("TeachingExpNeeded", expNeeded)
			plr:SetAttribute("TeachingExp", exp)
		end
	end)
	TeachingCons[plr] = conn
end
game.Players.PlayerRemoving:Connect(function(plr)
	if TeachingCons[plr] then
		TeachingCons[plr]:Disconnect()
		TeachingCons[plr] = nil
	end
end)


--Los eventos correspondientes los declaro encima de cada funcion, para encontrarlos mas facil
local USEvent = SystemEvents:WaitForChild("UpgradeStat")
USEvent.OnServerEvent:Connect(function(Player, StatName, PointsSpent)
	LevelSystem.UpgradeStat(Player,PointsSpent,StatName)
end)


--Sistema de rage
local CRageEvent = RS:WaitForChild("SystemAssets"):WaitForChild("ChargeSystem"):WaitForChild("Events"):WaitForChild("ChargeRage")
CRageEvent.OnServerEvent:Connect(function(plr,chr,Type)
	if Type == true then
		ChargeManager.StartChargeRage(chr)
	else
		ChargeManager.StopChargeRage(chr)
	end
end)


local InventoryReplicator = RS:WaitForChild("UISEvents"):WaitForChild("ReplicateInventory")
Players.PlayerAdded:Connect(function(Player)
	DataModule.GetPlayerData(Player)
		:andThen(function(PlayerProfile)
			--Atribute Manager-----
			local SessionData = PlayerProfile.SessionData
			local PStats = PlayerProfile.Stats.Data
			Player.CharacterAdded:Connect(function(Character)
				StatSystem.PlayerSetStartConfig(Character,SessionData)
				EquipSystem.AddToolsOnStarterPlayer(Player)
			end)
			StatSystem.PlayerSetStartConfig(Player.Character,SessionData)
			StatSystem.AddAtributeAccess(Player,PStats,SessionData)
			EquipSystem.AddToolsOnStarterPlayer(Player)
			-------------------------------------------------------
			TeachingTracing(Player)
			--Inventory Replication----------------
			local ItemsTable = ISF.GetAllItems(PlayerProfile.Inventory.Data)
			ChestSystem.ReplicateChests(Player)
			for i,item in pairs(ItemsTable) do
				InventoryReplicator:FireClient(Player,item)
			end
			---------------------------------------
		end)
		:catch(function(err)
			warn("Error with data loading:", err)
		end)
end)