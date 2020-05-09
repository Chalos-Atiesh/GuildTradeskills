local GT_Name, GT = ...
local LOCALE = GetLocale()

local GREEN = '|cff3ce13f'
local YELLOW = '|cfffcba03'
local COLOR_END = '|r'

if LOCALE == 'enUS' or LOCALE == 'enGB' or GT.L == nil then
	local L = {}

	local tagTemplate = '{{first_color_start}}{{first_text}}{{first_color_end}}{{second_color_start}}{{second_text}}{{second_color_end}}{{end_text}}'

	local whisperTag = string.gsub(tagTemplate, '%{{first_color_start}}', '')
	whisperTag = string.gsub(whisperTag, '%{{first_text}}', 'G')
	whisperTag = string.gsub(whisperTag, '%{{first_color_end}}', '')
	whisperTag = string.gsub(whisperTag, '%{{second_color_start}}', '')
	whisperTag = string.gsub(whisperTag, '%{{second_text}}', 'T')
	whisperTag = string.gsub(whisperTag, '%{{second_color_end}}', '')
	whisperTag = string.gsub(whisperTag, '%{{end_text}}', ': ')

	local logTag = string.gsub(tagTemplate, '%{{first_color_start}}', GREEN)
	logTag = string.gsub(logTag, '%{{first_text}}', 'G')
	logTag = string.gsub(logTag, '%{{first_color_end}}', COLOR_END)
	logTag = string.gsub(logTag, '%{{second_color_start}}', YELLOW)
	logTag = string.gsub(logTag, '%{{second_text}}', 'T')
	logTag = string.gsub(logTag, '%{{second_color_end}}', COLOR_END)
	logTag = string.gsub(logTag, '%{{end_text}}', ': ')

	local longTag = string.gsub(tagTemplate, '%{{first_color_start}}', GREEN)
	longTag = string.gsub(longTag, '%{{first_text}}', 'Guild')
	longTag = string.gsub(longTag, '%{{first_color_end}}', COLOR_END)
	longTag = string.gsub(longTag, '%{{second_color_start}}', YELLOW)
	longTag = string.gsub(longTag, '%{{second_text}}', 'Tradeskills')
	longTag = string.gsub(longTag, '%{{second_color_end}}', COLOR_END)
	longTag = string.gsub(longTag, '%{{end_text}}', '')

	L['WHISPER_TAG'] = whisperTag
	L['LOG_TAG'] = logTag
	L['LONG_TAG'] = longTag

	---------- SLASH COMMANDS START ----------

	L['HELP_INTRO'] = 'Available slash commands.'

	L['SLASH_COMMANDS'] = {
		SLASH_COMMAND_HELP = {
			command = 'help',
			help = 'Print this message: ' .. SLASH_GT_SLASHCOMMAND1 .. ' help'
		},
		SLASH_COMMAND_SEARCH = {
			command = 'search',
			help = 'Open the search pane: ' .. SLASH_GT_SLASHCOMMAND1 .. ' search'
		},
		SLASH_COMMAND_PROFESSION_ADD = {
			command = 'addprofession',
			help = 'Add a profession: ' .. SLASH_GT_SLASHCOMMAND1 .. ' addprofession'
		},
		SLASH_COMMAND_PROFESSION_REMOVE = {
			command = 'removeprofession',
			help = 'Remove a profession: ' .. SLASH_GT_SLASHCOMMAND1 .. ' removeprofession {profession_name}'
		},
		SLASH_COMMAND_RESET = {
			command = 'reset',
			help = 'Reset everything. Yes, the entire addon: ' .. SLASH_GT_SLASHCOMMAND1 .. ' reset'
		},
		SLASH_COMMAND_CHAT_WINDOW = {
			command = 'chatwindow',
			help = 'Set the chat window that this addon prints to: ' ..SLASH_GT_SLASHCOMMAND1 .. ' chatwindow {chat_window_name}'
		}
	}

	L['COMMAND_INVALID'] = 'Sorry! \'' .. SLASH_GT_SLASHCOMMAND1 .. ' {{command}}\' is an invalid command. Get help with \'' .. SLASH_GT_SLASHCOMMAND1 .. ' ' .. L['SLASH_COMMANDS']['SLASH_COMMAND_HELP']['command'] .. '\'.'

	L['COMMAND_RESET_CONFIRM'] = 'confirm'
	L['COMMAND_RESET_CANCEL'] = 'cancel'
	
	---------- SLASH COMMANDS END ----------
	---------- PROFESSIONS START ----------

    L['ALCHEMY'] = 'Alchemy'
    L['BLACKSMITHING'] = 'Blacksmithing'
    L['ENCHANTING'] = 'Enchanting'
    L['ENGINEERING'] = 'Engineering'
    L['LEATHERWORKING'] = 'Leatherworking'
    L['TAILORING'] = 'Tailoring'
    L['COOKING'] = 'Cooking'

	L['PROFESSION_ADD_INIT'] = 'Please open the profession you want to add.'
	L['PROFESSION_ADD_CANCEL'] = 'Canceling profession add.'
	L['PROFESSION_ADD_SUCCESS'] = 'Successfully added profession \'{{profession_name}}\' to character \'{{character_name}}\'.'
	L['PROFESSION_REMOVE_NIL_CHARACTER'] = 'Looks like you did not pass a character name. You can remove a profession with \'' .. SLASH_GT_SLASHCOMMAND1 .. ' removeprofession {character_name} {prfession_name}'
	L['PROFESSION_REMOVE_NIL_PROFESSION'] = 'Looks like you did not pass a profession name. You can remove a profession with \'' .. SLASH_GT_SLASHCOMMAND1 .. ' removeprofession {prfession_name}'
	L['PROFESSION_REMOVE_PROFESSION_NOT_FOUND'] = 'Could not find profession \'{{profession_name}}\' for character \'{{character_name}}\' in the database.'
	L['PROFESSION_REMOVE_SUCCESS'] = 'Successfully removed profession \'{{profession_name}}\' from character \'{{character_name}}\'.'

	---------- PROFESSIONS END ----------
	---------- ERROR MESSAGES START ----------

	L['ERROR_PROFESSION_ADD'] = 'Encountered an error when adding profession: '
	L['RESET_UNKNOWN'] = 'Sorry! Dont\'t know what \'{{command}}\' is. Please try again.'

	---------- ERROR MESSAGES END ----------
	---------- GUI MESSAGES START ----------

	L['SEARCH_SKILLS'] = 'Search for skills:'
    L['SEARCH_REAGENTS'] = 'Search for reagents:'
    L['SEARCH_CHARACTERS'] = 'Search for characters:'
    L['LABEL_PROFESSIONS'] = 'Professions'
    L['LABEL_SKILLS'] = 'Skills'
    L['LABEL_REAGENTS'] = 'Reagents'
    L['LABEL_CHARACTERS'] = 'Characters'

    L['BUTTON_FILTERS_RESET'] = 'Clear Filters'

    L['WHISPER_REQUEST'] = L['WHISPER_TAG'] .. 'Hey {{character_name}}! Could you craft {{item_link}} for me?'
    L['WHISPER_SELECT_REQUIRED'] = 'No selected skill found. You must select a skill first.'
    L['WHISPER_NO_CHARACTER_FOUND'] = 'It doesn\'t look like the character \'{{character_name}}\' is online.'

	---------- GUI MESSAGES END ----------


	L['RESET_WARN'] = 'Are you sure? This will reset the entire addon. Type \'' .. SLASH_GT_SLASHCOMMAND1 .. ' ' .. L['SLASH_COMMANDS']['SLASH_COMMAND_RESET']['command'] .. ' ' .. L['COMMAND_RESET_CONFIRM'] .. '\' to confirm or \'' .. SLASH_GT_SLASHCOMMAND1 .. ' ' .. L['SLASH_COMMANDS']['SLASH_COMMAND_RESET']['command'] .. ' ' .. L['COMMAND_RESET_CANCEL'] .. '\' to cancel.'
	L['RESET_CHARACTER_WARN'] = 'Are you sure? This will delete all profession data for the current character. Type \'' .. SLASH_GT_SLASHCOMMAND1 .. ' ' .. L['SLASH_COMMANDS']['SLASH_COMMAND_RESET']['command'] .. ' ' .. L['COMMAND_RESET_CONFIRM'] .. '\' to confirm or \'' .. SLASH_GT_SLASHCOMMAND1 .. ' ' .. L['SLASH_COMMANDS']['SLASH_COMMAND_RESET']['command'] .. ' ' .. L['COMMAND_RESET_CANCEL'] .. '\' to cancel.'
	L['RESET_PROFESSION_WARN'] = 'Are you sure? This will delete all profession data for {{profession}}. Type \'' .. SLASH_GT_SLASHCOMMAND1 .. ' ' .. L['SLASH_COMMANDS']['SLASH_COMMAND_RESET']['command'] .. ' ' .. L['COMMAND_RESET_CONFIRM'] .. '\' to confirm or \'' .. SLASH_GT_SLASHCOMMAND1 .. ' ' .. L['SLASH_COMMANDS']['SLASH_COMMAND_RESET']['command'] .. ' ' .. L['COMMAND_RESET_CANCEL'] .. '\' to cancel.'
	L['RESET_FINAL'] = 'Resetting entire addon. We warned you.'
	L['RESET_CANCEL'] = 'Canceling addon reset.'

	L['GUILD_OFFLINE'] = '|cff7f7f7f{{guild_member}}|r - |cff7f7f7fOffline|r'
	L['GUILD_ONLINE'] = '|c{{class_color}}{{guild_member}}|r - |cff00ff00Online|r'

	L['WELCOME'] = 'Welcome to ' .. L['LONG_TAG'] .. '! For help getting started you can type \'' .. SLASH_GT_SLASHCOMMAND1 .. ' ' .. L['SLASH_COMMANDS']['SLASH_COMMAND_HELP']['command'] .. '\'.'

	GT.L = L
end