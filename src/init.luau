-- @name dLib
-- @desc bootstraps the library
-- @author dig1t

--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Packages = ReplicatedStorage:FindFirstChild("Packages")
local ServerPackages = ServerScriptService:FindFirstChild("ServerPackages")
local Util = require(script.Util)

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
function dLib.setDivider(divider: string): nil
	assert(typeof(divider) == "string", "dLib.setDivider - Divider is not a string")
	
	dLib._pathDivider = divider
end

-- @desc Sets the root path for a specific root type
-- this should be set first before importing any modules
-- For example if you want to use a custom shared folder,
-- you would do
-- `dLib.setRootPath("shared", game:GetService("ReplicatedStorage").Shared)`
-- @param rootType: string, root: Instance
-- @returns nil
function dLib.setRootPath(rootType: string, root: Instance): nil
	assert(typeof(rootType) == "string", "dLib.setRootPath - Path is not a string")
	assert(typeof(root) == "Instance", "dLib.setRootPath - Root is not an Instance")
	
	dLib._rootPaths[rootType] = root
end

-- @desc Imports a module
-- @param path: string, isServerModule: boolean?
-- @returns any
function dLib.import(path: string, isServerModule: boolean?): any
	assert(typeof(path) == "string", "dLib.import - Path is not a string")
	
	-- Return module if it was already used
	if dLib._loadedModules[path] then
		return dLib._loadedModules[path]
	end
	
	local modulePath: ModuleScript = (
		-- Check if the module is a dLib module
		Util.treePath(script, path, dLib._pathDivider) or (
			-- If it's a server module, check if it's a server dependency or
			-- if it exists in the server folder
			isServerModule and (
				ServerPackages and Util.treePath(ServerPackages, path, dLib._pathDivider) or
				Util.treePath(dLib._rootPaths[dLib.ROOT_PATH_TYPES.SERVER], path, dLib._pathDivider)
			)
		) or (
			-- Check if it's a dependency or if it exists in the shared folder
			Packages and Util.treePath(Packages, path, dLib._pathDivider) or
			Util.treePath(dLib._rootPaths[dLib.ROOT_PATH_TYPES.SHARED], path, dLib._pathDivider)
		)
	)
	
	assert(
		modulePath,
		"dLib.import - Could not find" .. (isServerModule and " server" or "") .. " module " .. path
	)
	assert(
		modulePath:IsA("ModuleScript"),
		string.format("dLib.import - %s is not a ModuleScript instance", path)
	)
	
	local requiredModule = Util.try(function()
		return require(modulePath)
	end, function(err)
		error("dLib.import - " .. err)
	end)
	
	dLib._loadedModules[path] = requiredModule
	
	return requiredModule
end

return dLib