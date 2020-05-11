local AddOnName, GT = ...

GT = LibStub('AceAddon-3.0'):NewAddon(AddOnName, 'AceComm-3.0', 'AceConsole-3.0', 'AceEvent-3.0')

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnName, true)

---------- START LOAD LIBRARIES ----------

GT.Text = LibStub:GetLibrary('GTText')
GT.Table = LibStub:GetLibrary('GTTable')

---------- END LOAD LIBRARIES ----------

GT.resetWarned = false
GT.version = '@project-version@'

function GT:OnInitialize()
	GT.Log:Enable()

	GT.Log:Info('GT_OnInitialize')

	GT.Command:Enable()
	GT.Event:Enable()
end

function GT:OnDisable()
	GT.Log:Info('GT_OnDisable')
end

function GT:InitReset(tokens)
	if not GT.resetWarned then
		GT.Log:PlayerWarn(L['RESET_WARN'])
		GT.resetWarned = true
		return
	end
	GT.resetWarned = false

	local token = GT.Table:RemoveToken(tokens)
	if token == nil then
		GT.Log:PlayerWarn(L['RESET_NO_TOKEN'])
		return
	end
	if string.lower(token) == string.lower(L['RESET_EXPECT_CANCEL']) then
		GT.Log:PlayerInfo(L['RESET_CANCEL'])
		return
	end
	if string.lower(token) == string.lower(L['RESET_EXPECT_COMFIRM']) then
		GT.Log:PlayerWarn(L['RESET_FINAL'])

		GT.Log:OnEnable(true)
		GT.Command:OnEnable(true)
		GT.DB:OnEnable(true)
		GT.Event:OnEnable(true)
		return
	end

	local message = string.gsub(L['RESET_UNKNOWN'], '%{{token}}', token)
	GT.Log:PlayerWarn(message)
end
