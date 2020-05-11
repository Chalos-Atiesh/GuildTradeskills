local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnName, true)

local Command = GT:NewModule('Command')
GT.Command = Command
GT.Command.tokens = nil

function Command:OnEnable()
	GT.Log:Info('Command_OnEnable')
	for command, info in pairs(L['SLASH_COMMANDS']) do
		GT.RegisterChatCommand(self, command, info.methodName)
	end
end

function Command:OnCommand(input)
	GT.Log:Info('Command_OnCommand', input)
	local tokens = GT.Text:Tokenize(input)
	if #tokens <= 0 then
		Command:Search()
		return
	end

	local commands = L['SLASH_COMMANDS']['gt'].subCommands

	local userCommand, tokens = GT.Table:RemoveToken(tokens)
	userCommand = string.lower(userCommand)
	
	for command, info in pairs(commands) do
		if userCommand == command then
			Command.tokens = tokens
			local methodName = info.methodName
			GT.Log:Info('Command_OnCommand', command, methodName, tokens)
			Command[methodName]()
			return
		end
	end

	GT.Log:PlayerWarn(string.gsub(L['UNKNOWN_COMMAND'], '%{{command}}', userCommand))
end

function Command:Help()
	GT.Log.Info('Command_Help')
	Command:_Help(L['SLASH_COMMANDS'])
end

function GT.Command:_Help(commands)
	for command, info in pairs(commands) do
		GT.Log:PlayerInfo(info.help)
		if info.subCommands then
			GT.Command:_Help(info.subCommands)
		end
	end
end

function Command:InitAddProfession()
	GT.Log:Info('Command_InitAddProfession')
	GT.Profession:InitAddProfession()
end

function Command:RemoveProfession()
	GT.Log:Info('Command_RemoveProfession', Command.tokens)
	local professionName = GT.Table:RemoveToken(Command.tokens)
	local characterName = UnitName('player')
	GT.Profession:DeleteProfession(characterName, professionName)
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

--@debug@
function Command:Delimit()
	GT.Log:PlayerError('--------------------')
end

function Command:PrintDB()
	GT.Log:Info(GT.DB:GetCharacters())
	GT.Log:Info(GT.DB:GetProfessions())
end

function Command:Recap()
	GT.Log:Recap()
end
--@end-debug@
