local FormatNumber = {}

local function addCommas(number)
	local formatted = tostring(number)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return formatted
end


local suffixes = {
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"
}

local function abbreviate(number)
	local index = 1
	local num = math.abs(number) * 1.0
	while num >= 1000 and index < #suffixes do
		num = num / 1000
		index = index + 1
	end

	local formatted = string.format("%.2f", num)

	formatted = string.gsub(formatted, "%.00$", "")
	formatted = string.gsub(formatted, "(%.%d)0$", "%1")

	if number < 0 then
		formatted = "-" .. formatted
	end

	return formatted .. suffixes[index]
end

function FormatNumber.Format(number)
	if math.abs(number) >= 1000 then
		return abbreviate(number)
	else
		return addCommas(number)
	end
end

return FormatNumber