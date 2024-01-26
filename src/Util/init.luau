--!strict

local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Import util modules
local DateUtil = require(script.DateUtil)
local MathUtil = require(script.MathUtil)
local PlayerUtil = require(script.PlayerUtil)
local SearchUtil = require(script.SearchUtil)
local SystemUtil = require(script.SystemUtil)
local TableUtil = require(script.TableUtil)

local _cache: { [string]: any } = {}

--- @class Util
local Util = {}

setmetatable({}, {
	__index = Util,
	__call = function (class, ...)
		return class.instance(...)
	end
})

-- Add util modules
TableUtil.extend(
	Util,
	DateUtil,
	MathUtil,
	PlayerUtil,
	SearchUtil,
	SystemUtil,
	TableUtil
)

function Util.use(moduleName: string | ModuleScript)
	local module: { [any]: any }

	if typeof(moduleName) == "string" then
		if script:FindFirstChild(moduleName) then
			module = require(script[moduleName]) :: { [any]: any }
		elseif script.Parent:FindFirstChild(moduleName) then
			module = require(script.Parent[moduleName]) :: { [any]: any }
		else
			error("Could not load module: " .. moduleName)
		end
	elseif typeof(moduleName) == "Instance" and moduleName.ClassName == "ModuleScript" then
		module = require(moduleName) :: { [any]: any }
	else
		error("Could not load module: " .. moduleName.Name)
	end

	for key, value in pairs(module) do
		if Util[key] == nil then
			Util[key] = value
		end
	end
end

Util.asset = "rbxassetid://" :: string
Util.defaultWalkSpeed = 16 :: number

function Util.instance(className: string, ...): (any) -> Instance
	local props: { [any]: any } = {}
	local extraProps: { [any]: any } = {...}

	for i = 1, #extraProps do
		if typeof(extraProps[i]) == "table" then
			for name: string, value: any in pairs(extraProps[i]) do
				props[name] = value
			end
		end
	end

	return function(data: { [any]: any }): Instance
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
					local _obj: any = obj -- Type hack

					_obj[prop] = value
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

local valueObjectClassNames: { [string]: string } = {
	["table"] = "ObjectValue";
	["string"] = "StringValue";
	["number"] = "NumberValue";
	["boolean"] = "BoolValue";
	["CFrame"] = "CFrameValue";
	["Vector3"] = "Vector3Value";
	["Color3"] = "Color3Value";
	["BrickColor"] = "BrickColorValue";
}

--[=[
	This is a custom type to represent and typecheck value instances.

	Roblox has a built-in [ValueBase](https://create.roblox.com/docs/reference/engine/classes/ValueBase) type, but it does not have a `Value` property.

	#### Example:
	```lua
	local value: ValueBaseType = Instance.new("BoolValue")
	```

	@type ValueBaseType ValueBase & { Value: any }
	@within Util
]=]
export type ValueBaseType = ValueBase & { Value: any }

function Util.get(path, parent) -- expiremental
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
function Util.set(
	parent: Instance, name: string, value: any, customValueType: string?
): ValueBaseType?
	return Util.try(function()
		local valueObject: ValueBaseType | Instance? = nil

		if not parent:FindFirstChild(name) then
			local valueType: string = customValueType or valueObjectClassNames[typeof(value)]

			assert(table.find(valueObjects, valueType), "Util.set - Invalid value type: " .. valueType)

			local newObject = Instance.new(valueType) :: ValueBaseType
			valueObject = newObject

			newObject.Name = name
			newObject.Parent = parent
		else
			local _parent: any = parent -- Type hack
			valueObject = _parent[name] :: ValueBaseType
		end

		if valueObject then
			local _valueObject: any = valueObject -- Type hack
			_valueObject.Value = value
		end

		return
	end, function(err)
		warn("Util.set - " .. err)
		return nil
	end)
end

--[=[
	Prints a JSON string to the console using HttpService.

	Example:
	```lua
	Util.printTable({
		foo = "bar";
		bar = "foo";
	}) -- {"foo":"bar","bar":"foo"}
	```

	@within Util
	@param source { [any]: any }
	@return nil
]=]
function Util.printTable(source: { [any]: any }): nil
	assert(source and typeof(source) == "table", "Util.printTable - Missing source table")

	print(source and HttpService:JSONEncode(source))

	return nil
end

--[=[
	Create a new NumberSequence from a table of keypoints.

	Example:
	```lua
	local gradient: ColorSequence = Util.colorSequence({
		{ 0, Color3.fromRGB(255, 0, 0) };
		{ 1, Color3.fromRGB(0, 255, 0) };
	})

	local particle: ParticleEmitter = Instance.new("ParticleEmitter")
	particle.Color = gradient
	```

	@within Util
	@param data { any }
	@return nil
]=]
function Util.numberSequence(data: { { number } }): NumberSequence
	assert(data and typeof(data) == "table", "Util.numberSequence - Missing data table")
	assert(#data > 1, "Util.numberSequence - Must have at least 2 keypoints")

	local keypoints: { [any]: any } = Util.map(data, function(keypoint: { number }): NumberSequenceKeypoint?
		if #keypoint == 2 then
			return NumberSequenceKeypoint.new(keypoint[1], keypoint[2])
		end

		return nil
	end)

	assert(#keypoints > 1, "Util.numberSequence - Must have at least 2 keypoints")

	return NumberSequence.new(keypoints)
end

--[=[
	Retrieves product info with the Roblox marketplace API.

	@within Util
	@param productId number
	@param infoType Enum.InfoType?
	@return { [any]: any }?
]=]
function Util.getProductInfo(productId: number, infoType: Enum.InfoType?): { [any]: any }?
	if infoType == nil then
		infoType = Enum.InfoType.Asset -- Roblox default
	end

	assert(typeof(productId) == "number", "Util.getProductInfo - Missing productId argument")
	assert(typeof(infoType) == "EnumItem", "Util.getProductInfo - Invalid infoType argument")

	local cacheIndex: string = `{infoType.Name}-{productId}`

	if _cache[cacheIndex] then
		return _cache[cacheIndex]
	end

	local success: boolean, result: any = Util.attempt(function()
		local productInfo: { [any]: any } = MarketplaceService:GetProductInfo(productId, infoType)
		_cache[cacheIndex] = productInfo

		return productInfo
	end)

	return success and result or nil
end

--[=[
	Returns an asset URI.

	Example:
	```lua
	Util.getAssetId("rbxassetid://1234567890") -- rbxassetid://1234567890
	Util.getAssetId(1234567890) -- rbxassetid://1234567890
	```

	@within Util
	@param assetId number | string
	@return string?
]=]
function Util.getAssetURI(assetId: number | string): string?
	assert(typeof(assetId) == "number" or typeof(assetId) == "string", "Util.getAssetId - assetId must be a number or string")

	return (typeof(assetId) == "number" and `rbxassetid://{assetId}`)
		or (typeof(assetId) == "string" and assetId) or nil
end

--[=[
	Calls the given function until it successfully runs.
	Useful for retrieving from a data store or GET/POST requests.

	It will return a tuple of (success: boolean, result: any, tries: number).

	Example:
	```lua
	local success: boolean, result: any, tries: number = Util.attempt(function()
		return game:GetService("HttpService"):GetAsync("https://example.com")
	end)

	print(success, result)
	print(`It took {tries} tries to retrieve the data`)
	```

	@within Util
	@param runner () -> any
	@param maxTries number? -- Defaults to 3
	@param yield number?
	@return (boolean, any, number)
]=]
function Util.attempt(runner: () -> any, maxTries: number?, yield: number?): (boolean, any, number)
	assert(typeof(runner) == "function", "Util.attempt - runner must be a function")
	assert(maxTries == nil or typeof(maxTries) == "number", "Util.attempt - maxTries must be a number or nil")
	assert(yield == nil or typeof(yield) == "number", "Util.attempt - yield must be a number or nil")

	local res: any
	local successful: boolean = false
	local tries: number = 0

	repeat
		local success: boolean, _res: any = pcall(runner)

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

--[=[
	Simple try catch function.

	Example:
	```lua
	local result: any = Util.try(function()
		return "Hello world!"
	end, function(err)
		warn("Error: " .. err)
	end)

	print(result) -- "Hello world!"
	```

	Example:
	```lua
	local result: any = Util.try(function()
		error("Something went wrong")
	end, function(err)
		warn("Error: " .. err)
	end)

	print(result) -- nil
	```

	@within Util
	@param runner () -> any
	@param catch (any) -> any
	@return any
]=]
function Util.try(runner: () -> any, catch: (any) -> any): any
	assert(typeof(runner) == "function", "Util.try - runner argument must be a function")
	assert(typeof(catch) == "function", "Util.try - catch argument must be a function")

	local success: boolean, res: any = pcall(runner)

	if not success then
		catch(res)
	end

	return res
end

-- Parts

--[=[
	Welds 2 parts together.

	Example:
	```lua
	local weld: WeldConstraint = Util.weld(game.Workspace.Car.Wheel, game.Workspace.Car)
	```

	@within Util
	@param part BasePart
	@param attachTo BasePart
	@param offset CFrame?
	@return WeldConstraint
]=]
function Util.weld(part: BasePart, attachTo: BasePart, offset: CFrame?): WeldConstraint
	assert(typeof(part) == "Instance", "Util.weld - First argument must be an instance")
	assert(typeof(attachTo) == "Instance", "Util.weld - Second argument must be an instance")
	assert(part:IsA("BasePart"), "Util.weld - First argument must be a base part")
	assert(attachTo:IsA("BasePart"), "Util.weld - Second argument must be a base part")
	assert(part ~= attachTo, "Util.weld - Cannot weld part to itself")
	assert(offset == nil or typeof(offset) == "CFrame", "Util.weld - Third argument must be a CFrame or nil")

	if offset then
		part.CFrame = attachTo.CFrame * offset
	end

	return Util.instance("WeldConstraint") {
		Part0 = part;
		Part1 = attachTo;
		Parent = part;
	} :: WeldConstraint
end

--[=[
	Welds all parts in a model to the PrimaryPart if it is set.

	Example:
	```lua
	Util.weldModel(game.Workspace.Car)
	```

	@within Util
	@param model Model
	@return nil
]=]
function Util.weldModel(model: Model): Model?
	assert(typeof(model) == "Instance", "Util.weldModel - First argument must be an instance")

	if not model.PrimaryPart then
		return
	end

	for _, part: BasePart | Instance in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= model.PrimaryPart then
			Util.weld(part, model.PrimaryPart)
		end
	end

	return model
end

--[=[
	Clears all welds from an instance.

	Example:
	```lua
	Util.clearWelds(game.Workspace.House)
	```

	@within Util
	@param instance Instance
	@return nil
]=]
function Util.clearWelds(instance: Instance): nil
	assert(typeof(instance) == "Instance", "Util.clearWelds - First argument must be an instance")

	for _, obj: WeldConstraint | Weld | Instance in pairs(instance:GetDescendants()) do
		if obj:IsA("WeldConstraint") or obj:IsA("Weld") then
			obj:Destroy()
		end
	end

	return nil
end

--[=[
	Clears all joints from an instance.

	Example:
	```lua
	Util.breakJoints(game.Workspace.House)
	```

	@within Util
	@param instance Instance
	@return nil
]=]
function Util.breakJoints(instance: Instance): nil
	assert(typeof(instance) == "Instance", "Util.breakJoints - instance argument must be an instance")

	for _, child: Instance in pairs(instance:GetDescendants()) do
		if child:IsA("WeldConstraint") or child:IsA("Weld") or child:IsA("Motor6D") then
			child:Destroy()
		end
	end

	return nil
end

-- Models

--[=[
	Gets the mass of a model.

	@within Util
	@param model Model
	@return number
]=]
function Util.getMass(model: Model): number?
	assert(typeof(model) == "Instance", "Util.getMass - First argument must be an instance")
	assert(model:IsA("Model"), "Util.getMass - First argument must be a model")

	local mass: number = 0

	for _, part: BasePart in pairs(Util.getDescendantParts(model)) do
		mass += part:GetMass()
	end

	return mass
end

function Util.rotateModel(model: Model, angle: number): nil
	local rotate: CFrame = CFrame.fromEulerAnglesXYZ(0, angle, 0)

	for _, object: BasePart | Instance in pairs(model:GetChildren()) do
		if object:IsA("BasePart") then
			object.CFrame = rotate * object.CFrame
		end
	end

	return nil
end

function Util.moveModel(model: Model, to: CFrame): nil
	local firstPart: BasePart = Util.getFirstPart(model)

	if firstPart then
		local origin: Vector3 = firstPart.CFrame.Position

		for _, part: BasePart | Instance in pairs(model:GetDescendants()) do
			if not part:IsA("BasePart") then
				continue
			end

			local newPositionInWorld: Vector3 = part.Position - origin + to.Position
			local _x, _y, _z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = part.CFrame:GetComponents()

			part.CFrame = CFrame.new(
				newPositionInWorld.X, newPositionInWorld.Y, newPositionInWorld.Z,
				R00, R01, R02, R10, R11, R12, R20, R21, R22
			)
		end
	end

	return nil
end

-- Events

function Util.waitForChild(parent: Instance, name: string): Instance?
	assert(parent and typeof(parent) == "Instance", "Util.waitForChild - Parent must be an instance")
	assert(name, "Util.waitForChild - Missing child name")

	local current: Instance? = parent:FindFirstChild(name)

	if current then
		return current
	end

	while true do
		parent.ChildAdded:Wait()
		current = parent:FindFirstChild(name)

		if current then
			return current
		end
	end
end

--[=[
	Expiremental

	Listens to a property or attribute on an instance and runs a callback when it changes.
	It will return a connection that can be disconnected.

	Using addListener() is an addition to Roblox's built-in GetPropertyChangedSignal() and GetAttributeChangedSignal().

	The callback will be called with the previous value and the new value.

	Example:
	```lua
	local connection = Util.addListener(
		game.Workspace.NPC,
		"Health",
		"Attribute",
		function(oldValue, newValue)
			print("Health changed from " .. oldValue .. " to " .. newValue)
		end
	)
	```

	@within Util
	@param instance Instance
	@param listenerType string -- "Property" | "Attribute"
	@param listenTo string -- The property or attribute to listen to
	@param callback (any, any) -> any -- The callback to run when the property or attribute changes
	@return RBXScriptConnection
]=]
function Util.addListener(
	instance: Instance,
	listenerType: string,
	listenTo: string,
	callback: (oldValue: any, newValue: any) -> any
): RBXScriptConnection
	assert(instance and typeof(instance) == "Instance", "Util.addListener - First argument must be an instance")
	assert(
		listenerType == "Property" or listenerType == "Attribute",
		"Util.addListener - Invalid listener type, must be 'Property' or 'Attribute'"
	)
	assert(listenTo, "Util.addListener - Missing listenTo argument")
	assert(callback and typeof(callback) == "function", "Util.addListener - Missing callback")

	local obj: any = instance -- Type hack
	local oldValue: any = obj[listenTo]

	local signalGetter: string = listenerType == "Property" and "GetPropertyChangedSignal" or "GetAttributeChangedSignal"

	return obj[signalGetter](obj, listenTo):Connect(function()
		local newValue: any = obj[listenTo]
		local _oldValue: any = oldValue

		oldValue = newValue
		callback(_oldValue, newValue)
	end)
end

--[=[
	Shortcut for Util.addListener

	Example:
	```lua
	local connection = Util.addPropertyListener(game.Workspace.NPC, "Name", function(oldValue, newValue)
			print("Name changed from " .. oldValue .. " to " .. newValue)
		end
	)
	```

	@within Util
	@param instance Instance
	@param listenTo string
	@param callback (any, any) -> any
	@return RBXScriptConnection
]=]
function Util.addPropertyListener(
	instance: Instance,
	listenTo: string,
	callback: (oldValue: any, newValue: any) -> any
): RBXScriptConnection
	assert(instance and typeof(instance) == "Instance", "Util.addPropertyListener - First argument must be an instance")
	assert(listenTo, "Util.addPropertyListener - Missing listenTo argument")
	assert(callback and typeof(callback) == "function", "Util.addPropertyListener - Missing callback")

	return Util.addListener(instance, "Property", listenTo, callback)
end

--[=[
	Shortcut for Util.addListener

	Example:
	```lua
	local connection = Util.addAttributeListener(game.Workspace.NPC, "Health", function(oldValue, newValue)
			print("Health changed from " .. oldValue .. " to " .. newValue)
		end
	)
	```

	@within Util
	@param instance Instance
	@param listenTo string
	@param callback (any, any) -> any
	@return RBXScriptConnection
]=]
function Util.addAttributeListener(
	instance: Instance,
	listenTo: string,
	callback: (oldValue: any, newValue: any) -> any
): RBXScriptConnection
	assert(instance and typeof(instance) == "Instance", "Util.addAttributeListener - First argument must be an instance")
	assert(listenTo, "Util.addAttributeListener - Missing listenTo argument")
	assert(callback and typeof(callback) == "function", "Util.addAttributeListener - Missing callback")

	return Util.addListener(instance, "Attribute", listenTo, callback)
end

local ON_TOUCH_OFFSET: number = 4

-- onTouch will increase the likelyhood that
-- players get detected when walking on a part
-- by placing a clone of the part above the part
function Util.onTouch(part: BasePart, fn: (any) -> any): RBXScriptConnection
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

function Util.onPlayerTouch(
	obj: BasePart,
	fn: (Player, BasePart) -> any,
	ignoreIfDead: boolean?,
	offsetPart: boolean?
): RBXScriptConnection
	local callback: (part: BasePart) -> nil = function(part: BasePart): nil
		local player: Player = Util.getPlayerFromPart(part)

		if player then
			local alive: boolean = Util.isAlive(player)

			if alive or (not alive and ignoreIfDead) then
				fn(player, part)
			end
		end

		return nil
	end

	return offsetPart and Util.onTouch(obj, callback) or obj.Touched:Connect(callback)
end

return Util
