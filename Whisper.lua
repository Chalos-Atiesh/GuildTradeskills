local GT_Name, GT = ...

GT.whisper = {}
GT.whisper.characters = {}

local TRIGGER_CHAR = '!'
local SKILLS_PER_PAGE = 5

function GT.whisper.init()

end

function GT.whisper.onWhisperReceived(frame, event, message, sender)
	GT.logging.info(GT.textUtils.concat('GT_Whisper_OnWhisperReceived', GT.logging.DELIMITER, event, sender, message))
	-- ChatThrottleLib:SendChatMessage('ALERT', GT.comm.PREFIX, message, 'WHISPER', 'Common', sender)
	local firstChar = string.sub(message, 1, 1)
	if firstChar ~= TRIGGER_CHAR then
		GT.logging.info(GT.textUtils.concat('GT_Whisper_OnWhisperReceived_NoTrigger', GT.logging.DELIMITER, event, sender, message))
		return
	end

	local modMessage = string.sub(message, 2, #message)
	local tokens = GT.textUtils.tokenize(modMessage, ' ')
	local professionSearch, tokens = GT.tableUtils.removeToken(tokens)
	local searchTerm = table.concat(tokens, ' ')
	if searchTerm == '' then
		searchTerm = nil
	end

	if string.lower(professionSearch) == GT.L['WHISPER_HELP_ME'] then
		GT.whisper.help(sender)
		return
	end
	
	local character = GT.database.getCharacter(
		GT_Character.realmName,
		GT_Character.factionName,
		GT_Character.guildName,
		GT_Character.characterName
	)

	local professions = character.professions
	local finalProfession = nil
	local professionNames = {}
	for professionName, _ in pairs(professions) do
		table.insert(professionNames, professionName)
		if string.lower(professionName) == string.lower(professionSearch) then
			GT.logging.info(GT.textUtils.concat('GT_Whisper_OnWhisperReceived_ProfFound', GT.logging.DELIMITER, event, sender, message, professionName))
			finalProfession = professionName
			break
		end
	end

	if finalProfession == nil then
		local returnMessage = string.gsub(GT.L['WHISPER_PROFESSION_NOT_FOUND'], '%{{profession_name}}', professionSearch)
		if #professionNames <= 0 then
			table.insert(professionNames, 'none')
		end
		returnMessage = string.gsub(returnMessage, '%{{profession_names}}', table.concat(professionNames, ', '))
		GT.logging.info(GT.textUtils.concat('GT_Whisper_OnWhisperReceived_ProfNotFound', GT.logging.DELIMITER, event, sender, message, returnMessage))
		ChatThrottleLib:SendChatMessage('ALERT', GT.comm.PREFIX, returnMessage, 'WHISPER', 'Common', sender)
		return
	end

	GT.whisper.sendResponse(sender, finalProfession, searchTerm)
end

function GT.whisper.help(recipient)
	GT.logging.info(GT.textUtils.concat('GT_Whisper_Help', GT.logging.DELIMITER, recipient))
	local professions = GT.database.getCharacter(
		GT_Character.realmName,
		GT_Character.factionName,
		GT_Character.guildName,
		GT_Character.characterName
	).professions

	local hasFirstProfession = false
	local hasSecondProfession = false
	local firstProfessionName = nil
	local secondProfessionName = nil
	local firstSkillCount = 0
	local secondSkillCount = 0

	for professionName, _ in pairs(professions) do
		if not hasFirstProfession then
			hasFirstProfession = true
			firstProfessionName = professionName
		else
			hasSecondProfession = true
			secondProfessionName = professionName
		end
		local skills = professions[professionName].skills
		for skillName, _ in pairs(skills) do
			if hasSecondProfession then
				secondSkillCount = secondSkillCount + 1
			else
				firstSkillCount = firstSkillCount + 1
			end
		end
	end

	local firstMsg = ''
	if hasFirstProfession then
		firstMsg = string.gsub(GT.L['WHISPER_FIRST_PROFESSION'], '%{{skill_count}}', firstSkillCount)
		firstMsg = string.gsub(firstMsg, '%{{profession_name}}', firstProfessionName)
	end
	local secondMsg = ''
	if hasSecondProfession then
		secondMsg = string.gsub(GT.L['WHISPER_SECOND_PROFESSION'], '%{{skill_count}}', secondSkillCount)
		secondMsg = string.gsub(secondMsg, '%{{profession_name}}', secondProfessionName)
	end

	local msg = string.gsub(GT.L['WHISPER_HELP'], '%{{first_profession}}', firstMsg)
	msg = string.gsub(msg, '%{{second_profession}}', secondMsg)
	if hasFirstProfession then
		msg = msg .. '.'
	end
	GT.logging.info(GT.textUtils.concat('GT_Whisper_HelpSend', GT.logging.DELIMITER, recipient, msg))
	ChatThrottleLib:SendChatMessage('ALERT', GT.comm.PREFIX, msg, 'WHISPER', 'Common', recipient)
end

function GT.whisper.sendResponse(recipient, professionName, searchTerm)
	GT.logging.info(GT.textUtils.concat('GT_Whisper_SendResponse', GT.logging.DELIMITER, recipient, professionName))

	if tonumber(searchTerm) == nil then
		GT.whisper.sendInitialResponse(recipient, professionName, searchTerm)
	else
		GT.whisper.sendPagedResponse(recipient, professionName, searchTerm)
	end
end

function GT.whisper.sendInitialResponse(recipient, professionName, searchTerm)
	GT.logging.info(GT.textUtils.concat('GT_Whisper_SendInitialResponse', GT.logging.DELIMITER, recipient, professionName, searchTerm))
	if GT.whisper.characters[recipient] == nil then
		GT.whisper.characters[recipient] = {}
	end
	local character = GT.whisper.characters[recipient]
	character[professionName] = {}
	character[professionName].searchTerm = searchTerm

	local returnSkills = GT.whisper._searchSkills(professionName, searchTerm)
	GT.whisper._sendResponse(recipient, professionName, returnSkills, 1)
end

function GT.whisper.sendPagedResponse(recipient, professionName, page)
	GT.logging.info(GT.textUtils.concat('GT_Whisper_SendPagedResponse', GT.logging.DELIMITER, recipient, professionName, page))

	if GT.whisper.characters[recipient] == nil then
		GT.whisper.sendInitialResponse(recipient, professionName, nil)
		return
	end

	local whisperCharacter = GT.whisper.characters[recipient]
	if whisperCharacter[professionName] == nil then
		GT.whisper.sendInitialResponse(recipient, professionName, nil)
		return
	end
	local whisperProfession = whisperCharacter[professionName]
	local searchTerm = whisperProfession.searchTerm

	local returnSkills = GT.whisper._searchSkills(professionName, searchTerm)
	GT.whisper._sendResponse(recipient, professionName, returnSkills, page)
end

function GT.whisper._sendResponse(recipient, professionName, skills, page)
	page = tonumber(page)
	skillCount = 0
	for k, v in pairs(skills) do
		skillCount = skillCount + 1
	end
	GT.logging.info(GT.textUtils.concat('GT_Whisper_SendResponse', GT.logging.DELIMITER, recipient, professionName, page, skills))
	local totalPages = math.ceil(skillCount / SKILLS_PER_PAGE)
	local firstIndex = (page - 1) * SKILLS_PER_PAGE
	local lastIndex = firstIndex + SKILLS_PER_PAGE

	if lastIndex > skillCount then
		GT.logging.info(GT.textUtils.concat('GT_Whisper_SendResponse_PageNotFull', GT.logging.DELIMITER, recipient, professionName, page, skillCount, skills))
		lastIndex = skillCount
	end

	if firstIndex > skillCount then
		local msg = string.gsub(GT.L['WHISPER_INVALID_PAGE'], '%{{page}}', tostring(page))
		msg = string.gsub(msg, '%{{max_pages}}', totalPages)
		GT.logging.info(GT.textUtils.concat('GT_Whisper_SendResponse_InvalidPage', GT.logging.DELIMITER, recipient, professionName, msg))
		ChatThrottleLib:SendChatMessage('ALERT', GT.comm.PREFIX, msg, 'WHISPER', 'Common', recipient)
		return
	end

	if totalPages > 1 then
		local msg = string.gsub(GT.L['WHISPER_HEADER'], '%{{current_page}}', page)
		msg = string.gsub(msg, '%{{total_pages}}', tostring(totalPages))
		msg = string.gsub(msg, '%{{total_skills}}', tostring(skillCount))
		GT.logging.info(GT.textUtils.concat('GT_Whisper_SendResponse_Header', GT.logging.DELIMITER, recipient, professionName, searchTerm, msg))
		ChatThrottleLib:SendChatMessage('ALERT', GT.comm.PREFIX, msg, 'WHISPER', 'Common', recipient)
	end

	local count = firstIndex
	local i = 0
	local sortedKeys = GT.tableUtils.getSortedKeys(skills, function(a, b) return a < b end, true)
	for _, key in ipairs(sortedKeys) do
		if i + 1 > firstIndex and i < lastIndex then
			local skillLink = skills[key]
			msg = string.gsub(GT.L['WHISPER_ITEM'], '%{{number}}', tostring(count + 1))
			msg = string.gsub(msg, '%{{skill_link}}', skillLink)
			GT.logging.info(GT.textUtils.concat('GT_Whisper_SendResponse_Item', GT.logging.DELIMITER, recipient, professionName, searchTerm, msg))
			ChatThrottleLib:SendChatMessage('ALERT', GT.comm.PREFIX, msg, 'WHISPER', 'Common', recipient)
			count = count + 1
		end
		i = i + 1
	end

	if totalPages > 1 then
		if page < totalPages then
			msg = string.gsub(GT.L['WHISPER_FOOTER'], '%{{profession_name}}', professionName)
			msg = string.gsub(msg, '%{{next_page}}', tostring(page + 1))
			GT.logging.info(GT.textUtils.concat('GT_Whisper_SendResponse_Footer', GT.logging.DELIMITER, recipient, professionName, searchTerm, msg))
			ChatThrottleLib:SendChatMessage('ALERT', GT.comm.PREFIX, msg, 'WHISPER', 'Common', recipient)
		else
			msg = string.gsub(GT.L['WHISPER_FOOTER_LAST_PAGE'], '%{{profession_name}}', professionName)
			GT.logging.info(GT.textUtils.concat('GT_Whisper_SendResponse_FooterLastPage', GT.logging.DELIMITER, recipient, professionName, searchTerm, msg))
			ChatThrottleLib:SendChatMessage('ALERT', GT.comm.PREFIX, msg, 'WHISPER', 'Common', recipient)
		end
	end
end

function GT.whisper._searchSkills(professionName, searchTerm)
	local skills = GT.database.getProfession(
		GT_Character.realmName,
		GT_Character.factionName,
		GT_Character.guildName,
		GT_Character.characterName,
		professionName
	)
	if skills == nil then
		GT.logging.error(GT.textUtils.concat('GT_Whisper_SendInitialResponse_NilSkills', GT.logging.DELIMITER, recipient, professionName))
		return {}
	end
	skills = skills.skills

	local returnSkills = {}
	for skillName, _ in pairs(skills) do
		local addSkill = true
		if searchTerm ~= nil and not string.find(string.lower(skillName), string.lower(searchTerm)) then
			addSkill = false
		end
		if addSkill then
			local skillLink = skills[skillName].skillLink
			local tempSkillName = GT.textUtils.getTextBetween(skillLink, '%[', ']')
			returnSkills[tempSkillName] = skillLink
		end
	end
	return returnSkills
end