local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local Event = GT:NewModule('Event')
GT.Event = Event

LibStub('AceEvent-3.0'):Embed(Event)

local EVENT_MAP = {}

function Event:OnEnable()
	-- GT.Log:Info('Event_OnEnable')
	
	EVENT_MAP = {
		PLAYER_LOGIN = 'PlayerLogin',
		PLAYER_ENTERING_WORLD = 'PlayerEnteringWorld',
		ADDON_LOADED = 'AddonLoaded',
		TRADE_SKILL_UPDATE = 'TradeSkillUpdate',
		CRAFT_UPDATE = 'TradeSkillUpdate',
		CHAT_MSG_WHISPER = 'WhisperReceived',
		CHAT_MSG_CHANNEL_NOTICE = 'ChannelNotice',
		CHAT_MSG_SYSTEM = 'ChatMessageSystem'
	}

	for event, methodName in pairs(EVENT_MAP) do
		-- GT.Log:Info('Event_RegisterEvent', event, methodName)
		Event:RegisterEvent(event, methodName)
	end
end

function Event:PlayerLogin()
	GT.Log:Info('Event_PlayerLogin')
end

function Event:PlayerEnteringWorld()
	GT.Log:Info('Event_PlayerEnteringWorld')
end

function Event:AddonLoaded()
	GT.Log:Info('Event_AddonLoaded')
end

function Event:TradeSkillUpdate()
	GT.Log:Info('Event_TradeSkillUpdate')
	GT.Profession:AddProfession()
end

function Event:WhisperReceived(...)
	GT.Log:Info('Event_WhisperReceived')
	GT.Whisper:OnWhisperReceived(...)
end

function Event:ChannelNotice(...)
	local event = select(1, ...)
	local subEvent = select(2, ...)
	local channelType = select(8, ...)
	local channelNumber = select(9, ...)

	GT.Log:Info('Event_ChannelNotice', event, subEvent, channelType, channelNumber)

	if GT.Table:Contains(GT.Advertise.events, subEvent) then
		GT.Advertise:ChannelNotice(subEvent, channelType, channelNumber)
	end
end

function Event:ChatMessageSystem(event, message)
	GT.CommGuild:ChatMessageSystem(message)
end