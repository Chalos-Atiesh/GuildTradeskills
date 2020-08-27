local TEXT_VERSION = 1

local _G = _G

if not _G.GTText then
    _G.GTText = {}
end

GTText = _G.GTText
local GTText = _G.GTText

GTText.version = TEXT_VERSION

local DEFAULT_DELIMITER = ' '
local TABLE_INDENT = '  '

function GTText:Tokenize(text, delimiter)
    delimiter = delimiter or DEFAULT_DELIMITER
    local tokens = {}
    local token = ''
    for i = 1, #text do
        local c = text:sub(i, i)
        if c == delimiter and token ~= '' then
            table.insert(tokens, token)
            token = ''
        elseif c ~= delimiter then
            token = token .. c
        end
    end
    if token ~= '' then
        table.insert(tokens, token)
    end
    return tokens
end

function GTText:Concat(delimiter, ...)
    delimiter = delimiter or DEFAULT_DELIMITER
    local args = {...}
    local txt = nil
    for i = 1, #args do
        local arg = args[i]
        if txt == nil then
            txt = GTText:ToString(arg)
        else
            txt = txt .. delimiter .. GTText:ToString(arg)
        end
    end
    if txt == nil then return 'nil' end
    return txt
end

function GTText:ToString(object)
    if object == nil then
        return 'nil'
    end
    if type(object) == 'string' then
        return object
    end
    if type(object) == 'boolean' then
        if object then
            return 'true'
        else
            return 'false'
        end
    end
    if type(object) == 'number' then
        return tostring(object)
    end
    if type(object) == 'function' then
        return 'function'
    end
    if type(object) == 'table' then
        local txt = '{'
        for k, v in pairs(object) do
            txt = txt .. '{' .. GTText:ToString(k) .. ':' .. GTText:ToString(v) .. '}'
        end
        txt = txt .. '}'
        return txt
    end
    return type(object)
end

function GTText:Lower(text)
    if text == nil then return nil end
    if type(text) ~= 'string' then return text end
    return string.lower(text)
end

function GTText:Strip(text)
    text = string.gsub(text, '|cff[%a%d][%a%d][%a%d][%a%d][%a%d][%a%d]', '')
    text = string.gsub(text, '|r', '')
    local returnText = ''
    local adding = true
    local i = 1

    while i <= #text do
        local c = string.sub(text, i, i)
        if c == '|' then
            local nextC = string.sub(text, i + 1, i + 1)
            if nextC == 'H' then
                adding = false
            elseif nextC == 'h' then
                adding = true
                i = i + 2
                c = string.sub(text, i, i)
            end
        end
        if adding then
            returnText = returnText .. c
        end
        i = i + 1
    end
    return returnText
end

function GTText:ConvertCharacterName(characterName)
    characterName = GTText:GetTextBetween(characterName, '%[', ']')
    if not string.find(characterName, '-') then
        return characterName
    end
    local dashIndex = string.find(characterName, '-')
    return string.sub(characterName, 1, dashIndex - 1)
end

function GTText:GetTextBetween(text, startCharacter, endCharacter)
    if not string.find(text, startCharacter) or not string.find(text, endCharacter) then
        return text
    end
    local startIndex = string.find(text, startCharacter)
    local endIndex = string.find(text, endCharacter)
    return string.sub(text, startIndex + 1, endIndex - 1)
end

function GTText:UUID()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    local uuid = string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
    return uuid
end

function GTText:IsUUIDValid(uuid)
    local _, countDash = string.gsub(uuid, '-', '-')
    if #uuid ~= 36 then
        GT.Log:Error('CommValidator_IsRequestValid_IvalidLength', 36, #uuid, uuid)
        return false
    end
    if countDash ~= 4 then
        GT.Log:Error('CommValidator_IsRequestValid_InvalidDashCount', 4, countDash, uuid)
        return false
    end
    return true
end

function GTText:IsNumber(str)
    if tonumber(str) ~= nil then return true end
    return false
end

function GTText:IsLink(str)
    if string.find(str, ']') then return true end
    return false
end

function GTText:FormatTable(tbl)
    local txt = GTText:_FormatTable(tbl, 1)
    return txt
end

function GTText:_FormatTable(tbl, depth)
    txt = '{'
    local count = 0
    for k, v in pairs(tbl) do
        if type(k) == 'table' then
            return 'TABLES SHOULD NEVER EVER HAVE TABLES AS KEYS! WTF WERE YOU THINKING?!'
        end
        formatting = string.rep('    ', depth) .. k .. ': '
        if type(v) == 'table' then
            txt = txt .. '\n' .. formatting .. GTText:_FormatTable(v, depth + 1)
        else
            txt = txt .. '\n' .. formatting .. GTText:ToString(v)
        end
        count = count + 1
    end
    if count > 0 then
        txt = txt .. '\n' .. string.rep('    ', depth - 1)
    end
    txt = txt .. '}'
    return txt
end