local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Cache = require(script.Parent.Cache)
local Maid = require(script.Parent.Maid)

--[=[
	Game pass library that caches game pass ownership results and watches for pass purchases.

	```lua
	local hasPass = GamePass.has(player.UserId, 123456)
	```

	@class GamePass
]=]
local GamePass = {}

local callbacks = {}

local _maid = Maid.new()
local cache = Cache.new()

--[=[
	Checks if a player has a game pass.

	```lua
	local hasPass = GamePass.has(player.UserId, 123456)
	```

	@param userId number -- The userId to check.
	@param passId number -- The game pass id to check.
	@return boolean
]=]
function GamePass.has(userId, passId): boolean
	assert(userId, "GamePass.has - Missing user id")
	assert(passId, "GamePass.has - Missing game pass id")

	local key = `${userId}-${passId}`

	local cached: boolean = cache:get(key)

	if cache:get(key) == nil then
		local success, res = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, userId, passId)

		if success then
			cache:set(key, res)

			return res
		else
			-- error(res)
			return false
		end
	end

	return cached == true
end

--[=[
	Prompts the player to purchase a game pass.

	```lua
	GamePass.prompt(player, 123456)
	```

	@param player Player -- The player to prompt.
	@param gamePassId number -- The game pass id.
	@return nil
]=]
function GamePass.prompt(player: Player, gamePassId: number): nil
	assert(typeof(player) == "Player", "GamePass.prompt - Missing player")
	assert(typeof(gamePassId) == "number", "GamePass.prompt - Missing game pass id")

	MarketplaceService:PromptGamePassPurchase(player, gamePassId)

	return nil
end

-- This function fixes the caching issue with UserOwnsGamePassAsync
-- by saving purchases made in the server. This allows the user to
-- continue playing without having to re-join.

--[=[
	Watches for game pass purchases.
	This allows the player to continue playing without having to re-join.

	@return nil
]=]
function GamePass.watch(): nil
	GamePass.unwatch() -- Prevent duplicating watchers

	_maid:task(MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end

		cache:set(`${player.UserId}-${passId}`, true)

		for _, callback in pairs(callbacks) do
			callback(player, passId)
		end
	end))

	_maid:task(Players.PlayerRemoving:Connect(function(player: Player)
		for key: string, _owned: boolean in pairs(cache:keys()) do
			if string.sub(key, 1, #tostring(player.UserId) + 1) == `{player.UserId}-` then
				-- Remove cache record in case the ownership changed
				-- while they were away and then re-join the game.
				cache:delete(key)
			end
		end
	end))

	return nil
end

--[=[
	Triggers a callback when a player purchases a game pass.

	```lua
	GamePass.onPurchase(function(player: Player, passId: number)
		print(player.Name .. " purchased game pass " .. passId)
	end)
	```

	@param callback (player: Player, passId: number) -> () -- The callback to trigger.
	@return nil
]=]
function GamePass.onPurchase(callback: (player: Player, passId: number) -> ())
	callbacks[#callbacks + 1] = callback
end

--[=[
	Stops watching for game pass purchases.
]=]
function GamePass.unwatch()
	_maid:clean()
end

return GamePass
