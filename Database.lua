local GT_Name, GT = ...

GT.database = {}
GT.database.state = {}
GT.database.state.initialized = false
GT.database.state.currentCharacter = nil

function GT.database.init(force)
	if GT.database.state.initialized and not force then
		return
	end
	GT.logging.info('GT_Database_Init')

	if GT_DB == nil then
		GT.logging.info(GT.L['DATABASE_CREATE'])
		GT_DB = {}
	end

	local realmName = GetRealmName()
	if realmName == nil then
		GT.logging.error(GT.L['ERROR_NIL_REALM'])
		return
	end
	if GT_DB.realms == nil then
		GT.logging.info(GT.L['DATABASE_REALM_CREATE'])
		GT_DB.realms = {}
	end
	if GT_DB.realms[realmName] == nil then
		GT.logging.info(GT.L['DATABASE_REALM_UPDATE'] .. realmName)
		GT_DB.realms[realmName] = {}
	end

	local realm = GT_DB.realms[realmName]
	local _, factionName = UnitFactionGroup('player')
	if factionName == nil then
		GT.logging.error(GT.L['ERROR_NIL_FACTION'])
		return
	end
	if realm.factions == nil then
		GT.logging.info(GT.L['DATABASE_FACTION_CREATE'])
		realm.factions = {}
	end
	if realm.factions[factionName] == nil then
		GT.logging.info(GT.L['DATABASE_FACTION_UPDATE'] .. factionName)
		realm.factions[factionName] = {}
	end

	local faction = realm.factions[factionName]
	local guildName = GetGuildInfo('player')
	if guildName == nil then
		GT.logging.error(GT.L['ERROR_NIL_GUILD'])
		return
	end
	if faction.guilds == nil then
		GT.logging.info(GT.L['DATABASE_GUILD_CREATE'])
		faction.guilds = {}
	end
	if faction.guilds[guildName] == nil then
		GT.logging.info(GT.L['DATABASE_GUILD_UPDATE'] .. guildName)
		faction.guilds[guildName] = {}
	end

	local guild = faction.guilds[guildName]
	local characterName = UnitName('player')
	if characterName == nil then
		GT.logging.error(GT.L['ERROR_NIL_NAME'])
		return
	end
	if guild.characters == nil then
		GT.logging.info(GT.L['DATABASE_CHARACTER_CREATE'])
		guild.characters = {}
	end
	if guild.characters[characterName] == nil then
		GT.logging.info(GT.L['DATABASE_CHARACTER_UPDATE'] .. characterName)
		guild.characters[characterName] = {}
	end

	local character = guild.characters[characterName]
	if character.professions == nil then
		GT.logging.info(GT.L['DATABASE_PROFESSION_CREATE'])
		character.professions = {}
	end

	GT.database.state.initialized = true
end

function GT.database.drillDown(realmName, factionName, guildName, characterName, professionName, skillName, reagentName)
	if GT_DB.realms[realmName] == nil then return nil end
	local realm = GT_DB.realms[realmName]
	if factionName == nil then return realm end

	if realm.factions[factionName] == nil then return nil end
	local faction = realm.factions[factionName]
	if guildName == nil then return faction end

	if faction.guilds == nil or faction.guilds[guildName] == nil then return nil end
	local guild = faction.guilds[guildName]
	if characterName == nil then return guild end

	if guild.characters[characterName] == nil then return nil end
	local character = guild.characters[characterName]
	if professionName == nil then return character end

	if character.professions[professionName] == nil then return nil end
	local profession = character.professions[professionName]
	if skillName == nil then return profession end

	if profession.skills[skillName] == nil then return nil end
	local skill = profession.skills[skillName]
	if reagentName == nil then return skill end

	if skill.reagents[reagentName] == nil then return nil end
	return skill.reagents[skillName]
end

function GT.database.getGuild(realmName, factionName, guildName)
	return GT.database.drillDown(realmName, factionName, guildName)
end

function GT.database.getCharacter(realmName, factionName, guildName, characterName)
	return GT.database.drillDown(realmName, factionName, guildName, characterName)
end

function GT.database.addCharacter(realmName, factionName, guildName, characterName)
	GT.logging.info('GT_Database_AddCharacter: ' .. guildName .. ', ' .. characterName)
	local characters = GT.database.drillDown(realmName, factionName, guildName).characters
	characters[characterName] = {}
	characters[characterName].professions = {}
	return characters[characterName]
end

function GT.database.getProfessions(realmName, factionName, guildName, characterName)
	local character = GT.database.drillDown(realmName, factionName, guildName, characterName)
	if character == nil then return nil end
	return character.professions
end

function GT.database.getProfession(realmName, factionName, guildName, characterName, professionName)
	local professions = GT.database.getProfessions(realmName, factionName, guildName, characterName)
	if professions == nil then return nil end
	if professions[professionName] == nil then return nil end
	return professions[professionName]
end

function GT.database.addProfession(realmName, factionName, guildName, characterName, professionName)
	GT.logging.info('GT_Database_AddProfession: ' .. guildName .. ', ' .. characterName .. ', ' .. professionName)
	local character = GT.database.getCharacter(realmName, factionName, guildName, characterName)
	character.professions[professionName] = {}
	local profession = character.professions[professionName]
	profession.skills = {}
	profession.lastUpdate = time()
	return profession
end

function GT.database.removeProfession(realmName, factionName, guildName, characterName, professionName)
	GT.logging.info('GT_Database_RemoveProfession: ' .. guildName .. ', ' .. characterName .. ', ' .. professionName)
	local character = GT.database.getCharacter(realmName, factionName, guildName, characterName)
	table.remove(character.professions, professionName)
end

function GT.database.getSkills(realmName, factionName, guildName, characterName, professionName)
	local profession = GT.database.drillDown(realmName, factionName, guildName, characterName, professionName)
	if profession == nil then return nil end
	return profession.skills
end

function GT.database.getSkill(realmName, factionName, guildName, characterName, professionName, skillName)
	local skills = GT.database.getSkills(realmName, factionName, guildName, characterName, professionName)
	if skills == nil then return nil end
	if skills[skillName] == nil then return nil end
	return skills[skillName]
end

function GT.database.addSkill(realmName, factionName, guildName, characterName, professionName, skillName, skillLink)
	local profession = GT.database.getProfession(realmName, factionName, guildName, characterName, professionName)
	profession.skills[skillName] = {}
	local skill = profession.skills[skillName]
	skill.reagents = {}
	skill.skillName = skillName
	skill.skillLink = skillLink
	return skill
end

function GT.database.removeSkill(realmName, factionName, guildName, characterName, professionName, skillName)
	GT.logging.info('GT_Database_RemoveSkill: ' .. guildName .. ', ' .. characterName .. ', ' .. professionName .. ', ' .. skillName)
end

function GT.database.getReagents(realmName, factionName, guildName, characterName, professionName, skillName)
	local skill = GT.database.drillDown(realmName, factionName, guildName, characterName, professionName, skillName)
	return skill.reagents
end

function GT.database.getReagent(realmName, factionName, guildName, characterName, professionName, skillName, reagentName)
	return GT.database.drillDown(realmName, factionName, guildName, characterName, professionName, skillName, reagentName)
end

function GT.database.addReagent(realmName, factionName, guildName, characterName, professionName, skillName, reagentName, reagentCount)
	local skill = GT.database.drillDown(realmName, factionName, guildName, characterName, professionName, skillName)
	local reagents = skill.reagents
	reagents[reagentName] = {}
	local reagent = reagents[reagentName]
	reagent.reagentName = reagentName
	reagent.reagentCount = reagentCount
	reagent.isHidden = false
	return reagent
end

function GT.database.reset()
	GT.logging.info('GT_Database_Reset')
	GT_DB = nil
	GT.database.init(true)
end