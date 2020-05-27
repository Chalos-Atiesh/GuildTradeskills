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
local PANEL_NAME = AddOnName .. '_Options'

local options = {
	type = 'group',
	args = {
		professionGroup = {
			name = GT.L['LABEL_PROFESSIONS'],
			type = 'group',
			width = 'full',
			inline = true,
			order = 0,
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
			order = 1,
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
			order = 2,
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
			order = 3,
			args = {
				advertiseToggle = {
					name = GT.L['LABEL_ADVERTISING'],
					desc = GT.L['DESC_ADVERTISE_TOGGLE'],
					type = 'toggle',
					disabled = true,
					order = 0,
					get = function() return GT.DB:IsAdvertising() end,
					set = function(info, val) GT.DB:SetAdvertising(val) end
				},
				advertiseInterval = {
					name = GT.L['LABEL_ADVERTISING_INTERVAL'],
					desc = GT.L['DESC_ADVERTISING_INTERVAL'],
					type = 'range',
					min = GT.Advertise.MINIMUM_INTERVAL / 60,
					max = GT.Advertise.MAXIMUM_INTERVAL / 60,
					step = 0.25,
					get = function() return GT.DB:GetAdvertisingInterval() / 60 end,
					set = function(info, val) GT.DB:SetAdvertisingInterval(val * 60) end,
				}
			}
		},
		broadcastingRow = {
			name = GT.L['BROADCASTING'],
			type = 'group',
			width = 'full',
			inline = true,
			order = 4,
			args = {
				broadcastInterval = {
					name = GT.L['LABEL_BROADCAST_INTERVAL'],
					desc = GT.L['DESC_BROADCAST_INTERVAL'],
					type = 'range',
					width = 'full',
					min = GT.CommYell.MIN_BROADCAST_INTERVAL / 60,
					max = GT.CommYell.MAX_BROADCAST_INTERVAL / 60,
					step = 0.25,
					order = 1,
					get = function() return GT.DB:GetBroadcastInterval() / 60 end,
					set = function(info, val) GT.DB:SetBroadcastInterval(val * 60) end,
				},
				sendBroadcastingToggle = {
					name = GT.L['LABEL_SEND_BROADCAST'],
					desc = GT.L['DESC_SEND_BROADCAST'],
					type = 'toggle',
					width = 'full',
					order = 2,
					get = function() return GT.DB:IsBroadcasting() end,
					set = function(info, val) GT.DB:SetBroadcasting(val) end
				},
				receiveBroadcastingToggle = {
					name = GT.L['LABEL_RECEIVE_BROADCASTS'],
					desc = GT.L['DESC_RECEIVE_BROADCASTS'],
					type = 'toggle',
					width = 'full',
					order = 3,
					get = function() return GT.DB:IsReceivingBroadcasts() end,
					set = function(info, val) GT.DB:SetReceivingBroadcasts(val) end
				},
				sendForwardsToggle = {
					name = GT.L['LABEL_SEND_FORWARDS'],
					desc = GT.L['DESC_SEND_FORWARDS'],
					type = 'toggle',
					width = 'full',
					order = 4,
					get = function() return GT.DB:IsForwarding() end,
					set = function(info, val) GT.DB:SetForwarding(val) end
				},
				receiveForwardsToggle = {
					name = GT.L['LABEL_RECEIVE_FORWARDS'],
					desc = GT.L['DESC_RECEIVE_FORWARDS'],
					type = 'toggle',
					width = 'full',
					order = 5,
					get = function() return GT.DB:IsReceivingForwards() end,
					set = function(info, val) GT.DB:SetReceivingForwards(val) end
				},
			}
		}
	}
}

function Options:OnEnable()
	GT.Log:Info('Options_OnEnable')
	Config:RegisterOptionsTable(PANEL_NAME, options)
	CD:AddToBlizOptions(GT.L['BARE_LONG_TAG'], GT.L['LONG_TAG'])
end

function Options:GetRequestFilter()
	local filterState = GT.DB:GetRequestFilterState()
	GT.Log:Info('Options_GetRequestsFilter', GT.Text:ToString(filterState))
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
	GT.Log:Info('Options_SetRequestsFilter', GT.Text:ToString(val))
	GT.DB:SetRequestFilterState(val)
end

function Options:SendConfirm()
	local characterName = Options:GetSelectedRequest()
	GT.CommWhisper:SendConfirm(characterName, true)
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
	local comms = GT.DB:GetCommsWithCommand(GT.CommWhisper.INCOMING, GT.CommWhisper.REQUEST)
	local requests = {}
	for _, comm in pairs(comms) do
		local characterName = comm.characterName:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
		requests[characterName] = characterName
	end

	return requests
end

function Options:GetSelectedRequest()
	local comms = GT.DB:GetCommsWithCommand(GT.CommWhisper.INCOMING, GT.CommWhisper.REQUEST)
	if Options.selectedRequest == nil then
		for _, comm in pairs(comms) do
			local characterName = comm.characterName:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
			Options.selectedRequest = characterName
			break
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
	local characters = GT.DB:GetCharacters()
	for characterName, _ in pairs(characters) do
		local character = characters[characterName]
		if not character.isGuildMember then
			returnCharacters[characterName] = characterName
		end
	end
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
	GT.DB:DeleteCharacter(Options.selectedCharacter)
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

function Options:ToggleOptions()
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
	local characterName = GT:GetCurrentCharacter()
	local professions = GT.DB:GetCharacter(characterName).professions
	local returnProfessions = {}
	for professionName, _ in pairs(professions) do
		returnProfessions[professionName] = professionName
	end
	return returnProfessions
end