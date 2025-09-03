--[=[
	@class Replica

	A class for creating replicated objects.

	[Replica.Server](/api/ReplicaServer) is used on the server to create and manage replicated objects.
	[Replica.Client](/api/ReplicaClient) is used on the client to receive replicated objects.

	Install with wally by adding the following to your `wally.toml`:
	```toml
	Replica = "dig1t/replica@1.0.12"
	```
]=]

--!strict

local ReplicaClient = require(script.ReplicaClient)
local ReplicaServer = require(script.ReplicaServer)
local ReplicaTypes = require(script.ReplicaTypes)

export type ReplicaServer<T> = ReplicaServer.ReplicaServer<T>
export type ReplicaClient<T> = ReplicaClient.ReplicaClient<T>

export type EventData = ReplicaTypes.EventData
export type Data = ReplicaTypes.Data

local Replica = {}

--[=[
	@prop Server ReplicaServer
	@within Replica
]=]
Replica.Server = ReplicaServer

--[=[
	@prop Client ReplicaClient
	@within Replica
]=]
Replica.Client = ReplicaClient

return Replica
