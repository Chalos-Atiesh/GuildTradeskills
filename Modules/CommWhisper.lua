local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local CommWhisper = GT:NewModule('CommWhisper')
GT.CommWhisper = CommWhisper

LibStub('AceComm-3.0'):Embed(CommWhisper)

local GET = 'GET'

local COMMAND_MAP = {}

function CommWhisper:OnEnable()
	GT.Log:Info('CommWhisper_OnEnable')
	COMMAND_MAP = {
		GET = 'OnGetReceived'
	}

	for command, functionName in pairs(COMMAND_MAP) do
		CommWhisper:RegisterComm(command, functionName)
	end
end

function CommWhisper:OnTimestampsReceived(sender, toGet, toPost)
	GT.Log:Info('CommWhisper_OnTimestampsReceived', sender, toGet, toPost)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommWhisper_OnTimestampsReceived_CommDisabled')
		return
	end

	local sendLines = {}
	for characterName, _ in pairs(toGet) do
		for _, professionName in pairs(toGet[characterName]) do
			table.insert(sendLines, GT.Text:Concat(characterName, professionName))
		end
	end

	local message = table.concat(sendLines, GT.Comm.DELIMITER)
	GT.Log:Info('CommWhisper_OnTimestampsReceived_SendGet', sender, message)
	Comm:SendCommMessage(GET, message, GT.Comm.WHISPER, sender, 'NORMAL')

	for characterName, _ in pairs(toPost) do
		if characterName ~= sender then
			for _, professionName in pairs(toPost[characterName]) do
				Comm:SendPost(GT.Comm.WHISPER, characterName, professionName, sender)
			end
		end
	end
end

function CommWhisper:OnGetReceived(prefix, message, distribution, sender)
	GT.Log:Info('CommWhisper_OnGetReceived', sender, message)

	if not GT.DB:IsCommEnabled() then
		GT.Log:Warn('CommWhisper_OnGetReceived_CommDisabled')
		return
	end

	if not GT.CommValidator:IsGetValid(message) then
		GT.Log:Error('CommWhisper_OnGetReceived_InvalidGet', sender, message)
		return
	end

	local tokens = GT.Text:Tokenize(message, Comm.DELIMITER)
	while #tokens > 0 do
		local characterName, tokens = GT.Table:RemoveToken(tokens)
		local professionName, tokens = GT.Table:RemoveToken(tokens)

		if professionName ~= 'None' then
			GT.Comm:SendPost(GT.Comm.WHISPER, characterName, professionName, sender)
		else
			GT.Log:Info('Comm_OnGetReceived_Ignore', prefix, distribution, sender, characterName, professionName)
		end
	end
end