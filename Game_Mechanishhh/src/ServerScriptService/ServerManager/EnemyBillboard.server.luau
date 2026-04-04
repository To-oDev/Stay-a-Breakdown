local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:WaitForChild("GUIStorage")
local BillboardUIS = Assets:WaitForChild("BillboardUIS")

local function updateBillboard(enemy: Model?)
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local billboard = BillboardUIS.EnemyHealthDisplayerTemplate:Clone()
	billboard.EnemyName.Text = enemy.Name
	
	local HealthBar = billboard:FindFirstChild("HealthBar")
	local Bar = HealthBar:FindFirstChild("Bar")
	
	local function updateUI()
		local health = humanoid.Health
		local maxHealth = humanoid.MaxHealth

		local percent = health / maxHealth
		HealthBar.Health.Text = math.floor(health) .. "/" .. maxHealth
		Bar:TweenSize(UDim2.new(percent, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
	end
	
	billboard.Enabled = true
	billboard.Parent = enemy:FindFirstChild("Head")
	
	updateUI()
	humanoid:GetPropertyChangedSignal("Health"):Connect(updateUI)
end

local function updateBillboards()
	for _, enemy in ipairs(CollectionService:GetTagged("Enemy")) do
		updateBillboard(enemy)
	end
	
	CollectionService:GetInstanceAddedSignal("Enemy"):Connect(updateBillboard)
end

updateBillboards()