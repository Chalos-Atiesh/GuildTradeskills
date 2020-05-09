local GT_Name, GT = ...

local EVENT_MAP = {}
local SLASH_COMMAND_MAP = {}
local RESET_COMMAND_MAP = {}
local SLASH_COMMAND_DELIMITER = ' '
GT.state = {}
GT.state.initialized = false
GT.state.resetWarned = false

local function GT_Init()
	if GT.state.initialized then
		return
	end

	EVENT_MAP = {
		PLAYER_LOGIN = GT_PlayerLogin,
		PPLAYER_ENTERING_WORLD = GT_PlayerEnteringWorld,
		ADDON_LOADED = GT_AddonLoaded,
		TRADE_SKILL_UPDATE = GT_TradeSkillUpdate,
		CRAFT_UPDATE = GT_TradeSkillUpdate,
		PLAYER_GUILD_UPDATE = GT_GuildUpdate
	}

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

	GT.logging.init()
	GT.database.init()
	GT.comm.init()
	GT.player.init()
	GT.search.init()

	GT.logging.info('GT_Core_Init')

	GT.logging.playerInfo(GT.L['WELCOME'], nil, true)

	GT.state.initialized = true
end

---------- START EVENT HANDLERS ----------

local function GT_MainEventHandler(frame, event, ...)
	if event == 'ADDON_LOADED' then
		GT_AddonLoaded(frame, event, ...)
		return
	end
	for mapEvent, fn in pairs(EVENT_MAP) do
		if event == mapEvent then
			GT.logging.info(event)
			fn(frame, event, ...)
		end
	end
end

function GT_AddonLoaded(frame, event, ...)
	local name = ...
	if name == GT_Name then
		GT_Init()
	end
end

function GT_PlayerLogin(frame, event, ...)
	GT.player.init()
	GT.comm.sendDeletions()
	GT.comm.sendTimestamps()
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

local mainFrame = CreateFrame('Frame')
mainFrame:RegisterEvent('PLAYER_LOGIN')
mainFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
mainFrame:RegisterEvent('ADDON_LOADED')
mainFrame:RegisterEvent('TRADE_SKILL_UPDATE')
mainFrame:RegisterEvent('CRAFT_UPDATE')
mainFrame:RegisterEvent('PLAYER_GUILD_UPDATE')

mainFrame:SetScript('OnEvent', GT_MainEventHandler)

---------- END EVENT HANDLERS ----------
---------- START SLASH COMMAND HANDLERS ----------

SLASH_GT_SLASHCOMMAND1 = '/gt'

function SlashCmdList.GT_SLASHCOMMAND(msg)
	local tokens = GT.textUtils.tokenize(msg, SLASH_COMMAND_DELIMITER)
	local command = tokens[1]
	tokens = GT.tableUtils.removeToken(tokens)
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