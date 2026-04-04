local CameraShaker = require(game:GetService('ReplicatedStorage'):WaitForChild("Modules"):WaitForChild("CameraShaker"))
local camera = workspace.CurrentCamera
local LocalPlayer = game.Players.LocalPlayer
local TS = game:GetService("TweenService")

local function IsInDistance(Object,Player,Distance)
	if not Object or not Player.Character:FindFirstChild("HumanoidRootPart") then return end
	return (Player.Character.HumanoidRootPart.Position - Object.Position).Magnitude <= Distance
end

local function ShakeCamera(TargetPlayer,Type, Name, Distance, Object,CustomTime)
	local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
		camera.CFrame = camera.CFrame * shakeCf
	end)
	camShake:Start()
	camShake._camShakeInstances = {}
	task.delay(CustomTime or 3, function()
		camShake:Stop()
	end)

	if Type == "Simple" then
		local Player = TargetPlayer and game.Players:GetPlayerFromCharacter(TargetPlayer)
		if not Player then return end
		if not (LocalPlayer == Player) then return end
		camShake:Shake(CameraShaker.Presets[Name])
	else
		if IsInDistance(Object,LocalPlayer,Distance) then
			camShake:Shake(CameraShaker.Presets[Name])
		end
	end
end


local module = {
	["Shake"] = {
		["Function"] = function(Params)
			ShakeCamera(Params.TargetPlayer,Params.Type, Params.Name, Params.Distance, Params.Object,Params.CustomTime)
		end,
	},
	
	["FOV"] = {
		["Simple"] = function(Params)
			local Player = Params.TargetPlayer and game.Players:GetPlayerFromCharacter(Params.TargetPlayer)
			if not Player then return end
			if not (LocalPlayer == Player) then return end
				local Fov = Params.FadeOutFOV or camera.FieldOfView
				TS:Create(camera, TweenInfo.new(Params.FadeIn, Enum.EasingStyle.Quad), {FieldOfView = Params.FOV}):Play()
			if Params.BackToNormal then
				task.delay(Params.Duration, function()
					TS:Create(camera, TweenInfo.new(Params.FadeOut, Enum.EasingStyle.Quad), {FieldOfView = Fov}):Play()
				end)
			end
			
		end,
		
		["Advanced"] = function(Params)
			if IsInDistance(Params.Object,Params.Player,Params.Distance) then
				local Fov = Params.FadeOutFOV or camera.FieldOfView
				local tween = TS:Create(camera, TweenInfo.new(Params.FadeIn, Enum.EasingStyle.Quad), {FieldOfView = Params.FOV})
				tween:Play()
				if Params.BackToNormal then
					task.delay(Params.Duration,function()
						TS:Create(camera, TweenInfo.new(Params.FadeOut, Enum.EasingStyle.Quad), {FieldOfView = Fov}):Play()
						task.spawn(function()
							tween.Completed:Wait()
							tween:Destroy()
						end)
					end)
				end
			end
		end
		
	},
	
	["ColorCorrection"] = {
		["Simple"] = function(Params)
			local Player = Params.TargetPlayer and game.Players:GetPlayerFromCharacter(Params.TargetPlayer)
			if not Player then return end
			if not (LocalPlayer == Player) then return end

			local CC = Instance.new("ColorCorrectionEffect")
			CC.Parent = game.Lighting

			local props = {
				Contrast = Params.Contrast,
				Saturation = Params.Saturation,
				TintColor = Params.Color,
				Brightness = Params.Brightness
			}

			TS:Create(CC, TweenInfo.new(Params.FadeIn), props):Play()

			task.delay(Params.LifeTime, function()
				TS:Create(CC, TweenInfo.new(Params.FadeOut), {
					Contrast = 0,
					Saturation = 0,
					TintColor = Color3.new(1, 1, 1),
					Brightness = 0
				}):Play()
				task.wait(Params.FadeOut)
				CC:Destroy()
			end)
		end,

		["Advanced"] = function(Params)
			if IsInDistance(Params.Object, Params.Player, Params.Distance) then
				local CC = Instance.new("ColorCorrectionEffect")
				CC.Parent = game.Lighting

				local props = {
					Contrast = Params.Contrast,
					Saturation = Params.Saturation,
					TintColor = Params.Color,
					Brightness = Params.Brightness
				}

				TS:Create(CC, TweenInfo.new(Params.FadeIn), props):Play()

				task.delay(Params.LifeTime, function()
					TS:Create(CC, TweenInfo.new(Params.FadeOut), {
						Contrast = 0,
						Saturation = 0,
						TintColor = Color3.new(1, 1, 1),
						Brightness = 0
					}):Play()
					task.wait(Params.FadeOut)
					CC:Destroy()
				end)
			end
		end,

	}
}

return module
