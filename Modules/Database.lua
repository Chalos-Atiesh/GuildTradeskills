local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnName, true)

local DB = GT:NewModule('Database')
GT.DB = DB

function DB:OnEnable(force)
	if force == nil then
		force = false
	end
	-- GT.Log:Info('DB_OnEnable', force)

	DB.db = LibStub('AceDB-3.0'):New('GTDB')

	if DB.db.char == nil or force then
		DB.db.char = {}
	end

	if DB.db.global == nil or force then
		DB.db.global = {}
	end

	if DB.db.char.characters == nil or force then
		DB.db.char.characters = {}
	end

	if DB.db.char.professions == nil or force then
		DB.db.char.professions = {}
	end

	if DB.db.char.search == nil then
		DB.db.char.search = {}
	end

	if DB.db.global.professions == nil or force then
		DB.db.global.professions = {}
	end

	GT.Comm:SendTimestamps()
	GT.Comm:SendVersion()

	GT.Log:PlayerInfo(L['WELCOME'])
end

function DB:Reset()
	GT.Log:Info('DB_Reset')
	DB.db.char.characters = {}
end

function DB:GetSearch(searchField)
	if DB.db.char.search[searchField] == nil then
		return nil
	end
	return DB.db.char.search[searchField]
end

function DB:SetSearch(searchField, searchTerm)
	DB.db.char.search[searchField] = searchTerm
end

function DB:GetCharacters()
	-- GT.Log:Info('DB_GetCharacters')
	return DB.db.char.characters
end

function DB:GetProfessions()
	-- GT.Log:Info('DB_GetProfessions')
	return DB.db.global.professions
end

function DB:GetCharacter(characterName)
	-- GT.Log:Info('DB_GetCharacter', characterName)
	if DB.db.char.characters[characterName] == nil then
		return DB:AddCharacter(characterName)
	end
	return DB.db.char.characters[characterName]
end

function DB:AddCharacter(characterName)
	-- GT.Log:Info('DB_AddCharacter', characterName)
	if DB.db.char.characters[characterName] == nil then
		DB.db.char.characters[characterName] = {}
	end

	local character = DB.db.char.characters[characterName]
	character.characterName = characterName
	if character.professions == nil then
		character.professions = {}
	end

	if character.deletedProfessions == nil then
		character.deletedProfessions = {}
	end
	return character
end

function DB:GetProfession(characterName, professionName)
	-- GT.Log:Info('DB_GetProfession', characterName, professionName)

	DB:_GetProfession(professionName)

	local professions = DB:GetCharacter(characterName).professions
	if professions[professionName] == nil then
		-- GT.Log:Info('DB_GetProfession_Nil', characterName, professionName)
		return nil
	end
	return professions[professionName]
end

function DB:GetProfessions()
	return DB.db.global.professions
end

function DB:_GetProfession(professionName)
	-- GT.Log:Info('DB__GetProfession', professionName)
	if DB.db.global.professions[professionName] == nil then
		-- GT.Log:Info('DB__GetProfession_NilProfession', professionName)
		DB.db.global.professions[professionName] = {}
	end
	local profession = DB.db.global.professions[professionName]
	if profession.skills == nil then
		profession.skills = {}
	end
	return profession
end

function DB:AddProfession(characterName, professionName)
	-- GT.Log:Info('DB_AddProfession', characterName, professionName)

	DB:_GetProfession(professionName)
	-- GT.Log:Info(DB:GetProfessions())

	local character = DB:GetCharacter(characterName)
	character.deletedProfessions = GT.Table:RemoveByValue(character.deletedProfessions, professionName)
	local professions = character.professions
	if professions[professionName] == nil then
		professions[professionName] = {}
		professions[professionName].professionName = professionName
		professions[professionName].lastUpdate = time()
	end
	local profession = professions[professionName]
	if profession.skills == nil then
		profession.skills = {}
	end
	return profession
end

function DB:DeleteProfession(characterName, professionName)
	-- GT.Log:Info('DB_DeleteProfession', characterName, professionName)
	local character = DB:GetCharacter(characterName)
	for dbProfessionName, _ in pairs(character.professions) do
		if dbProfessionName == professionName then
			table.insert(character.deletedProfessions, professionName)
			character.professions[professionName] = nil
			return true
		end
	end
	return false
end

function DB:GetSkill(characterName, professionName, skillName)
	-- GT.Log:Info('DB_GetSkill', characterName, professionName, skillName)

	DB:_GetSkill(professionName, skillName)

	profession = DB:GetProfession(characterName, professionName)
	if profession == nil then
		-- GT.Log:Info('DB_GetSkill_ProfessionNil', characterName, professionName, skillName)
		return nil
	end
	if not GT.Table:Contains(profession.skills, skillName) then
		-- GT.Log:Info('DB_GetSkill_SkillNil', characterName, professionName, skillName)
		return nil
	end
	return DB:_GetSkill(professionName, skillName)
end

function DB:_GetSkill(professionName, skillName, skillLink)
	-- GT.Log:Info('DB__GetSkill', professionName, skillName, skillLink)
	local profession = DB:_GetProfession(professionName)
	if profession.skills[skillName] == nil then
		profession.skills[skillName] = {}
	end
	local skill = profession.skills[skillName]
	skill.skillName = skillName
	if skillLink then
		skill.skillLink = skillLink
	end
	if skill.reagents == nil then
		skill.reagents = {}
	end
	return skill
end

function DB:AddSkill(characterName, professionName, skillName, skillLink)
	-- GT.Log:Info('DB_AddSkill', characterName, professionName, skillName, skillLink)

	profession = DB:GetProfession(characterName, professionName)
	if profession == nil then
		GT.Log:Error('DB_AddSkill_ProfessionNil' .. characterName, professionName, skillName, skillLink)
		return nil
	end
	local skills = profession.skills
	if not GT.Table:Contains(skills, skillName) then
		table.insert(skills, skillName)
		profession.lastUpdate = time()
	end
	return DB:_GetSkill(professionName, skillName, skillLink)
end

function DB:GetReagent(professionName, skillName, reagentName)
	-- GT.Log:Info('DB_GetReagent', professionName, skillName, reagentName)
	
	return DB:_GetReagent(professionName, skillName, reagentName)
end

function DB:_GetReagent(professionName, skillName, reagentName, reagentCount)
	-- GT.Log:Info('DB__GetReagent', professionName, skillName, reagentName, reagentCount)
	local skill = DB:_GetSkill(professionName, skillName)
	if skill.reagents == nil then
		skill.reagents = {}
	end
	local reagents = skill.reagents
	if reagents[reagentName] == nil then
		reagents[reagentName] = {}
	end
	local reagent = reagents[reagentName]
	reagent.reagentName = reagentName
	if reagentCount then
		reagent.reagentCount = reagentCount
	end
	return reagent
end

function DB:AddReagent(professionName, skillName, reagentName, reagentCount)
	-- GT.Log:Info('DB_AddReagent', professionName, skillName, reagentName, reagentCount)

	return DB:_GetReagent(professionName, skillName, reagentName, reagentCount)
end

function DB:GetChatFrameNumber()
	if DB.db == nil then return 1 end
	if DB.db.global == nil then return 1 end
	if DB.db.global.chatFrameNumber == nil then return 1 end
	return DB.db.global.chatFrameNumber
end

function DB:SetChatFrameNumber(frameNumber)
	-- GT.Log:Info('DB_SetChatFrame', frameNumber)
	DB.db.global.chatFrameNumber = frameNumber
end

function DB:InitVersion(version)
	GT.Log:Info('DB_InitVersion', version)
	if DB.db.global.versionNotification == nil then
		DB.db.global.versionNotification = version
	end
end

function DB:ShouldNotifyUpdate(version)
	--@debug@
	if true then
		return false
	end
	--@end-debug@
	local vNotification = DB.db.global.versionNotification
	GT.Log:Info('DB_ShouldNotifyUpdate', vNotification, version)
	if vNotification < version then
		return true
	end
	return false
end

function DB:UpdateNotified(version)
	DB.db.global.versionNotification = version
end