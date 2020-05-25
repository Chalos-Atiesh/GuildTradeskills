local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local CommYell = GT:NewModule('CommYell')
GT.CommYell = CommYell

LibStub('AceComm-3.0'):Embed(CommYell)

CommYell.MIN_BROADCAST_INTERVAL = 60
CommYell.MAX_BROADCAST_INTERVAL = 300
CommYell.DEFAULT_BROADCAST_INTERVAL = 120

function CommYell:Broadcast()
	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommYell_Broadcast_CommDisabled')
		return
	end

	local characters = GT.DB:GetCharacters()
	for characterName, _ in pairs(characters) do
		local character = characters[characterName]
		if GT:IsCurrentCharacter(characterName) or character.isBroadcasted then
			for professionName, _ in pairs(character.professions) do
				CommYell:SendPost(characterName, professionName)
			end
		end
	end

	local wait = GT:GetWait(GT.DB:GetBroadcastInterval(), GT.Comm.COMM_VARIANCE)
	GT:Wait(wait, CommYell['Broadcast'])
end

function CommYell:ToggleBroadcast(tokens)
	GT.Log:Info('CommYell_ToggleBroadcast', tokens)
	local broadcastType = GT.Table:RemoveToken(tokens)

	if broadcastType == nil then
		CommYell:_ToggleBroadcast()
		return
	end
	broadcastType = string.lower(broadcastType)
	if broadcastType == GT.L['SEND'] and GT.DB:IsBroadcasting() then
		GT.DB:SetBroadcasting(false)
		GT.Log:PlayerInfo(GT.L['BROADCAST_SEND_OFF'])
		return
	elseif broadcastType == GT.L['SEND'] then
		GT.DB:SetBroadcasting(true)
		GT.Log:PlayerInfo(GT.L['BROADCAST_SEND_ON'])
		return
	end

	if broadcastType == GT.L['RECEIVE'] and GT.DB:IsReceivingBroadcasts() then
		GT.DB:SetReceivingBroadcasts(false)
		GT.Log:PlayerInfo(GT.L['BROADCAST_RECEIVE_OFF'])
		return
	elseif broadcastType == GT.L['RECEIVE'] then
		GT.DB:SetReceivingBroadcasts(true)
		GT.Log:PlayerInfo(GT.L['BROADCAST_RECEIVE_ON'])
		return
	end

	local message = string.gsub(GT.L['BROADCAST_UNKNOWN'], '%{{broadcast_type}}', broadcastType)
	GT.Log:PlayerWarn(message)
end

function CommYell:_ToggleBroadcast()
	GT.Log:Info('CommYell__ToggleBroadcast')
	if GT.DB:IsBroadcasting() or GT.DB:IsReceivingBroadcasts() then
		GT.DB:SetBroadcasting(false)
		GT.DB:SetReceivingBroadcasts(false)
		GT.DB:SetForwarding(false)
		GT.DB:SetReceivingForwards(false)
		GT.Log:PlayerInfo(GT.L['BROADCAST_ALL_OFF'])
		return
	end
	GT.DB:SetBroadcasting(true)
	GT.DB:SetReceivingBroadcasts(true)
	GT.DB:SetForwarding(true)
	GT.DB:SetReceivingForwards(true)
	GT.Log:PlayerInfo(GT.L['BROADCAST_ALL_ON'])
end

function CommYell:ToggleForwards(tokens)
	GT.Log:Info('CommYell_ToggleForwards', tokens)
	local broadcastType = GT.Table:RemoveToken(tokens)

	if broadcastType == nil then
		CommYell:_ToggleForwards()
		return
	end

	broadcastType = string.lower(broadcastType)
	if broadcastType == GT.L['SEND_FORWARDS'] and GT.DB:IsForwarding() then
		GT.DB:SetForwarding(false)
		GT.Log:PlayerInfo(GT.L['BROADCAST_SEND_FORWARD_OFF'])
		return
	elseif broadcastType == GT.L['SEND_FORWARDS'] then
		GT.DB:SetForwarding(true)
		GT.Log:PlayerInfo(GT.L['BROADCAST_SEND_FORWARD_ON'])
		return
	end

	if broadcastType == GT.L['RECEIVE_FORWARDS'] and GT.DB:IsReceivingForwards() then
		GT.DB:SetReceivingForwards(false)
		GT.Log:PlayerInfo(GT.L['BROADCAST_SEND_FORWARD_OFF'])
		return
	elseif broadcastType == GT.L['RECEIVE_FORWARDS'] then
		GT.DB:SetReceivingForwards(true)
		GT.Log:PlayerInfo(GT.L['BROADCAST_SEND_FORWARD_ON'])
		return
	end

	local message = string.gsub(GT.L['BROADCAST_FORWARD_UNKNOWN'], '%{{broadcast_type}}', broadcastType)
	GT.Log:PlayerWarn(message)
end

function CommYell:_ToggleForwards()
	GT.Log:Info('CommYell__ToggleForwards')
	if GT.DB:IsForwarding() or GT.DB:IsReceivingForwards() then
		GT.DB:SetForwarding(false)
		GT.DB:SetReceivingForwards(false)
		GT.Log:PlayerInfo(GT.L['BROADCAST_FORWARDING_OFF'])
		return
	end
	GT.DB:SetForwarding(true)
	GT.DB:SetReceivingForwards(true)
	GT.Log:PlayerInfo(GT.L['BROADCAST_FORWARDING_ON'])
end

function CommYell:_ShouldSendPost(characterName)
	if GT.DB:IsBroadcasting() and GT:IsCurrentCharacter(characterName) then
		return true
	end

	if GT.DB:IsForwarding() and not GT:IsCurrentCharacter(characterName) then
		return true
	end
	return false
end

function CommYell:SendPost(characterName, professionName)
	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommYell_SendPost_CommDisabled')
		return
	end
	if not CommYell:_ShouldSendPost(characterName) then
		return
	end
	GT.Log:Info('CommYell_SendPost', characterName, professionName)

	local character = GT.DB:GetCharacter(characterName)
	for professionName, _ in pairs(character.professions) do
		local message = GT.Comm:GetPostMessage(characterName, professionName)
		if message ~= nil then
			GT.Comm:SendPost(GT.Comm.YELL, characterName, professionName, nil)
		end
	end
end