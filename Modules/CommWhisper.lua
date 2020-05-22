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
local MAX_REQUESTS = 50

local COMMAND_MAP = {}

local COMM_QUEUES = {
	requests = REQUEST,
	confirms = CONFIRM,
	rejections = REJECT,
	ignores = IGNORE
}

local COMM_QUEUE_STRING_MAP = {
	incomingRequests = 'COMM_QUEUE_INCOMING_REQUEST',
	outgoingRequests = 'COMM_QUEUE_OUTGOING_REQUEST',
	incomingConfirms = 'COMM_QUEUE_INCOMING_CONFIRM',
	outgoingConfirms = 'COMM_QUEUE_OUTGOING_CONFIRM',
	incomingRejections = 'COMM_QUEUE_INCOMING_REJECT',
	outgoingRejections = 'COMM_QUEUE_OUTGOING_REJECT',
	incomingIgnored = 'COMM_QUEUE_INCOMING_IGNORE',
	outgoingIgnored = 'COMM_QUEUE_OUTGOING_IGNORE'
}

local COMM_QUEUE_TIMEOUT_MAP = {
	incomingRequests = 'COMM_QUEUE_INCOMING_REQUEST_TIMEOUT',
	outgoingRequests = 'COMM_QUEUE_OUTGOING_REQUEST_TIMEOUT',
	incomingConfirms = 'COMM_QUEUE_INCOMING_CONFIRM_TIMEOUT',
	outgoingConfirms = 'COMM_QUEUE_OUTGOING_CONFIRM_TIMEOUT',
	incomingRejections = 'COMM_QUEUE_INCOMING_REJECT_TIMEOUT',
	outgoingRejections = 'COMM_QUEUE_OUTGOING_REJECT_TIMEOUT',
	incomingIgnored = 'COMM_QUEUE_INCOMING_IGNORE_TIMEOUT',
	outgoingIgnored = 'COMM_QUEUE_OUTGOING_IGNORE_TIMEOUT'
}

local COMM_QUEUE_OFFLINE_MAP = {
	incomingRequests = 'COMM_QUEUE_INCOMING_REQUEST_OFFLINE',
	outgoingRequests = 'COMM_QUEUE_OUTGOING_REQUEST_OFFLINE',
	incomingConfirms = 'COMM_QUEUE_INCOMING_CONFIRM_OFFLINE',
	outgoingConfirms = 'COMM_QUEUE_OUTGOING_CONFIRM_OFFLINE',
	incomingRejections = 'COMM_QUEUE_INCOMING_REJECT_OFFLINE',
	outgoingRejections = 'COMM_QUEUE_OUTGOING_REJECT_OFFLINE',
	incomingIgnored = 'COMM_QUEUE_INCOMING_IGNORE_OFFLINE',
	outgoingIgnored = 'COMM_QUEUE_OUTGOING_IGNORE_OFFLINE'
}

local isPlayerInitiatedComm = false

function CommWhisper:OnEnable()
	GT.Log:Info('CommWhisper_OnEnable')

	for queueName, command in pairs(COMM_QUEUES) do
		GT.DB:InitCommQueue(queueName, command)
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

function CommWhisper:SendTimestamps()
	GT.Log:Info('CommWhisper_SendTimestamps')
	-- GT.Comm:SendTimestamps(GT.Comm.WHISPER, )
end

function CommWhisper:ProcessPendingComms()
	GT.Friends:CancelIsOnline()

	local commQueues = GT.DB:GetCommQueues()
	for queueName, _ in pairs(commQueues) do
		local commQueue = commQueues[queueName]
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

function CommWhisper:SendComm(characterName, isOnline)
	local queue, uuid = GT.DB:GetCommQueueForCharacter(characterName)
	if isPlayerInitiatedComm then
		GT.Log:Info('CommWhisper_SendComm', characterName, isOnline)
		if not isOnline then
			local stringKey = COMM_QUEUE_OFFLINE_MAP[queue.queueName]
			local message = string.gsub(GT.L[stringKey], '%{{character_name}}', characterName)
			GT.Log:PlayerInfo(message)
			return
		end
	end

	CommWhisper:SendCommMessage(queue.command, GT.DB:GetUUID(), GT.Comm.WHISPER, characterName, 'NORMAL')
	GT.DB:RemovePendingComm(queue.queueName, uuid, characterName)
	isPlayerInitiatedComm = false
end

function CommWhisper:SendRequest(characterName)
	GT.Log:Info('CommWhisper_InitSendRequest', characterName)
	characterName = GT.Table:RemoveToken(characterName)
	if characterName == nil then
		GT.Log:PlayerWarn(GT.L['REQUEST_CHARACTER_NIL'])
		return
	end

	local queue, uuid = GT.DB:GetCommQueueForCharacter(characterName)
	if queue ~= nil and queue.queueName == 'incomingRequests' then
		CommWhisper:EnqueueConfirm(queue, uuid, characterName)
		return
	end

	local queues = DB:GetCommQueues()
	local requestCount = 0
	for queueName, _ in pairs(queues) do
		local queue = queues[queueName]
		for uuid, _ in pairs(queue) do
			local uuidQueue = queue[uuid]
			for characterName, _ in pairs(uuidQueue) do
				requestCount = requestCount + 1
			end
		end
	end
	if requestCount >= MAX_REQUESTS then
		local message = string.gsub(GT.L['REQUEST_MAX_COUNT'], '%{{max_requests}}', MAX_REQUESTS)
		GT.Log:PlayerWarn(message)
		return
	end

	isPlayerInitiatedComm = true

	local added = GT.DB:AddPendingComm('outgoingRequests', GT.DB:GetUUID(), characterName)
	if not added then
		local message = string.gsub(GT.L['REQUEST_OUTGOING_REPEAT'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)
		return
	end

	GT.Friends:IsOnline(characterName, CommWhisper['SendComm'])
end

function CommWhisper:OnRequestReceived(prefix, message, distribution, sender)
	GT.Log:Info('CommWhisper_OnRequestReceived', distribution, sender, message)
	if not GT.CommValidator:IsRequestValid(message) then
		GT.Log:Error('CommWhisper_OnRequestReceived_Invalid', sender, message)
		return
	end
	local pendingComm = DB:GetPendingComm('incomingRequests', message, sender)
	if pendingComm ~= nil then
		GT.Log:Warn('CommWhisper_OnRequestReceived_Repeat', sender, message)
		return
	end

	GT.DB:AddRequestReceived('incomingRequests', message, sender)
	local message = string.gsub(GT.L['PLAYER_REQUEST_RECEIVED'], '%{{character_name}}', sender)
	GT.Log:PlayerInfo(message)
end

function CommWhisper:EnqueueConfirm(queue, uuid, characterName)
	GT.Log:Info('CommWhisper_SendConfirm', characterName)
	GT.DB:RemovePendingComm(queue.queueName, uuid, characterName)
	GT.DB:AddPendingComm('outgoingConfirms', uuid, characterName)
	local character = GT.DB:GetCharacter(characterName)
	character.isRando = true
	local message = string.gsub(GT.L['COMM_QUEUE_OUTGOING_CONFIRM'], '%{{character_name}}', characterName)
	GT.Log:PlayerInfo(message)
end

function CommWhisper:ChatMessageSystem(message)
	if (isRequesting or isConfirming) and string.find(message, GT.L['PLAYER_REQUEST_SYSTEM_NOT_FOUND']) then
		local characterName = nil
		if isRequesting then
			characterName = GT.DB:GetMostRecentPendingRequest()
			GT.DB:RemovePendingRequest(characterName)
		else
			characterName = GT.DB:GetMostRecentPendingOutgoingConfirm()
			GT.DB:RemovePendingOutgoingConfirm(characterName)
		end
		local message = string.gsub(GT.L['PLAYER_REQUEST_NOT_FOUND'], '%{{character_name}}', characterName)
		GT.Log:PlayerWarn(message)
		isRequesting = false
		GT.Friends:CancelIsOnline()
		CommWhisper:ProcessPendingRequests()
	end
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