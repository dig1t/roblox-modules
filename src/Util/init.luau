--[[
-- @name dLib Utilites
-- @author dig1t
]]

--!strict

local HttpService = game:GetService("HttpService")

local Util = {}

setmetatable({}, {
	__index = Util,
	__call = function (class, ...)
		return class.instance(...)
	end
})

Util.use = function(obj: string | ModuleScript): nil
	local module: table
	
	if typeof(obj) == "string" then
		if script:FindFirstChild(obj) then
			module = require(script[obj])
		elseif script.Parent:FindFirstChild(obj) then
			module = require(script.Parent[obj])
		else
			error("Could not load module: " .. obj)
		end
	elseif typeof(obj) == "Instance" and obj.ClassName == "ModuleScript" then
		module = require(obj)
	else
		error("Could not load module: " .. obj)
	end
	
	for key, value in pairs(module) do
		Util[key] = value
	end
end

-- Import modules
Util.use("Date")
Util.use("Math")
Util.use("Players")
Util.use("Search")
Util.use("System")
Util.use("Tables")

Util.asset = "rbxassetid://" :: string
Util.defaultWalkSpeed = 16 :: number

Util.instance = function(className: string, ...): Instance
	local props: table = {}
	local extraProps: table = {...}
	
	for i = 1, #extraProps do
		if typeof(extraProps[i]) == "table" then
			for name: string, value: any in pairs(extraProps[i]) do
				props[name] = value
			end
		end
	end
	
	return function(data: table)
		local obj: Instance = Instance.new(className)
		
		if data then
			Util.extend(props, data)
			
			if props.children then
				for _, child in pairs(props.children) do
					if typeof(child) == "function" then
						child = child()
					end
					
					child.Parent = obj
				end
				
				props.children = nil
			end
			
			for prop, value in pairs(props) do
				if typeof(prop) == "number" then -- Instance?
					if typeof(value) == "function" then
						value = value()
					end
					
					value.Parent = obj
				elseif prop ~= "Parent" then -- Apply properties
					obj[prop] = value
				end
			end
			
			if props.Parent then
				obj.Parent = props.Parent -- Always set parent last
			end
		end
		
		return obj
	end
end

local valueObjects = {
	"ObjectValue", "StringValue", "IntValue", "NumberValue", "BoolValue", "CFrameValue", "Vector3Value", "Color3Value", "BrickColorValue"
}

Util.get = function(path, parent) -- expiremental
	local res = parent
	
	local chunks = Util.split(path, ".")
	
	if not chunks then
		return
	end
	
	res = res or (chunks[1] == "game" and game or game[chunks[1]])
	
	for _, child in pairs(chunks) do
		res = res[child]
	end
	
	table.remove(chunks, 1)
	
	return res ~= nil and Util.indexOf(valueObjects, res.ClassName) > 0 and res.Value or res -- success and res
end

-- Tool to set value instances
Util.set = function(
	parent: Instance, name: string, value: any, customValueType: string?
) : Instance
	return Util.try(function()
		local valueObject: Instance
		
		if not parent:FindFirstChild(name) then
			local valueType: string = customValueType or typeof(value)
			
			if valueType == "table" then
				valueType = "ObjectValue"
			elseif valueType == "string" then
				valueType = "StringValue"
			elseif valueType == "number" then
				valueType = "NumberValue"
			elseif valueType == "boolean" then
				valueType = "BoolValue"
			elseif valueType == "CFrame" then
				valueType = "CFrameValue"
			elseif valueType == "Vector3" then
				valueType = "Vector3Value"
			elseif valueType == "Color3" then
				valueType = "Color3Value"
			elseif valueType == "BrickColor" then
				valueType = "BrickColorValue"
			end
			
			valueObject = Instance.new(valueType)
			valueObject.Name = name
			valueObject.Parent = parent
		else
			valueObject = parent[name]
		end
		
		valueObject.Value = value
		
		return
	end, function(err)
		warn("Util.set - " .. err)
	end)
end

Util.printTable = function(tbl: table): nil
	print(tbl and HttpService:JSONEncode(tbl))
end

Util.numberSequence = function(data: { { number } })
	assert(data and typeof(data) == "table", "Util.numberSequence - Missing data table")
	assert(#data > 1, "Util.numberSequence - Must have at least 2 keypoints")
	
	local keypoints: table = Util.map(data, function(keypoint: { number })
		if #keypoint == 2 then
			return NumberSequenceKeypoint.new(keypoint[1], keypoint[2])
		end
	end)
	
	assert(#keypoints > 1, "Util.numberSequence - Must have at least 2 keypoints")
	
	return NumberSequence.new(keypoints)
end

-- Calls the given function until it successfully runs
-- Used for retrieving from a data store or GET/POST requests
Util.attempt = function(fn: () -> any, maxTries: number?, yield: number?): (boolean, any, number)
	local res: any
	local successful: boolean = false
	local tries: number = 0
	
	repeat
		local success: boolean, _res: any = pcall(fn)
		
		if success then
			res = _res
			successful = true
		end
		
		tries += 1
		
		if not successful then -- or tries <= (maxTries or 3) then
			task.wait(yield or 1)
		end
	until successful or tries > (maxTries or 3)
	
	return successful, res, tries
end

Util.try = function(fn: () -> any, catch: (any) -> any): any
	local success: boolean, res: any = pcall(fn)
	
	if not success then
		catch(res)
	end
	
	return res
end

-- Parts

--[[
	- @desc welds 2 parts
]]--
Util.weld = function(part: BasePart, attachTo: BasePart, offset: CFrame?): WeldConstraint
	if not part or not part.Parent or not attachTo or not attachTo.Parent then
		return
	end
	
	if offset then
		part.CFrame = attachTo.CFrame * offset
	end
	
	return Util.instance("WeldConstraint") {
		Part0 = part;
		Part1 = attachTo;
		Parent = part;
	} :: WeldConstraint
end

Util.weldModel = function(model: Model): Model
	if not model or not model:IsA("Model") or not model.PrimaryPart then
		return
	end
	
	for _, part: BasePart in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= model.PrimaryPart then
			Util.weld(part, model.PrimaryPart)
		end
	end
	
	return model
end

Util.clearWelds = function(instance: Instance): nil
	assert(typeof(instance) == "Instance", "Util.clearWelds - First argument must be an instance")
	
	for _, obj: WeldConstraint | Weld in pairs(instance:GetDescendants()) do
		if obj:IsA("WeldConstraint") or obj:IsA("Weld") then
			obj:Destroy()
		end
	end
end

-- Models

Util.getModelBounds = function(model: Model): (Vector3, Vector3)
	return model and model:IsA("Model") and model:GetBoundingBox()
end

Util.getMass = function(model: Model): number
	if not model or not model:IsA("Model") then
		return
	end
	
	local mass: number = 0
	
	for _, part: BasePart in pairs(Util.getDescendantParts(model)) do
		mass += part:GetMass()
	end
	
	return mass
end

Util.rotateModel = function(model: Model, angle: number): nil
	local rotate: CFrame = CFrame.fromEulerAnglesXYZ(0, angle, 0)
	
	for i, object: BasePart in pairs(model:GetChildren()) do
		if object:IsA("BasePart") then
			object.CFrame = rotate * object.CFrame
		end
	end
end

Util.moveModel = function(model: Model, to: CFrame): nil
	local firstPart: BasePart = Util.getFirstPart(model)
	
	if firstPart then
		local origin: Vector3 = firstPart.CFrame.Position
		
		for _, part: BasePart in pairs(model:GetDescendants()) do
			if not part:IsA("BasePart") then
				continue
			end
			
			local newPositionInWorld: Vector3 = part.Position - origin + to.Position
			local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = part.CFrame:GetComponents()
			
			part.CFrame = CFrame.new(newPositionInWorld.X, newPositionInWorld.Y, newPositionInWorld.Z, R00, R01, R02, R10, R11, R12, R20, R21, R22)
		end
	end
end

-- Events

Util.waitForChild = function(parent: Instance, name: string): Instance
	assert(parent and typeof(parent) == "Instance", "Util.waitForChild - Parent must be an instance")
	assert(name, "Util.waitForChild - Missing child name")
	
	if parent:FindFirstChild(name) then
		return parent[name]
	end
	
	while true do
		parent.ChildAdded:Wait()
		
		if parent:FindFirstChild(name) then
			return parent[name]
		end
	end
end

Util.addEventListener = function(obj: Instance, targetEvent: string, fn: () -> any): RBXScriptConnection
	return obj.Changed:Connect(function(event: string)
		if event == targetEvent then
			fn()
		end
	end)
end

local ON_TOUCH_OFFSET: number = 4

-- onTouch will increase the likelyhood that
-- players get detected when walking on a part
-- by placing a clone of the part above the part
Util.onTouch = function(part: BasePart, fn: () -> any): RBXScriptConnection
	local detector: BasePart = part:Clone()
	detector.Name = "Detector"
	detector.Transparency = 1
	detector.Size = Vector3.new(detector.Size.X, ON_TOUCH_OFFSET, detector.Size.Z)
	detector.CFrame = part.CFrame:ToWorldSpace(
		CFrame.new(0, (ON_TOUCH_OFFSET / 2) + (part.Size.Y / 2), 0)
	) -- Place on top of the current part, then offset by half of ON_TOUCH_OFFSET
	detector.CanCollide = false
	detector.Parent = part
	
	if not part.Anchored then
		Util.weld(detector, part)
	end
	
	return detector.Touched:Connect(fn)
end

Util.onPlayerTouch = function(
	obj: BasePart, fn: (Player, BasePart) -> any, ignoreIfDead: boolean?, offsetPart: Vector3?
): RBXScriptConnection
	local callback: () -> nil = function(part)
		local player: Player = Util.getPlayerFromPart(part)
		
		if player then
			local alive: boolean = Util.isAlive(player)
			
			if alive or (not alive and ignoreIfDead) then
				fn(player, part)
			end
		end
	end
	
	return offsetPart and Util.onTouch(obj, callback) or obj.Touched:Connect(callback)
end

return Util