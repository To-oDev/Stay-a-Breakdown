------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PUEDE SOPORTAR MOBILE, PC Y CONSOLA A LA VEZ.
-- UTILIZA UN MODULO QUE UTILIZA EL SERVICIO CONTEXTACTIONSERVICE PARA CREAR UNA GUI DE CONTROLES QUE SOPORTA TANTAS TECLAS COMO QUIERAS.
-- EL MODULO LO QUE HACE ES QUE PERMITE PERSONALIZAR MAS CADA BOTON QUE CREAS EN MOBILE, TE DA MUCHA LIBERTAD Q NO TE DA EL SERVICIO POR DEFAULT.
------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local PlayerService = game:GetService("Players")

local LocalPlayer = PlayerService.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local Utilities = ReplicatedStorage:FindFirstChild("Utilities")
local Modules = ReplicatedStorage:FindFirstChild("Modules")
local SystemAssets = ReplicatedStorage:FindFirstChild("SystemAssets")
local SystemEvents = ReplicatedStorage:FindFirstChild("SystemEvents")

local ContextActionUtility = require(Utilities:FindFirstChild("ContextActionUtility"))

local SkillsLibrary = require(Modules.DataBaseLibrarys.SkillsLibrary)
local SharedLocalScriptFuncts = require(Modules.SharedLocalScriptFuncts)

local SkillServerHandler: RemoteFunction = SystemEvents.SkillServerInvoke
local Checkout: RemoteFunction = SystemEvents:WaitForChild("Checkout")
local ChargeRage: RemoteEvent = SystemAssets.ChargeSystem.Events.ChargeRage
-- Cosas extra
local Character: Model = LocalPlayer.Character
local Humanoid = Character:FindFirstChild("Humanoid") or Character:WaitForChild("Humanoid", 3)

local SkillsGui: ScreenGui = PlayerGui:FindFirstChild("SkillGuis") or PlayerGui:WaitForChild("SkillGuis", 3)

local Cooldown = false
local SkillCooldown = false

---------------------------------------------------------------------
-- CONFIG
---------------------------------------------------------------------

local SkillKeys = {
	Z = "Z",
	X = "X",
	V = "V",
	T = "T",
	G = "G",
	C = "C",
	H = "H",
}

---------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------

local function getEquippedTool(): Tool?
	return Character:FindFirstChildOfClass("Tool")
end

local function SetOnCooldownSkill(cooldownTime: number?, skill, teaching: boolean?)
	if not skill then return end

	local equippedType = Character:GetAttribute("EquippedToolType")
	if not equippedType then return end

	local skillGui = SkillsGui:FindFirstChild(equippedType .. "SkillsGui")
	if not skillGui then return end

	local templates = skillGui:FindFirstChild("Templates")
	if not templates then return end

	for _, holder in ipairs(templates:GetChildren()) do
		if holder:GetAttribute("LinkedSkill") ~= skill.SkillName then
			continue
		end

		local cooldownFrame = holder.Frames.CooldownFrame
		cooldownFrame.Visible = true
		cooldownFrame.Size = UDim2.new(1, 0, 1, 0)

		if teaching then
			cooldownFrame.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
			cooldownFrame.BackgroundTransparency = 0.7

			TweenService:Create(
				cooldownFrame,
				TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ Size = UDim2.new(0, 0, 1, 0) }
			):Play()

			task.delay(0.3, function()
				if cooldownFrame.Parent then
					cooldownFrame.Visible = false
				end
			end)

		else
			if not cooldownTime or cooldownTime <= 0 then
				cooldownFrame.Visible = false
				return
			end

			cooldownFrame.BackgroundColor3 = Color3.new(0, 0, 0)
			cooldownFrame.BackgroundTransparency = 0.7

			TweenService:Create(
				cooldownFrame,
				TweenInfo.new(cooldownTime, Enum.EasingStyle.Sine),
				{ Size = UDim2.new(0, 0, 1, 0) }
			):Play()

			task.delay(cooldownTime, function()
				if cooldownFrame.Parent then
					cooldownFrame.Visible = false
				end
			end)
		end

		break
	end
end



local function isOnCooldown(skillValue)
	local endTime = Checkout:InvokeServer("CheckCooldown",{Skill = skillValue})
	return endTime and os.clock() < endTime
end

---------------------------------------------------------------------
-- UI cooldown de las skills
---------------------------------------------------------------------

local function startSkillCooldown(skillValue, cooldownTime)
	if not skillValue or not cooldownTime then return end
	local skillName = skillValue.SkillName
	if not skillName then return end
	Checkout:InvokeServer("SetCooldown",{Skill = skillValue})
	SetOnCooldownSkill(cooldownTime, skillValue)
end


---------------------------------------------------------------------
-- Terminar skill (para hold y para server-callback)
---------------------------------------------------------------------

local function EndSkill(skillValue,skillFinished)
	
	if not skillValue then return end

	local cooldownTime = Checkout:InvokeServer("GetCooldown", {Skill = skillValue})
	if not cooldownTime then
		return
	end

	if Character:GetAttribute("HoldingSkill") ~= skillValue.SkillName then
		return
	end

	Character:SetAttribute("HoldingSkill", nil)
	local params = {
		Player = Character,
		Function = "End",
		Name = skillValue.SkillName,
		Value = skillValue,
		Finished = skillFinished,
	}
	
	SkillServerHandler:InvokeServer(params)

	startSkillCooldown(skillValue,cooldownTime)

end

-- Para cuando el server quiera forzar el fin de la skill
SkillServerHandler.OnClientInvoke = function(skillValue,skillFinished)
	EndSkill(skillValue,skillFinished)
end

---------------------------------------------------------------------
-- HELPER: detener carga de mana
---------------------------------------------------------------------

local function StopManaCharge()
	-- Si está en modo "desenfrenado" no hacemos nada (igual que en End)
	if Character:GetAttribute("IsUnbridled") then
		return
	end

	if Character:GetAttribute("IsCharging") then
		-- Reseteamos el cooldown un poquito después para respetar tu lógica original
		task.delay(0.2, function()
			Cooldown = false
		end)
	else
		Cooldown = false
	end

	-- Avisamos al servidor que ya no está cargando
	ChargeRage:FireServer(Character, false)
end

---------------------------------------------------------------------
-- ACCIÓN: CARGA DE MANA (E)
---------------------------------------------------------------------
local function ManaCharge(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
	if inputState == Enum.UserInputState.Begin then
		if SharedLocalScriptFuncts.CFS(Character) < 1 then
			local isUnbridled = Character:GetAttribute("IsUnbridled")

			if not isUnbridled and not Cooldown then
				Cooldown = true
				ChargeRage:FireServer(Character, true)
			end
		end

	elseif inputState == Enum.UserInputState.End then
		StopManaCharge()
	end

	return Enum.ContextActionResult.Sink
end

---------------------------------------------------------------------
-- ACCIÓN: SKILLS (Z, X, V, T, G, C, H)
---------------------------------------------------------------------

local function HandleSkillKey(keyName: string, inputState: Enum.UserInputState)
	if not SkillKeys[keyName] then
		return Enum.ContextActionResult.Pass
	end

	local cfsCasting = SharedLocalScriptFuncts.CFS

	if inputState == Enum.UserInputState.Begin then
		if not Character:GetAttribute("EquippedTool") then
			return Enum.ContextActionResult.Sink
		end

		if cfsCasting(Character) >= 1 or SkillCooldown then
			return Enum.ContextActionResult.Sink
		end

		Character:SetAttribute("HoldingSkill", nil)

		local tool = getEquippedTool()
		if not tool then
			return Enum.ContextActionResult.Sink
		end
		
		local skillFolder = SkillsLibrary.GetSkillTableWithTool(tool)
		if not skillFolder then
			return Enum.ContextActionResult.Sink
		end

		local key = SkillKeys[keyName]

		for _, skillValue in ipairs(skillFolder) do
			local skillName = skillValue.SkillName

			if skillValue.Key == key
				and not isOnCooldown(skillValue)
				and not SkillCooldown
			then
				if skillValue.Type == "Unbridled" and not Character:GetAttribute("IsUnbridled") then return end
				SkillCooldown = true
				task.delay(0.1, function()
					SkillCooldown = false
				end)

				local cooldownTime = Checkout:InvokeServer("GetCooldown", {Skill = skillValue, CostCheck = true})
				if cooldownTime == "Insufficient Teaching!" then
					SetOnCooldownSkill(nil,skillValue,true)
					return Enum.ContextActionResult.Sink
				end
				if not cooldownTime then
					return Enum.ContextActionResult.Sink
				end

				Character:SetAttribute("HoldingSkill", skillName)
				skillValue.Shiny = tool:GetAttribute("Shiny")
				local params = {
					Player = Character,
					Function = "Start",
					Name = skillName,
					Value = skillValue,
				}

				SkillServerHandler:InvokeServer(params)

				if not skillValue.Hold then
					startSkillCooldown(skillValue,cooldownTime)
				end

				break
			end
		end
		
	elseif inputState == Enum.UserInputState.End then
		if cfsCasting(Character, { "CastingSkill" }) >= 1 then
			return Enum.ContextActionResult.Sink
		end

		local tool = getEquippedTool()
		if not tool then
			return Enum.ContextActionResult.Sink
		end

		local skillFolder = SkillsLibrary.GetSkillTableWithTool(tool)
		if not skillFolder then
			return Enum.ContextActionResult.Sink
		end

		local key = SkillKeys[keyName]

		for _, skillValue in ipairs(skillFolder) do
			if skillValue.Hold
				and skillValue.Key == key
				and not isOnCooldown(skillValue)
				and cfsCasting(Character, { "CastingSkill" }) < 1
			then
				EndSkill(skillValue)
				break
			end
		end
	end

	return Enum.ContextActionResult.Sink
end

-- Genera una callback por tecla (así cada acción tiene su propio botón)
local function CreateSkillAction(keyName: string)
	return function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
		return HandleSkillKey(keyName, inputState)
	end
end

---------------------------------------------------------------------
-- BIND DE ACCIONES
---------------------------------------------------------------------

local function connectAction(key, actionName, functionToBind, mobileButton: boolean, stickyHold: boolean, ...)
	ContextActionUtility:UnbindAction(actionName)
	
	if not ContextActionUtility:GetButton(actionName) then
		ContextActionUtility:BindAction(actionName, functionToBind, mobileButton, stickyHold, ...)
		ContextActionUtility:SetTitle(actionName, key or actionName)
	end
end

local function disconnecAction(actionName)
	if ContextActionUtility:GetButton(actionName) then
		ContextActionUtility:UnbindAction(actionName)
	end
end

-- E = carga de mana
connectAction("E", "ManaCharge", ManaCharge, true, false, Enum.KeyCode.E)

-- Z, X, V, T, G, C, H = skills (solo las que existan en el arma actual)
local function connectAllAbilities()
	local tool = getEquippedTool()
	if not tool then
		return
	end

	local skillFolder = SkillsLibrary.GetSkillTableWithTool(tool)
	if not skillFolder then
		return
	end

	local boundKeys = {}

	for _, skillValue in ipairs(skillFolder) do
		local keyName = skillValue.Key

		if keyName and SkillKeys[keyName] and not boundKeys[keyName] then
			boundKeys[keyName] = true

			local actionName = "Skill_" .. keyName
			connectAction(
				keyName,
				actionName,
				CreateSkillAction(keyName),
				true,
				true,
				Enum.KeyCode[keyName]
			)
		end
	end
end

local function disconnectAllAbilities()
	for keyName in pairs(SkillKeys) do
		local actionName = "Skill_" .. keyName
		disconnecAction(actionName)
	end
end

if Humanoid then
	Humanoid.Died:Connect(function()
		StopManaCharge()
	end)
end

if Character:GetAttribute("EquippedTool") then
	connectAllAbilities()
else
	disconnectAllAbilities()
end

Character:GetAttributeChangedSignal("EquippedTool"):Connect(function()
	disconnectAllAbilities()

	if Character:GetAttribute("EquippedTool") then
		connectAllAbilities()
	end
end)

Character:GetAttributeChangedSignal("IsUnbridled"):Connect(function()
	if Character:GetAttribute("IsUnbridled") == false then
		Cooldown = false
	end
end)