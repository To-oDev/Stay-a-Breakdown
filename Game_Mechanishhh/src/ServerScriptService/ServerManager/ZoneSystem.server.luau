local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:FindFirstChild("UISEvents")

local Zones = workspace:FindFirstChild("Zones")

local Modules = ReplicatedStorage:FindFirstChild("Modules")
local MysterysZoneChecker = require(Modules:FindFirstChild("MysterysZoneChecker"))

local function configureZone(zone: Part)
	zone.CanCollide = false
	zone.CastShadow = false
	zone.CanQuery = false
	zone.CanTouch = false
end

for i, v in Zones:GetChildren() do
	configureZone(v)

	local zone = MysterysZoneChecker.new(v)
	
	zone.PlayerInZone:Connect(function(plr)
		Events.ZoneEvent:FireClient(plr, {
			ZoneName = v.Name, 
			Entered = true
		})
	end)

	zone.PlayerLeavingZone:Connect(function(plr)
		Events.ZoneEvent:FireClient(plr, {
			ZoneName = v.Name, 
			Entered = false,
		})
	end)
end