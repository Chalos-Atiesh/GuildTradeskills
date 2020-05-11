local GT_Name, GT = ...

GT = LibStub('AceAddon-3.0'):NewAddon('GuildTradeskills')

local EVENT_MAP = {}
local SLASH_COMMAND_MAP = {}
local RESET_COMMAND_MAP = {}
local SLASH_COMMAND_DELIMITER = ' '
GT.version = '@project-version@'
GT.state = {}
GT.state.slashMapInitialized = false
GT.state.initialized = false
GT.state.resetWarned = false

function GT:OnEnable()
	if GT.state.initialized then
		return
	end

	EVENT_MAP = {
		PLAYER_LOGIN = GT_PlayerLogin,
		PLAYER_ENTERING_WORLD = GT_PlayerEnteringWorld,
		ADDON_LOADED = GT_AddonLoaded,
		TRADE_SKILL_UPDATE = GT_TradeSkillUpdate,
		CRAFT_UPDATE = GT_TradeSkillUpdate,
		PLAYER_GUILD_UPDATE = GT_GuildUpdate,
		CHAT_MSG_WHISPER = GT_OnWhisperReceived
		--@debug@
		,CHAT_MSG_SYSTEM = GT_AFK
		--@end-debug@
	}

	GT.logging.init()
	GT.database.init()
	GT.comm.init()
	GT.player.init()
	GT.search.init()

	GT.logging.info('GT_Core_Init')

	GT.state.initialized = true
end

function GT_InitSlashCommandMap()
	if GT.state.slashMapInitialized then
		return
	end
	GT.logging.info('GT_InitSlashCommandMap')
	SLASH_COMMAND_MAP[GT.L['SLASH_COMMANDS']['SLASH_COMMAND_HELP']['command']] = GT_SlashCommandHelp

	SLASH_COMMAND_MAP[GT.L['SLASH_COMMANDS']['SLASH_COMMAND_SEARCH']['command']] = GT.search.openSearch

	SLASH_COMMAND_MAP[GT.L['SLASH_COMMANDS']['SLASH_COMMAND_PROFESSION_ADD']['command']] = GT.professions.initAdd
	SLASH_COMMAND_MAP[GT.L['SLASH_COMMANDS']['SLASH_COMMAND_PROFESSION_REMOVE']['command']] = GT.professions.removeProfession

	SLASH_COMMAND_MAP[GT.L['SLASH_COMMANDS']['SLASH_COMMAND_RESET']['command']] = GT_Reset
	SLASH_COMMAND_MAP[GT.L['SLASH_COMMANDS']['SLASH_COMMAND_CHAT_WINDOW']['command']] = GT.logging.setChatFrame

	--@debug@
	SLASH_COMMAND_MAP['togglecomms'] = GT.comm.toggleComms
	SLASH_COMMAND_MAP['delimit'] = GT_Delimit
	--@end-debug@
	
	GT.state.slashMapInitialized = true
end

---------- START EVENT HANDLERS ----------

function GT_MainEventHandler(frame, event, ...)
	if event == 'ADDON_LOADED' then
		-- GT_AddonLoaded(frame, event, ...)
		return
	end
	for mapEvent, fn in pairs(EVENT_MAP) do
		if event == mapEvent then
			if GT.logging ~= nil then
				GT.logging.info(event)
			else
				print(event)
			end
			fn(frame, event, ...)
		end
	end
end

-- function GT_AddonLoaded(frame, event, ...)
-- 	local name = ...
-- 	if name == GT_Name then
-- 		GT:OnEnable()
-- 	end
-- end

function GT_PlayerLogin(frame, event, ...)
	GT.logging.playerInfo(GT.L['WELCOME'], nil, true)
	GT.player.init()
	GT.comm.sendDeletions()
	GT.comm.sendTimestamps()
	GT.comm.sendVersion()
end

function GT_PlayerEnteringWorld(frame, event, ...)
	GT.player.guildUpdate()
end

function GT_TradeSkillUpdate(frame, event, ...)
	GT.professions.addProfession()
end

function GT_GuildUpdate(frame, event, ...)
	GT.player.guildUpdate()
end

function GT_OnWhisperReceived(frame, event, ...)

end

--@debug@
function GT_AFK(frame, event, message)
	if message ~= nil and message == IDLE_MESSAGE then
		ForceQuit()
	end
end
--@end-debug@

local mainFrame = CreateFrame('Frame')
mainFrame:RegisterEvent('PLAYER_LOGIN')
mainFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
mainFrame:RegisterEvent('ADDON_LOADED')
mainFrame:RegisterEvent('TRADE_SKILL_UPDATE')
mainFrame:RegisterEvent('CRAFT_UPDATE')
mainFrame:RegisterEvent('PLAYER_GUILD_UPDATE')
mainFrame:RegisterEvent('CHAT_MSG_WHISPER')

--@debug@
mainFrame:RegisterEvent("CHAT_MSG_SYSTEM")
--@end-debug@

mainFrame:SetScript('OnEvent', GT_MainEventHandler)

---------- END EVENT HANDLERS ----------
---------- START SLASH COMMAND HANDLERS ----------

SLASH_GT_SLASHCOMMAND1 = '/gt'

function SlashCmdList.GT_SLASHCOMMAND(msg)

	local tokens = GT.textUtils.tokenize(msg, SLASH_COMMAND_DELIMITER)
	local command, tokens = GT.tableUtils.removeToken(tokens)
	local commandFound = false
	for mapCommand, fn in pairs(SLASH_COMMAND_MAP) do
		if mapCommand == string.lower(command) then
			fn(tokens)
			commandFound = true
			break
		end
	end
	if not commandFound then
		GT.logging.playerError(string.gsub(GT.L['COMMAND_INVALID'], '%{{command}}', msg))
	end
end

function GT_SlashCommandHelp()
	GT.logging.playerInfo(GT.L['HELP_INTRO'])
	for _, slashCommand in pairs(GT.L['SLASH_COMMANDS']) do
		GT.logging.playerInfo(slashCommand['help'])
	end
end

function GT_Reset(tokens)
	if not GT.state.resetWarned then
		if #tokens <= 0 then
			GT.logging.playerWarn(GT.L['RESET_WARN'])
		else

		end
		GT.state.resetWarned = true
		return
	end
	
	if string.lower(tokens[#tokens]) == GT.L['COMMAND_RESET_CONFIRM'] then
		GT.logging.playerWarn(GT.L['RESET_FINAL'])
		GT.database.reset()
		GT.logging.reset()
		GT.player.reset()
		GT.state.resetWarned = false
	elseif string.lower(tokens[#tokens]) == GT.L['COMMAND_RESET_CANCEL'] then
		GT.logging.playerInfo(GT.L['RESET_CANCEL'])
		GT.state.resetWarned = false
	else
		GT.logging.playerWarn(string.gsub(GT.L['RESET_UNKNOWN'], '%{{command}}', tokens[#tokens]))
	end
end

--@debug@
function GT_Delimit()
	GT.logging.info('----------')
end
--@end-debug@

---------- END SLASH COMMAND HANDLERS ----------