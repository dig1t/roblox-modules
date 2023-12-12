local ReplicatedStorage = game:GetService("ReplicatedStorage")

local import = require(ReplicatedStorage.Packages.dLib).import
local Util = import("dLib/Util")

local Maid = {}
Maid.__index = Maid

function Maid.hire(): { [any]: any }
	local self = setmetatable({}, Maid)
	
	self._tasks = {}
	
	return self
end

function Maid:assign(task: any, destructor: any?): string
	local taskId = Util.randomString(14)
	
	self._tasks[taskId] = destructor and {
		task = task,
		destructor = destructor
	} or task
	
	return taskId
end

function Maid:removeTask(taskToRemove: any): nil
	for taskId, task in pairs(self._tasks) do
		if task == taskToRemove then
			self._tasks[taskId] = nil
		end
	end
	
	return
end

function Maid:cleanTasks(taskIds: { [any]: any }?): nil
	local tasks = taskIds and {} or self._tasks
	
	if taskIds then
		for _, taskId in pairs(taskIds) do
			if self._tasks[taskId] then
				tasks[taskId] = self._tasks[taskId]
			end
		end
	end
	
	for taskId, _ in pairs(tasks) do
		local taskType = typeof(task)
		
		if taskType == "function" then
			task() -- Run cleaning task
		elseif taskType == "RBXScriptConnection" and task.Connected then
			task:Disconnect()
		elseif task.Destroy then
			task:Destroy()
		elseif task.destroy then
			task:destroy()
		elseif taskType == "table" then
			if task.destructor then
				task.destructor(task.task or task)
			end
		end
		
		self._tasks[taskId] = nil
	end
end

function Maid:clean(): nil
	self:cleanTasks()
	self._tasks = nil
end

return Maid