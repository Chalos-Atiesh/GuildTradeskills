local AddOnName, GT = ...

local GREEN = '|cff3ce13f'
local YELLOW = '|cfffcba03'
local COLOR_END = '|r'

local L = LibStub('AceLocale-3.0'):NewLocale(AddOnName, 'enUS', true, true)

local LONG_TAG = GREEN .. 'Guild' .. COLOR_END .. YELLOW .. 'Tradeskills' .. COLOR_END
local WHISPER_TAG = 'GT: '
local TRIGGER_CHAR = '?'

if L then
	---------- CHARACTER START ----------

	L['CHARACTER'] = 'character'

	L['CHARACTER_RESET_NOT_FOUND'] = 'Could not find character \'{{character_name}}\'.'
	L['CHARACTER_RESET_FINAL'] = 'Successfully reset character \'{{character_name}}\'.'

	---------- CHARACTER END ----------
	---------- COMMAND START ----------

	L['UNKNOWN_COMMAND'] = 'Sorry! Couldn\'t find the command \'{{command}}\'. Type \'' .. YELLOW .. '/gt help' .. COLOR_END .. '\' to get a list of available commands.'
	--@debug@
	L['FORCE'] = 'force'
	--@end-debug@

	L['SLASH_COMMANDS'] = {
		gt = {
			methodName = 'OnCommand',
			help = YELLOW .. '/gt' .. COLOR_END .. ': Toggle the search pane.',
			subCommands = {
				help = {
					methodName = 'Help',
					help = YELLOW .. '/gt help' .. COLOR_END .. ': Print this mesage.'
				},
				search = {
					methodName = 'Search',
					help = YELLOW .. '/gt search' .. COLOR_END .. ': Toggle the search pane.'
				},
				addprofession = {
					methodName = 'InitAddProfession',
					help = YELLOW .. '/gt addprofession' .. COLOR_END .. ': Toggle adding a profession.'
				},
				removeprofession = {
					methodName = 'RemoveProfession',
					help = YELLOW .. '/gt removeprofession {profession_name}' .. COLOR_END .. ': Removes a profession.'
				},
				window = {
					methodName = 'SetChatFrame',
					help = YELLOW .. '/gt window {window_name}' .. COLOR_END .. ': Sets the output to a chat window.'
				},
				reset = {
					methodName = 'Reset',
					help = YELLOW .. '/gt reset' .. COLOR_END .. ': Resets all stored info. |cffff0000This cannot be undone.|r'
				},
				advertise = {
					methodName = 'ToggleAdvertising',
					help = YELLOW .. '/gt advertise' .. COLOR_END .. ': Toggles whether you are advertising.' .. YELLOW .. ' /gt advertise {seconds}' .. COLOR_END .. ': Sets the number of seconds between advertisements.'
				}
			}
		}
	}

	L['RESET_WARN'] = 'Are you sure? This will reset the entire addon. Type \'/gt reset confirm\' to continue or \'/gt reset cancel\'.'
	L['RESET_EXPECT_COMFIRM'] = 'confirm'
	L['RESET_EXPECT_CANCEL'] = 'cancel'
	L['RESET_NO_CONFIRM'] = 'Sorry! Please type either \'/gt reset confirm\' to confirm or \'/gt reset cancel\' to cancel.'
	L['RESET_CANCEL'] = 'Canceling addon reset.'
	L['RESET_CHARACTER'] = 'Resetting character \'{{character_name}}\'. We warned you.'
	L['RESET_PROFESSION'] = 'Resetting profession \'{{profession_name}}\'. We warned you.'
	L['RESET_FINAL'] = 'Resetting entire addon. We warned you.'
	L['RESET_UNKNOWN'] = 'Sorry! We dont\'t know what \'{{token}}\' is.'

	---------- COMMAND END ----------
	---------- WHISPER START ----------

	L['TRIGGER_CHAR'] = TRIGGER_CHAR

	L['WHISPER_TAG'] = WHISPER_TAG
	L['WHISPER_FIRST_PROFESSION'] = '{{profession_name}}'
	L['WHISPER_SECOND_PROFESSION'] = ' and {{profession_name}}'
	L['WHISPER_PROFESSION_NOT_FOUND'] = WHISPER_TAG .. 'Whoops! Looks like I don\'t have \'{{profession_search}}\'. Available professions are {{first_profession}}{{second_profession}}.'
	L['WHISPER_NIL_PROFESSIONS'] = WHISPER_TAG .. 'Looks like I haven\'t added any professions. Please come back later!'

	L['WHISPER_INVALID_PAGE'] = WHISPER_TAG .. 'Oops! Page {{page}} isn\'t a valid page. I only have {{max_pages}} pages.'
	L['WHISPER_HEADER'] = WHISPER_TAG .. 'Page {{current_page}} of {{total_pages}}. I have {{total_skills}} skills.'
	L['WHISPER_ITEM'] = WHISPER_TAG .. '{{number}}. {{skill_link}}'
	L['WHISPER_FOOTER'] = WHISPER_TAG .. 'You can get the next page by replying \'' .. TRIGGER_CHAR .. '{{profession_name}} {{next_page}}\' or jump to a page by replying \'' .. TRIGGER_CHAR .. '{{profession_name}} {page_number}\'.'
	L['WHISPER_FOOTER_LAST_PAGE'] = WHISPER_TAG .. 'You can jump to a page by replying \'' .. TRIGGER_CHAR .. '{{profession_name}} {page_number}\'.'

    L['WHISPER_REQUEST'] = WHISPER_TAG .. 'Hey {{character_name}}! Could you craft {{item_link}} for me?'
    L['WHISPER_SELECT_REQUIRED'] = 'No selected skill found. You must select a skill first.'
    L['WHISPER_NO_CHARACTER_FOUND'] = 'It doesn\'t look like the character \'{{character_name}}\' is online.'

	---------- WHISPER END ----------
	---------- LOG START ----------

	L['LOG_TAG'] = GREEN .. 'G' .. COLOR_END .. YELLOW .. 'T' .. COLOR_END .. ': '

	--@debug@
	L['RECAP_HEADER'] = '---------- RECAP START ----------'
	L['RECAP_FOOTER'] = '---------- RECAP END ----------'
	L['LOG_DUMP'] = 'Log Dump'
	L['CHARACTERS'] = 'CHARACTERS'
	L['PROFESSIONS'] = 'PROFESSIONS'
	--@end-debug@

	---------- LOG END ----------
	---------- PROFESSION START ----------

	L['PROFESSION'] = 'profession'

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
	L['PROFESSION_REMOVE_NIL_PROFESSION'] = 'Looks like you did not pass a profession name. You can remove a profession with \'/gt removeprofession {prfession_name}'
	L['PROFESSION_REMOVE_NOT_FOUND'] = 'Could not find profession \'{{profession_name}}\' for character \'{{character_name}}\'.'
	L['PROFESSION_REMOVE_SUCCESS'] = 'Successfully removed profession \'{{profession_name}}\' from character \'{{character_name}}\'.'

	L['PROFESSION_RESET_NOT_FOUND'] = 'Could not find profession \'{{profession_name}}\'.'
	L['PROFESSION_RESET_FINAL'] = 'Successfully reset profession \'{{profession_name}}\'.'

	---------- PROFESSION END ----------
	---------- GUI START ----------

	L['LONG_TAG'] = LONG_TAG

	L['WELCOME'] = 'Welcome to ' .. LONG_TAG .. '! For help getting started you can type \'/gt help\'.'

	L['SEARCH_SKILLS'] = 'Search for skills:'
    L['SEARCH_REAGENTS'] = 'Search for reagents:'
    L['SEARCH_CHARACTERS'] = 'Search for characters:'
    L['LABEL_PROFESSIONS'] = 'Professions'
    L['LABEL_SKILLS'] = 'Skills'
    L['LABEL_REAGENTS'] = 'Reagents'
    L['LABEL_CHARACTERS'] = 'Characters'

    L['BUTTON_FILTERS_RESET'] = 'Clear Filters'
    
	L['GUILD_OFFLINE'] = '|cff7f7f7f{{guild_member}}|r - |cff7f7f7fOffline|r'
	L['GUILD_ONLINE'] = '|c{{class_color}}{{guild_member}}|r - |cff00ff00Online|r'

	L['CHAT_FRAME_NIL'] = 'Looks like you didn\'t pass a chat window name. You can do so with \'/gt chatwindow {window_name}\'.'
	L['CHAT_WINDOW_SUCCESS'] = 'Set ouput chat window to \'{{frame_name}}\'.'
	L['CHAT_WINDOW_INVALID'] = 'Sorry! We couldn\'t find a chat window with name \'{{frame_name}}\'.'

	L['UPDATE_AVAILABLE'] = LONG_TAG .. ' is out of date. Your version is {{local_version}} and {{remote_version}} is available.'

	L['CORRUPTED_DATABASE'] = 'Unfortunately it seems your database has become corrupted. Please reset it with \'/gt reset\'.'

	---------- GUI END ----------
	---------- ADVERTISE START ----------

	L['ADVERTISE_ON'] = 'Now advertising!'
	L['ADVERTISE_OFF'] = 'Stopped advertising.'

	L['ADVERTISING_INVALID_INTERVAL'] = '\'{{interval}}\' is an invalid time. It must be in seconds.'
	L['ADVERTISE_MINIMUM_INTERVAL'] = '{{interval}} seconds is too short. Setting interval to {{minimum_interval}} seconds.'
	L['ADVERTISE_SET_INTERVAL'] = 'Set advertising interval to {{interval}} seconds.'
	L['ADVERTISE_NO_PROFESSIONS'] = 'Uh oh! Looks like you haven\'t added any professios to advertise. You can add one with \'/gt addprofession\'.' 

	L['ADVERTISE_FIRST_PROFESSION'] = '{{skill_count}} {{profession_name}}'
	L['ADVERTISE_SECOND_PROFESSION'] = ' and {{skill_count}} {{profession_name}}'
	L['ADVERTISE_FIRST_WHISPER'] = '\'' .. TRIGGER_CHAR .. '{{profession_name}}\' or \'' .. TRIGGER_CHAR .. '{{profession_name}} {search}\''
	L['ADVERTISE_SECOND_WHISPER'] = ' or \'' .. TRIGGER_CHAR .. '{{profession_name}}\' or \'' .. TRIGGER_CHAR .. '{{profession_name}} {search}\'' 
	L['ADVERTISE_ADVERTISEMENT'] = WHISPER_TAG .. 'Offering my crafting services! I have {{first_profession}}{{second_profession}} recipies. Whisper {{first_whisper}}{{second_whisper}}.'

	---------- ADVERTISE END ----------
	---------- SYSTEM START ----------

	L['GUILD_MEMBER_ONLINE'] = '^.*%[(.*)%].* has come online'
	L['GUILD_MEMBER_OFFLINE'] = '(.*) has gone offline'

	---------- SYSTEM END ----------
end
