--[[
	MovementSystem - Professional Client-Side Movement & Footstep Handler
	
	Description:
		Manages character movement animations and footstep sounds with optimized
		sound pooling, dynamic animation switching, and material-based audio feedback.
	
	Features:
		- Dynamic walk/run animation switching based on speed
		- Material-based footstep sound system
		- Optimized sound pooling with strict limits
		- Pitch and volume variation based on movement speed
		- Marker-based animation synchronization
		- Memory-efficient resource management
	
	Author: Optimized Version
	Last Updated: 2024
--]]

-- ====================================================================
-- SERVICES
-- ====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ====================================================================
-- PLAYER REFERENCES
-- ====================================================================

local LocalPlayer = Players.LocalPlayer
local Character: Model = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid: Humanoid = Character:WaitForChild("Humanoid", 5)
local RootPart: BasePart = Character:WaitForChild("HumanoidRootPart", 5)
local Animator: Animator | AnimationController = Humanoid:FindFirstChildOfClass("AnimationController") 
	or Humanoid:WaitForChild("Animator", 5)

-- ====================================================================
-- MODULE DEPENDENCIES
-- ====================================================================

local FootstepModule = require(ReplicatedStorage:WaitForChild("FootstepModule"))

-- ====================================================================
-- CONFIGURATION
-- ====================================================================

local CONFIG = {
	-- Movement thresholds
	WalkSpeedThreshold = 16,           -- Speed above which character runs
	MinimumMovementSpeed = 0.1,        -- Minimum speed to play footsteps

	-- Audio settings
	VolumeMultiplier = 0.01,           -- Base volume calculation
	VolumeMin = 0.02,                  -- Minimum footstep volume
	VolumeMax = 0.15,                  -- Maximum footstep volume

	-- Pitch settings
	PitchBase = 0.8,                   -- Base pitch value
	PitchSpeedMultiplier = 0.03,       -- Pitch increase per speed unit
	PitchMin = 0.8,                    -- Minimum pitch
	PitchMax = 1.5,                    -- Maximum pitch

	-- Sound pooling
	MaxSounds = 2,                     -- Maximum sounds in pool
	MaxActiveSounds = 2,               -- Maximum concurrent playing sounds

	-- Animation blending
	AnimationFadeIn = 0.5,             -- Animation blend-in time
	AnimationFadeOut = 0.5,            -- Animation blend-out time
	StopFadeOut = 0.3,                 -- Fade out when stopping

	-- Animation IDs
	Animations = {
		Run = "rbxassetid://83631684395731",
		Walk = "rbxassetid://100338584680767",
	},

	-- Footstep marker names
	FootstepMarkers = {
		"Footstep",
		"LeftStep",
		"RightStep",
	},
}

-- ====================================================================
-- STATE MANAGEMENT
-- ====================================================================

local State = {
	-- Animation state
	currentTrack = nil,
	animationTracks = {},
	footstepConnections = {},

	-- Movement state
	isMoving = false,

	-- Sound pooling
	soundPool = {},
	activeSounds = {},

	-- Cleanup
	cleanupConnections = {},
}

-- ====================================================================
-- SOUND POOL SYSTEM
-- ====================================================================

local SoundPool = {}

--- Initializes the sound pool with pre-created instances
function SoundPool.Initialize()
	for i = 1, CONFIG.MaxSounds do
		local sound = Instance.new("Sound")
		sound.Name = "FootstepSound_" .. i
		sound.Parent = RootPart
		table.insert(State.soundPool, sound)
	end
end

--- Cleans up finished sounds from active list
local function CleanActiveSound()
	for i = #State.activeSounds, 1, -1 do
		if not State.activeSounds[i].IsPlaying then
			table.remove(State.activeSounds, i)
		end
	end
end

--- Gets an available sound from the pool
--- @return Sound?
function SoundPool.GetSound(): Sound?
	-- Clean up finished sounds
	CleanActiveSound()

	-- Check if we've hit the active sound limit
	if #State.activeSounds >= CONFIG.MaxActiveSounds then
		return nil
	end

	-- Find available sound in pool
	for i = #State.soundPool, 1, -1 do
		local sound = State.soundPool[i]
		if not sound.IsPlaying then
			table.remove(State.soundPool, i)
			return sound
		end
	end

	-- No available sounds
	return nil
end

--- Returns a sound to the pool
--- @param sound Sound
function SoundPool.ReturnSound(sound: Sound)
	if not sound then return end

	-- Remove from active sounds
	for i = #State.activeSounds, 1, -1 do
		if State.activeSounds[i] == sound then
			table.remove(State.activeSounds, i)
			break
		end
	end

	-- Return to pool if not full
	if #State.soundPool < CONFIG.MaxSounds then
		sound.TimePosition = 0
		table.insert(State.soundPool, sound)
	end
end

--- Destroys all sounds in the pool
function SoundPool.DestroyAll()
	-- Stop and clear active sounds
	for _, sound in State.activeSounds do
		if sound.Parent then
			sound:Stop()
		end
	end
	table.clear(State.activeSounds)

	-- Destroy pooled sounds
	for _, sound in State.soundPool do
		if sound.Parent then
			sound:Destroy()
		end
	end
	table.clear(State.soundPool)
end

-- ====================================================================
-- FOOTSTEP AUDIO SYSTEM
-- ====================================================================

local FootstepAudio = {}

--- Calculates volume based on movement speed
--- @param speed number
--- @return number volume
local function CalculateVolume(speed: number): number
	return math.clamp(
		speed * CONFIG.VolumeMultiplier,
		CONFIG.VolumeMin,
		CONFIG.VolumeMax
	)
end

--- Calculates pitch based on movement speed
--- @param speed number
--- @return number pitch
local function CalculatePitch(speed: number): number
	return math.clamp(
		CONFIG.PitchBase + speed * CONFIG.PitchSpeedMultiplier,
		CONFIG.PitchMin,
		CONFIG.PitchMax
	)
end

--- Plays a footstep sound effect
function FootstepAudio.PlayFootstep()
	-- Check movement speed
	local velocity = RootPart.AssemblyLinearVelocity
	local speed = velocity.Magnitude

	if speed < CONFIG.MinimumMovementSpeed then
		return
	end

	-- Get material data
	local floorMaterial = Humanoid.FloorMaterial
	local materialData = FootstepModule:GetTableFromMaterial(floorMaterial)

	if not materialData then
		return
	end

	-- Get random sound for material
	local soundId = FootstepModule:GetRandomSound(materialData)
	if not soundId then
		return
	end

	-- Get sound from pool
	local sound = SoundPool.GetSound()
	if not sound then
		return -- Pool exhausted, skip this footstep
	end

	-- Configure sound properties
	sound.SoundId = soundId
	sound.Volume = CalculateVolume(speed)
	sound.PlaybackSpeed = CalculatePitch(speed)

	-- Play sound
	table.insert(State.activeSounds, sound)
	sound:Play()

	-- Return to pool when finished
	sound.Ended:Once(function()
		SoundPool.ReturnSound(sound)
	end)
end

-- ====================================================================
-- ANIMATION SYSTEM
-- ====================================================================

local AnimationSystem = {}

--- Loads all movement animations
function AnimationSystem.LoadAnimations()
	for animName, animId in CONFIG.Animations do
		local animation = Instance.new("Animation")
		animation.Name = animName
		animation.AnimationId = animId

		local track = Animator:LoadAnimation(animation)
		State.animationTracks[animName] = track
	end
end

--- Disconnects all footstep marker connections
local function DisconnectFootstepMarkers()
	for _, connection in State.footstepConnections do
		connection:Disconnect()
	end
	table.clear(State.footstepConnections)
end

--- Sets up footstep marker listeners for an animation track
--- @param track AnimationTrack
function AnimationSystem.SetupFootstepMarkers(track: AnimationTrack)
	-- Clean existing connections
	DisconnectFootstepMarkers()

	-- Connect to each marker type
	for _, markerName in CONFIG.FootstepMarkers do
		local success, connection = pcall(function()
			return track:GetMarkerReachedSignal(markerName):Connect(
				FootstepAudio.PlayFootstep
			)
		end)

		if success and connection then
			table.insert(State.footstepConnections, connection)
		end
	end
end

--- Switches to a different animation
--- @param animationName string
function AnimationSystem.SwitchAnimation(animationName: string)
	local targetTrack = State.animationTracks[animationName]

	if not targetTrack then
		warn(`[MovementSystem] Animation "{animationName}" not found`)
		return
	end

	-- Already playing this animation
	if targetTrack == State.currentTrack then
		return
	end

	-- Stop current animation
	if State.currentTrack then
		State.currentTrack:Stop(CONFIG.AnimationFadeOut)
	end

	-- Play new animation
	State.currentTrack = targetTrack
	targetTrack:Play(CONFIG.AnimationFadeIn)

	-- Setup footstep markers
	AnimationSystem.SetupFootstepMarkers(targetTrack)
end

--- Stops the current animation
function AnimationSystem.StopAnimation()
	if not State.currentTrack then
		return
	end

	State.currentTrack:Stop(CONFIG.StopFadeOut)
	State.currentTrack = nil

	DisconnectFootstepMarkers()
end

-- ====================================================================
-- MOVEMENT LOGIC
-- ====================================================================

local MovementLogic = {}

--- Determines which animation should play based on speed
--- @return string animationName
local function DetermineAnimation(): string
	local walkSpeed = Humanoid.WalkSpeed
	return walkSpeed > CONFIG.WalkSpeedThreshold and "Run" or "Walk"
end

--- Handles movement state changes
function MovementLogic.OnMovementChanged()
	local moveDirection = Humanoid.MoveDirection
	local isMoving = moveDirection.Magnitude > 0

	if isMoving and not State.isMoving then
		-- Started moving
		State.isMoving = true
		local animName = DetermineAnimation()
		AnimationSystem.SwitchAnimation(animName)

	elseif not isMoving and State.isMoving then
		-- Stopped moving
		State.isMoving = false
		AnimationSystem.StopAnimation()
	end
end

--- Handles walk speed changes while moving
function MovementLogic.OnWalkSpeedChanged()
	if State.isMoving then
		local animName = DetermineAnimation()
		AnimationSystem.SwitchAnimation(animName)
	end
end

-- ====================================================================
-- EVENT CONNECTIONS
-- ====================================================================

local EventConnections = {}
local Cleanup = {}

--- Connects all movement-related events
function EventConnections.ConnectMovementEvents()
	-- Movement direction changed
	local moveConnection = Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(
		MovementLogic.OnMovementChanged
	)
	table.insert(State.cleanupConnections, moveConnection)

	-- Walk speed changed
	local speedConnection = Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(
		MovementLogic.OnWalkSpeedChanged
	)
	table.insert(State.cleanupConnections, speedConnection)
end

--- Connects death event for cleanup
function EventConnections.ConnectCleanupEvents()
	Humanoid.Died:Once(function()
		Cleanup.PerformFullCleanup()
	end)
end

-- ====================================================================
-- CLEANUP SYSTEM
-- ====================================================================

--- Performs complete cleanup of all resources
function Cleanup.PerformFullCleanup()
	-- Stop animation
	AnimationSystem.StopAnimation()

	-- Disconnect all event connections
	for _, connection in State.cleanupConnections do
		if connection.Connected then
			connection:Disconnect()
		end
	end
	table.clear(State.cleanupConnections)

	-- Clean up sound pool
	SoundPool.DestroyAll()

	-- Reset state
	State.isMoving = false
end

-- ====================================================================
-- INITIALIZATION
-- ====================================================================

local function Initialize()
	-- Load animations
	AnimationSystem.LoadAnimations()

	-- Initialize sound pool
	SoundPool.Initialize()

	-- Connect events
	EventConnections.ConnectMovementEvents()
	EventConnections.ConnectCleanupEvents()

	-- Setup script cleanup
	script.Destroying:Connect(function()
		Cleanup.PerformFullCleanup()
	end)
end

-- ====================================================================
-- START SYSTEM
-- ====================================================================

Initialize()