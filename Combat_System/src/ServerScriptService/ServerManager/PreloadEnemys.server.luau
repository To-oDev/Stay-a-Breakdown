local function preloadSystem()
	local ServerStorage = game:GetService("ServerStorage")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Workspace = game:GetService("Workspace")

	local Systems = ServerStorage:WaitForChild("Systems")
	local EnemySpawner = require(Systems:WaitForChild("EnemySpawner"))

	-- Parte escondida bajo el mapa para el warmup
	local WarmupPart = Instance.new("Part")
	WarmupPart.Anchored = true
	WarmupPart.CanCollide = false
	WarmupPart.Transparency = 1
	WarmupPart.Size = Vector3.new(4,1,4)
	WarmupPart.Position = Vector3.new(0, -500, 0) -- muy abajo
	WarmupPart.Name = "WarmupSpawnPart"
	WarmupPart.Parent = Workspace

	task.spawn(function()
		-- Espera a que todo cargue un poco
		task.wait()

		-- Config mínima, ajusta a tus modelos reales
		local possibleModels = { "EnemyIA" } -- o el que tengas seguro
		local level = 1

		local dummyZoneName = "WarmupZone"

		local enemy = EnemySpawner.SpawnEnemy(
			possibleModels,
			level,
			"WarmupID",
			dummyZoneName,
			nil,
			WarmupPart
		)

		if enemy then
			local hum = enemy:FindFirstChildOfClass("Humanoid")
			if hum then
				-- Forzar muerte para disparar todo el flujo de muerte
				hum.Health = 0
			end

			-- Cleanup por si algo se queda
			task.delay(1, function()
				if enemy.Parent then
					enemy:Destroy()
				end
			end)
		end
	end)
end

preloadSystem()