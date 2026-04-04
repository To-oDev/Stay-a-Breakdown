local ScreenGui = script:FindFirstAncestorOfClass("ScreenGui")
local Information = ScreenGui:WaitForChild("Information")

local Texts = {
	[1] = {
		Header = "Misiones de viaje:",
		Body = "Las misiones de viaje consumen monedas y son esenciales de modo de juego PvE. Son geniales para cultivar sin interrupciones.",
	}
}

local function updateText(i)
	local Text = Texts[i]
	
	if Text then
		Information.Header.Text = Text.Header
		Information.Body.Text = Text.Body
	end
end

updateText(1)