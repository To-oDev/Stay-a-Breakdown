local RS = game.ReplicatedStorage
local CRageEvent = RS:WaitForChild("SystemAssets"):WaitForChild("ChargeSystem"):WaitForChild("Events"):WaitForChild("ChargeRage")
local RemoteEvent = RS:WaitForChild("SystemEvents"):WaitForChild("FXEvent")
local Shake = RS:WaitForChild("SystemEvents"):WaitForChild("FXManagerEvent")
local CFSModule = require(RS:WaitForChild("Modules"):WaitForChild("SharedLocalScriptFuncts"))

local Players = game.Players
local active_charge = {}
local active_unbridled = {}
local active_effects = {}
local RageSystem = {}
local UnFunction
local UnbridledManager
local ChargeReset
local UnbridledHandler
local RageCalculator
local MaxExtasis


local function ShakeEffect(chr, name)
	Shake:FireAllClients({
		NameF = "Shake",
		Function = "Function",
		TargetPlayer = chr,
		Type = "Advanced",
		Object = chr.HumanoidRootPart,
		Distance = 50,
		Name = name,
		Module = "CameraManager",
	})
end

local function FireFOV(player, fov, fadeIn, duration, fadeOut,BackToNormal,FadeOutFov)
	Shake:FireClient(player, {
		NameF = "FOV",
		Function = "Simple",
		FOV = fov,
		FadeIn = fadeIn or 0.15,
		Duration = duration,
		FadeOut = fadeOut,
		BackToNormal = BackToNormal,
		TargetPlayer = player.Character,
		FadeOutFov = FadeOutFov,
		Module = "CameraManager",
	})
end

local function StopEffects(chr, removeCharge, player)
	if not chr or not active_effects[chr] then return end
	RemoteEvent:FireAllClients("AuraFalse", chr)
	FireFOV(player, 70, 0.3)
	active_effects[chr] = nil
	if removeCharge then active_charge[chr] = false end
end

local function StartEffects(chr, effectType,player)
	if not chr then return end
	ShakeEffect(chr, effectType)
	task.spawn(function()
		if active_effects[chr] ~= effectType then
			active_effects[chr] = effectType
			local fov = effectType == "Extasis" and 110 or 90
			RemoteEvent:FireAllClients("AuraTrue", chr, effectType, player:GetAttribute("ServantName"))
			task.wait(0.4)
			if chr:GetAttribute("IsCharging") then
				FireFOV(player, fov, 0.15)
			end
			
		end
	end)
end

local function UnFunction(player,chr)

	local decrease = player:GetAttribute("MaxMana") * (0.01 / player:GetAttribute("TotalExtasisMult"))

	if player:GetAttribute("ManaExtasis") <= decrease then
		UnbridledManager(player,"Ended", chr)
		RemoteEvent:FireAllClients("Unbridled", chr, "Remove", player:GetAttribute("ServantName"))
		active_unbridled[chr] = false
		player:SetAttribute("ManaExtasis",0)
		if player then CRageEvent:FireClient(player, false) end
	else
		local newValue = player:GetAttribute("ManaExtasis") - decrease
		player:SetAttribute("ManaExtasis",newValue)
	end
end

function UnbridledManager(player,state, chr)
	if state == "Start" then
		task.spawn(function()
			while chr:GetAttribute("IsUnbridled") do
				task.wait(0.1)
				UnFunction(player,chr)
			end
		end)
	elseif state == "Ended" then
		chr:SetAttribute("IsUnbridled", false)
	end
end

function ChargeReset(player, chr, reset)
	local hrp = chr:FindFirstChild("HumanoidRootPart")
	local humanoid = chr:FindFirstChild("Humanoid")

	if reset then
		StopEffects(chr, true, player)
		if player then CRageEvent:FireClient(player, false) end
		if hrp then hrp.Anchored = false end
		if humanoid then humanoid.AutoRotate = true end
		chr:SetAttribute("IsCharging", false)
		chr:SetAttribute("IsExtasis", false)
		player:SetAttribute("ManaExtasis",0)
	else
		chr:SetAttribute("IsExtasis", false)
		UnbridledManager(player,"Start", chr)
		active_charge[chr] = false
		if hrp then hrp.Anchored = false end
		if humanoid then humanoid.AutoRotate = true end
		active_unbridled[chr] = true
		task.delay(0.1, function()
			ShakeEffect(chr, "Explosion")
			RemoteEvent:FireAllClients("Unbridled", chr, "Explosion", player:GetAttribute("ServantName"))
			RemoteEvent:FireAllClients("Unbridled", chr, "Add", player:GetAttribute("ServantName"))
			Shake:FireClient(player, {
				NameF = "FOV",
				Function = "Simple",
				FOV = 130,
				FadeIn = 0.15,
				Duration = 0.15,
				FadeOut = 0.3,
				BackToNormal = true,
				TargetPlayer = player.Character,
				FadeOutFOV = 70,
				Module = "CameraManager",
			})
		end)
	end
end

function UnbridledHandler(player,chr)
	chr:SetAttribute("IsCharging", false)
	chr:SetAttribute("IsUnbridled", true)
	ChargeReset(player, chr, false)
	local player = Players:GetPlayerFromCharacter(chr)
end

function RageCalculator(player, chr, _, Berserker)
	local IE = chr:GetAttribute("IsExtasis")
	local mana = player:GetAttribute("Mana")
	local maxMana = player:GetAttribute("MaxMana")
	local manaExtasis = player:GetAttribute("ManaExtasis")

	if mana >= maxMana then
		if Berserker and not IE and chr:GetAttribute("IsCharging") then
			chr:SetAttribute("IsExtasis", true)
			if player then 
				CRageEvent:FireClient(player, true) 
			end
		end

		if manaExtasis >= maxMana and IE then
			UnbridledHandler(player, chr)

		elseif (manaExtasis + maxMana * 0.04) > maxMana and IE then
			player:SetAttribute("ManaExtasis", maxMana)
			StartEffects(chr, "Extasis", player)

		elseif IE then
			local newManaExtasis = math.round(manaExtasis + maxMana * 0.04)
			player:SetAttribute("ManaExtasis", newManaExtasis)
			StartEffects(chr, "Extasis", player)

		else
			StartEffects(chr, "Normal", player)
		end

	elseif (mana + maxMana * 0.015) > maxMana then
		player:SetAttribute("Mana", maxMana)
		StartEffects(chr, "Normal", player)

	else
		local newMana = math.round(mana + maxMana * 0.015)
		player:SetAttribute("Mana", newMana)
		StartEffects(chr, "Normal", player)
	end
end


function RageSystem.StopChargeRage(chr)
	if active_charge[chr] then
		local player = Players:GetPlayerFromCharacter(chr)
		ChargeReset(player, chr, true)
	end
end

function RageSystem.StartChargeRage(chr)
	active_charge[chr] = true
	chr:SetAttribute("IsCharging", true)

	local player = Players:GetPlayerFromCharacter(chr)

	local cooldown = 2.7
	local hrp, humanoid = chr:FindFirstChild("HumanoidRootPart"), chr:FindFirstChild("Humanoid")
	if humanoid then humanoid.AutoRotate = false end
	if hrp then hrp.Anchored = true end

	task.spawn(function()
		while active_charge[chr] and not active_unbridled[chr] do
			if not player:GetAttribute("Mana") or not player:GetAttribute("MaxMana") then return end
			if CFSModule.CFS(chr, {"IsCharging"}) == 1 then
				RageSystem.StopChargeRage(chr)
				break
			elseif player:GetAttribute("Mana") < player:GetAttribute("MaxMana") then
				RageCalculator(player, chr)
			elseif cooldown > 0 then
				cooldown -= 0.1
				RageCalculator(player, chr)
			else
				RageCalculator(player, chr, nil, true)
			end
			task.wait(0.1)
		end
	end)
end

return RageSystem