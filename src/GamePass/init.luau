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

	@param player Player -- The Player to check.
	@param gamePassId number -- The game pass id to check.
	@return boolean
]=]
function GamePass.has(player: Player, gamePassId: number): boolean
	assert(typeof(player) == "Instance" and player:IsA("Player"), "GamePass.has - Missing Player object")
	assert(typeof(gamePassId) == "number", "GamePass.has - Missing GamePass id")

	local key = `${player.UserId}-${gamePassId}`

	local cached: boolean = cache:Get(key)

	if cache:Get(key) == nil then
		local success, res =
			pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, gamePassId)

		if success then
			cache:Set(key, res)

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
]=]
function GamePass.prompt(player: Player, gamePassId: number)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "GamePass.prompt - Missing Player object")
	assert(typeof(gamePassId) == "number", "GamePass.prompt - Missing game pass id")

	MarketplaceService:PromptGamePassPurchase(player, gamePassId)
end

-- This function fixes the caching issue with UserOwnsGamePassAsync
-- by saving purchases made in the server. This allows the user to
-- continue playing without having to re-join.

--[=[
	Watches for game pass purchases.
	This allows the player to continue playing without having to re-join.
]=]
function GamePass.watch()
	GamePass.unwatch() -- Prevent duplicating watchers

	_maid:Task(
		MarketplaceService.PromptGamePassPurchaseFinished:Connect(
			function(player: Player, gamePassId: number, purchased: boolean)
				if not purchased then
					return
				end

				cache:Set(`${player.UserId}-${gamePassId}`, true)

				for _, callback in pairs(callbacks) do
					callback(player, gamePassId)
				end
			end
		)
	)

	_maid:Task(Players.PlayerRemoving:Connect(function(player: Player)
		for key: Cache.Key, _owned: boolean in pairs(cache:Keys()) do
			if string.sub(key, 1, #tostring(player.UserId) + 1) == `{player.UserId}-` then
				-- Remove cache record in case the ownership changed
				-- while they were away and then re-joined the game.
				cache:Delete(key)
			end
		end
	end))
end

--[=[
	Triggers a callback when a player purchases a game pass.

	```lua
	GamePass.onPurchase(function(player: Player, gamePassId: number)
		print(player.Name .. " purchased game pass " .. gamePassId)
	end)
	```

	@param callback (player: Player, gamePassId: number) -> () -- The callback to trigger.
]=]
function GamePass.onPurchase(callback: (player: Player, gamePassId: number) -> ())
	callbacks[#callbacks + 1] = callback
end

--[=[
	Stops watching for game pass purchases.
]=]
function GamePass.unwatch()
	_maid:Clean()
end

return GamePass
