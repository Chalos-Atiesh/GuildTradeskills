local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local Options = GT:NewModule('Options')
GT.Options = Options

local Config = LibStub('AceConfig-3.0')
Options.Config = Config

local CD = LibStub('AceConfigDialog-3.0')
Options.CD = CD

local CR = LibStub('AceConfigRegistry-3.0')
Options.CR = CR

local ADD_DELAY = 1
local PANEL_NAME = GT.L['LONG_TAG'] .. ' Options'

local options = {
	type = 'group',
	args = {
		openSearchButton = {
			name = GT.L['LABEL_OPEN_SEARCH'],
			desc = GT.L['DESC_OPEN_SEARCH'],
			type = 'execute',
			order = 0,
			func = function()
				InterfaceOptionsFrame_Show()
				ToggleGameMenu()
				CD:Close(PANEL_NAME)
				GT.Search:ToggleFrame()
			end
		},
		professionGroup = {
			name = GT.L['LABEL_PROFESSIONS'],
			type = 'group',
			width = 'full',
			inline = true,
			order = 1,
			args = {
				professionSelect = {
					name = GT.L['LABEL_PROFESSIONS'],
					desc = GT.L['DESC_PROFESSIONS'],
					type = 'select',
					style = 'dropdown',
					order = 0,
					values = function() return Options:GetPlayerProfessions() end,
					set = function(info, value) Options.selectedProfession = value end,
					get = function() return Options:GetSelectedProfession() end
				},
				professionAdd = {
					name = GT.L['PROFESSION_ADD_NAME'],
					desc = GT.L['PROFESSION_ADD_DESC'],
					type = 'execute',
					order = 1,
					func = function() Options:ToggleAddProfession() end
				},
				professionRemove = {
					name = GT.L['PROFESSION_DELETE_NAME'],
					desc = GT.L['PROFESSION_DELETE_DESC'],
					type = 'execute',
					disabled = true,
					order = 2,
					confirm = function(info) return Options:GetConfirmText(info, GT.L['PROFESSION_DELETE_CONFIRM'], Options['GetSelectedProfession']) end,
					func = function() Options:DeleteProfession() end
				}
			}
		},
		nonGuildMembers = {
			name = GT.L['LABEL_NON_GUILD_CHARACTERS'],
			type = 'group',
			width = 'full',
			inline = true,
			order = 2,
			args = {
				characterInput = {
					name = GT.L['LABEL_ADD_CHARACTER'],
					desc = GT.L['DESC_ADD_CHARACTER'],
					type = 'input',
					order = 0,
					set = function(...) Options.AddCharacter(...) end
				},
				characters = {
					name = GT.L['LABEL_NON_GUILD_CHARACTERS'],
					desc = GT.L['DESC_NON_GUILD_CHARACTERS'],
					type = 'select',
					style = 'dropdown',
					order = 1,
					disabled = true,
					values = function() return Options:GetCharacters() end,
					get = function() return Options:GetSelectedCharacter() end,
					set = function(info, value) Options.selectedCharacter = value end,
				},
				characterRemove = {
					name = GT.L['LABEL_CHARACTER_REMOVE'],
					desc = GT.L['DESC_CHARACTER_REMOVE'],
					type = 'execute',
					disabled = true,
					order = 2,
					confirm = function(info) return Options:GetConfirmText(info, GT.L['CHARACTER_REMOVE_CONFIRM'], Options['GetSelectedCharacter']) end,
					func = function() Options:DeleteCharacter() end,
				}
			}
		},
		requestsRow = {
			name = GT.L['LABEL_REQUESTS'],
			type = 'group',
			width = 'full',
			inline = true,
			order = 3,
			args = {
				requestsToggle = {
					name = GT.L['LABEL_REQUESTS_TOGGLE_CONFIRM'],
					desc = GT.L['DESC_REQUESTS_TOGGLE'],
					type = 'toggle',
					tristate = true,
					width = 'full',
					order = 0,
					get = function() return Options:GetRequestFilter() end,
					set = function(info, val) Options:SetRequestFilter(val) end,
				},
				requests = {
					name = GT.L['LABEL_REQUESTS'],
					desc = GT.L['DESC_REQUESTS'],
					type = 'select',
					style = 'dropdown',
					disabled = true,
					width = 0.9,
					order = 1,
					values = function() return Options:GetRequests() end,
					set = function(info, value) Options.selectedRequest = value end,
					get = function() return Options:GetSelectedRequest() end
				},
				sendConfirm = {
					name = GT.L['LABEL_SEND_CONFIRM'],
					desc = GT.L['DESC_SEND_CONFIRM'],
					type = 'execute',
					disabled = true,
					width = 0.9,
					order = 2,
					func = function() Options:SendConfirm() end
				},
				sendReject = {
					name = GT.L['LABEL_SEND_REJECT'],
					desc = GT.L['DESC_SEND_REJECT'],
					type = 'execute',
					disabled = true,
					width = 0.9,
					order = 3,
					func = function() Options:SendReject() end
				},
				sendIgnore = {
					name = GT.L['LABEL_SEND_IGNORE'],
					desc = GT.L['DESC_SEND_IGNORE'],
					type = 'execute',
					disabled = true,
					width = 0.9,
					order = 4,
					confirm = function(info) return Options:GetConfirmText(info, GT.L['CHARACTER_IGNORE_CONFIRM'], Options['GetSelectedRequest']) end,
					func = function() Options:SendIgnore() end
				}
			}
		},
		advertiseRow = {
			name = GT.L['LABEL_ADVERTISING'],
			type = 'group',
			width = 'full',
			inline = true,
			order = 4,
			args = {
				advertiseToggle = {
					name = GT.L['LABEL_ADVERTISING'],
					desc = GT.L['DESC_ADVERTISE_TOGGLE'],
					type = 'toggle',
					order = 0,
					get = function() return Options:GetIsAdvertising() end,
					set = function(info, val) Options:SetIsAdvertising(val) end
				},
				advertiseInterval = {
					name = GT.L['LABEL_ADVERTISING_INTERVAL'],
					desc = GT.L['DESC_ADVERTISING_INTERVAL'],
					type = 'range',
					disabled = true,
					min = GT.Advertise.MINIMUM_INTERVAL / 60,
					max = GT.Advertise.MAXIMUM_INTERVAL / 60,
					step = 0.25,
					get = function() return GT.DBComm:GetAdvertisingInterval() / 60 end,
					set = function(info, val) GT.DBComm:SetAdvertisingInterval(val * 60) end,
				}
			}
		},
		broadcastingRow = {
			name = GT.L['BROADCASTING'],
			type = 'group',
			width = 'full',
			inline = true,
			order = 5,
			args = {
				broadcastInterval = {
					name = GT.L['LABEL_BROADCAST_INTERVAL'],
					desc = GT.L['DESC_BROADCAST_INTERVAL'],
					type = 'range',
					width = 'full',
					disabled = true,
					min = GT.CommYell.MIN_BROADCAST_INTERVAL / 60,
					max = GT.CommYell.MAX_BROADCAST_INTERVAL / 60,
					step = 0.25,
					order = 1,
					get = function() return GT.DBComm:GetBroadcastInterval() / 60 end,
					set = function(info, val) GT.DBComm:SetBroadcastInterval(val * 60) end,
				},
				sendBroadcastingToggle = {
					name = GT.L['LABEL_SEND_BROADCAST'],
					desc = GT.L['DESC_SEND_BROADCAST'],
					type = 'toggle',
					width = 'full',
					order = 2,
					confirm = function(info) return Options:GetBroadcastingConfirm(GT.L['CONFIRM_SEND_BROADCAST'], GT.DBComm:GetIsBroadcasting()) end,
					get = function() return Options:GetIsBroadcasting() end,
					set = function(info, val) Options:SetIsBroadcasting(val) end
				},
				receiveBroadcastingToggle = {
					name = GT.L['LABEL_RECEIVE_BROADCASTS'],
					desc = GT.L['DESC_RECEIVE_BROADCASTS'],
					type = 'toggle',
					width = 'full',
					order = 3,
					confirm = function(info) return Options:GetBroadcastingConfirm(GT.L['CONFIRM_RECEIVE_BROADCASTS'], GT.DBComm:GetIsReceivingBroadcasts()) end,
					get = function() return GT.DBComm:GetIsReceivingBroadcasts() end,
					set = function(info, val) GT.DBComm:SetIsReceivingBroadcasts(val) end
				},
				sendForwardsToggle = {
					name = GT.L['LABEL_SEND_FORWARDS'],
					desc = GT.L['DESC_SEND_FORWARDS'],
					type = 'toggle',
					width = 'full',
					order = 4,
					confirm = function(info) return Options:GetBroadcastingConfirm(GT.L['CONFIRM_SEND_FORWARDS'], GT.DBComm:GetIsForwarding()) end,
					get = function() return Options:GetIsForwarding() end,
					set = function(info, val) Options:SetIsForwarding(val) end
				},
				receiveForwardsToggle = {
					name = GT.L['LABEL_RECEIVE_FORWARDS'],
					desc = GT.L['DESC_RECEIVE_FORWARDS'],
					type = 'toggle',
					width = 'full',
					order = 5,
					confirm = function(info) return Options:GetBroadcastingConfirm(GT.L['CONFIRM_RECEIVE_FORWARDS'], GT.DBComm:GetIsReceivingForwards()) end,
					get = function() return GT.DBComm:GetIsReceivingForwards() end,
					set = function(info, val) GT.DBComm:SetIsReceivingForwards(val) end
				},
			}
		}
	}
}

function Options:OnEnable()
	GT.Log:Info('Options_OnEnable')
	Config:RegisterOptionsTable(PANEL_NAME, options)
	CR:RegisterOptionsTable(AddOnName, options)
	CD:AddToBlizOptions(GT.L['BARE_LONG_TAG'], GT.L['LONG_TAG'])
end

function Options:GetBroadcastingConfirm(message, isBroadcasting)
	if not isBroadcasting then
		return message
	end
	return nil
end

function Options:GetIsBroadcasting()
	local isBroadcasting = GT.DBComm:GetIsBroadcasting()
	local isForwarding = GT.DBComm:GetIsForwarding()
	GT.Log:Info('Options_GetIsBroadcasting', isBroadcasting)
	options.args.broadcastingRow.args.broadcastInterval.disabled = not isBroadcasting or not isForwarding
	return isBroadcasting
end

function Options:SetIsBroadcasting(val)
	GT.Log:Info('Options_SetIsBroadcasting', val)
	local isForwarding = GT.DBComm:GetIsForwarding()
	options.args.broadcastingRow.args.broadcastInterval.disabled = not val and not isForwarding
	GT.DBComm:SetIsBroadcasting(val)
	CR:NotifyChange(PANEL_NAME)
end

function Options:GetIsForwarding()
	local isBroadcasting = GT.DBComm:GetIsBroadcasting()
	local isForwarding = GT.DBComm:GetIsForwarding()
	GT.Log:Info('Options_GetIsForwarding', isForwarding)
	options.args.broadcastingRow.args.broadcastInterval.disabled = not isBroadcasting and not isForwarding
	return isForwarding
end

function Options:SetIsForwarding(val)
	GT.Log:Info('Options_SetIsForwarding', val)
	local isBroadcasting = GT.DBComm:GetIsBroadcasting()
	options.args.broadcastingRow.args.broadcastInterval.disabled = not val and not isForwarding
	GT.DBComm:SetIsForwarding(val)
	CR:NotifyChange(PANEL_NAME)
end

function Options:GetIsAdvertising()
	local isAdvertising = GT.DBComm:GetIsAdvertising()
	GT.Log:Info('Options_GetIsAdvertising', isAdvertising)
	options.args.advertiseRow.args.advertiseInterval.disabled = not isAdvertising
	return isAdvertising
end

function Options:SetIsAdvertising(val)
	GT.Log:Info('Options_SetIsAdvertising', val)
	options.args.advertiseRow.args.advertiseInterval.disabled = not val
	GT.DBComm:SetIsAdvertising(val)
	CR:NotifyChange(PANEL_NAME)
end

function Options:GetRequestFilter()
	local filterState = GT.DBComm:GetRequestFilterState()
	GT.Log:Info('Options_GetRequestsFilter', Text:ToString(filterState))
	local toggle = options.args.requestsRow.args.requestsToggle
	if filterState == nil then
		toggle.name = GT.L['LABEL_REQUESTS_TOGGLE_CONFIRM']
	elseif filterState == true then
		toggle.name = GT.L['LABEL_REQUESTS_TOGGLE_ALL']
	elseif filterState == false then
		toggle.name = GT.L['LABEL_REQUESTS_TOGGLE_NONE']
	end
	CR:NotifyChange(PANEL_NAME)
	return filterState
end

function Options:SetRequestFilter(val)
	GT.Log:Info('Options_SetRequestsFilter', Text:ToString(val))
	GT.DBComm:SetRequestFilterState(val)
end

function Options:SendConfirm()
	local characterName = Options:GetSelectedRequest()
	GT.CommWhisper:SendConfirm(characterName, false)
	Options.selectedRequest = nil
	GT:ScheduleTimer(Options['_SendConfirm'], ADD_DELAY)
end

function Options:_SendConfirm()
	GT.Log:Info('Options__SendConfirm')
	options.args.nonGuildMembers.args.characters.values = Options:GetCharacters()
	CR:NotifyChange(PANEL_NAME)
end

function Options:SendReject()
	local characterName = Options:GetSelectedRequest()
	GT.CommWhisper:SendReject({characterName})
	CR:NotifyChange(PANEL_NAME)
end

function Options:SendIgnore()
	local characterName = Options:GetSelectedRequest()
	GT.CommWhisper:SendIgnore({characterName})
	CR:NotifyChange(PANEL_NAME)
end

function Options:GetRequests()
	local comms = GT.DBComm:GetComms()
	local requests = {}
	for characterName, comm in pairs(comms) do
		if comm.isIncoming == GT.CommWhisper.INCOMING and comm.command == GT.CommWhisper.REQUEST then
			local characterName = characterName:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
			requests[characterName] = characterName
		end
	end

	return requests
end

function Options:GetSelectedRequest()
	local comms = GT.DBComm:GetComms()
	if Options.selectedRequest == nil then
		for characterName, comm in pairs(comms) do
			if comm.isIncoming == GT.CommWhisper.INCOMING and comm.command == GT.CommWhisper.REQUEST then
				local characterName = characterName:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
				Options.selectedRequest = characterName
				break
			end
		end
	end

	local requestsRowArgs = options.args.requestsRow.args

	local requests = requestsRowArgs.requests
	local confirmButton = requestsRowArgs.sendConfirm
	local rejectButton = requestsRowArgs.sendReject
	local ignoreButton = requestsRowArgs.sendIgnore

	if Options.selectedRequest ~= nil then
		requests.disabled = false
		confirmButton.disabled = false
		rejectButton.disabled = false
		ignoreButton.disabled = false
	else
		requests.disabled = true
		confirmButton.disabled = true
		rejectButton.disabled = true
		ignoreButton.disabled = true
	end
	return Options.selectedRequest
end

function Options:AddCharacter(characterName)
	GT.Log:Info('Options_AddCharacter', characterName)
	GT.CommWhisper:SendRequest({characterName})
end

function Options:GetCharacters()
	local returnCharacters = {}
	local characters = GT.DBCharacter:GetCharacters()
	local enabled = false
	for characterName, _ in pairs(characters) do
		local character = characters[characterName]
		if not character.isGuildMember then
			returnCharacters[characterName] = characterName
			enabled = true
		end
	end
	if enabled then
		options.args.nonGuildMembers.args.characters.disabled = false
	else
		options.args.nonGuildMembers.args.characters.disabled = true
	end
	CR:NotifyChange(PANEL_NAME)
	return returnCharacters
end

function Options:GetSelectedCharacter()
	if Options.selectedCharacter == nil then
		local characters = Options:GetCharacters()
		for characterName, _ in pairs(characters) do
			Options.selectedCharacter = characterName
			break
		end
	end
	GT.Log:Info('Options_GetSelectedCharacter', Options.selectedCharacter)
	local button = options.args.nonGuildMembers.args.characterRemove
	if Options.selectedCharacter == nil then
		button.disabled = true
	else
		button.disabled = false
	end
	return Options.selectedCharacter
end

function Options:DeleteCharacter()
	GT.Log:Info('Options_DeleteCharacter', Options.selectedCharacter)
	GT.DBCharacter:DeleteCharacter(Options.selectedCharacter)
	Options.selectedCharacter = nil
	CR:NotifyChange(PANEL_NAME)
end

function Options:ToggleAddProfession()
	GT.Log:Info('Options_ToggleAddProfession')
	GT.Profession:InitAddProfession(Options['_ToggleAddProfession'])
	if GT.Profession.adding then
		options.args.professionGroup.args.professionAdd.name = GT.L['CANCEL']
		options.args.professionGroup.args.professionAdd.desc = GT.L['PROFESSION_ADD_CANCEL_DESC']
	else
		options.args.professionGroup.args.professionAdd.name = GT.L['PROFESSION_ADD_NAME']
		options.args.professionGroup.args.professionAdd.desc = GT.L['PROFESSION_ADD_DESC']
	end
end

function Options:_ToggleAddProfession()
	GT.Log:Info('Options__ToggleAddProfession')
	options.args.professionGroup.args.professionAdd.name = GT.L['PROFESSION_ADD_NAME']
	options.args.professionGroup.args.professionAdd.desc = GT.L['PROFESSION_ADD_DESC']
	CR:NotifyChange(PANEL_NAME)
end

function Options:DeleteProfession()
	GT.Profession:DeleteProfession({Options:GetSelectedProfession()})
	Options.selectedProfession = nil
	CR:NotifyChange(PANEL_NAME)
end

function Options:GetConfirmText(info, template, fn)
	local widgetName = info[1]
	local widget = info.options.args[widgetName]
	local replacement = fn()
	local message = template
	message = string.gsub(message, '%{{profession_name}}', replacement)
	message = string.gsub(message, '%{{character_name}}', replacement)
	return message
end

function Options:ToggleFrame()
	if not CD:Close(PANEL_NAME) then
		CD:Open(PANEL_NAME)
	end
end

function Options:GetSelectedProfession()
	if Options.selectedProfession == nil then
		local professions = Options:GetPlayerProfessions()
		for professionName, _ in pairs(professions) do
			Options.selectedProfession = professionName
			break
		end
	end
	GT.Log:Info('Options_GetSelectedProfession', Options.selectedProfession)
	local button = options.args.professionGroup.args.professionRemove
	local toggle = options.args.advertiseRow.args.advertiseToggle
	if Options.selectedProfession == nil then
		toggle.disabled = true
		button.disabled = true
	else
		toggle.disabled = false
		button.disabled = false
	end
	return Options.selectedProfession
end

function Options:GetPlayerProfessions()
	local characterName = GT:GetCharacterName()
	local professions = GT.DBCharacter:GetProfessions(characterName)
	local returnProfessions = {}
	for professionName, _ in pairs(professions) do
		returnProfessions[professionName] = professionName
	end
	return returnProfessions
end