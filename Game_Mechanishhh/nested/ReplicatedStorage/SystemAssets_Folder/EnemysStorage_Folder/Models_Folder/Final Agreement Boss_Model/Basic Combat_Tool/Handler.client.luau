local Tool = script.Parent
local Player = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local CFSModule = require(RS:WaitForChild("Modules"):WaitForChild("SharedLocalScriptFuncts"))
local Character = Player.Character
local SkillGuis = Player.PlayerGui:WaitForChild("SkillGuis")
local SE = RS:WaitForChild("SystemEvents")
local EquipTool = SE:WaitForChild("EquipTool")
local ActivateTool = SE:WaitForChild("ActivateTool")
--Atributos que necesitaran llevar todas las tools
--Type: Servant, Combat, Sword
--Name: Harturia Dragon, Basic Combat, Basic Sword
--ObjectID: ID del objeto al que referencia en el inventario
--Si es shiny
--Shiny: Nombredelshiny

Tool.Equipped:Connect(function()
	EquipTool:FireServer(Tool,true)
	SkillGuis[Tool:GetAttribute("Type").."SkillsGui"].Visible = true
end)
Tool.Unequipped:Connect(function()
	EquipTool:FireServer(Tool,false)
	SkillGuis[Tool:GetAttribute("Type").."SkillsGui"].Visible = false
end)




Tool.Activated:Connect(function()
	if Tool:GetAttribute("M1") then
		local canAttack = Character:GetAttribute("CanAttack")
		if not canAttack or CFSModule.CFS(Character,{"Attacking"}) == 1 then return end
		CFSModule.LookToMouse(Character,Player:GetMouse(),1.5)
		ActivateTool:FireServer(Tool)
	end
end)