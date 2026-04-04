function onTouch(hit)
script.Parent.Anchored = true
script.Parent.Parent = Workspace
script.Parent.Transparency = 1
wait()
script.Parent.Atom.Disabled = false
end

script.Parent.Touched:connect(onTouch)