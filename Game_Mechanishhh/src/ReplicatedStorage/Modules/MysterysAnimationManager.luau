local module = {}
local AnimCache = {}

function RegisterAnimator(animator: Animator)
	AnimCache[animator] = {}
	animator.Destroying:Connect(function()
		AnimCache[animator] = nil
	end)
	animator.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			AnimCache[animator] = nil
		end
	end)
end


function module.GetTrack(animator, animation)
	local cache = AnimCache[animator]
	if not cache then
		RegisterAnimator(animator)
		cache = AnimCache[animator]
	end

	local id = animation.AnimationId
	if not cache[id] then
		cache[id] = animator:LoadAnimation(animation)
	end
	return cache[id]
end
return module