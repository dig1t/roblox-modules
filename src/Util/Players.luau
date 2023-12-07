--!strict

local Players = game:GetService("Players")

local players = {}

local groupRankCache = {}

function players.getGroupRank(player, groupId): number
	local uniqueId = player.UserId .. groupId
	
	if not player or not groupId then
		return 0
	elseif not groupRankCache[uniqueId] then
		local success, res = pcall(function()
			return player:GetRankInGroup(groupId)
		end)
		
		groupRankCache[uniqueId] = res
		
		return success and res or 0
	else
		return groupRankCache[uniqueId]
	end
end

function players.isCreator(player: Player): boolean
	return (
		game.CreatorType == Enum.CreatorType.Group and players.getGroupRank(player, game.CreatorId) >= 255
	) or (
		game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId
	)
end

local userLevel = {
	normal = 0;
	premium = 1;
	VIP = 2;
	moderator = 3;
	superuser = 4;
	creator = 5;
}

players.userLevel = userLevel

function players.getUserLevel(player): number
	return (
		(players.isCreator(player) and userLevel.creator) or
		(player.MembershipType == Enum.MembershipType.Premium and userLevel.premium) or
		userLevel.normal
	)
end

function players.getHumanoid(obj): Humanoid?
	return obj and typeof(obj) == "Instance" and (
		(obj:IsA("Player") and obj.Character and obj.Character:FindFirstChild("Humanoid")) or
		(obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid")) or
		(obj:IsA("Humanoid") and obj) or
		nil -- Did not find a humanoid object
	)
end

function players.isAlive(obj): boolean
	local humanoid = players.getHumanoid(obj)
	
	return humanoid and humanoid.Health ~= 0
end

function players.hasHumanoid(obj): boolean
	return players.getHumanoid(obj) ~= nil
end

function players.getPlayerFromPart(part: BasePart): Player?
	if typeof(part) ~= "Instance" or not part:IsA("BasePart") then
		return
	end
	
	local node: Instance = part
	local humanoid: Humanoid?
	
	repeat
		humanoid = node and node:FindFirstChildOfClass("Humanoid")
		node = node.Parent :: Instance
	until not node or humanoid or node == game or node == nil
	
	return humanoid and Players:GetPlayerFromCharacter(humanoid.Parent) or nil
end

return players
