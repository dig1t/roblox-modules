--!strict

local ui = {}

ui.darken = function(color: Color3, percentage: number): Color3
	local h, s, v = color:ToHSV()
	
	return Color3.fromHSV(h, s, v * (1 - percentage))
end

ui.lighten = function(color: Color3, percentage: number): Color3
	local h, s, v = color:ToHSV()
	
	return Color3.fromHSV(h, s, v + (1 - v) * percentage)
end

return ui