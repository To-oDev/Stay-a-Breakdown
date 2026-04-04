-- Camera Shake Instance
-- Stephen Leitnick
-- February 26, 2018

local CameraShakeInstance = {}
CameraShakeInstance.__index = CameraShakeInstance

local V3 = Vector3.new
local NOISE = math.noise

CameraShakeInstance.CameraShakeState = {
	FadingIn = 0;
	FadingOut = 1;
	Sustained = 2;
	Inactive = 3;
}

function CameraShakeInstance.new(magnitude, roughness, fadeInTime, fadeOutTime)
	-- Default fade-in and fade-out times to 0 if not provided
	fadeInTime = fadeInTime or 0
	fadeOutTime = fadeOutTime or 0

	-- Validate input types
	assert(type(magnitude) == "number", "Magnitude must be a number")
	assert(type(roughness) == "number", "Roughness must be a number")
	assert(type(fadeInTime) == "number", "FadeInTime must be a number")
	assert(type(fadeOutTime) == "number", "FadeOutTime must be a number")

	local self = setmetatable({
		Magnitude = magnitude;
		Roughness = roughness;
		PositionInfluence = V3();
		RotationInfluence = V3();
		DeleteOnInactive = true;
		roughMod = 1;
		magnMod = 1;
		fadeOutDuration = fadeOutTime;
		fadeInDuration = fadeInTime;
		sustain = fadeInTime > 0;
		currentFadeTime = (fadeInTime > 0 and 0) or 1;
		tick = Random.new():NextNumber(-100, 100);
		_camShakeInstance = true;
	}, CameraShakeInstance)

	return self
end

function CameraShakeInstance:UpdateShake(dt)
	-- Accumulate time and process in fixed steps
	self.dtAccumulator = (self.dtAccumulator or 0) + dt
	local fixedDt = 1 / 60  -- Simulate 60 FPS steps

	while self.dtAccumulator >= fixedDt do
		local mod = self.Roughness * self.roughMod
		if not self.sustain then
			mod = mod * self.currentFadeTime
		end
		self.tick = self.tick + (fixedDt * mod)
		self.dtAccumulator = self.dtAccumulator - fixedDt
	end

	-- Generate shake offset
	local offset = Vector3.new(
		NOISE(self.tick, 0) * 0.5,
		NOISE(0, self.tick) * 0.5,
		NOISE(self.tick, self.tick) * 0.5
	)

	-- Handle fade in/out based on time
	local fadeMod = self.currentFadeTime
	if self.fadeInDuration > 0 and self.sustain then
		fadeMod = math.min(1, fadeMod + (dt / self.fadeInDuration))
		if fadeMod == 1 and self.fadeOutDuration > 0 then
			self.sustain = false
		end
	elseif not self.sustain then
		fadeMod = math.max(0, fadeMod - (dt / self.fadeOutDuration))
	end

	self.currentFadeTime = fadeMod
	return offset * self.Magnitude * self.magnMod * fadeMod
end

function CameraShakeInstance:StartFadeOut(fadeOutTime)
	self.fadeOutDuration = fadeOutTime
	self.fadeInDuration = 0
	self.sustain = false
	self.currentFadeTime = fadeOutTime > 0 and self.currentFadeTime or 0
end

function CameraShakeInstance:StartFadeIn(fadeInTime)
	self.fadeInDuration = fadeInTime or self.fadeInDuration
	self.fadeOutDuration = 0
	self.sustain = true
	self.currentFadeTime = 1
end

-- Getter and Setter methods for scale values
function CameraShakeInstance:GetScaleRoughness() return self.roughMod end
function CameraShakeInstance:SetScaleRoughness(v) self.roughMod = v end
function CameraShakeInstance:GetScaleMagnitude() return self.magnMod end
function CameraShakeInstance:SetScaleMagnitude(v) self.magnMod = v end

function CameraShakeInstance:GetNormalizedFadeTime() return self.currentFadeTime end

-- State check methods
function CameraShakeInstance:IsShaking() return self.currentFadeTime > 0 or self.sustain end
function CameraShakeInstance:IsFadingOut() return not self.sustain and self.currentFadeTime > 0 end
function CameraShakeInstance:IsFadingIn() return self.currentFadeTime < 1 and self.sustain and self.fadeInDuration > 0 end

function CameraShakeInstance:GetState()
	if self:IsFadingIn() then
		return CameraShakeInstance.CameraShakeState.FadingIn
	elseif self:IsFadingOut() then
		return CameraShakeInstance.CameraShakeState.FadingOut
	elseif self:IsShaking() then
		return CameraShakeInstance.CameraShakeState.Sustained
	else
		return CameraShakeInstance.CameraShakeState.Inactive
	end
end

return CameraShakeInstance
