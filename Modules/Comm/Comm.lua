local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local Comm = GT:NewModule('Comm')
GT.Comm = Comm

LibStub('AceComm-3.0'):Embed(Comm)

Comm.COMM_SIZE_LIMIT = 255

Comm.COMM_VARIANCE = 0.3

Comm.NOT_UPDATED = -1
Comm.EQUAL = 0
Comm.UPDATED = 1

Comm.DELIMITER = '?'

Comm.WHISPER = 'WHISPER'
Comm.GUILD = 'GUILD'
Comm.YELL = 'YELL'
Comm.SAY = 'SAY'

Comm.ALERT = 'ALERT'
Comm.NORMAL = 'NORMAL'
Comm.BULK = 'BULK'

Comm.TIMESTAMP = 'TIMESTAMP'
Comm.GET = 'GET'
Comm.POST = 'POST'
Comm.DELETE = 'DELETE'
Comm.VERSION = 'VERSION'

local DISTRIBUTIONS = {}
local COMMAND_MAP = {}
local STARTUP_TASKS = {}

function Comm:OnEnable()
	GT.Log:Info('Comm_OnEnable')

	table.insert(STARTUP_TASKS, GT.CommWhisper['StartupTasks'])
	table.insert(STARTUP_TASKS, GT.CommGuild['StartupTasks'])
	table.insert(STARTUP_TASKS, GT.CommYell['StartupTasks'])

	COMMAND_MAP = {
		TIMESTAMP = 'OnTimestampsReceived',
		POST = 'OnPostReceived',
		DELETE = 'OnDeletionsReceived',
		VERSION = 'OnVersionReceived'
	}

	table.insert(DISTRIBUTIONS, Comm.WHISPER)
	table.insert(DISTRIBUTIONS, Comm.GUILD)
	table.insert(DISTRIBUTIONS, Comm.YELL)
	table.insert(DISTRIBUTIONS, Comm.SAY)

	GT.CommGuild:Enable()
	GT.CommWhisper:Enable()
	GT.CommYell:Enable()

	for command, functionName in pairs(COMMAND_MAP) do
		Comm:RegisterComm(command, functionName)
	end
end

function Comm:StartupTasks()
	GT:CreateActionQueue(GT.STARTUP_DELAY, STARTUP_TASKS)
end

function Comm:CommReceived(characterName)
	if GT.DBCharacter:CharacterExists(characterName) then
		local character = GT.DBCharacter:GetCharacter(characterName)
		local time = time()
		character.lastCommReceived = time
		return time
	end
	return nil
end

function Comm:GetTimestampString(characterName)
	local character = GT.DBCharacter:GetCharacter(characterName)
	local professionStrings = {}
	for professionName, profession in pairs(character.professions) do
		local professionString = GTText:Concat(Comm.DELIMITER, characterName, professionName, profession.lastUpdate)
		GT.Log:Info('Comm_GetTimestampString', professionString)
		table.insert(professionStrings, professionString)
	end
	if #professionStrings <= 0 then return nil end
	return table.concat(professionStrings, Comm.DELIMITER)
end

function Comm:OnTimestampsReceived(prefix, message, distribution, sender)
	local characterName = GT:GetCharacterName()
	if sender == characterName and distribution ~= Comm.GUILD then
		return
	end
	GT.Log:Info('Comm_OnTimestampsReceived', distribution, sender, message)

	Comm:CommReceived(sender)

	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('Comm_OnTimestampsReceived_CommDisabled')
		return
	end

	if not Table:Contains(DISTRIBUTIONS, distribution) then
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
	elseif distribution == Comm.YELL then
		GT.CommYell:OnTimestampsReceived(sender, toGet, toPost)
	else
		GT.Log:Error('Comm_OnTimestampsReceived_DistributionRejected', distribution, sender, message)
	end
end

function Comm:SendPost(distribution, characterName, professionName, recipient)
	GT.Log:Info('Comm_SendPost', distribution, characterName, professionName, recipient)

	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('Comm_SendPost_CommDisabled')
		return
	end

	if characterName == recipient then
		GT.Log:Warn('Comm_SendPost_AboutThemselves', characterName, professionName, recipient)
		return
	end

	local message = Comm:GetPostMessage(characterName, professionName)
	if message == nil then
		GT.Log:Error('Comm_SendPost_LocalNil', characterName, professionName)
		if GT:IsCurrentCharacter(characterName) then
			local character = GT.DBCharacter:GetCharacter(characterName)
			character.deletedProfessions = Table:Insert(character.deletedProfessions, nil, professionName)
			Comm:SendDeletions(distribution, recipient)
		end
		return
	end

	GT.Log:Info('Comm_SendPost_Send', recipient, message)
	Comm:SendCommMessage(Comm.POST, message, distribution, recipient, Comm.BULK)
end

function Comm:GetPostMessage(characterName, professionName)
	local profession = GT.DBCharacter:GetProfession(characterName, professionName)
	if profession == nil then
		return nil
	end

	local message = nil
	for _, skillName in pairs(profession.skills) do
		local skill = GT.DBProfession:GetSkill(professionName, skillName)
		if skill ~= nil then
			if message == nil then
				message = GTText:Concat(Comm.DELIMITER, skillName, skill.skillLink)
			else
				message = GTText:Concat(Comm.DELIMITER, message, skillName, skill.skillLink)
			end

			local uniqueReagentCount = 0
			for reagentName, _ in pairs(skill.reagents) do
				uniqueReagentCount = uniqueReagentCount + 1
			end

			message = GTText:Concat(Comm.DELIMITER, message, uniqueReagentCount)
			for reagentName, reagent in pairs(skill.reagents) do
				message = GTText:Concat(Comm.DELIMITER, message, reagentName, GTText:ToString(reagent.reagentLink), reagent.reagentCount)
			end
		end
	end
	if message ~= nil then
		local header = GTText:Concat(Comm.DELIMITER, characterName, professionName, profession.lastUpdate)
		return GTText:Concat(Comm.DELIMITER, header, message)
	else
		return nil
	end
end

function Comm:OnPostReceived(prefix, message, distribution, sender)
	if GT:IsCurrentCharacter(sender) then return end
	GT.Log:Info('Comm_OnPostReceived', distribution, sender)

	Comm:CommReceived(sender)

	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('Comm_OnPostReceived_CommDisabled')
		return
	end

	if distribution ~= Comm.WHISPER and distribution ~= Comm.GUILD then
		GT.Log:Error('Comm_OnPostReceived_RejectDistribution', distribution, sender)
		return
	end

	if not GT.CommValidator:IsPostValid(message) then
		GT.Log:Error('Comm_OnPostReceived_RejectFormat', distribution, sender, message)
		return
	end

	local tokens = GTText:Tokenize(message, Comm.DELIMITER)
	local characterName = Table:RemoveToken(tokens)

	if GT:IsCurrentCharacter(characterName) then
		GT.Log:Info('Comm_OnPostReceived_AboutMe', prefix, distribution, sender, message)
		return
	end

	local professionName, tokens = Table:RemoveToken(tokens)
	local lastUpdate, tokens = Table:RemoveToken(tokens)
	lastUpdate = tonumber(lastUpdate)

	GT.Log:Info('Comm_OnPostReceived_Accept', prefix, distribution, sender, characterName, professionName, lastUpdate)

	GT.DBProfession:AddProfession(professionName)

	if distribution == Comm.WHISPER then
		GT.CommWhisper:OnPostReceived(sender, message)
	elseif distribution == Comm.GUILD then
		GT.CommGuild:OnPostReceived(sender, message)
	end
end

function Comm:UpdateProfession(message)
	local tokens = GTText:Tokenize(message, Comm.DELIMITER)
	local characterName, tokens = Table:RemoveToken(tokens)
	local professionName, tokens = Table:RemoveToken(tokens)
	local lastUpdate, tokens = Table:RemoveToken(tokens)
	lastUpdate = tonumber(lastUpdate)
	GT.Log:Info('Comm__UpdateProfession', characterName, professionName, lastUpdate)

	profession = GT.DBCharacter:GetProfession(characterName, professionName)
	if profession == nil then
		profession = GT.DBCharacter:AddProfession(characterName, professionName)
	end

	while #tokens > 0 do
		local skillName, tokens = Table:RemoveToken(tokens)
		local skillLink, tokens = Table:RemoveToken(tokens)
		local uniqueReagentCount, tokens = Table:RemoveToken(tokens)
		uniqueReagentCount = tonumber(uniqueReagentCount)

		GT.DBCharacter:AddSkill(characterName, professionName, skillName)
		local skill = GT.DBProfession:AddSkill(professionName, skillName, skillLink)

		for i = 1, uniqueReagentCount do
			local reagentName, tokens = Table:RemoveToken(tokens)
			local reagentLink, tokens = Table:RemoveToken(tokens)
			local thisReagentCount, tokens = Table:RemoveToken(tokens)

			if reagentLink == 'nil' then
				reagentLink = nil
			end

			GT.DBProfession:AddReagent(professionName, skillName, reagentName, reagentLink, thisReagentCount)
		end
	end
	profession.lastUpdate = lastUpdate
end

function Comm:SendDeletions(distribution, recipient)
	GT.Log:Info('Comm_SendDeletions', distribution, recipient)

	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('Comm_SendDeletions_CommDisabled')
		return
	end

	local characterName = GT:GetCharacterName()
	local character = GT.DBCharacter:GetCharacter(characterName)

	local sendDelete = false
	local message = characterName
	for _, professionName in pairs(character.deletedProfessions) do
		message = GTText:Concat(Comm.DELIMITER, message, professionName)
		sendDelete = true
	end

	if sendDelete then
		GT.Log:Info('Comm_SendDeletions_Send', message)
		Comm:SendCommMessage(Comm.DELETE, message, distribution, recipient, Comm.NORMAL)
	end
end

function Comm:OnDeletionsReceived(prefix, message, distribution, sender)
	GT.Log:Info('Comm_OnDeletionsReceived', prefix, distribution, sender, message)

	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('Comm_OnDeletionsReceived_CommDisabled')
		return
	end

	if not distribution == Comm.GUILD and not distribution == Comm.WHISPER then
		GT.Log:Warn('Comm_OnDeletionsReceived_DistributionRejected', distribution, sender)
		return
	end

	local tokens = GTText:Tokenize(message, Comm.DELIMITER)
	local characterName, tokens = Table:RemoveToken(tokens)

	if string.lower(characterName) ~= string.lower(sender) then
		GT.Log:Warn('Comm_OnDeletionsReceived_NotAboutThemselves', distribution, sender, characterName)
		return
	end

	if GT:IsCurrentCharacter(characterName) then
		GT.Log:Info('Comm_OnDeletionsReceived_AboutMe', distribution, sender, characterName)
		return
	end

	while #tokens > 0 do
		local professionName, tokens = Table:RemoveToken(tokens)
		GT.DBCharacter:DeleteProfession(characterName, professionName)
	end
end

function Comm:SendVersion(distribution, recipient)
	local version = GT:GetCurrentVersion()

	if not GT.DBComm:GetIsEnabled() then
		-- GT.Log:Warn('Comm_SendVersion_CommDisabled', distribution, recipient, version)
		return
	end
	GT.Log:Info('Comm_SendVersion', distribution, recipient, version)

	--@debug@
	GT.Log:Info('Comm_SendVersion_DebugIntercept')
	--@end-debug@
	--[===[@non-debug@
	Comm:SendCommMessage(Comm.VERSION, tostring(version), distribution, recipient, Comm.NORMAL)
	--@end-non-debug@]===]
end

function Comm:OnVersionReceived(prefix, message, distribution, sender)
	GT.Log:Info('Comm_OnVersionReceived', distribution, sender, message)

	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('Comm_OnVersionReceived_CommDisabled')
		return
	end

	local lVersion = GT:GetCurrentVersion()
	local rVersion = 0
	if tonumber(message) ~= nil then
		rVersion = tonumber(message)
	else
		GT.Log:Warn('Comm_OnVersionReceived_InvalidVersion', distribution, sender, message)
		return
	end

	if lVersion > rVersion then
		GT.Log:Info('Comm_OnVersionReceived_RemoteUpdate', lVersion, rVersion)
		--[===[@non-debug@
		Comm:SendCommMessage(Comm.VERSION, tostring(lVersion), distribution, sender, Comm.NORMAL)
		--@end-non-debug@]===]
		return
	end

	if lVersion < rVersion then
		GT.Log:Info('Comm_OnVersionReceived_LocalUpdate', lVersion, rVersion)

		if GT.DB:GetVersionNotification() < rVersion then
			local lrVersion, lbVersion, laVersion = GT:DeconvertVersion(lVersion)
			local rrVersion, rbVersion, raVersion = GT:DeconvertVersion(rVersion)
			local message = string.gsub(GT.L['UPDATE_AVAILABLE'], '%{{local_version}}', GTText:Concat('.', lrVersion, lbVersion, laVersion))
			message = string.gsub(message, '%{{remote_version}}', GTText:Concat('.', rrVersion, rbVersion, raVersion))
			GT.Log:PlayerInfo(message)
			GT.DB:SetVersionNotification(rVersion)
		else
			GT.Log:Info('Comm_OnVersionReceived_AlreadyNotified', lVersion, rVersion)
		end
		return
	end
	GT.Log:Info('Comm_OnVersionReceived_UpToDate', lVersion, rVersion)
end

function Comm:ToggleComms()
	if GT.DBComm:GetIsEnabled() then
		GT.DBComm:SetIsEnabled(false)
	else
		GT.DBComm:SetIsEnabled(true)
	end
	local enabled = GT.DBComm:GetIsEnabled()
	GT.Log:Info('Comm_ToggleComms_IsEnabled', enabled)
	return enabled
end

function Comm:RemoveInactive(timeout, isGuildMember, isBroadcasted, printTemplate)
	local characters = GT.DBCharacter:GetCharacters()

	local charactersRemoved = {}
	for characterName, _ in pairs(characters) do
		local character = characters[characterName]
		if character.isGuildMember == isGuildMember
			and character.isBroadcasted == isBroadcasted
		then
			local lastUpdate = 0
			if not isBroadcasted then
				lastUpdate = character.lastCommReceived
			end

			local professions = character.professions
			for professionName, _ in pairs(professions) do
				local profession = professions[professionName]
				if profession.lastUpdate > lastUpdate then
					lastUpdate = profession.lastUpdate
				end
			end

			if lastUpdate + timeout < time() and not GT:IsCurrentCharacter(characterName) then
				GT.DBCharacter:DeleteCharacter(characterName)
				charactersRemoved = Table:Insert(charactersRemoved, nil, characterName)
			end
		end
	end

	if #charactersRemoved > 0 and printTemplate ~= nil then
		local characterNames = table.concat(GT.L['PRINT_DELIMITER'], removedCharacters)
		local message = string.gsub(printTemplate, '%{{character_names}}', removedCharacters)
		local days = tostring(math.floor(timeout / GT.DAY))
		message = string.gsub(message, '%{{timeout_days}}', days)
		GT.Log:PlayerInfo(message)
	end
end

function Comm:_ProcessTimestamps(message)
	-- GT.Log:Info('Comm_ProcessTimestamps', message)
	local toGet = {}
	local toPost = {}
	local all = {}

	local tokens = GTText:Tokenize(message, Comm.DELIMITER)

	while #tokens > 0 do
		local characterName, tokens = Table:RemoveToken(tokens)
		local professionName, tokens = Table:RemoveToken(tokens)
		local lastUpdate, tokens = Table:RemoveToken(tokens)
		lastUpdate = tonumber(lastUpdate)

		if professionName ~= 'None' then
			all = Comm:_Update(all, characterName, professionName, lastUpdate)
			local profession = GT.DBCharacter:GetProfession(characterName, professionName)

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

	local characters = GT.DBCharacter:GetCharacters()
	for characterName, _ in pairs(characters) do
		local postAll = false
		if not Table:Contains(all, characterName) then
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