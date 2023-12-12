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

function search.find(parent, condition, maxRounds, round): Instance?
	if not parent or not condition then
		return
	end

	if not round then
		round = 1
	end

	local test = typeof(condition) == "string" and function(obj)
		return obj and obj.Name == condition
	end or condition

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
		for _, child in pairs(nextBatch) do
			match = search.find(child, test, maxRounds, round + 1)
		end
	end

	return match
end

function search.exists(obj, name): boolean
	if not obj then
		return false
	end

	if typeof(name) == "string" then
		return typeof(obj) == "Instance" and obj:FindFirstChild(name) or obj[name]
	elseif typeof(name) == "table" then
		for _, v in pairs(name) do
			if not obj[v] then
				return false
			end
		end

		return true
	end

	return false
end

function search.getFirstPart(model): BasePart?
	local children = typeof(model) == "table" and model or model:GetChildren()

	if not children or #children == 0 then
		return
	end

	local i = 0

	repeat
		i += 1
	until children[i]:IsA("BasePart") or i < #children

	return children[i]:IsA("BasePart") and children[i]
end

return search
