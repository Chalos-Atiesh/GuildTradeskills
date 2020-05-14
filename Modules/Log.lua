local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnName, true)

local AceGUI = LibStub('AceGUI-3.0')

local Log = GT:NewModule('Log')
GT.Log = Log

local DELIMITER = ': '
local LOG_FORMAT = '{{tag}}{{start_color}}{{message}}{{end_color}}'
local LOG_LINE_LENGTH_LIMIT = 200
local LOG_ARCHIVE_LIMIT = 100

local INFO = 0
local DEBUG = 1
local WARN = 2
local ERROR = 3
local PLAYER_INFO = 4
local PLAYER_WARN = 5
local PLAYER_ERROR = 6
local LOG_COLOR_MAP = {}

local LOG_LEVEL_FILTER = PLAYER_INFO
local DEFAULT_LOG_LEVEL = INFO
--@debug@
LOG_LEVEL_FILTER = INFO
--@end-debug@

local COLOR_INFO = '|cff7f7f7f'
local COLOR_DEBUG = '|cffffffff'
local COLOR_WARN = '|cffff9900'
local COLOR_ERROR = '|cffff0000'
local COLOR_PLAYER_INFO = ''
local COLOR_PLAYER_WARN = '|cffff9900'
local COLOR_PLAYER_ERROR = '|cffff0000'

local DEFAULT_LOG_COLOR = COLOR_INFO

function Log:OnEnable()
	LOG_COLOR_MAP[INFO] = COLOR_INFO
	LOG_COLOR_MAP[DEBUG] = COLOR_DEBUG
	LOG_COLOR_MAP[WARN] = COLOR_WARN
	LOG_COLOR_MAP[ERROR] = COLOR_ERROR
	LOG_COLOR_MAP[PLAYER_INFO] = COLOR_PLAYER_INFO
	LOG_COLOR_MAP[PLAYER_WARN] = COLOR_PLAYER_WARN
	LOG_COLOR_MAP[PLAYER_ERROR] = COLOR_PLAYER_ERROR

	if GTDB == nil then
		GTDB = {}
	end

	if GTDB.log == nil then
		GTDB.log = {}
	end
	-- Log:BuildCopyLogFrame()
end

function Log:Reset()
	Log:Info('Log_Reset')
	GTDB.log = {}
end

function Log:Info(...)
	Log:_Log(INFO, ...)
end

function Log:Debug(...)
	Log:_Log(DEBUG, ...)
end

function Log:Warn(...)
	Log:_Log(WARN, ...)
end

function Log:Error(...)
	Log:_Log(ERROR, ...)
end

function Log:PlayerInfo(...)
	Log:_Log(PLAYER_INFO, ...)
end

function Log:PlayerWarn(...)
	Log:_Log(PLAYER_WARN, ...)
end

function Log:PlayerError(...)
	Log:_Log(PLAYER_ERROR, ...)
end

function Log:SetChatFrame(frameName)
	Log:Info('Log_SetChatFrame', frameName)
	if frameName == nil then
		Log:PlayerWarn(L['CHAT_FRAME_NIL'])
	end

	for i = 1, NUM_CHAT_WINDOWS do
		local name = GetChatWindowInfo(i) or ''
		if name ~= '' and string.lower(name) == string.lower(frameName) then
			GT.DB:SetChatFrameNumber(i)
			local msg = string.gsub(L['CHAT_WINDOW_SUCCESS'], '%{{frame_name}}', name)
			Log:PlayerInfo(msg)
			return
		end
	end
	local msg = string.gsub(L['CHAT_WINDOW_INVALID'], '%{{frame_name}}', frameName)
	Log:PlayerError(msg)
end

function Log:_Log(logLevel, ...)
	local color = LOG_COLOR_MAP[logLevel] or DEFAULT_LOG_COLOR

	local original = GT.Text:Concat(DELIMITER, ...)
	local stripped = GT.Text:Strip(original)
	
	local printMessage = string.gsub(LOG_FORMAT, '%{{message}}', original)
	printMessage = string.gsub(printMessage, '%{{tag}}', L['LOG_TAG'])
	printMessage = string.gsub(printMessage, '%{{start_color}}', color)
	if color == '' then
		printMessage = string.gsub(printMessage, '%{{end_color}}', '')
	else
		printMessage = string.gsub(printMessage, '%{{end_color}}', '|r')
	end
	if logLevel < PLAYER_INFO and #stripped >= LOG_LINE_LENGTH_LIMIT then
		printMessage = string.sub(stripped, 1, LOG_LINE_LENGTH_LIMIT - 3) .. '...'
	end

	if GTDB ~= nil and GTDB.log ~= nil then
		local levelWithColor = nil
		if color == '' then
			levelWithColor = tostring(logLevel)
		else
			levelWithColor = color .. tostring(logLevel) .. '|r'
		end
		while #GTDB.log > LOG_ARCHIVE_LIMIT do
			table.remove(GTDB.log, 1)
		end
		stripped = GT.Text:Concat(DELIMITER, levelWithColor, date('%y-%m-%d %H:%M:%S', time()), stripped)
		table.insert(GTDB.log, stripped)
	end

	if logLevel < LOG_LEVEL_FILTER then
		return
	end

	local chatFrame = _G['ChatFrame' .. GT.DB:GetChatFrameNumber()]
	chatFrame:AddMessage(printMessage)
end



--@debug@
function Log:LogDump()
	Log:Info('Log_LogDump')
	local editBox = Log:GetEditBox()
	editBox:SetDisabled(true)

	local text = nil
	for _, logLine in pairs(GTDB.log) do
		if text == nil then
			text = logLine
		else
			text = GT.Text:Concat('\n', text, logLine)
		end
		editBox:SetText(text)
	end
	editBox:HighlightText(1, #text)
	
	editBox:SetDisabled(false)
end

function Log:DBDump()
	Log:Info('Log_DBDump')

	local editBox = Log:GetEditBox()
	local characterDump = GT.Text:FormatTable(GT.DB:GetCharacters())
	local professionDump = GT.Text:FormatTable(GT.DB:GetProfessions())
	editBox:SetText(GT.Text:Concat('\n', L['CHARACTERS'], characterDump, L['PROFESSIONS'], professionDump))
end

function Log:GetEditBox()
	local frame = AceGUI:Create("Frame")

	frame:SetCallback('OnClose', function(widget)
		widget:ReleaseChildren()
		AceGUI:Release(widget)
	end)
	frame:SetTitle(L['LOG_DUMP'])
	frame:SetLayout('Flow')

	_G['GT_CopyLogFrame'] = frame.frame
	tinsert(UISpecialFrames, "GT_CopyLogFrame")

	-- local logScrollContainer = AceGUI:Create('SimpleGroup')
	-- logScrollContainer:SetFullWidth(true)
	-- logScrollContainer:SetFullHeight(true)
	-- logScrollContainer:SetLayout('Fill')
	-- frame:AddChild(logScrollContainer)

	local editBox = AceGUI:Create('MultiLineEditBox')
	editBox:SetFullWidth(true)
	editBox:SetFullHeight(true)
	editBox:DisableButton(true)
	frame:AddChild(editBox)

	frame:Show()

	return editBox
end
--@end-debug@
