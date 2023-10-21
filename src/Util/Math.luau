--!strict

local mathMethods = {}

mathMethods.lerp = function(start: number, stop: number, alpha: number): number
	return start * (1 - alpha) + stop * alpha
end

mathMethods.round = function(x: number, kenetec): number
	return not kenetec and math.floor(x + .5) or x + .5 - (x + .5) % 1
end

mathMethods.formatInt = function(number: number): string -- 1000.01 to 1,000.01
	local minus, int, fraction = tostring(number):match("([-]?)(%d+)([.]?%d*)")
	return minus .. string.gsub(int:reverse(), "(%d%d%d)", "%1,"):reverse():gsub("^,", "") .. fraction
end

--[[
Util.random(10) -- random number 1 through 10
Util.random()
]]
mathMethods.random = function(number1: number, number2: number?, float: boolean?): number
    local min = not number2 and 1 or number1 -- If number2 is not defined, use 1 as min
    local max = not number2 and number1 or number2 -- If number2 is not defined, use number1 as max
    
    return float and Random.new():NextNumber(min, max) or Random.new():NextInteger(min, max)
end

mathMethods.charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

mathMethods.randomString = function(length: number?): string
	local res: string = ""
	
	for _ = 1, (length or 18) do
		local r = mathMethods.random(#mathMethods.charset)
		res = res .. mathMethods.charset:sub(r, r)
	end
	
	return res
end

mathMethods.randomObj = function(obj)
	if typeof(obj) == "Instance" then
		-- convert to a table
		obj = obj:GetChildren()
	end
	
	if typeof(obj) == "table" then
		return obj[mathMethods.random(1, #obj)]
	end
end

local si = { "K", "M" , "B", "T", "Q" }

mathMethods.shortenNumber = function(number: number, minimumTier): string
	assert(number, "No number to shorten")
	
	number = typeof(number) == "string" and tonumber(number) or number
	
	assert(typeof(number) == "number", "Number to shorten must be a number")
	
	local negative = math.abs(number) == number and 1 or -1
	number = math.abs(number)
	
	local tier = math.log10(number) / 3
	
	if tier < (minimumTier or 1) then -- If under 1 mil
		return mathMethods.formatInt(number) * negative
	end
	
	tier = math.floor(tier)
	
	local suffix = si[tier] or si[#si] -- Get tier or use highest tier if # too high
	
	return (mathMethods.formatInt(tonumber(
		string.format("%.2f", number / 10 ^ (3 * tier))
	)) * negative) .. suffix
end

mathMethods.getVector3 = function(object: any)
	return typeof(object) == "Vector3" and object or (
		typeof(object) == "CFrame" and object.Position
	) or (
		typeof(object) == "Instance" and (
			(object:IsA("BasePart") and object.Position) or
			(object:IsA("CFrameValue") and object.Value.Position) or
			(object:IsA("Vector3Value") and object.Value)
		)
	) or nil
end

mathMethods.getDistance = function(a, b)
	a = mathMethods.getVector3(a)
	b = mathMethods.getVector3(b)
	
	assert(a, "Util.getDistance - Parameter 1 is missing a Vector3 value or an Instance with a Vector3 Position")
	assert(b, "Util.getDistance - Parameter 2 is missing a Vector3 value or an Instance with a Vector3 Position")
	
	return (a - b).Magnitude
end

mathMethods.getPartBottomSurface = function(part: BasePart): CFrame
	return part.CFrame * CFrame.new(0, -part.Size.Y / 2, 0)
end

return mathMethods