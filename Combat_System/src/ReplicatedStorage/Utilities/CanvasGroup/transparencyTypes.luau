local types = {
	-- ▼ GUIOBJECTS ▼ --
	["Frame"] = {
		"BackgroundTransparency"
	},

	["TextLabel"] = {
		"BackgroundTransparency",
		"TextTransparency",
		"TextStrokeTransparency"
	},

	["TextButton"] = {
		"BackgroundTransparency",
		"TextTransparency",
		"TextStrokeTransparency"
	},
	
	["TextBox"] = {
		"BackgroundTransparency",
		"TextTransparency",
		"TextStrokeTransparency"
	},

	["ImageLabel"] = {
		"BackgroundTransparency",
		"ImageTransparency"
	},

	["ImageButton"] = {
		"BackgroundTransparency",
		"ImageTransparency"
	},

	["ScrollingFrame"] = {
		"BackgroundTransparency",
		"ScrollBarImageTransparency"
	},

	["ViewportFrame"] = {
		"BackgroundTransparency"
	},

	["CanvasGroup"] = {
		"GroupTransparency"
	},

	["VideoFrame"] = {
		"BackgroundTransparency"
	},

	-- ▼ NO ES GUIOBJECT, PERO LO QUIERES AQUI ▼ --
	["UIStroke"] = {
		"Transparency"
	},

}

return function(child: Instance)
	return types[child.ClassName]
end