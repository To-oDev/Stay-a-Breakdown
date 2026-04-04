local PlaySound = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GUIStorage = ReplicatedStorage:FindFirstChild("GUIStorage")

local Sounds = GUIStorage:FindFirstChild("Sounds")

function PlaySound.PlaySound(SoundName: string, Parent: Instance?, volume: number?)
	local sound = Sounds:FindFirstChild(SoundName)
	if not sound then return end
	
	local SoundClone = sound:Clone()
	SoundClone.Parent = Parent
	
	if volume then
		SoundClone.Volume = volume
	end
	
	SoundClone:Play()
	SoundClone.Ended:Connect(function()
		SoundClone:Destroy()
	end)
end


return PlaySound