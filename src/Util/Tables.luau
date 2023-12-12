--!strict

local valueClasses = {
	BoolValue = true;
	BrickColorValue = true;
	CFrameValue = true;
	Color3Value = true;
	IntValue = true;
	NumberValue = true;
	ObjectValue = true;
	RayValue = true;
	StringValue = true;
	Vector3Value = true;
}

--[=[
	Used to type check a value instance.

	#### Example:
	```lua
	local value: ValueBaseType = Instance.new("BoolValue")
	```

	@type ValueBaseType ValueBase & { Value: any }
	@within Util
]=]
export type ValueBaseType = ValueBase & { Value: any }

local tableUtil = {}

--[=[
	Flips the table's keys with its values.

	#### Example:
	```lua
	flip({ a = 1, b = 2 }) -- { [1] = "a", [2] = "b" }
	flip({ a = 1, b = 2 }, true) -- { [1] = { "a" }, [2] = { "b" } }
	```

	@within Util
	@param source { [any]: any } -- The table you want to flip
	@param mergeDuplicates boolean? -- Merge key duplicates into a table instead of overwriting them
	@return { [any]: any }
]=]
function tableUtil.flip(source: { [any]: any }, mergeDuplicates: boolean?): { [any]: any }
	local res: { [any]: any } = {}
	local duplicates: { [any]: {any} } = {}

	for key: any, value: any in pairs(source) do
		if res[value] == nil then
			res[value] = key
		elseif mergeDuplicates then
			if not duplicates[value] then
				duplicates[value] = { key }
				res[value] = duplicates[value]
			else
				duplicates[value][#duplicates[value] + 1] = key
			end
		end
	end

	return res
end

-- @desc Returns a table of filtered values from the original table or instance
-- @reference https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/map
-- @return table: filtered table

--[=[
	Maps a table or instance to a new table.

	#### Example:
	```lua
	map({ 1, 2, 3 }, function(v)
		return v * 2
	end) -- { 2, 4, 6 }

	map({ 1, 2, 3 }, function(v, i)
		return i * 2
	end) -- { 2, 4, 6 }
	```

	@within Util
	@param source { [any]: any } -- The table you want to map
	@param filterFn (any, any) -> any -- The function to filter the table with
	@return { [any]: any }
]=]
function tableUtil.map(source: { [any]: any }, filterFn: (any, any) -> (any, any)): { [any]: any }
	assert(typeof(source) == "table" or typeof(source) == "Instance", "source must be a table or instance")
	assert(filterFn == nil or typeof(filterFn) == "function", "filterFn must be a function or nil")

	local res = {}

	--[[for index, value in ipairs(source) do
		res[#res + 1] = filterFn(value, index) or value
	end]]

	for key: any, value: any in pairs(
		-- If instance, convert variable to a table of it's children
		typeof(source) == "Instance" and source:GetChildren() or source
	) do -- Order not guaranteed
		local index: any = #res + 1

		if filterFn then
			local result, secondResult = filterFn(value, key)

			if secondResult ~= nil then -- Both the index and value are specified
				index = result
				value = secondResult
			else -- If there is no second result, we will use "#res + 1" as the index
				value = result -- Use the first result as the value
			end
		end

		res[index] = value
	end

	return res
end

-- Map an object by index

--[=[
	Maps a table to a new table using the index as the key.

	Includes a second argument as a function to filter the table with.

	#### Example:
	```lua
	mapIndex({ 1, 2, 3 }) -- { [1] = 1, [2] = 2, [3] = 3 }

	mapIndex({ 1, 2, 3 }, function(v)
		return v * 2
	end) -- { [1] = 2, [2] = 4, [3] = 6 }

	mapIndex({ 1, 2, 3 }, function(v, i)
		return i * 2
	end) -- { [2] = 2, [4] = 4, [6] = 6 }
	```

	@within Util
	@param source { [any]: any } -- The table you want to map
	@param filterFn (key: any, value: any) -> (value: any, key: any?) -- The function to filter the table with
	@return { [any]: any }
]=]
function tableUtil.mapIndex(source: { [any]: any }, filterFn: (any, any) -> (any, any)): { [any]: any }
	assert(typeof(source) == "table", "source must be a table")
	assert(filterFn == nil or typeof(filterFn) == "function", "filterFn must be a function or nil")

	local res = {}

	for key: any, value: any in ipairs(source) do
		local index = #res + 1

		if filterFn then
			local fnVal, fnKey = filterFn(value, key)

			if fnKey then
				index = fnKey
			end

			if fnVal ~= nil then
				value = fnVal
			end
		end

		res[index] = value
	end

	return res
end

--[=[
	Trims leading and trailing whitespace from a string.

	#### Example:
	```lua
	trimWhitespace("  Hello, world!  ") -- "Hello, world!"
	```

	@within Util
	@param text string
	@return string
]=]
function tableUtil.trimWhitespace(text: string): string
	assert(typeof(text) == "string", "text must be a string")

	return string.match(text, "^%s*(.-)%s*$") :: string
end

--[=[
	Trims leading whitespace from a string.

	#### Example:
	```lua
	trimLeadingWhitespace("  Hello, world!") -- "Hello, world!"
	```

	@within Util
	@param text string
	@return string
]=]
function tableUtil.trimLeadingWhitespace(text: string): string
	assert(typeof(text) == "string", "text must be a string")

	return string.match(text, "^%s*(.-)$") :: string
end

--[=[
	Trims trailing whitespace from a string.

	#### Example:
	```lua
	trimTrailingWhitespace("Hello, world!  ") -- "Hello, world!"
	```

	@within Util
	@param text string
	@return string
]=]
function tableUtil.trimTrailingWhitespace(text: string): string
	assert(typeof(text) == "string", "text must be a string")

	return string.match(text, "^(.-)%s*$") :: string
end

--[=[
	Splits a string into a table of strings using a delimiter.
	If `delimiter` is not provided, it defaults to a space.

	Setting `trimTrailingDelimiter` to `false` will result in an empty string at the end of the table if the text ends with the delimiter

	Setting `trim` to `false` will result in whitespace not being trimmed from each chunk

	#### Example:
	```lua
	split("Hello, world!") -- { "Hello,", "world!" }
	split("Hello, world!", ", ") -- { "Hello", "world!" }
	split("Hello, world!", ",", nil, false) -- { "Hello", " world!" } -- no whitespace is trimmed
	split("Hello, world!,", ",", false) -- { "Hello", "world!", "" } -- trailing delimiter is included

	split("path/to/file", "/") -- { "path", "to", "file" }
	split("path/to/file/", "/") -- { "path", "to", "file" } -- trailing delimiter is trimmed
	```

	@within Util
	@param text string
	@param delimiter string?
	@param trimTrailingDelimiter boolean?
	@param trim boolean? -- Trim whitespace from each chunk
	@return { string }
]=]
function tableUtil.split(text: string?, delimiter: string?, trimTrailingDelimiter: boolean?, trim: boolean?): { string }
	if not text then
		return {}
	end

	assert(typeof(text) == "string", "text must be a string")
	assert(delimiter == nil or typeof(delimiter) == "string", "delimiter must be a string or nil")
	assert(trimTrailingDelimiter == nil or typeof(trimTrailingDelimiter) == "boolean", "trimTrailingDelimiter must be a boolean or nil")
	assert(trim == nil or typeof(trim) == "boolean", "trim must be a boolean or nil")

	if trimTrailingDelimiter == nil then
		trimTrailingDelimiter = true
	end

	if trim == nil then
		trim = true
	end

	if not delimiter then
		delimiter = " " :: string
	end

	text = tostring(text)

	local chunks: { string } = {}

	if not trimTrailingDelimiter and text:sub(0, 1) == delimiter then
		chunks[1] = ""
	end

	-- Trim trailing spaces
	while string.len(text) > 0 and string.sub(text, -1, -1) == " " do
		text = text:sub(0, -2)
	end

	for match: string in string.gmatch(text, `([^{delimiter}]+)`) do
		chunks[#chunks + 1] = trim and tableUtil.trimWhitespace(match) or match
	end

	if not trimTrailingDelimiter and text:sub(-1, -1) == delimiter then
		chunks[#chunks + 1] = ""
	end

	return chunks
end

--[[
-- Todo: add nested merge
tableUtil.merge = function(to, from) -- Merges to the first given table
	assert(typeof(to) == "table", "First argument must be a table")
	assert(typeof(from) == "table", "Second argument must be a table")

	for k, v in pairs(from) do
		to[k] = v
	end
end]]

--[=[
	Joins a table of strings and numbers into a single string.

	The string is joined using a separator, which defaults to a comma.

	#### Example:
	```lua
	join({"Hello", "world!"}) -- "Hello,world!"
	join({"Hello", "world!"}, ", ") -- "Hello, world!"
	```

	@within Util
	@param stringTable { [any]: string | number } -- The table you want to join
	@param separator string? -- The separator to use when joining the table (defaults to ",")
	@return string
]=]
function tableUtil.join(stringTable: { [any]: string | number }, separator: string): string
	assert(stringTable, "Util.join - Missing object")
	assert(typeof(stringTable) == "table", "Util.join - Cannot index " .. typeof(stringTable))
	assert(typeof(separator) == "string", "Util.join - Separator must be a string or nil")

	if not separator then
		separator = ","
	end

	local res: string = ""

	for index: number, value: string | number in ipairs(stringTable) do
		local _value: string | number? = value

		if typeof(_value) == "number" then
			_value = tostring(_value) :: string
		end

		if typeof(_value) == "string" then
			res = res .. (index == #stringTable and _value or _value .. separator)
		end
	end

	return res
end

--[=[
	Extends a table with one or more tables.

	#### Example:
	```lua
	extend({ a = 1 }, { b = 2 }, { c = 3 }) -- { a = 1, b = 2, c = 3 }
	extend({ a = 1 }, { a = 2 }, { a = 3 }) -- { a = 3 }
	extend({ a = 1 }, { a = 2 }, { a = 3 }, true) -- Error: 4th argument must be a table
	```

	#### Config override example:
	```lua
	local function getDefaultConfig()
		return {
			health = 100
		}
	end

	local buffConfig = {
		health = 150,
		speed = 1.5
	}

	-- { health = 150, speed = 1.5 }
	local playerConfig = extend(getDefaultConfig(), buffConfig)
	```

	@within Util
	@param targetTable { [any]: any } -- The table you want to extend
	@param ... { [any]: any } -- The tables you want to extend the target table with
	@return { [any]: any }
]=]
function tableUtil.extend(targetTable: { [any]: any }, ...): { [any]: any }
	assert(typeof(targetTable) == "table", "targetTable must be a table")

	local args: { [any]: any } = {...}

	for argIndex: number, sourceTable in pairs(args) do
		assert(typeof(sourceTable) == "table", `Argument #{argIndex} must be a table`)

		for key, value in pairs(sourceTable) do
			targetTable[key] = value
		end
	end

	return targetTable
end

--[=[
	Gets a value from a table or Instance using a path.

	#### Example:
	```lua
	treePath({ a = { b = { c = 1 } } }, "a.b.c") -- 1
	treePath({ a = { b = { c = 1 } } }, "a.b") -- { c = 1 }
	treePath(game.Workspace, "House.Door") -- Door instance
	treePath(script, "NonexistantChild") -- nil
	```

	@within Util
	@param tree { [any]: any } | Instance -- The table or instance you want to get the value from
	@param path string -- The path to the value
	@param delimiter string? -- The delimiter to use when splitting the path
	@return any
]=]
function tableUtil.treePath(tree: { [any]: any } | Instance, path: string, delimiter: string?): any
	assert(typeof(tree) == "table" or typeof(tree) == "Instance", "Tree must be a table or instance")
	assert(typeof(path) == "string", "path must be a string")

	local node = tree
	local steps: { string } = tableUtil.split(path, delimiter or ".")
	local stepIndex: number = 1

	if #steps == 0 then
		return node -- Return the root node
	end
	
	while node ~= nil and stepIndex <= #steps do
		local childNode = steps[stepIndex]

		if typeof(node) ~= "Instance" and node[childNode] then
			node = node[childNode] :: { [any]: any }
		elseif typeof(node) == "Instance" and node:FindFirstChild(childNode) then
			node = node:FindFirstChild(childNode) :: Instance
		else
			return nil
		end

		stepIndex += 1
	end

	-- Reached last step in path, return the node
	return node
end

-- Inserts a value into a table if the test condition is true

--[=[
	Inserts a value into a table if the test condition is true.

	#### Example:
	```lua
	insertIf({ 1, 2, 3 }, 4, true) -- { 1, 2, 3, 4 }
	insertIf({ 1, 2, 3 }, 4, false) -- { 1, 2, 3 }
	insertIf({ 1, 2, 3 }, 4, function()
		return true
	end) -- { 1, 2, 3, 4 }
	```

	@within Util
	@param target { [any]: any } -- The table you want to insert the value into
	@param value any -- The value you want to insert
	@param condition boolean | () -> boolean -- The test condition
	@return nil
]=]
function tableUtil.insertIf(target: { [any]: any }, value: any, condition: () -> boolean): nil
	assert(typeof(target) == "table", "Target is missing")
	assert(typeof(value) ~= "nil", "Value is missing")
	assert(
		condition == nil or typeof(condition) == "function" or typeof(condition) == "boolean",
		"Test must be a function, boolean, or nil"
	)

	local canInsert = if typeof(condition) ~= "function" then condition else condition()

	if canInsert then
		target[#target + 1] = value
	end

	return nil
end

--[=[
	Collects all children of an instance into a table.

	#### Example:
	```lua
	instanceChildrenToTable(game.Workspace) -- { Part = Instance, Part2 = Instance }
	instanceChildrenToTable(game.ReplicatedStorage.Config) -- { Config1 = CFrameValue, Config2 = StringValue }
	```

	@within Util
	@param instance Instance -- The instance you want to collect children from
	@return { [string]: Instance }
]=]
function tableUtil.instanceChildrenToTable(instance: Instance): { [string]: Instance }
	assert(typeof(instance) == "Instance", "Instance is missing")

	local children = {}

	for _, child in pairs(instance:GetChildren()) do
		children[child.Name] = child
	end

	return children
end

--[=[
	Returns the total amount of values in a table.

	#### Example:
	```lua
	tableLength({ 1, 2, 3 }) -- 3
	tableLength({ a = 1, b = 2, c = 3 }) -- 3
	```

	@within Util
	@param source { [any]: any }
	@return number
]=]
function tableUtil.tableLength(source: { [any]: any }): number
	assert(source, "Util.tableLength - Missing object")

	local length: number = 0

	for _index, _value in pairs(source) do
		length += 1
	end

	return length
end

--[=[
	Returns a random index from a table or instance.

	#### Example:
	```lua
	tableRandomIndex({ 1, 2, 3 }) -- 2
	tableRandomIndex({ a = 1, b = 2, c = 3 }) -- "b"
	```

	@within Util
	@param obj { [any]: any } | Instance -- The table or instance you want to get a random index from
	@return any
]=]
function tableUtil.tableRandomIndex(obj: { [any]: any } | Instance): any
	assert(
		typeof(obj) == "table" or typeof(obj) == "Instance",
		"Util.tableRandomIndex - Cannot index " .. typeof(obj)
	)

	local collection: { [any]: any } = if typeof(obj) == "Instance" then obj:GetChildren() else obj

	local indexes = {}

	-- Map all children names and indexes into a table
	for index, _ in pairs(collection) do
		indexes[#indexes + 1] = index
	end

	return #indexes > 0 and indexes[Random.new():NextInteger(1, #indexes)] or nil
end

function tableUtil.indexOf(obj, value)
	assert(obj, "Util.indexOf - Missing object")
	assert(typeof(obj) == "table", "Util.indexOf - Cannot index " .. typeof(obj))

	for k, v in pairs(obj) do
		if v == value then
			return k
		end
	end

	return 0 -- No index found
end

function tableUtil.tableRandom(obj: { [any]: any } | Instance): any
	assert(obj, "Util.tableRandom - Missing object")
	assert(typeof(obj) == "table" or typeof(obj) == "Instance", "Util.tableRandomIndex - Cannot index " .. typeof(obj))

	local collection: { [any]: any } = if typeof(obj) == "Instance" then obj:GetChildren() else obj

	return collection[tableUtil.tableRandomIndex(collection)]
end

--[=[
	Creates a nested table of value instances from a Folder or Configuration instance.

	#### Example:

	- Config (Folder) -- in ReplicatedStorage
	  - Origin (CFrameValue), Value = CFrame.new(0, 1, 0)
	  - WelcomeMessage (StringValue), Value = "Hello, world!"

	```lua
	makeConfigFromValues(game.ReplicatedStorage.Config)
	```

	Result:
	```lua
	{
		Origin = CFrame.new(0, 1, 0),
		WelcomeMessage = "Hello, world!"
	}
	```

	@within Util
	@param folder Folder | Configuration -- The folder or Configuration you want to make a table from
	@return { [string]: any }
]=]
function tableUtil.makeConfigFromValues(folder: Folder | Configuration): { [string]: any }
	assert(
		typeof(folder) == "Instance" and
		(folder:IsA("Folder") or folder:IsA("Configuration")),
		"Util.makeConfigFromValues - Folder is missing"
	)

	local config: { [string]: any } = {}

	for _, child: Instance in pairs(folder:GetChildren()) do
		if child:IsA("Folder") or child:IsA("Configuration") then -- Nest
			config[child.Name] = tableUtil.makeConfigFromValues(child)
		elseif valueClasses[child.ClassName] then
			config[child.Name] = (child :: ValueBaseType).Value
		else --elseif configClasses[el.ClassName] then
			config[child.Name] = child
		end
	end

	return config
end

--[=[
	Removes a value from a table or instance.

	#### Example:
	```lua
	tableRemove({ 1, 2, 3 }, 2) -- { 1, 3 }
	tableRemove({ 1, 2, 3 }, { 2, 3 }) -- { 1 }
	tableRemove({ 1, 2, 3 }, function(value, newIndex, i)
		return value == 2
	end) -- { 1, 3 }
	```

	@within Util
	@param obj { [any]: any } | Instance -- The table or instance you want to remove the value from
	@param removeTest number | { any } | (any, number, number) -> boolean -- The value or test function to remove
	@return nil
]=]
function tableUtil.tableRemove(obj: { [any]: any }, removeTest: number | { any }): nil
	-- Convert to a test function if the test value is a number or table
	local test: (any, number, number) -> boolean

	if typeof(removeTest) == "number" then
		test = function(_value, _newIndex, i)
			return i == removeTest
		end
	elseif typeof(removeTest) == "table" then
		test = function(value, _newIndex, _i)
			for _, v in ipairs(removeTest) do
				return value == v
			end

			return false
		end
	end

	local newIndex = 1

	for i, value in ipairs(obj) do
		if not test(value, newIndex, i) then
			if i ~= newIndex then
				obj[newIndex] = obj[i] -- Move to new index
				obj[i] = nil -- Delete from old index
			end

			newIndex += 1 -- Increment index
		else
			obj[i] = nil
		end
	end

	return nil
end

return tableUtil
