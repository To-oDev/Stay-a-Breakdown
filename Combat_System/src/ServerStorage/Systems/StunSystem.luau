local heartbeat = game:GetService("RunService").Heartbeat

local Stunned = {}

local clock = os.clock
local isChecking = false
local checkConnection
local currentTime
local stunnedHumanoids

local function stunChecker()
	currentTime = clock()
	stunnedHumanoids = 0
	
	for humanoid, data in pairs(Stunned) do
		if not data.stunned then continue end
		
		if currentTime >= data.duration then
			data.stunned = false

			data.changedConn:Disconnect()
			data.changedConn = nil

			if humanoid:IsDescendantOf(workspace) then
				local BS = humanoid:GetAttribute("BaseSpeed") or 16
				humanoid.WalkSpeed = BS
				humanoid.JumpPower = 50
				humanoid.Parent:SetAttribute("Stunned", false)
			end
		end
		
		stunnedHumanoids += 1
	end
	
	if stunnedHumanoids == 0 then
		checkConnection:Disconnect()
		isChecking = false
	end
end


--//Stun Handler
return {Stun = function (humanoid, duration)
	if humanoid.Health <= 0 then return end
	
	if not Stunned[humanoid] then
		Stunned[humanoid] = {}
	end

	local data = Stunned[humanoid]
	currentTime = clock()
	
	if not data.stunned then -- not stunned
		data.stunned = true
		data.duration = currentTime + duration
		
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
		humanoid.Parent:SetAttribute("Stunned", true)
	elseif data.duration - currentTime < duration then -- update duration if less time left
		data.duration = currentTime + duration
	end
	
	if not data.changedConn then
		data.changedConn = humanoid.Changed:Connect(function()
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.JumpHeight = 0
		end)
	end
	
	if not data.diedConn then
		data.diedConn = humanoid.AncestryChanged:Connect(function()
			data.diedConn:Disconnect()
			
			if data.changedConn then data.changedConn:Disconnect() end
			
			Stunned[humanoid] = nil
		end)
	end
	
	if not isChecking then
		isChecking = true
		checkConnection = heartbeat:Connect(stunChecker)
	end
end}
