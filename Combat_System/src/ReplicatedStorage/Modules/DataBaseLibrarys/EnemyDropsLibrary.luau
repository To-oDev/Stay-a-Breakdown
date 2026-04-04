local AllPossibleDropsModule = require(game.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataBaseLibrarys"):WaitForChild("ItemsLibrary"))
local AllPossibleDrops = AllPossibleDropsModule.GetDropsTable()
local module = {}


local EnemyDrops = {
	["EnemyIA"] = {
		{
			Item = AllPossibleDrops.Exp,
			Amount = {5,20},

		},
		{
			Item = AllPossibleDrops.TeachingExp,
			Amount = {5,20},

		},
		{
			Item = AllPossibleDrops.Dims,
			Amount = {1,2},
		},
		{
			Item = AllPossibleDrops.Wood,
			Amount = {1,2},
			DropChance = 20
		},
	},
}

function module.GetEnemyDrops(Name)
	local drops = EnemyDrops[Name]
	if not drops then drops = EnemyDrops["EnemyIA"] 
	end
	if not drops then return nil end
	return drops
end

return module
