local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')
local RunService = game:GetService('RunService')

local Util = require(ReplicatedStorage.Lib.Util)

local isServer = RunService:IsServer()

local function import(path, serverLib)
	assert(typeof(path) == 'string', 'Bootstrap.import - Path is not a string')
	
	if serverLib == true and not isServer then
		error('Bootstrap.import - Server modules can only be requested from the server')
	end
	
	local modulePath = Util.treePath(script, path, '/') or Util.treePath(serverLib == true and ServerScriptService or ReplicatedStorage, path, '/')
	
	assert(modulePath, 'Bootstrap.import - Missing module ' .. path)
	assert(
		modulePath:IsA('ModuleScript'),
		string.format('Bootstrap.import - %s is not a ModuleScript instance', modulePath.ClassName, path)
	)
	
	if modulePath and modulePath:IsA('ModuleScript') then
		local success, res = pcall(function()
			return require(modulePath)
		end)
		
		if not success then
			error('Bootstrap.import - ' .. res)
		end
		
		return res
	end
end

return { import = import }