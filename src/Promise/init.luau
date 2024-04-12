--[=[
	@within Promise
	@type Callback (...any) -> ()
]=]
export type Callback = (...any) -> ()

type PromiseClass = {
	__index: PromiseClass,
	statusType: {
		pending: "pending";
		fulfilled: "fulfilled";
		rejected: "rejected";
	},
	new: (fn: (resolve: Callback, reject: Callback) -> ()) -> PromiseType,
	resolve: (self: PromiseType, ...any) -> (),
	reject: (self: PromiseType, any) -> (),
	destroy: (self: PromiseType) -> (),
	andThen: (self: PromiseType, fn: Callback) -> PromiseType,
	catch: (self: PromiseType, fn: Callback) -> PromiseType,
	finally: (self: PromiseType, fn: Callback) -> PromiseType,
	_run: (self: PromiseType) -> (),

	PromiseType: PromiseType
}

type PromiseInstance = {
	_fulfillmentCallbacks: { Callback },
	_rejectionCallbacks: { Callback },
	_onFinalizedCallback: Callback?,
	_resultArgs: { [any]: any },
	_executor: PromiseExecutor,
	status: string?,
	[any]: any
}
export type PromiseType = typeof(setmetatable(
	{} :: PromiseInstance,
	{} :: PromiseClass
))

--[=[
	@within Promise
	@interface PromiseExecutor
	@field resolve Callback -- Resolves the promise
	@field reject Callback -- Rejects the promise
]=]
export type PromiseExecutor = (resolve: Callback, reject: Callback) -> nil

--[=[
	Promise class for asynchronous operations.

	```lua
	local promise: typeof(Promise.PromiseType)? -- Blank variable to allow rejection during a waterfall

	promise = Promise.new(function(resolve, reject)
		task.wait(1)
		resolve(0)
	end):andThen(function(num)
		return num + 1
	end):andThen(function(num)
		promise:reject("error")
	end):catch(function(err)
		warn(err)
	end):finally(function(num)
		print("finally", promise.status)

		if promise.status ~= "rejected" then
			print(num)
		end
	end) :: typeof(Promise.PromiseType)
	```

	@class Promise
]=]
local Promise: PromiseClass = {} :: PromiseClass
Promise.__index = Promise

--[=[
	Current status of the promise

	@within Promise
	@prop statusType table -- The status types of the promise
]=]
Promise.statusType = {
	pending = "pending"; -- The promise is waiting for a result
	fulfilled = "fulfilled"; -- The promise was fulfilled successfully
	rejected = "rejected"; -- The promise was rejected
}

--[=[
	Constructs a new Promise instance.

	```lua
	Promise.new(function(resolve, reject)
		task.wait(1)
		resolve(0)
	end)
	```

	@param executor function -- The function to call when the promise is created.
	@return Promise
]=]
function Promise.new(executor: PromiseExecutor): PromiseType
	assert(typeof(executor) == "function", "Must give a function to make a promise")

	local self = setmetatable({}, Promise)

	self._fulfillmentCallbacks = {}
	self._rejectionCallbacks = {}
	self._resultArgs = {}

	self._executor = executor
	self.status = Promise.statusType.pending

	self:_run()

	return self
end

--[=[
	Runs the Promise executor.

	```lua
	Promise:_run()
	```

	@ignore
	@return ()
]=]
function Promise:_run(): ()
	local _success, err = pcall(
		self._executor,
		function(...) -- resolve
			self:resolve(...)
		end,
		function(...) -- reject
			self:reject(...)
		end
	)

	if err and self.status == Promise.statusType.pending then
		self:reject(err)
	end

	return nil
end

--[=[
	Resolves a promise with tuple parameters.

	```lua
	Promise:resolve(...)
	```

	@param ... any -- The tuple parameters to resolve the promise with.
	@return ()
]=]
function Promise:resolve(...): ()
	if self.status ~= Promise.statusType.pending then
		warn(string.format(
			"Cannot resolve a promise %s",
			self.status == Promise.statusType.rejected and "after rejection" or "more than once"
		))

		return
	end

	self._resultArgs = {...}

	local lastRes = self._resultArgs or {} -- Start the callbacks with the initial resolution tuple

	if not self._fulfillmentCallbacks or #self._fulfillmentCallbacks == 0 then
		self.status = Promise.statusType.fulfilled

		if self._onFinalizedCallback then
			self._onFinalizedCallback(unpack(lastRes))
		end

		return
	end

	for _key, fn in ipairs(self._fulfillmentCallbacks) do
		-- Set lastRes to the returned argument from the last callback.
		lastRes = { fn(unpack(lastRes)) }

		if self.status ~= Promise.statusType.pending then
			break
		end
	end

	if self.status == Promise.statusType.pending then
		self.status = Promise.statusType.fulfilled
	end

	-- If defined, last result will be passed to the finally event.
	if self._onFinalizedCallback then
		self._onFinalizedCallback(unpack(lastRes))
	end
end

--[=[
	Rejects a promise with tuple parameters.

	```lua
	Promise:reject(errorMessage)
	```

	@param ... any -- The tuple parameters to reject the promise with.
	@return ())
]=]
function Promise:reject(...): ()
	if self.status ~= Promise.statusType.pending then
		warn(string.format(
			"Cannot reject a promise %s",
			self.status == Promise.statusType.fulfilled and "after fulfillment" or "more than once"
		))

		return
	end

	self.status = Promise.statusType.rejected
	self._resultArgs = {...}

	if self._rejectionCallbacks then
		for _key, fn in ipairs(self._rejectionCallbacks) do
			fn(...)
		end
	end

	if self._onFinalizedCallback then
		self._onFinalizedCallback(...)
	end

	return
end

--[=[
	Resolves a promise with tuple parameters.

	Called when the promise is fulfilled, if there are multiple fulfillment callbacks
	then the result of the last callback will waterfall into the next callback, if the promise rejects during the
	callback waterfall, then it will stop waterfalling.

	The first callback will begin with the arguments from the resolution callback.

	The promise can be rejected until the last fulfillment callback is called.

	```lua
	Promise:resolve(...)
	```

	@param executor function -- The function to call when the promise is fulfilled.
	@return nil
]=]
function Promise:andThen(executor: Callback): PromiseType
	assert(typeof(executor) == "function", "Must give a function to resolve")

	if self.status == Promise.statusType.fulfilled then
		executor(unpack(self._resultArgs))

		return self
	end

	self._fulfillmentCallbacks[#self._fulfillmentCallbacks + 1] = executor

	return self
end

--[=[
	Called when the Promise is rejected.


	@param callback function -- The function to call when the Promise is rejected.
	@return nil
]=]
function Promise:catch(callback: Callback): PromiseType
	assert(typeof(callback) == "function", "Must give a function to catching errors")

	if self.status == Promise.statusType.rejected then
		callback(unpack(self._resultArgs))

		return self
	end

	self._rejectionCallbacks[#self._rejectionCallbacks + 1] = callback

	return self
end

--[=[
	Similar to andThen, finally will always be called at the end of the Promise
	and can only be set once, if the Promise is rejected then the callback run with return no parameters

	```lua
	Promise:resolve(...)
	```

	@param callback function -- The function to call when the promise is fulfilled.
	@return nil
]=]
function Promise:finally(callback: Callback): PromiseType
	assert(not self._onFinalizedCallback, "Only one finally callback can be used")
	assert(typeof(callback) == "function", "Must give a function for the finally callback")

	if self.status == Promise.statusType.fulfilled or self.status == Promise.statusType.rejected then
		callback(unpack(self._resultArgs))

		return self
	end

	self._onFinalizedCallback = callback

	return self
end

--[=[
	Destroys the Promise instance.

	```lua
	Promise:destroy()
	```

	@return ()
]=]
function Promise:destroy(): ()
	for key: any, _ in pairs(self) do
		self[key] = nil
	end
end

return Promise
