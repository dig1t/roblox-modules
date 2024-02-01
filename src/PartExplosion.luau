-- TODO: refactor this module

--!strict

local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")

local Util = require(script.Parent.Util)

local PLAYER_COLLISION_GROUP_NAME = "Player"
local PROPS_COLLISION_GROUP_NAME = "Props"

--[=[
	Explosion modifications

	@interface PartExplosionConfig
	@within PartExplosion
	.clean boolean? -- Remove fragments after a set amount of time (cleanTime)
	.cleanTime number? -- Time until fragments are removed
	.throw boolean? -- Throws fragments forward
	.parent Instance? -- Where fragments are placed in the World object
]=]
export type PartExplosionConfig = {
	clean: boolean?,
	cleanTime: number?,
	throw: boolean?,
	parent: Instance?
}

--[=[
	Breaks blocks and throws its fragments in it's forward face

	@class PartExplosion
]=]
local PartExplosion = {}
PartExplosion.__index = PartExplosion

PartExplosion.isReady = false -- Whether or not the collision groups are registered

--[=[
	Whether or not the fragments are collidable

	@within PartExplosion
	@prop isCollidable boolean
]=]
PartExplosion.isCollidable = false -- Players cannot interact with these objects

--[=[
	@param source Instance | table -- part or list of parts to destroy
	@param config PartExplosionConfig -- Explosion modifications
]=]
function PartExplosion.new(source: { Instance } | Instance, config: {
	clean: boolean?,
	cleanTime: number?,
	throw: boolean?,
	parent: Instance?
}?)
	assert(typeof(source) == "Instance" and source:IsA("BasePart") or typeof(source) == "table", "Missing part(s) to break")

	local self = setmetatable({}, PartExplosion)

	PartExplosion.setup()

	local parts: { BasePart } = {}

	if typeof(source) == "Instance" then
		parts = { source }
	elseif typeof(source) == "table" then
		for _, _part in pairs(source) do
			if typeof(_part) == "Instance" and _part:IsA("BasePart") then
				parts[#parts + 1] = _part :: BasePart
			end
		end
	end

	self.config = typeof(config or nil) == "table" and config or {
		clean = true;
		cleanTime = 1;
		throw = true;
		parent = Workspace;
	}
	self.fragments = {} :: { BasePart }

	task.spawn(function()
		for _, _part in pairs(parts) do
			if typeof(_part) == "Instance" and _part:IsA("BasePart") then
				task.spawn(function()
					self:_breakPart(_part)
				end)
			end
		end

		task.wait(.85)

		if self.config.throw and self.fragments then
			for _, fragment in pairs(self.fragments) do
				if fragment.Parent then
					fragment:ClearAllChildren()
				end
			end
		end

		task.wait(self.config.cleanTime or 8)

		if self.config.clean and self.fragments then
			self:destroy()
		elseif self.fragments then
			for _, fragment in pairs(self.fragments) do
				if fragment.Parent then
					-- Remove remaining moving parts
					if fragment.AssemblyLinearVelocity.Magnitude > .001 then
						fragment:Destroy()
					end

					fragment.Anchored = true
				end
			end
		end
	end)

	return self
end

function PartExplosion.setup()
	-- Insert collision groups if missing
	if PartExplosion.isReady or PartExplosion.isCollidable or RunService:IsServer() then
		return
	end

	local playerGroupExists
	local propGroupExists

	for _, group in pairs(PhysicsService:GetRegisteredCollisionGroups()) do
		if group.name == PLAYER_COLLISION_GROUP_NAME then
			playerGroupExists = true
		elseif group.name == PROPS_COLLISION_GROUP_NAME then
			propGroupExists = true
		end
	end

	if not playerGroupExists then
		PhysicsService:RegisterCollisionGroup(PLAYER_COLLISION_GROUP_NAME)
	end

	if not propGroupExists then
		PhysicsService:RegisterCollisionGroup(PROPS_COLLISION_GROUP_NAME)
	end

	if not playerGroupExists or not propGroupExists then
		-- Disable collisions with ragdoll characters
		PhysicsService:CollisionGroupSetCollidable(
			PLAYER_COLLISION_GROUP_NAME,
			PROPS_COLLISION_GROUP_NAME,
			false
		)
	end

	PartExplosion.isReady = true
end

function PartExplosion:_breakPart(part: BasePart): nil
	local partMagnitude = 0

	repeat
		local fragment: BasePart = part:Clone()

		if not PartExplosion.isCollidable then
			-- Disable player collision
			fragment.CollisionGroup = PROPS_COLLISION_GROUP_NAME
		end

		fragment:ClearAllChildren() -- Remove welds, effects, etc.

		fragment.Anchored = false
		fragment.CanCollide = true

		local newPosition: CFrame = part.CFrame:ToWorldSpace(CFrame.new(
			Util.random(-part.Size.X * 10, part.Size.X * 10) / 10 / 2,
			Util.random(-part.Size.Y * 10, part.Size.Y * 10) / 10 / 2,
			Util.random(-part.Size.Z * 10, part.Size.Z * 10) / 10 / 2
		))

		fragment.CFrame = newPosition + (fragment.CFrame.LookVector * 1.2)

		fragment.Size = Vector3.new(
			part.Size.X / (Util.random(4, 8) / 1.2),
			part.Size.Y / (Util.random(4, 8) / 1.2),
			part.Size.Z / (Util.random(4, 8) / 1.2)
		)

		if self.config.throw then
			local attachment = Instance.new("Attachment")
			attachment.Name = "GlassAttachment"
			attachment.Position = fragment.CFrame:ToObjectSpace(
				newPosition + (fragment.CFrame.LookVector * 4)
			).Position
			attachment.Parent = fragment

			local force = Instance.new("VectorForce")
			force.Force = fragment.CFrame:ToObjectSpace(
				newPosition + (fragment.CFrame.LookVector * 40)
			).Position
			force.Attachment0 = attachment
			force.Parent = fragment
		end

		partMagnitude += fragment.Size.Magnitude

		if self.fragments then
			self.fragments[#self.fragments + 1] = fragment
		end

		fragment.Parent = self.config.parent or Workspace
	until partMagnitude > part.Size.Magnitude * 3

	part:Destroy()

	return nil
end

--[=[
	Removes all fragments and cleans up the PartExplosion instance

	@within PartExplosion
	@return nil
]=]
function PartExplosion:destroy(): nil
	if self.fragments then
		for _, fragment in pairs(self.fragments) do
			if fragment.Parent then
				fragment:Destroy()
			end
		end
	end

	self.fragments = {}

	return nil
end

return PartExplosion
