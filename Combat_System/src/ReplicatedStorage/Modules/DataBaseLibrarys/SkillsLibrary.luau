local SkillsTable = {
	Servant = {
		["Harturia Dragon"] = {
			Normal = {
				[1] = {
					SkillName = "Double Note",
					Key = "Z",
					Type = "Normal",
					Teaching = 0,
					Cooldown = 17,--20
					Cost = 20,
					Damage = 5,
					Source = "Servant",
					ID = "HDDN"
				},
				[2] = {
					SkillName = "Slash Barrage",
					Key = "X",
					Type = "Normal",
					Teaching = 20,
					Cooldown = 18,--23
					Cost = 20,
					Damage = 5,
					Hold = true,
					Source = "Servant",
					ID = "HDSB"
				},
				[3] = {
					SkillName = "Sword Turret",
					Key = "C",
					Type = "Normal",
					Teaching = 100,
					Cooldown = 20,--23
					Cost = 30,
					Damage = 5,
					Hold = true,
					Source = "Servant",
					ID = "HDST"
				},
				[4] = {
					SkillName = "Sword Explosion",
					Key = "V",
					Type = "Normal",
					Teaching = 150,
					Cooldown = 19,--23
					Cost = 30,
					Damage = 4,
					Hold = true,
					Source = "Servant",
					ID = "HDSE",
				},
				[5] = {
					SkillName = "Excaliba",
					Key = "T",
					Type = "Unbridled",
					Teaching = 200,
					Cooldown = 30,--13
					Cost = 0,
					Damage = 19,
					Source = "Servant",
					ID = "HDE"
				},
			},
		},
		["Ku Shulan"] = {
			Normal = {
				[1] = {
					SkillName = "Rotating Lance",
					Key = "Z",
					Type = "Normal",
					Teaching = 0,
					Cooldown = 16,--20
					Cost = 30,
					Damage = 5,
					Hold = true,
					Source = "Servant",
					ID = "KSRL"
				},
				[2] = {
					SkillName = "Lance Barrage",
					Key = "X",
					Type = "Normal",
					Teaching = 50,
					Cooldown = 15,--13
					Cost = 30,
					Damage = 4,
					Hold = true,
					Source = "Servant",
					ID = "KSLB"
				},
				[3] = {
					SkillName = "Spear Of God",
					Key = "C",
					Type = "Normal",
					Teaching = 100,
					Cooldown = 18,--13
					Cost = 40,
					Damage = 5,
					Hold = true,
					Source = "Servant",
					ID = "KSSOG"
				},
			}
		},
		["Sasako"] = {
			Normal = {
				[1] = {
					SkillName = "Gyroscope Attack",
					Key = "Z",
					Type = "Normal",
					Teaching = 0,
					Cooldown = 12,--20
					Cost = 30,
					Damage = 5,
					Source = "Servant",
					ID = "SasGA"
				},
				[2] = {
					SkillName = "Thousand Slashes",
					Key = "X",
					Type = "Normal",
					Teaching = 50,
					Cooldown = 15,--13
					Cost = 30,
					Damage = 4,
					Hold = true,
					Source = "Servant",
					ID = "SasTS"
				},
			}
		}
	},
	Combat = {
		["Basic Combat"] = {
			Normal = {
				[1] = {
					SkillName = "Iron Fist",
					Key = "Z",
					Type = "Normal",
					Teaching = 0,
					Cooldown = 7,--20
					Cost = 20,
					Damage = 4,
					Source = "Combat",
					ID = "BCIF",
					
				},
				[2] = {
					SkillName = "Burst Dash",
					Key = "X",
					Type = "Normal",
					Teaching = 0,
					Cooldown = 7,--20
					Cost = 30,
					Damage = 3,
					Source = "Combat",
					ID = "BCBD"
				},
			}
		}
	},
	Sword = {
		["Basic Sword"] = {
			Normal = {
				[1] = {
					SkillName = "Big Slash",
					Key = "Z",
					Type = "Normal",
					Teaching = 0,
					Cooldown = 10,--20
					Cost = 40,
					Damage = 5,
					Source = "Sword",
					ID = "BSBS"
				},
			}
		}
	}
}

local module = {}

function module.GetAllSkillsTable()
	return SkillsTable
end
function module.GetSkillTable(Type, Name)
	local Table = SkillsTable[Type] 
		and SkillsTable[Type][Name] 
		and SkillsTable[Type][Name]["Normal"]
	return Table
end
function module.GetSkillTableWithTool(tool)
	if not tool then return nil end

	local toolType = tool:GetAttribute("Type")
	local toolName = tool:GetAttribute("Name")

	if not toolType or not toolName then
		return nil
	end

	return module.GetSkillTable(toolType, toolName)
end

return module
