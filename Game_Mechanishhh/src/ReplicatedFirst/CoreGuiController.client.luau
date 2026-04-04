local StarterGui = game:GetService("StarterGui")

task.spawn(function()
	print("Setting CoreGui Off...")
	script:SetAttribute("CoreGuiVisible", false)
	while not script:GetAttribute("CoreGuiVisible") do
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		end)
		task.wait(0.1)
	end
	print("Setting CoreGui On...")
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
end)