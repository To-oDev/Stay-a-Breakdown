local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local RemoteFunction = game:GetService("ReplicatedStorage"):WaitForChild("SystemEvents"):WaitForChild("GetClientAsset")

RemoteFunction.OnClientInvoke = function(Type)
	if Type == "GetMouseHit" then
		local mouse = LocalPlayer:GetMouse()
		if not mouse or not mouse.Hit then return end
		local cam = workspace.CurrentCamera
		local origin = cam.CFrame.Position
		local direction = (mouse.Hit.Position - origin).Unit * 1000
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {LocalPlayer.Character}

		local result = workspace:Raycast(origin, direction, params)

		if result then
			local part = result.Instance

			if part.Transparency > 0
				or part:IsA("Decal")
				or part:IsA("Texture")
				or part:IsA("BillboardGui")
				or part:GetAttribute("IgnoreMouse") == true
			then
				return mouse.Hit.Position
			end

			return result.Position
		end

		return mouse.Hit.Position
	end
end
