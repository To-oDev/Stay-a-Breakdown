local ShopStorage = {}

ShopStorage.Items = {
	X2Dims = {
		Name = "X2Dims",
		PurchaseType = "GamePass",
		PurchaseId = 1631256638,
		Reward = {
			Attribute = "X2Dims",
			Amount = 1
		},
		OneUse = true
	},

	X2Teaching = {
		Name = "X2Teaching",
		PurchaseType = "GamePass",
		PurchaseId = 1631422546,
		
		Reward = {
			Attribute = "X2Teaching",
			Amount = 1
		},
		OneUse = true
	},

	Dim25RBX = {
		Name = "Dim25RBX",
		PurchaseType = "Product",
		PurchaseId = 3479176069,
		
		Reward = {
			Attribute = "Dims",
			Amount = 25
		}
	},

	Dim50RBX = {
		Name = "Dim50RBX",
		PurchaseType = "Product",
		PurchaseId = 3479176567,
		
		Reward = {
			Attribute = "Dims",
			Amount = 50
		}
	},

	Dim150RBX = {
		Name = "Dim150RBX",
		PurchaseType = "Product",
		PurchaseId = 3479176565,
		
		Reward = {
			Attribute = "Dims",
			Amount = 150
		}
	},

	Dim250RBX = {
		Name = "Dim250RBX",
		PurchaseType = "Product",
		PurchaseId = 3479176566,
		
		Reward = {
			Attribute = "Dims",
			Amount = 250
		}
	},

	Quartz120RBX = {
		Name = "Quartz120RBX",
		PurchaseType = "Product",
		PurchaseId = 3479176069,
		
		Reward = {
			Attribute = "Quartz",
			Amount = 120
		}
	},

	Quartz650RBX = {
		Name = "Quartz650RBX",
		PurchaseType = "Product",
		PurchaseId = 3479176567,
		
		Reward = {
			Attribute = "Quartz",
			Amount = 650
		}
	},

	Quartz1100RBX = {
		Name = "Quartz1100RBX",
		PurchaseType = "Product",
		PurchaseId = 3479176565,
		
		Reward = {
			Attribute = "Quartz",
			Amount = 1100
		}
	},

	Quartz1200RBX = {
		Name = "Quartz1200RBX",
		PurchaseType = "Product",
		PurchaseId = 200004,
		
		Reward = {
			Attribute = "Quartz",
			Amount = 3479176566
		}
	},

	Xp25RBX = {
		Name = "Xp25RBX",
		PurchaseType = "Product",
		PurchaseId = 300001,
		
		Reward = {
			Attribute = "XP",
			Amount = 25
		}
	},

	Xp45RBX = {
		Name = "Xp45RBX",
		PurchaseType = "Product",
		PurchaseId = 300002,
		
		Reward = {
			Attribute = "XP",
			Amount = 45
		}
	},

	Xp100RBX = {
		Name = "Xp100RBX",
		PurchaseType = "Product",
		PurchaseId = 300003,
		
		Reward = {
			Attribute = "XP",
			Amount = 100
		}
	},

	Xp145RBX = {
		Name = "Xp145RBX",
		PurchaseType = "Product",
		PurchaseId = 300004,
		
		Reward = {
			Attribute = "XP",
			Amount = 145
		}
	}
}

function ShopStorage.SearchItemById(itemId: string)
	return ShopStorage.Items[itemId]
end

return ShopStorage