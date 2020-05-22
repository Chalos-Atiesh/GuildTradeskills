local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local CommGuild = GT:NewModule('CommGuild')
GT.CommGuild = CommGuild

LibStub('AceComm-3.0'):Embed(CommGuild)

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
	GT.Log:Info('CommGuild_OnEnable_Enter')
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

function CommGuild:ChatMessageSystem(message)
	local _, _, characterName = string.find(message, GT.L['GUILD_MEMBER_OFFLINE'])
	if not characterName then return end

	if voteState < VOTE_STATE_REGISTERING then
		return
	end

	if not GT.Table:Contains(registeredVoters, characterName) then
		return
	end

	GT.Log:Info('CommGuild_ChatMessageSystem', characterName)
	table.insert(goneOffline, characterName)
end

---------- START VOTE NEGOTIATION ----------

function CommGuild:RequestStartVote()
	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommGuild_RequestStartVote_CommDisabled')
		return
	end

	if voteState ~= VOTE_STATE_PRE_VOTE then
		GT.Log:Info('CommGuild_RequestStartVote_InvalidVoteState', voteState)
		return
	end
	voteStart = time()
	GT.Log:Info('CommGuild_RequestStartVote', voteStart)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommGuild_RequestStartVote_CommDisabled')
		return
	end

	registeredVoters = {}
	timestampCollection = {}
	voteCollection = {}
	voteState = VOTE_STATE_START_REQUESTED
	CommGuild:SendCommMessage(START_VOTE, tostring(voteStart), GT.Comm.GUILD, nil, GT.Comm.ALERT)
end

function CommGuild:OnRequestStartVoteReceived(prefix, message, distribution, sender)
	if GT:IsCurrentCharacter(sender) then return end

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommGuild_OnRequestStartVoteReceived_CommDisabled')
		return
	end

	GT.Log:Info('CommGuild_OnRequestStartVoteReceived', sender, message)
	if not GT.CommValidator:IsVoteStartValid(message) then
		GT.Log:Error('CommGuild_OnRequestStartVoteReceived_InvalidVoteStart', sender, message)
		return
	end

	if voteState > VOTE_STATE_REGISTERING then
		GT.Log:Info('CommGuild_OnRequestStartVoteReceived_Deny', voteState, sender, message)
		CommGuild:SendCommMessage(START_VOTE_DENY, tostring(voteEnd + 1), GT.Comm.GUILD, nil, GT.Comm.ALERT)
		return
	end

	if voteState == VOTE_STATE_REGISTERING then
		GT.Log:Info('CommGuild_OnRequestStartVoteReceived_Registering', sender, voteStart)
		registeredVoters = GT.Table:Insert(registeredVoters, nil, sender)
		CommGuild:SendCommMessage(START_VOTE_ACK, tostring(voteStart), GT.Comm.GUILD, nil, GT.Comm.ALERT)
		return
	end

	GT.Log:Info('CommGuild_OnRequestStartVoteReceived_Ack', sender, message)

	voteState = VOTE_STATE_REGISTERING
	voteStart = tonumber(message)
	voteEnd = voteStart + VOTE_DURATION

	registeredVoters = {}
	timestampCollection = {}
	voteCollection = {}

	GT.Log:Info('CommGuild_OnRequestStartVoteReceived_RegisterSelf', GT:GetCurrentCharacter())
	registeredVoters = GT.Table:Insert(registeredVoters, nil, GT:GetCurrentCharacter())
	registeredVoters = GT.Table:Insert(registeredVoters, nil, sender)
	GT:Wait(START_WINDOW, CommGuild['SendTimestamps'])
	CommGuild:SendCommMessage(START_VOTE_ACK, tostring(voteStart), GT.Comm.GUILD,  nil, GT.Comm.ALERT)
end

function CommGuild:OnVoteStartAckReceived(prefix, message, distribution, sender)
	if GT:IsCurrentCharacter(sender) then return end

	GT.Log:Info('CommGuild_OnVoteStartAckReceived', sender, message)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommGuild_OnVoteStartAckReceived_CommDisabled')
		return
	end

	if not GT.CommValidator:IsVoteStartValid(message) then
		GT.Log:Error('CommGuild_OnVoteStartAckReceived_InvalidVoteStartAck', sender, message)
		return
	end

	if voteState > VOTE_STATE_REGISTERING then
		GT.Log:Error('CommGuild_OnVoteStartAckReceived_InvalidVoteState', voteState, sender, message)
		return
	end

	if voteState < VOTE_STATE_REGISTERING then
		GT.Log:Info('CommGuild_OnVoteStartAckReceived_RegisterSelf', GT:GetCurrentCharacter())
		registeredVoters = GT.Table:Insert(registeredVoters, nil, GT:GetCurrentCharacter())
		GT:Wait(START_WINDOW, CommGuild['SendTimestamps'])
	end

	GT.Log:Info('CommGuild_OnVoteStartAckReceived_Register', sender, message)
	voteState = VOTE_STATE_REGISTERING
	regiteredVoters = GT.Table:Insert(registeredVoters, nil, sender)
end

function CommGuild:OnVoteStartDenyReceived(prefix, message, distribution, sender)
	if GT:IsCurrentCharacter(sender) then return end

	GT.Log:Info('CommGuild_OnVoteStartDenyReceived', sender, message)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommGuild_OnVoteStartDenyReceived_CommDisabled')
		return
	end

	if not GT.CommValidator:IsVoteStartValid(message) then
		GT.Log:Error('CommGuild_OnVoteStartDenyReceived_InvalidVoteDeny', sender, message)
		return
	end

	if voteState > VOTE_STATE_REGISTERING then
		GT.Log:Error('CommGuild_OnVoteStartDenyReceived_InvalidVoteState', voteState, sender, message)
		return
	end

	voteState = VOTE_STATE_PRE_VOTE
	local reRequestTime = tonumber(message) + math.random(VOTE_DENY_VARIANCE)
	local waitTime = reRequestTime - time()
	GT.Log:Info('CommGuild_OnVoteStartDenyReceived_Waiting', sender, message, reRequestTime, waitTime)
	GT:Wait(waitTime, CommGuild['RequestStartVote'])
end

---------- END VOTE NEGOTIATION ----------
---------- START VOTING PROCESS ----------

function CommGuild:SendTimestamps()
	GT.Log:Info('CommGuild_SendTimestamps')
	if voteState <= VOTE_STATE_START_REQUESTED then
		GT.Log:Info('Comm_SendTimestamps_NoResponses')
		return
	end
	GT.Comm:SendTimestamps(GT.Comm.GUILD, nil)
end

function CommGuild:OnTimestampsReceived(sender, toGet, toPost)
	GT.Log:Info('CommGuild_OnTimestampsReceived', sender, toGet, toPost)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommGuild_OnTimestampsReceived_CommDisabled')
		return
	end

	if voteState > VOTE_STATE_TIMESTAMPS
		or voteState < VOTE_STATE_REGISTERING
	then
		GT.Log:Error('CommGuild_OnTimestampsReceived_InvalidVoteState', voteState, sender, message)
		return
	end

	if not GT.Table:Contains(registeredVoters, sender) then
		GT.Log:Error('CommGuild_OnTimestampsReceived_NotRegistered', sender, message)
		return
	end

	timestampCollection = CommGuild:_CollectTimestamps(sender, toGet)
	timestampCollection = CommGuild:_CollectTimestamps(sender, toPost)

	if voteState == VOTE_STATE_REGISTERING then
		GT.Log:Info('CommGuild_OnTimestampsReceived_ScheduleVote')
		GT:Wait(VOTE_WINDOW, CommGuild['DoVote'])
	end
	voteState = VOTE_STATE_TIMESTAMPS
end

function CommGuild:DoVote()
	GT.Log:Info('CommGuild_DoVote_Enter', timestampCollection)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommGuild_DoVote_CommDisabled')
		return
	end

	if voteState < VOTE_STATE_TIMESTAMPS then
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
			local vote = GT.Table:Random(candidates)
			local voteMessage = GT.Text:Concat(GT.Comm.DELIMITER, characterName, professionName, vote)
			table.insert(votes, voteMessage)
		end
	end

	local message = table.concat(votes, GT.Comm.DELIMITER)
	GT.Log:Info('CommGuild_DoVote_Exit', message)
	GT.Comm:SendCommMessage(VOTE, message, GT.Comm.GUILD, nil, 'NORMAL')

	timestampCollection = {}

	GT:Wait(VOTE_WINDOW, CommGuild['FinalizeVote'])
end

function CommGuild:OnVoteReceived(prefix, message, distribution, sender)
	GT.Log:Info('CommGuild_OnVoteReceived', sender, message)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommGuild_OnVoteReceived_CommDisabled')
		return
	end

	if voteState < VOTE_STATE_TIMESTAMPS
		or voteState > VOTE_STATE_VOTING
	then
		GT.Log:Error('CommGuild_OnVoteReceived_InvalidVoteState', voteState, sender, message)
		return
	end

	if not GT.Table:Contains(registeredVoters, sender) then
		GT.Log:Error('CommGuild_OnVoteReceived_NotRegistered', sender, registeredVoters, message)
		return
	end

	if not GT.CommValidator:IsVoteValid(message) then
		GT.Log:Error('CommGuild_OnVoteReceived_InvalidVote', sender, message)
		return
	end

	voteState = VOTE_STATE_VOTING

	local tokens = GT.Text:Tokenize(message, GT.Comm.DELIMITER)
	while #tokens > 0 do
		local characterName, tokens = GT.Table:RemoveToken(tokens)
		local professionName, tokens = GT.Table:RemoveToken(tokens)
		local vote, tokens = GT.Table:RemoveToken(tokens)

		voteCollection = GT.Table:InsertField(voteCollection, characterName)
		local character = voteCollection[characterName]
		character = GT.Table:InsertField(character, professionName)
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

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommGuild_FinalizeVote_CommDisabled')
		return
	end

	if voteState ~= VOTE_STATE_VOTING then
		GT.Log:Error('CommGuild_FinalizeVote_InvalidVoteState', voteState)
		return
	end

	voteState = VOTE_STATE_POSTING

	local winners = {}
	for characterName, _ in pairs(voteCollection) do
		winners = GT.Table:InsertField(winners, characterName)
		local characterWin = winners[characterName]

		local character = voteCollection[characterName]
		for professionName, _ in pairs(character) do
			characterWin = GT.Table:InsertField(characterWin, professionName)
			local professionWin = characterWin[professionName]

			local profession = character[professionName]

			local professionWinners = {}
			local winnerCount = 0
			for vote, voteCount in pairs(profession) do
				local didGoOffline = GT.Table:Contains(goneOffline, vote)
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
				local keys = GT.Table:GetSortedKeys(winners, nil, false)
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

	GT:Wait(POST_WINDOW, CommGuild['FinalizePost'])
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

---------- END VOTING PROCESS ----------

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
				profession.candidates = GT.Table:Insert(candidates, nil, sender)
			end
		end
	end
	GT.Log:Info('CommGuild_CollectTimestamps_Exit', timestampCollection)
	return timestampCollection
end