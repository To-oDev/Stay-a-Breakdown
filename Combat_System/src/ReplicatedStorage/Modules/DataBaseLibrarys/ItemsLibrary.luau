local AllItems = {
	--Stats
	Exp = {
		Name = "Exp",
		Amount = 0,
		Type = "Stat"
	},
	Dims = {
		Name = "Dims",
		Amount = 0,
		Type = "Stat"
	},
	TeachingExp = {
		Name = "TeachingExp",
		Amount = 0,
		Type = "Stat"
	},
	--Combate
	BasicCombat = {
		PropertysID = "BC1",
		Amount = 0,
		Equipped = false, 
		Stats = {
			Upgrades = 3,
			DamageMult = 0,
		},
	},
	
	--Material
	Wood = {
		PropertysID = "W1",
		Amount = 0,
	},

	--Espada
	BasicSword = {
		PropertysID = "BS1",
		Amount = 0,
		Equipped = false, 
		Stats = {
			Upgrades = 3,
			DamageMult = 0.5,
			WeaponType = "Greatsword",
		},
	},
	--Servant
	HarturiaDragon = {
		PropertysID = "HD1",
		Amount = 0,
		Equipped = false, 
		Stats = {
			Class = "Saber",
			Shiny = false,
		},
	},
	
	KuShulan = {
		PropertysID = "KS1",
		Amount = 0, 
		Equipped = false,
	
		Stats = {
			Class = "Lancer",
			Shiny = false,
		},
	},
	
	Sasako = {
		PropertysID = "Sas1",
		Amount = 0, 
		Equipped = false,

		Stats = {
			Class = "Assasin",
			Shiny = false,
		},
	},
	TheBegginersKey = {
		PropertysID = "TheBegginersKey1",
		Amount = 0,
	}
	
}

--// Soy frac, perdon por modificar tu codigo :(
--// NO BORRES ESTO, SIRVE PARA EL DISPLAY DE LOS SERVANTS //-- :) 
--// SOLO AÑADI ESTO Y MAS ABAJO HAY MAS COMENTARIOS POR LEER, BUENO SOLO 2 AAJAJAJ //--
local RaritysBackground = {
	Common = "rbxassetid://118893333763906",
	Epic = "rbxassetid://82326816069919",
	Legendary = "rbxassetid://96992051539650",
	Mythic = "rbxassetid://113416492899576",
	Shiny = "rbxassetid://106755067344252",
}

local AllItemsPropertys = {
	TheBegginersKey1 = {
		Name = "The Begginers Key",
		Description = "You were at the release of Stay Breakdown Universe!",
		ImageID = "rbxassetid://10736455115",
		Rarity = "Mythic",
		Type = "Material",
	},
	W1 = {
		Name = "Wood",
		Description = "A piece of wood...",
		ImageID = "rbxassetid://94624222357354",
		Rarity = "Common",
		Type = "Material",
	},
	BC1 = {
		Name = "Basic Combat",
		Description = "Average combat skills i think...",
		ImageID = "rbxassetid://104509847458490",
		Rarity = "Common",
		Type = "Combat",
		Equipable = true,
	},
	HD1 = { --Harturia Dragon
		Name = "Harturia Dragon",
		Description = "Use this grimoire to obtain the 'Saber' Servant abilities",
		ImageID = "rbxassetid://122118185668584",
		Rarity = "Legendary",
		Type = "Servant",
		Equipable = true,
	},
	HDH = { --Harturia Dragon Hasta
		Name = "Harturia Dragon",
		Description = "Use this grimoire to obtain the 'Saber' Servant abilities",
		ImageID = "rbxassetid://130747770944954",
		Rarity = "Mythic",
		Type = "Servant",
		Equipable = true,
	},
	BS1 = {
		Name = "Basic Sword",
		Description = "A piece of steel made to easily slice enemies",
		ImageID = "http://www.roblox.com/asset/?id=138980143308167",
		Rarity = "Common",
		Type = "Sword",
		Equipable = true,
	},
	KS1 = {
		Name = "Ku Shulan",
		Description = "Use this grimoire to obtain the 'Lancer' Servant abilities",
		ImageID = "rbxassetid://124174888276875",
		Rarity = "Epic",
		Type = "Servant",
		Equipable = true,
	},
	Sas1 = {
		Name = "Sasako",
		Description = "Use this grimoire to obtain the 'Assasin' Servant abilities",
		ImageID = "rbxassetid://124174888276875",
		Rarity = "Common",
		Type = "Servant",
		Equipable = true,
	}
}


local module = {}
local function CopyTable(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			copy[k] = CopyTable(v)
		else
			copy[k] = v
		end
	end
	return copy
end



function module.GetDropsTable()
	return AllItems
end
function module.GetItemPropertys()
	return AllItemsPropertys
end


function module.GetItemCopy(ItemName)
	local itemCopy
	if AllItems[ItemName] then
		itemCopy = CopyTable(AllItems[ItemName])
	else
		itemCopy = CopyTable(ItemName)
	end
	return itemCopy
end

function module.ApplyDropOverrides(drop,items)
	for key, value in pairs(items) do
		if key ~= "Item" and key ~= "DropChance" then
			if typeof(value) == "table" and key ~= "Stats" then
				drop[key] = math.random(unpack(value))
			else

				drop[key] = value
			end
		end
	end
	return drop
end


return module