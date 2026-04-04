local Players = game:GetService("Players")
local CooldownTable = {}
local module = {}

Players.PlayerRemoving:Connect(function(player)
	CooldownTable[player] = nil
end)


function module.SetOnCooldown(Player: Player, skillValue, modifier, skillTable)
	local plrData = CooldownTable[Player]

	if not plrData then
		plrData = {}
		CooldownTable[Player] = plrData
	end

	local now = os.clock()

	local baseCooldown = modifier
		or (skillValue and skillValue.Cooldown)
		or 0

	baseCooldown = math.clamp(baseCooldown, 0, 12)

	if skillTable then
		for _, skill in ipairs(skillTable) do
			if not skill.ID or not skill.Cooldown then continue end
			
			plrData[skill.ID] = now + math.clamp((modifier or skill.Cooldown),0,12)
		end
	else
		if skillValue and skillValue.ID then
			plrData[skillValue.ID] = now + baseCooldown
		end
	end
end


function module.GetCooldown(Player: Player, skillValue: string,ID)
	local plrData = CooldownTable[Player]
	if not plrData then
		return nil
	end
	return plrData[skillValue.ID or ID]
end

return module
