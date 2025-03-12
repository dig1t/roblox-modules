local CollectionService = game:GetService("CollectionService")

local Maid = require(script.Parent.Maid)
local Signal = require(script.Parent.Signal)

--[=[
	@class CollectionObject

	CollectionObject is a wrapper for CollectionService instances found using CollectionWatcher.

	It provides a `Destroyed` signal that fires when the object is removed from the game as an
	alternative to using `CollectionService:GetInstanceRemovedSignal()`.

	Example usage:
	```lua
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local CollectionWatcher = require(ReplicatedStorage.Shared.Class.CollectionWatcher)
	local Util = require(ReplicatedStorage.Packages.Util)

	local killPart: CollectionWatcher.CollectionWatcher<BasePart> =
		CollectionWatcher.new("KILL_PART")

	-- Add a handler for kill parts
	killPart:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
		object.context.Touched:Connect(function(part: BasePart)
			local humanoid: Humanoid? = part.Parent:FindFirstChildOfClass("Humanoid")
				or part.Parent.Parent:FindFirstChildOfClass("Humanoid")

			if humanoid then
				humanoid.Health = 0
			end
		end)

		object.Destroyed:Connect(function()
			-- Play sparkle VFX where the object used to be
		end)
	end)
	```
]=]
local CollectionObject = {}
CollectionObject.__index = CollectionObject

export type CollectionObject<T> = typeof(setmetatable(
	{} :: {
		context: T,

		Destroyed: Signal.Signal<nil>,
	},
	CollectionObject
))

local function newCollectionObject<T>(instance: T): CollectionObject<T>
	return setmetatable({
		context = instance,

		Destroyed = Signal.new(),
	}, CollectionObject) :: CollectionObject<T>
end

--- @private
function CollectionObject._destroy<T>(self: CollectionObject<T>)
	self.Destroyed:Fire()
end

--[=[
	@class CollectionWatcher

	Usage:
	```lua
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local CollectionWatcher = require(ReplicatedStorage.Shared.Class.CollectionWatcher)
	local Util = require(ReplicatedStorage.Packages.Util)

	local killPart: CollectionWatcher.CollectionWatcher<BasePart> =
		CollectionWatcher.new("KILL_PART")

	-- Add a handler for kill parts
	-- The callback will be called for all existing objects
	-- in addition to new objects that are added to the collection.
	local killPartAddedConnection = killPart:RegisterHandler(function(object: CollectionWatcher.CollectionObject<BasePart>)
		object.context.Touched:Connect(function(part: BasePart)
			local humanoid: Humanoid? = part.Parent:FindFirstChildOfClass("Humanoid")
				or part.Parent.Parent:FindFirstChildOfClass("Humanoid")

			if humanoid then
				humanoid.Health = 0
			end
		end)
	end)
	```

	Dont need the connection anymore?
	```lua
	killPartAddedConnection:Disconnect()
	```

	Or you can destroy the watcher
	```lua
	killPart:Destroy()
	```

	Only need to listen for new objects?
	```lua
	killPart.Added:Connect(function(object: CollectionWatcher.CollectionObject<BasePart>)
		print(`{object.context.Name} was added!`)
	end)
	```
]=]
local CollectionWatcher = {}
CollectionWatcher.__index = CollectionWatcher

export type CollectionWatcher<T> = typeof(setmetatable(
	{} :: {
		_maid: Maid.MaidType,
		_instances: { [T]: CollectionObject<T> },

		Added: Signal.Signal<CollectionObject<T>>,
	},
	CollectionWatcher
))

--[=[
	Creates a new CollectionWatcher for the given tag

	@within CollectionWatcher
	@function new
	@return CollectionWatcher
]=]
function CollectionWatcher.new<T>(tag: string): CollectionWatcher<T>
	local self = setmetatable({
		_maid = Maid.new(),
		_instances = {},

		Added = Signal.new(),
	}, CollectionWatcher) :: CollectionWatcher<T>

	for _, obj in CollectionService:GetTagged(tag) do
		local newObject: CollectionObject<T> = newCollectionObject(obj)
		self._instances[obj] = newObject
	end

	self._maid:Add(CollectionService:GetInstanceAddedSignal(tag):Connect(function(obj: T)
		local newObject: CollectionObject<T> = newCollectionObject(obj)
		self._instances[obj] = newObject
		self.Added:Fire(newObject)
	end))

	self._maid:Add(
		CollectionService:GetInstanceRemovedSignal(tag):Connect(function(obj: T)
			if self._instances[obj] then
				self._instances[obj]:_destroy()
				self._instances[obj] = nil
			end
		end)
	)

	return self
end

--[=[
	Returns all CollectionObjects in the collection.

	@within CollectionWatcher
	@method GetAll
	@return { CollectionObject }
]=]
function CollectionWatcher.GetAll<T>(
	self: CollectionWatcher<T>
): { CollectionObject<T> }
local result: {CollectionObject<T>} = {}

for _, object in pairs(self._instances) do
	table.insert(result, object)
end

	return result
end

--[=[
	Fires the callback for all existing objects and connects it to the Added signal
	Use the `Added` signal to listen for new objects without firing the callback for existing objects.

	@within CollectionWatcher
	@method RegisterHandler
	@param callback (object: CollectionObject<T>) -> ()
	@return RBXScriptConnection -- The connection to the Added signal
]=]
function CollectionWatcher.RegisterHandler<T>(
	self: CollectionWatcher<T>,
	callback: (object: CollectionObject<T>) -> ()
)
	-- Callback for existing objects
	for _, object in pairs(self._instances) do
		callback(object)
	end

	return self.Added:Connect(callback)
end

--[=[
	Disconnects all signals and stops listening for new objects.
	This does not destroy any objects from the game.

	@within CollectionWatcher
	@method Destroy
]=]
function CollectionWatcher.Destroy<T>(
	self: CollectionWatcher<T>
)
	self._maid:Destroy()
end

return CollectionWatcher
