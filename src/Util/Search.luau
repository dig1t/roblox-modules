--!strict

local search = {}

function search.getDescendantCount(obj): number?
	if not obj then
		return
	end

	local count = 0

	for _, part in pairs(obj:GetDescendants()) do
		if part:IsA("BasePart") then
			count += 1
		end
	end

	return count
end

function search.getDescendantParts(obj): { BasePart }?
	if not obj then
		return
	end

	local parts = {}

	for _, part in pairs(obj:GetDescendants()) do
		if part:IsA("BasePart") then
			parts[#parts + 1] = part
		end
	end

	return parts
end

function search.getAncestor(child, condition): Instance?
	if not child or not condition then
		return
	end

	if typeof(condition) == "string" then
		local searchString = condition

		condition = function(obj)
			return obj and obj.Name == searchString
		end
	end

	while child do
		if condition(child) then
			return child
		elseif child.Parent then
			child = child.Parent :: Instance
		else
			break
		end
	end

	return
end

type ConditionTest = (obj: Instance) -> boolean

function search.find(parent: Instance?, condition: ConditionTest | string, maxRounds: number, _round: number): Instance?
	assert(typeof(parent) == "Instance" or parent == nil, "parent must be an Instance or nil")
	assert(typeof(condition) == "function" or condition == "string", "condition must be a function or string")
	assert(typeof(maxRounds) == "number" or maxRounds == nil, "maxRounds must be a number or nil")
	assert(typeof(_round) == "number" or _round == nil, "_round must be a number or nil")

	if not parent or not condition then
		return
	end

	local round: number = _round or 1

	local function test(obj: Instance): boolean
		if typeof(condition) == "function" then
			local _test = condition :: ConditionTest
			return _test(obj)
		end

		return obj and obj.Name == condition
	end

	local match
	local nextBatch = {}

	-- search all children first - first round
	for _, child in pairs(parent:GetChildren()) do
		if test(child) then
			match = child
			break
		elseif #child:GetChildren() > 0 then
			table.insert(nextBatch, child)
		end
	end

	if not match and round >= maxRounds then
		return
	end

	-- search grandchildren after - second round
	if not match then
		for _, child: Instance in pairs(nextBatch) do
			if child then
				print(1) -- match = search.find(child, test, maxRounds, round + 1)
			end
		end
	end

	return match
end

function search.exists(parent: Instance?, childName: string | { string }): boolean
	assert(typeof(parent) == "Instance" or parent == nil, "parent must be an Instance or nil")
	assert(typeof(childName) == "string" or typeof(childName) == "table", "childName must be a string or table")

	if not parent then
		return false
	end

	if typeof(childName) == "string" then
		-- Search a single child name
		if typeof(parent) == "Instance" then
			return parent:FindFirstChild(childName) ~= nil
		elseif typeof(parent) == "table" then
			return parent[childName] ~= nil
		end
	elseif typeof(childName) == "table" then
		-- Search a table of children names
		for _, v in pairs(childName) do
			if typeof(parent) == "table" and parent[v] == nil then
				return false
			end
		end

		return true
	end

	return false
end

-- Returns the first part in the given instance
function search.getFirstPart(instance: Instance): BasePart?
	assert(typeof(instance) == "Instance", "instance argument must be an Instance")

	local children = instance:GetChildren() :: { [number]: BasePart | Instance }

	if not children or #children == 0 then
		return
	end

	local index: number = 1
	local current: Instance = nil

	while index < #children do
		current = children[index]

		if current and current:IsA("BasePart") then
			local result: BasePart = current
			return result
		end

		index += 1
	end

	return nil
end

return search
