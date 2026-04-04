local module = {}

local ChestTable = {
	{ item = "CommonChest", chance = 45 },
	{ item = "UncommonChest", chance = 35 },
	{ item = "RareChest", chance = 12.5 },
	{ item = "EpicChest", chance = 5 },
	{ item = "LegendaryChest", chance = 2 },
	{ item = "MythicChest", chance = 0.5 },
	{ item = "EventChest", chance = 0 },
}

function module.GetChances(Table)
		local roll = math.random() * 100
		local cumulative = 0

		for _, entry in ipairs(Table) do
			cumulative += entry.chance
			if roll <= cumulative then
				return entry.item
			end
		end
end

function module.GetRandomChest(Table)
	return module.GetChances(Table or ChestTable)
end

return module
