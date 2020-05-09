local GT_Name, GT = ...

GT.comm = {}
GT.comm.state = {}
GT.comm.state.initialized = false
--@debug@
GT.comm.state.enabled = true
--@end-debug@

GT.comm.aceComm = LibStub("AceAddon-3.0"):NewAddon("TSWL", "AceComm-3.0")

GT.comm.PREFIX = 'GT'
GT.comm.DELIMITER = '?'
GT.comm.REAGENT_COUNT = 'REAGENT_COUNT'

GT.comm.COMMAND_TIMESTAMP = 'TIMESTAMP'
GT.comm.COMMAND_GET = 'GET'
GT.comm.COMMAND_POST = 'POST'
GT.comm.COMMAND_DELETE = 'DELETE'
GT.comm.COMMAND_VERSION = 'VERSION'

GT.comm.COMMAND_MAP = {}

function GT.comm.init()
	if GT.comm.state.initialized then
		return
	end
	GT.logging.info('GT_Comm_Init')

	GT.comm.COMMAND_MAP = {
		TIMESTAMP = GT.comm.onTimestampsReceived,
		GET = GT.comm.onGetReceived,
		POST = GT.comm.onPostReceived,
		DELETE = GT.comm.onDeleteReceived,
		VERSION = GT.comm.onVersionReceived
	}

	GT.comm.aceComm:RegisterComm(GT.comm.PREFIX, GT.comm.aceComm:OnCommReceived())

	GT.comm.state.initialized = true
end

function GT.comm.aceComm:OnCommReceived(prefix, message, distribution, sender)
	if prefix == nil or message == nil or distribution == nil or sender == nil then
		return
	end
	GT.logging.info(GT.textUtils.concat('GT_Comm_OnCommReceived', GT.logging.DELIMITER, prefix, distribution, sender, message))
	--@debug@
	if not GT.comm.state.enabled then
		GT.logging.info(GT.textUtils.concat('GT_Comm_OnCommReceived_Dropped', GT.logging.DELIMITER, prefix, distribution, message))
		return
	end
	--@end-debug@

	local tokens = GT.textUtils.tokenize(message, GT.comm.DELIMITER)
	local command, tokens = GT.tableUtils.removeToken(tokens)
	local commandFound = false
	for mapCommand, fn in pairs(GT.comm.COMMAND_MAP) do
		if command == mapCommand then
			fn(prefix, tokens, distribution, sender)
			commandFound = true
		end
	end
	if not commandFound then
		GT.logging.warn(GT.textUtils.concat('GT_Comm_OnCommReceived', GT.logging.DELIMITER, prefix, distribution, sender, message))
	end
end

function GT.comm.sendVersion()
	local releaseVersion, betaVersion, alphaVersion = GT.database.getCurrentVersion()
	GT.logging.info(GT.textUtils.concat('GT_Comm_SendVersion', GT.logging.DELIMITER, releaseVersion, betaVersion, alphaVersion))
	local msg = GT.textUtils.concat(GT.comm.COMMAND_VERSION, GT.comm.DELIMITER, releaseVersion, betaVersion, alphaVersion)
	--[===[@non-debug@
	GT.comm._sendToOnline(msg)
	--@end-non-debug@]===]
end

function GT.comm.onVersionReceived(prefix, tokens, distribution, sender)
	GT.logging.info(GT.textUtils.concat('GT_Comm_OnVersionReceived', GT.logging.DELIMITER, prefix, distribution, sender, tokens))
	--@debug@
	if true then
		GT.logging.info('GT_Comm_OnVersionReceived_DebugIgnore')
		return
	end
	--@end-debug@

	local localReleaseVersion, localBetaVersion, localAlphaVersion = GT.database.getCurrentVersion()

	local remoteReleaseVersion, tokens = GT.tableUtils.removeToken(tokens)
	local remoteBetaVersion, tokens = GT.tableUtils.removeToken(tokens)
	local remoteAlphaVersion, tokens = GT.tableUtils.removeToken(tokens)

	remoteReleaseVersion = tonumber(remoteReleaseVersion)
	remoteBetaVersion = tonumber(remoteBetaVersion)
	remoteAlphaVersion = tonumber(remoteAlphaVersion)

	local localStringVersion = GT.textUtils.concat(nil, '.', localReleaseVersion, localBetaVersion, localAlphaVersion)
	local remoteStringVersion = GT.textUtils.concat(nil, '.', remoteReleaseVersion, remoteBetaVersion, remoteAlphaVersion)

	-- If we need to notify *them* of an update.
	if localReleaseVersion > remoteReleaseVersion
		--@debug@
		or localBetaVersion > remoteBetaVersion
		or localAlphaVersion > remoteAlphaVersion
		--@end-debug@
	then
		local msg = GT.textUtils.concat(GT.comm.COMMAND_VERSION, GT.comm.DELIMITER, localReleaseVersion, remoteBetaVersion, remoteAlphaVersion)
		GT.logging.info('GT_Comm_OnVersionReceived_RemoteUpdate', GT.logging.DELIMITER, msg)
		GT.comm.aceComm:SendCommMessage(GT.comm.PREFIX, msg, 'WHISPER', sender, 'NORMAL')
		return
	end

	if localReleaseVersion < remoteReleaseVersion
		--@debug@
		or localBetaVersion < remoteBetaVersion
		or localAlphaVersion < remoteAlphaVersion
		--@end-debug@
	then
		GT.logging.info(GT.textUtils.concat('GT_Comm_OnVersionReceived_LocalUpdate', GT.logging.DELIMITER, localStringVersion, remoteStringVersion))
		if GT.database.shouldNotifyUpdate(remoteReleaseVersion, remoteBetaVersion, remoteAlphaVersion) then
			local msg = string.gsub(GT.L['UPDATE_AVAILABLE'], '%{{local_version}}', localStringVersion)
			msg = string.gsub(msg, '%{{remote_version}}', remoteStringVersion)
			GT.logging.info('GT_Comm_OnVersionReceived_PlayerNotify', GT.logging.DELIMITER, localStringVersion, remoteStringVersion)
			GT.logging.playerInfo(msg)
			GT.database.updateNotified(remoteReleaseVersion, remoteBetaVersion, remoteAlphaVersion)
		else
			GT.logging.info(GT.textUtils.concat('GT_Comm_OnVersionReceived_AlreadyNotified', GT.logging.DELIMITER, localStringVersion, remoteStringVersion))
		end
		return
	end
	GT.logging.info(GT.textUtils.concat('GT_Comm_OnVersionReceived_UpToDate', GT.logging.DELIMITER, localStringVersion, remoteStringVersion))
end

function GT.comm.sendDeletions()
	GT.logging.info('GT_Comm_SendDeletions')
	--@debug@
	if not GT.comm.state.enabled then
		GT.logging.info('GT_Comm_SendDeletions_Dropped')
		return
	end
	--@end-debug@
	if GT_Character.guildName == nil then
		GT.logging.warn('Character does not have a guild. Not sending deletions.')
	end
	local characters = GT.database.getGuild(GT_Character.realmName, GT_Character.factionName, GT_Character.guildName)
	if characters == nil then
		GT.logging.error('No characters found to send deletions for.')
		return
	end
	characters = characters.characters
	local msg = GT.comm.COMMAND_DELETE
	for characterName, _ in pairs(characters) do
		if characters[characterName].deletedProfessions ~= nil then
			for _, professionName in pairs(characters[characterName].deletedProfessions) do
				msg = GT.textUtils.concat(msg, GT.comm.DELIMITER, characterName, professionName)
			end
		else
			characters[characterName].deletedProfessions = {}
		end
	end
	if msg ~= GT.comm.COMMAND_DELETE then
		GT.logging.info(GT.textUtils.concat('GT_Comm_SendDeletions', GT.logging.DELIMITER, GT.comm.PREFIX, 'WHISPER', 'NORMAL', characterName, msg))
		GT.comm.aceComm:SendCommMessage(GT.comm.PREFIX, msg, 'WHISPER', characterName, 'NORMAL')
	end
end

function GT.comm.onDeleteReceived(prefix, tokens, distribution, sender)
	GT.logging.info(GT.textUtils.concat('GT_Comm_OnDelete_Received', GT.logging.DELIMITER, prefix, distribution, sender))
	while #tokens > 0 do
		local characterName, tokens = GT.tableUtils.removeToken(tokens)
		local professionName, tokens = GT.tableUtils.removeToken(tokens)
		GT.logging.info(GT.textUtils.concat('GT_Comm_OnDelete_Received', GT.logging.DELIMITER, characterName, professionName))

		local character = GT.database.getCharacter(
			GT_Character.realmName,
			GT_Character.factionName,
			GT_Character.guildName,
			characterName
		)
		if character ~= nil then
			local profession = GT.database.getProfession(
				GT_Character.realmName,
				GT_Character.factionName,
				GT_Character.guildName,
				characterName,
				professionName
			)
			if profession ~= nil then
				GT.database.removeProfession(
					GT_Character.realmName,
					GT_Character.factionName,
					GT_Character.guildName,
					characterName,
					professionName
				)
			else
				GT.logging.warn(characterName .. ' does not have profession ' .. professionName .. '.')
			end
		else
			GT.logging.warn('No character ' .. characterName .. ' found to delete ' .. professionName .. ' from.')
		end
	end
end

function GT.comm.sendTimestamps()
	GT.logging.info('GT_Comm_SendTimestamps')
	--@debug@
	if not GT.comm.state.enabled then
		GT.logging.info('GT_Comm_SendTimestamps_Dropped')
		return
	end
	--@end-debug@
	if GT_Character.guildName == nil then
		GT.logging.warn('Character does not have a guild. Not sending timestamps')
	end
	local characters = GT.database.getGuild(GT_Character.realmName, GT_Character.factionName, GT_Character.guildName)
	if characters == nil then
		GT.logging.error('No characters found to send timestamps for.')
		return
	end
	characters = characters.characters
	local msg = GT.comm.COMMAND_TIMESTAMP
	for characterName, _ in pairs(characters) do
		local professions = characters[characterName].professions
		for professionName, _ in pairs(professions) do
			msg = GT.textUtils.concat(msg, GT.comm.DELIMITER, characterName, professionName, professions[professionName].lastUpdate)
		end
	end

	GT.comm._sendToOnline(msg)
end

function GT.comm.onTimestampsReceived(prefix, tokens, distribution, sender)
	GT.logging.info('GT_Comm_OnTimestampsReceived: ' .. prefix .. ', ' .. distribution .. ', ' .. sender)
	GT.logging.info(GT.textUtils.concat('GT_Comm_OnTimestampsReceived', GT.logging.DELIMITER, prefix, distribution, sender, tokens))
	--@debug@
	if not GT.comm.state.enabled then
		GT.logging.info('GT_Comm_OnTimestampsReceived_Dropped')
		return
	end
	--@end-debug@
	local charactersToPost = {}
	local charactersToGet = {}
	local charactersReceived = {}
	local professionsToDelete = {}
	while #tokens > 0 do
		local characterName, tokens = GT.tableUtils.removeToken(tokens)
		local professionName, tokens = GT.tableUtils.removeToken(tokens)
		local lastUpdate, tokens = GT.tableUtils.removeToken(tokens)
		lastUpdate = tonumber(lastUpdate)

		charactersReceived[characterName] = {}
		table.insert(charactersReceived[characterName], professionName)

		local character = GT.database.getCharacter(
			GT_Character.realmName,
			GT_Character.factionName,
			GT_Character.guildName,
			characterName
		)
		if character == nil then
			character = GT.database.addCharacter(
				GT_Character.realmName,
				GT_Character.factionName,
				GT_Character.guildName,
				characterName
			)
		end
		if characterName == GT_Character.characterName and GT.tableUtils.tableContains(character.deletedProfessions, professionName) then
			if professionsToDelete[characterName] == nil then
				professionsToDelete[characterName] = {}
			end
			table.insert(professionsToDelete[characterName], professionName)
		else
			local profession = GT.database.getProfession(
				GT_Character.realmName,
				GT_Character.factionName,
				GT_Character.guildName,
				characterName,
				professionName
			)
			if profession == nil then
				charactersToGet[characterName] = {}
				table.insert(charactersToGet[characterName], professionName)
			else

				--[===[@non-debug@
				if lastUpdate < profession.lastUpdate then
				--@end-non-debug@]===]
				--@debug@
				if lastUpdate < time() then
				--@end-debug@
					charactersToPost[characterName] = {}
					table.insert(charactersToPost[characterName], professionName)
				elseif lastUpdate > profession.lastUpdate then
					charactersToGet[characterName] = {}
					table.insert(charactersToGet[characterName], professionName)
				else
					GT.logging.info(GT.textUtils.concat('GT_Comm_OnTimestampsReceived_NoUpdate', GT.logging.DELIMITER, characterName, professionName))
				end
			end
		end
	end

	local guildCharacters = GT.database.getGuild(
		GT_Character.realmName,
		GT_Character.factionName,
		GT_Character.guildName
	).characters
	for characterName, _ in pairs(guildCharacters) do
		local professions = guildCharacters[characterName].professions
		local characterReceived = GT.tableUtils.tableContains(charactersReceived, characterName)
		if not characterReceived then
			charactersToPost[characterName] = {}
		end
		for professionName, _ in pairs(professions) do
			local professionReceived = GT.tableUtils.tableContains(charactersReceived[characterName], professionName)
			if not professionReceived then
				table.insert(charactersToPost[characterName], professionName)
			end
		end
	end

	local msg = GT.comm.COMMAND_DELETE
	for characterName, _ in pairs(professionsToDelete) do
		local professions = professionsToDelete[characterName]
		for _, professionName in pairs(professions) do
			msg = msg .. GT.comm.DELIMITER .. characterName .. GT.comm.DELIMITER .. professionName
		end
	end
	if msg ~= GT.comm.COMMAND_DELETE then
		GT.comm.aceComm:SendCommMessage(GT.comm.PREFIX, msg, 'WHISPER', sender, 'NORMAL')
	end

	local msg = GT.comm.COMMAND_GET
	for characterName, _ in pairs(charactersToGet) do
		local professions = charactersToGet[characterName]
		for _, professionName in pairs(professions) do
			msg = msg .. GT.comm.DELIMITER .. characterName .. GT.comm.DELIMITER .. professionName
		end
	end
	if msg ~= GT.comm.COMMAND_GET then
		GT.comm.aceComm:SendCommMessage(GT.comm.PREFIX, msg, 'WHISPER', sender, 'NORMAL')
	end

	local msg = GT.comm.COMMAND_POST
	for characterName, _ in pairs(charactersToPost) do
		local professions = charactersToPost[characterName]
		for _, professionName in pairs(professions) do
			GT.comm.sendPost(characterName, professionName, sender)
		end
	end
end

function GT.comm.onGetReceived(prefix, tokens, distribution, sender)
	GT.logging.info('GT_Comm_OnGetReceived: ' .. prefix .. ', ' .. distribution .. ', ' .. sender)
	--@debug@
	if not GT.comm.state.enabled then
		GT.logging.info('GT_Comm_OnGetReceived_Dropped')
		return
	end
	--@end-debug@
	while #tokens > 0 do
		local characterName, tokens = GT.tableUtils.removeToken(tokens)
		local professionName, tokens = GT.tableUtils.removeToken(tokens)

		GT.comm.sendPost(characterName, professionName, sender)
	end
end

function GT.comm.sendPost(characterName, professionName, recipient)
	GT.logging.info('GT_Comm_SendPost: ' .. characterName .. ', ' .. professionName .. ', ' .. recipient)
	--@debug@
	if not GT.comm.state.enabled then
		GT.logging.info('GT_Comm_SendPost_Dropped')
		return
	end
	--@end-debug@

	local character = GT.database.getCharacter(
		GT_Character.realmName,
		GT_Character.factionName,
		GT_Character.guildName,
		characterName
	)
	if GT.tableUtils.tableContains(character.deletedProfessions, professionName) then
		GT.logging.info(characterName .. ' profession ' .. professionName .. ' is deleted. Canceling post.')
		local msg = GT.comm.COMMAND_DELETE .. GT.comm.DELIMITER .. characterName .. GT.comm.DELIMITER .. professionName
		GT.comm.aceComm:SendCommMessage(GT.comm.PREFIX, msg, 'WHISPER', sender, 'NORMAL')
		return
	end
	local profession = GT.database.getProfession(
		GT_Character.realmName,
		GT_Character.factionName,
		GT_Character.guildName,
		characterName,
		professionName
	)
	if profession ~= nil then
		msg = GT.comm.COMMAND_POST .. GT.comm.DELIMITER .. characterName .. GT.comm.DELIMITER .. professionName .. GT.comm.DELIMITER .. profession.lastUpdate
		local skills = profession.skills
		for skillName, _ in pairs(skills) do
			local skill = skills[skillName]
			msg = msg .. GT.comm.DELIMITER .. skill.skillName .. GT.comm.DELIMITER .. skill.skillLink
			local reagents = skill.reagents
			local sendingReagents = {}
			local sendingReagentCount = 0
			for reagentName, _ in pairs(reagents) do
				local reagent = reagents[reagentName]
				if not reagent.isHidden then
					sendingReagents[reagentName] = reagent.reagentCount
					sendingReagentCount = sendingReagentCount + 1
				end
			end
			msg = msg .. GT.comm.DELIMITER .. sendingReagentCount
			for reagentName, reagentCount in pairs(sendingReagents) do
				msg = msg .. GT.comm.DELIMITER .. reagentName .. GT.comm.DELIMITER .. reagentCount
			end
		end
		if msg ~= GT.comm.COMMAND_POST .. GT.comm.DELIMITER .. characterName .. GT.comm.DELIMITER .. professionName .. GT.comm.DELIMITER .. profession.lastUpdate then
			GT.comm.aceComm:SendCommMessage(GT.comm.PREFIX, msg, 'WHISPER', recipient, 'NORMAL')
		end
	end
end

function GT.comm.onPostReceived(prefix, tokens, distribution, sender)
	--@debug@
	if not GT.comm.state.enabled then
		GT.logging.info('GT_Comm_OnPostReceived_Dropped')
		return
	end
	--@end-debug@
	local characterName, tokens = GT.tableUtils.removeToken(tokens)
	local professionName, tokens = GT.tableUtils.removeToken(tokens)
	local lastUpdate, tokens = GT.tableUtils.removeToken(tokens)
	lastUpdate = tonumber(lastUpdate)

	GT.logging.info('GT_Comm_OnPostReceived: ' .. prefix .. ', ' .. distribution .. ', ' .. sender .. ', ' .. characterName .. ', ' .. professionName)

	local character = GT.database.getCharacter(
		GT_Character.realmName,
		GT_Character.factionName,
		GT_Character.guildName,
		characterName
	)

	if character == nil then
		character = GT.database.addCharacter(
			GT_Character.realmName,
			GT_Character.factionName,
			GT_Character.guildName,
			characterName
		)
	end

	if characterName == GT_Character.characterName and GT.tableUtils.tableContains(character.deletedProfessions, professionName) then
		GT.logging.info(characterName .. ' profession ' .. professionName .. ' is deleted. Canceling post receiving.')
		local msg = GT.comm.COMMAND_DELETE .. GT.comm.DELIMITER .. characterName .. GT.comm.DELIMITER .. professionName
		GT.comm.aceComm:SendCommMessage(GT.comm.PREFIX, msg, 'WHISPER', sender, 'NORMAL')
		return
	end

	local professions = character.professions

	local profession = GT.database.getProfession(
		GT_Character.realmName,
		GT_Character.factionName,
		GT_Character.guildName,
		characterName,
		professionName
	)
	if profession == nil then
		profession = GT.database.addProfession(
			GT_Character.realmName,
			GT_Character.factionName,
			GT_Character.guildName,
			characterName,
			professionName
		)
	end

	local skills = profession.skills

	while #tokens > 0 do
		local skillName, tokens = GT.tableUtils.removeToken(tokens)
		local skillLink, tokens = GT.tableUtils.removeToken(tokens)
		local uniqueReagentCount, tokens = GT.tableUtils.removeToken(tokens)
		uniqueReagentCount = tonumber(uniqueReagentCount)

		local skill = GT.database.getSkill(
			GT_Character.realmName,
			GT_Character.factionName,
			GT_Character.guildName,
			characterName,
			professionName,
			skillName
		)
		if skill == nil then
			skill = GT.database.addSkill(
				GT_Character.realmName,
				GT_Character.factionName,
				GT_Character.guildName,
				characterName,
				professionName,
				skillName,
				skillLink
			)
		end

		local i = 0
		while i < uniqueReagentCount do
			local reagentName, tokens = GT.tableUtils.removeToken(tokens)
			local reagentCount, tokens = GT.tableUtils.removeToken(tokens)

			local reagent = GT.database.getReagent(
				GT_Character.realmName,
				GT_Character.factionName,
				GT_Character.guildName,
				characterName,
				professionName,
				skillName,
				reagentName
			)

			if reagent == nil then
				GT.database.addReagent(
					GT_Character.realmName,
					GT_Character.factionName,
					GT_Character.guildName,
					characterName,
					professionName,
					skillName,
					reagentName,
					reagentCount
				)
			end

			i = i + 1
		end
	end
end

function GT.comm._sendToOnline(msg)
	local totalGuildMembers = GetNumGuildMembers()
	for i = 1, totalGuildMembers do
		local characterName, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(i)
		local tempCharacterName = GT.textUtils.convertCharacterName(characterName)
		local isCurrentCharacter = tempCharacterName == GT_Character.characterName
		if online then
			--[===[@non-debug@
			if not isCurrentCharacter then
			--@end-non-debug@]===]
				GT.logging.info(GT.textUtils.concat('GT_Comm_SendToOnline', GT.logging.DELIMITER, GT.comm.PREFIX, characterName, msg))
				GT.comm.aceComm:SendCommMessage(GT.comm.PREFIX, msg, 'WHISPER', characterName, 'NORMAL')
			--[===[@non-debug@
			end
			--@end-non-debug@]===]
		end
	end
end

--@debug@
function GT.comm.toggleComms()
	if GT.comm.state.enabled then
		GT.logging.info('Disabling comms.')
		GT.comm.state.enabled = false
	else
		GT.logging.info('Enabling comms.')
		GT.comm.state.enabled = true
	end
end
--@end-debug@