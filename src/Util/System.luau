--!strict

local RunService = game:GetService("RunService")

local sys = {}

--[=[
	Runs a function after `yieldTime` seconds.

	#### Example:
	```lua
	sys.timeout(1, function()
		print("Hello, world!")
	end)
	```

	@within Util
	@param yieldTime number
	@param fn function
	@return nil
]=]
function sys.timeout(yieldTime, fn)
	task.spawn(function()
		local start = os.clock()
		local connection: RBXScriptConnection

		connection = RunService.Stepped:Connect(function()
			if os.clock() - start >= yieldTime then
				connection:Disconnect()
				fn()
			end
		end)
	end)
end

--[=[
	Runs a function every `interval` in seconds.
	Return `false` within the callback to stop the interval or call `:disconnect()` on the returned object.

	#### Example:
	```lua
	sys.interval(1, function(elapsed)
		print(elapsed)
	end)
	```

	@within Util
	@param interval number
	@param callback function
	@return table
]=]
function sys.interval(interval: number, callback: (any) -> (boolean?)): any
	local elapsed: number = 0
	local lastEventAt: number = os.clock()

	local connection: RBXScriptConnection

	connection = RunService.Stepped:Connect(function(deltaTime: number)
		elapsed += deltaTime

		if os.clock() - lastEventAt >= interval then
			lastEventAt = os.clock()

			task.spawn(function()
				local success = callback(elapsed)

				if success == false then
					connection:Disconnect()
				end
			end)
		end
	end)

	return connection
end

--[=[
	Checks if a value is in a table.

	#### Example:
	```lua
	inTable({ 1, 2, 3 }, 2) -- true
	inTable({ 1, 2, 3 }, 4) -- false
	inTable({ Part, 2, 3, Part2 = true }, Part) -- true
	```

	@within Util
	@param searchTable { [any]: any }
	@param target any
	@return boolean
]=]
function sys.inTable(searchTable: { [any]: any }, target: any): boolean
	assert(typeof(searchTable) == "table", "searchTable must be a table")

	for _, value: any in pairs(searchTable) do
		if value == target then
			return true
		end
	end

	return false
end

return sys
