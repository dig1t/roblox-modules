--[=[
	@class Trash

	Trash is a class that allows you to destroy an instance after a certain amount of time.

	If the instance is destroyed before the time is up, the `Trash` object will automatically clear itself

	In addition to instances, this class can be used to destroy any class object that has a `Destroy` method.

	```lua
	local MyClass = require(class)

	local myInstance = MyClass.new()

	Trash.new(myInstance, 10) -- Destroy the instance after 10 seconds
	```

	```lua
	local function partExplosion()
		for i = 1, 100 do
			local part = Instance.new("Part")
			part.Parent = Workspace

			Trash.new(part, 10) -- Destroy the part after 10 seconds

			part.Touched:Connect(function()
				part:Destroy()
				-- `Trash` will now automatically clear the Trash object
			end)
		end
	end
	```
]=]

--!native

local RunService = game:GetService("RunService")

local DEFAULT_DESTRUCTION_TIME = 60

local trash: { Trash } = {}

local Trash = {}
Trash.__index = Trash

export type Trash = typeof(setmetatable(
	{} :: {
		instance: any,
		destroyAt: number,
	},
	Trash
))

local function destroyTrash(trashIndex: number)
	local debris = trash[trashIndex]

	if not debris then
		return
	end

	pcall(debris.instance.Destroy, debris.instance) -- Safely destroy the instance

	table.remove(trash, trashIndex)
end

--- Destroys all instances waiting to be destroyed.
function Trash.empty()
	for trashIndex, _ in trash do
		destroyTrash(trashIndex)
	end

	trash = {}
end

--- Stops an instance from being destroyed.
function Trash.removeFromTrash(instance: any)
	-- Search for the instance
	for trashIndex, debris in trash do
		if debris.instance == instance then
			table.remove(trash, trashIndex)
			break
		end
	end
end

--[=[
	Creates a new Trash object

	@param instance Instance -- The instance to destroy
	@param life number? -- The amount of time (seconds) to wait before destroying the instance. Defaults to 60 seconds.
]=]
function Trash.new(instance: any, life: number?): Trash
	assert(instance.Destroy, "Instance must have a Destroy method")

	local self = setmetatable({
		instance = instance,
		destroyAt = os.clock() + (life or DEFAULT_DESTRUCTION_TIME),
	}, Trash)

	table.insert(trash, self)

	-- Order the trash by destruction time
	table.sort(trash, function(a, b)
		return a.destroyAt < b.destroyAt
	end)

	-- Is this instance has a Destroying signal
	-- Connect to it to remove the instance from the trash list
	-- If the instance is destroyed before the time is up
	if instance.Destroying then
		instance.Destroying:Once(function()
			local trashIndex = table.find(trash, self)

			if trashIndex then
				table.remove(trash, trashIndex)
			end
		end)
	end

	return self
end

function Trash.Destroy(self: Trash)
	local trashIndex = table.find(trash, self)

	if trashIndex then
		destroyTrash(trashIndex)
	end
end

RunService.Stepped:Connect(function()
	local now = os.clock()

	for garbageIndex = 1, #trash do
		local debris = trash[garbageIndex]

		if now > debris.destroyAt then
			destroyTrash(garbageIndex)
		else
			return
		end
	end
end)

return Trash
