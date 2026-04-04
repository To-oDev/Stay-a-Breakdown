--[[

	:Enable(cameraPart, time?, easingStyle?, easingDirection?)
	:SetCamera(cameraPart, time?, easingStyle?, easingDirection?)
	:Reset(time?, easingStyle?, easingDirection?)
	:ResetToPlayerCamera(time?)
	:LockInput(state)
	:Disable()

--]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local MenuCamera = {}
MenuCamera.__index = MenuCamera

-- ========================
-- CONFIG
-- ========================
MenuCamera.Camera = workspace.CurrentCamera

MenuCamera.MaxXRotation = 10
MenuCamera.MaxYRotation = 10
MenuCamera.Smoothness = 0.08

-- ========================
-- STATE
-- ========================
MenuCamera.CF0 = nil
MenuCamera._targetCF = nil
MenuCamera._inputLocked = false

MenuCamera._mouseConn = nil
MenuCamera._renderConn = nil
MenuCamera._tweenConn = nil

-- ========================
-- INTERNAL SMOOTH
-- ========================
function MenuCamera:_SmoothTo(
	time: number,
	targetCF: CFrame,
	easingStyle: Enum.EasingStyle,
	easingDirection: Enum.EasingDirection,
	callback
)
	if self._tweenConn then
		self._tweenConn:Disconnect()
		self._tweenConn = nil
	end

	local startCF = self.Camera.CFrame
	local startTime = tick()

	self._tweenConn = RunService.RenderStepped:Connect(function()
		local alpha = math.clamp((tick() - startTime) / time, 0, 1)
		local eased = TweenService:GetValue(alpha, easingStyle, easingDirection)

		self.Camera.CFrame = startCF:Lerp(targetCF, eased)

		if alpha >= 1 then
			self._tweenConn:Disconnect()
			self._tweenConn = nil
			if callback then callback() end
		end
	end)
end

-- ========================
-- LOCK INPUT
-- ========================
function MenuCamera:LockInput(state: boolean)
	self._inputLocked = state
end

-- ========================
-- SET CAMERA (MENU)
-- ========================
function MenuCamera:SetCamera(
	cameraPart: BasePart,
	time: number?,
	easingStyle: Enum.EasingStyle?,
	easingDirection: Enum.EasingDirection?
)
	self:Disable()
	
	time = time or 0.6
	easingStyle = easingStyle or Enum.EasingStyle.Sine
	easingDirection = easingDirection or Enum.EasingDirection.Out

	self.Camera.CameraType = Enum.CameraType.Scriptable
	self.Camera.FieldOfView = 55

	self.CF0 = cameraPart.CFrame
	self._targetCF = self.CF0

	--self:LockInput(false)

	self:_SmoothTo(time, self.CF0, easingStyle, easingDirection, function()
		local function updateMouse()
			if self._inputLocked then return end

			local x = (Mouse.X / self.Camera.ViewportSize.X) - 0.5
			local y = (Mouse.Y / self.Camera.ViewportSize.Y) - 0.5

			self._targetCF =
				self.CF0
				* CFrame.fromOrientation(
					math.rad(self.MaxYRotation * -y),
					math.rad(self.MaxXRotation * -x),
					0
				)
		end

		updateMouse()
		self._mouseConn = Mouse.Move:Connect(updateMouse)

		self._renderConn = RunService.RenderStepped:Connect(function()
			self.Camera.CFrame =
				self.Camera.CFrame:Lerp(self._targetCF, self.Smoothness)
		end)
	end)
end

-- ========================
-- RESET MENU CAMERA
-- ========================
function MenuCamera:Reset(
	time: number?,
	easingStyle: Enum.EasingStyle?,
	easingDirection: Enum.EasingDirection?
)
	if not self.CF0 then return end

	if self._renderConn then
		self._renderConn:Disconnect()
		self._renderConn = nil
	end

	time = time or 0.5
	easingStyle = easingStyle or Enum.EasingStyle.Sine
	easingDirection = easingDirection or Enum.EasingDirection.Out

	self:_SmoothTo(time, self.CF0, easingStyle, easingDirection, function()
		self._targetCF = self.CF0

		self._renderConn = RunService.RenderStepped:Connect(function()
			self.Camera.CFrame =
				self.Camera.CFrame:Lerp(self._targetCF, self.Smoothness)
		end)
	end)
end

-- ========================
-- RESET TO GAMEPLAY
-- ========================
function MenuCamera:ResetToPlayerCamera(time: number?)
	local character = Player.Character or Player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	time = time or 0.6

	--self:LockInput(true)
	self:Disable()

	self.Camera.CameraType = Enum.CameraType.Scriptable

	self:_SmoothTo(time, self.Camera.CFrame, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, function()
		self.Camera.CameraType = Enum.CameraType.Custom
		self.Camera.CameraSubject = humanoid
	end)
end

-- ========================
-- DISABLE
-- ========================
function MenuCamera:Disable()
	if self._mouseConn then
		self._mouseConn:Disconnect()
		self._mouseConn = nil
	end

	if self._renderConn then
		self._renderConn:Disconnect()
		self._renderConn = nil
	end

	if self._tweenConn then
		self._tweenConn:Disconnect()
		self._tweenConn = nil
	end
end

return MenuCamera