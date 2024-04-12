local Util = require(script.Parent.Util)

type MaidClass = {
	__index: MaidClass,
	new: () -> MaidType,
	task: (self: MaidType, task: any, cleaner: () -> ()) -> string,
	removeTask: (self: MaidType, taskToRemove: MaidTask) -> (),
	clean: (self: MaidType) -> (),
	destroy: (self: MaidType) -> (),

	MaidType: MaidType,
}

type MaidInstance = {
	_tasks: { [string]: MaidTask },
	[any]: any,
}

export type MaidType = typeof(setmetatable({} :: MaidInstance, {} :: MaidClass))

type MaidTask = {
	Connected: boolean?,
	Disconnect: () -> (),
	Destroy: (any) -> (),
	destroy: (any) -> (),
	destructor: (task: any) -> (),
	[any]: any,
}? | () -> ()? | Instance

--[=[
	Task management class for cleaning up things for garbage collection.

	@class Maid
]=]
local Maid: MaidClass = {} :: MaidClass
Maid.__index = Maid

--[=[
	Creates a new Maid instance.

	```lua
	local maid = Maid.new()
	```

	@return Maid
]=]
function Maid.new(): MaidType
	local self = setmetatable({}, Maid)

	self._tasks = {}

	return self
end

--[=[
	Adds a task to the Maid instance.

	```lua
	local maid = Maid.new()

	maid:task(function()
		print("Hello world!")
	end)
	```

	Multiple types of tasks can be added to the Maid instance.

	```lua
	local maid = Maid.new()

	-- Functions
	maid:task(function()
		print("Hello world!")
	end)

	-- RBXScriptConnections
	maid:task(workspace.ChildAdded:Connect(function()
		print("Hello world!")
	end))

	-- Instances with "Destroy" methods
	maid:task(Instance.new("Part"))

	-- Packages with "Destroy", "destroy", or "destructor" methods
	local instance = Class.new({
		PackageVariable = "Hello world!",
		Destroy = function()
			-- destroy this package instance
		end
	})

	maid:task(instance)
	```

	@param _task any -- The task to add.
	@return string -- The task id.
]=]
function Maid:task(_task: MaidTask): string
	local taskId = Util.randomString(14)

	self._tasks[taskId] = _task

	return taskId
end

--[=[
	Removes a task from the Maid instance.

	```lua
	local maid = Maid.new()

	local taskId = maid:task(function()
		print("Hello world!")
	end)

	maid:removeTask(taskId)
	```

	@param taskToRemove any -- The task item to remove.
]=]
function Maid:removeTask(taskToRemove: string | MaidTask): ()
	-- Remove by task id
	if typeof(taskToRemove) == "string" then
		self._tasks[taskToRemove] = nil

		return
	end

	-- Remove by task
	for taskId, _task: MaidTask in pairs(self._tasks) do
		if _task == taskToRemove then
			self._tasks[taskId] = nil
		end
	end
end

--[=[
	Cleans up all tasks in the Maid instance.

	```lua
	local maid: typeof(Maid.MaidType) = Maid.new()

	maid:task(function()
		print("Hello world!")
	end)

	maid:clean() -- Hello world!
	```
]=]
function Maid:clean(): ()
	for taskId, _task: MaidTask in pairs(self._tasks) do
		if typeof(_task) == "function" then
			_task() -- Run cleaning _task
		elseif typeof(_task) == "RBXScriptConnection" and _task.Connected then
			_task:Disconnect()
		elseif typeof(_task) == "Instance" then
			_task:Destroy()
		elseif _task and _task.Destroy then
			-- Type workaround for non-roblox instances with Destroy methods
			local customDestroy = _task.Destroy

			customDestroy(_task)
		elseif _task and _task.destroy then
			_task:destroy()
		elseif typeof(_task) == "table" then
			if _task.destructor then
				_task.destructor(_task.task)
			end
		end

		self._tasks[taskId] = nil
	end
end

--[=[
	Destroys the Maid instance.

	```lua
	local maid = Maid.new()

	maid:task(function()
		print("Hello world!")
	end)

	maid:destroy()

	maid:clean() -- method no longer exists
	```
]=]
function Maid:destroy(): ()
	for key: any, _ in pairs(self) do
		self[key] = nil
	end
end

return Maid
