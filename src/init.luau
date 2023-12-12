-- @name dLib
-- @desc bootstraps the library
-- @author dig1t

--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Packages: any = ReplicatedStorage:FindFirstChild("Packages")
local ServerPackages: any = ServerScriptService:FindFirstChild("ServerPackages")
local Util: any = require(script.Util)

--[=[
	Bootrapping library to allow for importing modules.

	@class dLib
]=]
local dLib = {}

dLib.ROOT_PATH_TYPES = {
	SHARED = "SHARED";
	SERVER = "SERVER";
}

dLib._loadedModules = {
	Util = Util -- We already required the Util module above
}
dLib._rootPaths = {
	[dLib.ROOT_PATH_TYPES.SHARED] = ReplicatedStorage,
	[dLib.ROOT_PATH_TYPES.SERVER] = ServerScriptService,
}
dLib._pathDivider = "/"

-- @desc Sets the divider used to separate paths
-- @param divider: string
-- @returns nil

--[=[
	Sets the divider used to separate paths.

	@param divider string
]=]
function dLib.setDivider(divider: string)
	assert(typeof(divider) == "string", "dLib.setDivider - Divider is not a string")

	dLib._pathDivider = divider
end

--[=[
	Sets the root path for a specific root type.
	This should be set first before importing any modules.
	For example if you want to use a custom shared folder you would do:
	`dLib.setRootPath("shared", game:GetService("ReplicatedStorage").Shared)`

	The root must be a descendant of `game`.

	@param rootName string -- The name of the root path (e.g. "Shared", "Server")
	@param rootInstance Instance -- The root path (e.g. ReplicatedStorage.Shared)
]=]
function dLib.setRootPath(rootName: string, rootInstance: Instance)
	assert(
		typeof(rootName) == "string",
		"dLib.setRootPath - Path is not a string"
	)
	assert(
		typeof(rootInstance) == "Instance",
		"dLib.setRootPath - rootInstance is not an Instance"
	)
	assert(
		rootInstance:IsDescendantOf(game),
		"dLib.setRootPath - rootInstance is not a descendant of game"
	)

	dLib._rootPaths[rootName] = rootInstance
end

--[=[
	@interface ImportResult
	@within dLib
	@field [any] any -- The module that was imported
]=]
type ImportResult = {
	[any]: any
}

--[=[
	Imports a module.

	@param path string
]=]
function dLib.import(path: string): ImportResult
	assert(typeof(path) == "string", "dLib.import - Path is not a string")

	-- Return module if it was already used
	if dLib._loadedModules[path] then
		return dLib._loadedModules[path]
	end

	local splitPath = Util.split(path, dLib._pathDivider)
	local rootPath: Instance = game

	if #splitPath > 1 then
		rootPath = script:FindFirstChild(splitPath[2])

		assert(
			rootPath,
			"dLib.import - Could not find root path " .. splitPath[2] .. ". please set it using dLib.setRootPath."
		)
	end

	local modulePath: ModuleScript = Util.treePath("Shared", rootPath, dLib._pathDivider)

	assert(
		modulePath,
		`dLib.import - Could not find module {path} in {rootPath:GetFullName()}`
	)
	assert(
		modulePath:IsA("ModuleScript"),
		string.format("dLib.import - %s is not a ModuleScript instance", path)
	)

	local requiredModule = Util.try(function()
		return require(modulePath) :: any
	end, function(err)
		error("dLib.import - " .. err)
	end)

	dLib._loadedModules[path] = requiredModule

	return requiredModule :: ImportResult
end

-- Set default root paths
dLib.setRootPath("dLib", script)
dLib.setRootPath("Shared", ReplicatedStorage)

if RunService:IsServer() then
	dLib.setRootPath("Server", ServerScriptService)
end

if RunService:IsClient() then
	dLib.setRootPath("Client", Players.LocalPlayer)
end

return dLib
