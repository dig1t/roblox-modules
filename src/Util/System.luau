--!strict

local RunService = game:GetService("RunService")

local sys = {}

sys.print = function(str): nil
	print(str)
end

sys.error = function(err): nil
	error("Error: " .. err, 0)
end

sys.warn = function(str): nil
	error("Error: " .. str, 0)
end

sys.yield = function(yieldTime): nil
	yieldTime = yieldTime or .0001
	
	if yieldTime <= 0 then
		return
	end
	
	local start = os.clock()
	
	repeat
		RunService.Stepped:Wait()
	until os.clock() - start >= yieldTime
end

sys.timeout = function(yieldTime, fn): nil
	task.spawn(function()
		task.wait(yieldTime)
		fn()
	end)
end

sys.interval = function(yieldTime, fn): nil
	local mt = {}
	mt.__index = mt
	
	function mt:disconnect()
		self.connected = false
	end
	
	local self = setmetatable({}, mt)
	
	self.connected = true
	self.start = os.clock()
	self.elapsed = 0
	
	while self.connected do
		local success = fn(self.elapsed)
		
		if success == false then
			self:disconnect()
		else
			task.wait(yieldTime)
			self.elapsed = os.clock() - self.start
		end
	end
	
	return self
end

sys.inTable = function(obj, e): boolean
	if not obj then
		return false
	end
	
	if typeof(e) == "table" then
		local i = 0
		
		for k, v in pairs(e) do
			i += 1
			
			if k ~= i then
				if not obj[k] then
					return false
				end
			else
				if not obj[v] then
					return false
				end
			end
		end
		
		return true
	else
		for _, v in pairs(obj) do
			if v == e then
				return true
			end
		end
		
		return false
	end
end

return sys