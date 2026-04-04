local BaseSpeed = game:GetService("ReplicatedStorage"):WaitForChild("SystemEvents"):WaitForChild("BaseSpeed")
local SpeedTable = {
	Run = 32,
	Walk = 14
}

BaseSpeed.OnServerInvoke = function(Player,Speed)
	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChild("Humanoid")
	if not Character or not Humanoid then return end
	Character:SetAttribute("BaseSpeed",SpeedTable[Speed])
	Character.Humanoid.WalkSpeed = SpeedTable[Speed]
end