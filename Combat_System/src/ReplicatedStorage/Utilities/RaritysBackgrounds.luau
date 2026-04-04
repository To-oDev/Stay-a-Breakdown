local RaritysBackgorunds = {}
RaritysBackgorunds.Raritys = {
	Common = "rbxassetid://118893333763906",
	Epic = "rbxassetid://82326816069919",
	Legendary = "rbxassetid://96992051539650",
	Mythic = "rbxassetid://113416492899576",
	Shiny = "rbxassetid://106755067344252",
	Uncategorized  = "rbxassetid://106755067344252",
}

function RaritysBackgorunds.GetBackground(rarity: string)
	return RaritysBackgorunds.Raritys[rarity]
end

return RaritysBackgorunds