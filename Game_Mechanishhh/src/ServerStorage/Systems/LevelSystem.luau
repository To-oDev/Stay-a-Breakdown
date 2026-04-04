local DataSaver = require(game:GetService("ServerStorage"):WaitForChild("DataModules"):WaitForChild("DataSaver"))

local LevelCap = 3500
local RankLevelCap = {
	C = 2000,
	B = 2250,
	A = 2500,
	S = 3000,
	SS = 3500,
}
local StatTable = {
	DefenseStat = {
		StatName = "DP",
		StatRank = "DefenseRank"
	},
	MeleeStat = {
		StatName = "MP",
		StatRank = "MeleeRank"
	},
	SwordStat = {
		StatName = "SwP",
		StatRank = "SwordRank"
	},
	ServantStat = {
		StatName = "SP",
		StatRank = "ServantRank"
	},
}

local module = {}



function module.UpgradeStat(Player,PointsSpent,StatName)
	DataSaver.GetPlayerData(Player)
		:andThen(function(PlayerProfile)
			local StatValues = PlayerProfile.Stats.Data
			local Rank = StatTable[StatName].StatRank
			StatName = StatTable[StatName].StatName 
			local StatLevelCap = RankLevelCap[StatValues[Rank]]
			
			
			local StatValue = StatValues[StatName]
			local SkillPValue = StatValues.SkP
			
	
			if SkillPValue >= PointsSpent and StatValue and StatValue < StatLevelCap then
				if (StatValue + PointsSpent) <= StatLevelCap then
					StatValue += PointsSpent
					SkillPValue -= PointsSpent
				else
					local Difference = StatLevelCap - StatValue
					StatValue += Difference
					SkillPValue -= Difference
				end
			elseif PointsSpent > SkillPValue and StatValue and StatValue < StatLevelCap then
				local Difference = SkillPValue
				if StatValue + Difference <= StatLevelCap then
					StatValue += Difference
					SkillPValue -= Difference
				else
					local Difference2 = StatLevelCap - StatValue
					StatValue += Difference2
					SkillPValue -= Difference2
				end
			end
			Player:SetAttribute("SkP",SkillPValue)
			Player:SetAttribute(StatName,StatValue)
		end)
		:catch(function(err)
			warn("Error with data loading:", err)
		end)
end



return module
