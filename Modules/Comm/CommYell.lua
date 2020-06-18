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
local lastCharacterName = nil

function CommYell:OnEnable()
	table.insert(STARTUP_TASKS, CommYell['SendTimestamps'])
	table.insert(STARTUP_TASKS, CommYell['SendVersion'])
	table.insert(STARTUP_TASKS, CommYell['RemoveInactive'])
end

function CommYell:Reset()
	GT.DBComm:SetBroadcastInterval(CommYell.DEFAULT_BROADCAST_INTERVAL)
	GT.DBComm:SetIsBroadcasting(CommYell.DEFAULT_IS_BROADCASTING)
	GT.DBComm:SetIsReceivingBroadcasts(CommYell.DEFAULT_IS_RECEIVING_BROADCASTS)
	GT.DBComm:SetIsForwarding(CommYell.DEFAULT_IS_FORWARDING)
	GT.DBComm:SetIsReceivingForwards(CommYell.DEFAULT_IF_RECEIVING_FORWARDS)
end

function CommYell:StartupTasks()
	GT:CreateActionQueue(GT.STARTUP_DELAY, STARTUP_TASKS)
end

function CommYell:RemoveInactive()
	local characters = GT.DBCharacter:GetCharacters()
	for characterName, character in pairs(characters) do
		if not GT:IsCurrentCharacter(characterName) and character.isBroadcasted then
			local lastUpdate = character.lastCommReceived

			local professions = character.professions
			for professionName, profession in pairs(professions) do
				if profession.lastUpdate > lastUpdate then
					lastUpdate = profession.lastUpdate
				end
			end

			if lastUpdate + CommYell.INACTIVE_TIMEOUT < time() then
				GT.Log:Info('CommWhisper_RemoveInactive_RemoveCharacter', characterName, lastUpdate, time())
				GT.DBCharacter:DeleteCharacter(characterName)
			end
		end
	end
end

function CommYell:SendVersion()
	GT.Comm:SendVersion(GT.Comm.YELL, nil)
	local wait = GT:GetWait(GT.DBComm:GetBroadcastInterval(), GT.Comm.COMM_VARIANCE)
	GT:ScheduleTimer(CommYell['SendVersion'], wait)
end

function CommYell:SendTimestamps()
	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommYell_SendTimestamps_CommDisabled')
		return
	end

	local characterStrings = {}
	local size = 0

	if GT.DBComm:GetIsBroadcasting() then
		local characterString = GT.Comm:GetTimestampString(GT:GetCharacterName())
		if characterString ~= nil then
			size = size + #characterString
			GT.Log:Info('CommYell_SendTimestamps_Broadcasting', characterString)
			table.insert(characterStrings, characterString)
		end
	end

	if GT.DBComm:GetIsForwarding() then
		local characters = GT.DBCharacter:GetCharacters()
		local characterNames = Table:GetSortedKeys(characters, function(a, b) return a < b end, true)
		local adding = false
		for _, characterName in pairs(characterNames) do
			local character = characters[characterName]
			if character.isBroadcasted then
				if characterName == lastCharacterName then
					adding = true
				elseif lastCharacterName == nil or adding then
					adding = true
					local characterString = GT.Comm:GetTimestampString(characterName)
					if characterString ~= nil and size + #characterString < GT.Comm.COMM_SIZE_LIMIT then
						size = size + #characterString
						lastCharacterName = characterName
						table.insert(characterStrings, characterString)
					else
						break
					end
				end
			end
			lastCharacterName = nil
		end
	end

	GT.Log:Info('CommYell_SendTimestamps', characterStrings)
	if #characterStrings > 0 then
		local message = table.concat(characterStrings, GT.Comm.DELIMITER)
		GT.Log:Info('CommYell_SendTimestamps_Send', message)
		GT.Comm:SendCommMessage(GT.Comm.TIMESTAMP, message, GT.Comm.YELL, nil, GT.Comm.NORMAL)
	end

	GT:ScheduleTimer(CommYell['SendTimestamps'], GT.DBComm:GetBroadcastInterval())
end

function CommYell:OnTimestampsReceived(sender, toGet, toPost)
	if not GT.DBComm:GetIsEnabled() then
		GT.Log:Warn('CommYell_OnTimestampsReceived_CommDisabled')
		return
	end

	GT.Log:Info('CommYell_OnTimestampsReceived', sender, toGet, toPost)

	local sendLines = {}
	for characterName, _ in pairs(toGet) do
		GT.Log:Info('CommYell_OnTimestampsReceived_About', characterName)

		local shouldSendGet = true
		if characterName == sender and not GT.DBComm:GetIsReceivingBroadcasts() then
			GT.Log:Info('CommYell_OnTimestampsReceived_NotReceivingBroadcasts', sender)
			shouldSendGet = false
		end

		if characterName ~= sender and not GT.DBComm:GetIsReceivingForwards() then
			GT.Log:Info('CommYell_OnTimestampsReceived_NotReceivingForwards', sender, characterName)
			shouldSendGet = false
		end

		if GT:IsCurrentCharacter(characterName) then
			GT.Log:Info('CommYell_OnTimestampsReceived_AboutSelf', sender, characterName)
			shouldSendGet = false
		end

		if GT:IsGuildMember(characterName) then
			GT.Log:Info('CommYell_OnTimestampsReceived_AboutGuildMember', sender, characterName)
			shouldSendGet = false
		end

		local character = GT.DBCharacter:GetCharacter(characterName)
		if not GT:IsGuildMember(characterName) and character ~= nil and not character.isBroadcasted then
			GT.Log:Info('CommYell_OnTimestampsReceived_AboutAdded', sender, characterName)
			shouldSendGet = false
		end

		if shouldSendGet then
			for professionName, _ in pairs(toGet[characterName]) do
				table.insert((sendLines), Text:Concat(GT.Comm.DELIMITER, characterName, professionName))
			end
		end
	end

	if #sendLines > 0 then
		local message = table.concat(sendLines, GT.Comm.DELIMITER)
		GT.Log:Info('CommYell_OnTimestampsReceived_SendGet', sender, message)
		GT.Comm:SendCommMessage(GT.Comm.GET, message, GT.Comm.WHISPER, sender, 'NORMAL')
	end
end

function CommYell:ToggleBroadcast(tokens)
	GT.Log:Info('CommYell_ToggleBroadcast', tokens)
	local broadcastType = Table:RemoveToken(tokens)

	if broadcastType == nil then
		CommYell:_ToggleBroadcast()
		return
	end
	broadcastType = string.lower(broadcastType)
	if broadcastType == GT.L['SEND'] and GT.DBComm:GetIsBroadcasting() then
		GT.DBComm:SetIsBroadcasting(false)
		GT.Log:PlayerInfo(GT.L['BROADCAST_SEND_OFF'])
		return
	elseif broadcastType == GT.L['SEND'] then
		GT.DBComm:SetIsBroadcasting(true)
		GT.Log:PlayerInfo(GT.L['BROADCAST_SEND_ON'])
		return
	end

	if broadcastType == GT.L['RECEIVE'] and GT.DBComm:GetIsReceivingBroadcasts() then
		GT.DBComm:SetIsReceivingBroadcasts(false)
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
	if GT.DBComm:GetIsBroadcasting() or GT.DBComm:GetIsReceivingBroadcasts() then
		GT.DBComm:SetIsBroadcasting(false)
		GT.DBComm:SetIsReceivingBroadcasts(false)
		GT.DBComm:SetIsForwarding(false)
		GT.DBComm:SetIsReceivingForwards(false)
		GT.Log:PlayerInfo(GT.L['BROADCAST_ALL_OFF'])
		return
	end
	GT.DBComm:SetIsBroadcasting(true)
	GT.DBComm:SetIsReceivingBroadcasts(true)
	GT.DBComm:SetIsForwarding(true)
	GT.DBComm:SetIsReceivingForwards(true)
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
	if broadcastType == GT.L['SEND_FORWARDS'] and GT.DBComm:GetIsForwarding() then
		GT.DBComm:SetIsForwarding(false)
		GT.Log:PlayerInfo(GT.L['BROADCAST_SEND_FORWARD_OFF'])
		return
	elseif broadcastType == GT.L['SEND_FORWARDS'] then
		GT.DBComm:SetIsForwarding(true)
		GT.Log:PlayerInfo(GT.L['BROADCAST_SEND_FORWARD_ON'])
		return
	end

	if broadcastType == GT.L['RECEIVE_FORWARDS'] and GT.DBComm:GetIsReceivingForwards() then
		GT.DBComm:SetIsReceivingForwards(false)
		GT.Log:PlayerInfo(GT.L['BROADCAST_SEND_FORWARD_OFF'])
		return
	elseif broadcastType == GT.L['RECEIVE_FORWARDS'] then
		GT.DBComm:SetIsReceivingForwards(true)
		GT.Log:PlayerInfo(GT.L['BROADCAST_SEND_FORWARD_ON'])
		return
	end

	local message = string.gsub(GT.L['BROADCAST_FORWARD_UNKNOWN'], '%{{broadcast_type}}', broadcastType)
	GT.Log:PlayerWarn(message)
end

function CommYell:_ToggleForwards()
	GT.Log:Info('CommYell__ToggleForwards')
	if GT.DBComm:GetIsForwarding() or GT.DBComm:GetIsReceivingForwards() then
		GT.DBComm:SetIsForwarding(false)
		GT.DBComm:SetIsReceivingForwards(false)
		GT.Log:PlayerInfo(GT.L['BROADCAST_FORWARDING_OFF'])
		return
	end
	GT.DBComm:SetIsForwarding(true)
	GT.DBComm:SetIsReceivingForwards(true)
	GT.Log:PlayerInfo(GT.L['BROADCAST_FORWARDING_ON'])
end