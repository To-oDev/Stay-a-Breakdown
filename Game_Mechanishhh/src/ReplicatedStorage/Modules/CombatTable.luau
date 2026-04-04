local SS = game:GetService("ServerStorage")
local Systems = SS:WaitForChild("Systems")
local RewardModule = require(game.ServerStorage:WaitForChild("Systems"):WaitForChild("RewardManager"))
local SkillRagdoll = require(Systems:WaitForChild("RagdollSystem"))
local HCS = require(Systems:WaitForChild("HitCalculateService"))
local t = {}




-----Funcion para los CollisionGroups
local function SetCollisionGroup(Character)
	for i,part in ipairs(Character:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Part") then
			part.CollisionGroup = "Players"
		end
	end
end

----Funcion para DeathRagdoll
local function onCharacterAdded(character)
	
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		character.Humanoid.BreakJointsOnDeath = false
		humanoid.Died:Connect(function()
			if not character:GetAttribute("IsAPlayer") and not character:GetAttribute("NPC") then
				RewardModule.RewardEnemy(character)
			end
			SkillRagdoll.enableDeathRagdoll(character)
			HCS.StunNRemoveAnims(character,20,nil,nil,nil,true)
		end)
	end
end
------------------------------------------------------------------------------------------

--Funciones para los chequeos de atributos
local function UpdateCanAttack(Value,Char)
	if Value and Value.Value ~= nil then
		Char:SetAttribute("CanAttack",true)
	else
		Char:SetAttribute("CanAttack",false)
	end
end
------------------------------------------------------------------------------------
--Funcion que crea los atributos y funcion que desconecta funciones
local function AddAtributesAndFollow(Plr,Char)
	-- Atributos Base
	Char:SetAttribute("CanAttack", true)
	Char:SetAttribute("CanSprint", true)
	Char:SetAttribute("IsAPlayer", false)
	if game.Players:GetPlayerFromCharacter(Char) then
		Char:SetAttribute("IsAPlayer", true)
	end
	Char:SetAttribute("CanCharge", true)
	Char:SetAttribute("IsCharging", false)
	Char:SetAttribute("IsExtasis", false)
	Char:SetAttribute("IsUnbridled", false)
	Char:SetAttribute("IsRagdolled",false)
	Char:SetAttribute("BaseSpeed",16)
	-- Atributos de Combate
	local CombatAttributes = {
		"Stunned", "Attacking",
		"CinematicMode", "CastingSkill"
	}
	for _, attr in ipairs(CombatAttributes) do
		Char:SetAttribute(attr, false)
	end
end
-----------------------------------------------------------------------------------

--Funcion para la combatTable
local function SetT(c)
	local h = c:FindFirstChild("Humanoid")

	if h then
		t[c] = {
			Attacking = false,
			Combo = 1,
		}
	end
end
---------------------------------------------------------------------




local EnemyStageFolders = {}

table.insert(EnemyStageFolders, workspace)
table.insert(EnemyStageFolders, workspace:WaitForChild("SpawnedEnemysFolder"))
for _, v in ipairs(workspace:GetDescendants()) do
	if v.Name == "EnemyStageFolder" then
		table.insert(EnemyStageFolders, v)
	end
end

for _, Folder in ipairs(EnemyStageFolders) do
	for _, Model in ipairs(Folder:GetChildren()) do
		if Model:FindFirstChild("Humanoid") then
			local Player = game.Players:GetPlayerFromCharacter(Model)
			SetCollisionGroup(Model)
			if Player then
				AddAtributesAndFollow(Player,Model)
			end
			onCharacterAdded(Model)
			SetT(Model)
		end
	end

	Folder.ChildAdded:Connect(function(Model)
		if Model:FindFirstChild("Humanoid")then
			local Player = game.Players:GetPlayerFromCharacter(Model)
			SetCollisionGroup(Model)
			if Player then
				AddAtributesAndFollow(Player,Model)
			end
			onCharacterAdded(Model)
			SetT(Model)
		end
	end)

	Folder.ChildRemoved:Connect(function(Model)
		if not Model:FindFirstChild("Humanoid") then return end
		t[Model] = nil
	end)
end


return t