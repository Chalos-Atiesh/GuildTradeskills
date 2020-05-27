local AddOnName, GT = ...

GT = LibStub('AceAddon-3.0'):NewAddon(AddOnName, 'AceComm-3.0', 'AceConsole-3.0', 'AceEvent-3.0', 'AceTimer-3.0')

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnName, true)
GT.L = L

---------- START LOAD LIBRARIES ----------

GT.Text = LibStub:GetLibrary('GTText')
GT.Table = LibStub:GetLibrary('GTTable')

---------- END LOAD LIBRARIES ----------

GT.resetWarned = false
GT.version = '@project-version@'

GT.STARTUP_DELAY = 5

local STARTUP_TASKS = {}

function GT:OnInitialize()
	GT.Log:Enable()

	GT.Log:Info('GT_OnInitialize')

	table.insert(STARTUP_TASKS, GT.Log['InitChatFrame'])
	table.insert(STARTUP_TASKS, GT.Comm['StartupTasks'])
	table.insert(STARTUP_TASKS, GT['Welcome'])
	table.insert(STARTUP_TASKS, GT.DB['PurgeGuild'])
	table.insert(STARTUP_TASKS, GT.Advertise['Advertise'])

	GT.Advertise:Enable()
	GT.Command:Enable()
	GT.Event:Enable()
	GT.Comm:Enable()
	GT.Whisper:Enable()
	GT.Friends:Enable()
	GT.Options:Enable()

	GT:ScheduleTimer(GT['StartupTasks'], GT.STARTUP_DELAY)
end

local waitTable = {};
local waitFrame = nil;

function GT:StartupTasks()
	GT:CreateActionQueue(GT.STARTUP_DELAY, STARTUP_TASKS)
end

function GT:Welcome()
	GT.Log:PlayerInfo(L['WELCOME'])
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

function GT:OnDisable()
	GT.Log:Info('GT_OnDisable')
end

function GT:InitReset(tokens)
	tokens = GT.Table:Lower(tokens)
	GT.Log:Info('GT_InitReset', tokens)
	local force = false
	--@debug@
	if GT.Table:Contains(tokens, L['FORCE']) then
		GT.Log:PlayerWarn('Forcing reset.')
		tokens = GT.Table:RemoveByValue(tokens, L['FORCE'])
		force = true
	end
	--@end-debug@
	if not GT.resetWarned and not force then
		GT.Log:PlayerWarn(L['RESET_WARN'])
		GT.resetWarned = true
		return
	end
	GT.resetWarned = false

	if GT.Table:Contains(tokens, L['RESET_CANCEL']) then
		GT.Log:PlayerInfo(L['RESET_CANCEL'])
		return
	end

	if not GT.Table:Contains(tokens, L['RESET_EXPECT_COMFIRM']) and not force then
		local message = string.gsub(L['RESET_UNKNOWN'], '%{{token}}', GT.Text:Concat(' ', tokens))
		GT.Log:PlayerWarn(message)
		return
	end

	GT:Reset(force)
end

function GT:Reset(force)
	GT.Log:PlayerWarn(L['RESET_FINAL'])

	GT.Log:Reset(force)
	GT.DB:Reset(force)
	GT.Advertise:Reset(force)
end

function GT:ResetProfession(professionName, force)
	local reset = GT.DB:ResetProfession(professionName)
	if not reset then
		local message = string.gsub(L['PROFESSION_RESET_NOT_FOUND'], '%{{profession_name}}', professionName)
		GT.Log:PlayerError(message)
		return
	end
	local message = string.gsub(L['PROFESSION_RESET_FINAL'], '%{{profession_name}}', professionName)
	GT.Log:PlayerInfo(message)
end

function GT:ResetCharacter(characterName, force)
	local reset = GT.DB:ResetCharacter(characterName)
	if not reset then
		local message = string.gsub(L['CHARACTER_RESET_NOT_FOUND'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)
		return
	end
	local message = string.gsub(L['CHARACTER_RESET_FINAL'], '%{{character_name}}', characterName)
	GT.Log:PlayerInfo(message)
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
	local version = GT:ConvertVersion(98, 99, 99)
	--@debug@
	if true then
		GT.DB:InitVersion(version)
		GT.Log:Info('GT_GetCurrentVersion', version)
		return version
	end
	--@end-debug@
	local tokens = GT.Text:Tokenize(GT.version, '_')
	local version = tokens[2]
	tokens = GT.Text:Tokenize(version, '.')
	rVersion, tokens = GT.Table:RemoveToken(tokens)
	bVersion, tokens = GT.Table:RemoveToken(tokens)
	aVersion, tokens = GT.Table:RemoveToken(tokens)

	version = GT:ConvertVersion(rVersion, bVersion, aVersion)
	GT.Log:Info('GT_GetCurrentVersion', version)

	GT.DB:InitVersion(version)

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
	if string.lower(GT:GetCurrentCharacter()) == string.lower(characterName) then
		return true
	end
	return false
end

function GT:GetCurrentCharacter()
	local characterName = UnitName('player')
	return characterName
end

function GT:IsGuildMember(characterName)
	local countTotalMembers, countOnlineMembers = GetNumGuildMembers()
	for i = 1, countTotalMembers do
		local tempCharacterName = GetGuildRosterInfo(i)
		tempCharacterName = Ambiguate(tempCharacterName, 'none')
		if string.lower(characterName) == string.lower(tempCharacterName) then
			return true
		end
	end
	return false
end