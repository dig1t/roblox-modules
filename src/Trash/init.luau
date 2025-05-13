--[=[
	@class Trash

	Trash is a class that allows you to destroy an instance after a certain amount of time.

	If the instance is destroyed before the time is up, the `Trash` object will automatically clear itself

	In addition to instances, this class can be used to destroy any class object that has a `Destroy` method.

	Migrating from Debris:
	`Debris:AddItem(part, 8)` -> `Trash.new(part, 8)`

	Timed class destruction:
	```lua
	local MyClass = require(class)

	local myInstance = MyClass.new()

	Trash.new(myInstance, 10) -- Destroy the instance after 10 seconds
	```

	Use case:
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
		callback: () -> (),
	},
	Trash
))

local function isInstanceValid(instance: any): boolean
	-- For Roblox Instances, check if Parent is not nil
	if typeof(instance) == "Instance" then
		return instance.Parent ~= nil
	end

	-- For custom objects, assume valid if not nil
	return instance ~= nil
end

local function destroyTrash(trashIndex: number)
	local debris = trash[trashIndex]

	if not debris then
		return
	end

	if isInstanceValid(debris.instance) then
		pcall(debris.instance.Destroy, debris.instance) -- Safely destroy the instance
	end

	if debris.callback then
		task.spawn(debris.callback)
	end

	table.remove(trash, trashIndex)
end

--- Destroys all instances waiting to be destroyed.
function Trash.empty()
	for trashIndex = #trash, 1, -1 do
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
	@param callback function? -- A callback function to call when the instance is destroyed
	@return Trash
]=]
function Trash.new(instance: any, life: number?, callback: () -> ()?): Trash
	assert(instance.Destroy, "Instance must have a Destroy method")

	local self = setmetatable({
		instance = instance,
		destroyAt = os.clock() + (life or DEFAULT_DESTRUCTION_TIME),
		callback = callback,
	}, Trash) :: Trash

	table.insert(trash, self)

	-- Order the trash by destruction time (ascending)
	table.sort(trash, function(a, b)
		return a.destroyAt < b.destroyAt
	end)

	-- If this instance has a Destroying signal
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

--- Destroys a Trash object
function Trash.Destroy(self: Trash)
	local trashIndex = table.find(trash, self)

	if trashIndex then
		destroyTrash(trashIndex)
	end
end

RunService.Stepped:Connect(function()
	local now = os.clock()
	local trashAmount = #trash

	if trashAmount == 0 then
		return
	end

	while #trash > 0 do
		local debris = trash[1] -- Always check the first item (earliest destroyAt)

		if debris and debris.destroyAt <= now then
			destroyTrash(1)
		else
			break -- List is sorted, so stop at first not ready
		end
	end
end)

return Trash
