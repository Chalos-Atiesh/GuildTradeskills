local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnName, true)

local Comm = GT:NewModule('Comm')
GT.Comm = Comm

GT.Comm.enabled = true

LibStub('AceComm-3.0'):Embed(Comm)
-- GT.Comm.AceComm = LibStub('AceComm-3.0')

local DELIMITER = '?'
local REAGENT_COUNT = 'REAGENT_COUNT'

local TIMESTAMP = 'TIMESTAMP'
local GET = 'GET'
local POST = 'POST'
local DELETE = 'DELETE'
local VERSION = 'VERSION'

local COMMAND_MAP = {}

function Comm:OnEnable()
	GT.Log:Info('Comm_OnEnable')

	COMMAND_MAP = {
		TIMESTAMP = 'OnTimestampsReceived',
		GET = 'OnGetReceived',
		POST = 'OnPostReceived',
		DELETE = 'OnDeleteReceived',
		VERSION = 'OnVersionReceived'
	}

	for command, functionName in pairs(COMMAND_MAP) do
		-- GT.Log:Info('Comm_RegisterComm', command, functionName)
		Comm:RegisterComm(command, functionName)
	end
end

function Comm:SendTimestamps()
	GT.Log:Info('Comm_SendTimestamps')

	local characters = GT.DB:GetCharacters()
	local professionStrings = {}
	for characterName, _ in pairs(characters) do
		local professions = characters[characterName].professions
		for professionName, _ in pairs(professions) do
			local profession = professions[professionName]
			local professionString = GT.Text:Concat(DELIMITER, characterName, professionName, profession.lastUpdate)
			table.insert(professionStrings, professionString)
		end
	end
	if #professionStrings > 0 then
		Comm:_SendToOnline(TIMESTAMP, table.concat(professionStrings, DELIMITER))
	else
		local characterName = UnitName('player')
		Comm:_SendToOnline(TIMESTAMP, GT.Text:Concat(DELIMITER, characterName, 'None', 0))
	end
end

function Comm:OnTimestampsReceived(prefix, message, distribution, sender)
	GT.Log:Info('Comm_OnTimestampsReceived', prefix, distribution, sender, message)

	local toGet = {}
	local toPost = {}
	local all = {}

	local tokens = GT.Text:Tokenize(message, DELIMITER)

	while #tokens > 0 do
		local characterName, tokens = GT.Table:RemoveToken(tokens)
		local professionName, tokens = GT.Table:RemoveToken(tokens)
		local timestamp, tokens = GT.Table:RemoveToken(tokens)
		timestamp = tonumber(timestamp)

		if all[characterName] == nil then
			all[characterName] = {}
		end
		table.insert(all[characterName], professionName)

		local profession = GT.DB:GetProfession(characterName, professionName)

		--@debug@
		if toPost[characterName] == nil then
			toPost[characterName] = {}
		end
		if not GT.Table:Contains(toPost[characterName], professionName) then
			table.insert(toPost[characterName], professionName)
		end
		--@end-debug@

		if profession == nil then
			if toGet[characterName] == nil then
				toGet[characterName] = {}
			end
			if not GT.Table:Contains(toGet[characterName], professionName) then
				GT.Log:Info('Comm_OnTimestampsReceived_LocalNil', characterName, professionName)
				table.insert(toGet[characterName], professionName)
			end
		elseif profession.lastUpdate < timestamp then
			if toGet[characterName] == nil then
				toGet[characterName] = {}
			end
			if not GT.Table:Contains(toGet[characterName], professionName) then
				GT.Log:Info('Comm_OnTimestampsReceived_LocalOutOfDate', characterName, professionName, profession.lastUpdate, timestamp)
				table.insert(toGet[characterName], professionName)
			end
		elseif profession.lastUpdate > timestamp then
			if toPost[characterName] == nil then
				toPost[characterName] = {}
			end
			if not GT.Table:Contains(toPost[characterName], professionName) then
				GT.Log:Info('Comm_OnTimestampsReceived_RemoteOutOfDate', characterName, professionName, profession.lastUpdate, timestamp)
				table.insert(toPost[characterName], professionName)
			end
		else
			GT.Log:Info('Comm_OnTimestampsReceived_UpToDate', characterName, professionName, profession.lastUpdate, timestamp)
			if all[characterName] == nil then
				all[characterName] = {}
			end
			if not GT.Table:Contains(all[characterName], professionName) then
				table.insert(all[characterName], professionName)
			end
		end
	end

	local characters = GT.DB:GetCharacters()
	for characterName, _ in pairs(characters) do
		if all[characterName] == nil then
			all[characterName] = {}
		end
		local professions = characters[characterName].professions
		for professionName, _ in pairs(professions) do
			if not GT.Table:Contains(all[characterName], professionName) then
				if toPost[characterName] == nil or not GT.Table:Contains(toPost[characterName], professionName) then
					if toPost[characterName] == nil then
						toPost[characterName] = {}
					end
					if not GT.Table:Contains(toPost[characterName], professionName) then
						table.insert(toPost[characterName], professionName)
					end
				end
			end
		end
	end

	for characterName, _ in pairs(toGet) do
		for _, professionName in pairs(toGet[characterName]) do
			Comm:SendGet(characterName, professionName, sender)
		end
	end

	for characterName, _ in pairs(toPost) do
		if characterName ~= sender then
			for _, professionName in pairs(toPost[characterName]) do
				Comm:SendPost(characterName, professionName, sender)
			end
		end
	end
end

function Comm:SendGet(characterName, professionName, recipient)
	GT.Log:Info('Comm_SendGet', characterName, professionName, recipient)

	local message = GT.Text:Concat(DELIMITER, characterName, professionName)

	GT.Log:Info('Comm_SendGet_Send', recipient, message)
	Comm:SendCommMessage(GET, message, 'WHISPER', recipient, 'NORMAL')
end

function Comm:GetAll()
	GT.Log:Info('Comm_GetAll')
	Comm:_SendToOnline(GET, 'ALL')
end

function Comm:OnGetReceived(prefix, message, distribution, sender)
	GT.Log:Info('Comm_OnGetReceived', prefix, distribution, sender, message)
	local tokens = GT.Text:Tokenize(message, DELIMITER)
	while #tokens > 0 do
		local characterName, tokens = GT.Table:RemoveToken(tokens)
		local professionName, tokens = GT.Table:RemoveToken(tokens)

		if professionName ~= 'None' then
			Comm:SendPost(characterName, professionName, sender)
		else
			GT.Log:Info('Comm_OnGetReceived_Ignore', prefix, distribution, sender, characterName, professionName)
		end

	end
end

function Comm:SendPost(characterName, professionName, recipient)
	GT.Log:Info('Comm_SendPost', characterName, professionName, recipient)

	if characterName == recipient then
		GT.Log:Info('Comm_SendPost_AboutThemselves', characterName, professionName, recipient)
		return
	end

	local profession = GT.DB:GetProfession(characterName, professionName)
	if profession == nil then
		GT.Log:Error('Comm_SendPost_LocalNil', characterName, professionName)
		return
	end

	local message = GT.Text:Concat(DELIMITER, characterName, professionName, profession.lastUpdate)
	for _, skillName in pairs(profession.skills) do
		local skill = GT.DB:GetSkill(characterName, professionName, skillName)
		message = GT.Text:Concat(DELIMITER, message, skillName, skill.skillLink)

		local reagentCount = 0
		local reagents = {}
		for reagentName, _ in pairs(skill.reagents) do
			local reagent = skill.reagents[reagentName]
			reagentCount = reagentCount + 1
			reagents[reagentName] = reagent.reagentCount
		end

		message = GT.Text:Concat(DELIMITER, message, reagentCount)
		for reagentName, reagentCount in pairs(reagents) do
			message = GT.Text:Concat(DELIMITER, message, reagentName, reagentCount)
		end
	end
	GT.Log:Info('Comm_SendPost_Send', recipient, message)
	Comm:SendCommMessage(POST, message, 'WHISPER', recipient, 'NORMAL')
end

function Comm:OnPostReceived(prefix, message, distribution, sender)
	GT.Log:Info('Comm_OnPostReceived', prefix, distribution, sender, message)

	if not Comm:IsPostValidFormat(message) then
		GT.Log:Error('Comm_OnPostReceived_RejectFormat', prefix, distribution, sender)
		return
	end

	local tokens = GT.Text:Tokenize(message, DELIMITER)
	
	local characterName, tokens = GT.Table:RemoveToken(tokens)
	local professionName, tokens = GT.Table:RemoveToken(tokens)
	local lastUpdate, tokens = GT.Table:RemoveToken(tokens)
	lastUpdate = tonumber(lastUpdate)

	GT.Log:Info('Comm_OnGetReceived_AcceptFormat', prefix, distribution, sender, characterName, professionName, lastUpdate)

	local localCharacterName = UnitName('player')
	if characterName == localCharacterName then
		GT.Log:Info('Comm_OnPostReceived_AboutMe', prefix, distribution, sender, message)
		return
	end

	local profession = GT.DB:GetProfession(characterName, professionName)
	if profession ~= nil and profession.lastUpdate > lastUpdate then
		GT.Log:Info('Comm_OnPostReceived_RemoteOutOfDate', sender, characterName, professionName)
		Comm:SendPost(characterName, professionName, sender)
		return
	elseif profession == nil or profession.lastUpdate < lastUpdate then
		GT.Log:Info('Comm_OnPostReceived_LocalOutOfDate', characterName, professionName)
		profession = GT.DB:AddProfession(characterName, professionName)
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

function Comm:IsPostValidFormat(message)
	GT.Log:Info('Comm_IsPostValidFormat')
	local tokens = GT.Text:Tokenize(message, DELIMITER)
	
	local characterName, tokens = GT.Table:RemoveToken(tokens)
	local professionName, tokens = GT.Table:RemoveToken(tokens)
	local lastUpdate, tokens = GT.Table:RemoveToken(tokens)

	GT.Log:Info('Comm_IsPostValidFormat_IntroCheck', characterName, professionName, lastUpdate)

	if characterName == nil then
		GT.Log:Error('Comm_IsPostValidFormat_NilCharacterName')
		return false
	end

	if professionName == nil then
		GT.Log:Error('Comm_IsPostValidFormat_NilProfessionName')
		return false
	end

	if lastUpdate == nil or tonumber(lastUpdate) == nil then
		GT.Log:Error('Comm_IsPostValidFormat_InvalidLastUpdate', GT.Text:ToString(lastUpdate))
		return false
	end

	GT.Log:Info('Comm_IsPostValidFormat_ValidIntro', characterName, professionName, lastUpdate)

	while #tokens > 0 do
		local skillName, tokens = GT.Table:RemoveToken(tokens)
		local skillLink, tokens = GT.Table:RemoveToken(tokens)
		local uniqueReagentCount, tokens = GT.Table:RemoveToken(tokens)

		GT.Log:Info('Comm_IsPostValidFormat_SkillCheck', skillName, skillLink, GT.Text:ToString(uniqueReagentCount))

		if skillName == nil then
			GT.Log:Error('Comm_IsPostValidFormat_NilSkillName')
			return false
		end

		if skillLink == nil then
			GT.Log:Error('Comm_IsPostValidFormat_NilSkillLink')
			return false
		end

		if uniqueReagentCount == nil or tonumber(uniqueReagentCount) == nil then
			GT.Log:Error('Comm_IsPostValidFormat_InvalidReagentCount', GT.Text:ToString(uniqueReagentCount))
			return false
		end

		for i = 1, uniqueReagentCount do
			local reagentName, tokens = GT.Table:RemoveToken(tokens)
			local thisReagentCount, tokens = GT.Table:RemoveToken(tokens)

			GT.Log:Info('Comm_IsPostValidFormat_ReagentCheck', reagentName, GT.Text:ToString(thisReagentCount))

			if reagentName == nil or string.find(reagentName, ']') then
				GT.Log:Error('Comm_IsPostValidFormat_InvalidReagentName', GT.Text:ToString(reagentName))
				return false
			end

			if thisReagentCount == nil or tonumber(thisReagentCount) == nil then
				GT.Log:Error('Comm_IsPostValidFormat_InvalidReagentCount', GT.Text:ToString(reagentCount))
				return false
			end
		end
	end
	return true
end

function Comm:SendDeletions()
	GT.Log:Info('Comm_SendDeletions')

	local message = UnitName('player')
	local sendDelete = false
	local character = GT.DB:GetCharacter(message)

	for _, professionName in pairs(character.deletedProfessions) do
		message = GT.Text:Concat(DELIMITER, message, professionName)
		sendDelete = true
	end

	if sendDelete then
		Comm:_SendToOnline(DELETE, message)
	end
end

function Comm:OnDeleteReceived(prefix, message, distribution, sender)
	GT.Log:Info('Comm_OnDeleteReceived', prefix, distribution, sender, message)

	local tokens = GT.Text:Tokenize(message, DELIMITER)
	local characterName, tokens = GT.Table:RemoveToken(tokens)
	while #tokens > 0 do
		local professionName, tokens = GT.Table:RemoveToken(tokens)
		GT.DB:DeleteProfession(characterName, professionName)
	end
end

function Comm:SendVersion()
	local version = GT:GetCurrentVersion()
	GT.Log:Info('Comm_SendVersion', version)

	--[===[@non-debug@
	Comm:_SendToOnline(VERSION, tostring(version))
	--@end-non-debug@]===]
end

function Comm:OnVersionReceived(prefix, message, distribution, sender)
	GT.Log:Info('Comm_OnVersionReceived', prefix, distribution, sender, message)

	local lVersion = GT:GetCurrentVersion()
	local rVersion = tonumber(message)

	if rVersion == nil or lVersion > rVersion then
		GT.Log:Info('Comm_OnVersionReceived_RemoteUpdate', lVersion, rVersion)
		--[===[@non-debug@
		Comm:_SendToOnline(VERSION, tostring(version))
		--@end-non-debug@]===]
		return
	end

	if lVersion < rVersion then
		GT.Log:Info('Comm_OnVersionReceived_LocalUpdate', lVersion, rVersion)
		if GT.DB:ShouldNotifyUpdate(rVersion) then
			local lrVersion, lbVersion, laVersion = GT:DeconvertVersion(lVersion)
			local rrVersion, rbVersion, raVersion = GT:DeconvertVersion(rVersion)
			local message = string.gsub(L['UPDATE_AVAILABLE'], '%{{local_version}}', GT.Text:Concat('.', lrVersion, lbVersion, laVersion))
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

function Comm:_SendToOnline(prefix, msg)
	GT.Log:Info('Comm_SendToOnline', prefix, msg)
	local totalGuildMembers = GetNumGuildMembers()
	local currentCharacter = UnitName('player')
	for i = 1, totalGuildMembers do
		local characterName, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(i)
		if online then
			local tempCharacterName = GT.Text:ConvertCharacterName(characterName)
			if tempCharacterName ~= currentCharacter then
				GT.Log:Info('GT_Comm_SendToOnline', prefix, tempCharacterName, msg)
				Comm:SendCommMessage(prefix, msg, 'WHISPER', characterName, 'NORMAL')
			end
		end
	end
end

function Comm:GetDelimiter()
	return DELIMITER
end
