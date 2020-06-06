local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local Command = GT:NewModule('Command')
GT.Command = Command
GT.Command.tokens = nil

local devCommands = {
	logdump = {
		methodName = 'LogDump',
		help = '/gt recap: Dumps the stored logs to a copy/pastable window.'
	},
	dbdump = {
		methodName = 'DBDump',
		help = '/gt dbdump: Dumps the database to a copy/pastable window.'
	},
	comm = {
		methodName = 'ToggleComms',
		help = '/gt comm: Toggles comms.'
	}
}

function Command:OnEnable()
	GT.Log:Info('Command_OnEnable')
	for command, info in pairs(GT.L['SLASH_COMMANDS']) do
		GT.RegisterChatCommand(self, command, info.methodName)
	end
	for devCommand, info in pairs(devCommands) do
		GT.RegisterChatCommand(self, devCommand, info.methodName)
	end
end

function Command:OnCommand(input)
	GT.Log:Info('Command_OnCommand', input)
	local tokens = Text:Tokenize(input)
	if #tokens <= 0 then
		Command:Search()
		return
	end

	local userCommand, tokens = Table:RemoveToken(tokens)
	userCommand = string.lower(userCommand)
	Command.tokens = tokens

	local publicDidRun = Command:DoCommand(GT.L['SLASH_COMMANDS']['gt'].subCommands, userCommand)
	local devDidRun = Command:DoCommand(devCommands, userCommand)

	if publicDidRun or devDidRun then
		return
	end

	local message = string.gsub(GT.L['UNKNOWN_COMMAND'], '%{{command}}', userCommand)
	GT.Log:PlayerWarn(message)
end

function Command:DoCommand(commands, userCommand)
	for command, info in pairs(commands) do
		if userCommand == command then
			local methodName = info.methodName
			GT.Log:Info('Command_OnCommand_Found', command, methodName)
			Command[methodName]()
			return true
		end
	end
	return false
end

function Command:Help()
	GT.Log:Info('Command_Help', Command.tokens)
	Command:_Help(GT.L['SLASH_COMMANDS'])
end

function Command:_Help(commands)
	local sortedKeys = Table:GetSortedKeys(commands, function(a, b) return Command:_CompareCommands(a, commands[a], b, commands[b]) end)
	for _, command in pairs(sortedKeys) do
		local info = commands[command]
		if info.help ~= nil then
			GT.Log:PlayerInfo(info.help)
		end
		if info.subCommands then
			GT.Command:_Help(info.subCommands)
		end
	end
end

function Command:_CompareCommands(a, aInfo, b, bInfo)
	if aInfo.order ~= nil and bInfo.order ~= nil then
		return aInfo.order < bInfo.order
	end
	return a < b
end

function Command:Options()
	GT.Options:ToggleFrame(Command.tokens)
end

function Command:Search()
	GT.Log:Info('Command_Search', Command.tokens)
	GT.Search:Enable()
	GT.Search:ToggleFrame(Command.tokens)
end

function Command:InitAddProfession()
	GT.Log:Info('Command_InitAddProfession')
	GT.Profession:InitAddProfession()
end

function Command:RemoveProfession()
	GT.Log:Info('Command_RemoveProfession', Command.tokens)
	GT.Profession:DeleteProfession(Command.tokens)
end

function Command:SetChatFrame()
	GT.Log:Info('Command_SetChatFrame', Command.tokens)
	local windowName = Table:RemoveToken(Command.tokens)
	if windowName == nil then
		GT.Log:PlayerError(GT.L['CHAT_FRAME_NIL'])
		return
	end
	local franeNumber = Log:SetChatFrameByName(windowName)
	if franeNumber == nil then
		local message = string.gsub(GT.L['CHAT_WINDOW_INVALID'], '%{{frame_name}}', frameName)
		GT.Log:PlayerError(message)
		return
	end
	GT.DB:SetChatFrameNumber(frameNumber)
	local message = string.gsub(GT.L['CHAT_WINDOW_SUCCESS'], '%{{frame_name}}', name)
	Log:PlayerInfo(message)
end

function Command:Reset()
	GT.Log:Info('Command_Reset', Command.tokens)
	GT:InitReset(Command.tokens)
end

function Command:LogDump()
	GT.Log:Info('Command_LogDump', Command.tokens)
	GT.Log:LogDump(Command.tokens)
end

function Command:DBDump()
	GT.Log:Info('Command_DBDump', Command.tokens)

	local arg, args = Table:RemoveToken(Command.tokens)

	local characterDump = Text:FormatTable(GT.DBCharacter:GetCharacters())
	local professionDump = Text:FormatTable(GT.DBProfession:GetProfessions())
	local text = Text:Concat('\n', GT.L['CHARACTERS'], characterDump, GT.L['PROFESSIONS'], professionDump)
	GT.Log:DumpText(text)
end

function Command:ToggleAdvertising()
	GT.Log:Info('Command_ToggleAdvertising', Command.tokens)
	GT.Advertise:ToggleAdvertising(Command.tokens)
end

function Command:SendRequest()
	GT.Log:Info('Command_SendRequest', Command.tokens)
	GT.CommWhisper:SendRequest(Command.tokens)
end

function Command:SendReject()
	GT.Log:Info('Command_SendReject', Command.tokens)
	GT.CommWhisper:SendReject(Command.tokens)
end

function Command:SendIgnore()
	GT.Log:Info('Command_SendIgnore', Command.tokens)
	GT.CommWhisper:SendIgnore(Command.tokens)
end

function Command:ShowRequests()
	local comms = GT.DBComm:GetComms(GT.CommWhisper.INCOMING, GT.CommWhisper.REQUEST)
	local characterNames = {}
	for characterName, comm in pairs(comms) do
		if comm.isIncoming and comm.command == GT.CommWhisper.REQUEST then
			local characterName = characterName:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
			table.insert(characterNames, characterName)
		end
	end
	local message = nil
	if #characterNames <= 0 then
		message = GT.L['WHISPER_NO_INCOMING_REQUESTS']
	else
		local characters = table.concat(characterNames, GT.L['PRINT_DELIMITER'])
		message = string.gsub(GT.L['WHISPER_INCOMING_REQUESTS'], '%{{character_names}}', characters)
	end
	GT.Log:PlayerInfo(message)
end

function Command:ToggleBroadcast()
	GT.Log:Info('Command_ToggleBroadcast', Command.tokens)
	local token = Table:RemoveToken(Command.tokens)
	if token == nil or token == GT.L['SEND'] or token == GT.L['RECEIVE'] then
		GT.CommYell:ToggleBroadcast({token})
		return
	end
	if token ~= nil and (token == GT.L['SEND_FORWARDS'] or token == GT.L['RECEIVE_FORWARDS']) then
		GT.CommYell:ToggleForwards({token})
		return
	end
	local message = string.gsub(GT.L['BROADCAST_UNKNOWN'], '%{{broadcast_type}}', token)
	GT.Log:PlayerWarn(message)
end

--@debug@
function Command:ToggleComms()
	GT.Comm:ToggleComms()
end

function Command:VersionCheck()
	GT.Comm:SendVersion()
end
--@end-debug@
