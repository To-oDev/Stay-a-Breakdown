local module = {}
--Services
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Modules = RS:WaitForChild("Modules")
local DataModules = SS:WaitForChild("DataModules")
--Modules
local DataSaver = require(DataModules:WaitForChild("DataSaver"))
local FXModule = require(Modules:WaitForChild("FXModule"))
local RewardModule = require(DataModules.Parent:WaitForChild("Systems"):WaitForChild("RewardManager"))
local ChestDrops = require(Modules:WaitForChild("DataBaseLibrarys"):WaitForChild("ChestDropsLibrary"))
local ISF = require(Modules:WaitForChild("InventorySharedFunctions"))
local DataManager = require(DataModules:WaitForChild("DataManager"))
--Events
local GuiEvent = RS:WaitForChild("UISEvents"):WaitForChild("ShowChestGUI")
local RemoteEvent = RS:WaitForChild("SystemEvents"):WaitForChild("FXEvent")
local NotificationEvent = RS:WaitForChild("UISEvents"):WaitForChild("ShowMessage")
local ChestVerificator = RS:WaitForChild("UISEvents"):WaitForChild("ChestVerificator")

local ChestGenerationZones = workspace:WaitForChild("ChestGenerationZones")
--Requirements
local DungeonChestsTable = {}
local CGZ = game.Workspace:WaitForChild("ChestGenerationZones")
local function Data(Part)
	RemoteEvent:FireAllClients("CreateChests",Part)
	module.SetChestZones(Part)
end

task.delay(2,function()
	for i,Part in ipairs(CGZ:GetChildren()) do
		Data(Part)
	end
	CGZ.ChildAdded:Connect(function(Part)
		Data(Part)
	end)
end)


function module.ReplicateChests(Player)
	RemoteEvent:FireClient(Player,"CreateChests")
end

function module.SetChestZones(ChestSpawnPart: Part)
	if ChestSpawnPart:FindFirstChild("OpenPart") and (not ChestSpawnPart:GetAttribute("Configured")) then
		local Configurations = require(ChestSpawnPart:FindFirstChild("Configuration"))
		if not Configurations then return end
		
		ChestSpawnPart:SetAttribute("Configured", true)
		ChestSpawnPart.Name = Configurations.ChestID
		
		local ChestPrompt = Instance.new("ProximityPrompt")
		ChestPrompt.Style = Enum.ProximityPromptStyle.Custom
		
		ChestPrompt.MaxActivationDistance = 10
		ChestPrompt.MaxIndicatorDistance = 40
		
		ChestPrompt.HoldDuration = 0.5
		ChestPrompt:SetAttribute("PromptStyle", "ChestPrompt")
		ChestPrompt.Parent = ChestSpawnPart.OpenPart
		
		ChestSpawnPart.Destroying:Once(function()
			if ChestPrompt then
				ChestPrompt:Destroy()
			end
		end)
		
		if ChestSpawnPart:GetAttribute("CantBeOpened") then
			if ChestPrompt then
				ChestPrompt:Destroy()
			end
		end
		
		ChestSpawnPart:GetAttributeChangedSignal("CantBeOpened"):Once(function()
			local cantBeOpened = ChestSpawnPart:GetAttribute("CantBeOpened")
			
			if cantBeOpened and ChestPrompt then
				ChestPrompt:Destroy()
			end
		end)
	end
end

function module.ErrorChest(Player,ChestData,Message)
	NotificationEvent:FireClient(Player, "Error", Message or "You need ("..ChestData.Locked.." x"..(ChestData.LockedAmount or 1)..") to unlock this chest", "Error", 3)
	GuiEvent:FireClient(Player,"Failed")
end

ChestVerificator.OnServerInvoke = function(Player: Player, Prompt: ProximityPrompt, active: boolean)
	local Character = Player.Character
	local ChestSpawnPart = Prompt and Prompt.Parent and Prompt.Parent.Parent
	
	if Character and ChestSpawnPart then
		Character:SetAttribute("ChestZone", active and ChestSpawnPart.Name or nil)
	end
	
	local OpenPart = ChestSpawnPart and ChestSpawnPart:FindFirstChild("OpenPart")
	local ChestPrompt = OpenPart and OpenPart:FindFirstChildOfClass("ProximityPrompt")
	if not Character or not ChestSpawnPart then return end
	
	local CantBeOpened = ChestSpawnPart:GetAttribute("CantBeOpened")
	local isDungeonChest = (DungeonChestsTable[ChestSpawnPart.Name] and DungeonChestsTable[ChestSpawnPart.Name][Player])

	if CantBeOpened then
		if ChestPrompt then
			ChestPrompt:Destroy()
		end
		
		isDungeonChest = true
	end
	
	return isDungeonChest 
end

GuiEvent.OnServerEvent:Connect(function(Player,Verification)
	local Character = Player.Character
	if Character:GetAttribute("ChestZone") then
		local Chest = Character:GetAttribute("ChestZone")
		local TargetPart = game.Workspace:WaitForChild("ChestGenerationZones"):FindFirstChild(Chest)
		local CantBeOpened = TargetPart:GetAttribute("CantBeOpened")
		if CantBeOpened then return end
		local hrp = Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local ChestData = require(TargetPart:FindFirstChild("Configuration"))
		if ChestData.Locked then
			local Data = DataSaver.GetSyncPlayerData(Player)
			local Inv = Data and Data.Inventory.Data
			local Item = ISF.FindItemWithName(Inv,ChestData.Locked)
			if not Item then
				module.ErrorChest(Player,ChestData)
				return
			elseif Verification then
				local Success = DataManager.RemoveItem(Player,Item.ObjectID,(ChestData.LockedAmount or 1),Item.Type,Item.Name)
				if not Success then module.ErrorChest(Player,ChestData,"You don't have the neccesary amount of items.") return end
			else
				GuiEvent:FireClient(Player,nil,nil,"Use ("..ChestData.Locked.." x"..(ChestData.LockedAmount or 1)..") to unlock this chest?")
				return
			end
		end

		local frontOffset = TargetPart.CFrame.LookVector * -5
		local targetPosition = Vector3.new(TargetPart.Position.X,Character.HumanoidRootPart.Position.Y+0.4,TargetPart.Position.Z) + frontOffset
		local lookAtCFrame = CFrame.new(targetPosition, TargetPart.Position)
		hrp.CFrame = CFrame.new(targetPosition, TargetPart.Position)
		GuiEvent:FireClient(Player,nil,true)
		if ChestData.ChestType == "DungeonChest" then
			if not DungeonChestsTable[ChestData.ChestID] then
				DungeonChestsTable[ChestData.ChestID] = {}
			end
			DungeonChestsTable[ChestData.ChestID][Player] = true
		end
		if next(ChestData.ChestLoots) then
			RewardModule.CalculateReward(Player,ChestData.ChestLoots)
		else
			local Table = ChestDrops.GetChestDrops(ChestData.ChestName)
			local Reward = Table[math.random(1,#Table)]
			RewardModule.CalculateReward(Player,Reward)
		end
		
		Character:SetAttribute("ChestZone", nil)

		if not ChestData.Local then
			TargetPart:SetAttribute("CantBeOpened",true)
			RemoteEvent:FireAllClients("OpenChest",Player,Chest)
		else
			RemoteEvent:FireClient(Player,"OpenChest",Player,Chest)
		end
	end
end)

return module