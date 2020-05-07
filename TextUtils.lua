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