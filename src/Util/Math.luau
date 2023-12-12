--!strict

local mathMethods = {}

--[=[
	Interpolates between two numbers.

	#### Example:
	```lua
	lerp(0, 10, .5) -- 5
	lern(0, 10, 1) -- 10
	```

	@within Util
	@param start number
	@param stop number
	@param alpha number
	@return number
]=]
function mathMethods.lerp(start: number, stop: number, alpha: number): number
	return start * (1 - alpha) + stop * alpha
end

--[=[
	Rounds a number to the nearest integer.

	#### Example:
	```lua
	round(1.5) -- 2
	round(1.4) -- 1
	```

	@within Util
	@param number number
	@param kenetec boolean? -- Whether to use kenetec rounding or not. Defaults to false.
	@return number
]=]
function mathMethods.round(number: number, kenetec: boolean?): number
	assert(typeof(number) == "number", "number must be a number")
	assert(typeof(kenetec) == "boolean" or kenetec == nil, "kenetec must be a boolean or nil")

	return not kenetec and math.floor(number + .5) or number + .5 - (number + .5) % 1
end

--[=[
	Formats a number to have commas.

	#### Example:
	```lua
	formatInt(1000) -- 1,000
	formatInt(1000.01) -- 1,000.01
	```

	@within Util
	@param number number
	@return string
]=]
function mathMethods.formatInt(number: number): string -- 1000.01 to 1,000.01
	assert(typeof(number) == "number", "Number argument must be a number")

	local numberString: string = tostring(number)
	local minus, int, fraction = numberString:match("([-]?)(%d+)([.]?%d*)")

	if not minus or not int or not fraction then
		return ""
	end

	int = string.gsub(int:reverse(), "(%d%d%d)", "%1,"):reverse():gsub("^,", "")

	return `{minus}{int}{fraction}`
end

--[=[
	Returns a random number between two numbers.

	#### Example:
	```lua
	random(1, 10) -- 5
	random(1, 10, true) -- 5.5
	random(10) -- 5 (min defaults to 1)
	random(10, true) -- 5.5 (min defaults to 1)
	```

	@within Util
	@param number1 number
	@param number2 number?
	@param float boolean? -- Whether to return as a float or not. Defaults to false.
]=]
function mathMethods.random(number1: number, number2: number?, float: boolean?): number
	assert(typeof(number1) == "number", "Number1 argument must be a number")
	assert(typeof(number2) == "number" or number2 == nil, "Number2 argument must be a number or nil")
	assert(typeof(float) == "boolean" or float == nil, "Float argument must be a boolean or nil")

	local min: number = not number2 and 1 or number1 -- If number2 is not defined, use 1 as min
	local max: number = number2 or number1

	return float == true and
		Random.new():NextNumber(min, max) or -- Return float
		Random.new():NextInteger(min, max) -- Return integer
end

local charset: string = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local charsetLength: number = #charset

--[=[
	Returns a random string.

	#### Example:
	```lua
	randomString() -- "aBcDeFgHiJkLmNoPqRsTuVwXyZ"
	randomString(10) -- "aBcDeFgHiJ"
	```

	@within Util
	@param length number? -- The length of the string. Defaults to 18.
	@return string
]=]
function mathMethods.randomString(length: number?): string
	local res: string = ""

	for _ = 1, (length or 18) do
		local random: number = mathMethods.random(charsetLength)
		res = res .. charset:sub(random, random)
	end

	return res
end

--[=[
	Returns a random object from a table or instance.

	#### Example:
	```lua
	randomObj({ "a", "b", "c" }) -- "b"
	randomObj(Workspace.Player) -- Head
	```

	@within Util
	@param obj table | Instance
	@return any
]=]
function mathMethods.randomObj(obj: { [any]: any } | Instance): any
	if typeof(obj) == "Instance" then
		-- convert to a table
		obj = obj:GetChildren()
	end

	if typeof(obj) == "table" then
		return obj[mathMethods.random(1, #obj)]
	end

	return
end

local si = { "K", "M" , "B", "T", "Q" }

--[=[
	Shortens a large number to a readable format.
	Useful for displaying large numbers that don't require exact precision.
	Common use cases are for displaying XP, money in leaderboards, damage etc.

	#### Example:
	```lua
	shortenNumber(1000) -- 1K
	shortenNumber(1000000) -- 1M
	shortenNumber(1000000000) -- 1B
	shortenNumber(1000000000000) -- 1T
	shortenNumber(1000000000000000) -- 1Q
	```

	minimumTiers is useful for when you want to shorten a number but only if it's above a certain tier.
	For example, if you want to shorten a number but only if it's above 1,000,000, you would do:
	```lua
	shortenNumber(1000000, 2) -- 1,000,000
	```

	A tier is the amount of commas in a number. For example, 1,000,000 has 2 tiers and 1,000 has 1 tier.

	Tier list and their abbreviations:
	- 1,000 = K
	- 1,000,000 = M
	- 1,000,000,000 = B
	- 1,000,000,000,000 = T
	- 1,000,000,000,000,000 = Q

	@within Util
	@param number number | string
	@param minimumTiers number? -- The minimum number of tiers to shorten. Defaults to 1.
	@return string
]=]
function mathMethods.shortenNumber(number: number | string, minimumTiers: number?): string
	assert(number, "Missing number argument")

	number = typeof(number) == "string" and tonumber(number) or number

	assert(typeof(number) == "number", "Number argument be a number or string that can be converted to a number")

	local negative: number = math.abs(number) == number and 1 or -1
	number = math.abs(number)

	local tier = math.log10(number) / 3

	if tier < (minimumTiers or 1) then -- If tier is less than minimumTiers, return the number
		return mathMethods.formatInt(number * negative)
	end

	tier = math.floor(tier)

	local tierSuffix = si[tier] or si[#si] -- Get tier or use highest tier if # too high

	local _number: number? = tonumber(
		string.format("%.2f", number / 10 ^ (3 * tier))
	)

	if not _number then
		return ""
	end

	return (mathMethods.formatInt(_number)) .. tierSuffix
end

--[=[
	Gets a Vector3 from an object containing a Vector3 or CFrame.

	#### Supports:
	- Vector3
	- CFrame
	- Attachment
	- BasePart
	- CFrameValue
	- Vector3Value
	- Camera

	@within Util
	@param object Vector3 | CFrame | Instance
	@return Vector3?
]=]
function mathMethods.getVector3(object: Vector3 | CFrame | Instance): Vector3?
	return (
		typeof(object) == "Vector3" and object
	) or (
		typeof(object) == "CFrame" and object.Position
	) or (
		typeof(object) == "Instance" and (
			(object:IsA("Attachment") and object.WorldPosition) or
			(object:IsA("BasePart") and object.Position) or
			(object:IsA("CFrameValue") and object.Value and object.Value.Position) or
			(object:IsA("Vector3Value") and object.Value) or
			(object:IsA("Camera") and object.CFrame.Position)
		)
	) or nil
end

--[=[
	Gets the distance between two Vector3s.

	@within Util
	@param origin Vector3 | Instance
	@param target Vector3 | Instance
	@return number
]=]
function mathMethods.getDistance(origin: any, target: any)
	local originVector3: Vector3? = mathMethods.getVector3(origin)
	local targetVector3: Vector3? = mathMethods.getVector3(target)

	assert(
		originVector3,
		"Util.getDistance - Parameter 1 is missing a Vector3 value or an Instance with a Vector3 Position"
	)
	assert(
		targetVector3,
		"Util.getDistance - Parameter 2 is missing a Vector3 value or an Instance with a Vector3 Position"
	)

	return (originVector3 - targetVector3).Magnitude
end

--[=[
	Gets the bottom surface of a part.

	@within Util
	@param part BasePart
	@return CFrame
]=]
function mathMethods.getPartBottomSurface(part: BasePart): CFrame
	return part.CFrame * CFrame.new(0, -part.Size.Y / 2, 0)
end

return mathMethods
