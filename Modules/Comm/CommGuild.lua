local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local CommGuild = GT:NewModule('CommGuild')
GT.CommGuild = CommGuild

LibStub('AceComm-3.0'):Embed(CommGuild)

-- 30 Days
CommGuild.INACTIVE_TIMEOUT = 30 * GT.DAY

local VOTE_DENY_VARIANCE = 30

local START_WINDOW = 5
local TIMESTAMP_WINDOW = 5
local VOTE_WINDOW = 5
local POST_WINDOW = 20
local VOTE_DURATION = START_WINDOW + TIMESTAMP_WINDOW + VOTE_WINDOW + POST_WINDOW

local START_VOTE = 'START_VOTE'
local START_VOTE_ACK = 'START_VOTE_ACK'
local START_VOTE_DENY = 'START_VOTE_DENY'
local VOTE = 'VOTE'

local COMMAND_MAP = {}
local STARTUP_TASKS = {}

local VOTE_STATE_PRE_VOTE = -1
local VOTE_STATE_START_REQUESTED = 0
local VOTE_STATE_REGISTERING = 1
local VOTE_STATE_TIMESTAMPS = 2
local VOTE_STATE_VOTING = 3
local VOTE_STATE_POSTING = 4

local voteStart = nil
local voteEnd = nil
local registeredVoters = {}
local timestampCollection = {}
local voteCollection = {}
local goneOffline = {}

local voteState = VOTE_STATE_PRE_VOTE

function CommGuild:OnEnable()
	GT.Log:Info('CommGuild_OnEnable')

	table.insert(STARTUP_TASKS, CommGuild['RollCall'])
	table.insert(STARTUP_TASKS, CommGuild['SendVersion'])
	table.insert(STARTUP_TASKS, CommGuild['SendDeletions'])
	table.insert(STARTUP_TASKS, CommGuild['RequestStartVote'])
	table.insert(STARTUP_TASKS, CommGuild['RemoveInactive'])

	COMMAND_MAP = {
		START_VOTE = 'OnRequestStartVoteReceived',
		START_VOTE_ACK = 'OnVoteStartAckReceived',
		START_VOTE_DENY = 'OnVoteStartDenyReceived',
		VOTE = 'OnVoteReceived',
	}

	for command, functionName in pairs(COMMAND_MAP) do
		CommGuild:RegisterComm(command, functionName)
	end
end

----- START STARTUP TASKS -----

function CommGuild:StartupTasks()
	GT:CreateActionQueue(GT.STARTUP_DELAY, STARTUP_TASKS)
end

function CommGuild:RollCall()
	for i = 1, GetNumGuildMembers() do
		local characterName, _, _, _, class, _, _, _, online = GetGuildRosterInfo(i)
		characterName = Ambiguate(characterName, 'none')
		if GT.DBCharacter:CharacterExists(characterName) then
			local character = GT.DBCharacter:GetCharacter(characterName)
			character.isOnline = online
			if class ~= nil and string.upper(class) ~= 'UNKNOWN' then
				character.class = string.upper(class)
			end
		end
	end
end

function CommGuild:SendDeletions()
	if not IsInGuild() then return end
	GT.Comm:SendDeletions(GT.Comm.GUILD, nil)
end

function CommGuild:SendVersion()
	if not IsInGuild() then return end
	GT.Comm:SendVersion(GT.Comm.GUILD, nil)
end

----- END STARTUP TASKS -----
----- START VOTE NEGOTIATION -----

function CommGuild:RequestStartVote()
	voteStart = time()
	GT.Log:Info('CommGuild_RequestStartVote', voteStart)
	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommGuild_RequestStartVote_CommDisabled')
		return
	end

	if not CommGuild:_IsInValidVoteState(VOTE_STATE_PRE_VOTE) then
		GT.Log:Info('CommGuild_RequestStartVote_InvalidVoteState', VOTE_STATE_PRE_VOTE, voteState)
		return
	end

	if not IsInGuild() then
		GT.Log:Info('CommGuild_RequestStartVote_NotInGuild')
		return
	end

	registeredVoters = {}
	timestampCollection = {}
	voteCollection = {}
	voteState = VOTE_STATE_START_REQUESTED
	CommGuild:SendCommMessage(START_VOTE, tostring(voteStart), GT.Comm.GUILD, nil, GT.Comm.NORMAL)
end

function CommGuild:OnRequestStartVoteReceived(prefix, message, distribution, sender)
	if GT:IsCurrentCharacter(sender) then return end

	if GT.DBCharacter:CharacterExists(sender) then
		local character = GT.DBCharacter:GetCharacter(sender)
		character.lastCommReceived = time()
	end

	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommGuild_OnRequestStartVoteReceived_CommDisabled')
		return
	end

	GT.Log:Info('CommGuild_OnRequestStartVoteReceived', sender, message)
	if tonumber(message) == nil then
		GT.Log:Error('CommGuild_OnRequestStartVoteReceived_InvalidVoteStart', sender, message)
		return
	end

	if voteState > VOTE_STATE_REGISTERING then
		GT.Log:Info('CommGuild_OnRequestStartVoteReceived_Deny', voteState, sender, message)
		CommGuild:SendCommMessage(START_VOTE_DENY, tostring(voteEnd + 1), GT.Comm.GUILD, nil, GT.Comm.ALERT)
		return
	end
	
	voteStart = tonumber(message)
	voteEnd = voteStart + VOTE_DURATION

	if voteState == VOTE_STATE_REGISTERING then
		GT.Log:Info('CommGuild_OnRequestStartVoteReceived_Registering', sender, voteStart)
		registeredVoters = Table:Insert(registeredVoters, nil, sender)
		CommGuild:SendCommMessage(START_VOTE_ACK, tostring(voteStart), GT.Comm.GUILD, nil, GT.Comm.NORMAL)
		return
	end

	GT.Log:Info('CommGuild_OnRequestStartVoteReceived_Ack', sender, message)

	voteState = VOTE_STATE_REGISTERING

	registeredVoters = {}
	timestampCollection = {}
	voteCollection = {}

	GT.Log:Info('CommGuild_OnRequestStartVoteReceived_RegisterSelf', GT:GetCharacterName())
	registeredVoters = Table:Insert(registeredVoters, nil, GT:GetCharacterName())
	registeredVoters = Table:Insert(registeredVoters, nil, sender)
	GT:ScheduleTimer(CommGuild['SendTimestamps'], START_WINDOW)
	CommGuild:SendCommMessage(START_VOTE_ACK, tostring(voteStart), GT.Comm.GUILD,  nil, GT.Comm.NORMAL)
end

function CommGuild:OnVoteStartAckReceived(prefix, message, distribution, sender)
	if GT:IsCurrentCharacter(sender) then return end

	if GT.DBCharacter:CharacterExists(sender) then
		local character = GT.DBCharacter:GetCharacter(sender)
		character.lastCommReceived = time()
	end

	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommGuild_OnVoteStartAckReceived_CommDisabled')
		return
	end

	GT.Log:Info('CommGuild_OnVoteStartAckReceived', sender, message)

	if tonumber(message) == nil then
		GT.Log:Error('CommGuild_OnVoteStartAckReceived_InvalidVoteStartAck', sender, message)
		return
	end

	if not CommGuild:_IsInValidVoteState(VOTE_STATE_REGISTERING) then
		GT.Log:Error('CommGuild_OnVoteStartAckReceived_InvalidVoteState', voteState, sender, message)
		return
	end

	local otherVoteStart = tonumber(message)

	if voteState < VOTE_STATE_REGISTERING then
		GT.Log:Info('CommGuild_OnVoteStartAckReceived_RegisterSelf', GT:GetCharacterName())
		registeredVoters = Table:Insert(registeredVoters, nil, GT:GetCharacterName())
		if otherVoteStart < voteStart then
			local wait = START_WINDOW - (voteStart - otherVoteStart)
			if wait <= 0 then
				CommGuild:SendTimestamps()
			else
				GT.ScheduleTimer(CommGuild['SendTimestamps'], wait)
			end
		else
			GT:ScheduleTimer(CommGuild['SendTimestamps'], START_WINDOW)
		end
	end

	GT.Log:Info('CommGuild_OnVoteStartAckReceived_Register', sender, message)
	voteState = VOTE_STATE_REGISTERING
	regiteredVoters = Table:Insert(registeredVoters, nil, sender)
end

function CommGuild:OnVoteStartDenyReceived(prefix, message, distribution, sender)
	if GT:IsCurrentCharacter(sender) then return end

	if GT.DBCharacter:CharacterExists(sender) then
		local character = GT.DBCharacter:GetCharacter(sender)
		character.lastCommReceived = time()
	end

	GT.Log:Info('CommGuild_OnVoteStartDenyReceived', sender, message)

	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommGuild_OnVoteStartDenyReceived_CommDisabled')
		return
	end

	if tonumber(message) == nil then
		GT.Log:Error('CommGuild_OnVoteStartDenyReceived_InvalidVoteDeny', sender, message)
		return
	end

	if not CommGuild:_IsInValidVoteState(VOTE_STATE_REGISTERING) then
		GT.Log:Error('CommGuild_OnVoteStartDenyReceived_InvalidVoteState', voteState, sender, message)
		return
	end

	voteState = VOTE_STATE_PRE_VOTE
	local reRequestTime = tonumber(message) + math.random(VOTE_DENY_VARIANCE)
	local waitTime = reRequestTime - time()
	GT.Log:Info('CommGuild_OnVoteStartDenyReceived_Waiting', sender, message, reRequestTime, waitTime)
	GT:ScheduleTimer(CommGuild['RequestStartVote'], waitTime)
end

----- END VOTE NEGOTIATION -----
----- START VOTING PROCESS -----

function CommGuild:SendTimestamps()
	GT.Log:Info('CommGuild_SendTimestamps')
	if voteState <= VOTE_STATE_START_REQUESTED then
		GT.Log:Info('Comm_SendTimestamps_NoResponses')
		return
	end
	local characters = GT.DBCharacter:GetCharacters()
	local characterStrings = {}
	for characterName, character in pairs(characters) do
		if character.isGuildMember then
			local characterString = GT.Comm:GetTimestampString(characterName)
			if characterString ~= nil then
				table.insert(characterStrings, characterString)
			end
		end
	end
	GT.Log:Info('CommGuild_SendTimestamps_Send', characterStrings)
	if #characterStrings > 0 then
		local message = table.concat(characterStrings, GT.Comm.DELIMITER)
		GT.Comm:SendCommMessage(GT.Comm.TIMESTAMP, message, GT.Comm.GUILD, nil, GT.Comm.NORMAL)
	end
end

function CommGuild:OnTimestampsReceived(sender, toGet, toPost)
	GT.Log:Info('CommGuild_OnTimestampsReceived', sender, toGet, toPost)

	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommGuild_OnTimestampsReceived_CommDisabled')
		return
	end

	if not CommGuild:_IsInValidVoteState(VOTE_STATE_TIMESTAMPS) then
		GT.Log:Error('CommGuild_OnTimestampsReceived_InvalidVoteState', voteState, sender, message)
		return
	end

	if not Table:Contains(registeredVoters, sender) then
		GT.Log:Error('CommGuild_OnTimestampsReceived_NotRegistered', sender, message)
		return
	end

	timestampCollection = CommGuild:_CollectTimestamps(sender, toGet)
	timestampCollection = CommGuild:_CollectTimestamps(sender, toPost)

	if voteState == VOTE_STATE_REGISTERING then
		GT:ScheduleTimer(CommGuild['DoVote'], VOTE_WINDOW)
	end
	voteState = VOTE_STATE_TIMESTAMPS
end

function CommGuild:DoVote()
	GT.Log:Info('CommGuild_DoVote_Enter', timestampCollection)

	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommGuild_DoVote_CommDisabled')
		return
	end

	if not CommGuild:_IsInValidVoteState(VOTE_STATE_TIMESTAMPS) then
		GT.Log:Error('CommGuild_DoVote_InvalidVoteState', voteState)
		return
	end

	voteState = VOTE_STATE_VOTING

	local votes = {}
	for characterName, _ in pairs(timestampCollection) do
		local character = timestampCollection[characterName]
		for professionName, _ in  pairs(character) do
			local profession = character[professionName]
			local candidates = profession.candidates
			local voteMessage = nil
			if Table:Contains(candidates, characterName) then
				voteMessage = Text:Concat(GT.Comm.DELIMITER, characterName, professionName, characterName)
			else
				local vote = Table:Random(candidates)
				local voteMessage = Text:Concat(GT.Comm.DELIMITER, characterName, professionName, vote)
			end
			table.insert(votes, voteMessage)
		end
	end

	if #votes > 0 then
		local message = table.concat(votes, GT.Comm.DELIMITER)
		GT.Log:Info('CommGuild_DoVote_Exit', message)
		GT.Comm:SendCommMessage(VOTE, message, GT.Comm.GUILD, nil, GT.Comm.NORMAL)
	end

	timestampCollection = {}

	GT:ScheduleTimer(CommGuild['FinalizeVote'], VOTE_WINDOW)
end

function CommGuild:OnVoteReceived(prefix, message, distribution, sender)
	GT.Log:Info('CommGuild_OnVoteReceived', sender, message)

	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommGuild_OnVoteReceived_CommDisabled')
		return
	end

	if not CommGuild:_IsInValidVoteState(VOTE_STATE_VOTING) then
		GT.Log:Error('CommGuild_OnVoteReceived_InvalidVoteState', voteState, sender, message)
		return
	end

	if not Table:Contains(registeredVoters, sender) then
		GT.Log:Error('CommGuild_OnVoteReceived_NotRegistered', sender, registeredVoters, message)
		return
	end

	if not GT.CommValidator:IsVoteValid(message) then
		GT.Log:Error('CommGuild_OnVoteReceived_InvalidVote', sender, message)
		return
	end

	voteState = VOTE_STATE_VOTING

	local tokens = Text:Tokenize(message, GT.Comm.DELIMITER)
	while #tokens > 0 do
		local characterName, tokens = Table:RemoveToken(tokens)
		local professionName, tokens = Table:RemoveToken(tokens)
		local vote, tokens = Table:RemoveToken(tokens)

		voteCollection = Table:InsertField(voteCollection, characterName)
		local character = voteCollection[characterName]
		character = Table:InsertField(character, professionName)
		local profession = character[professionName]
		if profession[vote] == nil then
			profession[vote] = 0
		end
		profession[vote] = profession[vote] + 1
	end
	GT.Log:Info('CommGuild_OnVoteReceived', voteCollection)
end

function CommGuild:FinalizeVote()
	GT.Log:Info('CommGuild_FinalizeVote', voteCollection)

	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommGuild_FinalizeVote_CommDisabled')
		return
	end

	if not CommGuild:_IsInValidVoteState(VOTE_STATE_POSTING) then
		GT.Log:Error('CommGuild_FinalizeVote_InvalidVoteState', voteState)
		return
	end

	voteState = VOTE_STATE_POSTING

	local winners = {}
	for characterName, _ in pairs(voteCollection) do
		winners = Table:InsertField(winners, characterName)
		local characterWin = winners[characterName]

		local character = voteCollection[characterName]
		for professionName, _ in pairs(character) do
			characterWin = Table:InsertField(characterWin, professionName)
			local professionWin = characterWin[professionName]

			local profession = character[professionName]

			local professionWinners = {}
			local winnerCount = 0
			for vote, voteCount in pairs(profession) do
				local didGoOffline = Table:Contains(goneOffline, vote)
				if voteCount > winnerCount and not didGoOffline then
					professionWinners = {}
				end
				if voteCount >= winnerCount and not didGoOffline then
					table.insert(professionWinners, vote)
					winnerCount = voteCount
				end
			end
			professionWin.winners = professionWinners
		end
	end

	GT.Log:Info('CommGuild_FinalizeVote_Winners', winners)

	for characterName, _ in pairs(winners) do
		local profession = winners[characterName]
		for professionName, _ in pairs(profession) do
			local winners = profession[professionName].winners

			local winner = nil
			if #winners > 1 then
				local keys = Table:GetSortedKeys(winners, nil, false)
				winner = winners[keys[1]]
			else
				winner = winners[1]
			end

			if GT:IsCurrentCharacter(winner) then
				GT.Log:Info('CommGuild_FinalizeVote_SelfWin', characterName, professionName, winner)
				GT.Comm:SendPost(GT.Comm.GUILD, characterName, professionName, nil)
			end
		end
	end

	GT:ScheduleTimer(CommGuild['FinalizePost'], POST_WINDOW)
end

function CommGuild:FinalizePost()
	GT.Log:Info('CommGuild_FinalizePost')

	voteState = VOTE_STATE_PRE_VOTE
	registeredVoters = {}
	timestampCollection = {}
	voteCollection = {}
	goneOffline = {}
	voteStart = nil
	voteEnd = nil
end

----- END VOTING PROCESS -----
----- START MAINTENANCE -----

function CommGuild:RemoveInactive()
	local characters = GT.DBCharacter:GetCharacters()
	local characterNames = {}
	for characterName, character in pairs(characters) do
		if not GT:IsCurrentCharacter(characterName) and character.isGuildMember then
			local lastUpdate = character.lastCommReceived

			local professions = character.professions
			for professionName, profession in pairs(professions) do
				if profession.lastUpdate > lastUpdate then
					lastUpdate = profession.lastUpdate
				end
			end

			if lastUpdate + CommGuild.INACTIVE_TIMEOUT < time() then
				GT.Log:Info('CommGuild_RemoveInactive_RemoveCharacter', characterName, lastUpdate, time())
				table.insert(characterNames, characterName)
				GT.DBCharacter:DeleteCharacter(characterName)
			end
		end
	end

	if #characterNames > 0 then
		local names = table.concat(characterNames, GT.L['PRINT_DELIMITER'])
		local days = tostring(math.floor(timeout / GT.DAY))

		local message = string.gsub(GT.L['REMOVE_GUILD_INACTIVE'], '%{{character_names}}', names)
		message = string.gsub(message, '%{{timeout_days}}', days)
		GT.Log:PlayerInfo(message)
	end
end

----- END MAINTENANCE -----

function CommGuild:OnPostReceived(sender, message)
	local tokens = Text:Tokenize(message, GT.Comm.DELIMITER)
	local characterName, tokens = Table:RemoveToken(tokens)

	local character = GT.DBCharacter:GetCharacter(characterName)
	if character == nil then
		character = GT.DBCharacter:AddCharacter(characterName)
		character.isGuildMember = true
		character.isBroadcasted = false
	end

	local professionName, tokens = Table:RemoveToken(tokens)
	local lastUpdate, tokens = Table:RemoveToken(tokens)
	lastUpdate = tonumber(lastUpdate)
	GT.Log:Info('CommGuild_OnPostReceived', sender, characterName, professionName, lastUpdate)

	local profession = GT.DBCharacter:GetProfession(characterName, professionName)

	if profession ~= nil and profession.lastUpdate > lastUpdate then
		GT.Log:Info('CommGuild_OnPostReceived_RemoteUpdate', characterName, professionName, profession.lastUpdate, lastUpdate)
		GT.Comm:SendPost(GT.Comm.GUILD, characterName, professionName, sender)
		return
	end

	if profession == nil or profession.lastUpdate < lastUpdate then
		local tempLastUpdate = nil
		if profession ~= nil then
			tempLastUpdate = profession.lastUpdate
		end
		GT.Log:Info('CommGuild_OnPostReceived_LocalUpdate', characterName, professionName, Text:ToString(tempLastUpdate), lastUpdate)
		GT.Comm:UpdateProfession(message)
	end
end

function CommGuild:ChatMessageSystem(message)
	local offlineName = message:match(string.gsub(ERR_FRIEND_OFFLINE_S, '(%%s)', '(.+)'))
	if offlineName ~= nil then
		if GT.DBCharacter:CharacterExists(offlineName) then
			local character = GT.DBCharacter:GetCharacter(offlineName)
			GT.Log:Info('CommGuild_ChatMessageSystem_Offline', offlineName)
			character.isOnline = false
		end
	end

	local onlineName = message:match(string.gsub(ERR_FRIEND_ONLINE_SS, '(%%s)', '(.+)'))
	if onlineName ~= nil then
		if GT.DBCharacter:CharacterExists(onlineName) then
			local character = GT.DBCharacter:GetCharacter(onlineName)
			GT.Log:Info('CommGuild_ChatMessageSystem_Online', onlineName)
			character.isOnline = true
		end
	end

	if voteState < VOTE_STATE_REGISTERING then
		return
	end

	if offlineName ~= nil then
		goneOffline = Table:Insert(goneOffline, nil, offlineName)
	end
	if onlineName ~= nil then
		goneOffline = Table:Insert(goneOffline, nil, onlineName)
	end
end

function CommGuild:_CollectTimestamps(sender, timestamps)
	GT.Log:Info('CommGuild_CollectTimestamps', sender, timestamps)
	local updateState = GT.Comm.NOT_UPDATED
	for characterName, _ in pairs(timestamps) do
		local character = timestamps[characterName]
		for professionName, _ in pairs(character) do
			local profession = character[professionName]
			timestampCollection, updateState = GT.Comm:_Update(timestampCollection, characterName, professionName, profession.lastUpdate)

			local profession = timestampCollection[characterName][professionName]
			if profession.candidates == nil or updateState == GT.Comm.UPDATED then
				profession.candidates = {}
			end
			local candidates = profession.candidates
			if updateState > GT.Comm.NOT_UPDATED then
				profession.candidates = Table:Insert(candidates, nil, sender)
			end
		end
	end
	GT.Log:Info('CommGuild_CollectTimestamps_Exit', timestampCollection)
	return timestampCollection
end

function CommGuild:_IsInValidVoteState(expectedVoteState)
	if voteState < expectedVoteState - 1 or voteState > expectedVoteState + 1 then
		return false
	end
	return true
end