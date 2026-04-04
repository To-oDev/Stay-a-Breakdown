function onClicked()
	script.Parent.Parent.Door.CanCollide = false
	script.Parent.Parent.Door.Transparency = 1
end

script.Parent.ClickDetector.MouseClick:connect(onClicked)