local GetSyncPP = game:GetService("ReplicatedStorage"):WaitForChild("SystemEvents"):WaitForChild("GetSyncPP")
local module = {}


function module.GetItem(Inventory,ItemID)
	for type, names in pairs(Inventory) do
		for name, itemList in pairs(names) do
			for i, item in ipairs(itemList) do
				if item.ObjectID == ItemID then
					return {itemList,i,item}
				end
			end
		end
	end
	return nil
end

function module.GetAllItems(Inventory)
	local Items = {}
	for type, names in pairs(Inventory) do
		for name, itemList in pairs(names) do
			for i, item in ipairs(itemList) do
				table.insert(Items,item)
			end
		end
	end
	return Items
end

function module.FindItemWithName(Inventory,Name)
	for type, names in pairs(Inventory) do
		for name, itemList in pairs(names) do
			for i, item in ipairs(itemList) do
				if item.Name == Name then
					return item
				end
			end
		end
	end
	return nil
end

function module.GetSyncPlayerProfile(player)
	local success, result = pcall(function()
		return GetSyncPP:InvokeServer()
	end)

	if success then
		return result
	end
end

return module