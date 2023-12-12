--!strict

local dateUtil = {}

export type DateTimeComponents = {
	Year: number,
	Month: number,
	Day: number,
	Hour: number,
	Minute: number,
	Second: number,
	Millisecond: number
} | any

local milisecondsInSecond: number = 1000
local milisecondsInMinute: number = milisecondsInSecond * 60
local milisecondsInHour: number = milisecondsInMinute * 60
local milisecondsInDay: number = milisecondsInHour * 24
local milisecondsInYear: number = 31556952000
local milisecondsInMonth: number = 2629746000

local secondsInMinute: number = 60
local secondsInHour: number = secondsInMinute * 60
local secondsInDay: number = secondsInHour * 24
local secondsInMonth: number = 2629746
local secondsInYear: number = 31556952

--[=[
	Converts a DateTimeComponents table to a timestamp.

	@within Util
	@param components DateTimeComponents
	@return number
]=]
function dateUtil.dateTimeComponentsToTimestamp(components: DateTimeComponents): number
	assert(typeof(components) == "table", "Components must be a table")
	assert(typeof(components.Year) == "number", "Components.Year must be a number")
	assert(typeof(components.Month) == "number", "Components.Month must be a number")
	assert(typeof(components.Day) == "number", "Components.Day must be a number")
	assert(typeof(components.Hour) == "number", "Components.Hour must be a number")
	assert(typeof(components.Minute) == "number", "Components.Minute must be a number")
	assert(typeof(components.Second) == "number", "Components.Second must be a number")
	assert(typeof(components.Millisecond) == "number", "Components.Millisecond must be a number")

	local timestamp: number = 0

	timestamp += components.Year * milisecondsInYear
	timestamp += components.Month * milisecondsInMonth
	timestamp += components.Day * milisecondsInDay
	timestamp += components.Hour * milisecondsInHour
	timestamp += components.Minute * milisecondsInMinute
	timestamp += components.Second * milisecondsInSecond
	timestamp += components.Millisecond

	return timestamp / 1000
end

--[=[
	Get the current unix timestamp in UTC time.
	This is the number of **seconds** since January 1, 1970.

	@within Util
	@return number
]=]
function dateUtil.unix(): number
	local utcDateComponents: DateTimeComponents = DateTime.now():ToUniversalTime()

	return dateUtil.dateTimeComponentsToTimestamp(utcDateComponents)
end

--[=[
	Gets the time in seconds since now or the provided timestamp.

	@within Util
	@param timestamp number?
	@param endTimestamp number? -- The timestamp to compare to. Defaults to current time.
	@return number
]=]
function dateUtil.timeAgoUnix(timestamp: number, endTimestamp: number?): number
	assert(typeof(timestamp) == "number", "Timestamp must be a number")
	assert(typeof(endTimestamp) == "number" or endTimestamp == nil, "toTimestamp must be a number or nil")

	return (endTimestamp or dateUtil.unix()) - timestamp
end

--[=[
	Converts a unix timestamp to a `mm:ss` format (e.g. 00:02).
	A format and locale can be provided.

	Use the [DateTime](https://create.roblox.com/docs/reference/engine/datatypes/DateTime) API for formatting options.

	#### Example
	```lua
	local secondsLeft: number = 80

	formatUnix(secondsLeft, "mm:ss") -- 01:20
	formatUnix(secondsLeft, "HH:mm:ss") -- 00:01:20
	```

	@within Util
	@param timestamp number
	@param format string -- The format to use.
	@param locale string? -- The locale to use. Defaults to `en-us`.
	@return string -- The formatted time in local time.
]=]
function dateUtil.formatUnix(timestamp: number, format: string, locale: string?): string
	assert(typeof(timestamp) == "number", "Timestamp must be a number")
	assert(typeof(format) == "string", "format must be a string")
	assert(typeof(locale) == "string" or locale == nil, "locale must be a string or nil")

	local dateTime = DateTime.fromUnixTimestamp(math.floor(timestamp))

	return dateTime:FormatLocalTime(format, locale or "en-us")
end

--[=[
	Converts a unix timestamp to a `mm:ss` format (e.g. 00:02).

	#### Example
	```lua
	local secondsLeft: number = 80

	unixToClockFormat(secondsLeft) -- 01:20
	unixToClockFormat(secondsLeft, "HH:mm:ss") -- 00:01:20
	```

	@within Util
	@param timestamp number
	@param format string? -- The format to use. Defaults to `mm:ss`.
	@param locale string? -- The locale to use. Defaults to `en-us`.
	@return string -- The formatted time in local time.
]=]
function dateUtil.unixToClockFormat(timestamp: number, format: string?, locale: string?): string
	return dateUtil.formatUnix(timestamp, format or "mm:ss", locale)
end

--[=[
	Converts a unix timestamp to a read-able time ago format (e.g. 1 minute ago, 1 minute 20 seconds ago).

	#### Example
	```lua
	local secondsLeft: number = 80

	timeAgo(secondsLeft) -- 1 minute ago
	```

	```lua
	local secondsLeft: number = 80

	timeAgo(secondsLeft, 80 + 60) -- just now
	```

	@within Util
	@param timestamp number
	@param endTimestamp number? -- The timestamp to compare to. Defaults to current time.
	@return string
]=]
function dateUtil.timeAgo(timestamp: number, endTimestamp: number?): string
	assert(typeof(timestamp) == "number", "Timestamp must be a number")
	assert(typeof(endTimestamp) == "number" or endTimestamp == nil, "endTimestamp must be a number or nil")

	local timeAgo: number = dateUtil.timeAgoUnix(timestamp, endTimestamp)
	local result: string = ""

	local times: {{ any }} = {
		{ secondsInYear, "year" },
		{ secondsInMonth, "month" },
		{ secondsInDay, "day" },
		{ secondsInHour, "hour" },
		{ secondsInMinute, "minute" },
		{ 1, "second" }
	}

	if timeAgo < 1 then
		return "now"
	end

	local current: number = 1
	local previousUnitSeconds: number = 0

	while current <= #times do
		local _time: {} = times[current]
		local unitThreshold: number = times[current][1]
		local unit: string = times[current][2]

		if (timeAgo >= unitThreshold) and current <= #times then
			local amount = math.floor((timeAgo - previousUnitSeconds) / unitThreshold)

			previousUnitSeconds += amount * unitThreshold

			if amount > 0 then
				local plural: string = amount > 1 and "s" or ""

				result = `{result}{amount} {unit}{plural} `
			end
		end

		current += 1
	end

	return `{result}ago`
end

return dateUtil
