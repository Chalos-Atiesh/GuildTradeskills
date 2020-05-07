local GT_Name, GT = ...

GT.tableUtils = {}

function GT.tableUtils.removeToken(tokens)
	table.remove(tokens, 1)
	return tokens
end

function GT.tableUtils.getSortedKeys(tbl, sortFunction, sortByKey)
	local keys = {}
	for key in pairs(tbl) do
		table.insert(keys, key)
	end

	if sortByKey then
		table.sort(keys, function(a, b)
			return sortFunction(a, b)
		end)
	else
		table.sort(keys, function(a, b)
			return sortFunction(tbl[a], tbl[b])
		end)
	end

	return keys
end

function GT.tableUtils.tableContains(tbl, value)
	if tbl == nil then
		return false
	end
	for i, v in ipairs(tbl) do
		if v == value or i == value then
			return true
		end
	end

	return false
end