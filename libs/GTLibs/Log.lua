local majorVersion = 'Log'
local minorVersion = 1

local Log, oldMinor = LibStub:NewLibrary(majorVersion, minorVersion)

local AceGUI = LibStub('AceGUI-3.0')

local Text = assert(Text, 'Log-1.0 requires the Text library.')
local Table = assert(Table, 'Log-1.0 requires the Table library.')

Log.DEFAULT_CHAT_FRAME = 1

local DELIMITER = ': '
local LOG_FORMAT = '{{tag}}{{start_color}}{{message}}{{end_color}}'
local LOG_LINE_LENGTH_LIMIT = 200
local LOG_ARCHIVE_LIMIT = 500

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

local STRING_INFO = 'INFO'
local STRING_DEBUG = 'DEBUG'
local STRING_WARN = 'WARN'
local STRING_ERROR = 'ERROR'
local STRING_PLAYER_INFO = 'PLAYER_INFO'
local STRING_PLAYER_WARN = 'PLAYER_WARN'
local STRING_PLAYER_ERROR = 'PLAYER_ERROR'

local LOG_STRING_MAP = {}

local DEFAULT_LOG_COLOR = COLOR_INFO

function Log:Init()
	LOG_COLOR_MAP[INFO] = COLOR_INFO
	LOG_COLOR_MAP[DEBUG] = COLOR_DEBUG
	LOG_COLOR_MAP[WARN] = COLOR_WARN
	LOG_COLOR_MAP[ERROR] = COLOR_ERROR
	LOG_COLOR_MAP[PLAYER_INFO] = COLOR_PLAYER_INFO
	LOG_COLOR_MAP[PLAYER_WARN] = COLOR_PLAYER_WARN
	LOG_COLOR_MAP[PLAYER_ERROR] = COLOR_PLAYER_ERROR

	LOG_STRING_MAP[INFO] = STRING_INFO
	LOG_STRING_MAP[DEBUG] = STRING_DEBUG
	LOG_STRING_MAP[WARN] = STRING_WARN
	LOG_STRING_MAP[ERROR] = STRING_ERROR
	LOG_STRING_MAP[PLAYER_INFO] = STRING_PLAYER_INFO
	LOG_STRING_MAP[PLAYER_WARN] = STRING_PLAYER_WARN
	LOG_STRING_MAP[PLAYER_ERROR] = STRING_PLAYER_ERROR

	if Log.DB == nil then
		Log.DB = {}
	end

	if Log.DB.log == nil then
		Log.DB.log = {}
	end

	if Log.DB.logTag == nil then
		Log.DB.logTag = ''
	end

	if Log.DB.frameNumber == nil then
		Log.DB.frameNumber = Log.DEFAULT_CHAT_FRAME
	end
end

function Log:Reset()
	Log.DB.log = {}
	Log.DB.frameNumber = Log.DEFAULT_CHAT_FRAME
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

function Log:GetChatFrameNumber()
	if Log.DB.frameNumber == nil then
		return Log.DEFAULT_CHAT_FRAME
	end
	return Log.DB.frameNumber
end

function Log:SetChatFrameByName(frameName)
	Log:Info('Log_SetChatFrame', frameName)

	for i = 1, NUM_CHAT_WINDOWS do
		local name = GetChatWindowInfo(i) or ''
		local shown = select(7, GetChatWindowInfo(i))
		if name ~= '' and string.lower(name) == string.lower(frameName) and shown then
			Log.DB.frameNumber = i
			return i
		end
	end
	return nil
end


function Log:SetChatFrameByNumber(frameNumber)
	local name = GetChatWindowInfo(frameNumber)
	local shown = select(7, GetChatWindowInfo(frameNumber))
	if shown then
		Log.DB.frameNumber = i
		return true
	end
	return false
end
function Log:GetLogTag()
	return Log.DB.logTag
end

function Log:SetLogTag(logTag)
	Log.DB.logTag = logTag
end

function Log:_Log(logLevel, ...)
	local color = LOG_COLOR_MAP[logLevel] or DEFAULT_LOG_COLOR

	local original = Text:Concat(DELIMITER, ...)
	
	local printMessage = string.gsub(LOG_FORMAT, '%{{message}}', original)
	printMessage = string.gsub(printMessage, '|r', '|r' .. color)
	local logMessage = Text:Strip(printMessage)
	if logLevel < PLAYER_INFO and #logMessage >= LOG_LINE_LENGTH_LIMIT then
		printMessage = string.sub(logMessage, 0, LOG_LINE_LENGTH_LIMIT - 3) .. '...'
	end
	printMessage = Log:_FormatLogLine(printMessage, color, Log.DB.logTag)
	logMessage = Log:_FormatLogLine(logMessage, color, '')

	if GTDB ~= nil and GTDB.log ~= nil then
		local levelWithColor = nil
		if color == '' then
			levelWithColor = Text:Concat(DELIMITER, tostring(logLevel),  LOG_STRING_MAP[logLevel])
		else
			levelWithColor = color .. Text:Concat(tostring(logLevel), LOG_STRING_MAP[logLevel]) .. '|r'
		end
		while #GTDB.log > LOG_ARCHIVE_LIMIT do
			table.remove(GTDB.log, 1)
		end
		logMessage = Text:Concat(DELIMITER, levelWithColor, date('%y-%m-%d %H:%M:%S', time()), logMessage)
		table.insert(GTDB.log, logMessage)
	end

	if logLevel < LOG_LEVEL_FILTER then
		return
	end

	local chatFrame = _G['ChatFrame' .. Log:GetChatFrameNumber()]
	chatFrame:AddMessage(printMessage)
end

function Log:_FormatLogLine(message, color, tag)
	message = string.gsub(message, '%{{tag}}', tag)
	message = string.gsub(message, '%{{start_color}}', color)
	if color == '' then
		message = string.gsub(message, '%{{end_color}}', '')
	else
		message = string.gsub(message, '%{{end_color}}', '|r')
	end
	return message
end

function Log:LogDump(args)
	Log:Info('Log_LogDump', args)
	local editBox = Log:GetEditBox()
	editBox:SetDisabled(true)

	local text = nil
	for _, logLine in pairs(GTDB.log) do
		if text == nil then
			text = logLine
		else
			text = Text:Concat('\n', text, logLine)
		end
		editBox:SetText(text)
	end
	editBox:HighlightText(0, #text)
	
	editBox:SetDisabled(false)
end

function Log:DumpText(text)
	Log:Info('Log_DumpText', text)
	local editBox = Log:GetEditBox()
	editBox:SetText(text)
	editBox:HighlightText(0, #text)
end

function Log:GetEditBox()
	local frame = AceGUI:Create('Frame')

	frame:SetCallback('OnClose', function(widget)
		widget:ReleaseChildren()
		AceGUI:Release(widget)
	end)
	frame:SetTitle('LOG DUMP')
	frame:SetLayout('Flow')

	_G['GT_CopyLogFrame'] = frame.frame
	tinsert(UISpecialFrames, 'GT_CopyLogFrame')

	local editBox = AceGUI:Create('MultiLineEditBox')
	editBox:SetFullWidth(true)
	editBox:SetFullHeight(true)
	editBox:DisableButton(true)
	frame:AddChild(editBox)

	frame:Show()

	return editBox
end

Log:Init()