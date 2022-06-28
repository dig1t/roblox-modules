--[[
@name dLib
@version 1.0.2
@author dig1t
@desc Tools and libraries made by dig1t
]]

local Util = require(script.Util)

local loadedModules = {}

local function use(path)
	assert(typeof(path) == 'string', 'dLib.use - Path is not a string')

	-- Return module if it was already used
	if loadedModules[path] then
		return loadedModules[path]
	end

	local modulePath = Util.treePath(script, path, '/')

	assert(modulePath, 'dLib.use - Missing module ' .. path)
	--[[assert(
		modulePath:IsA('ModuleScript'),
		string.format('dLib.use - %s is not a ModuleScript instance', path)
	)]]

	if modulePath and modulePath:IsA('ModuleScript') then
		local success, res = pcall(function()
			return require(modulePath)
		end)

		if not success then
			error('dLib.use - ' .. res)
		end

		loadedModules[path] = res

		return res
	end
end

return {
	use = use
}