local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local CommWhisper = GT:NewModule('CommWhisper')
GT.CommWhisper = CommWhisper

LibStub('AceComm-3.0'):Embed(CommWhisper)

local REQUEST_INTERVAL = 15

local GET = 'GET'
local REQUEST = 'REQUEST'
local CONFIRM = 'CONFIRM'
local REJECT = 'REJECT'
local IGNORE = 'IGNORE'

local TIMEOUT = 7 * 24 * 60 * 60
local MAX_REQUEST = 50
local IGNORE_THRESHOLD = 3

local COMMAND_MAP = {}

local COMM_QUEUES = {
	REQUEST,
	CONFIRM,
	REJECT,
	IGNORE
}

local COMM_QUEUE_INCOMING_STRING_MAP = {
	REQUEST = 'COMM_QUEUE_INCOMING_REQUEST',
	CONFIRM = 'COMM_QUEUE_INCOMING_CONFIRM',
	REJECT = 'COMM_QUEUE_INCOMING_REJECT',
	IGNORE = 'COMM_QUEUE_INCOMING_IGNORE'
}

local COMM_QUEUE_OUTGOING_STRING_MAP = {
	REQUEST = 'COMM_QUEUE_OUTGOING_REQUEST',
	CONFIRM = 'COMM_QUEUE_OUTGOING_CONFIRM',
	REJECT = 'COMM_QUEUE_OUTGOING_REJECT',
	IGNORE = 'COMM_QUEUE_OUTGOING_IGNORE'
}

local COMM_QUEUE_INCOMING_TIMEOUT_MAP = {
	REQUEST = 'COMM_QUEUE_INCOMING_REQUEST_TIMEOUT',
	CONFIRM = 'COMM_QUEUE_INCOMING_CONFIRM_TIMEOUT',
	REJECT = 'COMM_QUEUE_INCOMING_REJECT_TIMEOUT',
	IGNORE = 'COMM_QUEUE_INCOMING_IGNORE_TIMEOUT'
}

local COMM_QUEUE_OUTGOING_TIMEOUT_MAP = {
	REQUEST = 'COMM_QUEUE_OUTGOING_REQUEST_TIMEOUT',
	CONFIRM = 'COMM_QUEUE_OUTGOING_CONFIRM_TIMEOUT',
	REJECT = 'COMM_QUEUE_OUTGOING_REJECT_TIMEOUT',
	IGNORE = 'COMM_QUEUE_OUTGOING_IGNORE_TIMEOUT'
}

local COMM_QUEUE_INCOMING_OFFLINE_MAP = {
	REQUEST = 'COMM_QUEUE_INCOMING_REQUEST_OFFLINE',
	CONFIRM = 'COMM_QUEUE_INCOMING_CONFIRM_OFFLINE',
	REJECT = 'COMM_QUEUE_INCOMING_REJECT_OFFLINE',
	IGNORE = 'COMM_QUEUE_INCOMING_IGNORE_OFFLINE'
}

local COMM_QUEUE_OUTGOING_OFFLINE_MAP = {
	REQUEST = 'COMM_QUEUE_OUTGOING_REQUEST_OFFLINE',
	CONFIRM = 'COMM_QUEUE_OUTGOING_CONFIRM_OFFLINE',
	REJECT = 'COMM_QUEUE_OUTGOING_REJECT_OFFLINE',
	IGNORE = 'COMM_QUEUE_OUTGOING_IGNORE_OFFLINE'
}

local playerInitiatedComm = nil

function CommWhisper:OnEnable()
	GT.Log:Info('CommWhisper_OnEnable')

	for _, command in pairs(COMM_QUEUES) do
		GT.DB:InitCommQueue(true, command)
		GT.DB:InitCommQueue(false, command)
	end

	COMMAND_MAP = {
		GET = 'OnGetReceived',
		REQUEST = 'OnRequestReceived',
		CONFIRM = 'OnConfirmReceived',
		REJECT = 'OnRejectReceived',
		IGNORE = 'OnIgnoreReceived'
	}

	for command, functionName in pairs(COMMAND_MAP) do
		CommWhisper:RegisterComm(command, functionName)
	end
end

function CommWhisper:SendRequest(characterName)
	GT.Log:Info('CommWhisper_SendRequest', characterName)
	characterName = GT.Table:RemoveToken(characterName)
	if characterName == nil then
		GT.Log:PlayerWarn(GT.L['REQUEST_CHARACTER_NIL'])
		return
	end

	local queue, uuid = GT.DB:GetCommQueueForCharacter(true, characterName)
	if queue ~= nil and queue.command == REQUEST then
		playerInitiatedComm = characterName
		GT.Log:Info('CommWhisper_SendConfirm', false, queue.command, uuid, characterName)

		local character = GT.DB:GetCharacter(characterName)
		character.isRando = true
		
		GT.DB:RemovePendingComm(true, queue.command, uuid, characterName)
		GT.DB:AddPendingComm(false, CONFIRM, uuid, characterName)
		GT.Friends:IsOnline(characterName, CommWhisper['SendComm'])
		return
	end

	local queues = DB:GetCommQueues()
	local requestCount = 0
	for command, _ in pairs(queues) do
		local queue = queues[command]
		for uuid, _ in pairs(queue) do
			local uuidQueue = queue[uuid]
			for characterName, _ in pairs(uuidQueue) do
				requestCount = requestCount + 1
			end
		end
	end
	if requestCount >= MAX_REQUEST then
		local message = string.gsub(GT.L['REQUEST_MAX_COUNT'], '%{{max_requests}}', MAX_REQUEST)
		GT.Log:PlayerWarn(message)
		return
	end

	local added = GT.DB:AddPendingComm(false, REQUEST, GT.DB:GetUUID(), characterName)
	if not added then
		local message = string.gsub(GT.L['REQUEST_OUTGOING_REPEAT'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)
		return
	end

	playerInitiatedComm = characterName
	GT.Friends:IsOnline(characterName, CommWhisper['SendComm'])
end

function CommWhisper:OnRequestReceived(prefix, uuid, distribution, sender)
	GT.Log:Info('CommWhisper_OnRequestReceived', distribution, sender, uuid)
	if not GT.Text:IsUUIDValid(uuid) then
		GT.Log:Error('CommWhisper_OnRequestReceived_Invalid', sender, uuid)
		return
	end
	local pendingComm = DB:GetPendingComm(true, REQUEST, uuid, sender)
	if pendingComm ~= nil then
		GT.Log:Warn('CommWhisper_OnRequestReceived_Repeat', sender, uuid)
		return
	end

	GT.DB:AddPendingComm(true, REQUEST, uuid, sender)
	local message = string.gsub(GT.L['PLAYER_REQUEST_RECEIVED'], '%{{character_name}}', sender)
	GT.Log:PlayerInfo(message)
end

function CommWhisper:OnConfirmReceived(prefix, uuid, distribution, sender)
	GT.Log:Info('CommWhisper_OnConfirmReceived', distribution, sender, uuid)
	if not GT.Text:IsUUIDValid(uuid) then
		GT.Log:Error('CommWhisper_OnConfirmReceived_Invalid', sender, uuid)
		return
	end
	local pendingComm = DB:GetPendingComm(true, CONFIRM, uuid, characterName)
	if pendingComm == nil then
		GT.Log:Warn('CommWhisper_OnConfirmReceived_Unexpected', sender, uuid)
		return
	end

	GT.DB:RemovePendingComm(true, CONFIRM, uuid, characterName)

	if GT.DB:CharacterExists(sender) then
		GT.Log:Warn('CommWhisper_OnConfirmReceived_CharacterExists', sender, uuid)
		return
	end

	local character = GT.DB:GetCharacter(characterName)
	character.isRando = true
	local message = string.gsub(GT.L['COMM_QUEUE_INCOMING_CONFIRM'], '%{{character_name}}', sender)
	GT.Log:PlayerInfo(message)
end

function CommWhisper:SendReject(characterName)
	GT.Log:Info('CommWhisper_InitSendRequest', characterName)
	characterName = GT.Table:RemoveToken(characterName)
	if characterName == nil then
		GT.Log:PlayerWarn(GT.L['REJECT_CHARACTER_NIL'])
		return
	end

	local queue, uuid = GT.DB:GetCommQueueForCharacter(true, characterName)
	if queue == nil or queue.command ~= REQUEST then
		local message = string.gsub(GT.L['REJECT_CHARACTER_NOT_FOUND'], '%{{character_name}}', characterName)
		GT.Log:PlayerWarn(message)
		return
	end

	GT.DB:RemovePendingComm(true, REQUEST, uuid, characterName)
	GT.DB:AddPendingComm(false, REJECT, uuid, characterName)
	local rejectionCount = GT.DB:IncrementRejectionCount(false, uuid)
	local message = nil
	if rejectionCount == IGNORE_THRESHOLD then
		message = string.gsub(GT.L['REJECT_AUTO_IGNORE'], '%{{ignore_threshold}}', IGNORE_THRESHOLD)
		GT.DB:AddIgnore(false, uuid)
	elseif rejectionCount < IGNORE_THRESHOLD then
		message = string.gsub(GT.L['REJECT_COUNT_WARN'], '%{{ignore_count}}', tostring(rejectionCount))
		message = string.gsub(message, '%{{ignore_threshold}}', IGNORE_THRESHOLD)
	else
		message = GT.L['REJECT_THRESHOLD_EXCEEDED']
		GT.DB:AddIgnore(false, uuid)
		return
	end
	GT.Log:PlayerWarn(message)


end

function CommWhisper:OnRejectReceived(prefix, uuid, distribution, sender)
	GT.Log:Info('CommWhisper_OnRejectReceived', distribution, sender, uuid)
	if not GT.Text:IsUUIDValid(uuid) then
		GT.Log:Error('CommWhisper_OnRejectReceived_Invalid', sender, uuid)
		return
	end

	local pendingComm = DB:GetPendingComm(true, CONFIRM, uuid, characterName)
	if pendingComm == nil then
		GT.Log:Warn('CommWhisper_OnRejectReceived_Unexpected', sender, uuid)
		return
	end

	GT.DB:RemovePendingComm(true, CONFIRM, uuid, characterName)
	GT.DB:IncrementRejectionCount(true, uuid)

	local message = string.gsub(GT.L['COMM_QUEUE_INCOMING_REJECT'], '%{{character_name}}', sender)
	GT.Log:PlayerWarn(message)
end

function CommWhisper:OnIgnoreReceived(prefix, uuid, distribution, sender)
	GT.Log:Info('CommWhisper_OnIgnoreReceived', distribution, sender, uuid)
	if not GT.Text:IsUUIDValid(uuid) then
		GT.Log:Error('CommWhisper_OnRejectReceived_Invalid', sender, uuid)
		return
	end

	if GT.DB:IsIgnored(true, uuid) then
		GT.Log:Warn('CommWhisper_OnIgnoreReceived_Repeat', sender, uuid)
		return
	end

	GT.DB:AddIgnore(true, uuid)

	GT.DB:RemovePendingComm(true, REQUEST, uuid, characterName)
	GT.DB:RemovePendingComm(true, CONFIRM, uuid, characterName)
	GT.DB:RemovePendingComm(true, REJECT, uuid, characterName)

	GT.DB:RemovePendingComm(false, REQUEST, uuid, characterName)
	GT.DB:RemovePendingComm(false, CONFIRM, uuid, characterName)
	GT.DB:RemovePendingComm(false, REJECT, uuid, characterName)

	local message = string.gsub(GT.L['COMM_QUEUE_INCOMING_IGNORE'], '%{{character_name}}', sender)
	GT.Log:PlayerError(message)
end

function CommWhisper:SendComm(characterName, isOnline)
	local queue, uuid = GT.DB:GetCommQueueForCharacter(false, characterName)
	if playerInitiatedComm ~= nil then
		GT.Log:Info('CommWhisper_SendComm', false, queue.command, uuid, characterName, isOnline)
		if not isOnline or queue == nil then
			local stringKey = COMM_QUEUE_OUTGOING_OFFLINE_MAP[queue.command]
			local message = string.gsub(GT.L[stringKey], '%{{character_name}}', characterName)
			GT.Log:PlayerInfo(message)
			playerInitiatedComm = nil
			return
		end
	end
	if not isOnline then return end

	CommWhisper:SendCommMessage(queue.command, uuid, GT.Comm.WHISPER, characterName, 'NORMAL')
	GT.DB:RemovePendingComm(false, queue.command, uuid, characterName)
	GT.DB:AddPendingComm(true, queue.command, uuid, characterName)
	local stringKey = COMM_QUEUE_OUTGOING_STRING_MAP[queue.command]
	local message = string.gsub(GT.L[stringKey], '%{{character_name}}', characterName)
	GT.Log:PlayerInfo(message)
	playerInitiatedComm = nil
end

function CommWhisper:ChatMessageSystem(message)
	if playerInitiatedComm ~= nil
		and string.find(message, GT.L['PLAYER_REQUEST_SYSTEM_NOT_FOUND'])
	then
		local message = string.gsub(GT.L['PLAYER_REQUEST_NOT_FOUND'], '%{{character_name}}', playerInitiatedComm)
		GT.Log:PlayerWarn(message)
		playerInitiatedComm = nil
		GT.Friends:CancelIsOnline()
		CommWhisper:ProcessPendingRequests()
	end
end





function CommWhisper:SendTimestamps()
	GT.Log:Info('CommWhisper_SendTimestamps')
	-- GT.Comm:SendTimestamps(GT.Comm.WHISPER, )
end

function CommWhisper:ProcessPendingComms()
	GT.Friends:CancelIsOnline()

	local commQueues = GT.DB:GetCommQueues()
	for command, _ in pairs(commQueues) do
		local commQueue = commQueues[command]
		local command = commQueue.command
		local queue = commQueue.queue
		for uuid, _ in pairs(queue) do
			local uuidQueue = queue[uuid]
			for characterName, timestamp in pairs(uuidQueue) do
				CommWhisper:ProcessPendingComm(queue, uuid, characterName, timestamp)
			end
		end
	end
	GT:Wait(REQUEST_INTERVAL, CommWhisper['ProcessPendingComms'])
end

function CommWhisper:ProcessPendingComm(queue, uuid, characterName, timestamp)
	GT.Log:Info('CommWhisper_ProcessPendingComm', queue.queueName, queue.command, uuid, characterName, timestamp)
	if timestamp + REQUEST_TIMEOUT < time() then
		local removed = GT.DB:RemovePendingComm(queueName, uuid, characterName)
		if removed then
			local stringKey = COMM_QUEUE_TIMEOUT_MAP[queueName]
			local message = string.gsub(GT.L[stringKey], '%{{character_name}}', characterName)
			GT.Log:PlayerWarn(message)
		end
		return
	end
	GT.Friends:IsOnline(characterName, CommWhisper['SendComm'])
end


function CommWhisper:OnTimestampsReceived(sender, toGet, toPost)
	GT.Log:Info('CommWhisper_OnTimestampsReceived', sender, toGet, toPost)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommWhisper_OnTimestampsReceived_CommDisabled')
		return
	end

	local sendLines = {}
	for characterName, _ in pairs(toGet) do
		for _, professionName in pairs(toGet[characterName]) do
			table.insert(sendLines, GT.Text:Concat(characterName, professionName))
		end
	end

	local message = table.concat(sendLines, GT.Comm.DELIMITER)
	GT.Log:Info('CommWhisper_OnTimestampsReceived_SendGet', sender, message)
	Comm:SendCommMessage(GET, message, GT.Comm.WHISPER, sender, 'NORMAL')

	for characterName, _ in pairs(toPost) do
		if characterName ~= sender then
			for _, professionName in pairs(toPost[characterName]) do
				Comm:SendPost(GT.Comm.WHISPER, characterName, professionName, sender)
			end
		end
	end
end

function CommWhisper:OnGetReceived(prefix, message, distribution, sender)
	GT.Log:Info('CommWhisper_OnGetReceived', sender, message)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommWhisper_OnGetReceived_CommDisabled')
		return
	end

	if not GT.CommValidator:IsGetValid(message) then
		GT.Log:Error('CommWhisper_OnGetReceived_InvalidGet', sender, message)
		return
	end

	local tokens = GT.Text:Tokenize(message, Comm.DELIMITER)
	while #tokens > 0 do
		local characterName, tokens = GT.Table:RemoveToken(tokens)
		local professionName, tokens = GT.Table:RemoveToken(tokens)

		if professionName ~= 'None' then
			GT.Comm:SendPost(GT.Comm.WHISPER, characterName, professionName, sender)
		else
			GT.Log:Info('Comm_OnGetReceived_Ignore', prefix, distribution, sender, characterName, professionName)
		end
	end
end