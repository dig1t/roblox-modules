--[=[
	@class State

	The State class is used to manage state for anything.
	It can be used to store data for the game, UI, or any other feature.

	Usage example

	```lua
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})

	state:Listen(function(prevState, newState)
		print(prevState, newState)
	end)

	state:Set("val", 11)

	print(state:Length()) -- expect 3

	state:Set(function(prevState)
		prevState.val = 111

		return prevState
	end)

	state:Set({
		val = 1111
	})

	state.val = 11111

	state:Remove("val") -- Removes val from the state

	state:Reset()

	state:Destroy()

	local success = pcall(function()
		state:Set("val", 1)
	end)

	print("state destroyed:", not success) -- expect: state destroyed: true
	```
]=]

--!strict

local Util = require(script.Parent.Util)

local State = {}
State.__index = State

export type SubscriptionId = string

export type StateType = typeof(setmetatable(
	{} :: {
		_context: { [any]: any }?,
		_listeners: {
			[SubscriptionId]: (prevState: any, newState: any) -> nil,
		}?,
	},
	State
))

--[=[
	Creates a new state instance

	@param initialState { [any]: any }? -- Initial state values
	@return StateType
]=]
function State.new(initialState: { [any]: any }?): StateType
	if initialState ~= nil then
		assert(typeof(initialState) == "table", "Expected initialState to be a table")
	end

	local self = setmetatable(
		{
			__index = function(_self, key)
				return _self._context[key] or _self[key]
			end,
		} :: any,
		State
	) :: StateType

	self._context = initialState or {}
	self._listeners = {} :: {
		[SubscriptionId]: (prevState: any, newState: any) -> nil,
	}

	return self
end

-- Number of first level children

--[=[
	Returns the length of the state

	Example:
	```lua
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})

	print(state:Length()) -- expect 3
	```

	@within State
	@method Length
	@return number
]=]
function State.Length(self: StateType): number
	return self._context and Util.tableLength(self._context) or 0
end

--[=[
	Returns the value at the given path

	Example:
	```lua
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})

	print(state:Get("val")) -- expect 1
	print(state:Get("nest.val")) -- expect 123123

	-- True as the argument returns the entire state
	print(state:Get(true)) -- expect { val = 1, time = tick(), nest = { val = 123123 } }
	```

	@within State
	@method Get
	@param path string | number | boolean
	@return any
]=]
function State.Get(
	self: StateType,
	path: string | number | boolean
): any -- Todo: support for nested tables
	if not self._context then
		return nil
	end

	if typeof(path) == "number" then
		return self._context[path] -- Return the index, if exists
	end

	return path == true and self._context -- return the entire state
		or (typeof(path) == "string" and Util.treePath(self._context, path, "."))
		or nil
end

--[=[
	Listens for state changes

	Example:
	```lua
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})

	state:Listen(function(prevState, newState)
		print(prevState, newState)
	end)
	```

	@within State
	@method Listen
	@param callback (prevState: any, newState: any) -> nil
	@return SubscriptionId?
]=]
function State.Listen(
	self: StateType,
	callback: (prevState: any, newState: any) -> ()
): SubscriptionId?
	if not self._listeners then
		return
	end

	assert(typeof(callback) == "function", "Callback argument must be a function")

	-- Unique reference ID used for unsubscribing
	local subscriptionId: SubscriptionId = Util.randomString(8)

	self._listeners[subscriptionId] = callback

	return subscriptionId
end

--[=[
	Unlistens for state changes

	Example:
	```lua
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})

	local subscriptionId = state:Listen(function(prevState, newState)
		print(prevState, newState)
	end)

	state:Unlisten(subscriptionId)
	```

	@within State
	@method Unlisten
	@param subscriptionId SubscriptionId
]=]
function State.Unlisten(self: StateType, subscriptionId: SubscriptionId)
	if not self._listeners then
		return
	end

	assert(self._listeners[subscriptionId], "State listener does not exist")

	self._listeners[subscriptionId] = nil
end

--[=[
	Fires to all listeners with the new state

	@private
]=]
function State._pushUpdates(self: StateType, prevState: any, newState: any)
	if not self._context or not self._listeners then
		return
	end

	local _newState = newState or self._context

	for _, callback in pairs(self._listeners) do
		pcall(callback, prevState, _newState)
	end
end

--[=[
	Pushes a new value to the state

	Example:
	```lua
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})

	state:Push("val", 2)

	print(state:Get("val")) -- expect 2
	```

	@within State
	@method Push
	@param keyOrValue any -- The key of the pushed value or the value itself if the state is an array
	@param value any? -- The value to push
	@return any -- The key of the pushed value
]=]
function State.Push(self: StateType, keyOrValue: any, value: any?): any
	if not self._context then
		return
	end

	local prevState = Util.extend({}, self._context) -- Create a 1 level copy -- TODO: change to deep copy
	local key: any = value ~= nil and keyOrValue or #self._context + 1

	self._context[key] = value ~= nil and value or keyOrValue

	self:_pushUpdates(prevState)

	return key
end

--[=[
	Resets the state to an empty table

	Example:
	```lua
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})

	state:Reset()

	state:Get(true) -- expect {}
	```

	@within State
	@method Reset
]=]
function State.Reset(self: StateType)
	self:_pushUpdates(self._context, {})

	self._context = {}
end

--[=[
	Sets the state with a new value

	Example:
	```lua
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})

	state:Set("val", 11) -- Change val to 11

	state:Set(function(prevState)
		prevState.val = 111

		return prevState
	end) -- Change val to 111

	state:Set({
		val = 1111
	}) -- Change val to 1111

	state:Set("nest.val", 11111) -- Change nest.val to 11111

	state:Set("undefinedNest.val", 11111) -- Create undefinedNest and set val to 11111
	```

	@within State
	@method Set
	@param newState any -- The new state value
	@param value any? -- The value to set
]=]
function State.Set(self: StateType, newState: any, value: any)
	if not self._context then
		return
	end

	local prevState = Util.extend({}, self._context) -- Create a local copy -- TODO: change to deep copy

	if typeof(newState) == "function" then
		-- Replace entire state with the result of newState()
		-- If newState() returns nil, the state will not be changed -- TODO: change to nil instead of doing nothing?
		-- If the required value is nil, use State:Reset()

		self._context = newState(self._context) or self._context
	elseif typeof(newState) == "table" then
		-- Replace specific state keys with given values

		for k: any, v: any in pairs(newState) do
			self._context[k] = v
		end
	elseif typeof(newState) == "string" then
		-- Set specified state path with given value
		-- This requires the second argument to be a
		-- value, unless the path is being set to nil

		local path: { string } = Util.split(newState, ".", true)
		local res = self._context

		if not res then
			return
		end

		-- Go through nest until the last nest level is reached
		for i: number, childName: string in path do
			local numberIndex: number? = tonumber(childName)
			local resIndex: number | string = numberIndex or childName

			if res[resIndex] and i ~= #path then
				res = res[resIndex]
			elseif i == #path then
				-- Change the value if end of the path was reached
				res[resIndex] = value
			else
				break
			end
		end
	else
		warn("No valid state setter was given")
		return
	end

	self:_pushUpdates(prevState)
end

--[=[
	Removes a value from the state

	Example:
	```lua
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})

	state:Remove("val") -- Removes val from the state

	state:Get(true) -- expect { time = tick(), nest = { val = 123123 } }
	```

	@within State
	@method Remove
	@param path string | number -- The path to the value to remove
]=]
function State.Remove(self: StateType, path: string | number)
	local prevState = Util.extend({}, self._context or {}) -- Create a local copy
	local treePath = Util.split(tostring(path), ".", true)
	local res = self._context

	if not res then
		return
	end

	-- Dig through nest until the last nest level is reached
	for i: number, childName: string in treePath do
		local numberIndex: number? = tonumber(childName)
		local resIndex: number | string = numberIndex or childName

		if res[resIndex] and i ~= #treePath then
			res = res[resIndex]
		elseif i == #treePath then
			-- Remove the value if end of the path was reached
			res[resIndex] = nil
		else
			break
		end
	end

	self:_pushUpdates(prevState)
end

--[=[
	Destroys the state

	Example:
	```lua
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})

	state:Destroy()

	local success = pcall(function()
		state:Set("val", 1)
	end)

	print('state destroyed?', not success) -- expect: true
	```

	@within State
	@method Destroy
]=]
function State.Destroy(self: StateType)
	self._context = nil
	self._listeners = nil

	pcall(setmetatable, self, {})
end

return State
