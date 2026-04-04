--Services
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")

--------------------------------

--Declarations
local Modules = RS:WaitForChild("Modules")

-----------


--Modules
local ISF = require(Modules:WaitForChild("InventorySharedFunctions"))
local DataSaver = require(game:GetService("ServerStorage"):WaitForChild("DataModules"):WaitForChild("DataSaver"))
local ItemsProp = require(Modules:WaitForChild("DataBaseLibrarys"):WaitForChild("ItemsLibrary"))
local ItemPropTable = ItemsProp.GetItemPropertys()
---------------

--Events
local UE = RS:WaitForChild("UISEvents")
local ItemNotificacion = UE:WaitForChild("ShowItemAdded")
local ReplicateEvent = UE:WaitForChild("ReplicateInventory")
--------------------------------------------------------


local module = {}

local function ShowNewMessage(Player,Amount,PTable)
	ItemNotificacion:FireClient(Player,PTable.Name,PTable.ImageID,Amount,PTable.Rarity)
end


------------------------------------
--Funciones GLOBALES--------------------------------
----------------------------------------------------
local function ItemsAreEqual(item1, item2, blacklist)
	for key, value in pairs(item1) do
		if not blacklist[key] then
			if item2[key] ~= value then
				return false
			end
		end
	end

	for key, value in pairs(item2) do
		if not blacklist[key] then
			if item1[key] ~= value then
				return false
			end
		end
	end

	if item1.Stats ~= nil and item2.Stats ~= nil then
		if typeof(item1.Stats) ~= "table" or typeof(item2.Stats) ~= "table" then return end
		for key, value in pairs(item1.Stats) do
			if not blacklist[key] then
				if item2.Stats[key] ~= value then
					return false
				end
			end
		end
		for key, value in pairs(item2.Stats) do
			if not blacklist[key] then
				if item1.Stats[key] ~= value then
					return false
				end
			end
		end
	elseif (item1.Stats ~= nil and item2.Stats == nil) or (item1.Stats == nil and item2.Stats ~= nil) then
		return false
	end

	return true
end




local function removeFromList(itemList, index, amount,player)
	local item = itemList[index]
	if not item or not item.Amount or item.Amount < amount then
		return false
	end

	item.Amount = item.Amount - amount
	
	ReplicateEvent:FireClient(player,item)
	if item.Amount <= 0 then
		table.remove(itemList, index)
	end

	return true
end

--------------------------------------------------------------------------------------------------------



--Funciones del INVENTARIO
--------------------------------------------------------------------------------------------------------
---La lista negra de atributos que no se deben considerar a la hora de stackear objetos
local Blacklist = {Equipped = true,Amount = true,ObjectID = true,Stats = true}
local Blacklist2 = {"Equipped"}
--Estructura de un item----




--Datos de los items que no sera necesario guardar en el inventario
local InventarioEjemploDatosVolatiles = {
	FD1 = {
		Description = "Lol",
		ImageID = "rbxassetid//",
		Type = "Sword",
		WeaponType = "Greatsword",
		Rarity = "Legendary",
	}
}



local InventarioEjemplo = {
	--Estructura de un arma, esta es la estructura de los items que voy a guardar en el inventario del jugador
		{
			--General
			Name = "NombreItem", -- Nombre del item
			Amount = 0,--La cantidad de items
			ObjectID = "",--El id unico de un item con ciertas caracteristicas
			PropertysID = "", --El id de las propiedades constantes que tendra ese objeto: Descripcion,tipo,rareza,imagen etc...
			--Esto lo van a contener todos los items del juego
			--Atributos extra para armas o servants, +daño,+vida, etc....
			Stats = {

			},
		}
	---------------------------------------
}






function module.AddItem(player, newItem, amount)
	DataSaver.GetPlayerData(player)
		:andThen(function(PlayerProfile)
			local Inventory = PlayerProfile.Inventory.Data
			local amount = amount or newItem.Amount or 1

			local PTable =  ItemPropTable[newItem.PropertysID]
			local Type = PTable.Type
			local Name = PTable.Name
			local Equipable = PTable.Equipable
			
			Inventory[Type] = Inventory[Type] or {}
			Inventory[Type][Name] = Inventory[Type][Name] or {}
			local itemList = Inventory[Type][Name]



			for _, existing in ipairs(itemList) do
				if ItemsAreEqual(existing, newItem, Blacklist) then
					ShowNewMessage(player,amount,PTable)
					
					existing.Amount = (existing.Amount or 0) + amount
					ReplicateEvent:FireClient(player,existing)
					return
				end
			end

			
			for _, attributeName in pairs(Blacklist2) do
				if newItem[attributeName] ~= nil then
					newItem[attributeName] = false
				end
			end
			newItem.ObjectID = HttpService:GenerateGUID(false)
			newItem.Amount = amount
			newItem.Equipped = Equipable and not Equipable
			table.insert(itemList, newItem)
			
			ReplicateEvent:FireClient(player,newItem)
			ShowNewMessage(player,amount,PTable)
		end)
		:catch(function(err)
			warn("Error with data loading:", err)
		end)
end




function module.RemoveItem(player, ItemID, Amount, Type, Name)
	local Inventory = DataSaver.GetSyncPlayerData(player).Inventory.Data
	if Inventory == nil then return false end
	local ItemTable
	local ItemIndex
	local Item
	if Type and Name then
		local itemList = Inventory[Type] and Inventory[Type][Name]
		if not itemList then
			return false
		end
		ItemTable = itemList
		for i, item in ipairs(itemList) do
			if item.ObjectID == ItemID then
				ItemIndex = i
				Item = item
			end
		end
	else
		local Result = ISF.GetItem(Inventory,ItemID)
		ItemTable = Result[1]
		ItemIndex = Result[2]
		Item = Result[3]
	end

	Item.Amount = Item.Amount - Amount
	
	ReplicateEvent:FireClient(player,Item)
	if Item.Amount <= 0 and not Item.Equipped then
		table.remove(ItemTable, ItemIndex)
	end

	return true
end
--------------------------------------------------------------------------------------------------------------


return module
