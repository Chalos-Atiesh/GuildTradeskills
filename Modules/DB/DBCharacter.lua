local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local DBCharacter = GT:NewModule('DBCharacter')
GT.DBCharacter = DBCharacter

DBCharacter.valid = true

function DBCharacter:OnEnable()
	DBCharacter.db = DBCharacter.db or LibStub('AceDB-3.0'):New('GTDB')

	if DBCharacter.db.char.characters == nil or force then
		DBCharacter.db.char.characters = {}
	end

	--@debug@
	-- DBCharacter.db.char.characters = {}
	--@end-debug@

	DBCharacter.valid = DBCharacter:Validate()
end

function DBCharacter:Reset()
	GT.Log:Info('DBCharacter_Reset')
	DBCharacter.db.char.characters = {}

	DBCharacter:AddCharacter(GT:GetCharacterName())
end
----- CHARACTER START -----

function DBCharacter:CharacterExists(characterName)
	if characterName == nil then return false end
	characterName = string.lower(characterName)

	local characters = DBCharacter.db.char.characters
	for tempCharacterName, _ in pairs(characters) do
		if string.lower(tempCharacterName) == characterName then
			return true
		end
	end
	return false
end

function DBCharacter:GetCharacters()
	return DBCharacter.db.char.characters
end

function DBCharacter:GetCharacter(characterName)
	if not DBCharacter:CharacterExists(characterName) then return nil end
	characterName = string.lower(characterName)

	local characters = DBCharacter:GetCharacters()
	for tempCharacterName, character in pairs(characters) do
		if string.lower(tempCharacterName) == characterName then
			return character
		end
	end
	return nil
end

function DBCharacter:AddCharacter(characterName)
	if characterName == nil then return nil end

	local characters = DBCharacter:GetCharacters()
	characters = Table:InsertField(characters, characterName)

	local character = DBCharacter:GetCharacter(characterName)

	character.characterName = characterName
	character.isGuildMember = true
	character.isBroadcasted = false
	character.class = 'UNKNOWN'
	character.lastCommReceived = time()

	if character.professions == nil then
		character.professions = {}
	end

	if character.deletedProfessions == nil then
		character.deletedProfessions = {}
	end
	return character
end

function DBCharacter:DeleteCharacter(characterName)
	if not DBCharacter:CharacterExists(characterName) then return false end
	characterName = string.lower(characterName)

	local characters = DBCharacter:GetCharacters()
	for tempCharacterName, _ in pairs(characters) do
		if string.lower(tempCharacterName) == characterName then
			characters[tempCharacterName] = nil
			return true
		end
	end
	return false
end

----- CHARACTER END -----
----- PROFESSION START -----

function DBCharacter:ProfessionExists(characterName, professionName)
	if professionName == nil then return false end
	if not DBCharacter:CharacterExists(characterName)then return false end
	professionName = string.lower(professionName)

	local professions = DBCharacter:GetCharacter(characterName).professions
	for tempProfessionName, _ in pairs(professions) do
		if string.lower(tempProfessionName) == professionName then
			return true
		end
	end
	return false
end

function DBCharacter:GetProfessions(characterName)
	if not DBCharacter:CharacterExists(characterName) then return nil end
	return DBCharacter:GetCharacter(characterName).professions
end

function DBCharacter:GetProfession(characterName, professionName)
	if not DBCharacter:ProfessionExists(characterName, professionName) then return nil end
	professionName = string.lower(professionName)

	local professions = DBCharacter:GetProfessions(characterName)
	for tempProfessionName, profession in pairs(professions) do
		if string.lower(tempProfessionName) == professionName then
			return profession
		end
	end
	return nil
end

function DBCharacter:AddProfession(characterName, professionName)
	if professionName == nil then return nil end
	if not DBCharacter:CharacterExists(characterName) then return nil end

	local character = DBCharacter:GetCharacter(characterName)
	character.deletedProfessions = Table:RemoveByValue(character.deletedProfessions, professionName)

	local professions = DBCharacter:GetProfessions(characterName, professionName)
	professions = Table:InsertField(professions, professionName)

	local profession = DBCharacter:GetProfession(characterName, professionName)

	profession.professionName = professionName
	profession.lastUpdate = time()

	if profession.skills == nil then
		profession.skills = {}
	end
	return profession
end

function DBCharacter:DeleteProfession(characterName, professionName)
	if not DBCharacter:ProfessionExists(characterName, professionName) then return false end
	professionName = string.lower(professionName)

	local professions = DBCharacter:GetProfessions(characterName)
	for tempProfessionName, _ in pairs(professions) do
		if string.lower(tempProfessionName) == professionName then
			character.deletedProfessions = Table:Insert(character.deletedProfessions, nil, professionName)
			professions[tempProfessionName] = nil
			return true
		end
	end
	return false
end

----- PROFESSION END -----
----- SKILL CHARACTER START -----

function DBCharacter:HasSkill(characterName, skillName)
	if skillName == nil then return false end
	if not DBCharacter:CharacterExists(characterName) then return false end
	skillName = string.lower(skillName)

	local professions = DBCharacter:GetProfessions(characterName)
	for professionName, _ in pairs(professions) do
		local skills = DBCharacter:GetSkills(characterName, professionName)
		for _, tempSkillName in pairs(skills) do
			if string.lower(tempSkillName) == skillName then
				return true
			end
		end
	end
	return false
end

function DBCharacter:SkillExists(characterName, professionName, skillName)
	if skillName == nil then return false end
	if not DBCharacter:ProfessionExists(characterName, professionName) then return false end
	skillName = string.lower(skillName)

	local skills = DBCharacter:GetSkills(characterName, professionName)
	for _, tempSkillName in pairs(skills) do
		if string.lower(tempSkillName) == skillName then
			return true
		end
	end
	return false
end

function DBCharacter:GetSkills(characterName, professionName)
	if not DBCharacter:ProfessionExists(characterName, professionName) then return nil end
	return DBCharacter:GetProfession(characterName, professionName).skills
end

function DBCharacter:GetSkill(characterName, professionName, skillName)
	if not DBCharacter:SkillExists(characterName, professionName, skillName) then return nil end
	skillName = string.lower(skillName)

	local skills = DBCharacter:GetSkills(characterName, professionName)
	for tempSkillName, skill in pairs(skills) do
		if string.lower(tempSkillName) == skillName then
			return skill
		end
	end
	return nil
end

function DBCharacter:AddSkill(characterName, professionName, skillName)
	if skillName == nil then return nil end
	if not DBCharacter:ProfessionExists(characterName, professionName) then return nil end

	local skills = DBCharacter:GetSkills(characterName, professionName)
	skills = Table:Insert(skills, nil, skillName)

	return skillName
end

function DBCharacter:DeleteSkill(characterName, professionName, skillName)
	if not DBCharacter:SkillExists(characterName, professionName, skillName) then return false end
	skillName = string.lower(skillName)

	local skills = DBCharacter:GetSkills(characterName, professionName)
	for tempSkillName, _ in pairs(skills) do
		if string.lower(tempSkillName) == skillName then
			skills[tempSkillName] = nil
			return true
		end
	end
	return false
end

----- SKILL CHARACTER END -----
----- VALIDATION START -----

function DBCharacter:Validate()
	DBCharacter:ValidateStructure()
	return DBCharacter:ValidateData()
end

function DBCharacter:ValidateStructure()
	local characters = DBCharacter.db.char.characters
	for characterName, character in pairs(characters) do
		if character.professions == nil then
			character.professions = {}
		end

		local professions = character.professions
		for professionName, profession in pairs(professions) do
			if profession.skills == nil then
				profession.skills = {}
			end
		end
	end
end

function DBCharacter:ValidateData()
	local valid = true

	local characters = DBCharacter.db.char.characters
	for characterName, character in pairs(characters) do
		if Text:IsNumber(characterName) or Text:IsLink(characterName) then
			GT.Log:Error('DBCharacter_ValidateData_InvalidCharacterName', characterName)
			valid = false
		end

		if character.characterName == nil then
			character.characterName = characterName
		end

		local tempCharacterName = character.characterName
		if Text:IsNumber(tempCharacterName) or Text:IsLink(tempCharacterName) then
			GT.Log:Error('DBCharacter_ValidateData_InvalidCharacter_CharacterName', tempCharacterName)
		end
		if character.isGuildMember == nil then
			character.isGuildMember = true
		end
		if character.isBroadcasted == nil then
			character.isBroadcasted = false
		end
		if character.lastCommReceived == nil then
			character.lastCommReceived = time()
		end

		if character.professions == nil then
			character.professions = {}
		end

		for professionName, profession in pairs(character.professions) do
			if Text:IsNumber(professionName) or Text:IsLink(professionName) then
				GT.Log:Error('DBCharacter_ValidateData_InvalidProfessionName', professionName)
				valid = false
			end

			if profession.professionName == nil then
				profession.professionName = professionName
			end

			local tempProfessionName = profession.professionName
			if Text:IsNumber(tempProfessionName) or Text:IsLink(tempProfessionName) then
				GT.Log:Error('DBCharacter_ValidateData_InvalidProfession_ProfessionName', tempProfessionName)
				valid = false
			end

			local skills = profession.skills
			for _, skillName in pairs(skills) do
				if Text:IsNumber(skillName) or Text:IsLink(skillName) then
					GT.Log:Error('DBCharacter_ValidateData_InvalidSkillName', skillName)
					valid = false
				end
			end
		end
	end
	return valid
end