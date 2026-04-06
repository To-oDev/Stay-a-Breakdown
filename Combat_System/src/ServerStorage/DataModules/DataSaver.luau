local RS = game:GetService("ReplicatedStorage")
local Promise = require(RS:WaitForChild("Modules"):WaitForChild("Promise"))
local ProfileStore = require(game:GetService("ServerStorage"):WaitForChild("DataModules"):WaitForChild("ProfileStore"))
local GetSyncPP = RS:WaitForChild("SystemEvents"):WaitForChild("GetSyncPP")
local Players = game:GetService("Players")

local PlantillaParaUnItem = { --Esta es la estructura de los items que voy a guardar en el inventario del jugador
	{
		--General
		Name = "NombreItem", -- Nombre del item
		Amount = 0,--La cantidad de items
		ItemID = "",--El id unico de un item con ciertas caracteristicas
		PropertysID = "", --El id de las propiedades constantes que tendra ese objeto: Descripcion,tipo,rareza,imagen etc...
		--Esto lo van a contener todos los items del juego


		--Atributos extra
		--Tradable = true, --o false/nil si no es tradeable (opcional)
		--Lo cambie a las propertys xd
		------
		--Atributos extra para armas o servants, +daño,+vida, etc....
		Stats = {

		},
		--Atributos unicos de un arma
		--Equipped = false
		--Tambien lo cambiare a las propertys xd
	}
}


--Plantillas para hacer los inventarios y stats
local ItemStatsTemplate = {
	Teaching = {},
	Evolutions = {},
}
local InventoryTemplate = {}
local StatsTemplate = {
	--Rangos Base
	DefenseRank = "C",
	MeleeRank = "C",
	SwordRank = "C",
	ServantRank = "C",

	--Stats Base
	SkP = 0; --Puntos de skill
	MP = 1, --Melee
	DP = 1, --Defense
	SP = 1, --Servant
	SwP = 1, --Sword, lo cambie a sword porque es mas general
	--Cosas del nivel
	Level = 1,
	Exp = 0,
	ExpNeeded = 200,

	--Economia
	Dims = 0,
	Quartz = 0,

	--Equipamiento
	EquippedServant = "",
	EquippedSword = "",
	EquippedCombat = "",
	Race = "Human",
	--Si necesitamos mas atributos los agregare aqui
}

--La session data son datos que se calculan en el gameplay y que no se necesitan guardar permanentemente
--para evitar el guardado de stats innecesarios y agilizar la carga
local function createSessionData() 
	return {
		--Equis
		Mana = 100,
		ManaExtasis = 0,
		
		--Combat
		CurrentCombo = 1,
		MaxCombo = 0,
		--Stats
		MaxHealth = 20,
		MaxMana = 100,

		--Bases
		BMeleeDmg = 1,
		BSwordDmg = 1,
		--Multiplicadores base
		BServantMult = 1,
		BExtasisMult = 1,

		--Extras (opcionales)
		MeleeMult = 1, --Multiplica el daño base
		SwordMult = 1, --Multiplica el daño base

		EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
		EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

		TotalMeleeDmg = 1,
		TotalSwordDmg = 1,
		TotalServantMult = 1,
		TotalExtasisMult = 1,

		ExtraMP = 0,
		TotalMP = 1,
		----
		ExtraDP = 0,
		TotalDP = 1,
		----
		ExtraSP = 0,
		TotalSP = 1,
		----
		ExtraSwP = 0,
		TotalSwP = 1,
	}
end


local Profiles = {} --Aqui se guardan las referencias a los datos de los jugadores que entren
local PendingProfiles = {} -- Aqui se guardan las promises en curso

--las promises es una funcion asincrona que retorna un valor ya que las condiciones de cargado se cumplan, para evitar que en
--scripts importantes ocurran fallos por querer acceder a la data antes de ser cargada

local DataStores = {
	PlayersStats = ProfileStore.New("Stats", StatsTemplate),
	PlayersInventory = ProfileStore.New("Inventorys", InventoryTemplate),
	PlayersItemStats = ProfileStore.New("ItemStats",ItemStatsTemplate)
}

local module = {}

local function AddData(player: Player)
	if Profiles[player] then
		return Promise.resolve(Profiles[player]) 
	end
	
	if PendingProfiles[player] then
		return PendingProfiles[player] 
	end

	local loadPromise = Promise.new(function(resolve, reject)
		local userId = tostring(player.UserId)

		local inventoryProfile = DataStores.PlayersInventory:StartSessionAsync(userId, {
			Cancel = function() return player.Parent ~= Players end
		})

		local statsProfile = DataStores.PlayersStats:StartSessionAsync(userId, {
			Cancel = function() return player.Parent ~= Players end
		})

		local itemstatsProfile = DataStores.PlayersItemStats:StartSessionAsync(userId, {
			Cancel = function() return player.Parent ~= Players end
		})


		if inventoryProfile and statsProfile then
			inventoryProfile:AddUserId(player.UserId)
			statsProfile:AddUserId(player.UserId)
			itemstatsProfile:AddUserId(player.UserId)


			inventoryProfile:Reconcile()
			statsProfile:Reconcile()
			itemstatsProfile:Reconcile()
			

			
			local function EndSession()
				Profiles[player] = nil
				player:Kick("Profile session ended - please rejoin")
			end

			inventoryProfile.OnSessionEnd:Connect(EndSession)
			statsProfile.OnSessionEnd:Connect(EndSession)
			itemstatsProfile.OnSessionEnd:Connect(EndSession)

			Profiles[player] = {
				Inventory = inventoryProfile,
				Stats = statsProfile,
				ItemStats = itemstatsProfile,
				SessionData = createSessionData(),
			}
			
			print("All important data loaded for:", player.Name)
			PendingProfiles[player] = nil
			resolve(Profiles[player])
		else
			PendingProfiles[player] = nil
			reject("Failed to load data for: " .. player.Name)
		end
	end)

	PendingProfiles[player] = loadPromise
	return loadPromise
end

Players.PlayerAdded:Connect(function(player)
	AddData(player):catch(function(err)
		warn(err)
		player:Kick("Error loading data. Please rejoin.")
	end)
	
	--DataStores.PlayersStats:RemoveAsync(tostring(player.UserId))
	--DataStores.PlayersInventory:RemoveAsync(tostring(player.UserId))
	--DataStores.PlayersItemStats:RemoveAsync(tostring(player.UserId))

	--DataStores.PlayersStats:RemoveAsync("475931502")
	--DataStores.PlayersInventory:RemoveAsync("475931502")
	--DataStores.PlayersItemStats:RemoveAsync("475931502")

end)



Players.PlayerRemoving:Connect(function(player)
	local profileData = Profiles[player]
	if profileData then
		profileData.Inventory:EndSession()
		profileData.Stats:EndSession()
		profileData.ItemStats:EndSession()
	end
	Profiles[player] = nil
	PendingProfiles[player] = nil
end)


function module.GetPlayerData(player)
	return Promise.new(function(resolve, reject)
		if Profiles[player] then
			resolve(Profiles[player])
			return
		end
		if PendingProfiles[player] then
			PendingProfiles[player]:andThen(resolve):catch(reject)
			return
		end
		AddData(player):andThen(resolve):catch(reject)
	end)
end
local Enemys = {
	
	["Black Order"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 1,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 1,
		},
	},
	["Black Order Boss"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 1,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 1,
		},
	},
	["Cursed Oathbearer"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 1,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 1,
		},
	},
	["Cursed Oathbearer Boss"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 1,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 1,
		},
	},
	["Eternal Vow"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 1,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 1,
		},
	},
	["Eternal Vow Boss"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 1,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 1,
		},
	},
	["Executor"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 1,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 1,
		},
	},
	["Executor Boss"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 1,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 1,
		},
	},
	["Final Agreement"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 1,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 1,
		},
	},
	["Final Agreement Boss"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 1,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 1,
		},
	},
	["Nameless Reaper"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 1,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 1,
		},
	},
	["Nameless Reaper Boss"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 1,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 1,
		},
	},
	["Oathbound"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 2,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 2,
		},
	},
	["Oathbound Boss"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 5,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 1,
		},
	},
	["Radiant Order"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 1,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 1,
		},
	},
	["Radiant Order Boss"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 1,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 1,
		},
	},
	["Shadowbound Ronin"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 1,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 1,
		},
	},
	["Shadowbound Ronin Boss"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 1,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 1,
		},
	},
	["Warbound Colossus"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 1,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 1,
		},
	},
	["Warbound Colossus Boss"] = {
		SessionData = {
			--Equis
			Mana = 100,
			ManaExtasis = 0,

			--Combat
			CurrentCombo = 1,
			MaxCombo = 0,
			--Stats
			MaxHealth = 20,
			MaxMana = 100,

			--Bases
			BMeleeDmg = 1,
			BSwordDmg = 1,
			--Multiplicadores base
			BServantMult = 1,
			BExtasisMult = 1,

			--Extras (opcionales)
			MeleeMult = 1, --Multiplica el daño base
			SwordMult = 1, --Multiplica el daño base

			EServantMult = 0, --Multiplicador extra agregado a el daño de los servant
			EExtasisMult = 0, --Multiplicador extra del modo extasis (La sobrecarga)

			TotalMeleeDmg = 1,
			TotalSwordDmg = 1,
			TotalServantMult = 1,
			TotalExtasisMult = 1,

			ExtraMP = 0,
			TotalMP = 1,
			----
			ExtraDP = 0,
			TotalDP = 1,
			----
			ExtraSP = 0,
			TotalSP = 1,
			----
			ExtraSwP = 0,
			TotalSwP = 1,
		},
	},
}
function module.GetSyncPlayerData(player)
	if not player then return end
	if player:IsA("Model") then
		local PP = Enemys[player.Name]
		return { 
			Stats = PP.Stats,
			ItemStats = PP.ItemStats,
			SessionData = PP.SessionData,
		}
	else
		return Profiles[player]
	end
	
end


--Esta funcion con una remotefunction la puse para que los scripts locales puedan acceder a los datos, ya que este script esta 
--en ServerStorage y solo es accesible mediante el servidor
GetSyncPP.OnServerInvoke = function(player)
		local PP = Profiles[player]
		return { 
			Stats = PP.Stats.Data,
			Inventory = PP.Inventory.Data,
			ItemStats = PP.ItemStats.Data,
			SessionData = PP.SessionData,
		}
end


return module