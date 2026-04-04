local function WeldDestroy()
	for _, v in script.Parent:GetDescendants() do
		if v:IsA("Weld") and v.Name == "Weld" then
			v:Destroy()
		end
	end
end

WeldDestroy()

script.Parent.ChildAdded:Connect(function()
	WeldDestroy()
end)