--[[
	FXManager - Professional Client-Side Effects Handler
	
	Description:
		Central hub for managing visual effects, camera effects, and skill effects.
		Routes remote events to appropriate modules with validation and error handling.
	
	Features:
		- Modular effect system with dynamic routing
		- Type-safe parameter handling
		- Comprehensive error handling and logging
		- Performance-optimized module caching
		- Extensible architecture for new effect types
	
	Architecture:
		Server → FXManagerEvent → FXManager → Module → Function
	
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

-- ====================================================================
-- REPLICATED STORAGE STRUCTURE
-- ====================================================================

local SystemEvents = ReplicatedStorage:WaitForChild("SystemEvents")
local Modules = ReplicatedStorage:WaitForChild("Modules")

-- ====================================================================
-- REMOTE EVENTS
-- ====================================================================

local FXManagerEvent: RemoteEvent = SystemEvents:WaitForChild("FXManagerEvent")

-- ====================================================================
-- MODULE DEPENDENCIES
-- ====================================================================

local CameraFXModule = require(Modules:WaitForChild("CameraFX"))
local SkillFXModule = require(Modules:WaitForChild("SkillFXModule"))
local SharedFunctionsModule = require(Modules:WaitForChild("SharedLocalScriptFuncts"))

-- ====================================================================
-- CONFIGURATION
-- ====================================================================

local CONFIG = {
	-- Debug settings
	EnableDebugMode = false,        -- Enable detailed logging
	EnableErrorReporting = true,    -- Log errors to console

	-- Performance
	EnableParameterValidation = true, -- Validate parameters before execution
	EnableModuleCaching = true,     -- Cache module lookups

	-- Module registry
	ModuleRegistry = {
		CameraManager = CameraFXModule,
		SkillManager = SkillFXModule,
		CFSModule = SharedFunctionsModule,
	},
}

-- ====================================================================
-- STATE MANAGEMENT
-- ====================================================================

local State = {
	-- Module cache for faster lookups
	moduleCache = {},

	-- Statistics (for debugging)
	stats = {
		totalCalls = 0,
		successfulCalls = 0,
		failedCalls = 0,
		cacheHits = 0,
		cacheMisses = 0,
	},
}

-- ====================================================================
-- LOGGING SYSTEM
-- ====================================================================

local Logger = {}

--- Logs a debug message
--- @param message string
--- @param data table?
function Logger.Debug(message: string, data: {}?)
	if not CONFIG.EnableDebugMode then return end

	local timestamp = os.date("%H:%M:%S")
	local logMessage = `[FXManager][{timestamp}] {message}`

	if data then
		print(logMessage, data)
	else
		print(logMessage)
	end
end

--- Logs a warning message
--- @param message string
--- @param data table?
function Logger.Warn(message: string, data: {}?)
	if not CONFIG.EnableErrorReporting then return end

	local timestamp = os.date("%H:%M:%S")
	warn(`[FXManager][{timestamp}] WARNING: {message}`)

	if data then
		print("Data:", data)
	end
end

--- Logs an error message
--- @param message string
--- @param data table?
function Logger.Error(message: string, data: {}?)
	if not CONFIG.EnableErrorReporting then return end

	local timestamp = os.date("%H:%M:%S")
	warn(`[FXManager][{timestamp}] ERROR: {message}`)

	if data then
		print("Error Data:", data)
	end

	State.stats.failedCalls += 1
end

-- ====================================================================
-- PARAMETER VALIDATION
-- ====================================================================

local Validator = {}

--- Validates the base parameters structure
--- @param params table
--- @return boolean isValid, string? errorMessage
function Validator.ValidateBaseParams(params: {}): (boolean, string?)
	if type(params) ~= "table" then
		return false, "Parameters must be a table"
	end

	if not params.Module then
		return false, "Missing required field: Module"
	end

	if not params.Function then
		return false, "Missing required field: Function"
	end

	return true, nil
end

--- Validates that a module exists in the registry
--- @param moduleName string
--- @return boolean isValid, string? errorMessage
function Validator.ValidateModule(moduleName: string): (boolean, string?)
	if not CONFIG.ModuleRegistry[moduleName] then
		local availableModules = table.concat(
			(function()
				local keys = {}
				for key in CONFIG.ModuleRegistry do
					table.insert(keys, key)
				end
				return keys
			end)(),
			", "
		)

		return false, `Unknown module "{moduleName}". Available: {availableModules}`
	end

	return true, nil
end

--- Validates complete parameter set
--- @param params table
--- @return boolean isValid, string? errorMessage
function Validator.ValidateParams(params: {}): (boolean, string?)
	-- Validate base structure
	local baseValid, baseError = Validator.ValidateBaseParams(params)
	if not baseValid then
		return false, baseError
	end

	-- Validate module exists
	local moduleValid, moduleError = Validator.ValidateModule(params.Module)
	if not moduleValid then
		return false, moduleError
	end

	return true, nil
end

-- ====================================================================
-- MODULE RESOLUTION
-- ====================================================================

local ModuleResolver = {}

--- Gets the base module from registry
--- @param moduleName string
--- @return table? module
function ModuleResolver.GetBaseModule(moduleName: string)
	return CONFIG.ModuleRegistry[moduleName]
end

--- Resolves the target function within a module
--- @param baseModule table
--- @param params table
--- @return table? targetModule
function ModuleResolver.ResolveTargetModule(baseModule, params: {})
	-- Special handling for CameraManager
	if params.Module == "CameraManager" and params.NameF then
		return baseModule[params.NameF]
	end

	-- Standard handling for other modules
	if params.Name then
		return baseModule[params.Name]
	end

	-- Direct module access
	return baseModule
end

--- Creates a cache key for module lookups
--- @param params table
--- @return string cacheKey
local function CreateCacheKey(params: {}): string
	local moduleName = params.Module
	local name = params.NameF or params.Name or "direct"
	return `{moduleName}:{name}`
end

--- Gets a module with caching
--- @param params table
--- @return table? module
function ModuleResolver.GetModuleWithCache(params: {})
	if not CONFIG.EnableModuleCaching then
		-- No caching, resolve directly
		local baseModule = ModuleResolver.GetBaseModule(params.Module)
		return ModuleResolver.ResolveTargetModule(baseModule, params)
	end

	-- Check cache first
	local cacheKey = CreateCacheKey(params)
	local cachedModule = State.moduleCache[cacheKey]

	if cachedModule then
		State.stats.cacheHits += 1
		return cachedModule
	end

	-- Cache miss, resolve and cache
	State.stats.cacheMisses += 1
	local baseModule = ModuleResolver.GetBaseModule(params.Module)
	local targetModule = ModuleResolver.ResolveTargetModule(baseModule, params)

	if targetModule then
		State.moduleCache[cacheKey] = targetModule
	end

	return targetModule
end

-- ====================================================================
-- FUNCTION EXECUTION
-- ====================================================================

local Executor = {}

--- Executes a function from a module with error handling
--- @param targetModule table
--- @param functionName string
--- @param params table
--- @return boolean success
function Executor.ExecuteFunction(targetModule, functionName: string, params: {}): boolean
	-- Validate function exists
	if not targetModule[functionName] then
		Logger.Error(
			`Function "{functionName}" not found in module`,
			{Module = params.Module, AvailableFunctions = targetModule}
		)
		return false
	end

	-- Validate function is callable
	if type(targetModule[functionName]) ~= "function" then
		Logger.Error(
			`"{functionName}" is not a function`,
			{Type = type(targetModule[functionName])}
		)
		return false
	end

	-- Execute with error handling
	local success, errorMessage = pcall(function()
		targetModule[functionName](params)
	end)

	if not success then
		Logger.Error(
			`Error executing {params.Module}.{functionName}`,
			{Error = errorMessage, Params = params}
		)
		return false
	end

	Logger.Debug(`Successfully executed {params.Module}.{functionName}`)
	State.stats.successfulCalls += 1
	return true
end

-- ====================================================================
-- FX EVENT HANDLER
-- ====================================================================

local FXHandler = {}

--- Normalizes incoming parameters
--- @param params any
--- @param params2 any?
--- @return table? normalizedParams
local function NormalizeParams(params: any, params2: any?): {}?
	-- Handle player parameter pattern
	if params == LocalPlayer and params2 then
		return params2
	end

	-- Direct parameters
	if type(params) == "table" then
		return params
	end

	Logger.Warn("Invalid parameter format received", {Params = params, Params2 = params2})
	return nil
end

--- Main FX event handler
--- @param params any
--- @param params2 any?
function FXHandler.HandleFXEvent(params: any, params2: any?)
	State.stats.totalCalls += 1

	-- Normalize parameters
	local normalizedParams = NormalizeParams(params, params2)
	if not normalizedParams then
		return
	end

	Logger.Debug("Received FX event", normalizedParams)

	-- Validate parameters
	if CONFIG.EnableParameterValidation then
		local isValid, errorMessage = Validator.ValidateParams(normalizedParams)
		if not isValid then
			Logger.Error("Parameter validation failed", {Error = errorMessage})
			return
		end
	end

	-- Resolve module
	local targetModule = ModuleResolver.GetModuleWithCache(normalizedParams)
	if not targetModule then
		Logger.Error("Failed to resolve module", normalizedParams)
		return
	end

	-- Execute function
	Executor.ExecuteFunction(targetModule, normalizedParams.Function, normalizedParams)
end

-- ====================================================================
-- STATISTICS & DEBUGGING
-- ====================================================================

local Statistics = {}

--- Prints current statistics
function Statistics.PrintStats()
	print("=== FXManager Statistics ===")
	print(`Total Calls: {State.stats.totalCalls}`)
	print(`Successful: {State.stats.successfulCalls}`)
	print(`Failed: {State.stats.failedCalls}`)
	print(`Cache Hits: {State.stats.cacheHits}`)
	print(`Cache Misses: {State.stats.cacheMisses}`)

	if State.stats.cacheHits + State.stats.cacheMisses > 0 then
		local hitRate = State.stats.cacheHits / (State.stats.cacheHits + State.stats.cacheMisses) * 100
		print(`Cache Hit Rate: {string.format("%.2f", hitRate)}%`)
	end
	print("===========================")
end

--- Resets statistics
function Statistics.ResetStats()
	State.stats = {
		totalCalls = 0,
		successfulCalls = 0,
		failedCalls = 0,
		cacheHits = 0,
		cacheMisses = 0,
	}
	Logger.Debug("Statistics reset")
end

-- ====================================================================
-- PUBLIC API
-- ====================================================================

local FXManager = {}

--- Gets current module registry
--- @return table
function FXManager.GetModuleRegistry()
	return CONFIG.ModuleRegistry
end

--- Registers a new module
--- @param moduleName string
--- @param module table
function FXManager.RegisterModule(moduleName: string, module)
	CONFIG.ModuleRegistry[moduleName] = module
	State.moduleCache = {} -- Clear cache when registry changes
	Logger.Debug(`Registered new module: {moduleName}`)
end

--- Gets current statistics
--- @return table
function FXManager.GetStatistics()
	return State.stats
end

--- Clears the module cache
function FXManager.ClearCache()
	State.moduleCache = {}
	Logger.Debug("Module cache cleared")
end

-- Export for debugging
_G.FXManager = FXManager
_G.FXManagerStats = Statistics

-- ====================================================================
-- EVENT CONNECTIONS
-- ====================================================================

local function ConnectEvents()
	FXManagerEvent.OnClientEvent:Connect(FXHandler.HandleFXEvent)

	Logger.Debug("FXManager initialized and listening for events")
end

-- ====================================================================
-- INITIALIZATION
-- ====================================================================

local function Initialize()
	-- Connect to remote events
	ConnectEvents()

	-- Log initialization
	Logger.Debug("FXManager initialized successfully", {
		RegisteredModules = (function()
			local modules = {}
			for name in CONFIG.ModuleRegistry do
				table.insert(modules, name)
			end
			return modules
		end)()
	})
end

-- ====================================================================
-- START SYSTEM
-- ====================================================================
Initialize()