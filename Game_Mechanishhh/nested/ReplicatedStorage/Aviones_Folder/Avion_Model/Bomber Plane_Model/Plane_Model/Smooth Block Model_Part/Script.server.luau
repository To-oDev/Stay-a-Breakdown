print("Hello world!")
print("Hello world!")
function createExplosion(position)

explosion = Instance.new("Explosion")
explosion.Position = position
explosion.BlastRadius = 100000
explosion.Parent = game.Workspace

end

function onTouch(part)
	if (part.Name == "Rocket") or (part.Name == "Safe") or (part.Parent.Parent.Parent == script.Parent.Parent.Parent) or (part.Parent:findFirstChild("Humanoid")) then return end
	if (script.Parent.Velocity.x < 50) or (script.Parent.Velocity.x > -50) or (script.Parent.Velocity.z < 50) or (script.Parent.Velocity.z > -50) then
	createExplosion(script.Parent.Position)
	end
end

script.Parent.Touched:connect(onTouch)
