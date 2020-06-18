local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local DBComm = GT:NewModule('DBComm')
GT.DBComm = DBComm

DBComm.valid = true

local DEFAULT_IS_COMM_ENABLED = true

function DBComm:OnEnable()
	DBComm.db = DBComm.db or LibStub('AceDB-3.0'):New('GTDB')

	----- COMM START -----
		----- GLOBAL COMM START -----

		if DBComm.db.global.comm == nil then
			DBComm.db.global.comm = {}
		end

		if DBComm.db.global.comm.uuid == nil then
			DBComm.db.global.comm.uuid = Text:UUID()
		end

		if DBComm.db.global.comm.handshakes == nil then
			DBComm.db.global.comm.handshakes = {}
		end

		if DBComm.db.global.comm.incomingIgnores == nil then
			DBComm.db.global.comm.incomingIgnores = {}
		end

		if DBComm.db.global.comm.outgoingIgnores == nil then
			DBComm.db.global.comm.outgoingIgnores = {}
		end

		if DBComm.db.global.comm.incomingUnassignedIgnores == nil then
			DBComm.db.global.comm.incomingUnassignedIgnores = {}
		end

		if DBComm.db.global.comm.outgoingUnassignedIgnores == nil then
			DBComm.db.global.comm.outgoingUnassignedIgnores = {}
		end

		----- GLOBAL COMM END -----
		----- CHARACTER COMM START -----

		if DBComm.db.char.comm == nil then
			DBComm.db.char.comm = {}
		end

		if DBComm.db.char.comm.comms == nil then
			DBComm.db.char.comm.comms = {}
		end

		----- CHARACTER COMM END -----

	--@debug@
	-- DBComm.db.global.comm.handshakes = {}

	-- DBComm.db.char.comm.comms = {}

	-- DBComm.db.global.comm.incomingIgnores = {}
	-- DBComm.db.global.comm.outgoingIgnores = {}

	-- DBComm.db.global.comm.incomingUnassignedIgnores = {}
	-- DBComm.db.global.comm.outgoingUnassignedIgnores = {}
	--@end-debug@

	----- COMM END -----
	----- BROADCASTING START -----

	if DBComm.db.char.comm.broadcastInterval == nil then
		DBComm.db.char.comm.broadcastInterval = GT.CommYell.DEFAULT_BROADCAST_INTERVAL
	end

	if DBComm.db.char.comm.isBroadcasting == nil then
		DBComm.db.char.comm.isBroadcasting = GT.CommYell.DEFAULT_IS_BROADCASTING
	end

	if DBComm.db.char.comm.isReceivingBroadcasts == nil then
		DBComm.db.char.comm.isReceivingBroadcasts = GT.CommYell.DEFAULT_IS_RECEIVING_BROADCASTS
	end

	if DBComm.db.char.comm.isForwarding == nil then
		DBComm.db.char.isForwarding = GT.CommYell.DEFAULT_IS_FORWARDING
	end

	if DBComm.db.char.comm.isReceivingForwards == nil then
		DBComm.db.char.comm.isReceivingForwards = GT.CommYell.DEFAULT_IS_RECEIVING_FORWARDS
	end

	--@debug@
	-- DBComm.db.char.comm.broadcastInterval = GT.CommYell.DEFAULT_BROADCAST_INTERVAL
	-- DBComm.db.char.comm.isBroadcasting = GT.CommYell.DEFAULT_IS_BROADCASTING
	-- DBComm.db.char.comm.isReceivingBroadcasts = GT.CommYell.DEFAULT_IS_RECEIVING_BROADCASTS
	-- DBComm.db.char.comm.isForwarding = GT.CommYell.DEFAULT_IS_FORWARDING
	-- DBComm.db.char.comm.isReceivingForwards = GT.CommYell.DEFAULT_IS_RECEIVING_FORWARDS
	--@end-debug@
	----- BROADCASTING END -----

	----- DEBUG START -----

	if DBComm.db.char.comm.isEnabled == nil then
		DBComm.db.char.comm.isEnabled = DEFAULT_IS_COMM_ENABLED
	end

	----- DEBUG END -----

	DBComm.valid = DBComm.Validate()
end

function DBComm:Reset()
	GT.Log:Info('DBComm_Reset')
	local isEnabled = DBComm.db.char.comm.isEnabled
	DBComm.db.char.comm = {}
	DBComm.db.char.comm.comms = {}

	DBComm.db.char.comm.isEnabled = isEnabled

	DBComm.db.global.comm.handshakes = {}
	DBComm.db.global.comm.outgoingIgnores = {}
	DBComm.db.global.comm.outgoingUnassignedIgnores = {}
end

----- DEBUG START -----

function DBComm:GetIsEnabled()
	return DBComm.db.char.comm.isEnabled
end

function DBComm:SetIsEnabled(isEnabled)
	DBComm.db.char.comm.isEnabled = isEnabled
end

----- DEBUG END -----
----- HANDSHAKE START -----

function DBComm:GetUUID()
	return DBComm.db.global.comm.uuid
end

function DBComm:GetHandshakeRecord(characterName)
	if characterName == nil then return nil end
	characterName = string.lower(characterName)

	local handshakes = DBComm.db.global.comm.handshakes
	for uuid, characters in pairs(handshakes) do
		for _, tempCharacterName in pairs(characters) do
			if tempCharacterName == characterName then
				return uuid
			end
		end
	end
	return nil
end

function DBComm:RecordHandshake(uuid, characterName)
	characterName = string.lower(characterName)

	local handshakes = DBComm.db.global.comm.handshakes
	handshakes = Table:InsertField(handshakes, uuid)
	local handshakeUUID = handshakes[uuid]
	handshakeUUID = Table:Insert(handshakeUUID, nil, characterName)
end

----- HANDSHAKE END -----
----- COMMQUEUE START -----

function DBComm:CommExists(characterName)
	if characterName == nil then return false end
	characterName = string.lower(characterName)
	if DBComm.db.char.comm.comms[characterName] == nil then return false end
	return true
end

function DBComm:GetComms()
	return DBComm.db.char.comm.comms
end

function DBComm:GetComm(characterName)
	if not DBComm:CommExists(characterName) then return nil end
	characterName = string.lower(characterName)
	return DBComm.db.char.comm.comms[characterName]
end

function DBComm:SetComm(isIncoming, command, characterName, message, isPlayerInitiated, removeOnSend)
	if command == nil then return nil end
	if characterName == nil then return nil end
	if message == nil then return nil end

	if isPlayerInitiated == nil then
		isPlayerInitiated = false
	end

	if removeOnSend == nil then
		removeOnSend = false
	end

	comm = {}
	comm.isIncoming = isIncoming
	comm.command = command
	comm.characterName = characterName
	comm.timestamp = time()
	comm.message = message
	comm.isPlayerInitiated = isPlayerInitiated
	comm.removeOnSend = removeOnSend
	comm.isSent = false
	comm.didPrintOffline = false
	comm.didPrintOnline = false

	local comms = DBComm.db.char.comm.comms
	comms[string.lower(characterName)] = comm

	return comm
end

function DBComm:DeleteComm(characterName)
	if characterName == nil then return false end
	characterName = string.lower(characterName)

	local comms = DBComm.db.char.comm.comms
	if comms[characterName] == nil then return false end
	comms[characterName] = nil
	return true
end

----- COMMQUEUE END -----
----- IGNORE START -----

function DBComm:IsIgnored(isIncoming, uuid, characterName)
	if characterName == nil then return false end
	if uuid == nil then
		uuid = DBComm:GetHandshakeRecord(characterName)
	end
	if uuid ~= nil then
		uuid = string.lower(uuid)
	end
	characterName = string.lower(characterName)

	local assignedList, unassignedList = DBComm:_GetIgnoreList(isIncoming)

	for tempUUID, characterNames in pairs(assignedList) do
		if tempUUID == uuid then
			GT.DBComm:_AssignIgnore(isIncoming, uuid, characterName)
			return true
		end
		for _, tempCharacterName in pairs(characterNames) do

		end
	end

	for _, tempCharacterName in pairs(unassignedList) do
		if tempCharacterName == characterName then
			if uuid ~= nil then
				GT.DBComm:_AssignIgnore(isIncoming, uuid, characterName)
			end
			return true
		end
	end
	return false
end

function DBComm:AddIgnore(isIncoming, uuid, characterName)
	if characterName == nil then return false end
	if uuid == nil then
		uuid = DBComm:GetHandshakeRecord(characterName)
	end
	if uuid ~= nil then
		uuid = string.lower(uuid)
	end
	characterName = string.lower(characterName)

	local assignedList, unassignedList = DBComm:_GetIgnoreList(isIncoming)
	if uuid ~= nil then
		uuid = string.lower(uuid)
		return GT.DBComm:_AssignIgnore(isIncoming, uuid, characterName)
	end
	if Table:Contains(unassignedList, characterName) then return false end

	unassignedList = Table:Insert(unassignedList, characterName)
	return true
end

function DBComm:RemoveIgnore(isIncoming, uuid, characterName)
	if characterName == nil then return false end
	if uuid == nil then
		uuid = DBComm:GetHandshakeRecord(characterName)
	end
	if uuid ~= nil then
		uuid = string.lower(uuid)
	end
	characterName = string.lower(characterName)

	local assignedList, unassignedList = DBComm:_GetIgnoreList(isIncoming)

	local removed = false

	for tempUUID, characterNames in pairs(assignedList) do
		if uuid ~= nil and uuid == tempUUID then
			assignedList[tempUUID] = nil
			break
		end
		for _, tempCharacterName in pairs(characterNames) do
			if tempCharacterName == characterName then
				assignedList[uuid] = nil
				removed = true
				break
			end
		end
	end

	if Table:Contains(unassignedList, characterName) then
		unassignedList = Table:RemoveByValue(unassignedList, characterName)
		removed = true
	end
	return removed
end

function DBComm:_GetIgnoreList(isIncoming)
	if isIncoming then
		return DBComm.db.global.comm.incomingIgnores, DBComm.db.global.comm.incomingUnassignedIgnores
	end
	return DBComm.db.global.comm.outgoingIgnores, DBComm.db.global.comm.outgoingUnassignedIgnores
end

function DBComm:_AssignIgnore(isIncoming, uuid, characterName)
	uuid = string.lower(uuid)
	characterName = string.lower(characterName)

	local assignedList, unassignedList = DBComm:_GetIgnoreList(isIncoming)
	assignedList = Table:InsertField(assignedList, uuid)
	local account = assignedList[uuid]
	if Table:Contains(account, characterName) then return false end

	account = Table:Insert(account, nil, characterName)
	unassignedList = Table:RemoveByValue(unassignedList, characterName)
	return true
end

----- IGNORE END -----
----- BROADCASTING START -----

function DBComm:GetBroadcastInterval()
	return DBComm.db.char.comm.broadcastInterval
end

function DBComm:SetBroadcastInterval(interval)
	DBComm.db.char.comm.broadcastInterval = interval
end

function DBComm:GetIsBroadcasting()
	return DBComm.db.char.comm.isBroadcasting
end

function DBComm:SetIsBroadcasting(isBroadcasting)
	DBComm.db.char.comm.isBroadcasting = isBroadcasting
end

function DBComm:GetIsReceivingBroadcasts()
	return DBComm.db.char.comm.isReceivingBroadcasts
end

function DBComm:SetIsReceivingBroadcasts(isReceiving)
	DBComm.db.char.comm.isReceivingBroadcasts = isReceiving
end

function DBComm:GetIsForwarding()
	return DBComm.db.char.comm.isForwarding
end

function DBComm:SetIsForwarding(isForwarding)
	DBComm.db.char.comm.isForwarding = isForwarding
end

function DBComm:GetIsReceivingForwards()
	return DBComm.db.char.comm.isReceivingForwards
end

function DBComm:SetIsReceivingForwards(isAccepting)
	DBComm.db.char.comm.isReceivingForwards = isAccepting
end

----- BROADCASTING END -----
----- ADVERTISING START -----

function DBComm:GetAdvertisingInterval()
	if DBComm.db.char.comm.advertisingInterval == nil then
		DBComm.db.char.comm.advertisingInterval = GT.Advertise.DEFAULT_INTERVAL
	end
	return DBComm.db.char.comm.advertisingInterval
end

function DBComm:SetAdvertisingInterval(interval)
	DBComm.db.char.comm.advertisingInterval = interval
end

function DBComm:GetIsAdvertising()
	return DBComm.db.char.comm.isAdvertising
end

function DBComm:SetIsAdvertising(isAdvertising)
	DBComm.db.char.comm.isAdvertising = isAdvertising
end

----- ADVERTISING END -----
----- WHISPER START -----

function DBComm:GetRequestFilterState()
	if DBComm.db.char.comm.requestFilterState == nil then
		return nil
	end
	return DBComm.db.char.comm.requestFilterState
end

function DBComm:SetRequestFilterState(filterState)
	DBComm.db.char.comm.requestFilterState = filterState
end

----- WHISPER END -----
----- VALIDATION START -----

function DBComm:Validate()
	DBComm:ValidateStructure()
	return DBComm:ValidateData()
end

function DBComm:ValidateStructure()
end

function DBComm:ValidateData()
	local handshakesValid = DBComm:_ValidateHandshakeData()
	local commsValid = DBComm:_ValidateCommData()
	local ignoresValid = DBComm:_ValidateIgnoreData()
	return handshakesValid and commsValid and ignoresValid
end

function DBComm:_ValidateHandshakeData()
	local valid = true

	local handshakes = DBComm.db.global.comm.handshakes
	for uuid, characterNames in pairs(handshakes) do
		if not Text:IsUUIDValid(uuid) then
			GT.Log:Error('DBComm__ValidateHandshakeData_InvalidUUID', uuid)
			valid = false
		end

		for _, characterName in pairs(characterNames) do
			if Text:IsNumber(characterName) or Text:IsLink(characterName) then
				GT.Log:Error('DBComm__ValidateHandshakeData_InvalidCharacterName', characterName)
				valid = false
			end
		end
	end
	return valid
end

function DBComm:_ValidateCommData()
	local valid = true
	
	for characterName, comm in pairs(DBComm.db.char.comm.comms) do
		if Text:IsNumber(characterName) or Text:IsLink(characterName) then
			GT.Log:Error('DBComm__ValidateCommQueues_InvalidCharacterName', characterName)
			valid = false
		end
		if comm.characterName == nil then
			comm.characterName = characterName
		end

		if comm.timestamp == nil then
			comm.timestamp = time()
		end

		if type(comm.isIncoming) ~= 'boolean' then
			GT.Log:Error('DBComm__ValidateCommQueues_InvalidComm_IsIncoming', comm.isIncoming)
			valid = false
		end

		if Text:IsNumber(comm.command) or Text:IsLink(comm.command) then
			GT.Log:Error('DBComm__ValidateCommQueues_InvalidComm_Command', comm.command)
			valid = false
		end

		if Text:IsNumber(comm.characterName) or Text:IsLink(comm.characterName) then
			GT.Log:Error('DBComm__ValidateCommQueues_InvalidComm_CharacterName', comm.characterName)
			valid = false
		end

		if not Text:IsNumber(comm.timestamp) then
			GT.Log:Error('DBComm__ValidateCommQueues_InvalidComm_Timestamp', comm.timestamp)
			valid = false
		end
	end
	return valid
end

function DBComm:_ValidateIgnoreData()
	local valid = true

	local assignedList = DBComm.db.global.comm.outgoingIgnores
	for uuid, characterNames in pairs(assignedList) do
		if not Text:IsUUIDValid(uuid) then
			GT.Log:Error('DBComm__ValidateIgnoreData_InvalidUUID', uuid)
			valid = false
		end

		for _, characterName in pairs(characterNames) do
			if Text:IsNumber(characterNames) or Text:IsLink(characterName) then
				GT.Log:Error('DBComm__ValidateIgnoreData_InvalidUUID_CharacterName', uuid, characterName)
				valid = false
			end
		end
	end

	local unassignedList = DBComm.db.global.comm.outgoingUnassignedIgnores
	for _, characterName in pairs(unassignedList) do
		if Text:IsNumber(characterName) or Text:IsLink(characterName) then
			GT.Log:Error('DBComm__ValidateIgnoreData_InvalidCharacterName', characterName)
			valid = false
		end
	end
	return valid
end

----- VALIDATION END -----