local RunService = game:GetService("RunService")

local module

if RunService:IsClient() then
	module = require(script.WeaponClient)
else
	module = require(script.WeaponServer)
end

return module
