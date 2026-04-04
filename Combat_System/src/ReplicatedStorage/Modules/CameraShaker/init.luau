-- Camera Shaker
-- Stephen Leitnick
-- February 26, 2018

--[[
	
	CameraShaker.CameraShakeInstance
	
	cameraShaker = CameraShaker.new(renderPriority, callbackFunction)
	
	CameraShaker:Start()
	CameraShaker:Stop()
	CameraShaker:StopSustained([fadeOutTime])
	CameraShaker:Shake(shakeInstance)
	CameraShaker:ShakeSustain(shakeInstance)
	CameraShaker:ShakeOnce(magnitude, roughness [, fadeInTime, fadeOutTime, posInfluence, rotInfluence])
	CameraShaker:StartShake(magnitude, roughness [, fadeInTime, posInfluence, rotInfluence])
	
	
	
	EXAMPLE:
	
		local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
			camera.CFrame = playerCFrame * shakeCFrame
		end)
		
		camShake:Start()
		
		-- Explosion shake:
		camShake:Shake(CameraShaker.Presets.Explosion)
		
		wait(1)
		
		-- Custom shake:
		camShake:ShakeOnce(3, 1, 0.2, 1.5)

		-- Sustained shake:
		camShake:ShakeSustain(CameraShaker.Presets.Earthquake)

		-- Stop all sustained shakes:
		camShake:StopSustained(1) -- Argument is the fadeout time (defaults to the same as fadein time if not supplied)

		-- Stop only one sustained shake:
		shakeInstance = camShake:ShakeSustain(CameraShaker.Presets.Earthquake)
		wait(2)
		shakeInstance:StartFadeOut(1) -- Argument is the fadeout time
	
	
	NOTE:
	
		This was based entirely on the EZ Camera Shake asset for Unity3D. I was given written
		permission by the developer, Road Turtle Games, to port this to Roblox.
		
		Original asset link: https://assetstore.unity.com/packages/tools/camera/ez-camera-shake-33148

		GitHub repository: https://github.com/Sleitnick/RbxCameraShaker
	
	
--]]



local CameraShaker = {}
CameraShaker.__index = CameraShaker

local V3 = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local RAD = math.rad
local v3Zero = V3()

local CameraShakeInstance = require(script.CameraShakeInstance)
local CameraShakeState = CameraShakeInstance.CameraShakeState

local defaultPosInfluence = V3(0.15, 0.15, 0.15)
local defaultRotInfluence = V3(1, 1, 1)

CameraShaker.CameraShakeInstance = CameraShakeInstance
CameraShaker.Presets = require(script.CameraShakePresets)

-- Crear una instancia de CameraShaker
function CameraShaker.new(renderPriority, callback)
	assert(type(renderPriority) == "number", "RenderPriority must be a number (e.g.: Enum.RenderPriority.Camera.Value)")
	assert(type(callback) == "function", "Callback must be a function")

	local renderName = "CameraShaker_" .. tostring(math.random())  -- Nombre único para la instancia

	return setmetatable({
		_running = false;
		_renderName = renderName;
		_renderPriority = renderPriority;
		_posAddShake = v3Zero;
		_rotAddShake = v3Zero;
		_camShakeInstances = {};
		_removeInstances = {};
		_callback = callback;
	}, CameraShaker)
end

-- Iniciar el efecto de cámara
function CameraShaker:Start()
	if self._running then return end
	self._running = true
	local callback = self._callback
	game:GetService("RunService"):BindToRenderStep(self._renderName, self._renderPriority, function(dt)
		callback(self:Update(dt))
	end)
end

-- Detener el efecto de cámara
function CameraShaker:Stop()
	if not self._running then return end
	game:GetService("RunService"):UnbindFromRenderStep(self._renderName)
	self._running = false
end

-- Detener las vibraciones sostenidas
function CameraShaker:StopSustained(duration)
	for _, c in pairs(self._camShakeInstances) do
		if c.fadeOutDuration == 0 then
			c:StartFadeOut(duration or c.fadeInDuration)
		end
	end
end

-- Actualizar la cámara con las vibraciones
function CameraShaker:Update(dt)
	local posAddShake = v3Zero
	local rotAddShake = v3Zero
	local instances = self._camShakeInstances

	-- Actualizar todas las instancias
	for i = #instances, 1, -1 do
		local c = instances[i]
		local state = c:GetState()

		if state == CameraShakeState.Inactive and c.DeleteOnInactive then
			table.insert(self._removeInstances, i)
		elseif state ~= CameraShakeState.Inactive then
			local shake = c:UpdateShake(dt)
			posAddShake += shake * c.PositionInfluence
			rotAddShake += shake * c.RotationInfluence * dt * 60
		end
	end

	-- Eliminar instancias inactivas
	for i = #self._removeInstances, 1, -1 do
		table.remove(instances, self._removeInstances[i])
		self._removeInstances[i] = nil
	end

	return CF(posAddShake) * ANG(0, RAD(rotAddShake.Y), 0) * ANG(RAD(rotAddShake.X), 0, RAD(rotAddShake.Z))
end

-- Añadir una nueva vibración
function CameraShaker:Shake(shakeInstance)
	assert(shakeInstance._camShakeInstance, "ShakeInstance must be of type CameraShakeInstance")
	table.insert(self._camShakeInstances, shakeInstance)
	return shakeInstance
end

-- Añadir una vibración sostenida
function CameraShaker:ShakeSustain(shakeInstance)
	assert(shakeInstance._camShakeInstance, "ShakeInstance must be of type CameraShakeInstance")
	table.insert(self._camShakeInstances, shakeInstance)
	shakeInstance:StartFadeIn(shakeInstance.fadeInDuration)
	return shakeInstance
end

-- Crear una vibración que ocurre una sola vez
function CameraShaker:ShakeOnce(magnitude, roughness, fadeInTime, fadeOutTime, posInfluence, rotInfluence)
	local shakeInstance = CameraShakeInstance.new(magnitude, roughness, fadeInTime, fadeOutTime)
	shakeInstance.PositionInfluence = posInfluence or defaultPosInfluence
	shakeInstance.RotationInfluence = rotInfluence or defaultRotInfluence
	table.insert(self._camShakeInstances, shakeInstance)
	return shakeInstance
end

-- Crear una vibración que se inicia y sostiene
function CameraShaker:StartShake(magnitude, roughness, fadeInTime, posInfluence, rotInfluence)
	local shakeInstance = CameraShakeInstance.new(magnitude, roughness, fadeInTime)
	shakeInstance.PositionInfluence = posInfluence or defaultPosInfluence
	shakeInstance.RotationInfluence = rotInfluence or defaultRotInfluence
	shakeInstance:StartFadeIn(fadeInTime)
	table.insert(self._camShakeInstances, shakeInstance)
	return shakeInstance
end

return CameraShaker
