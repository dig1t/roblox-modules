--[[
@name dLib Importer
@author dig1t
]]

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Util = require(script.Util)

local PATH_DIVIDER = '/'

local exports = {}

local loadedModules = {
	Util = Util -- We already required the Util module
}

function exports.import(path)
	assert(typeof(path) == 'string', 'dLib.import - Path is not a string')

	-- Return module if it was already used
	if loadedModules[path] then
		return loadedModules[path]
	end

	local modulePath = Util.treePath(script, path, PATH_DIVIDER)
	
	-- Tree search through ReplicatedStorage if there is no dLib module found
	if not modulePath then
		modulePath = Util.treePath(ReplicatedStorage, path, PATH_DIVIDER)
	end

	assert(modulePath, 'dLib.import - Missing module ' .. path)
	assert(
		modulePath:IsA('ModuleScript'),
		string.format('dLib.import - %s is not a ModuleScript instance', path)
	)
	
	local success, res = pcall(function()
		return require(modulePath)
	end)
		if not success then
		error('dLib.import - ' .. res)
	end
	
	loadedModules[path] = res
	
	return res
end

return exports