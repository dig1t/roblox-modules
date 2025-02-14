--[=[
	@class Replica

	A class for creating replicated objects.
]=]

--!strict

local ReplicaClient = require(script.ReplicaClient)
local ReplicaServer = require(script.ReplicaServer)
local ReplicaTypes = require(script.ReplicaTypes)

export type ReplicaServer = ReplicaServer.ReplicaServer
export type ReplicaClient = ReplicaClient.ReplicaClient

export type EventData = ReplicaTypes.EventData
export type Data = ReplicaTypes.Data

return {
	Server = ReplicaServer,
	Client = ReplicaClient,
}
