local AddOnName, GT = ...

local GREEN = '|cff3ce13f'
local YELLOW = '|cffe0ca0a'
local COLOR_END = '|r'

local L = LibStub('AceLocale-3.0'):NewLocale(AddOnName, 'deDE', false, true)

local LONG_TAG = GREEN .. 'Guild' .. COLOR_END .. YELLOW .. 'Tradeskills' .. COLOR_END
local WHISPER_TAG = 'GT: '
local TRIGGER_CHAR = '?'

local ONLINE = 'Online'
local OFFLINE = 'Offline'

local CHARACTER_NIL = 'Du musst den Namen eines Charakters angeben. \''

local ALCHEMY = 'Alchimie'
local BLACKSMITHING = 'Schmiedekunst'
local COOKING = 'Kochkunst'
local ENCHANTING = 'Verzauberkunst'
local ENGINEERING = 'Ingenieurskunst'
local JEWELCRAFTING = 'Juwelenschleifen'
local LEATHERWORKING = 'Lederverarbeitung'
local TAILORING = 'Schneiderei'

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

	L['CHARACTER'] = 'Charakter'

	L['CHARACTER_RESET_NOT_FOUND'] = 'Charakter \'{{character_name}}\' nicht gefunden.'
	L['CHARACTER_RESET_FINAL'] = 'Charakter \'{{character_name}}\' erfolgreich zurückgesetzt.'

	---------- CHARACTER END ----------
	---------- COMMAND START ----------

	L['UNKNOWN_COMMAND'] = 'Sorry! Der Befehl \'{{command}}\' wurde nicht gefunden. Gib \'' .. YELLOW .. '/gt help' .. COLOR_END .. '\' ein um dir eine Liste mit den vorhandenen Befehlen anzuzeigen.'
	--@debug@
	L['FORCE'] = 'force'
	--@end-debug@

	L['SLASH_COMMANDS'] = {
		gt = {
			order = 0,
			methodName = 'OnCommand',
			help = YELLOW .. '/gt' .. COLOR_END .. ': Öffnet das Suchefenster.',
			subCommands = {
				help = {
					order = 0,
					methodName = 'Help',
					help = YELLOW .. '/gt help' .. COLOR_END .. ': Gibt diese Nachricht aus.'
				},
				opt = {
					order = 1,
					methodName = 'Options',
					help = YELLOW .. '/gt opt' .. COLOR_END .. ': Öffnet das Optionsmenü.'
				},
				addprofession = {
					order = 2,
					methodName = 'InitAddProfession',
					help = YELLOW .. '/gt addprofession' .. COLOR_END .. ': Startet das Hinzufügen eines Berufs. Öffne den gewünschten Beruf im Anschluss um ihn hinzuzufügen.'
				},
				removeprofession = {
					order = 3,
					methodName = 'RemoveProfession',
					help = YELLOW .. '/gt removeprofession {profession_name}' .. COLOR_END .. ': Löscht einen Beruf.'
				},
				--[[
				advertise = {
					order = 4,
					methodName = 'ToggleAdvertising',
					help = YELLOW .. '/gt advertise' .. COLOR_END .. ': Schaltet Werbung um.',
					subCommands = {
						seconds = {
							parens = true,
							methodName = 'ToggleAdvertising',
							help =  YELLOW .. '/gt advertise {seconds}' .. COLOR_END .. ': Setzt den Intervall der Werbung in Sekunden fest.'
						}
					}
				},
				--]]
				add = {
					order = 5,
					methodName = 'SendRequest',
					help = YELLOW .. '/gt add {character_name}' .. COLOR_END .. ': Sendet eine Datenanfrage an einen spezifischen Charakter.'
				},
				reject = {
					order = 6,
					methodName = 'SendReject',
					help = YELLOW .. '/gt reject {character_name}' .. COLOR_END .. ': Lehnt die Datenanfrage eines Charakters ab. Der Versuch kann wiederholt werden.'
				},
				ignore = {
					order = 7,
					methodName = 'SendIgnore',
					help = YELLOW .. '/gt ignore {character_name}' .. COLOR_END .. ': Vollständiges ignorieren eines Charakters.'
				},
				requests = {
					order = 8,
					methodName = 'ShowRequests',
					help = YELLOW .. '/gt requests' .. COLOR_END .. ': Gibt eine Liste der Charakter, die dir eine Anfrage gestellt haben, aus.'
				},
				broadcast = {
					order = 9,
					methodName = 'ToggleBroadcast',
					help = YELLOW .. '/gt broadcast' .. COLOR_END .. ': Schaltet alle Übertrgungsfunktionen um.',
					subCommands = {
						send = {
							order = 0,
							methodName = 'ToggleBroadcast',
							help = YELLOW .. '/gt broadcast send' .. COLOR_END .. ': Schaltet um ob Daten an alle Charakter gesendet werden. ' .. YELLOW .. 'Jepp, alle alle.' .. COLOR_END
						},
						receive = {
							order = 1,
							methodName = 'ToggleBroadcast',
							help = YELLOW .. '/gt broadcast receive' .. COLOR_END .. ': Schaltet um ob Daten von allen Charaktern empfangen werden. ' .. YELLOW .. 'Jepp, alle alle.' .. COLOR_END
						},
						sendforwards = {
							order = 2,
							methodName = 'ToggleForwards',
							help = YELLOW .. '/gt broadcast sendforwards' .. COLOR_END .. ': Schaltet um ob empfangene Daten weitergeleitet werden. ' .. YELLOW .. 'Diese Funktion kann Performanceeinbußen verursachen.' .. COLOR_END
						},
						receiveforwards = {
							order = 3,
							methodName = 'ToggleForwards',
							help = YELLOW .. '/gt broadcast receiveforwards' .. COLOR_END .. ': Schaltet um ob man weitergeleitete Daten empfangen möchte. ' .. YELLOW .. 'Diese Funktion kann Performanceeinbußen verursachen.' .. COLOR_END
						}

					}
				},
				window = {
					order = 10,
					methodName = 'SetChatFrame',
					help = YELLOW .. '/gt window {window_name}' .. COLOR_END .. ': Setzt die Ausgabe auf ein Chatfenster.'
				},
				reset = {
					order = 11,
					methodName = 'Reset',
					help = YELLOW .. '/gt reset' .. COLOR_END .. ': Setzt alle gespeicherten Daten zurück. |cffff0000Dies ist unumkehrbar.|r'
				}
			}
		}
	}

	L['RESET_WARN'] = 'Bist du dir sicher das alle Daten zurückgesetzt werden sollen. Gib \'/gt reset confirm\' ein um fortzufahren oder \'/gt reset cancel\' um abzubrechen.'
	L['RESET_EXPECT_COMFIRM'] = 'confirm'
	L['RESET_EXPECT_CANCEL'] = 'cancel'
	L['RESET_NO_CONFIRM'] = 'Sorry! Gib entweder \'/gt reset confirm\' um fortzufahren oder \'/gt reset cancel\' um abzubrechen, ein.'
	L['RESET_CANCEL'] = 'Breche das zurücksetzen der Daten ab.'
	L['RESET_CHARACTER'] = 'Verwerfe Charakter \'{{character_name}}\'. Wir haben dich gewarnt.'
	L['RESET_PROFESSION'] = 'Verwerfe Beruf \'{{profession_name}}\'. Wir haben dich gewarnt.'
	L['RESET_FINAL'] = 'Setze alle weiteren Daten zurück. Wir haben dich gewarnt.'
	L['RESET_UNKNOWN'] = 'Sorry! Wir wissen nicht was \'{{token}}\' ist.'

	---------- COMMAND END ----------
	---------- WHISPER START ----------

	L['TRIGGER_CHAR'] = TRIGGER_CHAR

	L['QUERY_TOOLTIP'] = 'Rechtklick für ein Anfrage zu: {{skill}}'

	L['WHISPER_TAG'] = WHISPER_TAG
	L['WHISPER_FIRST_PROFESSION'] = '{{profession_name}}'
	L['WHISPER_SECOND_PROFESSION'] = ' und {{profession_name}}'
	L['WHISPER_PROFESSION_NOT_FOUND'] = WHISPER_TAG .. 'Whoops! Sieht so aus als hätte ich \'{{profession_search}}\' nicht. Vorhandene Berufe sind {{first_profession}}{{second_profession}}.'
	L['WHISPER_NIL_PROFESSIONS'] = WHISPER_TAG .. 'Bisher habe ich noch kein Berufe hinzugefügt. Versuch es bitte später noch einmal!'

	L['WHISPER_INVALID_PAGE'] = WHISPER_TAG .. 'Oops! Seite {{page}} ist nicht korrekt. Ich habe nur {{max_pages}} Seiten.'
	L['WHISPER_HEADER'] = WHISPER_TAG .. 'Seite {{current_page}} von {{total_pages}}. Ich habe {{total_skills}} Skills.'
	L['WHISPER_ITEM'] = WHISPER_TAG .. '{{number}}. {{skill_link}}'
	L['WHISPER_FOOTER'] = WHISPER_TAG .. 'Für die nächste Seite bitte mit \'' .. TRIGGER_CHAR .. '{{profession_name}} {{next_page}}\' antworten oder fúr eine spezifische Seite antworte mit \'' .. TRIGGER_CHAR .. '{{profession_name}} {page_number}\'.'
	L['WHISPER_FOOTER_LAST_PAGE'] = WHISPER_TAG .. 'Antworte mit \'' .. TRIGGER_CHAR .. '{{profession_name}} {page_number}\' um direkt zu einer Seite zu springen.'

    L['WHISPER_REQUEST'] = WHISPER_TAG .. 'Hey {{character_name}}! Könntest du mir bitte  {{item_link}} herstellen?'
    L['WHISPER_SELECT_REQUIRED'] = 'Den ausgewählten Skill nicht gefunden. Du musst zuerst einen Skill auswählen.'
    L['WHISPER_NO_CHARACTER_FOUND'] = 'Es sieht nicht so aus als sei der Charakter \'{{character_name}}\' online.'

    L['WHISPER_INCOMING_REQUESTS'] = 'Du hast eine Anfrage von: {{character_names}}'
    L['WHISPER_NO_INCOMING_REQUESTS'] = 'Du hast keine Anfragen.'

	---------- WHISPER END ----------
	---------- LOG START ----------

	L['LOG_TAG'] = GREEN .. 'G' .. COLOR_END .. YELLOW .. 'T' .. COLOR_END .. ': '

	L['DUMP_PROFESSION_NIL'] = 'Du musst einen Beruf angeben: /gt dumpprofession {profession_name}'
	L['DUMP_PROFESSION_NOT_FOUND'] = 'Whoops! Beruf nicht gefunden: {{profession_name}}'
	L['DUMP_PROFESSION'] = 'Gib Beruf aus: {{profession_name}}'

	L['DUMP_CHARACTER_NIL'] = 'Du musst einen Charakternamen angeben: /gt dumpcharacter {character_name}'
	L['DUMP_CHARACTER_NOT_FOUND'] = 'Whoops! Charakter nicht gefunden: {{character_name}}'
	L['DUMP_CHARACTER'] = 'Gib Charakter aus: {{character_name}}'

	---------- LOG END ----------
	---------- PROFESSION START ----------

	L['PROFESSION'] = 'Beruf'

	L['PROFESSIONS_LIST'] = {
		ALCHEMY = ALCHEMY,
		BLACKSMITHING = BLACKSMITHING,
		COOKING = COOKING,
		ENCHANTING = ENCHANTING,
		ENGINEERING = ENGINEERING,
		JEWELCRAFTING = JEWELCRAFTING,
		LEATHERWORKING = LEATHERWORKING,
		TAILORING = TAILORING
	}

	L['PROFESSION_ADD_INIT'] = 'Bitte öffne den Beruf den du hinzufügen willst.'
	L['PROFESSION_ADD_CANCEL'] = 'Breche das Hinzufügen eines Berufs ab.'
	L['PROFESSION_ADD_PROGRESS'] = 'Hole die Daten vom Server. Dieser Vorgang kann ein paar Sekunden dauern.'
	L['PROFESSION_ADD_SUCCESS'] = 'Beruf erfolgreich hinzugefügt: {{profession_name}}'
	L['PROFESSION_REMOVE_NIL_PROFESSION'] = 'Du hast keine valide Berufsbezeichnung angegeben. Du kannst Berufe mit \'/gt removeprofession {profession_name} entfernen'
	L['PROFESSION_REMOVE_NOT_FOUND'] = 'Konnte den Beruf \'{{profession_name}}\' des Charakters \'{{character_name}}\' nicht finden.'
	L['PROFESSION_REMOVE_SUCCESS'] = 'Der Beruf \'{{profession_name}}\' des Charakters \'{{character_name}}\' wurde erfolgreich gelöscht.'

	L['PROFESSION_RESET_NOT_FOUND'] = 'Beruf nicht gefunden: {{profession_name}}'
	L['PROFESSION_RESET_FINAL'] = 'Beruf erfolgreich zurückgesetzt: {{profession_name}}'

	---------- PROFESSION END ----------
	---------- GUI START ----------

		---------- OPTIONS START -----------

		L['LABEL_OPEN_SEARCH'] = 'Suche Öffnen'
		L['DESC_OPEN_SEARCH'] = 'Öffnet das Suchfeld.'

		L['LABEL_SHOW_LOGIN_MESSAGE'] = 'Anmeldemeldung'
		L['DESC_SHOW_LOGIN_MESSAGE'] = 'Schaltet um, ob die Anmeldemeldung gedruckt wird.'

		L['CANCEL'] = 'Cancel'
		L['OKAY'] = 'Okay'

		L['DESC_PROFESSIONS'] = 'Deine derzeitig verfolgten Berufe des Charakters.'

		L['PROFESSION_ADD_NAME'] = 'Beruf hinzufügen.'
		L['PROFESSION_ADD_DESC'] = 'Füge einen Beruf zu diesem Charakter hinzu.'
		L['PROFESSION_ADD_CANCEL_DESC'] = 'Hinzufügen des Berufs abbrechen.'

		L['PROFESSION_DELETE_NAME'] = 'Beruf löschen.'
		L['PROFESSION_DELETE_DESC'] = 'Der Beruf wird auf diesem Charakter nicht mehr verfolgt.'
		L['PROFESSION_DELETE_CONFIRM'] = 'Bist du dir sicher das du den Beruf {{profession_name}} nicht mehr verfolgen willst?'

		L['LABEL_ADD_CHARACTER'] = 'Nicht-Gilden Charakter hinzufügen'
		L['DESC_ADD_CHARACTER'] = 'Füge einen Charakter hinzu, der nicht in deiner Gilde ist.'

		L['LABEL_NON_GUILD_CHARACTERS'] = 'Nicht-Gilden Charakter'
		L['DESC_NON_GUILD_CHARACTERS'] = 'Charakter die nicht in deiner Gilde sind.'

		L['LABEL_CHARACTER_REMOVE'] = 'Lösche Charakter'
		L['DESC_CHARACTER_REMOVE'] = 'Folge diesen Charakter nicht mehr.'
		L['CHARACTER_REMOVE_CONFIRM'] = 'Möchtest du {{character_name}} wirklich löschen?'

		L['LABEL_REQUESTS_TOGGLE_ALL'] = 'Alle Erlauben'
		L['LABEL_REQUESTS_TOGGLE_CONFIRM'] = 'Bestätigung erforderlich'
		L['LABEL_REQUESTS_TOGGLE_NONE'] = 'Keinen Erlauben'
		L['DESC_REQUESTS_TOGGLE'] = 'Lege fest wieviele Anfragen du erlaubst.'

		L['LABEL_REQUESTS'] = 'Anfragen'
		L['DESC_REQUESTS'] = 'Diese Charaktere möchten dich hinzufügen.'

		L['LABEL_SEND_CONFIRM'] = 'Akzeptieren'
		L['DESC_SEND_CONFIRM'] = 'Akzeptiere die Anfrage.'

		L['LABEL_SEND_REJECT'] = 'Abweisen'
		L['DESC_SEND_REJECT'] = 'Weise die Anfrage ab.'

		L['LABEL_SEND_IGNORE'] = 'Ignorieren'
		L['DESC_SEND_IGNORE'] = 'Ignoriere diesen Charakter.'
		L['CHARACTER_IGNORE_CONFIRM'] = 'Möchtest du den Charakter {{character_name}} wirklich ignorieren?'

		L['LABEL_ADVERTISING'] = 'Werbung'
		L['DESC_ADVERTISE_TOGGLE'] = 'Schalte die automatische Werbung um.'

		L['LABEL_ADVERTISING_INTERVAL'] = 'Werbungsintervall'
		L['DESC_ADVERTISING_INTERVAL'] = 'Wartezeit zwischen den Werbungen in Minuten.'

		L['BROADCASTING'] = 'Datenübertragungen'

		L['LABEL_BROADCAST_INTERVAL'] = 'Übertragungsintervall'
		L['DESC_BROADCAST_INTERVAL'] = 'Wartezeit zwischen den Übertragungen in Minuten.'

		L['LABEL_SEND_BROADCAST'] = 'Sende Übertragung'
		L['DESC_SEND_BROADCAST'] = 'Sendet deine Berufe an alle.'
		L['CONFIRM_SEND_BROADCAST'] = 'Sendet deine Berufe an alle Charakter. Jepp, alle alle. Bist du dir sicher?'

		L['LABEL_RECEIVE_BROADCASTS'] = 'Datenübertragungen akzeptieren'
		L['DESC_RECEIVE_BROADCASTS'] = 'Datenübertragungen von anderen akzeptieren.'
		L['CONFIRM_RECEIVE_BROADCASTS'] = 'Du hast keine Möglichkeit zu beeinflussen, wer dir Daten sendet. Willst du das wirklich?'

		L['LABEL_SEND_FORWARDS'] = 'Datenübertragungen weiterleiten'
		L['DESC_SEND_FORWARDS'] = 'Weiterleiten von Datenübertragungen an andere Charakter.'
		L['CONFIRM_SEND_FORWARDS'] = 'Diese Funktion wird noch getestet. Probleme können auftreten. Möchtest du wirklich die Daten anderer Charakter weiterleiten?'

		L['LABEL_RECEIVE_FORWARDS'] = 'Weiterleitungen annehmen'
		L['DESC_RECEIVE_FORWARDS'] = 'Weitergeleitete Daten werden angenommen.'
		L['CONFIRM_RECEIVE_FORWARDS'] = 'Diese Funktion wird noch getestet. Probleme können auftreten. Möchtest du wirklich weitergeleitete Daten annehmen?'

		---------- OPTIONS END ----------

	L['BARE_LONG_TAG'] = 'GuildTradeskills'
	L['LONG_TAG'] = LONG_TAG

	L['WELCOME'] = 'Willkommen bei ' .. LONG_TAG .. '! Um anzufangen und die Hilfe zu öffnen gib bitte \'/gt help\' ein.'

	L['SEARCH_SKILLS'] = 'Suche nach Skills:'
    L['SEARCH_REAGENTS'] = 'Suche nach Reagenzien:'
    L['SEARCH_CHARACTERS'] = 'Suche nach Charakter:'
    L['LABEL_PROFESSIONS'] = 'Berufe'
    L['LABEL_SKILLS'] = 'Skills'
    L['LABEL_REAGENTS'] = 'Reagenzien'
    L['LABEL_CHARACTERS'] = 'Charakter'

    L['BUTTON_FILTERS_RESET'] = 'Filter zurücksetzen'
    
    L['ONLINE'] = ONLINE
    L['OFFLINE'] = OFFLINE
	L['BROADCASTED_TAG'] = '|cff7f7f7f{{guild_member}}|r'
	L['OFFLINE_TAG'] = '|c{{class_color}}{{guild_member}}|r - |cff7f7f7f' .. OFFLINE ..'|r'
	L['ONLINE_TAG'] = '|c{{class_color}}{{guild_member}}|r - |cff00ff00' .. ONLINE .. '|r'

	L['CHAT_FRAME_NIL'] = 'Du hast kein Chatfenster angegeben. Du kannst ein Chatfenster mit ' .. YELLOW .. '\'/gt chatwindow {window_name}\'' .. COLOR_END ..' angeben.'
	L['CHAT_WINDOW_SUCCESS'] = 'Ausgabe auf das Chatfenster \'{{frame_name}}\' gesetzt.'
	L['CHAT_WINDOW_INVALID'] = 'Sorry! Wir konnten kein Chatfenster mit dem Namen \'{{frame_name}}\' finden.'

	L['UPDATE_AVAILABLE'] = LONG_TAG .. ' ist veraltet. Deine Version ist {{local_version}} und Verfügbar ist die Version {{remote_version}}.'

	L['CORRUPTED_DATABASE'] = 'Leider sind deine Daten nicht mehr lesbar. Bitte setze alles mit \'/gt reset\' zurück.'

	L['NO_SKILL_SELECTED'] = 'Sie müssen eine Fertigkeit auswählen, bevor Sie einen Charakter flüstern.'
	L['SEND_WHISPER'] = WHISPER_TAG .. 'Hey {{character_name}}! Kannst du {{skill_link}} mich herstellen?'

	---------- GUI END ----------
	---------- ADVERTISE START ----------

	L['ADVERTISE_ON'] = 'Starte Werbung!'
	L['ADVERTISE_OFF'] = 'Stoppe Werbung.'

	L['ADVERTISING_INVALID_INTERVAL'] = '\'{{interval}}\' ist keine gültige Zeitangabe. Zeitangabe in Sekunden.'
	L['ADVERTISE_MINIMUM_INTERVAL'] = '{{interval}} Sekunden ist zu kurz. Der Intervall muss mindestens {{minimum_interval}} Sekunden betragen.'
	L['ADVERTISE_SET_INTERVAL'] = 'Setze das Werbungsintervall auf {{interval}} Sekunden.'
	L['ADVERTISE_NO_PROFESSIONS'] = 'Uh oh! Du hast noch gar keine Berufe hinzugefügt, die man bewerben kann. Du kannst Berufe mit \'/gt addprofession\' hinzufügen.' 

	L['ADVERTISE_FIRST_PROFESSION'] = '{{skill_count}} {{profession_name}}'
	L['ADVERTISE_SECOND_PROFESSION'] = ' und {{skill_count}} {{profession_name}}'
	L['ADVERTISE_FIRST_WHISPER'] = '\'' .. TRIGGER_CHAR .. '{{profession_name}}\' oder \'' .. TRIGGER_CHAR .. '{{profession_name}} {search}\''
	L['ADVERTISE_SECOND_WHISPER'] = ' oder \'' .. TRIGGER_CHAR .. '{{profession_name}}\' oder \'' .. TRIGGER_CHAR .. '{{profession_name}} {search}\'' 
	L['ADVERTISE_ADVERTISEMENT'] = WHISPER_TAG .. 'Ich biete meine Handwerkskünste an! Ich habe Kenntnisse in {{first_profession}}{{second_profession}}. Flüstere mich an mit {{first_whisper}}{{second_whisper}}.'

	---------- ADVERTISE END ----------
	---------- BROADCAST START ----------

	L['SEND'] = 'send'
	L['RECEIVE'] = 'receive'
	L['SEND_FORWARDS'] = 'sendforwards'
	L['RECEIVE_FORWARDS'] = 'receiveforwards'

	L['BROADCAST_UNKNOWN'] = 'Sorry! Wir kennen den Datenübertragungstyp \'{{broadcast_type}}\' nicht.'

	L['BROADCAST_SEND_ON'] = 'Du übertragst jetzt Daten an alle.'
	L['BROADCAST_SEND_OFF'] = 'Datenübertragung eingestellt.'

	L['BROADCAST_RECEIVE_ON'] = 'Du empfängst jetzt Datenübertragung von anderen Charaktern.'
	L['BROADCAST_RECEIVE_OFF'] = 'Datenübertragungen werden nicht mehr empfangen.'

	L['BROADCAST_SEND_FORWARD_ON'] = 'Du leitest jetzt Datenübertragungen anderer Charakter weiter.'
	L['BROADCAST_SEND_FORWARD_OFF'] = 'Weiterleitung eingestellt.'

	L['BROADCAST_FORWARDING_ON'] = 'Du erhälst jetzt weitergeleitete Daten und leitest diese auch selber weiter.'
	L['BROADCAST_FORWARDING_OFF'] = 'Weitergeleitete Daten werden nicht länger empfangen und weitergeleitet.'

	L['BROADCAST_FORWARD_UNKNOWN'] = 'Sorry! Wir kennen den Weiterleitungtyp \'{{broadcast_type}}\' nicht.'

	L['BROADCAST_ALL_ON'] = 'Du sendest und emfpängst jetzt alle Arten von Datenübertragungen.'
	L['BROADCAST_ALL_OFF'] = 'Alle Arten von Datenübertragungen eingestellt.'

	---------- BROADCAST END ----------
	---------- NON-GUILD REQUEST START ----------

	L['REQUEST_ADDON_NOT_INSTALLED'] = 'Der Charakter {{character_name}} hat ' .. LONG_TAG .. ' nicht installiert.'

	L['REQUEST_CHARACTER_NIL'] = CHARACTER_NIL .. YELLOW .. '/gt add {character_name}' .. COLOR_END .. '\'.'
	L['REQUEST_NOT_SELF'] = 'Du kannst dich nicht selbst hinzufügen.'
	L['REQUEST_NOT_GUILD'] = '{{character_name}} ist in deiner Gilde und kann daher dediziert hinzugefügt werden.'
	L['REQUEST_REPEAT'] = 'Du hast bereits eine Anfrage an den Charakter {{character_name}} gesendet. Eine weitere Anfrage ist nicht möglich.'
	L['REQUEST_EXISTS'] = 'Der Charakter {{character_name}} wurde bereits hinzugefügt.'
	L['REQUEST_INCOMING'] = 'Der Charakter {{character_name}} möchte dich hinzufügen ' .. LONG_TAG .. '. Gib \'' .. YELLOW .. '/gt help' .. COLOR_END .. '\' ein um deine möglichen Handlungsoptionen anzuzeigen.'

	L['CONFIRM_CHARACTER_NIL'] = CHARACTER_NIL .. YELLOW .. '/gt add {character_name}' .. COLOR_END .. '\'.'
	L['CONFIRM_NOT_SELF'] = 'Du kannst dich nicht selbst bestätigen.'
	L['CONFIRM_NOT_GUILD'] = '{{character_name}} ist in deiner Gilder und kann daher nicht bestätigt werden.'
	L['CONFIRM_REPEAT'] = 'Du hast bereits eine Bestätigung an den Charakter {{character_name}} gesendet. Das geht kein weiteres mal.'
	L['CONFIRM_EXISTS'] = 'Du hast den Charakter {{character_name}} bereits hinzugefügt. Dieser kann nicht nochmal hinzugefügt werden.'
	L['CONFIRM_INCOMING'] = 'Der Charakter {{character_name}} hat deine Anfrage angenommen! Datenaustausch beginnt in kürze.'
	L['CONFIRM_NIL'] = 'Keine ausstehenden Anfragen von {{character_name}}.'

	L['REJECT_CHARACTER_NIL'] = CHARACTER_NIL .. YELLOW .. '/gt reject {character_name}' .. COLOR_END .. '\'.'
	L['REJECT_NOT_SELF'] = 'Du kannst dich nicht selbst ablehnen.'
	L['REJECT_NOT_GUILD'] = 'Sorry! {{character_name}} ist in deiner Gilde und kann daher nicht abgelehnt werden.'
	L['REJECT_ALREADY_IGNORED'] = 'Du ignorierst den Charakter {{character_name}} bereits. Du kannst ihn nicht ablehnen.'
	L['REJECT_REPEAT'] = 'Du hast den Charakter {{character_name}} bereits abgelehnt. Du kannst ihn derzeit nicht noch einmal ablehnen.'
	L['REJECT_NIL'] = '{{character_name}} hat dir noch keine Absage gesendet.'

	L['IGNORE_CHARACTER_NIL'] = CHARACTER_NIL .. YELLOW .. '/gt ignore {character_name}' .. COLOR_END .. '\'.'
	L['IGNORE_NOT_SELF'] = 'Du kannst dich nicht selbst ignorieren.'
	L['IGNORE_NOT_GUILD'] = '{{character_name}} ist in deiner Gilde und kann daher nicht ignoriert werden.'
	L['IGNORE_REPEAT'] = 'Du ignorierst bereits den Charakter {{character_name}}. Du kannst ihn kein weiteres mal ignorieren.'
	L['IGNORE_INCOMING'] = 'Du wirst von {{character_name}} ignoriert. Bis auf weiteres kannst du dem Charakter keine weiteren Anfragen mehr senden.'
	L['IGNORE_OUTGOING'] = '{{character_name}} wird jetzt von dir ignoriert. Du wirst keine weiteren Anfragen mehr von diesem Account empfangen'
	L['IGNORE_REMOVE'] = '{{character_name}} wird nicht mehr ignoriert. Du kannst jetzt wieder Anfragen von diesem Account empfangen.'
	L['IGNORE_ALREADY_IGNORED'] = 'Du ignorierst {{character_name}} bereits. Du kannst ihn nicht nochmal ignorieren.'

	L['CHARACTER_NOT_FOUND'] = 'Whoops! Der Charakter \'{{character_name}}\' existiert nicht.'

	L['INCOMING_REQUEST'] = '{{character_name}} möchte dich hinzufügen ' .. LONG_TAG .. '. Gib \'' .. YELLOW .. '/gt help' .. COLOR_END .. '\' ein um deine Handlungsoptionen anzusehen.'
	L['INCOMING_CONFIRM'] = '{{character_name}} hat deine Anfrage akzeptiert. Die Daten werden in kürze ausgetauscht.'
	L['INCOMING_REJECT'] = '{{character_name}} hat deine Anfrage abgelehnt.'
	L['INCOMING_IGNORE'] = 'Du wirst von {{character_name}} ignoriert. Du kannst keine weiteren Anfragen senden.'

	L['INCOMING_REQUEST_TIMEOUT'] = 'Die Anfrage von {{character_name}} ist abgelaufen. Du kannst selbst eine Anfrage mit \'' .. YELLOW .. '/gt add {character_name}' .. COLOR_END .. '\' senden.'

	L['OUTGOING_REQUEST_ONLINE'] = 'Anfrage an {{character_name}} gesendet. Sobald deine Anfrage akzeptiert wurde, wird der Charakter zu deiner Liste hinzugefügt.'
	L['OUTGOING_CONFIRM_ONLINE'] = 'Anfrage von {{character_name}} angenommen! Die Daten werden in kürze ausgetauscht.'
	L['OUTGOING_REJECT_ONLINE'] = '{{character_name}} wird über deine Ablehnung informiert.'
	L['OUTGOING_IGNORE_ONLINE'] = '{{character_name}} wird informiert, dass du ihn ignorierst.'

	L['OUTGOING_REQUEST_TIMEOUT'] = 'Deine Anfrage an {{character_name}} ist abgelaufen und wird verworfen. Du kannst eine neue Anfrage mit \'' .. YELLOW .. '/gt add {character_name}' .. COLOR_END .. '\' senden.'
	L['OUTGOING_CONFIRM_TIMEOUT'] = 'Deine Bestätigung von {{character_name}} ist abgelaufen. Du kannst eine neue Bestätigung mit \'' .. YELLOW .. '/gt add {character_name}' .. COLOR_END .. '\' senden.'
	L['OUTGOING_REJECT_TIMEOUT'] = 'Deine Ablehnung von {{character_name}} ist abgelaufen. Du kannst erneut mit \'' .. YELLOW .. '/gt reject {character_name}' .. COLOR_END .. '\' ablehnen.'
	L['OUTGOING_IGNORE_TIMEOUT'] = '{{character_name}} konnte nicht informiert werden das er ignoriert wird. Dennoch wird der Charakter dir keine Anfragen senden können.'

	L['OUTGOING_REQUEST_OFFLINE'] = '{{character_name}} ist offline. Die Anfrage wird übertragen sobald ihr zur selben Zeit online seid.'
	L['OUTGOING_CONFIRM_OFFLINE'] = '{{character_name}} ist offline. Die Bestätigung wird übertragen sobald ihr zur selben Zeit online seid.'
	L['OUTGOING_REJECT_OFFLINE'] = '{{character_name}} is offline. Sobald ihr zur selben Zeit online seid, wird der Charakter informiert das du seine Anfrage abgelehnt hast.'
	L['OUTGOING_IGNORE_OFFLINE'] = '{{character_name}} is offline. Sobald ihr zur selben Zeit online seid, wird der Charakter informiert das du ihn ignorierst.'

	---------- NON-GUILD REQUEST END ----------
	---------- MISC START ----------

	L['PRINT_DELIMITER'] = ', '
	L['ADDED_BY'] = 'Hinzugefügt von'
	L['X'] = 'x'

	L['REMOVE_GUILD'] = 'Dieser Charakter ist nicht mehr teil deiner Gilde und wird entfernt: {{character_names}}'
	L['REMOVE_GUILD_INACTIVE'] = 'Die Gildenmember sind seit {{timeout_days}} Tagen inaktiv und werden daher entfernt: {{character_names}}'

	L['REMOVE_WHISPER_INACTIVE'] = 'Diese von dir hinzugefügten Charakter sind seit {{timeout_days}} Tagen inaktiv und werden daher entfernt: {{character_names}}'

	---------- MISC END ----------
end
