--Global
local RS = game:GetService("ReplicatedStorage")
local RSModules = RS:WaitForChild("Modules")

--Modules
local DataSaver = require(game:GetService("ServerStorage"):WaitForChild("DataModules"):WaitForChild("DataSaver"))
local ISF = require(RSModules:WaitForChild("InventorySharedFunctions"))
local AIP = require(RSModules:WaitForChild("DataBaseLibrarys"):WaitForChild("ItemsLibrary"))
--local SwordReplicator = require(RSModules:WaitForChild("SwordReplicator"))

--Declarations
local ItemPropertys = AIP.GetItemPropertys()
local NotificationEvent = RS:WaitForChild("UISEvents"):WaitForChild("ShowMessage")
local VFXEvent = RS:WaitForChild("SystemEvents"):WaitForChild("FXEvent")


local module = {}


local function ScaleStat(base, max, total)
	return math.floor(base + ((max - base) / 3499) * (total - 1))
end

local StatFunctions = {
	DP = function(Player)
		local Humanoid = Player.Character and Player.Character:FindFirstChild("Humanoid")
		if not Humanoid then return end
		local totalDP = Player:GetAttribute("TotalDP") or 1
		local newHealth = ScaleStat(20, 17500, totalDP)
		Player:SetAttribute("MaxHealth", newHealth)
		if Humanoid.Health == Humanoid.MaxHealth then
			Humanoid.MaxHealth = newHealth
			Humanoid.Health = newHealth
		else
			Humanoid.MaxHealth = newHealth
		end
	end,

	SwP = function(Player)
		local totalSP = Player:GetAttribute("TotalSwP") or 1
		local value = ScaleStat(1, 850, totalSP)
		Player:SetAttribute("BSwordDmg", value)
	end,

	MP = function(Player)
		local totalSP = Player:GetAttribute("TotalMP") or 1
		local value = ScaleStat(1, 800, totalSP)
		Player:SetAttribute("BMeleeDmg", value)
	end,

	SP = function(Player)
		local totalSP = Player:GetAttribute("TotalSP") or 1
		local mana = ScaleStat(100, 3000, totalSP)
		local serM = ScaleStat(1, 600, totalSP)
		local exDurM = ScaleStat(1, 5, totalSP)
		local currentMana, maxMana = Player:GetAttribute("Mana"), Player:GetAttribute("MaxMana")
		if currentMana == maxMana then
			Player:SetAttribute("Mana", mana)
		end
		Player:SetAttribute("MaxMana", mana)
		Player:SetAttribute("BServantMult", serM)
		Player:SetAttribute("BExtasisMult", exDurM)
	end
}

local function SetWeaponStats(Player,A1,A2,A3)
	Player:SetAttribute("WeaponName",A1)
	Player:SetAttribute("WeaponType",A2)
	Player:SetAttribute("WeaponUpgrades",A3)
end

local Blacklist = {}
local validStats = { "DP", "MP", "SwP", "SP" }
local CurrentMaxLevel = 3500
local PlayersLeveling = {}
local PlayersEffect = {}


local function GetChanges(AttributeName,Player)
	if Blacklist[AttributeName] then return end
	
		local baseStat
		if string.sub(AttributeName, 1, 5) == "Extra" then
			baseStat = string.sub(AttributeName, 6)
		else
			baseStat = AttributeName
		end
		
		if table.find(validStats, baseStat) then
			local NewValue = (Player:GetAttribute(baseStat) or 1) + (Player:GetAttribute("Extra"..baseStat) or 0)
			Player:SetAttribute("Total"..baseStat, NewValue)
			if StatFunctions[baseStat] then
				StatFunctions[baseStat](Player)
			end
		elseif AttributeName == "Exp" or AttributeName == "ExpNeeded" then
			task.spawn(function()
				local Exp, ExpNeeded, Level, SkP
				repeat
					Exp = Player:GetAttribute("Exp")
					ExpNeeded = Player:GetAttribute("ExpNeeded")
					Level = Player:GetAttribute("Level")
					SkP = Player:GetAttribute("SkP")
					task.wait(0.1)
				until (Exp and ExpNeeded and Level and SkP)


				if Level >= CurrentMaxLevel then
					if Exp > ExpNeeded then
						Player:SetAttribute("Exp", ExpNeeded)
					end
					return
				end

				if PlayersLeveling[Player] then return end

				if Exp >= ExpNeeded then
					PlayersLeveling[Player] = true

					task.spawn(function()
						while true do
							local CurrentExp = Player:GetAttribute("Exp")
							local CurrentExpNeeded = Player:GetAttribute("ExpNeeded")
							local CurrentLevel = Player:GetAttribute("Level")

							if not (CurrentExp and CurrentExpNeeded and CurrentLevel) then break end
							if CurrentLevel >= CurrentMaxLevel then break end
							if CurrentExp < CurrentExpNeeded then break end

							if not PlayersEffect[Player] then
								VFXEvent:FireAllClients("LevelUp", Player.Character)
								PlayersEffect[Player] = true
								task.delay(2, function()
									PlayersEffect[Player] = nil
								end)
							end

							Player:SetAttribute("Exp", math.max(0, CurrentExp - CurrentExpNeeded))
							Player:SetAttribute("Level", CurrentLevel + 1)
							Player:SetAttribute("SkP", Player:GetAttribute("SkP") + 4)

							local NewExpNeeded = math.floor(CurrentExpNeeded + (50 * math.log(CurrentLevel + 1)))
							Player:SetAttribute("ExpNeeded", NewExpNeeded)

							NotificationEvent:FireClient(Player, nil, "Level Increased (" .. tostring(CurrentLevel + 1) .. ")", "LevelUp", 3)

							task.wait()
						end

						PlayersLeveling[Player] = nil
						PlayersEffect[Player] = nil
					end)
				end
			end)
			
			
		elseif AttributeName == "BServantMult" or AttributeName == "EServantMult" then
			local TotalSerM = (Player:GetAttribute("BServantMult") or 1) + (Player:GetAttribute("EServantMult") or 0)
			Player:SetAttribute("TotalServantMult",TotalSerM)
			
		elseif AttributeName == "BExtasisMult" or AttributeName == "EExtasisMult" then
			local TotalExM = (Player:GetAttribute("BExtasisMult") or 1) + (Player:GetAttribute("EExtasisMult") or 0)
			Player:SetAttribute("TotalExtasisMult",TotalExM)
		elseif AttributeName == "BMeleeDmg" or AttributeName == "MeleeMult" then
			local TotalDmg = (Player:GetAttribute("BMeleeDmg") or 1) * (Player:GetAttribute("MeleeMult") or 1)
			Player:SetAttribute("TotalMeleeDmg",TotalDmg)
		elseif AttributeName == "BSwordDmg" or AttributeName == "SwordMult" then
			local TotalDmg = (Player:GetAttribute("BSwordDmg") or 1) * (Player:GetAttribute("SwordMult") or 1)
			Player:SetAttribute("TotalSwordDmg",TotalDmg)
		end
		

end


local function SetupAttribute(Player, AttrName, Value,Folder)
	Player:SetAttribute(AttrName, Value)
	GetChanges(AttrName, Player)
	Player:GetAttributeChangedSignal(AttrName):Connect(function()
		local newValue = Player:GetAttribute(AttrName)
		Folder[AttrName] = newValue
		GetChanges(AttrName, Player)
	end)
end


local function CreateAttributes(Player,Folder)
	for keyName, Value in pairs(Folder) do
		SetupAttribute(Player,keyName,Value,Folder)
	end
end


function module.AddAtributeAccess(Player,PStats,SessionData)
	CreateAttributes(Player,SessionData)
	CreateAttributes(Player,PStats)
end

function module.PlayerSetStartConfig(Character,SessionData)
	local MaxHealth = SessionData.MaxHealth
	local Humanoid = Character and Character:FindFirstChild("Humanoid")
	if not Humanoid then return end
	Humanoid.MaxHealth = MaxHealth
	Humanoid.Health = MaxHealth
end

return module