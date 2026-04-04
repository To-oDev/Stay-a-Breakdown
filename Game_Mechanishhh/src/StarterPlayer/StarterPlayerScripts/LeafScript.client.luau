--[[
	FoliageAnimationSystem - Professional Client-Side Foliage Movement
	
	Description:
		High-performance system for animating environmental foliage (leaves, plants)
		with distance-based LOD (Level of Detail) optimization and natural swaying motion.
	
	Features:
		- Distance-based update frequency (LOD system)
		- Natural wind-like swaying animation
		- Performance mode toggle (LDM - Low Detail Mode)
		- Automatic cleanup of destroyed parts
		- Memory-efficient caching
		- Spatial optimization with range checks
	
	Performance:
		- Near: Update every frame (< 400 studs)
		- Mid: Update every 0.5s (400-800 studs)
		- Far: Update every 2s (> 800 studs)
	
	Author: Optimized Version
	Last Updated: 2026
--]]

-- ====================================================================
-- SERVICES
-- ====================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

-- ====================================================================
-- PLAYER REFERENCES
-- ====================================================================

local LocalPlayer = Players.LocalPlayer
local Character: Model = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart: BasePart = Character:WaitForChild("HumanoidRootPart", 5)

-- ====================================================================
-- CONFIGURATION
-- ====================================================================

local CONFIG = {
	-- Foliage identification
	PartName = "Leaves",              -- Name of parts to animate
	UseCollectionService = false,      -- Use tags instead of names (more efficient)
	CollectionTag = "AnimatedFoliage", -- Tag to use if UseCollectionService is true

	-- Animation settings
	RotationSpeed = 0.6,              -- Speed of swaying motion
	RotationAngle = 6,                -- Maximum rotation angle (degrees)
	PhaseRandomization = true,        -- Randomize starting phase per leaf

	-- LOD (Level of Detail) ranges
	NearRange = 400,                  -- Full update rate range
	MidRange = 800,                   -- Reduced update rate range
	FarRange = math.huge,             -- Maximum render distance

	-- Update intervals by distance
	NearUpdateInterval = 0,           -- Update every frame
	MidUpdateInterval = 0.5,          -- Update every 0.5 seconds
	FarUpdateInterval = 2,            -- Update every 2 seconds

	-- Performance settings
	InitializationDelay = 5,          -- Delay before scanning workspace
	MaxLeavesPerFrame = 100,          -- Max leaves to process per scan iteration
	EnableAutoCleanup = true,         --// Remove destroyed parts from cache
	CleanupInterval = 10,             -- Seconds between cleanup passes

	-- Feature toggles
	RespectLDM = true,                -- Respect Low Detail Mode attribute
	EnableDebugMode = false,          -- Show debug information
}

-- ====================================================================
-- STATE MANAGEMENT
-- ====================================================================

local State = {
	-- Animation state
	isEnabled = true,

	-- Foliage cache
	foliageData = {},
	totalFoliage = 0,

	-- Performance tracking
	lastCleanupTime = 0,
	stats = {
		nearCount = 0,
		midCount = 0,
		farCount = 0,
		disabledCount = 0,
	},

	-- Connections
	connections = {},
}

-- ====================================================================
-- UTILITY FUNCTIONS
-- ====================================================================

local Utils = {}

--- Generates a random phase offset for animation variety
--- @return number phase
function Utils.GeneratePhaseOffset(): number
	return CONFIG.PhaseRandomization 
		and math.random() * math.pi * 2 
		or 0
end

--- Calculates the appropriate update interval based on distance
--- @param distance number
--- @return number interval
function Utils.GetUpdateInterval(distance: number): number
	if distance <= CONFIG.NearRange then
		return CONFIG.NearUpdateInterval
	elseif distance <= CONFIG.MidRange then
		return CONFIG.MidUpdateInterval
	else
		return CONFIG.FarUpdateInterval
	end
end

--- Determines LOD category from distance
--- @param distance number
--- @return string category
function Utils.GetLODCategory(distance: number): string
	if distance <= CONFIG.NearRange then
		return "near"
	elseif distance <= CONFIG.MidRange then
		return "mid"
	else
		return "far"
	end
end

-- ====================================================================
-- FOLIAGE DATA STRUCTURE
-- ====================================================================

local FoliageData = {}

--- Creates a new foliage data entry
--- @param part BasePart
--- @return table foliageEntry
function FoliageData.Create(part: BasePart)
	return {
		part = part,
		originCFrame = part.CFrame,
		phaseOffset = Utils.GeneratePhaseOffset(),
		nextUpdateTime = 0,
		isValid = true,
	}
end

--- Validates if a foliage entry is still valid
--- @param entry table
--- @return boolean isValid
function FoliageData.IsValid(entry): boolean
	return entry.isValid 
		and entry.part 
		and entry.part.Parent ~= nil
end

--- Marks an entry as invalid
--- @param entry table
function FoliageData.Invalidate(entry)
	entry.isValid = false
end

-- ====================================================================
-- FOLIAGE DISCOVERY
-- ====================================================================

local Discovery = {}

--- Checks if a part should be animated
--- @param part Instance
--- @return boolean shouldAnimate
local function ShouldAnimatePart(part: Instance): boolean
	if not part:IsA("BasePart") then
		return false
	end

	if CONFIG.UseCollectionService then
		return CollectionService:HasTag(part, CONFIG.CollectionTag)
	else
		return part.Name == CONFIG.PartName
	end
end

--- Prepares a part for animation
--- @param part BasePart
local function PreparePart(part: BasePart)
	part.Anchored = true
	part.CanCollide = false
end

--- Recursively finds and registers foliage parts
--- @param parent Instance
--- @param maxPerIteration number?
--- @return number partsFound
function Discovery.ScanRecursive(parent: Instance, maxPerIteration: number?): number
	local partsFound = 0
	local maxParts = maxPerIteration or CONFIG.MaxLeavesPerFrame

	local function scan(container: Instance)
		if partsFound >= maxParts then
			return
		end

		for _, child in container:GetChildren() do
			if partsFound >= maxParts then
				break
			end

			if ShouldAnimatePart(child) then
				PreparePart(child)

				local foliageEntry = FoliageData.Create(child)
				table.insert(State.foliageData, foliageEntry)
				partsFound += 1
				State.totalFoliage += 1
			end

			-- Recurse into children
			scan(child)
		end
	end

	scan(parent)
	return partsFound
end

--- Initializes foliage discovery
function Discovery.Initialize()
	if CONFIG.EnableDebugMode then
		print("[FoliageSystem] Starting foliage discovery...")
	end

	local startTime = os.clock()
	local totalFound = Discovery.ScanRecursive(workspace)
	local scanDuration = os.clock() - startTime

	if CONFIG.EnableDebugMode then
		print(`[FoliageSystem] Found {totalFound} foliage parts in {string.format("%.3f", scanDuration)}s`)
	end
end

-- ====================================================================
-- ANIMATION SYSTEM
-- ====================================================================

local Animation = {}

--- Calculates the swaying animation for a leaf
--- @param time number
--- @param phaseOffset number
--- @return number swayX, number swayZ
local function CalculateSway(time: number, phaseOffset: number): (number, number)
	local animationTime = time * CONFIG.RotationSpeed + phaseOffset

	local swayX = math.sin(animationTime) * CONFIG.RotationAngle
	local swayZ = math.cos(animationTime) * CONFIG.RotationAngle

	return swayX, swayZ
end

--- Applies animation to a foliage part
--- @param entry table
--- @param time number
--- @param distance number
function Animation.UpdateFoliage(entry, time: number, distance: number)
	local part = entry.part

	-- Reset to origin if far away
	if distance > CONFIG.MidRange then
		part.CFrame = entry.originCFrame
		return
	end

	-- Calculate and apply sway
	local swayX, swayZ = CalculateSway(time, entry.phaseOffset)

	part.CFrame = entry.originCFrame * CFrame.Angles(
		math.rad(swayX),
		0,
		math.rad(swayZ)
	)
end

--- Checks if an entry should update this frame
--- @param entry table
--- @param currentTime number
--- @param distance number
--- @return boolean shouldUpdate
local function ShouldUpdate(entry, currentTime: number, distance: number): boolean
	if currentTime < entry.nextUpdateTime then
		return false
	end

	local interval = Utils.GetUpdateInterval(distance)
	entry.nextUpdateTime = currentTime + interval

	return true
end

--- Main animation update loop
function Animation.Update()
	if not State.isEnabled or not HumanoidRootPart then
		return
	end

	local currentTime = os.clock()
	local playerPosition = HumanoidRootPart.Position

	-- Reset stats
	State.stats.nearCount = 0
	State.stats.midCount = 0
	State.stats.farCount = 0
	State.stats.disabledCount = 0

	-- Update each foliage part
	for _, entry in State.foliageData do
		-- Skip invalid entries
		if not FoliageData.IsValid(entry) then
			State.stats.disabledCount += 1
			continue
		end

		-- Calculate distance
		local distance = (entry.part.Position - playerPosition).Magnitude

		-- Update stats
		local category = Utils.GetLODCategory(distance)
		if category == "near" then
			State.stats.nearCount += 1
		elseif category == "mid" then
			State.stats.midCount += 1
		else
			State.stats.farCount += 1
		end

		-- Check if should update
		if not ShouldUpdate(entry, currentTime, distance) then
			continue
		end

		-- Apply animation
		Animation.UpdateFoliage(entry, currentTime, distance)
	end
end

-- ====================================================================
-- CLEANUP SYSTEM
-- ====================================================================

local Cleanup = {}

--- Removes invalid entries from foliage cache
--- @return number removedCount
function Cleanup.RemoveInvalidEntries(): number
	local removedCount = 0

	for i = #State.foliageData, 1, -1 do
		local entry = State.foliageData[i]

		if not FoliageData.IsValid(entry) then
			table.remove(State.foliageData, i)
			removedCount += 1
			State.totalFoliage -= 1
		end
	end

	return removedCount
end

--- Performs periodic cleanup of destroyed parts
function Cleanup.PerformAutoCleanup()
	if not CONFIG.EnableAutoCleanup then
		return
	end

	local currentTime = os.clock()

	if currentTime - State.lastCleanupTime < CONFIG.CleanupInterval then
		return
	end

	State.lastCleanupTime = currentTime
	local removed = Cleanup.RemoveInvalidEntries()

	if CONFIG.EnableDebugMode and removed > 0 then
		print(`[FoliageSystem] Cleaned up {removed} invalid entries`)
	end
end

--- Destroys all connections and clears cache
function Cleanup.DestroyAll()
	-- Disconnect all connections
	for _, connection in State.connections do
		connection:Disconnect()
	end
	table.clear(State.connections)

	-- Clear foliage cache
	table.clear(State.foliageData)
	State.totalFoliage = 0

	if CONFIG.EnableDebugMode then
		print("[FoliageSystem] System destroyed and cleaned up")
	end
end

-- ====================================================================
-- PERFORMANCE MODE (LDM)
-- ====================================================================

local PerformanceMode = {}

--- Updates enabled state based on LDM attribute
function PerformanceMode.UpdateState()
	if not CONFIG.RespectLDM then
		State.isEnabled = true
		return
	end

	local ldmEnabled = LocalPlayer:GetAttribute("LDM")
	State.isEnabled = not ldmEnabled

	if CONFIG.EnableDebugMode then
		print(`[FoliageSystem] LDM Mode: {ldmEnabled and "Enabled" or "Disabled"}`)
		print(`[FoliageSystem] Animations: {State.isEnabled and "Active" or "Paused"}`)
	end
end

--- Connects to LDM attribute changes
function PerformanceMode.ConnectLDM()
	if not CONFIG.RespectLDM then
		return
	end

	local connection = LocalPlayer:GetAttributeChangedSignal("LDM"):Connect(
		PerformanceMode.UpdateState
	)

	table.insert(State.connections, connection)

	-- Set initial state
	PerformanceMode.UpdateState()
end

-- ====================================================================
-- STATISTICS & DEBUGGING
-- ====================================================================

local Statistics = {}

--- Prints current system statistics
function Statistics.Print()
	print("========== Foliage System Stats ==========")
	print(`Total Foliage: {State.totalFoliage}`)
	print(`Active: {State.stats.nearCount + State.stats.midCount + State.stats.farCount}`)
	print(`  Near (< {CONFIG.NearRange}): {State.stats.nearCount}`)
	print(`  Mid ({CONFIG.NearRange}-{CONFIG.MidRange}): {State.stats.midCount}`)
	print(`  Far (> {CONFIG.MidRange}): {State.stats.farCount}`)
	print(`Invalid/Disabled: {State.stats.disabledCount}`)
	print(`Animation State: {State.isEnabled and "Enabled" or "Disabled"}`)
	print("=========================================")
end

--- Gets current statistics
--- @return table
function Statistics.Get()
	return {
		totalFoliage = State.totalFoliage,
		nearCount = State.stats.nearCount,
		midCount = State.stats.midCount,
		farCount = State.stats.farCount,
		disabledCount = State.stats.disabledCount,
		isEnabled = State.isEnabled,
	}
end

-- ====================================================================
-- PUBLIC API
-- ====================================================================

local FoliageSystem = {}

--- Gets system configuration
--- @return table
function FoliageSystem.GetConfig()
	return CONFIG
end

--- Gets system statistics
--- @return table
function FoliageSystem.GetStats()
	return Statistics.Get()
end

--- Manually triggers cleanup
function FoliageSystem.Cleanup()
	return Cleanup.RemoveInvalidEntries()
end

--- Toggles the system on/off
--- @param enabled boolean
function FoliageSystem.SetEnabled(enabled: boolean)
	State.isEnabled = enabled
end

--- Rescans the workspace for new foliage
function FoliageSystem.Rescan()
	Discovery.Initialize()
end

-- Export for debugging
_G.FoliageSystem = FoliageSystem
_G.FoliageStats = Statistics

-- ====================================================================
-- EVENT CONNECTIONS
-- ====================================================================

local function ConnectEvents()
	-- Main update loop
	local updateConnection = RunService.Heartbeat:Connect(function()
		Animation.Update()
		Cleanup.PerformAutoCleanup()
	end)
	table.insert(State.connections, updateConnection)

	-- Performance mode
	PerformanceMode.ConnectLDM()

	-- Cleanup on script destruction
	script.Destroying:Connect(Cleanup.DestroyAll)
end

-- ====================================================================
-- INITIALIZATION
-- ====================================================================

local function Initialize()
	-- Delayed initialization to allow workspace to load
	task.delay(CONFIG.InitializationDelay, function()
		Discovery.Initialize()

		if CONFIG.EnableDebugMode then
			Statistics.Print()
		end
	end)

	-- Connect events
	ConnectEvents()

	if CONFIG.EnableDebugMode then
		print("[FoliageSystem] System initialized")
	end
end

-- ====================================================================
-- START SYSTEM
-- ====================================================================

Initialize()