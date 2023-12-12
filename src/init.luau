-- @name dLib
-- @desc bootstraps the library
-- @author dig1t

--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Shared: any = ReplicatedStorage:FindFirstChild("Shared")
local Packages: any = ReplicatedStorage:FindFirstChild("Packages")
local Util: any = require(script.Util)

--[=[
	Bootrapping library to allow for importing modules.

	@class dLib
]=]
local dLib = {}

dLib._loadedModules = {
	Util = Util -- We already required the Util module above
}
dLib._rootPaths = {}
dLib._pathDivider = "/"

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

	assert(
		#splitPath > 1,
		"dLib.import - Path must be a valid path"
	)

	rootPath = dLib._rootPaths[splitPath[1]]

	assert(
		rootPath,
		"dLib.import - Could not find root path " .. splitPath[1] .. ". please set it using dLib.setRootPath."
	)

	table.remove(splitPath, 1)

	local modulePath: string = Util.join(splitPath, dLib._pathDivider)
	local module: ModuleScript = Util.treePath(
		rootPath, modulePath, dLib._pathDivider
	)

	assert(
		module,
		`dLib.import - Could not find module {path} in {rootPath:GetFullName()}`
	)

	print(modulePath, module:GetFullName())

	assert(
		module:IsA("ModuleScript"),
		string.format("dLib.import - %s is not a ModuleScript instance", path)
	)

	local requiredModule = Util.try(function()
		return require(module) :: any
	end, function(err)
		error("dLib.import - " .. err)
	end)

	dLib._loadedModules[path] = requiredModule

	return requiredModule :: ImportResult
end

-- Set default root paths
dLib.setRootPath("dLib", script)
dLib.setRootPath("Shared", Shared)
dLib.setRootPath("Packages", Packages)

if RunService:IsServer() then
	local ServerPackages: any = ServerScriptService:FindFirstChild("ServerPackages")
	local Server: any = ServerScriptService:FindFirstChild("Server")
	
	if Server then
		dLib.setRootPath("Server", Server)
	end
	
	if ServerPackages then
		dLib.setRootPath("ServerPackages", ServerPackages)
	end
end

if RunService:IsClient() then
	dLib.setRootPath("Client", Players.LocalPlayer.PlayerScripts.Client)
end

return dLib
