local AllPossibleDropsModule = require(game.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataBaseLibrarys"):WaitForChild("ItemsLibrary"))
local AllPossibleDrops = AllPossibleDropsModule.GetDropsTable()
local module = {}


local ChestDrops = {
	["CommonChest"] = {
		[1] = {
			{
				Item = AllPossibleDrops.Exp,
				Amount = {5,10},

			},
			{
				Item = AllPossibleDrops.Dims,
				Amount = {0,10},
			},

			{
				Item = AllPossibleDrops.ForbiddenDemonSlayer,
				Amount = {1,1},
				DropChance = 100, -- 100% de probabilidad
				Upgrades = {0,3},
				Fused = true,
			},
			{
				Item = AllPossibleDrops.Wood,
				Amount = {1,2},
				DropChance = 20 -- 20% de probabilidad
			},
		},
		[2] = {
			{
				Item = AllPossibleDrops.Exp,
				Amount = {5,10},

			},
			{
				Item = AllPossibleDrops.DSouls,
				Amount = {0,10},
			},
		},

	},
}

function module.GetChestDrops(Name)
	local drops = ChestDrops[Name]
	if not drops then return nil end
	return drops
end

return module