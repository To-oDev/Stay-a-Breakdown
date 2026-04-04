local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Modules = ReplicatedStorage:FindFirstChild("Modules")
local MysterysZoneChecker = require(Modules:FindFirstChild("MysterysZoneChecker"))

local EnemySpawner = require(
	ServerStorage:WaitForChild("Systems"):WaitForChild("EnemySpawner")
)

local EnemyGenerationZones = Workspace:WaitForChild("EnemyGenerationZones")

-- Pequeña función para inicializar una zona
local function setupZone(folder)
	if not folder:IsA("Folder") then
		return
	end

	-- Partes de distancia / tolerancia
	local spawnZonePart = folder:FindFirstChild("SpawnDistance")
	local tolerancyZonePart = folder:FindFirstChild("SpawnTolerancy")

	if not spawnZonePart or not tolerancyZonePart then
		warn("[EnemyZoneHandler] Folder sin SpawnDistance o SpawnTolerancy:", folder.Name)
		return
	end

	-- Carpeta con las partes de spawn
	local spawnPartsFolder = folder:FindFirstChild("SpawnParts")
	if not spawnPartsFolder then
		warn("[EnemyZoneHandler] Folder sin carpeta SpawnParts:", folder.Name)
		return
	end
	
	local enterZone = MysterysZoneChecker.new(spawnZonePart)
	local leaveZone = MysterysZoneChecker.new(tolerancyZonePart)
	
	enterZone.PlayerInZone:Connect(function(player)
		if folder:GetAttribute("EnemysSpawned") then
			return
		end

		folder:SetAttribute("EnemysSpawned", true)

		for _, part in ipairs(spawnPartsFolder:GetChildren()) do
			EnemySpawner.TrackSpawnPart(part, folder)
		end
	end)

	leaveZone.PlayerLeavingZone:Connect(function(player, inside: {})
		if not folder:GetAttribute("EnemysSpawned") then
			return
		end

		-- Si ya no queda nadie dentro de la zona
		if not inside or not next(inside) then
			for _, part in ipairs(spawnPartsFolder:GetChildren()) do
				EnemySpawner.UnTrackSpawnPart(part, folder)
			end

			folder:SetAttribute("EnemysSpawned", true)
		end
	end)
end

for _, folder in ipairs(EnemyGenerationZones:GetChildren()) do
	setupZone(folder)
end