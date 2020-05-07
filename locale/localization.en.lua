local GT_Name, GT = ...
local LOCALE = GetLocale()

if LOCALE == 'enUS' or LOCALE == 'enGB' or GT.L == nil then
	local L = {}

	L['SHORT_TAG'] = '|cff3ce13fG|rT'
	L['CHAT_TAG'] = L['SHORT_TAG'] .. ': '
	L['LONG_TAG'] = '|cff3ce13fGuild|r Tradeskills'

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
			help = 'Remove a profession: ' .. SLASH_GT_SLASHCOMMAND1 .. ' removeprofession {character_name} {profession_name}'
		},
		SLASH_COMMAND_RESET = {
			command = 'reset',
			help = 'Reset everything. Yes, the entire addon: ' .. SLASH_GT_SLASHCOMMAND1 .. ' reset'
		}
	}

	L['RESET_COMMANDS'] = {
		RESET_PROFESSION = {
			command = 'profession',
			help = 'Resets professions for a character. This cannot be undone.'
		},
		RESET_CHARACTER = {
			command = 'character',
			help = 'Resets a character deleting all stored profession data. This cannot be undone.'
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
	L['PROFESSION_ADD_SUCCESS'] = 'Successfully added profession \'{{profession_name}}\' to character \'{{character_name}}\'.'
	L['PROFESSION_REMOVE_NIL_CHARACTER'] = 'Looks like you did not pass a character name. You can remove a profession with \'' .. SLASH_GT_SLASHCOMMAND1 .. ' removeprofession {character_name} {prfession_name}'
	L['PROFESSION_REMOVE_NIL_PROFESSION'] = 'Looks like you did not pass a profession name. You can remove a profession with \'' .. SLASH_GT_SLASHCOMMAND1 .. ' removeprofession {character_name} {prfession_name}'
	L['PROFESSION_REMOVE_CHARACTER_NOT_FOUND'] = 'Could not find character \'{{chracter_name}}\' in the database.'
	L['PROFESSION_REMOVE_PROFESSION_NOT_FOUND'] = 'Could not find profession \'{{profession_name}}\' for character \'{{chracter_name}}\' in the database.'
	L['PROFESSION_REMOVE_SUCCESS'] = 'Successfully removed profession \'{{profession_name}}\' from character \'{{chracter_name}}\'.'

	---------- PROFESSIONS END ----------
	---------- CHARACTER MESSAGES START ----------

	L['CHARACTER_CREATE'] = 'Current character is nil. Creating it.'
	L['CHARACTER_REALM_UPDATE'] = 'Updating character realm: '
	L['CHARACTER_FACTION_UPDATE'] = 'Updating character faction: '
	L['CHARACTER_GUILD_UPDATE'] = 'Updating character guild: '
	L['CHARACTER_NAME_UPDATE'] = 'Updating character name: '

	L['CHARACTER_SET'] = 'Setting current character: '

	---------- CHARACTER MESSAGES END ----------
	---------- DATABASE MESSAGES START ----------

	L['DATABASE_CREATE'] = 'Current database is nil. Creating it.'

	L['DATABASE_REALM_CREATE'] = 'Database realm list is nil. Creating it.'
	L['DATABASE_FACTION_CREATE'] = 'Database faction list is nil. Creating it.'
	L['DATABASE_GUILD_CREATE'] = 'Database guild list is nil. Creating it.'
	L['DATABASE_CHARACTER_CREATE'] = 'Database character list is nil. Creating it.'
	L['DATABASE_PROFESSION_CREATE'] = 'Database profession list is nil. Creating it.'

	L['DATABASE_REALM_UPDATE'] = 'Updating database realm: '
	L['DATABASE_FACTION_UPDATE'] = 'Updating database faction: '
	L['DATABASE_GUILD_UPDATE'] = 'Updating database guild: '
	L['DATABASE_CHARACTER_UPDATE'] = 'Updating database character: '

	---------- DATABASE MESSAGES END ----------
	---------- ERROR MESSAGES START ----------

	L['ERROR_NIL_REALM'] = 'Character realm is nil.'
	L['ERROR_NIL_FACTION'] = 'Character faction is nil.'
	L['ERROR_NIL_GUILD'] = 'Could not find a guild for current character.'
	L['ERROR_NIL_NAME'] = 'could not find character name.'

	L['ERROR_PROFESSION_ADD'] = 'Encountered an error when adding profession: '
	L['ERROR_PROFESSION_NAME_NIL'] = 'Profession name is nil.'

	---------- ERROR MESSAGES END ----------
	---------- GUI MESSAGES START ----------

	L['SEARCH_SKILLS'] = 'Search for skills:'
    L['SEARCH_REAGENTS'] = 'Search for reagents:'
    L['SEARCH_CHARACTERS'] = 'Search for characters:'
    L['LABEL_SKILLS'] = 'Skills'
    L['LABEL_REAGENTS'] = 'Reagents'
    L['LABEL_CHARACTERS'] = 'Characters'

    L['BUTTON_FILTERS_RESET'] = 'Clear Filters'

    L['WHISPER_REQUEST'] = L['CHAT_TAG'] .. 'Hey {{character_name}}! Could you craft {{item_link}} for me?'
    L['WHISPER_SELECT_REQUIRED'] = 'No selected skill found. You must select a skill first.'
    L['WHISPER_NO_CHARACTER_FOUND'] = 'It doesn\'t look like the character \'{{character_name}}\' is online.'

	---------- GUI MESSAGES END ----------


	L['RESET_WARN'] = 'Are you sure? This will reset the entire addon. Type \'' .. SLASH_GT_SLASHCOMMAND1 .. ' ' .. L['SLASH_COMMANDS']['SLASH_COMMAND_RESET']['command'] .. ' ' .. L['COMMAND_RESET_CONFIRM'] .. '\' to confirm or \'' .. SLASH_GT_SLASHCOMMAND1 .. ' ' .. L['SLASH_COMMANDS']['SLASH_COMMAND_RESET']['command'] .. ' ' .. L['COMMAND_RESET_CANCEL'] .. '\' to cancel.'
	L['RESET_CHARACTER_WARN'] = 'Are you sure? This will delete all profession data for the current character. Type \'' .. SLASH_GT_SLASHCOMMAND1 .. ' ' .. L['SLASH_COMMANDS']['SLASH_COMMAND_RESET']['command'] .. ' ' .. L['COMMAND_RESET_CONFIRM'] .. '\' to confirm or \'' .. SLASH_GT_SLASHCOMMAND1 .. ' ' .. L['SLASH_COMMANDS']['SLASH_COMMAND_RESET']['command'] .. ' ' .. L['COMMAND_RESET_CANCEL'] .. '\' to cancel.'
	L['RESET_PROFESSION_WARN'] = 'Are you sure? This will delete all profession data for {{profession}}. Type \'' .. SLASH_GT_SLASHCOMMAND1 .. ' ' .. L['SLASH_COMMANDS']['SLASH_COMMAND_RESET']['command'] .. ' ' .. L['COMMAND_RESET_CONFIRM'] .. '\' to confirm or \'' .. SLASH_GT_SLASHCOMMAND1 .. ' ' .. L['SLASH_COMMANDS']['SLASH_COMMAND_RESET']['command'] .. ' ' .. L['COMMAND_RESET_CANCEL'] .. '\' to cancel.'
	L['RESET_FINAL'] = 'Resetting entire addon. We warned you.'
	L['RESET_CANCEL'] = 'Canceling addon reset.'
	L['RESET_UNKNOWN'] = 'Sorry! Dont\'t know what \'{{command}}\' is. Please try again.'

	L['GUILD_OFFLINE'] = '|cff7f7f7f{{guild_member}} - Offline|r'
	L['GUILD_ONLINE'] = '|c{{class_color}}{{guild_member}}|r - |cff00ff00Online|r'

	L['WELCOME'] = 'Welcome to ' .. L['LONG_TAG'] .. '! For help getting started you can type \'' .. SLASH_GT_SLASHCOMMAND1 .. ' ' .. L['SLASH_COMMANDS']['SLASH_COMMAND_HELP']['command'] .. '\'.'

	GT.L = L
end