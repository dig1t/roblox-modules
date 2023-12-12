--!strict

local Players = game:GetService("Players")

local players = {}

local groupRankCache = {}
local groupRankCacheExpiration = 60 -- 1 minutes

--[=[
	Gets the group rank of a player.

	#### Example:
	```lua
	players.getGroupRank(game.Players.LocalPlayer, 1) -- 255
	```

	@within Util
	@param player Player
	@param groupId number
	@return number
]=]
function players.getGroupRank(player: Player, groupId: number): number
	local uniqueId: string = `${player.UserId}-${groupId}`

	if not player or not groupId then
		return 0
	end

	if not groupRankCache[uniqueId] then
		local success, res = pcall(function()
			return player:GetRankInGroup(groupId)
		end)

		groupRankCache[uniqueId] = {
			rank = success and res or 0;
			fetchedAt = os.time();
		}

		return success and res or 0
	end

	if os.clock() - groupRankCache[uniqueId].fetchedAt > groupRankCacheExpiration then
		return players.getGroupRank(player, groupId) -- refetch if expired
	end

	return groupRankCache[uniqueId].rank
end

--[=[
	Checks if a player is the creator of the game.

	#### Example:
	```lua
	players.isCreator(game.Players.LocalPlayer) -- true
	```

	@within Util
	@param player Player
	@return boolean
]=]
function players.isCreator(player: Player): boolean
	return (
		game.CreatorType == Enum.CreatorType.Group and players.getGroupRank(player, game.CreatorId) >= 255
	) or (
		game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId
	)
end

--[=[
	@within Util
	@prop userLevel table<number, number>
]=]
players.userLevel = {
	normal = 0; -- (default)
	premium = 1; -- (requires premium)
	VIP = 2; -- (if game is owned by group, requires rank 10)
	moderator = 3; -- (if game is owned by group, requires rank 50)
	superuser = 4; -- developer (if game is owned by group, requires rank 254)
	creator = 5; -- (requires group rank 255 or if game is owned by user)
}

--[=[
	Gets the user level of a player.

	#### Example:
	```lua
	getUserLevel(game.Players.LocalPlayer) -- 0
	getUserLevel(game.Players.GameDeveloper) -- 4
	getUserLevel(game.Players.PremiumPlayer) -- 4
	getUserLevel(game.Players.Creator) -- 5
	```

	@within Util
	@param player Player
	@return number
]=]
function players.getUserLevel(player: Player): number
	local isGameOwnedByGroup: boolean = game.CreatorType == Enum.CreatorType.Group

	if players.isCreator(player) then
		return players.userLevel.creator
	elseif isGameOwnedByGroup then
		local playerRank: number = players.getGroupRank(player, game.CreatorId)

		if playerRank >= 253 then
			return players.userLevel.superuser
		elseif playerRank == 99 then
			return players.userLevel.moderator
		elseif playerRank < 10 then
			return players.userLevel.VIP
		end
	end

	return (
		player.MembershipType == Enum.MembershipType.Premium and players.userLevel.premium
	) or (
		players.userLevel.normal
	)
end


--[=[
	Gets the humanoid object from a player's character part, character model, player object, or humanoid.

	#### Example:
	```lua
	players.getHumanoid(game.Players.LocalPlayer) -- Humanoid
	```

	@within Util
	@param object Instance
	@return Humanoid?
]=]
function players.getHumanoid(object: Instance): Humanoid?
	if typeof(object) ~= "Instance" then
		warn("players.getHumanoid - object argument is not an Instance")
		return nil
	elseif object:IsA("Humanoid") then
		return object
	elseif object:IsA("Player") then
		return object.Character and object.Character:FindFirstChildOfClass("Humanoid")
	elseif object:IsA("Model") then
		return object:FindFirstChildOfClass("Humanoid")
	else
		return nil
	end
end

--[=[
	Checks if a humanoid is alive.

	#### Example:
	```lua
	players.isAlive(game.Players.LocalPlayer) -- true
	players.isAlive(game.Workspace.Zombie) -- false
	players.isAlive(game.Workspace.Part) -- nil, but will throw a warning
	```

	@within Util
	@param obj Instance
	@return boolean
]=]
function players.isAlive(obj: Instance): boolean
	local humanoid: Humanoid? = players.getHumanoid(obj)

	return humanoid and humanoid.Health > 0 or false
end

--[=[
	Checks if an object has a humanoid.

	#### Example:
	```lua
	players.hasHumanoid(game.Players.LocalPlayer) -- true
	players.hasHumanoid(game.Workspace.Zombie) -- true
	```

	@within Util
	@param obj Instance
	@return boolean
]=]
function players.hasHumanoid(obj): boolean
	return players.getHumanoid(obj) ~= nil
end

--[=[
	Gets the player object from a BasePart.

	#### Example:
	```lua
	players.getPlayerFromPart(game.Workspace.Part) -- Player
	```

	@within Util
	@param part BasePart
	@return Player?
]=]
function players.getPlayerFromPart(part: BasePart): Player?
	assert(typeof(part) == "Instance", "players.getPlayerFromPart - Part is not an Instance")

	local node: Instance = part
	local humanoid: Humanoid?

	repeat
		humanoid = node and node:FindFirstChildOfClass("Humanoid")
		node = node.Parent :: Instance
	until not node or humanoid or node == game

	return humanoid and Players:GetPlayerFromCharacter(humanoid.Parent) or nil
end

return players
