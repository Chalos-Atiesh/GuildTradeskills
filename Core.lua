local AddOnName, GT = ...

GT = LibStub('AceAddon-3.0'):NewAddon(AddOnName, 'AceComm-3.0', 'AceConsole-3.0', 'AceEvent-3.0', 'AceTimer-3.0')

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnName, true)
GT.L = L

---------- START LOAD LIBRARIES ----------

GT.Friends = LibStub:GetLibrary('Friends')
GT.Log = LibStub:GetLibrary('Log')

---------- END LOAD LIBRARIES ----------

GT.resetWarned = false
GT.version = '@project-version@'

GT.DAY = 24 * 60 * 60
GT.STARTUP_DELAY = 5

local STARTUP_TASKS = {}

local frame = nil
local frameNumber = 0
local frameDelays = {}

function GT:OnInitialize()
	local frameNumber = GT.DB:GetChatFrameNumber()
	GT.Log:SetChatFrameByNumber(frameNumber)
	GT.Log:SetLogTag(GT.L['LOG_TAG'])

	GT.Log:Info('GT_OnInitialize')

	GT.DB:Enable()
	GT.Advertise:Enable()
	GT.Command:Enable()
	GT.Event:Enable()
	GT.Comm:Enable()
	GT.Whisper:Enable()
	GT.Options:Enable()

	table.insert(STARTUP_TASKS, GT['Welcome'])
	table.insert(STARTUP_TASKS, GT.Comm['StartupTasks'])
	table.insert(STARTUP_TASKS, GT.Advertise['Advertise'])

	frame = CreateFrame('Frame')
	frame:SetScript('OnUpdate', GT['ProcessFrameDelays'])

	GT:ScheduleTimer(GT['StartupTasks'], GT.STARTUP_DELAY)
end

local waitTable = {};
local waitFrame = nil;

function GT:StartupTasks()
	GT:CreateActionQueue(GT.STARTUP_DELAY, STARTUP_TASKS)
end

function GT:Welcome()
	local characterName = GT:GetCharacterName()
	local character = GT.DBCharacter:AddCharacter(characterName)
	character.class = GT:GetCharacterClass()
	character.isOnline = true
	
	if GT.DB:GetShouldPrintLoginMessage() then
		GT.Log:PlayerInfo(L['WELCOME'])
	end
	if not GT.DB.valid then
		GT.Log:PlayerError(L['CORRUPTED_DATABASE'])
	end
end

function GT:CreateActionQueue(delay, queue)
	local wait = 0
	for i, task in pairs(queue) do
		GT:ScheduleTimer(task, (i - 1) * delay)
	end
end

function GT:FrameDelay(frameCount, callback)
	local uuid = Text:UUID()
	delay = {
		endFrame = frameCount + frameNumber,
		callback = callback
	}

	frameDelays[uuid] = delay
end

function GT:ProcessFrameDelays()
	frameNumber = frameNumber + 1
	local remainingCallbackCount = 0
	local uuids = {}
	for uuid, delay in pairs(frameDelays) do
		if delay.endFrame <= frameNumber then
			delay.callback()
			table.insert(uuids, uuid)
		else
			remainingCallbackCount = remainingCallbackCount + 1
		end
	end
	for _, uuid in pairs(uuids) do
		frameDelays[uuid] = nil
	end
	if remainingCallbackCount <= 0 then
		frameNumber = 0
	end
end

function GT:InitReset(tokens)
	tokens = Table:Lower(tokens)
	GT.Log:Info('GT_InitReset', tokens)
	if not GT.resetWarned then
		GT.Log:PlayerWarn(L['RESET_WARN'])
		GT.resetWarned = true
		return
	end
	GT.resetWarned = false

	if Table:Contains(tokens, L['RESET_CANCEL']) then
		GT.Log:PlayerInfo(L['RESET_CANCEL'])
		return
	end

	if not Table:Contains(tokens, L['RESET_EXPECT_COMFIRM']) then
		local message = string.gsub(L['RESET_UNKNOWN'], '%{{token}}', Text:Concat(' ', tokens))
		GT.Log:PlayerWarn(message)
		return
	end

	GT:Reset()
end

function GT:Reset()
	GT.Log:PlayerWarn(L['RESET_FINAL'])

	GT.DB:Reset()
	GT.Log:Reset()
	GT.Advertise:Reset()
	GT.CommYell:Reset()
end

function GT:ConvertVersion(releaseVersion, betaVersion, alphaVersion)
	local rVersion = tonumber(releaseVersion) * 10000
	local bVersion = tonumber(betaVersion) * 100
	local aVersion = tonumber(alphaVersion)

	return rVersion + bVersion + aVersion
end

function GT:DeconvertVersion(version)
	GT.Log:Info('v', version)
	local rVersion = math.floor(version / 10000)
	GT.Log:Info('rVersion', rVersion)
	version = version - (rVersion * 10000)
	GT.Log:Info('v', version)
	local bVersion = math.floor(version / 100)
	GT.Log:Info('bVersion', bVersion)
	local aVersion = version - (bVersion * 100)
	GT.Log:Info('aVersion', aVersion)
	return rVersion, bVersion, aVersion
end

function GT:GetCurrentVersion()
	local version = GT:ConvertVersion(99, 99, 99)
	--@debug@
	if true then
		-- GT.Log:Info('GT_GetCurrentVersion', version)
		return version
	end
	--@end-debug@
	local tokens = Text:Tokenize(GT.version, '_')
	local version = tokens[2]
	tokens = Text:Tokenize(version, '.')
	rVersion, tokens = Table:RemoveToken(tokens)
	bVersion, tokens = Table:RemoveToken(tokens)
	aVersion, tokens = Table:RemoveToken(tokens)

	version = GT:ConvertVersion(rVersion, bVersion, aVersion)
	GT.Log:Info('GT_GetCurrentVersion', version)

	return version
end

function GT:GetWait(interval, variance)
	local adjustment = math.random(interval * variance)
	local invert = math.random(2) - 1
	if invert > 0 then
		adjustment = adjustment * -1
	end
	return interval + adjustment
end

function GT:IsCurrentCharacter(characterName)
	if GT:GetCharacterName() ~= nil and characterName ~= nil and string.lower(GT:GetCharacterName()) == string.lower(characterName) then
		return true
	end
	return false
end

function GT:GetCharacterName()
	local characterName = UnitName('player')
	return characterName
end

function GT:GetCharacterClass()
	local _, class = UnitClass('player')
	return string.upper(class)
end

function GT:IsGuildMember(characterName)
	characterName = string.lower(characterName)
	local countTotalMembers, countOnlineMembers = GetNumGuildMembers()
	for i = 1, countTotalMembers do
		local tempCharacterName = GetGuildRosterInfo(i)
		tempCharacterName = Ambiguate(tempCharacterName, 'none')
		if characterName == string.lower(tempCharacterName) then
			return true
		end
	end
	return false
end

function GT:GetGuildMemberClass(characterName)
	characterName = string.lower(characterName)
	local countTotalMembers, countOnlineMembers = GetNumGuildMembers()
	for i = 1, countTotalMembers do
		local characterName, _, _, _, class = GetGuildRosterInfo(i)
		tempCharacterName = Ambiguate(tempCharacterName, 'none')
		if characterName == string.lower(tempCharacterName) then
			return string.upper(class)
		end
	end
	return 'UNKNOWN'
end