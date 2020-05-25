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
	local tokens = GT.Text:Tokenize(input)
	if #tokens <= 0 then
		Command:Search()
		return
	end

	local userCommand, tokens = GT.Table:RemoveToken(tokens)
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
	local sortedKeys = GT.Table:GetSortedKeys(commands, function(a, b) return Command:_CompareCommands(a, commands[a], b, commands[b]) end)
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
	GT.Options:ToggleOptions(Command.tokens)
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
	local windowName = GT.Table:RemoveToken(Command.tokens)
	GT.Log:SetChatFrame(windowName)
end

function Command:Reset()
	GT.Log:Info('Command_Reset', Command.tokens)
	GT:InitReset(Command.tokens)
end

function Command:Search()
	GT.Log:Info('Command_Search', Command.tokens)
	GT.Search:Enable()
	GT.Search:OpenSearch(Command.tokens)
end

function Command:LogDump()
	GT.Log:Info('Command_LogDump', Command.tokens)
	GT.Log:LogDump(Command.tokens)
end

function Command:DBDump()
	GT.Log:Info('Command_DBDump', Command.tokens)
	GT.Log:DBDump(Command.tokens)
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
	local comms = GT.DB:GetCommsWithCommand(GT.CommWhisper.INCOMING, GT.CommWhisper.REQUEST)
	local characterNames = {}
	for _, comm in pairs(comms) do
		local characterName = comm.characterName:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
		table.insert(characterNames, characterName)
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
	GT.CommYell:ToggleBroadcast(Command.tokens)
end

function Command:ToggleForwards()
	GT.Log:Info('Command_ToggleForwards', Command.tokens)
	GT.CommYell:ToggleForwards(Command.tokens)
end

--@debug@
function Command:ToggleComms()
	GT.Comm:ToggleComms()
end

function Command:VersionCheck()
	GT.Comm:SendVersion()
end
--@end-debug@
