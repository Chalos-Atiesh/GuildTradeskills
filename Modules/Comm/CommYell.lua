local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local CommYell = GT:NewModule('CommYell')
GT.CommYell = CommYell

LibStub('AceComm-3.0'):Embed(CommYell)

CommYell.MIN_BROADCAST_INTERVAL = 60
CommYell.MAX_BROADCAST_INTERVAL = 300
CommYell.DEFAULT_BROADCAST_INTERVAL = 120

CommYell.DEFAULT_IS_BROADCASTING = false
CommYell.DEFAULT_IS_RECEIVING_BROADCASTS = false
CommYell.DEFAULT_IS_FORWARDING = false
CommYell.DEFAULT_IS_RECEIVING_FORWARDS = false

CommYell.INACTIVE_TIMEOUT = 7 * GT.DAY

local STARTUP_TASKS = {}

function CommYell:OnEnable()
	table.insert(STARTUP_TASKS, CommYell['SendVersion'])
	table.insert(STARTUP_TASKS, CommYell['Broadcast'])
	table.insert(STARTUP_TASKS, CommYell['RemoveInactive'])
end

function CommYell:Reset()
	GT.DBComm:SetBroadcastInterval(CommYell.DEFAULT_BROADCAST_INTERVAL)
	GT.DBComm:SetBroadcasting(CommYell.DEFAULT_IS_BROADCASTING)
	GT.DBComm:SetReceivingBroadcasts(CommYell.DEFAULT_IS_RECEIVING_BROADCASTS)
	GT.DBComm:SetForwarding(CommYell.DEFAULT_IS_FORWARDING)
	GT.DBComm:SetReceivingForwards(CommYell.DEFAULT_IF_RECEIVING_FORWARDS)
end

function CommYell:StartupTasks()
	GT:CreateActionQueue(GT.STARTUP_DELAY, STARTUP_TASKS)
end

function CommYell:RemoveInactive()
	GT.Comm:RemoveInactive(CommYell.INACTIVE_TIMEOUT, false, false, true, nil)
end

function CommYell:SendVersion()
	GT.Comm:SendVersion(GT.Comm.YELL, nil)
	local wait = GT:GetWait(GT.DBComm:GetBroadcastInterval(), GT.Comm.COMM_VARIANCE)
	GT:ScheduleTimer(CommYell['SendVersion'], wait)
end

function CommYell:Broadcast()
	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommYell_Broadcast_CommDisabled')
		return
	end

	local characters = GT.DBCharacter:GetCharacters()
	for characterName, _ in pairs(characters) do
		local character = characters[characterName]
		for professionName, _ in pairs(character.professions) do
			if CommYell:_ShouldSendPost(characterName) then
				CommYell:SendPost(characterName, professionName)
			end
		end
	end

	local wait = GT:GetWait(GT.DBComm:GetBroadcastInterval(), GT.Comm.COMM_VARIANCE)
	GT:ScheduleTimer(CommYell['Broadcast'], wait)
end

function CommYell:ToggleBroadcast(tokens)
	GT.Log:Info('CommYell_ToggleBroadcast', tokens)
	local broadcastType = Table:RemoveToken(tokens)

	if broadcastType == nil then
		CommYell:_ToggleBroadcast()
		return
	end
	broadcastType = string.lower(broadcastType)
	if broadcastType == GT.L['SEND'] and GT.DBComm:IsBroadcasting() then
		GT.DBComm:SetBroadcasting(false)
		GT.Log:PlayerInfo(GT.L['BROADCAST_SEND_OFF'])
		return
	elseif broadcastType == GT.L['SEND'] then
		GT.DBComm:SetBroadcasting(true)
		GT.Log:PlayerInfo(GT.L['BROADCAST_SEND_ON'])
		return
	end

	if broadcastType == GT.L['RECEIVE'] and GT.DBComm:IsReceivingBroadcasts() then
		GT.DBComm:SetReceivingBroadcasts(false)
		GT.Log:PlayerInfo(GT.L['BROADCAST_RECEIVE_OFF'])
		return
	elseif broadcastType == GT.L['RECEIVE'] then
		GT.DDBCommB:SetReceivingBroadcasts(true)
		GT.Log:PlayerInfo(GT.L['BROADCAST_RECEIVE_ON'])
		return
	end

	local message = string.gsub(GT.L['BROADCAST_UNKNOWN'], '%{{broadcast_type}}', broadcastType)
	GT.Log:PlayerWarn(message)
end

function CommYell:_ToggleBroadcast()
	GT.Log:Info('CommYell__ToggleBroadcast')
	if GT.DBComm:IsBroadcasting() or GT.DBComm:IsReceivingBroadcasts() then
		GT.DBComm:SetBroadcasting(false)
		GT.DBComm:SetReceivingBroadcasts(false)
		GT.DBComm:SetForwarding(false)
		GT.DBComm:SetReceivingForwards(false)
		GT.Log:PlayerInfo(GT.L['BROADCAST_ALL_OFF'])
		return
	end
	GT.DBComm:SetBroadcasting(true)
	GT.DBComm:SetReceivingBroadcasts(true)
	GT.DBComm:SetForwarding(true)
	GT.DBComm:SetReceivingForwards(true)
	GT.Log:PlayerInfo(GT.L['BROADCAST_ALL_ON'])
end

function CommYell:ToggleForwards(tokens)
	GT.Log:Info('CommYell_ToggleForwards', tokens)
	local broadcastType = Table:RemoveToken(tokens)

	if broadcastType == nil then
		CommYell:_ToggleForwards()
		return
	end

	broadcastType = string.lower(broadcastType)
	if broadcastType == GT.L['SEND_FORWARDS'] and GT.DBComm:IsForwarding() then
		GT.DBComm:SetForwarding(false)
		GT.Log:PlayerInfo(GT.L['BROADCAST_SEND_FORWARD_OFF'])
		return
	elseif broadcastType == GT.L['SEND_FORWARDS'] then
		GT.DBComm:SetForwarding(true)
		GT.Log:PlayerInfo(GT.L['BROADCAST_SEND_FORWARD_ON'])
		return
	end

	if broadcastType == GT.L['RECEIVE_FORWARDS'] and GT.DBComm:IsReceivingForwards() then
		GT.DBComm:SetReceivingForwards(false)
		GT.Log:PlayerInfo(GT.L['BROADCAST_SEND_FORWARD_OFF'])
		return
	elseif broadcastType == GT.L['RECEIVE_FORWARDS'] then
		GT.DBComm:SetReceivingForwards(true)
		GT.Log:PlayerInfo(GT.L['BROADCAST_SEND_FORWARD_ON'])
		return
	end

	local message = string.gsub(GT.L['BROADCAST_FORWARD_UNKNOWN'], '%{{broadcast_type}}', broadcastType)
	GT.Log:PlayerWarn(message)
end

function CommYell:_ToggleForwards()
	GT.Log:Info('CommYell__ToggleForwards')
	if GT.DBComm:IsForwarding() or GT.DBComm:IsReceivingForwards() then
		GT.DBComm:SetForwarding(false)
		GT.DBComm:SetReceivingForwards(false)
		GT.Log:PlayerInfo(GT.L['BROADCAST_FORWARDING_OFF'])
		return
	end
	GT.DBComm:SetForwarding(true)
	GT.DBComm:SetReceivingForwards(true)
	GT.Log:PlayerInfo(GT.L['BROADCAST_FORWARDING_ON'])
end

function CommYell:_ShouldSendPost(characterName)
	if not GT.DBCharacter:CharacterExists(characterName) then return false end
	local isCurrentCharacter = GT:IsCurrentCharacter(characterName)
	local character = GT.DBCharacter:GetCharacter(characterName)
	if GT.DBComm:IsBroadcasting() and isCurrentCharacter then
		return true
	end

	if GT.DBComm:IsForwarding() and not isCurrentCharacter and character.isBroadcasted then
		return true
	end
	return false
end

function CommYell:SendPost(characterName, professionName)
	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommYell_SendPost_CommDisabled')
		return
	end
	if not CommYell:_ShouldSendPost(characterName) then
		return
	end
	GT.Log:Info('CommYell_SendPost', characterName, professionName)

	local character = GT.DBCharacter:GetCharacter(characterName)
	for professionName, _ in pairs(character.professions) do
		local message = GT.Comm:GetPostMessage(characterName, professionName)
		if message ~= nil then
			GT.Comm:SendPost(GT.Comm.YELL, characterName, professionName, nil)
		end
	end
end