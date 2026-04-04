local M1Table = {
	["Harturia Dragon"] = true,
	["Ku Shulan"] = true,
	["Sasako"] = true,
	["Basic Combat"] = true,
}

local module = {}


function module.CheckForWeapon(WeaponName)
	if M1Table[WeaponName] then 
		return true
	else
		return nil
	end
end
return module
