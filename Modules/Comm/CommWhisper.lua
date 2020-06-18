local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local CommWhisper = GT:NewModule('CommWhisper')
GT.CommWhisper = CommWhisper

LibStub('AceComm-3.0'):Embed(CommWhisper)

-- 30 Days
CommWhisper.INACTIVE_TIMEOUT = 30 * GT.DAY

CommWhisper.INCOMING = true
CommWhisper.OUTGOING = false

CommWhisper.HANDSHAKE = 'HANDSHAKE'
CommWhisper.REQUEST = 'REQUEST'
CommWhisper.CONFIRM = 'CONFIRM'
CommWhisper.REJECT = 'REJECT'
CommWhisper.IGNORE = 'IGNORE'

CommWhisper.REQUEST_FILTER_CONFIRM = nil
CommWhisper.REQUEST_FILTER_ALLOW_NONE = false
CommWhisper.REQUEST_FILTER_ALLOW_ALL = true

-- 7 Days
local COMM_TIMEOUT = 7 * 24 * 60 * 60
local PROCESS_COMM_INTERVAL = 60
local ROLL_CALL_INTERVAL = 60
local ADD_DELAY = 5
local IS_PLAYER_INITIATED = true
local NOT_PLAYER_INITIATED = false
local IS_AUTO = true
local NOT_AUTO = false
local REMOVE_ON_SEND = true
local NOT_REMOVE_ON_SEND = false

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

local pendingHandshakes = {}

function CommWhisper:OnEnable()
	GT.Log:Info('CommWhisper_OnEnable')

	table.insert(STARTUP_TASKS, CommWhisper['RollCall'])
	table.insert(STARTUP_TASKS, CommWhisper['SendDeletions'])
	table.insert(STARTUP_TASKS, CommWhisper['SendTimestamps'])
	table.insert(STARTUP_TASKS, CommWhisper['SendComms'])
	table.insert(STARTUP_TASKS, CommWhisper['SendVersion'])
	table.insert(STARTUP_TASKS, CommWhisper['RemoveInactive'])

	COMMAND_MAP = {
		GET = 'OnGetReceived',
		HANDSHAKE = 'OnHandshakeReceived',
		REQUEST = 'OnRequestReceived',
		CONFIRM = 'OnConfirmReceived',
		REJECT = 'OnRejectReceived',
		IGNORE = 'OnIgnoreReceived'
	}

	for command, functionName in pairs(COMMAND_MAP) do
		CommWhisper:RegisterComm(command, functionName)
	end
end

function CommWhisper:StartupTasks()
	GT:CreateActionQueue(GT.STARTUP_DELAY, STARTUP_TASKS)
end

function CommWhisper:AddonCheck()
	for _, characterName in pairs(pendingHandshakes) do
		GT.Log:Info('CommWhisper_AddonCheck', characterName)
		GT.Friends:IsOnline(characterName, CommWhisper['_AddonCheck'])
	end
end

function CommWhisper:_AddonCheck(info)
	GT.Log:Info('CommWhisper__AddonCheck', info.name, info.exists, info.connected)
	pendingHandshakes = Table:RemoveByValue(pendingHandshakes, info.name)
	if not info.connected then return end
	if GT.DBComm:GetHandshakeRecord(info.name) == nil then
		local message = string.gsub(GT.L['REQUEST_ADDON_NOT_INSTALLED'], '%{{character_name}}', info.name)
		GT.Log:PlayerWarn(message)
		GT.DBComm:DeleteComm(info.name)
	end
end

function CommWhisper:RemoveInactive()
	local characters = GT.DBCharacter:GetCharacters()
	local characterNames = {}
	for characterName, character in pairs(characters) do
		if not GT:IsCurrentCharacter(characterName)
			and not character.isGuildMember
			and not character.isBroadcasted
		then
			local lastUpdate = character.lastCommReceived

			local professions = character.professions
			for professionName, profession in pairs(professions) do
				if profession.lastUpdate > lastUpdate then
					lastUpdate = profession.lastUpdate
				end
			end

			if lastUpdate + CommWhisper.INACTIVE_TIMEOUT < time() then
				GT.Log:Info('CommWhisper_RemoveInactive_RemoveCharacter', characterName, lastUpdate, time())
				table.insert(characterNames, characterName)
				GT.DBCharacter:DeleteCharacter(characterName)
			end
		end
	end

	if #characterNames > 0 then
		local names = table.concat(characterNames, GT.L['PRINT_DELIMITER'])
		local days = tostring(math.floor(timeout / GT.DAY))

		local message = string.gsub(GT.L['REMOVE_WHISPER_INACTIVE'], '%{{character_names}}', names)
		message = string.gsub(message, '%{{timeout_days}}', days)
		GT.Log:PlayerInfo(message)
	end
end

function CommWhisper:SendVersion()
	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommWhisper_SendVersion_CommDisabled')
		return
	end

	local characters = GT.DBCharacter:GetCharacters()
	for characterName, _ in pairs(characters) do
		local character = characters[characterName]
		if not character.isGuildMember and not character.isBroadcasted then
			GT.Friends:IsOnline(characterName, CommWhisper['_SendVersion'])
		end
	end
end

function CommWhisper:_SendVersion(info)
	if not info.connected then return end
	GT.Log:Info('CommWhisper__SendVersion', info.name)
	GT.Comm:SendVersion(GT.Comm.WHISPER, info.name)
end

function CommWhisper:RollCall()
	GT.Log:Info('CommWhisper_RollCall')
	local characters = GT.DBCharacter:GetCharacters()
	for characterName, _ in pairs(characters) do
		local character = characters[characterName]
		if not character.isGuildMember and not character.isBroadcasted then
			GT.Log:Info('CommWhisper_RollCall', characterName)
			GT.Friends:IsOnline(characterName, CommWhisper['_RollCall'])
		end
	end
	local wait = GT:GetWait(ROLL_CALL_INTERVAL, GT.Comm.COMM_VARIANCE)
	GT:ScheduleTimer(CommWhisper['RollCall'], wait)
end

function CommWhisper:_RollCall(info)
	GT.Log:Info('CommWhisper__RollCall', info.name, info.connected)
	if info.exists then
		local character = GT.DBCharacter:GetCharacter(info.name)
		character.isOnline = info.connected
		if info.className ~= 'UNKNOWN' then
			character.class = info.className
		end

		if character.isOnline then
			GT.Friends:IsOnline(info.name, CommWhisper['_SendComm'])
		end
	end
end

function CommWhisper:SendDeletions()
	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommWhisper_SendDeletions_CommDisabled')
		return
	end
	
	local characters = GT.DBCharacter:GetCharacters()
	for characterName, character in pairs(characters) do
		if not character.isGuildMember and not character.isBroadcasted then
			GT.Friends:IsOnline(characterName, CommWhisper['_SendDeletions'])
		end
	end
end

function CommWhisper:_SendDeletions(info)
	if not info.connected then return end
	GT.Log:Info('CommWhisper__SendDeletions', info.name)
	GT.Comm:SendDeletions(GT.Comm.WHISPER, info.name)
end

function CommWhisper:CreateCharacter(info)
	if info.exists then
		GT.Log:Info('CommWhisper_CreateCharacter', info.name)
		local character = GT.DBCharacter:AddCharacter(info.name)
		character.isGuildMember = false
		character.isOnline = info.connected
		if info.className ~= 'UNKNOWN' then
			character.class = info.className
		end
		GT:ScheduleTimer(CommWhisper['SendTimestamps'], ADD_DELAY)
	else
		local message = string.gsub(GT.L['CHARACTER_NOT_FOUND'], '%{{character_name}}', info.name)
		GT.Log:PlayerError(message)
	end
end

function CommWhisper:OnHandshakeReceived(prefix, uuid, distribution, sender)
	GT.Log:Info('CommWhisper_OnHandshakeReceived', distribution, sender, uuid)

	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommWhisper_OnHandshakeReceived_CommDisabled')
		return
	end

	if not Text:IsUUIDValid(uuid) then
		GT.Log:Error('CommWhisper_OnHandshakeReceived_Invalid', sender, uuid)
		return
	end

	if GT:IsGuildMember(sender) then
		GT.Log:Error('CommWhisper_OnHandshakeReceived_FromGuildmate', sender, uuid)
		return
	end

	if GT.DBComm:GetHandshakeRecord(sender) == nil then
		CommWhisper:SendCommMessage(CommWhisper.HANDSHAKE, GT.DBComm:GetUUID(), GT.Comm.WHISPER, sender, 'ALERT')
	end
	GT.DBComm:RecordHandshake(uuid, sender)
end

function CommWhisper:SendRequest(characterName)
	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommWhisper_SendRequest_CommDisabled')
		return
	end

	GT.Log:Info('CommWhisper_SendRequest', characterName)

	characterName = Table:RemoveToken(characterName)

	-- Remove our ignore of them.
	GT.DBComm:RemoveIgnore(CommWhisper.OUTGOING, uuid, characterName)

	local valid = GT.CommValidator:IsOutgoingRequestValid(characterName, GT.L['REQUEST_CHARACTER_NIL'], GT.L['REQUEST_NOT_SELF'], GT.L['REQUEST_NOT_GUILD'])
	if not valid then
		return
	end

	local character = GT.DBCharacter:GetCharacter(characterName)
	if character ~= nil and not character.isBroadcasted then
		local message = string.gsub(GT.L['REQUEST_EXISTS'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)
		return
	end

	local comm = GT.DBComm:GetComm(characterName)
	if comm ~= nil then
		if comm.isIncoming then
			-- Incoming handshakes are not queued.

			if comm.command == CommWhisper.REQUEST then
				GT.Log:Info('CommWhisper_SendRequest_SendConfirm', characterName)
				CommWhisper:SendConfirm(characterName, false)
				return
			end

			-- Incoming confirms are not queued.
			-- Incoming rejects are not queued.
			-- Incoming ignores are not queued.
		else
			-- Outgoing handshakes are not queued.

			if comm.command == CommWhisper.REQUEST then
				-- We already haven an outgoing request to them.
				local message = string.gsub(GT.L['REQUEST_REPEAT'], '%{{character_name}}', characterName)
				GT.Log:PlayerError(message)
				return
			end

			if comm.command == CommWhisper.CONFIRM then
				-- We already have an outgoing confirm to them.
				local message = string.gsub(GT.L['CONFIRM_REPEAT'], '%{{character_name}}', characterName)
				GT.Log:PlayerError(message)
				return
			end

			-- Do nothing on outgoing rejects.
			-- Do nothing on outgoing ignores.
		end
	else
		-- Do nothing on nil comm.
	end

	GT.Log:Info('CommWhisper_SendRequest_Send', characterName)
	GT.DBComm:SetComm(CommWhisper.OUTGOING, CommWhisper.REQUEST, characterName, GT.DBComm:GetUUID(), IS_PLAYER_INITIATED)
	GT.Friends:IsOnline(characterName, CommWhisper['_SendComm'])
end

function CommWhisper:OnRequestReceived(prefix, uuid, distribution, sender)
	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommWhisper_OnRequestReceived_CommDisabled')
		return
	end

	GT.Log:Info('CommWhisper_OnRequestReceived', distribution, sender, uuid)

	-- Remove their ignore of us.
	GT.DBComm:RemoveIgnore(CommWhisper.INCOMING, uuid, sender)

	if not GT.CommValidator:IsIncomingRequestValid(distribution, sender, uuid) then
		return
	end

	local filterState = GT.DBComm:GetRequestFilterState()
	if filterState == CommWhisper.REQUEST_FILTER_ALLOW_NONE then
		GT.Log:Info('CommWhisper_OnRequestReceived_FilterAllowNone', sender, uuid)
		CommWhisper:SendReject({sender}, IS_AUTO)
		return
	end

	if filterState == CommWhisper.REQUEST_FILTER_ALLOW_ALL then
		GT.Log:Info('CommWhisper_OnRequestReceived_AllowAll', sender, uuid)
		CommWhisper:SendConfirm(sender, IS_AUTO)
		return
	end

	if GT.DBCharacter:CharacterExists(sender) then
		GT.Log:Info('CommWhisper_OnRequestReceived_Exists', sender, uuid)
		CommWhisper:SendConfirm(sender, IS_AUTO)
		return
	end

	local comm = GT.DBComm:GetComm(sender)
	if comm ~= nil then
		if comm.isIncoming then
			-- Incoming handshakes are not queued.

			if comm.command == CommWhisper.REQUEST then
				GT.Log:Warn('CommWhisper_OnRequestReceived_Repeat', sender, uuid)
				return
			end

			-- Incoming confirms are not queued.
			-- Incoming rejects are not queued.
			-- Incoming ignores are not queued.
		else
			-- Outgoing handshakes are not queued.

			if comm.command == CommWhisper.REQUEST then
				GT.Log:Info('CommWhisper_OnRequestReceived_OutgoingRequest', sender)
				CommWhisper:SendConfirm(sender, IS_AUTO)
				return
			end

			if comm.command == CommWhisper.CONFIRM then
				GT.Log:Info('CommWhisper_OnRequestReceived_OutgoingConfirm', sender)
				CommWhisper:SendComm(sender)
				return
			end

			if comm.command == CommWhisper.REJECT then
				GT.Log:Info('CommWhisper_OnRequestReceived_OutgoingReject', sender)
				CommWhisper:SendComm(sender)
				return
			end

			if comm.command == CommWhisper.IGNORE then
				GT.Log:Info('CommWhisper_OnRequestReceived_OutgoingIgnore', sender)
				CommWhisper:SendComm(sender)
				return
			end
		end
	else
		-- Do nothing on nil comm.
	end

	GT.DBComm:SetComm(CommWhisper.INCOMING, CommWhisper.REQUEST, sender, uuid)
	local message = string.gsub(GT.L['REQUEST_INCOMING'], '%{{character_name}}', sender)
	GT.Log:PlayerInfo(message)
end

function CommWhisper:SendConfirm(characterName, autoConfirm)
	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommWhisper_SendConfirm_CommDisabled')
		return
	end

	GT.Log:Info('CommWhisper_SendConfirm', characterName, autoConfirm)

	-- Remove our ignore of them.
	GT.DBComm:RemoveIgnore(CommWhisper.OUTGOING, uuid, characterName)

	local valid = GT.CommValidator:IsOutgoingRequestValid(characterName, GT.L['CONFIRM_CHARACTER_NIL'], GT.L['CONFIRM_NOT_SELF'], GT.L['CONFIRM_NOT_GUILD'])
	if not valid then
		return
	end

	if GT.DBCharacter:CharacterExists(characterName) and not autoConfirm then
		local message = string.gsub(GT.L['CONFIRM_EXISTS'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)
		return
	end

	local comm = GT.DBComm:GetComm(characterName)
	if comm ~= nil then
		if comm.isIncoming then
			-- Incoming handshakes are not queued.

			-- Do nothing on incoming requests.

			-- Incoming confirms are not queued.
			-- Incoming rejects are not queued.
			-- Incoming ignores are not queued.
		else
			-- Outgoing handshakes are not queued.

			if comm.command == CommWhisper.REQUEST and not autoConfirm then
				local message = string.gsub(GT.L['REQUEST_REPEAT'], '%{{character_name}}', characterName)
				GT.Log:PlayerError(message)
				return
			end

			if comm.command == CommWhisper.CONFIRM and not autoConfirm then
				local message = string.gsub(GT.L['CONFIRM_REPEAT'], '%{{character_name}}', characterName)
				GT.Log:PlayerError(message)
				return
			end

			-- Do nothing on outgoing rejects.
			-- Do nothing on outgoing ignores.
		end
	elseif comm == nil and not autoConfirm then
		local message = string.gsub(GT.L['CONFIRM_NIL'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)
		return
	end

	GT.Log:Info('CommWhisper_SendConfirm_Send', characterName)
	local comm = GT.DBComm:SetComm(CommWhisper.OUTGOING, CommWhisper.CONFIRM, characterName, GT.DBComm:GetUUID(), not autoConfirm, REMOVE_ON_SEND)
	GT.Friends:IsOnline(characterName, CommWhisper['_SendComm'])
	GT.Friends:IsOnline(characterName, CommWhisper['CreateCharacter'])
end

function CommWhisper:OnConfirmReceived(prefix, uuid, distribution, sender)
	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommWhisper_OnConfirmReceived_CommDisabled')
		return
	end

	GT.Log:Info('CommWhisper_OnConfirmReceived', distribution, sender, uuid)

	-- Remove their ignore of us.
	GT.DBComm:RemoveIgnore(CommWhisper.INCOMING, uuid, sender)

	if not GT.CommValidator:IsIncomingRequestValid(distribution, sender, uuid) then
		return
	end

	if GT.DBCharacter:CharacterExists(sender) then
		CommWhisper:SendConfirm(sender, IS_AUTO)
		return
	end

	local comm = GT.DBComm:GetComm(sender)
	if comm ~= nil then
		if comm.isIncoming then
			-- Incoming handshakes are not queued.

			if comm.command == CommWhisper.REQUEST then
				GT.Log:Warn('CommWhisper_OnConfirmReceived_NotConfirmed', sender, uuid)
				return
			end

			-- Incoming confirms are not queued.
			-- Incoming rejects are not queued.
			-- Incoming ignores are not queued.
		else
			-- Outgoing handshakes are not queued.

			-- Do nothing for outgoing requests.
			-- Do nothing for outgoing confirms.

			if comm.command == CommWhisper.REJECT then
				GT.Log:Info('CommWhisper_OnConfirmReceived_OutgoingReject', sender)
				CommWhisper:SendComm(sender)
				return
			end

			if comm.command == CommWhisper.IGNORE then
				GT.Log:Info('CommWhisper_OnConfirmReceived_OutgoingIgnore', sender)
				CommWhisper:SendComm(sender)
				return
			end
		end
	else
		GT.Log:Error('CommWhisper_OnConfirmReceived_NilComm', sender, uuid)
		return
	end

	GT.DBComm:DeleteComm(sender)

	local message = string.gsub(GT.L['CONFIRM_INCOMING'], '%{{character_name}}', sender)
	GT.Log:PlayerInfo(message)
	GT.Friends:IsOnline(sender, CommWhisper['CreateCharacter'])
end

function CommWhisper:SendReject(characterName, autoReject)
	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommWhisper_SendReject_CommDisabled')
		return
	end

	GT.Log:Info('CommWhisper_SendReject', characterName, autoReject)

	characterName = Table:RemoveToken(characterName)
	local uuid = GT.DBComm:GetHandshakeRecord(characterName)
	if GT.DBComm:IsIgnored(CommWhisper.OUTGOING, uuid, characterName) and not autoReject then
		-- We have ignored them.
		local message = string.gsub(GT.L['REJECT_ALREADY_IGNORED'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)
		return
	end

	local valid = GT.CommValidator:IsOutgoingRequestValid(characterName, GT.L['REJECT_CHARACTER_NIL'], GT.L['REJECT_NOT_SELF'], GT.L['REJECT_NOT_GUILD'])
	if not valid then
		return
	end

	local comm = GT.DBComm:GetComm(characterName)
	if comm ~= nil then
		if comm.isIncoming then
			-- Incoming handshakes are not queued.

			-- Do nothing on incoming requests.

			-- Incoming confirms are not queued.
			-- Incoming rejects are not queued.
			-- Incoming ignores are not queued.
		else
			-- Outgoing handshakes are not queued.

			-- Do nothing on outgoing requests.
			-- Do nothing on outgoing confirms.

			if comm.command == CommWhisper.REJECT then
				-- We have already queued a reject to them.
				GT.Log:Error('CommWhisper_SendReject_Repeat', characterName)
				if not autoReject then
					local message = string.gsub(GT.L['REJECT_REPEAT'], '%{{character_name}}', characterName)
					GT.Log:PlayerWarn(message)
				end
				return
			end

			if comm.command == CommWhisper.IGNORE or GT.DBComm:IsIgnored(comm.isIncoming, nil, characterName) then
				-- We have ignored them.
				local message = string.gsub(GT.L['REJECT_ALREADY_IGNORED'], '%{{character_name}}', characterName)
				GT.Log:PlayerError(message)
				return
			end
		end
	elseif comm == nil and not autoReject then
		GT.Log:Error('CommWhisper_SendReject_NilComm', characterName)
		local message = string.gsub(GT.L['REJECT_NIL'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)
		return
	end

	GT.Log:Info('CommWhisper_SendReject_Send', characterName)

	GT.DBComm:SetComm(CommWhisper.OUTGOING, CommWhisper.REJECT, characterName, GT.DBComm:GetUUID(), not autoReject, REMOVE_ON_SEND)
	GT.Friends:IsOnline(characterName, CommWhisper['_SendComm'])
end

function CommWhisper:OnRejectReceived(prefix, uuid, distribution, sender)
	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommWhisper_OnRejectReceived_CommDisabled')
		return
	end

	GT.Log:Info('CommWhisper_OnRejectReceived', distribution, sender, uuid)

	-- Remove their ignore of us.
	GT.DBComm:RemoveIgnore(CommWhisper.INCOMING, uuid, sender)

	if not GT.CommValidator:IsIncomingRequestValid(distribution, sender, uuid) then
		return
	end

	local comm = GT.DBComm:GetComm(sender)
	if comm ~= nil then
		if comm.isIncoming then
			-- Incoming handshakes are not queued.

			if comm.command == CommWhisper.REQUEST then
				GT.Log:Warn('CommWhisper_OnRejectReceived_IncomingRequest', sender, uuid)
				GT.DBComm:DeleteComm(sender)
				return
			end

			-- Incoming confirms are not queued.
			-- Incoming rejects are not queued.
			-- Incoming ignores are not queued.
		else
			-- Outgoing handshakes are not queued.

			if comm.command == CommWhisper.REQUEST then
				GT.DBComm:DeleteComm(sender)
				local message = string.gsub(GT.L['INCOMING_REJECT'], '%{{character_name}}', sender)
				GT.Log:PlayerWarn(message)
				return
			end

			if comm.command == CommWhisper.CONFIRM then
				GT.DBComm:DeleteComm(sender)
				local message = string.gsub(GT.L['INCOMING_REJECT'], '%{{character_name}}', sender)
				GT.Log:PlayerWarn(message)
				return
			end

			if comm.command == CommWhisper.REJECT then
				CommWhisper:SendComm(sender)
				return
			end

			if comm.command == CommWhisper.IGNORE then
				CommWhisper:SendComm(sender)
				return
			end
		end
	else
		GT.Log:Info('CommWhisper_OnRejectReceived_NilComm', sender, uuid)
		return
	end
end

function CommWhisper:SendIgnore(characterName)
	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommWhisper_SendIgnore_CommDisabled')
		return
	end

	GT.Log:Info('CommWhisper_SendIgnore', characterName)

	characterName = Table:RemoveToken(characterName)
	local uuid = GT.DBComm:GetHandshakeRecord(characterName)
	if GT.DBComm:IsIgnored(CommWhisper.OUTGOING, uuid, characterName) and not autoReject then
		-- We have ignored them.
		local message = string.gsub(GT.L['IGNORE_ALREADY_IGNORED'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)
		return
	end

	local valid = GT.CommValidator:IsOutgoingRequestValid(characterName, GT.L['IGNORE_CHARACTER_NIL'], GT.L['IGNORE_NOT_SELF'], GT.L['IGNORE_NOT_GUILD'])
	if not valid then
		return
	end

	local comm = GT.DBComm:GetComm(sender)
	if comm ~= nil then
		if comm.isIncoming then
			-- Incoming handshakes are not queued.

			-- Do nothing on incoming requests.

			-- Incoming confirms are not queued.
			-- Incoming rejects are not queued.
			-- Incoming ignores are not queued.
		else
			-- Outgoing handshakes are not queued.

			-- Do nothing on outgoing requests.
			-- Do nothing on outgoing confirms.
			-- Do nothing on outgoing rejects.

			if comm.command == CommWhisper.IGNORE or GT.DBComm:IsIgnored(comm.isIncoming, nil, characterName) then
				-- We have ignored them.
				local message = string.gsub(GT.L['IGNORE_ALREADY_IGNORED'], '%{{character_name}}', characterName)
				GT.Log:PlayerError(message)
				return
			end
		end
	else
		GT.Log:Info('CommWhisper_SendIgnore_NilComm', characterName)
	end

	local uuid = GT.DBComm:GetHandshakeRecord(characterName)
	GT.DBComm:AddIgnore(CommWhisper.OUTGOING, uuid, characterName)
	GT.DBComm:SetComm(CommWhisper.OUTGOING, CommWhisper.IGNORE, characterName, GT.DBComm:GetUUID(), IS_PLAYER_INITIATED, REMOVE_ON_SEND)
	GT.DBCharacter:DeleteCharacter(characterName)
	GT.Friends:IsOnline(characterName, CommWhisper['_SendComm'])
end

function CommWhisper:OnIgnoreReceived(prefix, uuid, distribution, sender)
	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommWhisper_OnIgnoreReceived_CommDisabled')
		return
	end

	GT.Log:Info('CommWhisper_OnIgnoreReceived', distribution, sender, uuid)

	if not GT.CommValidator:IsIncomingRequestValid(distribution, sender, uuid) then
		return
	end

	if GT.DBComm:IsIgnored(CommWhisper.INCOMING, uuid, sender) then
		GT.Log:Info('CommWhisper_OnIgnoreReceived_Duplicate', sender, uuid)
		return
	end

	local comm = GT.DBComm:GetComm(sender)
	if comm ~= nil then
		if comm.isIncoming then
			-- Incoming handshakes are not queued.

			-- Do nothing on incoming requests.

			-- Incoming confirms are not queued.
			-- Incoming rejects are not queued.
			-- Incoming ignores are not queued.
		else
			-- Outgoing handshakes are not queued.

			-- Do nothing on outgoing requests.
			-- Do nothing on outgoing confirms.
			-- Do nothing on outgoing rejects.
			-- Do nothing on outgoing ignores.
		end
	else
		GT.Log:Info('CommWhisper_OnIgnoreReceived_NilComm', sender)
	end

	GT.DBComm:DeleteComm(sender)

	GT.DBComm:AddIgnore(CommWhisper.INCOMING, uuid, sender)
	local message = string.gsub(GT.L['IGNORE_INCOMING'], '%{{character_name}}', sender)
	GT.Log:PlayerError(message)
end

function CommWhisper:SendComms()
	local comms = GT.DBComm:GetComms()
	for characterName, comm in pairs(comms) do
		if not comm.isIncoming then
			CommWhisper:SendComm(characterName)
		end
	end
	GT:ScheduleTimer(CommWhisper['SendComms'], PROCESS_COMM_INTERVAL)
end

function CommWhisper:SendComm(characterName)
	GT.Friends:IsOnline(characterName, CommWhisper['_SendComm'])
end

function CommWhisper:_SendComm(info)
	local characterName = info.name
	local isOnline = info.connected

	local comm = GT.DBComm:GetComm(characterName)
	if comm == nil then
		GT.Log:Error('CommWhisper__SendComm_NilComm', characterName)
		return
	end

	GT.Log:Info('CommWhisper__SendComm', characterName, comm.command, isOnline)
	if not info.exists then
		GT.Log:Error('CommWhisper__SendComm_NotExists', characterName)
		if comm.isPlayerInitiated then
			local message = string.gsub(GT.L['CHARACTER_NOT_FOUND'], '%{{character_name}}', characterName)
			GT.Log:PlayerError(message)
		end

		GT.DBComm:DeleteComm(characterName)
		return
	end

	if not isOnline then
		if comm.isPlayerInitiated and not comm.didPrintOffline then
			local stringKey = OFFLINE_MAP[comm.command]
			local message = string.gsub(GT.L[stringKey], '%{{character_name}}', characterName)
			GT.Log:PlayerInfo(message)
			comm.didPrintOffline = true
		end
		return
	end

	if not isOnline then return end

	local uuid = GT.DBComm:GetHandshakeRecord(characterName)
	if uuid == nil then
		CommWhisper:SendCommMessage(GT.CommWhisper.HANDSHAKE, GT.DBComm:GetUUID(), GT.Comm.WHISPER, characterName, 'ALERT')
		pendingHandshakes = Table:Insert(pendingHandshakes, nil, characterName)
		GT:ScheduleTimer(CommWhisper['AddonCheck'], ADD_DELAY)
	end

	GT.Log:Info('CommWhisper__SendComm_Send', comm.command, characterName, comm.message)
	CommWhisper:SendCommMessage(comm.command, comm.message, GT.Comm.WHISPER, characterName, 'ALERT')
	if comm.removeOnSend then
		GT.DBComm:DeleteComm(characterName)
	end

	if comm.isPlayerInitiated and not comm.didPrintOnline then
		local stringKey = ONLINE_MAP[comm.command]
		local message = string.gsub(GT.L[stringKey], '%{{character_name}}', characterName)
		GT.Log:PlayerInfo(message)
		comm.didPrintOnline = true
	end
end

function CommWhisper:SendTimestamps()
	local characters = GT.DBCharacter:GetCharacters()
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
	local message = GT.Comm:GetTimestampString(GT:GetCharacterName())
	GT.Log:Info('CommWhisper__SendTimestamps', info.name, Text:ToString(message))
	if message ~= nil then
		GT.Comm:SendCommMessage(GT.Comm.TIMESTAMP, message, GT.Comm.WHISPER, info.name, GT.Comm.NORMAL)
	end
end

function CommWhisper:OnTimestampsReceived(sender, toGet, toPost)
	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommWhisper_OnTimestampsReceived_CommDisabled')
		return
	end

	local character = GT.DBCharacter:GetCharacter(sender)
	if character == nil then
		GT.Log:Warn('CommWhisper_OnTimestampsReceived_NotExist', sender)
		return
	end

	if character.isBroadcasted then
		GT.Log:Warn('CommWhisper_OnTimestampsReceived_Broadcasted', sender)
		return
	end

	GT.Log:Info('CommWhisper_OnTimestampsReceived', sender, toGet, toPost)

	local currentCharacterName = GT:GetCharacterName()
	local sendLines = {}
	for characterName, _ in pairs(toGet) do
		if string.lower(currentCharacterName) == string.lower(characterName)
			or string.lower(sender) == string.lower(characterName)
		then
			for professionName, _ in pairs(toGet[characterName]) do
				table.insert(sendLines, Text:Concat(GT.Comm.DELIMITER, characterName, professionName))
			end
		end
	end

	if #sendLines > 0 then
		local message = table.concat(sendLines, GT.Comm.DELIMITER)
		GT.Log:Info('CommWhisper_OnTimestampsReceived_SendGet', sender, message)
		GT.Comm:SendCommMessage(GT.Comm.GET, message, GT.Comm.WHISPER, sender, 'NORMAL')
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
	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommWhisper_OnGetReceived_CommDisabled')
		return
	end

	if distribution ~= GT.Comm.WHISPER then
		GT.Log:Error('CommWhisper_OnGetReceived_InvalidDistribution', distribution, sender, message)
		return
	end

	if GT:IsGuildMember(sender) then
		GT.Log:Error('CommWhisper_OnGetReceived_FromGuildMember', distribution, sender, message)
		return
	end

	if not GT.CommValidator:IsGetValid(message) then
		GT.Log:Error('CommWhisper_OnGetReceived_InvalidGet', sender, message)
		return
	end

	local senderChar = GT.DBCharacter:GetCharacter(sender)

	if senderChar == nil and not GT.DBComm:GetIsBroadcasting() and not GT.DBComm:GetIsForwarding() then
		GT.Log:Info('CommWhisper_OnGetReceived_NotBroadcasting_NotForwarding', sender, message)
		return
	end
	GT.Log:Info('CommWhisper_OnGetReceived', sender, message)

	local tokens = Text:Tokenize(message, GT.Comm.DELIMITER)
	while #tokens > 0 do
		local characterName, tokens = Table:RemoveToken(tokens)
		local professionName, tokens = Table:RemoveToken(tokens)
		local character = GT.DBCharacter:GetCharacter(characterName)

		if character ~= nil then
			local shouldSend = false

			if GT:IsCurrentCharacter(characterName) and GT.DBComm:GetIsBroadcasting() then
				GT.Log:Info('CommWhisper_OnGetReceived_IsBroadcasting', sender, characterName, professionName)
				shouldSend = true
			end

			if not GT:IsCurrentCharacter(characterName)
				and character.isBroadcasted
				and GT.DBComm:GetIsForwarding()
			then
				GT.Log:Info('CommWhisper_OnGetReceived_IsForwarding', sender, characterName, professionName)
				shouldSend = true
			end

			if GT:IsCurrentCharacter(characterName)
				and senderChar ~= nil
				and not senderChar.isGuildMember
				and not senderChar.isBroadcasted
			then
				GT.Log:Info('CommWhisper_OnGetReceived_FromAdded', sender, characterName, professionName)
				shouldSend = true
			end

			if shouldSend then
				if professionName ~= 'None' then
					GT.Comm:SendPost(GT.Comm.WHISPER, characterName, professionName, sender)
				else
					GT.Log:Info('Comm_OnGetReceived_Ignore', prefix, distribution, sender, characterName, professionName)
				end
			end
		end
	end
end

function CommWhisper:OnPostReceived(sender, message)
	GT.Log:Info('CommWhisper_OnPostReceived', sender, message)

	local tokens = Text:Tokenize(message, GT.Comm.DELIMITER)
	local characterName, tokens = Table:RemoveToken(tokens)
	local professionName, tokens = Table:RemoveToken(tokens)
	local lastUpdate, tokens = Table:RemoveToken(tokens)
	
	local senderCharacter = GT.DBCharacter:GetCharacter(sender)

	if senderCharacter ~= nil
		and not senderCharacter.isGuildMember
		and not senderCharacter.isBroadcasted
		and string.lower(sender) == string.lower(characterName)
	then
		GT.Log:Info('CommWhisper_OnPostReceived_FromAdded', sender, professionName, lastUpdate)
		GT.Comm:UpdateProfession(message)
		return
	end

	if GT.DBComm:GetIsReceivingBroadcasts() and string.lower(sender) == string.lower(characterName) then
		local character = GT.DBCharacter:GetCharacter(characterName)
		if character == nil then
			character = GT.DBCharacter:AddCharacter(characterName)
			character.isBroadcasted = true
			character.isGuildMember = false
		end

		GT.Log:Info('CommWhisper_OnPostReceived_ReceiveBroadcast', sender, professionName, lastUpdate)
		GT.Comm:UpdateProfession(message)
		return
	end

	if GT.DBComm:GetIsReceivingForwards() and string.lower(sender) ~= string.lower(characterName) then
		local character = GT.DBCharacter:GetCharacter(characterName)
		if character == nil then
			character = GT.DBCharacter:AddCharacter(characterName)
			character.isBroadcasted = true
			character.isGuildMember = false
		end

		GT.Log:Info('CommWhisper_OnPostReceived_ReceiveForward', sender, characterName, professionName, lastUpdate)
		GT.Comm:UpdateProfession(message)
		return
	end
end