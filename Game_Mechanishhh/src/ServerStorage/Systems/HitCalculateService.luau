
local RepS = game:GetService("ReplicatedStorage")
local SE = RepS:WaitForChild("SystemEvents")
local UIevent = RepS:WaitForChild("UISEvents"):WaitForChild("ComboUI")
local FXRemoteEvent = SE:WaitForChild("FXEvent")
local Event = SE:WaitForChild("FXManagerEvent")
local StunHandler = require(game:GetService("ServerStorage"):WaitForChild("Systems"):WaitForChild("StunSystem"))
local RemoteFunct = SE:WaitForChild("SkillServerInvoke")
local module = {}



local EnemyDamageData = {}

local function cleanupEnemy(enemyId)
	local data = EnemyDamageData[enemyId]
	if not data then return end

	if data._connections then
		for _, conn in ipairs(data._connections) do
			if conn.Connected then
				conn:Disconnect()
			end
		end
	end

	EnemyDamageData[enemyId] = nil
end

function module.PWHEFolder(PlayerChar, EnemyChar, Damage, Source)
	if not EnemyChar or not PlayerChar or not Damage then return end
	if EnemyChar:GetAttribute("IsAPlayer") or not PlayerChar:GetAttribute("IsAPlayer") then return end
	local Humanoid = EnemyChar:FindFirstChild("Humanoid")
	if not Humanoid or Humanoid.Health <= 0 then return end
	
	local enemyId = EnemyChar:GetAttribute("EnemyID")
	if not enemyId then return end

	local enemyData = EnemyDamageData[enemyId]
	if not enemyData then
		enemyData = {
			Players = {},
			_connections = {}
		}
		EnemyDamageData[enemyId] = enemyData

		local humanoid = EnemyChar:FindFirstChildOfClass("Humanoid")
		if humanoid then
			table.insert(enemyData._connections,
				humanoid.Died:Connect(function()
					task.delay(3, function()
						cleanupEnemy(enemyId)
					end)
				end)
			)
		end

		table.insert(enemyData._connections,
			EnemyChar.AncestryChanged:Connect(function(_, parent)
				if not parent then
					task.delay(3, function()
						cleanupEnemy(enemyId)
					end)
				end
			end)
		)
	end

	local playerName = PlayerChar.Name
	local playerData = enemyData.Players[playerName]

	if not playerData then
		playerData = {
			DamageDealt = 0,
			LastHitSource = "Unknown"
		}
		enemyData.Players[playerName] = playerData
	end

	playerData.DamageDealt += Damage
	playerData.LastHitSource = Source or "Unknown"
end

function module.GetEnemyData(enemyId)
	return EnemyDamageData[enemyId]
end




function module.HandleHits(Player,EnemyChar,HighlightTime, Dmg,ExtraUITime,NoShake)
	if EnemyChar and EnemyChar:FindFirstChild("Humanoid") and Dmg then
		EnemyChar.Humanoid:TakeDamage(Dmg)

		if Player and Player:IsA("Player") then
			UIevent:FireClient(Player, Dmg,ExtraUITime)
		end
	end

	if not NoShake and EnemyChar then
		local Params = {
			NameF = "Shake",
			Function = "Function",
			TargetPlayer = EnemyChar,
			Type = "Simple",
			Object = nil,
			Distance = nil,
			Name = "Punched",
			CustomTime = nil,
			Module = "CameraManager"
		}
		local Player = game.Players:GetPlayerFromCharacter(EnemyChar)
		if Player then
			Event:FireClient(Player,Params)
		end

	end

	if HighlightTime then
		FXRemoteEvent:FireAllClients("Highlight",EnemyChar,HighlightTime)
	end

end

function RemoveHoldAttributes(Char)
	if Char:GetAttribute("CastingSkill") then
		Char:SetAttribute("CastingSkill",nil)
	end
	if Char:GetAttribute("SkillName") then
		Char:SetAttribute("SkillName",nil)
	end
end

local AnimTable = {
	"Start",
	"Hold",
	"Connect",
	"Enemy",
	"AttackAnimation",
}

local EffectsTable = {
	"SwordSkillEffect",
	"HoldEffectToDestroy",
	"SkillCastAttachment",
	"SkillVelocityAttach",
	"VelocityAttachment",
	"SkillEffect",
}

function StopEffects(Chr,NotAnims,NotEffects)
	if not NotAnims then
		if Chr and Chr:FindFirstChild("Humanoid") and Chr.Humanoid:FindFirstChild("Animator") then
			for _, animTrack in pairs(Chr.Humanoid.Animator:GetPlayingAnimationTracks()) do
				if table.find(AnimTable, animTrack.Name) then
					animTrack:Stop()
					animTrack:Destroy()
				end
			end
		end
	end
	if not NotEffects then
		for i,v in ipairs(Chr:GetDescendants()) do
			if table.find(EffectsTable, v.Name) then
				v:Destroy()
			end
		end
	end
end

function module.StunNRemoveAnims(Enemy,IFrameBreak,StunDur,NotAnims,NotEffects,RemoveHold,NotRemoveServant,FXBlackList)
	if IFrameBreak and Enemy and Enemy:GetAttribute("IFrame") and Enemy:GetAttribute("IFrame") > IFrameBreak then return end
	if not Enemy then return end
	if not Enemy:FindFirstChild("Humanoid") then return end
	--Quitar animaciones y efectos en el server y el cliente
	StopEffects(Enemy,NotAnims,true)
	if RemoveHold then
		RemoveHoldAttributes(Enemy)
	end

	Event:FireAllClients({
		Function = "Reset",
		Player = Enemy,
		Name = "StopAnims",
		NotAnims = NotAnims,
		NotEffects = NotEffects,
		Module = "SkillManager",
		NotRemoveServant = NotRemoveServant,
		FXBlackList = FXBlackList,
	})
	--------------------------------------------------------
	if StunDur then
		StunHandler.Stun(Enemy.Humanoid, StunDur)
		local player = game.Players:GetPlayerFromCharacter(Enemy)
		if not player then return end
			Event:FireAllClients({
				Function = "Equipment",
				Grimoire = true,
				Sword = true,
				Player = Enemy,
				Name = "StopAnims",
				Module = "SkillManager",
		})
	end

end

return module
