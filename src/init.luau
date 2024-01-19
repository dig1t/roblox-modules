--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Shared: any = ReplicatedStorage:FindFirstChild("Shared")
local Packages: any = ReplicatedStorage:FindFirstChild("Packages")

-- Load all modules
local Util = require(script.Util)
local Animation = require(script.Animation)
local Badge = require(script.Badge)
local Cache = require(script.Cache)
local ChatCommand = require(script.ChatCommand)
local GamePass = require(script.GamePass)
local Maid = require(script.Maid)
local Palette = require(script.Palette)
local PartExplosion = require(script.PartExplosion)
local Promise = require(script.Promise)
local Ragdoll = require(script.Ragdoll)
-- local WeaponClient: any = require(script.WeaponClient)
-- local WeaponServer: any = require(script.WeaponServer)

--[=[
	Bootstrapping library to allow for importing modules.

	```lua
	local dLib = require(ReplicatedStorage.Packages.dLib)
	local Util = dLib.import("dLib/Util")
	```

	You can also import modules from other roots:
	```lua
	local PlayerUtil = dLib.import("Shared/Util/PlayerUtil") -- ReplicatedStorage.Shared.Util.PlayerUtil
	local Knit = dLib.import("Packages/Knit") -- ServerScriptService.Server.Packages.Knit
	```

	Custom root paths can be set using `dLib.setRootPath`:
	```lua
	dLib.setRootPath("ServerFolder", ServerScriptService.ServerFolder)

	local ServerModule = dLib.import("ServerFolder/Module") -- ServerScriptService.ServerFolder.Module
	```

	Any custom root paths should be the first thing set before importing any modules.

	@class dLib
]=]
local dLib = {}

dLib._loadedModules = {
	Util = Util,
	Animation = Animation,
	Badge = Badge,
	Cache = Cache,
	ChatCommand = ChatCommand,
	GamePass = GamePass,
	Maid = Maid,
	Palette = Palette,
	PartExplosion = PartExplosion,
	Promise = Promise,
	Ragdoll = Ragdoll,
	-- WeaponClient = WeaponClient,
	-- WeaponServer = WeaponServer
}
dLib._rootPaths = {}
dLib._pathDivider = "/"

-- Expose built-in modules
dLib.Util = Util
dLib.Animation = Animation
dLib.Badge = Badge
dLib.Cache = Cache
dLib.ChatCommand = ChatCommand
dLib.GamePass = GamePass
dLib.Maid = Maid
dLib.Palette = Palette
dLib.PartExplosion = PartExplosion
dLib.Promise = Promise
dLib.Ragdoll = Ragdoll
-- dLib.WeaponClient = WeaponClient
-- dLib.WeaponServer = WeaponServer

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

if Shared then
	dLib.setRootPath("Shared", Shared)
end

if Packages then
	dLib.setRootPath("Packages", Packages)
end

if RunService:IsServer() then
	local ServerPackages: any = ServerScriptService:FindFirstChild("ServerPackages")
	local Server: any = ServerScriptService

	if Server then
		dLib.setRootPath("Server", Server)
	end

	if ServerPackages then
		dLib.setRootPath("ServerPackages", ServerPackages)
	end
end

if RunService:IsClient() then
	dLib.setRootPath("Client", Players.LocalPlayer.PlayerScripts)
end

return dLib
