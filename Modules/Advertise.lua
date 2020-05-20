local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local Advertise = GT:NewModule('Advertise')
GT.Advertise = Advertise

Advertise.events = {}
Advertise.DEFAULT_INTERVAL = 60
Advertise.DEFAULT_IS_ADVERTISING = false

local CHANNEL_TYPE = 2
local CHANNEL_NUMBER = 2
local DEFAULT_INTERVAL = 120
local MINIMUM_INTERVAL = 60
local PREFIX = 'ADVERTISE'

local isInTrade = false
local lastAdvertise = nil

function Advertise:OnEnable()
	GT.Log:Info('Advertise_OnEnable')
	table.insert(Advertise.events, 'YOU_CHANGED')
	table.insert(Advertise.events, 'SUSPENDED')

	Advertise:SetChannelState()
end

function Advertise:Reset()
	lastAdvertise = nil
	GT.DB:SetAdvertising(Advertise.DEFAULT_IS_ADVERTISING)
	GT.DB:SetAdvertisingInterval(Advertise.DEFAULT_INTERVAL)
end

function Advertise:ChannelNotice(subEvent, channelType, channelNumber)
	GT.Log:Info('Advertise_ChannelNotice', subEvent, channelType, channelNumber)

	if channelType ~= CHANNEL_TYPE or channelNumber ~= CHANNEL_NUMBER then
		GT.Log:Info('Advertise_ChannelNotice_IgnoreChannelTypeNumber', channelType, channelNumber)
		return
	end

	Advertise:SetChannelState(subEvent)

	if not isInTrade then
		GT.Log:Info('Advertise_ChannelNotice_NotInChannel')
		return
	end

	if not GT.DB:IsAdvertising() then
		GT.Log:Info('Advertise_ChannelNotice_NotAdvertising')
		return
	end

	Advertise:Advertise()
end


function Advertise:Advertise()
	if not isInTrade then
		GT.Log:Info('Advertise_Advertise_NotInTrade')
		return
	end

	if not GT.DB:IsAdvertising() then
		GT.Log:Info('Advertise_Advertise_NotAdvertising')
		return
	end

	local interval = GT.DB:GetAdvertisingInterval()
	if lastAdvertise ~= nil and lastAdvertise + interval < time() then
		GT.Log:Warn('Advertise_Advertise_ShortenedInterval', lastAdvertise, interval, time())
		GT:Wait(interval, Advertise['Advertise'])
		lastAdvertise = time()
		return
	end

	lastAdvertise = time()
	GT.Log:Info('Advertise_Advertise')

	local characterName = UnitName('player')
	local professions = GT.DB:GetCharacter(characterName).professions

	local firstProfession = nil
	local secondProfession = nil

	local firstSkillCount = 0
	local secondSkillCount = 0
	for professionName, _ in pairs(professions) do
		local profession = professions[professionName]
		if firstProfession == nil then
			firstProfession = profession
		else
			secondProfession = profession
		end

		for skillName, _ in pairs(profession.skills) do
			if secondProfession == nil then
				firstSkillCount = firstSkillCount + 1
			else
				secondSkillCount = secondSkillCount + 1
			end
		end
	end

	if firstProfession == nil then
		GT.Log:PlayerWarn(GT.L['ADVERTISE_NO_PROFESSIONS'])
		return
	end

	local firstMessage = string.gsub(GT.L['ADVERTISE_FIRST_PROFESSION'], '%{{skill_count}}', firstSkillCount)
	firstMessage = string.gsub(firstMessage, '%{{profession_name}}', firstProfession.professionName)
	local firstWhisper = string.gsub(GT.L['ADVERTISE_FIRST_WHISPER'], '%{{profession_name}}', firstProfession.professionName)

	local secondMessage = ''
	local secondWhisper = ''
	if secondProfession ~= nil then
		secondMessage = string.gsub(GT.L['ADVERTISE_SECOND_PROFESSION'], '%{{skill_count}}', secondSkillCount)
		secondMessage = string.gsub(secondMessage, '%{{profession_name}}', secondProfession.professionName)
		secondWhisper = string.gsub(GT.L['ADVERTISE_SECOND_WHISPER'], '%{{profession_name}}', secondProfession.professionName)
	end

	local message = string.gsub(GT.L['ADVERTISE_ADVERTISEMENT'], '%{{first_profession}}', firstMessage)
	message = string.gsub(message, '%{{second_profession}}', secondMessage)
	message = string.gsub(message, '%{{first_whisper}}', firstWhisper)
	message = string.gsub(message, '%{{second_whisper}}', secondWhisper)

	GT.Log:Info('Advertise_Advertise_Advertise', message)

	--[===[@non-debug@
	ChatThrottleLib:SendChatMessage('ALERT', PREFIX, message, 'CHANNEL', 'Common', CHANNEL_NUMBER)
	--@end-non-debug@]===]

	GT:Wait(GT.DB:GetAdvertisingInterval(), Advertise['Advertise'])
end


function Advertise:ToggleAdvertising(tokens)
	local isAdvertising = GT.DB:IsAdvertising()

	local interval, tokens = GT.Table:RemoveToken(tokens)
	if interval == nil then
		local message = nil
		if GT.DB:IsAdvertising() then
			GT.DB:SetAdvertising(false)
			message = GT.L['ADVERTISE_OFF']
		else
			GT.DB:SetAdvertising(true)
			message = GT.L['ADVERTISE_ON']
			Advertise:Advertise()
		end
		GT.Log:PlayerInfo(message)
		return
	end

	if tonumber(interval) == nil then
		local message = string.gsub(GT.L['ADVERTISING_INVALID_INTERVAL'], '%{{interval}}', interval)
		GT.Log:PlayerError(message)
		return
	end

	interval = tonumber(interval)
	if interval < MINIMUM_INTERVAL then
		local message = string.gsub(GT.L['ADVERTISE_MINIMUM_INTERVAL'], '%{{interval}}', interval)
		message = string.gsub(message, '%{{minimum_interval}}', MINIMUM_INTERVAL)
		GT.Log:PlayerWarn(message)
		interval = MINIMUM_INTERVAL
	end

	local message = string.gsub(GT.L['ADVERTISE_SET_INTERVAL'], '%{{interval}}', interval)
	GT.Log:PlayerInfo(message)
	GT.DB:SetAdvertisingInterval(interval)
end

function Advertise:SetChannelState(subEvent)
	local id, name = GetChannelName(CHANNEL_NUMBER)
	if subEvent == 'YOU_CHANGED'
		or name ~= nil then
		isInTrade = true
	else
		isInTrade = false
	end
	GT.Log:Info('Advertise_SetChannelState', isInTrade)
end