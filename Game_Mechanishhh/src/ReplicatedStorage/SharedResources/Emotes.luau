local Emotes = {
	["12345"] = {
		Type = "Emote",
		Price = 0,

		Name = "ANIMATION",
		Image = "rbxassetid://137338676693994",
		AnimationId = "rbxassetid://0"
	}
}

return function(EmoteID: string)
	return Emotes[EmoteID]
end