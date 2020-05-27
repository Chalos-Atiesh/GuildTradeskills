local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local CommWhisper = GT:NewModule('CommWhisper')
GT.CommWhisper = CommWhisper

LibStub('AceComm-3.0'):Embed(CommWhisper)

CommWhisper.INCOMING = true
CommWhisper.OUTGOING = false

CommWhisper.GET = 'GET'
CommWhisper.HANDSHAKE = 'HANDSHAKE'
CommWhisper.REQUEST = 'REQUEST'
CommWhisper.CONFIRM = 'CONFIRM'
CommWhisper.REJECT = 'REJECT'
CommWhisper.IGNORE = 'IGNORE'

CommWhisper.REQUEST_FILTER_CONFIRM = nil
CommWhisper.REQUEST_FILTER_ALLOW_NONE = false
CommWhisper.REQUEST_FILTER_ALLOW_ALL = true

local COMM_TIMEOUT = 7 * 24 * 60 * 60
local PROCESS_COMM_INTERVAL = 60
local ROLL_CALL_INTERVAL = 30
local ADD_DELAY = 5

local COMMAND_MAP = {}
local STARTUP_TASKS = {}

local INCOMING_TIMEOUT_MAP = {
	REQUEST = 'INCOMING_REQUEST_TIMEOUT'
}

local OUTGOING_TIMEOUT_MAP = {
	REQUEST = 'OUTGOING_REQUEST_TIMEOUT',
	CONFIRM = 'OUTGOING_CONFIRM_TIMEOUT',
	REJECT = 'OUTGOING_REJECT_TIMEOUT',
	IGNORE = 'OUTGOING_IGNORE_TIMEOUT'
}

local ONLINE_MAP = {
	REQUEST = 'OUTGOING_REQUEST_ONLINE',
	CONFIRM = 'OUTGOING_CONFIRM_ONLINE',
	REJECT = 'OUTGOING_REJECT_ONLINE',
	IGNORE = 'OUTGOING_IGNORE_ONLINE'
}

local OFFLINE_MAP = {
	REQUEST = 'OUTGOING_REQUEST_OFFLINE',
	CONFIRM = 'OUTGOING_CONFIRM_OFFLINE',
	REJECT = 'OUTGOING_REJECT_OFFLINE',
	IGNORE = 'OUTGOING_IGNORE_OFFLINE'
}

local playerInitComm = nil

function CommWhisper:OnEnable()
	GT.Log:Info('CommWhisper_OnEnable')

	table.insert(STARTUP_TASKS, CommWhisper['RollCall'])
	table.insert(STARTUP_TASKS, CommWhisper['SendTimestamps'])
	table.insert(STARTUP_TASKS, CommWhisper['ProcessPendingCommQueues'])

	COMMAND_MAP = {
		GET = 'OnGetReceived',
		HANDSHAKE = 'OnHandshakeReceived',
		REQUEST = 'OnRequestReceived',
		CONFIRM = 'OnConfirmReceived',
		REJECT = 'OnRejectReceived',
		IGNORE = 'OnIgnoreReceived'
	}

	GT.Friends:Enable()

	for command, functionName in pairs(COMMAND_MAP) do
		CommWhisper:RegisterComm(command, functionName)
	end
end

function CommWhisper:StartupTasks()
	GT:CreateActionQueue(GT.STARTUP_DELAY, STARTUP_TASKS)
end

function CommWhisper:RollCall()
	local characters = GT.DB:GetCharacters()
	for characterName, _ in pairs(characters) do
		local character = characters[characterName]
		if not character.isGuildMember and not character.isBroadcasted then
			-- GT.Log:Info('CommWhisper_RollCall', characterName)
			GT.Friends:IsOnline(characterName, CommWhisper['_RollCall'])
		end
	end
	local wait = GT:GetWait(ROLL_CALL_INTERVAL, GT.Comm.COMM_VARIANCE)
	GT:ScheduleTimer(CommWhisper['RollCall'], wait)
end

function CommWhisper:_RollCall(info)
	-- GT.Log:Info('CommWhisper__RollCall', info.name, info.connected)
	if info.exists then
		local character = GT.DB:GetCharacter(info.name)
		character.isOnline = info.connected
		if info.className ~= 'UNKNOWN' then
			character.class = info.className
		end
	end
end

function CommWhisper:CreateCharacter(info)
	if info.exists then
		GT.Log:Info('CommWhisper_CreateCharacter', info.name)
		local character = GT.DB:GetCharacter(info.name)
		character.isGuildMember = false
		if info.className ~= 'UNKNOWN' then
			character.class = info.className
		end
	end
end

function CommWhisper:OnHandshakeReceived(prefix, uuid, distribution, sender)
	GT.Log:Info('CommWhisper_OnHandshakeReceived', distribution, sender, uuid)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommWhisper_OnHandshakeReceived_CommDisabled')
		return
	end

	if not GT.Text:IsUUIDValid(uuid) then
		GT.Log:Error('CommWhisper_OnHandshakeReceived_Invalid', sender, uuid)
		return
	end

	if GT.DB:GetHandshakeRecord(sender) == nil then
		GT.DB:EnqueueComm(CommWhisper.OUTGOING, CommWhisper.HANDSHAKE, sender, GT.DB:GetUUID())
	end
	GT.DB:RecordHandshake(uuid, sender)
end

function CommWhisper:SendRequest(characterName)
	characterName = GT.Table:RemoveToken(characterName)
	if characterName == nil then
		GT.Log:PlayerWarn(GT.L['REQUEST_CHARACTER_NIL'])
		return
	end

	if GT:IsCurrentCharacter(characterName) then
		GT.Log:PlayerWarn(GT.L['REQUEST_NOT_SELF'])
		return
	end
	GT.Log:Info('CommWhisper_SendRequest', characterName)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommWhisper_SendRequest_CommDisabled')
		return
	end

	local uuid = GT.DB:GetHandshakeRecord(characterName)
	if uuid == nil then
		GT.Log:Info('CommWhisper_SendRequest_NilHandshake', characterName)
		GT.DB:EnqueueComm(CommWhisper.OUTGOING, CommWhisper.HANDSHAKE, characterName, GT.DB:GetUUID())
	end

	-- Remove our ignore of them.
	GT.DB:RemoveIgnore(CommWhisper.OUTGOING, uuid, characterName)

	if GT.DB:IsIgnored(CommWhisper.INCOMING, uuid, characterName) then
		-- We were ignored by them.
		local message = string.gsub(GT.L['IGNORE_INCOMING'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)

		GT.Log:Info(GT.DB.db.global.incomingIgnores)
		return
	end

	GT.DB:DequeueComm(CommWhisper.OUTGOING, CommWhisper.REJECT, characterName)
	GT.DB:DequeueComm(CommWhisper.OUTGOING, CommWhisper.IGNORE, characterName)

	local comm = GT.DB:GetCommForCharacter(CommWhisper.OUTGOING, characterName)
	if comm ~= nil and comm.command == CommWhisper.REQUEST then
		-- We already queued a request to them.
		local message = string.gsub(GT.L['REQUEST_REPEAT'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)
		return
	end

	if GT.DB:CharacterExists(characterName) then
		local message = string.gsub(GT.L['REQUEST_EXISTS'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)
		return
	end

	comm = GT.DB:GetCommForCharacter(CommWhisper.INCOMING, characterName)
	if comm ~= nil and comm.command == CommWhisper.REQUEST then
		CommWhisper:SendConfirm(characterName, true)
		return
	end

	GT.DB:EnqueueComm(CommWhisper.OUTGOING, CommWhisper.REQUEST, characterName, GT.DB:GetUUID())
	playerInitComm = GT.DB:GetCommWithCommand(CommWhisper.OUTGOING, CommWhisper.REQUEST, characterName)
	GT.Friends:CancelIsOnline(characterName)
	GT.Friends:IsOnline(characterName, CommWhisper['SendComm'])
end

function CommWhisper:OnRequestReceived(prefix, uuid, distribution, sender)
	if not GT.Text:IsUUIDValid(uuid) then
		GT.Log:Error('CommWhisper_OnRequestReceived_Invalid', sender, uuid)
		return
	end
	GT.Log:Info('CommWhisper_OnRequestReceived', distribution, sender, uuid)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommWhisper_OnRequestReceived_CommDisabled')
		return
	end

	GT.DB:RecordHandshake(uuid, sender)
	GT.DB:EnqueueComm(CommWhisper.OUTGOING, CommWhisper.HANDSHAKE, sender, GT.DB:GetUUID())

	-- Remove their ignore of us.
	GT.DB:RemoveIgnore(CommWhisper.INCOMING, uuid, sender)

	if GT.DB:IsIgnored(CommWhisper.OUTGOING, uuid, sender) then
		GT.Log:Info('CommWhisper_OnRequestReceived_Ignored', sender, uuid)
		return
	end

	local filterState = GT.DB:GetRequestFilterState()
	if filterState == CommWhisper.REQUEST_FILTER_ALLOW_NONE then
		GT.Log:Info('CommWhisper_OnRequestReceived_FilterAllowNone', sender, uuid)
		CommWhisper:SendReject({sender}, true)
		return
	end

	if filterState == CommWhisper.REQUEST_FILTER_ALLOW_ALL then
		GT.Log:Info('CommWhisper_OnRequestReceived_AllowAll', sender, uuid)
		GT.DB:EnqueueComm(CommWhisper.INCOMING, CommWhisper.REQUEST, sender, uuid)
		CommWhisper:SendConfirm(sender, false)
		return
	end

	local comm = GT.DB:GetCommForCharacter(CommWhisper.INCOMING, sender)
	if comm ~= nil and comm.command == CommWhisper.REQUEST then
		GT.Log:Warn('CommWhisper_OnRequestReceived_Repeat', sender, uuid)
		return
	end

	comm = GT.DB:GetCommForCharacter(CommWhisper.OUTGOING, sender)
	if comm ~= nil and comm.command == CommWhisper.REJECT then
		GT.Log:Warn('CommWhisper_OnRequestReceived_OutgoingReject', sender, uuid)
		return
	end
	if comm ~= nil and comm.command == CommWhisper.CONFIRM then
		GT.Log:Info('CommWhisper_OnRequestReceived_OutgoingConfirm', sender, uuid)
		return
	end

	GT.DB:EnqueueComm(CommWhisper.INCOMING, CommWhisper.REQUEST, sender, uuid)

	if comm ~= nil and comm.command == CommWhisper.REQUEST then
		GT.Log:Info('CommWhisper_OnRequestReceived_OutgoingRequest', sender, uuid)
		CommWhisper:SendConfirm(sender, false)
		return
	end

	if GT.DB:CharacterExists(sender) then
		GT.Log:Info('CommWhisper_OnRequestReceived_CharacterExists', sender, uuid)
		CommWhisper:SendConfirm(sender, false)
		return
	end
	local message = string.gsub(GT.L['REQUEST_INCOMING'], '%{{character_name}}', sender)
	GT.Log:PlayerInfo(message)
end

function CommWhisper:SendConfirm(characterName, isPlayerInitiated)
	if characterName == nil then
		GT.Log:PlayerWarn(GT.L['CONFIRM_CHARACTER_NIL'])
		return
	end

	if GT:IsCurrentCharacter(characterName) then
		GT.Log:PlayerWarn(GT.L['CONFIRM_NOT_SELF'])
		return
	end
	GT.Log:Info('CommWhisper_SendConfirm', characterName)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommWhisper_SendConfirm_CommDisabled')
		return
	end

	-- Remove our ignore of them.
	GT.DB:RemoveIgnore(CommWhisper.OUTGOING, uuid, characterName)

	if GT.DB:IsIgnored(CommWhisper.INCOMING, uuid, characterName) then
		-- We were ignored by them.
		local message = string.gsub(GT.L['IGNORE_INCOMING'], '%{{character_name}}', character_name)
		GT.Log:PlayerError(message)
		return
	end

	GT.DB:DequeueComm(CommWhisper.OUTGOING, CommWhisper.REJECT, characterName)
	GT.DB:DequeueComm(CommWhisper.OUTGOING, CommWhisper.IGNORE, characterName)

	local comm = GT.DB:GetCommForCharacter(CommWhisper.OUTGOING, characterName)
	if comm ~= nil and comm.command == CommWhisper.REQUEST then
		-- We already queued a request to them.
		local mesage = string.gsub(GT.L['REQUEST_REPEAT'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)
		return
	end

	if comm ~= nil and comm.command == CommWhisper.CONFIRM then
		-- We already queued a confirm to them.
		local message = string.gsub(GT.L['CONFIRM_REPEAT'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)
		return
	end

	if GT.DB:CharacterExists(characterName) and isPlayerInitiated then
		local message = string.gsub(GT.L['CONFIRM_EXISTS'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)
		return
	end

	comm = GT.DB:GetCommForCharacter(CommWhisper.INCOMING, characterName)
	if comm ~= nil and comm.command == CommWhisper.REQUEST then
		GT.Log:Info('CommWhisper_SendConfirm_Send', characterName)
		GT.DB:DequeueComm(CommWhisper.INCOMING, CommWhisper.REQUEST, characterName)
		comm = GT.DB:EnqueueComm(CommWhisper.OUTGOING, CommWhisper.CONFIRM, characterName, GT.DB:GetUUID())
		CommWhisper:ProcessPendingComm(comm)
		if isPlayerInitiated then
			playerInitComm = GT.DB:GetCommWithCommand(CommWhisper.OUTGOING, CommWhisper.CONFIRM, characterName)
		end
		GT.Log:Info('CommWhisper_SendConfirm_CreateCharacter', characterName)
		GT.Friends:IsOnline(characterName, CommWhisper['CreateCharacter'])
		GT:ScheduleTimer(CommWhisper['SendTimestamps'], ADD_DELAY)
	end
end

function CommWhisper:OnConfirmReceived(prefix, uuid, distribution, sender)
	if not GT.Text:IsUUIDValid(uuid) then
		GT.Log:Error('CommWhisper_OnConfirmReceived_Invalid', sender, uuid)
		return
	end
	GT.Log:Info('CommWhisper_OnConfirmReceived', distribution, sender, uuid)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommWhisper_OnConfirmReceived_CommDisabled')
		return
	end

	GT.DB:RecordHandshake(uuid, sender)
	GT.DB:EnqueueComm(CommWhisper.OUTGOING, CommWhisper.HANDSHAKE, sender, GT.DB:GetUUID())

	-- Remove their ignore of us.
	GT.DB:RemoveIgnore(CommWhisper.INCOMING, uuid, sender)

	if GT.DB:IsIgnored(CommWhisper.OUTGOING, uuid, sender) then
		Gt.Log:Info('CommWhisper_OnConfirmReceived_Ignored', sender, uuid)
		return
	end

	local comm = GT.DB:GetCommForCharacter(CommWhisper.INCOMING, sender)
	if comm ~= nil and comm.command == CommWhisper.REQUEST then
		GT.Log:Warn('CommWhisper_OnConfirmReceived_NotConfirmed', sender, uuid)
		return
	end

	comm = GT.DB:GetCommForCharacter(CommWhisper.OUTGOING, sender)
	if comm ~= nil and comm.command == CommWhisper.REJECT then
		GT.Log:Warn('CommWhisper_OnConfirmReceived_OutgoingReject', sender, uuid)
		return
	end

	if comm ~= nil and comm.command == CommWhisper.REQUEST then
		GT.Log:Info('CommWhisper_OnConfirmReceived_OutgoingRequest', sender, uuid)
		GT.DB:DequeueComm(CommWhisper.OUTGOING, CommWhisper.REQUEST, sender)
		comm = GT.DB:EnqueueComm(CommWhisper.OUTGOING, CommWhisper.CONFIRM, sender, GT.DB:GetUUID())
		CommWhisper:ProcessPendingComm(comm)
	end

	if GT.DB:CharacterExists(sender) then
		GT.Log:Info('CommWhisper_OnConfirmReceived_Repeat', sender, uuid)
		return
	end

	local message = string.gsub(GT.L['CONFIRM_INCOMING'], '%{{character_name}}', sender)
	GT.Log:PlayerInfo(message)
	GT.Friends:IsOnline(sender, CommWhisper['CreateCharacter'])
	GT:ScheduleTimer(CommWhisper['SendTimestamps'], ADD_DELAY)
end

function CommWhisper:SendReject(characterName, autoReject)
	characterName = GT.Table:RemoveToken(characterName)
	if characterName == nil then
		GT.Log:PlayerWarn(GT.L['REJECT_CHARACTER_NIL'])
		return
	end

	if GT:IsCurrentCharacter(characterName) then
		GT.Log:PlayerWarn(GT.L['REJECT_NOT_SELF'])
		return
	end
	GT.Log:Info('CommWhisper_SendReject', characterName)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommWhisper_SendReject_CommDisabled')
		return
	end

	local uuid = GT.DB:GetHandshakeRecord(characterName)
	if uuid == nil then
		GT.DB:EnqueueComm(CommWhisper.OUTGOING, CommWhisper.HANDSHAKE, characterName, GT.DB:GetUUID())
	end

	if GT.DB:IsIgnored(CommWhisper.INCOMING, uuid, characterName) and not autoReject then
		-- We were ignored by them.
		local message = string.gsub(GT.L['IGNORE_INCOMING'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)
		return
	end

	if GT.DB:IsIgnored(CommWhisper.OUTGOING, uuid, characterName) and not autoReject then
		-- We have ignored them.
		local message = string.gsub(GT.L['REJECT_ALREADY_IGNORED'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)
		return
	end

	GT.DB:DequeueComm(CommWhisper.OUTGOING, CommWhisper.REQUEST, characterName)
	GT.DB:DequeueComm(CommWhisper.OUTGOING, CommWhisper.CONFIRM, characterName)

	local comm = GT.DB:GetCommForCharacter(CommWhisper.OUTGOING, characterName)
	if comm ~= nil and comm.command == CommWhisper.REJECT and not autoReject then
		-- We have already queued a reject to them.
		local message = string.gsub(GT.L['REJECT_REPEAT'], '%{{character_name}}', characterName)
		GT.Log:PlayerWarn(message)
		return
	end

	comm = GT.DB:GetCommForCharacter(CommWhisper.INCOMING, characterName)
	if (comm ~= nil and comm.command == CommWhisper.REQUEST) or autoReject then
		GT.DB:DequeueComm(CommWhisper.INCOMING, CommWhisper.REQUEST, characterName)
		GT.DB:EnqueueComm(CommWhisper.OUTGOING, CommWhisper.REJECT, characterName, GT.DB:GetUUID())
		if not autoReject then
			playerInitComm = GT.DB:GetCommWithCommand(CommWhisper.OUTGOING, CommWhisper.REJECT, characterName)
		end
		GT.Friends:CancelIsOnline(characterName)
		GT.Friends:IsOnline(characterName, CommWhisper['SendComm'])
		return
	end

	if comm == nil and not autoReject then
		local message = string.gsub(GT.L['REJECT_NIL'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)
		return
	end

	GT.Log:Error('CommWhisper_SendReject_UnexpectedCommState', comm)
end

function CommWhisper:OnRejectReceived(prefix, uuid, distribution, sender)
	if not GT.Text:IsUUIDValid(uuid) then
		GT.Log:Error('CommWhisper_OnRejectReceived_Invalid', sender, uuid)
		return
	end
	GT.Log:Info('CommWhisper_OnRejectReceived', distribution, sender, uuid)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommWhisper_OnRejectReceived_CommDisabled')
		return
	end

	GT.DB:RecordHandshake(uuid, sender)
	GT.DB:EnqueueComm(CommWhisper.OUTGOING, CommWhisper.HANDSHAKE, sender, GT.DB:GetUUID())

	-- Remove their ignore of us.
	GT.DB:RemoveIgnore(CommWhisper.INCOMING, uuid, sender)

	if GT.DB:IsIgnored(CommWhisper.OUTGOING, uuid, sender) then
		GT.Log:Info('CommWhisper_OnRequestReceived_Ignored', sender, uuid)
		return
	end

	local comm = GT.DB:GetCommForCharacter(CommWhisper.OUTGOING, sender)
	if comm ~= nil and comm.command == CommWhisper.CONFIRM then
		GT.Log:Info('CommWhisper_OnRejectReceived_OutgoingConfirm', sender, uuid)
		GT.DB:DequeueComm(CommWhisper.OUTGOING, CommWhisper.CONFIRM, sender)
	end

	if comm ~= nil and comm.command == CommWhisper.REQUEST then
		GT.Log:Info('CommWhisper_OnRejectReceived_OutgoingRequest', sender, uuid)
		GT.DB:DequeueComm(CommWhisper.OUTGOING, CommWhisper.REQUEST, sender)
	end

	if comm ~= nil then
		local message = string.gsub(GT.L['INCOMING_REJECT'], '%{{character_name}}', sender)
		GT.Log:PlayerWarn(message)
	end

	comm = GT.DB:GetCommForCharacter(CommWhisper.INCOMING, sender)
	if comm ~= nil and comm.command == CommWhisper.REQUEST then
		GT.Log:Info('CommWhisper_OnRejectReceived_IncomingRequest', sender, uuid)
		GT.DB:DequeueComm(CommWhisper.INCOMING, CommWhisper.REQUEST, sender)
	end
end

function CommWhisper:SendIgnore(characterName)
	characterName = GT.Table:RemoveToken(characterName)
	if characterName == nil then
		GT.Log:PlayerWarn(GT.L['IGNORE_CHARACTER_NIL'])
		return
	end

	if GT:IsCurrentCharacter(characterName) then
		GT.Log:PlayerWarn(GT.L['IGNORE_NOT_SELF'])
		return
	end
	GT.Log:Info('CommWhisper_SendIgnore', characterName)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommWhisper_SendIgnore_CommDisabled')
		return
	end

	local uuid = GT.DB:GetHandshakeRecord(characterName)
	if uuid == nil then
		GT.DB:EnqueueComm(CommWhisper.OUTGOING, CommWhisper.HANDSHAKE, characterName, GT.DB:GetUUID())
	end

	GT.DB:DequeueComm(CommWhisper.OUTGOING, CommWhisper.REJECT, characterName)
	GT.DB:DequeueComm(CommWhisper.OUTGOING, CommWhisper.CONFIRM, characterName)
	GT.DB:DequeueComm(CommWhisper.OUTGOING, CommWhisper.REQUEST, characterName)

	if GT.DB:IsIgnored(CommWhisper.OUTGOING, uuid, characterName) then
		local message = string.gsub(GT.L['IGNORE_REPEAT'], '%{{character_name}}', characterName)
		GT.Log:PlayerWarn(message)
		return
	end

	GT.DB:DequeueComm(CommWhisper.INCOMING, CommWhisper.REQUEST, characterName)

	GT.DB:AddIgnore(CommWhisper.OUTGOING, uuid, characterName)
	GT.DB:EnqueueComm(CommWhisper.OUTGOING, CommWhisper.IGNORE, characterName, GT.DB:GetUUID())
	playerInitComm = GT.DB:GetCommWithCommand(CommWhisper.OUTGOING, CommWhisper.IGNORE, characterName)
	GT.Friends:CancelIsOnline(characterName)
	GT.Friends:IsOnline(characterName, CommWhisper['SendComm'])
end

function CommWhisper:OnIgnoreReceived(prefix, uuid, distribution, sender)
	if not GT.Text:IsUUIDValid(uuid) then
		GT.Log:Error('CommWhisper_OnIgnoreReceived_Invalid', sender, uuid)
		return
	end
	GT.Log:Info('CommWhisper_OnIgnoreReceived', distribution, sender, uuid)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommWhisper_OnIgnoreReceived_CommDisabled')
		return
	end

	GT.DB:RecordHandshake(uuid, sender)
	GT.DB:EnqueueComm(CommWhisper.OUTGOING, CommWhisper.HANDSHAKE, sender, GT.DB:GetUUID())

	if GT.DB:IsIgnored(CommWhisper.INCOMING, uuid, sender) then
		GT.Log:Info('CommWhisper_OnIgnoreReceived_Duplicate', sender, uuid)
		return
	end

	GT.DB:DequeueComm(CommWhisper.INCOMING, CommWhisper.REQUEST, sender)

	GT.DB:DequeueComm(CommWhisper.OUTGOING, CommWhisper.REJECT, sender)
	GT.DB:DequeueComm(CommWhisper.OUTGOING, CommWhisper.CONFIRM, sender)
	GT.DB:DequeueComm(CommWhisper.OUTGOING, CommWhisper.REQUEST, sender)


	GT.DB:AddIgnore(CommWhisper.INCOMING, uuid, sender)
	local message = string.gsub(GT.L['IGNORE_INCOMING'], '%{{character_name}}', sender)
	GT.Log:PlayerError(message)
end

function CommWhisper:ProcessPendingCommQueues()
	GT.Friends:CancelIsOnline(nil)
	-- GT.Log:Info('CommWhisper_ProcessPendingCommQueues')

	local pendingHandshakes = {}

	local handshakes = GT.DB:GetCommsWithCommand(CommWhisper.OUTGOING, CommWhisper.HANDSHAKE)
	for _, handshake in pairs(handshakes) do
		CommWhisper:ProcessPendingComm(handshake)
		pendingHandshakes = GT.Table:Insert(pendingHandshakes, handshake.characterName)
	end

	for command, _ in pairs(COMMAND_MAP) do
		if command ~= CommWhisper.HANDSHAKE then
			local incomingQueue = GT.DB:GetCommsWithCommand(CommWhisper.INCOMING, command)
			CommWhisper:ProcessPendingCommQueue(incomingQueue)
			local outgoingQueue = GT.DB:GetCommsWithCommand(CommWhisper.OUTGOING, command)
			CommWhisper:ProcessPendingCommQueue(outgoingQueue)
		end
	end

	local wait = GT:GetWait(PROCESS_COMM_INTERVAL, GT.Comm.COMM_VARIANCE)
	GT:ScheduleTimer(CommWhisper['ProcessPendingCommQueues'], wait)
end

function CommWhisper:ProcessPendingCommQueue(queue)
	for _, comm in pairs(queue) do
		CommWhisper:ProcessPendingComm(comm)
	end
end

function CommWhisper:ProcessPendingComm(comm)
	GT.Log:Info('CommWhisper_ProcessPendingComm', comm.isIncoming, comm.command, comm.characterName, comm.timestamp, comm.message)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommWhisper_ProcessPendingComm_CommDisabled')
		return
	end

	if comm.timestamp + COMM_TIMEOUT < time() then
		local removed = GT.DB:DequeueComm(comm.isIncoming, comm.command, comm.characterName)
		if removed then
			local stringKey = nil
			if comm.isIncoming then
				stringKey = OUTGOING_TIMEOUT_MAP[comm.command]
			else
				stringKey = INCOMING_TIMEOUT_MAP[comm.command]
			end
			local message = string.gsub(GT.L[stringKey], '%{{character_name}}', comm.characterName)
			GT.Log:PlayerWarn(message)
		end
		return
	end
	GT.Friends:IsOnline(comm.characterName, CommWhisper['SendComm'])
end

function CommWhisper:SendComm(info)
	local characterName = info.name
	local isOnline = info.connected
	GT.Log:Info('CommWhisper_SendComm', characterName, isOnline)
	if playerInitComm ~= nil and not info.exists then
		GT.DB:DequeueComms(CommWhisper.INCOMING, characterName)
		GT.DB:DequeueComms(CommWhisper.OUTGOING, characterName)
		local message = string.gsub(GT.L['CHARACTER_NOT_FOUND'], '%{{character_name}}', playerInitComm.characterName)
		GT.Log:PlayerError(message)
		playerInitComm = nil
		return
	end

	local handshake = GT.DB:GetCommWithCommand(CommWhisper.OUTGOING, CommWhisper.HANDSHAKE, characterName)
	if handshake ~= nil and isOnline then
		GT.Log:Info('CommWhisper_SendComm_Handshake', characterName, handshake.message)
		GT.DB:DequeueComm(CommWhisper.OUTGOING, CommWhisper.HANDSHAKE, characterName)
		CommWhisper:SendCommMessage(CommWhisper.HANDSHAKE, handshake.message, GT.Comm.WHISPER, characterName, 'ALERT')
	end

	local comm = GT.DB:GetCommForCharacter(CommWhisper.OUTGOING, characterName)
	if comm == nil then
		GT.Log:Info('CommWhisper_SendComm_NilComm', characterName)
		return
	end

	if playerInitComm ~= nil and not isOnline then
		local stringKey = OFFLINE_MAP[comm.command]
		local message = string.gsub(GT.L[stringKey], '%{{character_name}}', characterName)
		GT.Log:PlayerInfo(message)
		playerInitComm = nil
		return
	end
	if not isOnline then return end

	GT.Log:Info('CommWhisper_SendComm_Send', comm.command, characterName, comm.message)
	GT.DB:DequeueComm(CommWhisper.OUTGOING, comm.command, characterName, comm.message)
	CommWhisper:SendCommMessage(comm.command, comm.message, GT.Comm.WHISPER, characterName, 'NORMAL')

	if playerInitComm ~= nil
		and comm.command ~= CommWhisper.GET
		and comm.command ~= CommWhisper.HANDSHAKE
	then
		local stringKey = ONLINE_MAP[comm.command]
		local message = string.gsub(GT.L[stringKey], '%{{character_name}}', characterName)
		GT.Log:PlayerInfo(message)
		playerInitComm = nil
	end
end

function CommWhisper:SendTimestamps()

	local characters = GT.DB:GetCharacters()
	for characterName, _ in pairs(characters) do
		local character = characters[characterName]
		if not character.isGuildMember and not character.isBroadcasted then
			GT.Log:Info('CommWhisper_SendTimestamps', characterName)
			GT.Friends:IsOnline(characterName, CommWhisper['_SendTimestamps'])
		end
	end
end

function CommWhisper:_SendTimestamps(info)
	if not info.connected then return end
	GT.Log:Info('CommWhisper__SendTimestamps', info.name)
	GT.Comm:SendTimestamps(GT.Comm.WHISPER, info.name)
end

function CommWhisper:OnTimestampsReceived(sender, toGet, toPost)
	GT.Log:Info('CommWhisper_OnTimestampsReceived', sender, toGet, toPost)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommWhisper_OnTimestampsReceived_CommDisabled')
		return
	end

	if not GT.DB:CharacterExists(sender) then
		GT.Log:Warn('CommWhisper_OnTimestampsReceived_NotExist', sender)
		return
	end

	local currentCharacterName = GT:GetCurrentCharacter()
	local sendLines = {}
	for characterName, _ in pairs(toGet) do
		if string.lower(currentCharacterName) == string.lower(characterName)
			or string.lower(sender) == string.lower(characterName)
		then
			for professionName, _ in pairs(toGet[characterName]) do
				table.insert(sendLines, GT.Text:Concat(GT.Comm.DELIMITER, characterName, professionName))
			end
		end
	end

	local message = nil
	if #sendLines > 0 then
		message = table.concat(sendLines, GT.Comm.DELIMITER)
		GT.Log:Info('CommWhisper_OnTimestampsReceived_SendGet', sender, message)
		GT.Comm:SendCommMessage(CommWhisper.GET, message, GT.Comm.WHISPER, sender, 'NORMAL')
	end

	for characterName, _ in pairs(toPost) do
		if string.lower(characterName) ~= string.lower(sender) and GT:IsCurrentCharacter(characterName) then
			for professionName, _ in pairs(toPost[characterName]) do
				GT.Comm:SendPost(GT.Comm.WHISPER, characterName, professionName, sender)
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

	if not GT.DB:CharacterExists(sender) then
		GT.Log:Warn('CommWhisper_OnGetReceived_NotExist', sender)
		return
	end

	local tokens = GT.Text:Tokenize(message, GT.Comm.DELIMITER)
	while #tokens > 0 do
		local characterName, tokens = GT.Table:RemoveToken(tokens)
		local professionName, tokens = GT.Table:RemoveToken(tokens)

		if GT:IsCurrentCharacter(characterName) then
			if professionName ~= 'None' then
				GT.Comm:SendPost(GT.Comm.WHISPER, characterName, professionName, sender)
			else
				GT.Log:Info('Comm_OnGetReceived_Ignore', prefix, distribution, sender, characterName, professionName)
			end
		end
	end
end