local majorVersion = 'GTTable'
local minorVersion = 1

local lib, oldMinor = LibStub:NewLibrary(majorVersion, minorVersion)

function lib:RemoveToken(tokens)
	if tokens == nil then return nil, {} end
	for i = 1, #tokens do
		local token = tokens[1]
		table.remove(tokens, 1)
		return token, tokens
	end
	return nil, {}
end

function lib:RemoveByValue(tbl, value, valueIsKey)
	local returnTable = {}
	for k, v in pairs(tbl) do
		if valueIsKey and k ~= value then
			if tonumber(k) == nil then
				returnTable[k] = v
			else
				table.insert(returnTable, v)
			end
		elseif not valueIsKey and v ~= value then
			if tonumber(k) == nil then
				returnTable[k] = v
			else
				table.insert(returnTable, v)
			end
		end
	end
	return returnTable
end

function lib:Contains(tbl, value)
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

function lib:GetSortedKeys(tbl, sortFunction, sortByKey)
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

function lib:Lower(tbl)
	local returnTable = {}
	for k, v in pairs(tbl) do
		if type(k) == 'table' then
			k = lib:Lower(tbl)
		end
		if type(v) == 'table' then
			v = lib:Lower(tbl)
		end
		returnTable[k] = v
	end
	return returnTable
end