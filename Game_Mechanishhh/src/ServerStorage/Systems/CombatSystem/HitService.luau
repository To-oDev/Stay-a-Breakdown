--Services
local SS = game:GetService("ServerStorage")
local RepS = game:GetService("ReplicatedStorage")
--Folders
local SystemFolder = SS:WaitForChild("Systems")
--Modules
local HCS = require(SystemFolder:WaitForChild("HitCalculateService"))
local StunHandler = require(SystemFolder:WaitForChild("StunSystem"))
local ct = require(RepS:WaitForChild("Modules"):WaitForChild("CombatTable"))
--Events
local UIevent = RepS:WaitForChild("UISEvents"):WaitForChild("ComboUI")


local module = {}


function module.Hit(hum, damage, stundur, kb, humanoid,CV,Source)
	local p2 = game.Players:GetPlayerFromCharacter(humanoid.Parent)
	local character = hum.Parent
	local c = ct[character]
	local rp = character.HumanoidRootPart
	
	HCS.PWHEFolder(humanoid.Parent, character, damage,Source)
	HCS.HandleHits(p2,hum.Parent,stundur,damage)
	HCS.StunNRemoveAnims(hum.Parent,0,stundur,nil,nil,true)
	
	if kb then
		local A1 = Instance.new("Attachment",hum.RootPart)
		A1.Name = "KnockBackVelocity"
		local LV = Instance.new("LinearVelocity",A1)
		LV.Attachment0 = A1
		LV.MaxForce = 100000
		LV.VectorVelocity = kb
		game.Debris:AddItem(A1, .1)
	end
	return true
end

return module