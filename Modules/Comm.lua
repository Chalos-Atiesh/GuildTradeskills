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
		GT.Log:Info('Comm_RegisterComm', command, functionName)
		Comm:RegisterComm(command, functionName)
	end
end

function Comm:SendTimestamps()
	GT.Log:Info('Comm_SendTimestamps')

	local characters = GT.DB:GetCharacters()
	local msg = ''
	for characterName, _ in pairs(characters) do
		local professions = characters[characterName].professions
		for professionName, _ in pairs(professions) do
			local profession = professions[professionName]
			msg = msg .. GT.Text:Concat(DELIMITER, characterName, professionName, profession.lastUpdate)
		end
	end
	Comm:_SendToOnline(TIMESTAMP, msg)
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
		end

		if profession.lastUpdate < timestamp then
			if toGet[characterName] == nil then
				toGet[characterName] = {}
			end
			if not GT.Table:Contains(toGet[characterName], professionName) then
				GT.Log:Info('Comm_OnTimestampsReceived_LocalOutOfDate', characterName, professionName, profession.lastUpdate, timestamp)
				table.insert(toGet[characterName], professionName)
			end
		end

		if profession.lastUpdate > timestamp then
			if toPost[characterName] == nil then
				toPost[characterName] = {}
			end
			if not GT.Table:Contains(toPost[characterName], professionName) then
				GT.Log:Info('Comm_OnTimestampsReceived_RemoteOutOfDate', characterName, professionName, profession.lastUpdate, timestamp)
				table.insert(toPost[characterName], professionName)
			end
		end

		local characters = GT.DB:GetCharacters()
		for characterName, _ in pairs(characters) do
			if all[characterName] == nil then
				if toPost[characterName] == nil then
					toPost[characterName] = {}
				end
			end

			local professions = characters[characterName].professions
			for professionName, _ in pairs(professions) do
				if not GT.Table:Contains(all[characterName], professionName) and
					not GT.Table:Contains(toPost[characterName], professionName)
				then
					if not GT.Table:Contains(toPost[characterName], professionName) then
						GT.Log:Info('Comm_OnTimestampsReceived_RemoteNil', characterName, professionName)
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
		for _, professionName in pairs(toPost[characterName]) do
			Comm:SendPost(characterName, professionName, sender)
		end
	end
end

function Comm:SendGet(characterName, professionName, recipient)
	GT.Log:Info('Comm_SendGet', characterName, professionName, recipient)

	local message = GT.Text:Concat(DELIMITER, characterName, professionName)

	GT.Log:Info('Comm_SendGet_Send', recipient, message)
	Comm:SendCommMessage(GET, message, 'WHISPER', recipient, 'NORMAL')
end

function Comm:OnGetReceived(prefix, message, distribution, sender)
	GT.Log:Info('Comm_OnGetReceived', prefix, distribution, sender, message)
end

function Comm:SendPost(characterName, professionName, recipient)
	GT.Log:Info('Comm_SendPost', characterName, professionName, recipient)

	local profession = GT.DB:GetProfession(characterName, professionName)

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

	local tokens = GT.Text:Tokenize(message, DELIMITER)
	
	local characterName, tokens = GT.Table:RemoveToken(tokens)
	local professionName, tokens = GT.Table:RemoveToken(tokens)
	local lastUpdate, tokens = GT.Table:RemoveToken(tokens)
	lastUpdate = tonumber(lastUpdate)


	local update = false
	local profession = GT.DB:GetProfession(characterName, professionName)
	if profession ~= nil and profession.lastUpdate > lastUpdate then
		GT.Log:Info('Comm_OnPostReceived_RemoteOutOfDate', sender, characterName, professionName)
		Comm:SendPost(characterName, professionName, sender)
		return
	elseif profession == nil or profession.lastUpdate < lastUpdate then
		GT.Log:Info('Comm_OnPostReceived_LocalOutOfDate', characterName, professionName)
		profession = GT.DB:AddProfession(characterName, professionName)
		profession.lastUpdate = lastUpdate
		update = true
	end

	if update then
		while #tokens > 0 do
			local skillName, tokens = GT.Table:RemoveToken(tokens)
			local skillLink, tokens = GT.Table:RemoveToken(tokens)
			local reagentCount, tokens = GT.Table:RemoveToken(tokens)
			reagentCount = tonumber(reagentCount)

			local skill = GT.DB:AddSkill(characterName, professionName, skillName, skillLink)

			for i = 1, reagentCount do
				local reagentName, tokens = GT.Table:RemoveToken(tokens)
				local reagentCount, tokens = GT.Table:RemoveToken()

				GT.DB:AddReagent(professionName, skillName, skillLink)
			end
		end
	end
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

	local tokens = GT.Text:Tokenize(message)
	local characterName, tokens = GT.Table:RemoveToken(tokens)
	while #tokens > 0 do
		local professionName, tokens = GT.Table:RemoveToken(tokens)
		GT.DB:DeleteProfession(characterName, professionName)
	end
end

function Comm:SendVersion()
	local releaseVersion, betaVersion, alphaVersion = GT.DB:GetCurrentVersion()
	GT.Log:Info('Comm_SendVersion', releaseVersion, betaVersion, alphaVersion)

	local message = GT.Text:Concat(DELIMITER, releaseVersion, betaVersion, alphaVersion)
	--[===[@non-debug@
	Comm:_SendToOnline(VERSION, message)
	--@end-non-debug@]===]
end

function Comm:OnVersionReceived(prefix, message, distribution, sender)
	GT.Log:Info('Comm_OnVersionReceived', prefix, distribution, sender, message)

	local lReleaseV, lBetaV, lAlphaV = GT.DB:GetCurrentVersion()

	local tokens = GT.Text:Tokenize(message)
	local rReleaseV, tokens = GT.Table:RemoveToken(tokens)
	local rBetaV, tokens = GT.Table:RemoveToken(tokens)
	local rAlphaV, tokens = GT.Table:RemoveToken(tokens)

	rReleaseV = tonumber(rReleaseV)
	rBetaV = tonumber(rBetaV)
	rAlphaV = tonumber(rAlphaV)

	local lStringV = GT.Text:Concat('.', lReleaseV, lBetaV, lAlphaV)
	local rStingV = GT.Text:Concat('.', rReleaseV, rBetaV, rAlphaV)

	if lReleaseV > rReleaseV then
		GT.Log:Info('Comm_OnVersionReceived_RemoteUpdate', lStringV, rStingV)
		local message = GT.Text:Concat(DELIMITER, lReleaseV, lBetaV, lAlphaV)
		Comm:SendCommMessage(VERSION, message)
		return
	end

	if lReleaseV < rReleaseV then
		GT.Log:Info('Comm_OnVersionReceived_LocalUpdate', lStringV, rStingV)
		if GT.DB:ShouldNotifyUpdate(rReleaseV, rBetaV, rAlphaV) then
			local message = string.gsub(L['UPDATE_AVAILABLE'], '%{{local_version}}', lStringV)
			message = string.gsub(message, '%{{remote_version}}', rStingV)
			GT.Log:PlayerInfo(message)
			GT.DB:UpdateNotified(rReleaseV, rBetaV, rAlphaV)
		else
			GT.Log:Info('Comm_OnVersionReceived_AlreadyNotified', lStringV, rStingV)
		end
		return
	end
	GT.Log:Info('Comm_OnVersionReceived_UpToDate', lStringV, rStingV)
end

function Comm:_SendToOnline(prefix, msg)
	GT.Log:Info('Comm_SendToOnline', prefix, msg)
	local totalGuildMembers = GetNumGuildMembers()
	local currentCharacter = UnitName('player')
	for i = 1, totalGuildMembers do
		local characterName, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(i)
		if online then
			--[===[@non-debug@
			if not GT.Text:ConvertCharacterName(characterName) == currentCharacter then
			--@end-non-debug@]===]
				GT.Log:Info('GT_Comm_SendToOnline', prefix, characterName, msg)
				Comm:SendCommMessage(prefix, msg, 'WHISPER', characterName, 'NORMAL')
			--[===[@non-debug@
			end
			--@end-non-debug@]===]
		end
	end
end

function Comm:GetDelimiter()
	return DELIMITER
end