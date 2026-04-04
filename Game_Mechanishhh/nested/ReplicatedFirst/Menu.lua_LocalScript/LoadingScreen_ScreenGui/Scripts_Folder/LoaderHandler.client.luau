local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local ScreenGui = script:FindFirstAncestorOfClass("ScreenGui")
local Information = ScreenGui:WaitForChild("Information")
local Body = ScreenGui:WaitForChild("Body")

local assetsLoaded = Information:WaitForChild("AssetsLoaded")
local loadingBar = Body:WaitForChild("LoadingBar")
local bar = loadingBar:WaitForChild("Bar")
local skipButton = Body:WaitForChild("SkipButton")

local MenuSounds = SoundService:WaitForChild("MenuSounds")

local MIN_LOADING_TIME = 3
local skipped = false
local loadingFinished = false

local realProgress = 0
local visualProgress = 0

local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

TweenService:Create(assetsLoaded, tweenInfo, {
	TextTransparency = 0.35
}):Play()

task.delay(3, function()
	if not loadingFinished then
		skipButton:SetAttribute("Active", true)
	end
end)

skipButton.Activated:Connect(function()
	if loadingFinished then return end
	skipped = true
	MenuSounds.ButtonClick:Play()
end)

RunService.RenderStepped:Connect(function(dt)
	local speed = 3
	visualProgress += (realProgress - visualProgress) * math.clamp(dt * speed, 0, 1)

	bar.Size = UDim2.fromScale(visualProgress, 1)

	local percent = math.floor(visualProgress * 100)
	assetsLoaded.Text = ("Loading... %d%%"):format(percent)
end)


local function collectAssets(container)
	local assets = {}

	for _, obj in ipairs(container:GetDescendants()) do
		if obj:IsA("ImageLabel")
			or obj:IsA("ImageButton")
			or obj:IsA("Decal")
			or obj:IsA("Texture")
			or obj:IsA("Sound")
			or obj:IsA("MeshPart") then
			table.insert(assets, obj)
		end
	end

	return assets
end

local function preloadList(list, startProgress, endProgress)
	local batchSize = 25
	local total = #list
	local loaded = 0

	for i = 1, total, batchSize do

		if skipped then break end

		local batch = {}

		for j = i, math.min(i + batchSize - 1, total) do
			table.insert(batch, list[j])
		end

		ContentProvider:PreloadAsync(batch)

		loaded += #batch

		local alpha = loaded / total
		realProgress = startProgress + (endProgress - startProgress) * alpha

		task.wait()
	end
end

local startTime = os.clock()

local uiAssets = collectAssets(player.PlayerGui)
preloadList(uiAssets, 0, 0.3)

local soundAssets = collectAssets(SoundService)
preloadList(soundAssets, 0.3, 0.6)

local worldAssets = collectAssets(game.Workspace)
preloadList(worldAssets, 0.6, 0.95)

while os.clock() - startTime < MIN_LOADING_TIME do
	task.wait()
end

realProgress = 1
loadingFinished = true

skipButton:SetAttribute("Active", false)
assetsLoaded.Text = "Loading Complete!"

task.wait(1)
ScreenGui:SetAttribute("Active", false)