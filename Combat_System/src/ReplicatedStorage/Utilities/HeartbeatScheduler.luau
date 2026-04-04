-- ZoneScheduler.lua (en ServerStorage/System, por ejemplo)

local RunService = game:GetService("RunService")

local Scheduler = {}
Scheduler.zones = {}
Scheduler._acc = 0
Scheduler._running = false

function Scheduler.add(zone)
	Scheduler.zones[zone] = true
	if not Scheduler._running then
		Scheduler._running = true
		Scheduler:_run()
	end
end

function Scheduler.remove(zone)
	Scheduler.zones[zone] = nil
end

function Scheduler:_run()
	RunService.Heartbeat:Connect(function(dt)
		Scheduler._acc += dt
		for zone in pairs(Scheduler.zones) do
			zone:_step(dt)
		end
	end)
end

return Scheduler