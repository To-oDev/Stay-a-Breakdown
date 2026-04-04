local RemoteFunct = game:GetService("ReplicatedStorage"):WaitForChild("SystemEvents"):WaitForChild("SkillServerInvoke")
local SkillSystem = require(game:GetService("ServerStorage"):WaitForChild("Systems"):WaitForChild("SkillSystem"))

RemoteFunct.OnServerInvoke = function(Player,Params)
	if not SkillSystem[Params.Name] or not Params.Function then return end
	SkillSystem[Params.Name][Params.Function](Params)
end