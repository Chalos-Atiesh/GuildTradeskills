local GT_Name, GT = ...

GT.textUtils = {}

function GT.textUtils.tokenize(text, delimiter)
    local tokens = {}
    local token = ''
    for i = 1, #text do
        local c = text:sub(i, i)
        if c == delimiter then
            table.insert(tokens, token)
            token = ''
        else
            token = token .. c
        end
    end
    table.insert(tokens, token)
    return tokens
end

function GT.textUtils.getTextBetween(text, startCharacter, endCharacter)
    if not string.find(text, startCharacter) or not string.find(text, endCharacter) then
        return text
    end
    local startIndex = string.find(text, startCharacter)
    local endIndex = string.find(text, endCharacter)
    return string.sub(text, startIndex + 1, endIndex - 1)
end

function GT.textUtils.convertCharacterName(characterName)
    characterName = GT.textUtils.getTextBetween(characterName, '%[', ']')
    if not string.find(characterName, '-') then
        return characterName
    end
    local dashIndex = string.find(characterName, '-')
    return string.sub(characterName, 1, dashIndex - 1)
end

function GT.textUtils.textValue(value)
    if value == nil then
        return 'nil'
    end
    if type(value) == 'boolean' then
        if value then
            return 'true'
        else
            return 'false'
        end
    end
    return value
end

function GT.textUtils.concat(start, delimiter, ...)
    local txt = start
    local args = {...}
    local actualDelimiter = nil
    for i = 1, #args do
        if start == nil and actualDelimiter == nil then
            txt = ''
            actualDelimiter = ''
        else
            actualDelimiter = delimiter
        end
        local arg = args[i]
        if arg == nil then
            txt = txt .. actualDelimiter .. 'nil'
        elseif type(arg) == 'string' then
            txt = txt .. actualDelimiter .. args[i]
        elseif type(arg) == 'boolean' then
            if arg then
                txt = txt .. actualDelimiter .. 'true'
            else
                txt = txt .. actualDelimiter .. 'false'
            end
        elseif type(arg) == 'number' then
            txt = txt .. actualDelimiter .. tostring(arg)
        elseif type(arg) == 'table' then
            txt = txt .. actualDelimiter .. '{'
            for k, v in pairs(arg) do
                local key = GT.textUtils.concat(nil, ',', k)
                local value = GT.textUtils.concat(nil, ',', v)
                txt = txt .. '{' .. key .. ':' .. value .. '}'
            end
            txt = txt .. '}'
        elseif type(arg) == 'function' then
            txt = txt .. actualDelimiter .. 'function'
        end
    end
    return txt
end