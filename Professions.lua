local GT_Name, GT = ...

GT.professions = {}
GT.professions.state = {}
GT.professions.state.initialized = false
GT.professions.state.adding = false

function GT.professions.initAdd()
	if not GT.professions.state.adding then
		GT.logging.playerInfo(GT.L['PROFESSION_ADD_INIT'])
		GT.professions.state.adding = true
	else
		GT.logging.playerInfo(GT.L['PROFESSION_ADD_CANCEL'])
		GT.professions.state.adding = false
	end
end

function GT.professions.addProfession()
	GT.logging.info('GT_Professions_AddProfession')
	local professionName = GetTradeSkillLine()
	if professionName == 'UNKNOWN' then
		professionName = GetCraftDisplaySkillLine()
	end
	if professionName == nil then
		return
	end
	if GT.professions.state.adding then
		GT.player.init()
		GT.database.init()
		local profession = GT.database.getProfession(
			GT_Character.realmName,
			GT_Character.factionName,
			GT_Character.guildName,
			GT_Character.characterName,
			professionName
		)
		if profession == nil then
			GT.database.addProfession(
				GT_Character.realmName,
				GT_Character.factionName,
				GT_Character.guildName,
				GT_Character.characterName,
				professionName
			)
		end
		local msg = GT.L['PROFESSION_ADD_SUCCESS']
		msg = string.gsub(msg, '%{{character_name}}', GT_Character.characterName)
		msg = string.gsub(msg, '%{{profession_name}}', professionName)
		GT.logging.playerInfo(msg)
	end

	GT.professions.updateProfession(professionName)
	if GT.professions.state.adding then
	    CloseTradeSkill()
	    CloseCraft()
	end

	GT.professions.state.adding = false
end

function GT.professions.updateProfession(professionName)
	if professionName == nil then
		return
	end
	local GetNumTradeSkills = GetNumTradeSkills
	local GetTradeSkillInfo = GetTradeSkillInfo
	local GetTradeSkillItemLink = GetTradeSkillItemLink
	local GetTradeSkillNumReagents = GetTradeSkillNumReagents
	local GetTradeSkillReagentInfo = GetTradeSkillReagentInfo

	if professionName == 'Enchanting' then
		GetNumTradeSkills = GetNumCrafts
		GetTradeSkillItemLink = GetCraftItemLink
		GetTradeSkillNumReagents = GetCraftNumReagents
		GetTradeSkillReagentInfo = GetCraftReagentInfo

		GetTradeSkillInfo = function(i)
			local name, _, kind, num = GetCraftInfo(i)

			return name, kind, num
		end
	end

	local profession = GT.database.getProfession(
		GT_Character.realmName,
		GT_Character.factionName,
		GT_Character.guildName,
		GT_Character.characterName,
		professionName
	)
	if profession == nil then
		return
	end
	profession.lastUpdate = time()
	GT.logging.info('GT_Professions_UpdateProfession: ' .. professionName)
	for i = 1, GetNumTradeSkills() do
		local skillName, kind, num = GetTradeSkillInfo(i)
		
		if kind and kind ~= 'header' and kind ~= 'subheader' then
			local skillLink = GetTradeSkillItemLink(i)
			local skill = GT.database.getSkill(
				GT_Character.realmName,
				GT_Character.factionName,
				GT_Character.guildName,
				GT_Character.characterName,
				professionName,
				skillName
			)
			if skill == nil then
				GT.database.addSkill(
					GT_Character.realmName,
					GT_Character.factionName,
					GT_Character.guildName,
					GT_Character.characterName,
					professionName,
					skillName,
					skillLink
				)
			end

			for j = 1, GetTradeSkillNumReagents(i) do
				local reagentName, _, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(i, j)

				if reagentName then
					local reagent = GT.database.getReagent(
						GT_Character.realmName,
						GT_Character.factionName,
						GT_Character.guildName,
						GT_Character.characterName,
						professionName,
						skillName,
						reagentName
					)
					if reagent == nil then
						GT.database.addReagent(
							GT_Character.realmName,
							GT_Character.factionName,
							GT_Character.guildName,
							GT_Character.characterName,
							professionName,
							skillName,
							reagentName,
							reagentCount
						)
					end
				end
			end
		end
	end
	GT.comm.sendTimestamps()
end

function GT.professions.removeProfession(tokens)
	GT.player.init()
	GT.database.init()
	local professionNameToRemove = tokens[1]
	tokens = GT.tableUtils.removeToken(tokens)
	if professionNameToRemove == nil then
		GT.logging.playerError(GT.L['PROFESSION_REMOVE_NIL_PROFESSION'])
		return
	end
	GT.logging.info('GT_Professions_RemoveProfession: ' .. GT_Character.characterName .. ', ' .. professionNameToRemove)

	local character = GT.database.getCharacter(
		GT_Character.realmName,
		GT_Character.factionName,
		GT_Character.guildName,
		GT_Character.characterName
	)
	local professions = character.professions
	local professionRemoved = false
	for professionName, _ in pairs(professions) do
		if string.lower(professionName) == string.lower(professionNameToRemove) then
			GT.database.removeProfession(
				GT_Character.realmName,
				GT_Character.factionName,
				GT_Character.guildName,
				GT_Character.characterName,
				professionName
			)
			professionRemoved = true
		end
	end
	if professionRemoved then
		local msg = GT.L['PROFESSION_REMOVE_SUCCESS']
		msg = string.gsub(msg, '%{{character_name}}', GT_Character.characterName)
		msg = string.gsub(msg, '%{{profession_name}}', professionNameToRemove)
		GT.logging.playerInfo(msg)
		GT.comm.sendDeletions()
	else
		local msg = GT.L['PROFESSION_REMOVE_PROFESSION_NOT_FOUND']
		msg = string.gsub(msg, '%{{character_name}}', GT_Character.characterName)
		msg = string.gsub(msg, '%{{profession_name}}', professionNameToRemove)
		GT.logging.playerError(msg)
	end
end