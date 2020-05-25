local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local Comm = GT:NewModule('Comm')
GT.Comm = Comm

LibStub('AceComm-3.0'):Embed(Comm)
-- GT.Comm.AceComm = LibStub('AceComm-3.0')

Comm.COMM_VARIANCE = 0.3

Comm.DELIMITER = '?'

Comm.NOT_UPDATED = -1
Comm.EQUAL = 0
Comm.UPDATED = 1

Comm.WHISPER = 'WHISPER'
Comm.GUILD = 'GUILD'
Comm.YELL = 'YELL'
Comm.SAY = 'SAY'

Comm.ALERT = 'ALERT'
Comm.NORMAL = 'NORMAL'
Comm.BULK = 'BULK'

local DISTRIBUTIONS = {}

Comm.TIMESTAMP = 'TIMESTAMP'
Comm.POST = 'POST'
Comm.DELETE = 'DELETE'
Comm.VERSION = 'VERSION'

local COMMAND_MAP = {}

function Comm:OnEnable()
	GT.Log:Info('Comm_OnEnable')

	COMMAND_MAP = {
		TIMESTAMP = 'OnTimestampsReceived',
		POST = 'OnPostReceived',
		DELETE = 'OnDeleteReceived',
		VERSION = 'OnVersionReceived'
	}

	table.insert(DISTRIBUTIONS, Comm.WHISPER)
	table.insert(DISTRIBUTIONS, Comm.GUILD)
	table.insert(DISTRIBUTIONS, Comm.YELL)
	table.insert(DISTRIBUTIONS, Comm.SAY)

	GT.CommGuild:Enable()
	GT.CommWhisper:Enable()

	for command, functionName in pairs(COMMAND_MAP) do
		Comm:RegisterComm(command, functionName)
	end
end

function Comm:SendTimestamps(distribution, recipient)
	-- GT.Log:Info('Comm_SendTimestamps', distribution, recipient)
	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('Comm_SendTimestamps_CommDisabled')
		return
	end

	local characters = GT.DB:GetCharacters()
	local professionStrings = {}
	for characterName, _ in pairs(characters) do
		local character = characters[characterName]
		if (distribution == Comm.GUILD and character.isGuildMember)
			or (distribution == Comm.WHISPER and GT:IsCurrentCharacter(characterName))
		then
			local professions = character.professions
			for professionName, _ in pairs(professions) do
				local profession = professions[professionName]
				local professionString = GT.Text:Concat(Comm.DELIMITER, characterName, professionName, profession.lastUpdate)
				table.insert(professionStrings, professionString)
			end
		end
	end

	local message = nil
	if #professionStrings > 0 then
		message = table.concat(professionStrings, Comm.DELIMITER)
	else
		message = GT.Text:Concat(Comm.DELIMITER, GT:GetCurrentCharacter(), 'None', 0)
	end

	GT.Log:Info('Comm_SendTimestamps', recipient, message)
	Comm:SendCommMessage(Comm.TIMESTAMP, message, distribution, recipient, 'NORMAL')
end

function Comm:OnTimestampsReceived(prefix, message, distribution, sender)
	local characterName = UnitName('player')
	if sender == characterName and distribution ~= Comm.GUILD then
		return
	end
	GT.Log:Info('Comm_OnTimestampsReceived', distribution, sender, message)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('Comm_OnTimestampsReceived_CommDisabled')
		return
	end

	if not GT.Table:Contains(DISTRIBUTIONS, distribution) then
		GT.Log:Error('Comm_OnTimestampsReceived_UnknownDistribution', prefix, distribution, sender, message)
		return
	end

	if not GT.CommValidator:IsTimestampValid(message) then
		GT.Log:Error('Comm_OnTimestampsReceived_RejectFormat', sender, message)
		return
	end

	local toGet, toPost = Comm:_ProcessTimestamps(message)

	if distribution == Comm.WHISPER then
		GT.CommWhisper:OnTimestampsReceived(sender, toGet, toPost)
	elseif distribution == Comm.GUILD then
		GT.CommGuild:OnTimestampsReceived(sender, toGet, toPost)
	else
		GT.Log:Error('Comm_OnTimestampsReceived_DistributionRejected', distribution, sender, message)
	end
end

function Comm:SendPost(distribution, characterName, professionName, recipient)
	GT.Log:Info('Comm_SendPost', distribution, characterName, professionName, recipient)

	-- if not GT.DB:IsCommEnabled() then
	-- 	GT.Log:Warn('Comm_SendPost_CommDisabled')
	-- 	return
	-- end

	if characterName == recipient then
		GT.Log:Warn('Comm_SendPost_AboutThemselves', characterName, professionName, recipient)
		return
	end

	local message = Comm:GetPostMessage(characterName, professionName)
	if message == nil then
		GT.Log:Error('Comm_SendPost_LocalNil', characterName, professionName)
		return
	end

	GT.Log:Info('Comm_SendPost_Send', recipient, message)
	Comm:SendCommMessage(Comm.POST, message, distribution, recipient, Comm.BULK)
end

function Comm:GetPostMessage(characterName, professionName)
	local profession = GT.DB:GetProfession(characterName, professionName)
	if profession == nil then
		return nil
	end

	local message = GT.Text:Concat(Comm.DELIMITER, characterName, professionName, profession.lastUpdate)
	for _, skillName in pairs(profession.skills) do
		local skill = GT.DB:GetSkill(characterName, professionName, skillName)
		message = GT.Text:Concat(Comm.DELIMITER, message, skillName, skill.skillLink)

		local reagentCount = 0
		local reagents = {}
		for reagentName, _ in pairs(skill.reagents) do
			local reagent = skill.reagents[reagentName]
			reagentCount = reagentCount + 1
			reagents[reagentName] = reagent.reagentCount
		end

		message = GT.Text:Concat(Comm.DELIMITER, message, reagentCount)
		for reagentName, reagentCount in pairs(reagents) do
			message = GT.Text:Concat(Comm.DELIMITER, message, reagentName, reagentCount)
		end
	end
	return message
end

function Comm:OnPostReceived(prefix, message, distribution, sender)
	if GT:IsCurrentCharacter(sender) then return end
	GT.Log:Info('Comm_OnPostReceived', prefix, distribution, sender)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('Comm_OnPostReceived_CommDisabled')
		return
	end

	if not GT.Table:Contains(DISTRIBUTIONS, distribution) then
		GT.Log:Error('Comm_OnPostReceived_UnknownDistribution', prefix, distribution, sender)
		return
	end

	local tokens = GT.Text:Tokenize(message, Comm.DELIMITER)
	local characterName, tokens = GT.Table:RemoveToken(tokens)

	if characterName ~= nil
		and(distribution == Comm.YELL
			or distribution == Comm.SAY)
	then
		if not GT.DB:IsReceivingBroadcasts() and string.lower(characterName) == string.lower(sender) then
			GT.Log:Info('Comm_OnPostReceived_NotReceivingBroadcasts', prefix, distribution, sender)
			return
		end
		if not GT.DB:IsReceivingForwards() and string.lower(characterName) ~= string.lower(sender) then
			GT.Log:Info('Comm_OnPostReceived_NotReceivingFowards', prefix, distribution, sender)
			return
		end
	end

	local localCharacterName = UnitName('player')
	if characterName == localCharacterName then
		GT.Log:Info('Comm_OnPostReceived_AboutMe', prefix, distribution, sender, message)
		return
	end

	if distribution == Comm.WHISPER and string.lower(characterName) ~= string.lower(sender) then
		GT.Log:Error('Comm_OnPostReceived_WhisperAboutOther', distribution, sender, characterName)
		return
	end

	if not GT.CommValidator:IsPostValid(message) then
		GT.Log:Error('Comm_OnPostReceived_RejectFormat', prefix, distribution, sender, message)
		return
	end
	local professionName, tokens = GT.Table:RemoveToken(tokens)
	local lastUpdate, tokens = GT.Table:RemoveToken(tokens)
	lastUpdate = tonumber(lastUpdate)

	GT.Log:Info('Comm_OnPostReceived_AcceptFormat', prefix, distribution, sender, characterName, professionName, lastUpdate)

	local profession = GT.DB:GetProfession(characterName, professionName)
	if profession ~= nil and profession.lastUpdate > lastUpdate then
		GT.Log:Info('Comm_OnPostReceived_RemoteOutOfDate', sender, characterName, professionName)
		if distribution == Comm.YELL or distribution == Comm.SAY then
			GT.CommYell:SendPost(characterName, professionName)
		else
			Comm:SendPost(distribution, characterName, professionName, sender)
		end
		return
	elseif profession == nil or profession.lastUpdate < lastUpdate then
		GT.Log:Info('Comm_OnPostReceived_LocalOutOfDate', characterName, professionName)
		profession = GT.DB:AddProfession(characterName, professionName)
		if distribution == Comm.YELL or distribution == Comm.SAY then
			local character = GT.DB:GetCharacter(characterName)
			character.isBroadcasted = true
			character.isGuildMember = false
		end
	end

	while #tokens > 0 do
		local skillName, tokens = GT.Table:RemoveToken(tokens)
		local skillLink, tokens = GT.Table:RemoveToken(tokens)
		local uniqueReagentCount, tokens = GT.Table:RemoveToken(tokens)
		uniqueReagentCount = tonumber(uniqueReagentCount)

		local skill = GT.DB:AddSkill(characterName, professionName, skillName, skillLink)

		for i = 1, uniqueReagentCount do
			local reagentName, tokens = GT.Table:RemoveToken(tokens)
			local thisReagentCount, tokens = GT.Table:RemoveToken(tokens)

			GT.DB:AddReagent(professionName, skillName, reagentName, thisReagentCount)
		end
	end
	profession.lastUpdate = lastUpdate
end

function Comm:SendDeletions()
	GT.Log:Info('Comm_SendDeletions')

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('Comm_SendDeletions_CommDisabled')
		return
	end

	local message = UnitName('player')
	local sendDelete = false
	local character = GT.DB:GetCharacter(message)

	for _, professionName in pairs(character.deletedProfessions) do
		message = GT.Text:Concat(Comm.DELIMITER, message, professionName)
		sendDelete = true
	end

	if sendDelete then
		Comm:SendCommMessage(Comm.DELETE, message, GUILD, nil, Comm.NORMAL)
	end
end

function Comm:OnDeleteReceived(prefix, message, distribution, sender)
	GT.Log:Info('Comm_OnDeleteReceived', prefix, distribution, sender, message)

	local tokens = GT.Text:Tokenize(message, Comm.DELIMITER)
	local characterName, tokens = GT.Table:RemoveToken(tokens)
	while #tokens > 0 do
		local professionName, tokens = GT.Table:RemoveToken(tokens)
		GT.DB:DeleteProfession(characterName, professionName)
	end
end

function Comm:SendVersion()
	local version = GT:GetCurrentVersion()
	GT.Log:Info('Comm_SendVersion', version)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('Comm_SendVersion_CommDisabled')
		return
	end

	--[===[@non-debug@
	Comm:SendCommMessage(Comm.VERSION, tostring(version), GUILD, nil, Comm.NORMAL)
	--@end-non-debug@]===]
end

function Comm:OnVersionReceived(prefix, message, distribution, sender)
	GT.Log:Info('Comm_OnVersionReceived', prefix, distribution, sender, message)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('Comm_OnVersionReceived_CommDisabled')
		return
	end

	local lVersion = GT:GetCurrentVersion()
	local rVersion = tonumber(message)

	if rVersion == nil or lVersion > rVersion then
		GT.Log:Info('Comm_OnVersionReceived_RemoteUpdate', lVersion, rVersion)
		--[===[@non-debug@
		Comm:SendCommMessage(Comm.VERSION, tostring(lVersion), GUILD, nil, Comm.NORMAL)
		--@end-non-debug@]===]
		return
	end

	if lVersion < rVersion then
		GT.Log:Info('Comm_OnVersionReceived_LocalUpdate', lVersion, rVersion)
		if GT.DB:ShouldNotifyUpdate(rVersion) then
			local lrVersion, lbVersion, laVersion = GT:DeconvertVersion(lVersion)
			local rrVersion, rbVersion, raVersion = GT:DeconvertVersion(rVersion)
			local message = string.gsub(GT.L['UPDATE_AVAILABLE'], '%{{local_version}}', GT.Text:Concat('.', lrVersion, lbVersion, laVersion))
			message = string.gsub(message, '%{{remote_version}}', GT.Text:Concat('.', rrVersion, rbVersion, raVersion))
			GT.Log:PlayerInfo(message)
			GT.DB:UpdateNotified(rVersion)
		else
			GT.Log:Info('Comm_OnVersionReceived_AlreadyNotified', lVersion, rVersion)
		end
		return
	end
	GT.Log:Info('Comm_OnVersionReceived_UpToDate', lVersion, rVersion)
end

function Comm:ToggleComms()
	if GT.DB:IsCommEnabled() then
		GT.DB:SetCommEnabled(false)
	else
		GT.DB:SetCommEnabled(true)
	end
	local enabled = GT.DB:IsCommEnabled()
	GT.Log:Info('Comm_ToggleComms', enabled)
	return enabled
end

function Comm:_ProcessTimestamps(message)
	-- GT.Log:Info('Comm_ProcessTimestamps', message)
	local toGet = {}
	local toPost = {}
	local all = {}

	local tokens = GT.Text:Tokenize(message, Comm.DELIMITER)

	while #tokens > 0 do
		local characterName, tokens = GT.Table:RemoveToken(tokens)
		local professionName, tokens = GT.Table:RemoveToken(tokens)
		local lastUpdate, tokens = GT.Table:RemoveToken(tokens)
		lastUpdate = tonumber(lastUpdate)

		if professionName ~= 'None' then
			all = Comm:_Update(all, characterName, professionName, lastUpdate)
			local profession = GT.DB:GetProfession(characterName, professionName, false)

			if profession == nil or profession.lastUpdate < lastUpdate then
				if profession == nil then
					-- GT.Log:Info('Comm_OnTimestampsReceived_LocalNil', characterName, professionName, lastUpdate)
				else
					-- GT.Log:Info('Comm_OnTimestampsReceived_LocalOutOfDate', characterName, professionName, profession.lastUpdate, lastUpdate)
				end

				toGet = Comm:_Update(toGet, characterName, professionName, lastUpdate)
			elseif profession.lastUpdate > lastUpdate then
				-- GT.Log:Info('Comm_OnTimestampsReceived_RemoteOutOfDate', characterName, professionName, profession.lastUpdate, lastUpdate)
				toPost = Comm:_Update(toPost, characterName, professionName, profession.lastUpdate)
			else
				-- GT.Log:Info('Comm_OnTimestampsReceived_UpToDate', characterName, professionName, profession.lastUpdate, lastUpdate)
			end
		end
	end

	local characters = GT.DB:GetCharacters()
	for characterName, _ in pairs(characters) do
		local postAll = false
		if not GT.Table:Contains(all, characterName) then
			postAll = true
		end

		local professions = characters[characterName].professions
		for professionName, _ in pairs(professions) do
			local profession = professions[professionName]
			if postAll then
				toPost = Comm:_Update(toPost, characterName, professionName, profession.lastUpdate)
			else
				local character = all[characterName]
				if character[professionName] == nil then
					toPost = Comm:_Update(toPost, characterName, professionName, profession.lastUpdate)
				end
			end

			all = Comm:_Update(all, characterName, professionName, profession.lastUpdate)
			--@debug@
			toPost = Comm:_Update(toPost, characterName, professionName, profession.lastUpdate)
			--@end-debug@
		end
	end
	return toGet, toPost
end

function Comm:_Update(tbl, characterName, professionName, lastUpdate)
	local updateState = Comm.NOT_UPDATED

	if tbl == nil then
		tbl = {}
	end
	if tbl[characterName] == nil then
		tbl[characterName] = {}
		updateState = Comm.UPDATED
	end
	local character = tbl[characterName]
	if character[professionName] == nil then
		character[professionName] = {}
		updateState = Comm.UPDATED
	end
	local profession = character[professionName]
	if profession.lastUpdate == nil then
		profession.lastUpdate = 0
	end
	if lastUpdate == nil or tonumber(lastUpdate) == nil then
		lastUpdate = 0
	end
	if profession.lastUpdate < lastUpdate then
		profession.lastUpdate = lastUpdate
		updateState = Comm.UPDATED
	elseif profession.lastUpdate == lastUpdate then
		updateState = Comm.EQUAL
	end
	return tbl, updateState
end