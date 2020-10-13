local AddOnName, GT = ...

local GREEN = '|cff3ce13f'
local YELLOW = '|cffe0ca0a'
local COLOR_END = '|r'

local L = LibStub('AceLocale-3.0'):NewLocale("GuildTradeskills", 'ruRU')

local LONG_TAG = GREEN .. 'Guild' .. COLOR_END .. YELLOW .. 'Tradeskills' .. COLOR_END
local WHISPER_TAG = 'GT: '
local TRIGGER_CHAR = '?'

local ONLINE = 'В сети'
local OFFLINE = 'Не в сети'

local CHARACTER_NIL = 'You must pass a character name. \''

local ALCHEMY = 'Алхимия'
local BLACKSMITHING = 'Кузнечное дело'
local ENCHANTING = 'Наложение чар'
local ENGINEERING = 'Инженерное дело'
local LEATHERWORKING = 'Кожевничество'
local TAILORING = 'Портняжное дело'
local COOKING = 'Кулинария'

if L then
	---------- CLASSES START ----------

	-- The KEY should be the localized value here.
	-- It should be in all caps.
	-- We use it for getting class colors.
	L['ДРУИД'] = 'DRUID'
	L['ОХОТНИК'] = 'HUNTER'
	L['МАГ'] = 'MAGE'
	L['ПАЛАДИН'] = 'PALADIN'
	L['ЖРЕЦ'] = 'PRIEST'
	L['РАЗБОЙНИК'] = 'ROGUE'
	L['ШАМАН'] = 'SHAMAN'
	L['ЧЕРНОКНИЖНИК'] = 'WARLOCK'
	L['ВОИН'] = 'WARRIOR'

	---------- CHARACTER START ----------

	L['CHARACTER'] = 'персонаж'

	L['CHARACTER_RESET_NOT_FOUND'] = 'Невозможно найти персонажа \'{{character_name}}\'.'
	L['CHARACTER_RESET_FINAL'] = 'Успешный сброс персонажа \'{{character_name}}\'.'

	---------- CHARACTER END ----------
	---------- COMMAND START ----------

	L['UNKNOWN_COMMAND'] = 'Неизвестная команда \'{{command}}\'. Введите \'' .. YELLOW .. '/gt help' .. COLOR_END .. '\' для получения списка возможных команд.'
	--[===[@debug@
	L['FORCE'] = 'force'
	--@end-debug@]===]

	L['SLASH_COMMANDS'] = {
		gt = {
			order = 0,
			methodName = 'OnCommand',
			help = YELLOW .. '/gt' .. COLOR_END .. ': Открывает панель поиска.',
			subCommands = {
				help = {
					order = 0,
					methodName = 'Help',
					help = YELLOW .. '/gt help' .. COLOR_END .. ': Напишет это сообщение.'
				},
				opt = {
					order = 1,
					methodName = 'Options',
					help = YELLOW .. '/gt opt' .. COLOR_END .. ': Открывает панель настроек.'
				},
				addprofession = {
					order = 2,
					methodName = 'InitAddProfession',
					help = YELLOW .. '/gt addprofession' .. COLOR_END .. ': Включает режим добавления профессии. После этого нажмите на профессию, что вы хотите добавить.'
				},
				removeprofession = {
					order = 3,
					methodName = 'RemoveProfession',
					help = YELLOW .. '/gt removeprofession {Имя_профессии}' .. COLOR_END .. ': Убирает профессию.'
				},
				--[[
				advertise = {
					order = 4,
					methodName = 'ToggleAdvertising',
					help = YELLOW .. '/gt advertise' .. COLOR_END .. ': Включает/выключает режим рекламы.',
					subCommands = {
						seconds = {
							parens = true,
							methodName = 'ToggleAdvertising',
							help =  YELLOW .. '/gt advertise {секунды}' .. COLOR_END .. ': Устанавливает количество секунд между рекламными сообщениями.'
						}
					}
				},
				--]]
				add = {
					order = 5,
					methodName = 'SendRequest',
					help = YELLOW .. '/gt add {Имя_персонажа}' .. COLOR_END .. ': Запрос на добавление конкретного персонажа.'
				},
				reject = {
					order = 6,
					methodName = 'SendReject',
					help = YELLOW .. '/gt reject {Имя_персонажа}' .. COLOR_END .. ': Отказ на добавление вашего персонажа. Они могут попытаться снова.'
				},
				ignore = {
					order = 7,
					methodName = 'SendIgnore',
					help = YELLOW .. '/gt ignore {Имя_персонажа}' .. COLOR_END .. ': Игнорирует персонажа. Запросы от этого персонажа будут игнорироваться.'
				},
				requests = {
					order = 8,
					methodName = 'ShowRequests',
					help = YELLOW .. '/gt requests' .. COLOR_END .. ': Список персонажей, что захотели Вас добавить.'
				},
				broadcast = {
					order = 9,
					methodName = 'ToggleBroadcast',
					help = YELLOW .. '/gt broadcast' .. COLOR_END .. ': Включает/выключает все возможные передачи данных.',
					subCommands = {
						send = {
							order = 0,
							methodName = 'ToggleBroadcast',
							help = YELLOW .. '/gt broadcast send' .. COLOR_END .. ': Включает/выключает передачу данных от Вас всем остальным' .. YELLOW .. 'Да, всем всем.' .. COLOR_END
						},
						receive = {
							order = 1,
							methodName = 'ToggleBroadcast',
							help = YELLOW .. '/gt broadcast receive' .. COLOR_END .. ': Включает/выключает передачу данных вам ото всех остальных' .. YELLOW .. 'Да да, ото всех.' .. COLOR_END
						},
						sendforwards = {
							order = 2,
							methodName = 'ToggleForwards',
							help = YELLOW .. '/gt broadcast sendforwards' .. COLOR_END .. ': Включает/выключает возможность передачи чужих данных другим игрокам от Вас. То есть делает вас посредником в передаче данных.' .. YELLOW .. 'Использовать с умом. Может снизить производительность игры.' .. COLOR_END
						},
						receiveforwards = {
							order = 3,
							methodName = 'ToggleForwards',
							help = YELLOW .. '/gt broadcast receiveforwards' .. COLOR_END .. ': Включает/выключает возможность передачи данных от посредников Вам. ' .. YELLOW .. 'спользовать с умом. Может снизить производительность игры.' .. COLOR_END
						}

					}
				},
				window = {
					order = 10,
					methodName = 'SetChatFrame',
					help = YELLOW .. '/gt window {имя_окна}' .. COLOR_END .. ': Устанавливаев вывод в определенное окно чата.'
				},
				reset = {
					order = 11,
					methodName = 'Reset',
					help = YELLOW .. '/gt reset' .. COLOR_END .. ': Сброс всех данных. |cffff0000Не может быть отменено.|r'
				}
			}
		}
	}

	L['RESET_WARN'] = 'Вы уверены? Это сбросит все настройки аддона. Введите \'/gt reset confirm\' для подтверждения или \'/gt reset cancel\' для отмены.'
	L['RESET_EXPECT_COMFIRM'] = 'подтвердить'
	L['RESET_EXPECT_CANCEL'] = 'отмена'
	L['RESET_NO_CONFIRM'] = 'Пожалуйста, введите либо \'/gt reset confirm\' для подтверждения либо \'/gt reset cancel\' для отмены.'
	L['RESET_CANCEL'] = 'Сброс отменен.'
	L['RESET_CHARACTER'] = 'Сброс персонажа \'{{character_name}}\'. Мы вас предупреждали.'
	L['RESET_PROFESSION'] = 'Сброс профессии \'{{profession_name}}\'. Мы вас предупреждали.'
	L['RESET_FINAL'] = 'Сбросс всего аддона. Мы вас предупреждали.'
	L['RESET_UNKNOWN'] = 'Что \'{{token}}\' должно означать?.'

	---------- COMMAND END ----------
	---------- WHISPER START ----------

	L['TRIGGER_CHAR'] = TRIGGER_CHAR

	L['QUERY_TOOLTIP'] = 'ПКМ для того, чтобы спросить про: {{skill}}'

	L['WHISPER_TAG'] = WHISPER_TAG
	L['WHISPER_FIRST_PROFESSION'] = '{{profession_name}}'
	L['WHISPER_SECOND_PROFESSION'] = ' и {{profession_name}}'
	L['WHISPER_PROFESSION_NOT_FOUND'] = WHISPER_TAG .. 'Упс! Похоже у меня нет \'{{profession_search}}\'. Доступные профессии: {{first_profession}}{{second_profession}}.'
	L['WHISPER_NIL_PROFESSIONS'] = WHISPER_TAG .. 'Похоже, я еще не добавил никаких профессий. Спросите попозже!'

	L['WHISPER_INVALID_PAGE'] = WHISPER_TAG .. 'Ой! Страница {{page}} неверна. У меня только {{max_pages}} страниц.'
	L['WHISPER_HEADER'] = WHISPER_TAG .. 'Страница {{current_page}} из {{total_pages}}. У меня всего {{total_skills}} рецептов.'
	L['WHISPER_ITEM'] = WHISPER_TAG .. '{{number}}. {{skill_link}}'
	L['WHISPER_FOOTER'] = WHISPER_TAG .. 'Вы можете перейти на следующую страницу ответив \'' .. TRIGGER_CHAR .. '{{profession_name}} {{next_page}}\' или перейти на конкретную страницу, написав \'' .. TRIGGER_CHAR .. '{{profession_name}} {page_number}\'.'
	L['WHISPER_FOOTER_LAST_PAGE'] = WHISPER_TAG .. 'Вы можете перейти на конкретную страницу, написав \'' .. TRIGGER_CHAR .. '{{profession_name}} {page_number}\'.'

    L['WHISPER_REQUEST'] = WHISPER_TAG .. 'Эй, {{character_name}}! Сможешь скрафтить {{item_link}} для меня?'
    L['WHISPER_SELECT_REQUIRED'] = 'Не найдено выбранного рецепта. Вы должны сначала выбрать рецепт.'
    L['WHISPER_NO_CHARACTER_FOUND'] = 'Не похоже, что \'{{character_name}}\' в сети.'

    L['WHISPER_INCOMING_REQUESTS'] = 'У вас есть запросы от: {{character_names}}'
    L['WHISPER_NO_INCOMING_REQUESTS'] = 'У вас нет запросов.'

	---------- WHISPER END ----------
	---------- LOG START ----------

	L['LOG_TAG'] = GREEN .. 'G' .. COLOR_END .. YELLOW .. 'T' .. COLOR_END .. ': '

	L['DUMP_PROFESSION_NIL'] = 'Вы должны передать название профессии: /gt dumpprofession {profession_name}'
	L['DUMP_PROFESSION_NOT_FOUND'] = 'Ой! Не нашел профессии: {{profession_name}}'
	L['DUMP_PROFESSION'] = 'Демпинг профессия: {{profession_name}}'

	L['DUMP_CHARACTER_NIL'] = 'Вы должны передать имя персонажа: /gt dumpcharacter {character_name}'
	L['DUMP_CHARACTER_NOT_FOUND'] = 'Ой! Не удалось найти персонажа: {{character_name}}'
	L['DUMP_CHARACTER'] = 'Демпинг-персонаж: {{character_name}}'

	---------- LOG END ----------
	---------- PROFESSION START ----------

	L['PROFESSION'] = 'профессия'

	L['PROFESSIONS_LIST'] = {
		ALCHEMY = ALCHEMY,
		BLACKSMITHING = BLACKSMITHING,
		ENCHANTING = ENCHANTING,
		ENGINEERING = ENGINEERING,
		LEATHERWORKING = LEATHERWORKING,
		TAILORING = TAILORING,
		COOKING = COOKING
	}

	L['PROFESSION_ADD_INIT'] = 'Пожалуйста, откройте профессию, которую вы хотите добавить.'
	L['PROFESSION_ADD_UNSUPPORTED'] = 'Извените! {{profession_name}} еще не поддерживается.'
	L['PROFESSION_ADD_CANCEL'] = 'Отмена добавления профессии.'
	L['PROFESSION_ADD_PROGRESS'] = 'Загрузка данных с сервера. Может занять несколько секунд.'
	L['PROFESSION_ADD_SUCCESS'] = 'Успешно добавлена профессия: {{profession_name}}'
	L['PROFESSION_REMOVE_NIL_PROFESSION'] = 'Видимо, вы не ввели название профессии. Вы можете удалить профессию, введя\'/gt removeprofession {prfession_name}'
	L['PROFESSION_REMOVE_NOT_FOUND'] = 'Не найдена профессия \'{{profession_name}}\' у \'{{character_name}}\'.'
	L['PROFESSION_REMOVE_SUCCESS'] = 'Успешно удалена профессия \'{{profession_name}}\' у \'{{character_name}}\'.'

	L['PROFESSION_RESET_NOT_FOUND'] = 'Не найдена профессия: {{profession_name}}'
	L['PROFESSION_RESET_FINAL'] = 'Успешно сброшена профессия: {{profession_name}}'

	---------- PROFESSION END ----------
	---------- GUI START ----------

		---------- OPTIONS START -----------

		L['LABEL_OPEN_SEARCH'] = 'Открыть поиск'
		L['DESC_OPEN_SEARCH'] = 'Открывает панель поиска.'

		L['LABEL_SHOW_LOGIN_MESSAGE'] = 'Сообщение для входа'
		L['DESC_SHOW_LOGIN_MESSAGE'] = 'Переключает, будет ли напечатано сообщение для входа.'

		L['CANCEL'] = 'Отмена'
		L['OKAY'] = 'Подтвердить'

		L['DESC_PROFESSIONS'] = 'Отслеживаемые профессии на этом персонаже на данный момент.'

		L['PROFESSION_ADD_NAME'] = 'Добавить профессию'
		L['PROFESSION_ADD_DESC'] = 'Добавить профессию этому персонажу.'
		L['PROFESSION_ADD_CANCEL_DESC'] = 'Отмена добавления профессии.'

		L['PROFESSION_DELETE_NAME'] = 'Удалить профессию'
		L['PROFESSION_DELETE_DESC'] = 'Убрать отслеживание профессии на этом персонаже.'
		L['PROFESSION_DELETE_CONFIRM'] = 'Вы уверены, что хотите прекратить отслеживание {{profession_name}}?'

		L['LABEL_ADD_CHARACTER'] = 'Добавить персонажа вне гильдии'
		L['DESC_ADD_CHARACTER'] = 'Добавляет персонажа, не находящегося в вашей гильдии.'

		L['LABEL_NON_GUILD_CHARACTERS'] = 'Персонажи вне гильдии'
		L['DESC_NON_GUILD_CHARACTERS'] = 'Персонажи, что находятся все вашей гильдии.'

		L['LABEL_CHARACTER_REMOVE'] = 'Удалить персонажа'
		L['DESC_CHARACTER_REMOVE'] = 'Прекратить отслеживание персонажа.'
		L['CHARACTER_REMOVE_CONFIRM'] = 'Вы уверены, что хотите удалить {{character_name}}?'

		L['LABEL_REQUESTS_TOGGLE_ALL'] = 'Разрешить ВСЕ'
		L['LABEL_REQUESTS_TOGGLE_CONFIRM'] = 'Требуется подтверждение'
		L['LABEL_REQUESTS_TOGGLE_NONE'] = 'Запретить ВСЕ'
		L['DESC_REQUESTS_TOGGLE'] = 'Устанавливает количество возможных запросов.'

		L['LABEL_REQUESTS'] = 'Запросов'
		L['DESC_REQUESTS'] = 'Эти персонажи хотят добавить Вас.'

		L['LABEL_SEND_CONFIRM'] = 'Подтвердить'
		L['DESC_SEND_CONFIRM'] = 'Принять их запрос.'

		L['LABEL_SEND_REJECT'] = 'Отклонить'
		L['DESC_SEND_REJECT'] = 'Отклонить их запрос.'

		L['LABEL_SEND_IGNORE'] = 'Игнорировать'
		L['DESC_SEND_IGNORE'] = 'Игнорировать запросы от этого персонажа.'
		L['CHARACTER_IGNORE_CONFIRM'] = 'Вы уверены, что хотите игнорировать {{character_name}}?'

		L['LABEL_ADVERTISING'] = 'Реклама'
		L['DESC_ADVERTISE_TOGGLE'] = 'Включает авто-рекламу.'

		L['LABEL_ADVERTISING_INTERVAL'] = 'Промежуток между рекламными сообщениями'
		L['DESC_ADVERTISING_INTERVAL'] = 'Устанавливает промежуток между сообщениями (в минутах).'

		L['BROADCASTING'] = 'Передача данных'

		L['LABEL_BROADCAST_INTERVAL'] = 'Интервал передачи'
		L['DESC_BROADCAST_INTERVAL'] = 'Время между передачами (в минутах).'

		L['LABEL_SEND_BROADCAST'] = 'Передавать данные'
		L['DESC_SEND_BROADCAST'] = 'Передавать данные по вашим профессиям.'
		L['CONFIRM_SEND_BROADCAST'] = 'Вы будете передавать данные по вашим профессиям всем персонажам в гильдии и добавленным персонажам вне гильдии. Вы уверены?'

		L['LABEL_RECEIVE_BROADCASTS'] = 'Принимать данные'
		L['DESC_RECEIVE_BROADCASTS'] = 'Принимать передачу данных.'
		L['CONFIRM_RECEIVE_BROADCASTS'] = 'Кто угодно сможет прислать данные по своим профессиям. Вы уверены?'

		L['LABEL_SEND_FORWARDS'] = 'Перенаправлять данные'
		L['DESC_SEND_FORWARDS'] = 'Передавать данные о профессиях других персонажей.'
		L['CONFIRM_SEND_FORWARDS'] = 'БЕТА. Будет передавать данные о профессиях других персонажей. Вы уверены?'

		L['LABEL_RECEIVE_FORWARDS'] = 'Принимать перенаправленные данные'
		L['DESC_RECEIVE_FORWARDS'] = 'Принимать перенаправленные данные.'
		L['CONFIRM_RECEIVE_FORWARDS'] = 'БЕТА. Позволяет принимать перенаправленные данные. Вы уверены?'

		---------- OPTIONS END ----------

	L['BARE_LONG_TAG'] = 'GuildTradeskills'
	L['LONG_TAG'] = LONG_TAG

	L['WELCOME'] = 'Приветствуем в ' .. LONG_TAG .. '! Для получения помощи вы можете ввести \'/gt help\'.'

	L['SEARCH_SKILLS'] = 'Поиск навыков:'
    L['SEARCH_REAGENTS'] = 'Поиск реагентов:'
    L['SEARCH_CHARACTERS'] = 'Поиск персонажей:'
    L['LABEL_PROFESSIONS'] = 'Профессии'
    L['LABEL_SKILLS'] = 'Навыки'
    L['LABEL_REAGENTS'] = 'Реагенты'
    L['LABEL_CHARACTERS'] = 'Персонажи'

    L['BUTTON_FILTERS_RESET'] = 'Очистить фильтры'
    
    L['ONLINE'] = ONLINE
    L['OFFLINE'] = OFFLINE
	L['BROADCASTED_TAG'] = '|cff7f7f7f{{guild_member}}|r'
	L['OFFLINE_TAG'] = '|c{{class_color}}{{guild_member}}|r - |cff7f7f7f' .. OFFLINE ..'|r'
	L['ONLINE_TAG'] = '|c{{class_color}}{{guild_member}}|r - |cff00ff00' .. ONLINE .. '|r'

	L['CHAT_FRAME_NIL'] = 'По всей видимости, вы не ввели имя окна чата. Вы можете его ввести с помощью команды: ' .. YELLOW .. '\'/gt chatwindow {window_name}\'' .. COLOR_END ..'.'
	L['CHAT_WINDOW_SUCCESS'] = 'Устанавливает вывод сообщений на \'{{frame_name}}\'.'
	L['CHAT_WINDOW_INVALID'] = 'Окно чата с названием \'{{frame_name}}\' не найдено.'

	L['UPDATE_AVAILABLE'] = LONG_TAG .. ' устарел. Ваша версия {{local_version}} и {{remote_version}} доступна. Но не факт, что она будет работать.'

	L['CORRUPTED_DATABASE'] = 'К несчастью, ваша база данных была повреждена. Вам необходимо ее сбросить с помощью команды \'/gt reset\'.'

	L['NO_SKILL_SELECTED'] = 'Вы должны выбрать рецепт, перед тем, как писать сообщение персонажу.'
	L['SEND_WHISPER'] = WHISPER_TAG .. 'Эй, {{character_name}}! Сможешь сделать {{skill_link}} для меня?'

	---------- GUI END ----------
	---------- ADVERTISE START ----------

	L['ADVERTISE_ON'] = 'Реклама начата!'
	L['ADVERTISE_OFF'] = 'Реклама закончена.'

	L['ADVERTISING_INVALID_INTERVAL'] = '\'{{interval}}\' Неверный интервал. Он должен быть в секундах.'
	L['ADVERTISE_MINIMUM_INTERVAL'] = '{{interval}} секунд - слишком малый интервал. Установлено на {{minimum_interval}} секунд.'
	L['ADVERTISE_SET_INTERVAL'] = 'Установить интервал в {{interval}} секунд.'
	L['ADVERTISE_NO_PROFESSIONS'] = 'Похоже, вы еще не добавили ни одной професии для рекламы. Вы можете добавить профессию с помощью команды: \'/gt addprofession\'.' 

	L['ADVERTISE_FIRST_PROFESSION'] = '{{skill_count}} {{profession_name}}'
	L['ADVERTISE_SECOND_PROFESSION'] = ' и {{skill_count}} {{profession_name}}'
	L['ADVERTISE_FIRST_WHISPER'] = '\'' .. TRIGGER_CHAR .. '{{profession_name}}\' или \'' .. TRIGGER_CHAR .. '{{profession_name}} {search}\''
	L['ADVERTISE_SECOND_WHISPER'] = ' or \'' .. TRIGGER_CHAR .. '{{profession_name}}\' или \'' .. TRIGGER_CHAR .. '{{profession_name}} {search}\'' 
	L['ADVERTISE_ADVERTISEMENT'] = WHISPER_TAG .. 'Предоставляю Вам свои услуги с {{first_profession}}{{second_profession}}. /w {{first_whisper}}{{second_whisper}}.'

	---------- ADVERTISE END ----------
	---------- BROADCAST START ----------

	L['SEND'] = 'отправить'
	L['RECEIVE'] = 'получить'
	L['SEND_FORWARDS'] = 'перенаправить'
	L['RECEIVE_FORWARDS'] = 'получить перенаправленное'

	L['BROADCAST_UNKNOWN'] = 'Неизвестный тип передачи данных \'{{broadcast_type}}\'.'

	L['BROADCAST_SEND_ON'] = 'Включена передача данных.'
	L['BROADCAST_SEND_OFF'] = 'Выключена передача данных.'

	L['BROADCAST_RECEIVE_ON'] = 'Включен прием данных.'
	L['BROADCAST_RECEIVE_OFF'] = 'Выключен прием данных.'

	L['BROADCAST_SEND_FORWARD_ON'] = 'Включено перенаправление данных.'
	L['BROADCAST_SEND_FORWARD_OFF'] = 'Выключено перенаправление данных.'

	L['BROADCAST_FORWARDING_ON'] = 'Теперь вы получаете и отправляете все перенаправленные данные.'
	L['BROADCAST_FORWARDING_OFF'] = 'Вы перестали получать и отправлять все перенаправленные данные.'

	L['BROADCAST_FORWARD_UNKNOWN'] = 'Неизвестный тип передачи данных \'{{broadcast_type}}\'.'

	L['BROADCAST_ALL_ON'] = 'Вы включили все возможные передачи данных.'
	L['BROADCAST_ALL_OFF'] = 'Вы выключили все возможные передачи данных.'

	---------- BROADCAST END ----------
	---------- NON-GUILD REQUEST START ----------

	L['REQUEST_ADDON_NOT_INSTALLED'] = 'Непохоже, что {{character_name}} имеет установленный ' .. LONG_TAG .. '.'

	L['REQUEST_CHARACTER_NIL'] = CHARACTER_NIL .. YELLOW .. '/gt add {character_name}' .. COLOR_END .. '\'.'
	L['REQUEST_NOT_SELF'] = 'Вы не можете добавить себя.'
	L['REQUEST_NOT_GUILD'] = 'Вы состоите в одной гильдии с {{character_name}}, потому не можете его добавить.'
	L['REQUEST_REPEAT'] = 'Вы уже отправили запрос {{character_name}}.'
	L['REQUEST_EXISTS'] = 'Вы уже добавили {{character_name}}. Вы не можете снова его добавить.'
	L['REQUEST_INCOMING'] = '{{character_name}} хочет добавить вас в ' .. LONG_TAG .. '. Напишите \'' .. YELLOW .. '/gt help' .. COLOR_END .. '\' , если необходима помощь.'

	L['CONFIRM_CHARACTER_NIL'] = CHARACTER_NIL .. YELLOW .. '/gt add {character_name}' .. COLOR_END .. '\'.'
	L['CONFIRM_NOT_SELF'] = 'Вы не можете подтвердить запрос на себя самого.'
	L['CONFIRM_NOT_GUILD'] = 'Вы состоите в одной гильдии с {{character_name}} и потому не можете подтвердить его запрос.'
	L['CONFIRM_REPEAT'] = 'Вы уже имете исходящее подтверждение для {{character_name}}. Вы не можете отправить еще одно.'
	L['CONFIRM_EXISTS'] = 'Вы уже добавили {{character_name}}.'
	L['CONFIRM_INCOMING'] = '{{character_name}} согласился на ваш запрос! Вы должны увидеть их рецепты в скором времени.'
	L['CONFIRM_NIL'] = '{{character_name}} не отправлял вам никаких запросов.'

	L['REJECT_CHARACTER_NIL'] = CHARACTER_NIL .. YELLOW .. '/gt reject {character_name}' .. COLOR_END .. '\'.'
	L['REJECT_NOT_SELF'] = 'Вы не можете отказать себе самому.'
	L['REJECT_NOT_GUILD'] = 'Вы не можете отказывать персонажам из одной с вами гильдии.'
	L['REJECT_ALREADY_IGNORED'] = 'Вы уже игнорируете {{character_name}}.'
	L['REJECT_REPEAT'] = 'Вы уже отказали {{character_name}}.'
	L['REJECT_NIL'] = '{{character_name}} не отправлял вам никаких запросов.'

	L['IGNORE_CHARACTER_NIL'] = CHARACTER_NIL .. YELLOW .. '/gt ignore {character_name}' .. COLOR_END .. '\'.'
	L['IGNORE_NOT_SELF'] = 'Вы не можете игнорировать себя самого.'
	L['IGNORE_NOT_GUILD'] = 'Вы не можете игнорировать членов своей гильдии.'
	L['IGNORE_REPEAT'] = 'Вы уже игнорируете {{character_name}}.'
	L['IGNORE_INCOMING'] = 'Вы игнорируетесь {{character_name}}. Вы не можете отправлять им запросы.'
	L['IGNORE_OUTGOING'] = '{{character_name}} теперь игнорируется. Вы больше не получите никаких запросов от этого персонажа.'
	L['IGNORE_REMOVE'] = 'Вы более не игнорируете {{character_name}}. Вы теперь сможете получать запросы от этого персонажа.'
	L['IGNORE_ALREADY_IGNORED'] = 'Вы уже игнорируете {{character_name}}.'

	L['CHARACTER_NOT_FOUND'] = 'Ой! Похоже \'{{character_name}}\' не существует.'

	L['INCOMING_REQUEST'] = '{{character_name}} хочет добавить вас в ' .. LONG_TAG .. '. Напишите \'' .. YELLOW .. '/gt help' .. COLOR_END .. '\' ,если вам необходима помощь.'
	L['INCOMING_CONFIRM'] = 'Персонаж {{character_name}} согласился на ваш запрос! Вы должны будете увидеть их рецепты в скором времени.'
	L['INCOMING_REJECT'] = '{{character_name}} отклонил ваше предложение.'
	L['INCOMING_IGNORE'] = 'Вы игнорируетесь {{character_name}}. Вы не можете отправлять им запросы.'

	L['INCOMING_REQUEST_TIMEOUT'] = 'Истек срок запроса {{character_name}} и был отменен.'

	L['OUTGOING_REQUEST_ONLINE'] = 'Был отправлен запрос {{character_name}}. Если игрок его примет, то его персонаж отобразится у вас в панели поиска.'
	L['OUTGOING_CONFIRM_ONLINE'] = 'Принятый запрос от {{character_name}}! Скоро вы сможете увидеть рецепты этого персонажа.'
	L['OUTGOING_REJECT_ONLINE'] = 'Ваш отказ был отправлен {{character_name}}.'
	L['OUTGOING_IGNORE_ONLINE'] = '{{character_name}} уведомлен, что вы его игнорируете.'

	L['OUTGOING_REQUEST_TIMEOUT'] = 'Истек срок запроса {{character_name}} и был отменен.'
	L['OUTGOING_CONFIRM_TIMEOUT'] = 'Ваше подтверждение {{character_name}} не было получено.'
	L['OUTGOING_REJECT_TIMEOUT'] = 'Ваш отказ {{character_name}} не был получен.'
	L['OUTGOING_IGNORE_TIMEOUT'] = 'Сообщение о том, что вы теперь игнорируете {{character_name}} не было получено реципиентом. Однако, вы все же не будете получать запросы от этого персонажа.'

	L['OUTGOING_REQUEST_OFFLINE'] = '{{character_name}} вне игры. Запрос будет отправлен, когда вы оба будете в игре.'
	L['OUTGOING_CONFIRM_OFFLINE'] = '{{character_name}} вне игры. Запрос на подтерждение будет отправлен, когда вы оба будете в игре.'
	L['OUTGOING_REJECT_OFFLINE'] = '{{character_name}} вне игры. Отказ будет отправлен, когда вы оба будете в игре.'
	L['OUTGOING_IGNORE_OFFLINE'] = '{{character_name}} вне игры. Сообщение об игнорировании будет отправлено, когда вы оба будете в игре.'

	---------- NON-GUILD REQUEST END ----------
	---------- MISC START ----------

	L['PRINT_DELIMITER'] = ', '
	L['ADDED_BY'] = 'Добавлено'
	L['X'] = 'x'

	L['REMOVE_GUILD'] = 'Эти персонажи более не состоят в гильдии и были удалены:: {{character_names}}'
	L['REMOVE_GUILD_INACTIVE'] = 'Эти персонажи были неактивны в течение {{timeout_days}} дней и были удалены: {{character_names}}'

	L['REMOVE_WHISPER_INACTIVE'] = 'Эти персонажи были неактивны в течение {{timeout_days}} дней и были удалены: {{character_names}}'

	---------- MISC END ----------
end
