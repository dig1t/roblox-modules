--[=[
	@class ReplicaServer
	@server
	@tag Replica

	A class for creating replicated objects.

	All state keys must be strings.
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Maid = require(script.Parent.Parent.Maid)
local ReplicaTypes = require(script.Parent.ReplicaTypes)
local Signal = require(script.Parent.Parent.Signal)
local Util = require(script.Parent.Parent.Util)
local t = require(script.Parent.Parent.t) :: any -- HACK: any to avoid type errors during linting

local remote: RemoteEvent

if RunService:IsServer() then
	remote = Instance.new("RemoteEvent")
	remote.Name = "ReplicaEvents"
	remote.Parent = script.Parent
end

local ReplicaServer = {}
ReplicaServer.__index = ReplicaServer

local replicas: { ReplicaServer<any> } = {}

export type ReplicaServer<T> = typeof(setmetatable(
	{} :: {
		replicaId: string,
		class: string,

		replicatedTo: { Player }?,
		data: T,

		keyChangedSignals: { [string]: { Signal.Signal<any> } },

		maid: Maid.Maid,
	},
	ReplicaServer
))

--[=[
	@interface ReplicaServerConfig
	@within ReplicaServer
	.players { Player }? -- If defined, only these players will receive the replicated object
	.initialState { [string]: any }? -- The initial state of the replicated object. Keys must be strings.
	.class string -- The class of the replicated object
]=]
export type ReplicaServerConfig = {
	players: { Player }?,
	initialData: { [string]: any }?,
	class: string,
}

-- Type checking for the constructor
local tNewReplica = t.strictInterface({
	players = t.optional(t.array(t.instanceIsA("Player"))),
	initialData = t.optional(t.table),
	class = t.string,
})

--[=[
	Get all ReplicaServer objects by their class

	@param class string -- The class of the ReplicaServer objects
	@return { ReplicaServer }
]=]
function ReplicaServer.getReplicasByClass(class: string): { ReplicaServer<any> }
	local res: { ReplicaServer<any> } = {}

	for _, replica: ReplicaServer<any> in pairs(replicas) do
		if replica.class == class then
			table.insert(res, replica)
		end
	end

	return res
end

--[=[
	Get a ReplicaServer object by its replicaId

	@param replicaId string -- The replicaId of the ReplicaServer object
	@return ReplicaServer?
]=]
function ReplicaServer.getReplicaById(replicaId: string): ReplicaServer<any>?
	for _, replica: ReplicaServer<any> in pairs(replicas) do
		if replica.replicaId == replicaId then
			return replica
		end
	end

	return nil
end

--[=[
	Create a new ReplicaServer object

	@param config ReplicaServerConfig -- Configuration for the replicated object
	@return ReplicaServer -- The new ReplicaServer object
]=]
function ReplicaServer.new(config: ReplicaServerConfig): ReplicaServer<any>
	assert(RunService:IsServer(), "ReplicaServers can only be created on the server")
	tNewReplica(config)

	local replicaId: string = Util.randomString()

	local self = setmetatable({
		replicaId = replicaId,
		class = config.class,

		data = config.initialData or {},
		replicatedTo = config.players,

		keyChangedSignals = {},

		maid = Maid.new(),
	}, ReplicaServer) :: ReplicaServer<any>

	table.insert(replicas, self)

	self:Fire({
		type = "REPLICA_NEW",
		payload = {
			replicaId = replicaId,
			class = config.class,
			data = self.data,
		},
	} :: ReplicaTypes.InitialReplicaAction)

	self.maid:Add(function()
		-- Clear key changed signals
		for _, keySignals in self.keyChangedSignals do
			for _, signal in keySignals do
				signal:Destroy()
			end
		end
	end)

	self.maid:Add(function()
		self:Fire({
			type = "REPLICA_DESTROY",
			payload = {
				replicaId = replicaId,
			},
		} :: ReplicaTypes.EventData)

		-- Remove from replicas list
		for index, replica: ReplicaServer<any> in pairs(replicas) do
			if replica == self then
				table.remove(replicas, index)
				break
			end
		end
	end)

	return self
end

--[=[
	Fires an action to the appropriate clients

	@method Fire
	@within ReplicaServer
	@param action ReplicaTypes.Action -- The action to fire
]=]
function ReplicaServer.Fire<T>(self: ReplicaServer<T>, action: ReplicaTypes.Action)
	if self.replicatedTo then
		for _, player in self.replicatedTo do
			remote:FireClient(player, action)
		end
	else
		remote:FireAllClients(action)
	end
end

--[=[
	Pushes the changed key to the clients

	@method Push
	@within ReplicaServer
	@param key string -- The key to push
]=]
function ReplicaServer.Push<T>(self: ReplicaServer<ReplicaTypes.Data>, key: string)
	self:Fire({
		type = "REPLICA_UPDATE",
		payload = {
			replicaId = self.replicaId,
			class = self.class,
			key = key,
			value = self.data[key],
		},
	} :: ReplicaTypes.ReplicaUpdateAction)

	if self.keyChangedSignals[key] then
		for _, signal in self.keyChangedSignals[key] do
			signal:Fire(self.data[key])
		end
	end
end

--[=[
	Gets the value of a key in the ReplicaServer object

	@method Get
	@within ReplicaServer
	@param key string? -- The key to get. If nil, returns the entire data table
	@return any -- The value of the key, or the entire data table if key is nil
]=]
function ReplicaServer.Get<T>(self: ReplicaServer<T>, key: string?): any
	local data: ReplicaTypes.Data = self.data :: any

	return key and data[key] or data
end

--[=[
	Returns a Signal that fires when a key in the replica is updated

	Usage:
	```lua
	local replica = ReplicaServer.getReplicaById("replicaId")

	replica:GetKeyChangedSignal("key"):Connect(function(value)
		print("Key changed:", value)
	end)
	```

	@method GetKeyChangedSignal
	@within ReplicaServer
	@param key string -- The key to get the value of
	@return Signal.Signal<ReplicaServer>
]=]
function ReplicaServer.GetKeyChangedSignal<T>(
	self: ReplicaServer<T>,
	key: string
): Signal.Signal<any>
	assert(RunService:IsServer(), "ReplicaServer can only be used on the server")
	assert(type(key) == "string", "Expected string for key")

	local signal = Signal.new()

	if not self.keyChangedSignals[key] then
		self.keyChangedSignals[key] = {}
	end

	table.insert(self.keyChangedSignals[key], signal)

	signal.onDestroy = function()
		for index, storedSignal in self.keyChangedSignals[key] do
			if storedSignal == signal then
				table.remove(self.keyChangedSignals[key], index)
				break
			end
		end
	end

	return signal
end

--[=[
	Sets the value of a key in the ReplicaServer object and pushes the change to the clients

	@method Set
	@within ReplicaServer
	@param key string -- The key to REPLICA_UPDATE
	@param value any -- The value to set
]=]
function ReplicaServer.Set<T>(
	self: ReplicaServer<ReplicaTypes.Data>,
	key: string,
	value: any
)
	self.data[key] = value

	self:Push(key)
end

--[=[
	Destroys a replica object and replicates the event to clients

	@method Destroy
	@within ReplicaServer
	@tag Cleanup
]=]
function ReplicaServer.Destroy<T>(self: ReplicaServer<T>)
	self.maid:Clean()
end

if RunService:IsServer() then
	remote.OnServerEvent:Connect(function(player: Player, action: ReplicaTypes.Action)
		-- Detect exploiters who try to call ReplicaEvents
		if typeof(action) ~= "table" or action.type == nil then
			Players:BanAsync({
				UserIds = { player.UserId },
				PrivateReason = "Attempted to exploit the server by calling ReplicaEvents",
				PublicReason = "Attempted to exploit",
				Duration = 60 * 60 * 24 * 30,
			})
		end

		if action.type ~= "FETCH_CLASS_REPLICAS" then
			return
		end

		local res: { ReplicaTypes.ReplicaFetchPayloadItem } = {}

		for _, replica: ReplicaServer<any> in pairs(replicas) do
			if replica.class ~= action.payload then
				continue
			end

			if replica.replicatedTo and not table.find(replica.replicatedTo, player) then
				continue
			end

			table.insert(
				res,
				{
					replicaId = replica.replicaId,
					class = replica.class,
					data = replica.data,
				} :: ReplicaTypes.ReplicaFetchPayloadItem
			)
		end

		remote:FireClient(
			player,
			{
				type = "FETCH_CLASS_REPLICAS",
				payload = res,
			} :: ReplicaTypes.ReplicaFetchAction
		)
	end)
end

return ReplicaServer
