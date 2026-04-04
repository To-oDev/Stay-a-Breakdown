local RainbowColorText = {}
RainbowColorText.Object = {}

local RunService = game:GetService("RunService")
local UIGradient = script:FindFirstChildOfClass("UIGradient")

local function clearObject(TextLabel: TextLabel?)
	if RainbowColorText.Object[TextLabel] then
		RainbowColorText.Object[TextLabel]:Disconnect()
		RainbowColorText.Object[TextLabel] = nil
	end
end

function RainbowColorText.AddEffect(TextLabel: TextLabel)
	local newGradient = UIGradient:Clone()
	newGradient.Parent = TextLabel
	
	RunService:BindToRenderStep(TextLabel.Name, Enum.RenderPriority.Camera.Value + 1, function()
		newGradient.Rotation += 1
	end)
	
	RainbowColorText.Object[TextLabel] = TextLabel.Destroying:Once(function()
		clearObject(TextLabel)
		RunService:UnbindFromRenderStep(TextLabel.Name)
	end)
end

function RainbowColorText.RemoveEffect(TextLabel: TextLabel)
	clearObject(TextLabel)
	
	if TextLabel:FindFirstChildOfClass("UIGradient") then
		TextLabel:FindFirstChildOfClass("UIGradient"):Destroy()
	end
	
	if RainbowColorText.Object[TextLabel] then
		RunService:UnbindFromRenderStep(TextLabel.Name)
	end
end

return RainbowColorText