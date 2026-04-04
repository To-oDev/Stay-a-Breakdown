local lerpMan = {}
lerpMan.lerpStyles = {
	In = {},
	Out = {}
}
function lerpMan.lerpStyles.In.quad(progress)
	return progress ^ 2
end
function lerpMan.lerpStyles.In.quart(progress)
	return progress ^ 4
end
function lerpMan.lerpStyles.In.expo(progress)
	return 2 ^ (10 * progress - 10)
end
function lerpMan.lerpStyles.In.circ(progress)
	return 1 - math.sqrt(1 - (progress ^ 2))
end
function lerpMan.lerpStyles.In.cubic(progress)
	return progress ^ 3
end
function lerpMan.lerpStyles.Out.expo(progress)
	return progress == 1 and 1 or (1 - (2 ^ (-10 * progress)))
end
function lerpMan.lerpStyles.Out.quad(progress)
	return 1 - ((1 - progress) ^ 2)
end
function lerpMan.lerpStyles.Out.cubic(progress)
	return 1 - ((1 - progress) ^ 3)
end
function lerpMan.lerpStyles.Out.quart(progress)
	return 1 - ((1 - progress) ^ 4)
end
function lerpMan.lerpStyles.Out.circ(progress)
	return math.sqrt(1 - ((progress - 1) ^ 2))
end

function lerpMan.lerp(startValue, endValue, alpha, easingFunction)
	if easingFunction then
		alpha = easingFunction(alpha)
	end
	return startValue + (endValue - startValue) * alpha
end

return lerpMan