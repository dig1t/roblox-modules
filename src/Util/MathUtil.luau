--!strict

local MathUtil = {}

--[=[
	Interpolates between two numbers.

	#### Example:
	```lua
	Util.lerp(0, 10, .5) -- 5
	Util.lerp(0, 10, 1) -- 10
	```

	@within Util
	@param start number
	@param stop number
	@param alpha number
	@return number
]=]
function MathUtil.lerp(start: number, stop: number, alpha: number): number
	return start * (1 - alpha) + stop * alpha
end

--[=[
	Rounds a number to the nearest integer.

	#### Example:
	```lua
	Util.round(1.5) -- 2
	Util.round(1.4) -- 1
	```

	@within Util
	@param _number number
	@return number
]=]
function MathUtil.round(_number: number): number
	assert(typeof(_number) == "number", "Number argument must be a number")

	local decimal: number = _number % 1

	return math[decimal >= 0.5 and "ceil" or "floor"](_number)
end

--[=[
	Formats a number to have commas.

	#### Example:
	```lua
	Util.formatInt(1000) -- 1,000
	Util.formatInt(1000.01) -- 1,000.01
	```

	@within Util
	@param number number
	@param decimals number? -- The number of decimal places to round to. Defaults to 2.
	@return string
]=]
function MathUtil.formatInt(number: number, decimals: number?): string -- 1000.01 to 1,000.01
	assert(typeof(number) == "number", "Number argument must be a number")

	local numberString: string = tostring(number)

	if not numberString then
		error("Could not convert number to string")
	end

	local minus: string?, int: string?, fraction: string? = numberString:match("([-]?)(%d+)([.]?%d*)")

	if not minus or not int or not fraction then
		return ""
	end

	if #fraction > 0 then
		fraction = fraction:sub(1, (decimals or 2) + 1)
		if #fraction == 1 then
			fraction = ""
		end
	end

	int = string.gsub(int:reverse(), "(%d%d%d)", "%1,"):reverse():gsub("^,", "")

	return `{minus}{int}{fraction}`
end

--[=[
	Returns a random number between two numbers.

	#### Example:
	```lua
	Util.random(1, 10) -- 5
	Util.random(1, 10, true) -- 5.5
	Util.random(10) -- 5 (min defaults to 1)
	Util.random(10, true) -- 5.5 (min defaults to 1)
	```

	@within Util
	@param minValue number
	@param maxValue number?
	@param float boolean? -- Whether to return as a float or not. Defaults to false.
]=]
function MathUtil.random(minValue: number, maxValue: number?, float: boolean?): number
	assert(typeof(minValue) == "number", "Number1 argument must be a number")
	assert(typeof(maxValue) == "number" or maxValue == nil, "Number2 argument must be a number or nil")
	assert(typeof(float) == "boolean" or float == nil, "Float argument must be a boolean or nil")

	local min: number = not maxValue and 1 or minValue -- If maxValue is not defined, use 1 as min
	local max: number = maxValue or minValue

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
	Util.randomString() -- "aBcDeFgHiJkLmNoPqRsTuVwXyZ"
	Util.randomString(10) -- "aBcDeFgHiJ"
	```

	@within Util
	@param length number? -- The length of the string. Defaults to 18.
	@return string
]=]
function MathUtil.randomString(length: number?): string
	assert(typeof(length) == "number" or length == nil, "Length argument must be a number or nil")

	local res: string = ""

	for _ = 1, (length or 18) do
		local random: number = MathUtil.random(charsetLength)
		res = res .. charset:sub(random, random)
	end

	return res
end

--[=[
	Returns a random object from a table or instance.

	#### Example:
	```lua
	Util.randomObj({ "a", "b", "c" }) -- "b"
	Util.randomObj(Workspace.Player) -- Head
	```

	@within Util
	@param obj table | Instance
	@return any
]=]
function MathUtil.randomObj(obj: { [any]: any } | Instance): any
	assert(typeof(obj) == "table" or typeof(obj) == "Instance", "Object argument must be a table or Instance")

	if typeof(obj) == "Instance" then
		-- Convert to a table
		obj = obj:GetChildren()
	end

	if typeof(obj) == "table" then
		return obj[MathUtil.random(1, #obj)]
	end

	return
end

local shortNumberSuffixes: { string } = { "K", "M" , "B", "T", "Q" }

--[=[
	Shortens a large number to a readable format.
	Useful for displaying large numbers that don't require exact precision.
	Common use cases are for displaying XP, money in leaderboards, damage etc.

	#### Example:
	```lua
	Util.shortenNumber(1000) -- 1K
	Util.shortenNumber(1000000) -- 1M
	Util.shortenNumber(1000000000) -- 1B
	Util.shortenNumber(1000000000000) -- 1T
	Util.shortenNumber(1000000000000000) -- 1Q
	```

	minimumTiers is useful for when you want to shorten a number but only if it's above a certain tier.
	For example, if you want to shorten a number but only if it's above 1,000,000, you would do:
	```lua
	Util.shortenNumber(1000000, 2) -- 1,000,000
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
function MathUtil.shortenNumber(number: number | string, minimumTiers: number?): string
	assert(typeof(number) == "number" or typeof(number) == "string", "Number argument must be a number or string")
	assert(typeof(minimumTiers) == "number" or minimumTiers == nil, "MinimumTiers argument must be a number or nil")

	number = typeof(number) == "string" and tonumber(number) or number

	assert(typeof(number) == "number", "Number argument be a number or string that can be converted to a number")

	local negative: number = math.abs(number) == number and 1 or -1
	number = math.abs(number)

	local tier: number = math.log10(number) / 3

	if tier < (minimumTiers or 1) then -- If tier is less than minimumTiers, return the number
		return MathUtil.formatInt(number * negative, 0)
	end

	tier = math.floor(tier)

	local tierSuffix: string? = shortNumberSuffixes[tier]
		or shortNumberSuffixes[#shortNumberSuffixes] -- Get tier or use highest tier if # too high

	local _number: number? = tonumber(
		string.format("%.2f", number / 10 ^ (3 * tier))
	)

	if not _number or not tierSuffix then
		return ""
	end

	return (MathUtil.formatInt(_number, 0)) .. tierSuffix
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
function MathUtil.getVector3(object: Vector3 | CFrame | Attachment | BasePart | CFrameValue | Vector3Value | Camera): Vector3?
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
function MathUtil.getDistance(origin: any, target: any)
	local originVector3: Vector3? = MathUtil.getVector3(origin)
	local targetVector3: Vector3? = MathUtil.getVector3(target)

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
function MathUtil.getPartBottomSurface(part: BasePart): CFrame
	return part.CFrame * CFrame.new(0, -part.Size.Y / 2, 0)
end

return MathUtil
