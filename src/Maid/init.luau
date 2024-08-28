local Util = require(script.Parent.Util)

--[=[
	Task management class for cleaning up things for garbage collection.

	@class Maid
]=]
local Maid = {}
Maid.__index = Maid

export type MaidType = typeof(setmetatable(
	{} :: {
		_tasks: { [string]: MaidTask },
	},
	Maid
))

export type MaidTask = {
	Connected: boolean?,
	Disconnect: () -> (),
	Destroy: (any) -> (),
	Destructor: (task: any) -> (),
}? | () -> ()? | Instance

--[=[
	Creates a new Maid instance.

	```lua
	local maid = Maid.new()
	```

	@return MaidType
]=]
function Maid.new(): MaidType
	local self = setmetatable({}, Maid) :: MaidType

	self._tasks = {}

	return self
end

--[=[
	Adds a task to the Maid instance.

	```lua
	local maid = Maid.new()

	maid:Task(function()
		print("Hello world!")
	end)
	```

	Multiple types of tasks can be added to the Maid instance.

	```lua
	local maid: Maid.MaidType = Maid.new()

	-- Functions
	maid:Task(function()
		print("Hello world!")
	end)

	-- RBXScriptConnections
	maid:Task(workspace.ChildAdded:Connect(function()
		print("Hello world!")
	end))

	-- Instances with "Destroy" methods
	maid:Task(Instance.new("Part"))

	-- Packages with "Destroy", "destroy", or "destructor" methods
	local instance = Class.new({
		PackageVariable = "Hello world!",
		Destroy = function()
			-- destroy this package instance
		end
	})

	maid:Task(instance)
	```

	@within Maid
	@method Task
	@param _task MaidTask -- The task to add
	@return (MaidTask, string) -- The task and the task id are returned
]=]
function Maid.Task(self: MaidType, _task: MaidTask): (MaidTask, string)
	local taskId = Util.randomString(14)

	self._tasks[taskId] = _task

	return _task, taskId
end

--[=[
	Alias for Maid.Task

	@within Maid
	@method Add
	@param _task MaidTask -- The task to add
	@return (MaidTask, string) -- The task and the task id are returned
]=]
function Maid.Add(self: MaidType, _task: MaidTask): (MaidTask, string)
	return self:Task(_task)
end

--[=[
	Removes a task from the Maid instance.

	```lua
	local maid: Maid.MaidType = Maid.new()

	local taskId = maid:Task(function()
		print("Hello world!")
	end)

	maid:RemoveTask(taskId)
	```

	@within Maid
	@method RemoveTask
	@param taskToRemove any -- The task item to remove.
]=]
function Maid.RemoveTask(self: MaidType, taskToRemove: string | MaidTask): ()
	-- Remove by task id
	if typeof(taskToRemove) == "string" then
		self._tasks[taskToRemove] = nil

		return
	end

	-- Remove by task
	for taskId: string, _task: MaidTask in pairs(self._tasks) do
		if _task == taskToRemove then
			self._tasks[taskId] = nil
		end
	end
end

--[=[
	Cleans up all tasks in the Maid instance.

	```lua
	local maid: Maid.MaidType = Maid.new()

	maid:Task(function()
		print("Hello world!")
	end)

	maid:Clean() -- Hello world!
	```

	@within Maid
	@method Clean
]=]
function Maid.Clean(self: MaidType)
	for taskId, _task: MaidTask in pairs(self._tasks) do
		if typeof(_task) == "function" then
			_task() -- Run cleaning _task
		elseif typeof(_task) == "RBXScriptConnection" and _task.Connected then
			_task:Disconnect()
		elseif typeof(_task) == "Instance" then
			_task:Destroy()
		elseif typeof(_task) == "table" then
			-- Type workaround for non-roblox instances with Destroy methods
			if _task.Destroy then
				_task:Destroy()
			elseif _task.Destructor then
				_task:Destructor()
			end
		end

		self._tasks[taskId] = nil
	end
end

--[=[
	Alias for Maid.Clean

	@within Maid
	@method Cleanup
]=]
function Maid.Cleanup(self: MaidType)
	self:Clean()
end

--[=[
	Destroys the Maid instance.

	```lua
	local maid = Maid.new()

	maid:Task(function()
		print("Hello world!")
	end)

	maid:Destroy()

	maid:Clean() -- method no longer exists
	```

	@within Maid
	@method Destroy
]=]
function Maid.Destroy(self: MaidType)
	for key: any, _ in pairs(self) do
		self[key] = nil
	end
end

return Maid
