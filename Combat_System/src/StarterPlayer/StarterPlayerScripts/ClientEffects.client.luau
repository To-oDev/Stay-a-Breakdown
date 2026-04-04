local RS = game:GetService("ReplicatedStorage")
local FXModule = require(RS:WaitForChild("Modules"):WaitForChild("FXModule"))
local RemoteEvent = RS:WaitForChild("SystemEvents"):WaitForChild("FXEvent")
local remoteConnection


local function ConnectRemote()
	if remoteConnection then
		remoteConnection:Disconnect()
	end

	remoteConnection = RemoteEvent.OnClientEvent:Connect(function(fx_type, ...)
		FXModule[fx_type](...)
	end)
end

ConnectRemote()