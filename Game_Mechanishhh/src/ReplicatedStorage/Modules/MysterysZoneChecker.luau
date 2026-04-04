local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local GoodSignal = require(game.ServerStorage:WaitForChild("Systems"):WaitForChild("HitboxSystem"):WaitForChild("GoodSignal"))

local Zone = {}
Zone.__index = Zone

local FAST_CHECK_INTERVAL = 0.1
local SLOW_CHECK_INTERVAL = 2
local SLOWEST_CHECK_INTERVAL = 15
local CLOSE_DISTANCE = 50
local FAR_DISTANCE = 200
local FAREST_DISTANCE = 5000

function Zone.new(part:Part)
	local self = setmetatable({}, Zone)

	part.CanCollide = false
	part.Anchored = true
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	self.Part = part
	self.PlayerInZone = GoodSignal.new()
	self.PlayerLeavingZone = GoodSignal.new()

	self._inside = {}
	self._updateConnection = nil
	self._destroyed = false
	self._accumulatedTime = 0
	self._currentInterval = FAST_CHECK_INTERVAL

	self:_startTracking()

	return self
end

function Zone:_startTracking()
	self._updateConnection = RunService.Heartbeat:Connect(function(dt)
		if self._destroyed then return end

		self._accumulatedTime += dt
		if self._accumulatedTime < self._currentInterval then return end
		self._accumulatedTime = 0

		local regionCFrame = self.Part.CFrame
		local regionSize = self.Part.Size

		if regionSize.Magnitude < 0.1 then return end 

		local closestDistance = math.huge
		for _, player in pairs(Players:GetPlayers()) do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root then
				local distanceToCenter = (root.Position - self.Part.Position).Magnitude
				local halfDiagonal = self.Part.Size.Magnitude / 2
				local dist = math.max(0, distanceToCenter - halfDiagonal)
				if dist < closestDistance then
					closestDistance = dist
				end
			end
		end
		
		if closestDistance <= CLOSE_DISTANCE then
			self._currentInterval = FAST_CHECK_INTERVAL
		elseif closestDistance <= FAR_DISTANCE then
			self._currentInterval = SLOW_CHECK_INTERVAL
		elseif closestDistance <= FAREST_DISTANCE then
			self._currentInterval = SLOWEST_CHECK_INTERVAL
		else
			local t = math.clamp((closestDistance - CLOSE_DISTANCE) / (FAR_DISTANCE - CLOSE_DISTANCE), 0, 1)
			self._currentInterval = FAST_CHECK_INTERVAL + t * (SLOW_CHECK_INTERVAL - FAST_CHECK_INTERVAL)
		end

		local parts = Workspace:GetPartBoundsInBox(regionCFrame, regionSize, nil)
		local playersInRegion = {}

		for _, part in ipairs(parts) do
			local character = part:FindFirstAncestorOfClass("Model")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local player = humanoid and Players:GetPlayerFromCharacter(character)

			if player and player.Character and humanoid.Health > 0 then
				playersInRegion[player] = true

				if not self._inside[player] then
					self._inside[player] = true
					self.PlayerInZone:Fire(player,self._inside)
				end
			end
		end

		for player in pairs(self._inside) do
			if not playersInRegion[player] then
				self._inside[player] = nil
				self.PlayerLeavingZone:Fire(player,self._inside)
			end
		end
	end)
end

function Zone:Destroy()
	if self._destroyed then return end
	self._destroyed = true

	if self._updateConnection then
		self._updateConnection:Disconnect()
		self._updateConnection = nil
	end

	if self.PlayerInZone then
		self.PlayerInZone:Destroy()
		self.PlayerInZone = nil
	end

	if self.PlayerLeavingZone then
		self.PlayerLeavingZone:Destroy()
		self.PlayerLeavingZone = nil
	end

	self._inside = nil
	self.Part = nil
end

return Zone