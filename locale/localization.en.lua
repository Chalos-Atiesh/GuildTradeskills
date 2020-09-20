local AddOnName, GT = ...

local GREEN = '|cff3ce13f'
local YELLOW = '|cffe0ca0a'
local COLOR_END = '|r'

local L = LibStub('AceLocale-3.0'):NewLocale(AddOnName, 'enUS', true, true)

local LONG_TAG = GREEN .. 'Guild' .. COLOR_END .. YELLOW .. 'Tradeskills' .. COLOR_END
local WHISPER_TAG = 'GT: '
local TRIGGER_CHAR = '?'

local ONLINE = 'Online'
local OFFLINE = 'Offline'

local CHARACTER_NIL = 'You must pass a character name. \''

local ALCHEMY = 'Alchemy'
local BLACKSMITHING = 'Blacksmithing'
local ENCHANTING = 'Enchanting'
local ENGINEERING = 'Engineering'
local LEATHERWORKING = 'Leatherworking'
local TAILORING = 'Tailoring'
local COOKING = 'Cooking'

if L then
	---------- CLASSES START ----------

	-- The KEY should be the localized value here.
	-- It should be in all caps.
	-- We use it for getting class colors.
	L['DRUID'] = 'DRUID'
	L['HUNTER'] = 'HUNTER'
	L['MAGE'] = 'MAGE'
	L['PALADIN'] = 'PALADIN'
	L['PRIEST'] = 'PRIEST'
	L['ROGUE'] = 'ROGUE'
	L['SHAMAN'] = 'SHAMAN'
	L['WARLOCK'] = 'WARLOCK'
	L['WARRIOR'] = 'WARRIOR'

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
			order = 0,
			methodName = 'OnCommand',
			help = YELLOW .. '/gt' .. COLOR_END .. ': Toggle the search pane.',
			subCommands = {
				help = {
					order = 0,
					methodName = 'Help',
					help = YELLOW .. '/gt help' .. COLOR_END .. ': Print this mesage.'
				},
				opt = {
					order = 1,
					methodName = 'Options',
					help = YELLOW .. '/gt opt' .. COLOR_END .. ': Toggles the options panel.'
				},
				addprofession = {
					order = 2,
					methodName = 'InitAddProfession',
					help = YELLOW .. '/gt addprofession' .. COLOR_END .. ': Toggles adding a profession. Open the profession you want to add after.'
				},
				removeprofession = {
					order = 3,
					methodName = 'RemoveProfession',
					help = YELLOW .. '/gt removeprofession {profession_name}' .. COLOR_END .. ': Removes a profession.'
				},
				advertise = {
					order = 4,
					methodName = 'ToggleAdvertising',
					help = YELLOW .. '/gt advertise' .. COLOR_END .. ': Toggles whether you are advertising.',
					subCommands = {
						seconds = {
							parens = true,
							methodName = 'ToggleAdvertising',
							help =  YELLOW .. '/gt advertise {seconds}' .. COLOR_END .. ': Sets the number of seconds between advertisements.'
						}
					}
				},
				add = {
					order = 5,
					methodName = 'SendRequest',
					help = YELLOW .. '/gt add {character_name}' .. COLOR_END .. ': Requests to add a specific character.'
				},
				reject = {
					order = 6,
					methodName = 'SendReject',
					help = YELLOW .. '/gt reject {character_name}' .. COLOR_END .. ': Rejects someone\'s request to add you. They can request again.'
				},
				ignore = {
					order = 7,
					methodName = 'SendIgnore',
					help = YELLOW .. '/gt ignore {character_name}' .. COLOR_END .. ': Ignores that person. No requests from that account should get through.'
				},
				requests = {
					order = 8,
					methodName = 'ShowRequests',
					help = YELLOW .. '/gt requests' .. COLOR_END .. ': Lists the characters that have requested to add you.'
				},
				broadcast = {
					order = 9,
					methodName = 'ToggleBroadcast',
					help = YELLOW .. '/gt broadcast' .. COLOR_END .. ': Toggles all broadcasting capabilities.',
					subCommands = {
						send = {
							order = 0,
							methodName = 'ToggleBroadcast',
							help = YELLOW .. '/gt broadcast send' .. COLOR_END .. ': Toggles whether you are sending broadcasts to everyone. ' .. YELLOW .. 'Yes, everyone everyone.' .. COLOR_END
						},
						receive = {
							order = 1,
							methodName = 'ToggleBroadcast',
							help = YELLOW .. '/gt broadcast receive' .. COLOR_END .. ': Toggles whether you are receiving broadcasts from everyone. ' .. YELLOW .. 'Yes, everyone everyone.' .. COLOR_END
						},
						sendforwards = {
							order = 2,
							methodName = 'ToggleForwards',
							help = YELLOW .. '/gt broadcast sendforwards' .. COLOR_END .. ': Toggles whether you are frowarding broadcasts that you have received. ' .. YELLOW .. 'Use with caution. This may impact performance.' .. COLOR_END
						},
						receiveforwards = {
							order = 3,
							methodName = 'ToggleForwards',
							help = YELLOW .. '/gt broadcast receiveforwards' .. COLOR_END .. ': Toggles whether you are accepting forwarded broadcasts that you ahve received. ' .. YELLOW .. 'Use with caution. This may impact performance.' .. COLOR_END
						}

					}
				},
				window = {
					order = 10,
					methodName = 'SetChatFrame',
					help = YELLOW .. '/gt window {window_name}' .. COLOR_END .. ': Sets the output to a chat window.'
				},
				reset = {
					order = 11,
					methodName = 'Reset',
					help = YELLOW .. '/gt reset' .. COLOR_END .. ': Resets all stored info. |cffff0000This cannot be undone.|r'
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

	L['QUERY_TOOLTIP'] = 'Right click to ask about: {{skill}}'

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

    L['WHISPER_INCOMING_REQUESTS'] = 'You have requests from: {{character_names}}'
    L['WHISPER_NO_INCOMING_REQUESTS'] = 'You have no requests.'

	---------- WHISPER END ----------
	---------- LOG START ----------

	L['LOG_TAG'] = GREEN .. 'G' .. COLOR_END .. YELLOW .. 'T' .. COLOR_END .. ': '

	L['DUMP_PROFESSION_NIL'] = 'You must pass a profession name: /gt dumpprofession {profession_name}'
	L['DUMP_PROFESSION_NOT_FOUND'] = 'Whoops! Could not find profession: {{profession_name}}'
	L['DUMP_PROFESSION'] = 'Dumping profession: {{profession_name}}'

	L['DUMP_CHARACTER_NIL'] = 'You must pass a character name: /gt dumpcharacter {character_name}'
	L['DUMP_CHARACTER_NOT_FOUND'] = 'Whoops! Could not find character: {{character_name}}'
	L['DUMP_CHARACTER'] = 'Dumping character: {{character_name}}'

	---------- LOG END ----------
	---------- PROFESSION START ----------

	L['PROFESSION'] = 'profession'

	L['PROFESSIONS_LIST'] = {
		ALCHEMY = ALCHEMY,
		BLACKSMITHING = BLACKSMITHING,
		ENCHANTING = ENCHANTING,
		ENGINEERING = ENGINEERING,
		LEATHERWORKING = LEATHERWORKING,
		TAILORING = TAILORING,
		COOKING = COOKING
	}

	L['PROFESSION_ADD_INIT'] = 'Please open the profession you want to add.'
	L['PROFESSION_ADD_UNSUPPORTED'] = 'Sorry! {{profession_name}} is not currently supported.'
	L['PROFESSION_ADD_CANCEL'] = 'Canceling profession add.'
	L['PROFESSION_ADD_PROGRESS'] = 'Fetching data from the server. This should only take a few seconds.'
	L['PROFESSION_ADD_SUCCESS'] = 'Successfully added profession: {{profession_name}}'
	L['PROFESSION_REMOVE_NIL_PROFESSION'] = 'Looks like you did not pass a profession name. You can remove a profession with \'/gt removeprofession {prfession_name}'
	L['PROFESSION_REMOVE_NOT_FOUND'] = 'Could not find profession \'{{profession_name}}\' for character \'{{character_name}}\'.'
	L['PROFESSION_REMOVE_SUCCESS'] = 'Successfully removed profession \'{{profession_name}}\' from character \'{{character_name}}\'.'

	L['PROFESSION_RESET_NOT_FOUND'] = 'Could not find profession: {{profession_name}}'
	L['PROFESSION_RESET_FINAL'] = 'Successfully reset profession: {{profession_name}}'

	---------- PROFESSION END ----------
	---------- GUI START ----------

		---------- OPTIONS START -----------

		L['LABEL_OPEN_SEARCH'] = 'Open Search'
		L['DESC_OPEN_SEARCH'] = 'Opens the search panel.'

		L['CANCEL'] = 'Cancel'
		L['OKAY'] = 'Okay'

		L['DESC_PROFESSIONS'] = 'Your currently tracked professions on this character.'

		L['PROFESSION_ADD_NAME'] = 'Add Profession'
		L['PROFESSION_ADD_DESC'] = 'Add a profession to this character.'
		L['PROFESSION_ADD_CANCEL_DESC'] = 'Cancel adding profession.'

		L['PROFESSION_DELETE_NAME'] = 'Remove Profession'
		L['PROFESSION_DELETE_DESC'] = 'Stop tracking this profession on this character.'
		L['PROFESSION_DELETE_CONFIRM'] = 'Are you sure you want to stop tracking {{profession_name}}?'

		L['LABEL_ADD_CHARACTER'] = 'Add Non-Guild Character'
		L['DESC_ADD_CHARACTER'] = 'Add a character that is not in your guild.'

		L['LABEL_NON_GUILD_CHARACTERS'] = 'Non-Guild Characters'
		L['DESC_NON_GUILD_CHARACTERS'] = 'Characters you have added that are not in your guild.'

		L['LABEL_CHARACTER_REMOVE'] = 'Remove Character'
		L['DESC_CHARACTER_REMOVE'] = 'Stop tracking this character.'
		L['CHARACTER_REMOVE_CONFIRM'] = 'Are you sure you want to remove {{character_name}}?'

		L['LABEL_REQUESTS_TOGGLE_ALL'] = 'Allow All'
		L['LABEL_REQUESTS_TOGGLE_CONFIRM'] = 'Require Confirm'
		L['LABEL_REQUESTS_TOGGLE_NONE'] = 'Allow None'
		L['DESC_REQUESTS_TOGGLE'] = 'Set how many requests you allow.'

		L['LABEL_REQUESTS'] = 'Requests'
		L['DESC_REQUESTS'] = 'These characters have requested to add you.'

		L['LABEL_SEND_CONFIRM'] = 'Accept'
		L['DESC_SEND_CONFIRM'] = 'Accept their request.'

		L['LABEL_SEND_REJECT'] = 'Deny'
		L['DESC_SEND_REJECT'] = 'Deny their request.'

		L['LABEL_SEND_IGNORE'] = 'Ignore'
		L['DESC_SEND_IGNORE'] = 'Ignore this character.'
		L['CHARACTER_IGNORE_CONFIRM'] = 'Are you sure you want to ignore {{character_name}}?'

		L['LABEL_ADVERTISING'] = 'Advertising'
		L['DESC_ADVERTISE_TOGGLE'] = 'Toggle auto-advertising.'

		L['LABEL_ADVERTISING_INTERVAL'] = 'Advertising Interval'
		L['DESC_ADVERTISING_INTERVAL'] = 'How many minutes you want to wait between advertisements.'

		L['BROADCASTING'] = 'Broadcasting'

		L['LABEL_BROADCAST_INTERVAL'] = 'Broadcast Interval'
		L['DESC_BROADCAST_INTERVAL'] = 'How wmany minutes between broadcasts.'

		L['LABEL_SEND_BROADCAST'] = 'Send Broadcasts'
		L['DESC_SEND_BROADCAST'] = 'Broadcast your skills to everyone.'
		L['CONFIRM_SEND_BROADCAST'] = 'You will broadcast your skills to everyone. Yes, everyone everyone. Are you sure?'

		L['LABEL_RECEIVE_BROADCASTS'] = 'Accept Broadcasts'
		L['DESC_RECEIVE_BROADCASTS'] = 'Accept broadcasts from everyone.'
		L['CONFIRM_RECEIVE_BROADCASTS'] = 'Everyone will be able to add themselves. Yes, everyone everyone. Are you sure?'

		L['LABEL_SEND_FORWARDS'] = 'Forward Broadcasts'
		L['DESC_SEND_FORWARDS'] = 'Forward other player\'s broadcasts.'
		L['CONFIRM_SEND_FORWARDS'] = 'This feature is in beta. You may experience issues. You will forward any broadcasted character. Are you sure?'

		L['LABEL_RECEIVE_FORWARDS'] = 'Accept Forwards'
		L['DESC_RECEIVE_FORWARDS'] = 'Accept forwarded broadcasts.'
		L['CONFIRM_RECEIVE_FORWARDS'] = 'This feature is in beta. You may experience issues. You will accept any forwarded broadcasts. Are you sure?'

		---------- OPTIONS END ----------

	L['BARE_LONG_TAG'] = 'GuildTradeskills'
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
    
    L['ONLINE'] = ONLINE
    L['OFFLINE'] = OFFLINE
	L['BROADCASTED_TAG'] = '|cff7f7f7f{{guild_member}}|r'
	L['OFFLINE_TAG'] = '|c{{class_color}}{{guild_member}}|r - |cff7f7f7f' .. OFFLINE ..'|r'
	L['ONLINE_TAG'] = '|c{{class_color}}{{guild_member}}|r - |cff00ff00' .. ONLINE .. '|r'

	L['CHAT_FRAME_NIL'] = 'Looks like you didn\'t pass a chat window name. You can do so with ' .. YELLOW .. '\'/gt chatwindow {window_name}\'' .. COLOR_END ..'.'
	L['CHAT_WINDOW_SUCCESS'] = 'Set ouput chat window to \'{{frame_name}}\'.'
	L['CHAT_WINDOW_INVALID'] = 'Sorry! We couldn\'t find a chat window with name \'{{frame_name}}\'.'

	L['UPDATE_AVAILABLE'] = LONG_TAG .. ' is out of date. Your version is {{local_version}} and {{remote_version}} is available.'

	L['CORRUPTED_DATABASE'] = 'Unfortunately it seems your database has become corrupted. Please reset it with \'/gt reset\'.'

	L['NO_SKILL_SELECTED'] = 'You must select a skill before whispering a character.'
	L['SEND_WHISPER'] = WHISPER_TAG .. 'Hey {{character_name}}! Can you craft {{skill_link}} for me?'

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
	---------- BROADCAST START ----------

	L['SEND'] = 'send'
	L['RECEIVE'] = 'receive'
	L['SEND_FORWARDS'] = 'sendforwards'
	L['RECEIVE_FORWARDS'] = 'receiveforwards'

	L['BROADCAST_UNKNOWN'] = 'Sorry! We don\'t know the broadcast type \'{{broadcast_type}}\'.'

	L['BROADCAST_SEND_ON'] = 'You are now broadcasting to everyone.'
	L['BROADCAST_SEND_OFF'] = 'You are no longer broadcasting to anyone.'

	L['BROADCAST_RECEIVE_ON'] = 'You are now accepting broadcasts from everyone.'
	L['BROADCAST_RECEIVE_OFF'] = 'You are no longer accepting broadcasts from everyone.'

	L['BROADCAST_SEND_FORWARD_ON'] = 'You are now forwarding broadcasts.'
	L['BROADCAST_SEND_FORWARD_OFF'] = 'You are no longer forwarding broadcasts.'

	L['BROADCAST_FORWARDING_ON'] = 'You are now sending and accepting all forwarded broadcasts.'
	L['BROADCAST_FORWARDING_OFF'] = 'You are no longer sending or accepting forwarded broadcasts.'

	L['BROADCAST_FORWARD_UNKNOWN'] = 'Sorry! We dont\'t know the forwarded broadcast type \'{{broadcast_type}}\'.'

	L['BROADCAST_ALL_ON'] = 'You are now sending and receiving all broadcasts.'
	L['BROADCAST_ALL_OFF'] = 'You are no longer accepting any broadcasts.'

	---------- BROADCAST END ----------
	---------- NON-GUILD REQUEST START ----------

	L['REQUEST_ADDON_NOT_INSTALLED'] = 'It doesn\'t look like {{character_name}} has ' .. LONG_TAG .. ' installed.'

	L['REQUEST_CHARACTER_NIL'] = CHARACTER_NIL .. YELLOW .. '/gt add {character_name}' .. COLOR_END .. '\'.'
	L['REQUEST_NOT_SELF'] = 'You cannot add yourself.'
	L['REQUEST_NOT_GUILD'] = '{{character_name}} is a guildmate so you cannot add them.'
	L['REQUEST_REPEAT'] = 'You already have an outgoing request to {{character_name}}. You cannot send another.'
	L['REQUEST_EXISTS'] = 'You have already added {{character_name}}. You cannot add them again.'
	L['REQUEST_INCOMING'] = '{{character_name}} would like to add you in ' .. LONG_TAG .. '. Type \'' .. YELLOW .. '/gt help' .. COLOR_END .. '\' to see what to do.'

	L['CONFIRM_CHARACTER_NIL'] = CHARACTER_NIL .. YELLOW .. '/gt add {character_name}' .. COLOR_END .. '\'.'
	L['CONFIRM_NOT_SELF'] = 'You cannot confirm yourself.'
	L['CONFIRM_NOT_GUILD'] = '{{character_name}} is a guildmate so you cannot confirm them.'
	L['CONFIRM_REPEAT'] = 'You already have an outgoing confirmation to {{character_name}}. You cannot send another.'
	L['CONFIRM_EXISTS'] = 'You have already added {{character_name}}. You cannot confirm them again.'
	L['CONFIRM_INCOMING'] = '{{character_name}} has accepted your request! You should see their items shortly.'
	L['CONFIRM_NIL'] = '{{character_name}} has not sent you a request to confirm.'

	L['REJECT_CHARACTER_NIL'] = CHARACTER_NIL .. YELLOW .. '/gt reject {character_name}' .. COLOR_END .. '\'.'
	L['REJECT_NOT_SELF'] = 'You cannot reject yourself.'
	L['REJECT_NOT_GUILD'] = 'Sorry! {{character_name}} is a guildmate so you cannot reject them.'
	L['REJECT_ALREADY_IGNORED'] = 'You have already ignored {{character_name}}. You cannot reject them.'
	L['REJECT_REPEAT'] = 'You already have an outgoing rejection to {{character_name}}. You cannot send another at this time.'
	L['REJECT_NIL'] = '{{character_name}} has not sent you a request to reject.'

	L['IGNORE_CHARACTER_NIL'] = CHARACTER_NIL .. YELLOW .. '/gt ignore {character_name}' .. COLOR_END .. '\'.'
	L['IGNORE_NOT_SELF'] = 'You cannot ignore yourself.'
	L['IGNORE_NOT_GUILD'] = '{{character_name}} is a guildmate so you cannot ignore them.'
	L['IGNORE_REPEAT'] = 'You have already ignored {{character_name}}. You cannot ignore them again.'
	L['IGNORE_INCOMING'] = 'You have been ignored by {{character_name}}. You can no longer send requests to them.'
	L['IGNORE_OUTGOING'] = '{{character_name}} has been added to your ignore list. You should not receive any requests from this account.'
	L['IGNORE_REMOVE'] = 'Removed {{character_name}} from your ignore list. You will now receive requests from that account.'
	L['IGNORE_ALREADY_IGNORED'] = 'You have already ignored {{character_name}}. You cannot ignore them again.'

	L['CHARACTER_NOT_FOUND'] = 'Whoops! Looks like the character \'{{character_name}}\' does not exist.'

	L['INCOMING_REQUEST'] = '{{character_name}} would like to add you in ' .. LONG_TAG .. '. Type \'' .. YELLOW .. '/gt help' .. COLOR_END .. '\' to see what to do.'
	L['INCOMING_CONFIRM'] = '{{character_name}} has accepted your request! You should see their items shortly.'
	L['INCOMING_REJECT'] = '{{character_name}} has rejected your invitation.'
	L['INCOMING_IGNORE'] = 'You have been ignored by {{character_name}}. You can no longer send requests to them.'

	L['INCOMING_REQUEST_TIMEOUT'] = 'The request from {{character_name}} has timed out and has been canceled. You can re-request with \'' .. YELLOW .. '/gt add {character_name}' .. COLOR_END .. '\'.'

	L['OUTGOING_REQUEST_ONLINE'] = 'A request has been sent to {{character_name}}. If they accept they will be added to your list.'
	L['OUTGOING_CONFIRM_ONLINE'] = 'Accepted request from {{character_name}}! You should see their items shortly.'
	L['OUTGOING_REJECT_ONLINE'] = 'Your rejection has been sent to {{character_name}}.'
	L['OUTGOING_IGNORE_ONLINE'] = '{{character_name}} has been notified that they have been ignored.'

	L['OUTGOING_REQUEST_TIMEOUT'] = 'Your request to {{character_name}} has timed out and has been canceled. You can re-request with \'' .. YELLOW .. '/gt add {character_name}' .. COLOR_END .. '\'.'
	L['OUTGOING_CONFIRM_TIMEOUT'] = 'Your confirmation to {{character_name}} has timed out. You can refresh it with \'' .. YELLOW .. '/gt add {character_name}' .. COLOR_END .. '\'.'
	L['OUTGOING_REJECT_TIMEOUT'] = 'Your rejection to {{character_name}} has timed out. You can refresh it with \'' .. YELLOW .. '/gt reject {character_name}' .. COLOR_END .. '\'.'
	L['OUTGOING_IGNORE_TIMEOUT'] = 'Your ignore of {{character_name}} has timed out. However you will still not receive requests from them.'

	L['OUTGOING_REQUEST_OFFLINE'] = '{{character_name}} is offline. The request will be sent when you both are online at the same time.'
	L['OUTGOING_CONFIRM_OFFLINE'] = '{{character_name}} is offline. We will confirm with them when you both are online at the same time.'
	L['OUTGOING_REJECT_OFFLINE'] = '{{character_name}} is offline. The rejection will be sent when you both are online at the same time.'
	L['OUTGOING_IGNORE_OFFLINE'] = '{{character_name}} is offline. Then ignore will be sent when you both are online and you will stop receiving requests from them.'

	---------- NON-GUILD REQUEST END ----------
	---------- MISC START ----------

	L['PRINT_DELIMITER'] = ', '
	L['ADDED_BY'] = 'Added by'
	L['X'] = 'x'

	L['REMOVE_GUILD'] = 'These characters are no longer part of the guild and have been removed: {{character_names}}'
	L['REMOVE_GUILD_INACTIVE'] = 'These characters in the guild have been inactive for {{timeout_days}} days and have been removed: {{character_names}}'

	L['REMOVE_WHISPER_INACTIVE'] = 'These characters that you have added have been inactive for {{timeout_days}} and have been removed: {{character_names}}'

	---------- MISC END ----------
end
