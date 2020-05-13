local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnName, true)

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
			GT.Log:PlayerInfo(msg)
			return
		end
	end
	local msg = string.gsub(L['CHAT_WINDOW_INVALID'], '%{{frame_name}}', frameName)
	GT.Log:PlayerError(msg)
end

function Log:_Log(logLevel, ...)
	local color = LOG_COLOR_MAP[logLevel] or DEFAULT_LOG_COLOR

	local message = GT.Text:Concat(DELIMITER, ...)
	
	message = string.gsub(LOG_FORMAT, '%{{message}}', message)
	message = string.gsub(message, '%{{tag}}', L['LOG_TAG'])
	message = string.gsub(message, '%{{start_color}}', color)
	if color == '' then
		message = string.gsub(message, '%{{end_color}}', '')
	else
		message = string.gsub(message, '%{{end_color}}', '|r')
	end

	local stripped = GT.Text:Strip(message, GT.Comm:GetDelimiter())
	local printMessage = message
	if logLevel < PLAYER_INFO and #stripped >= LOG_LINE_LENGTH_LIMIT then
		printMessage = string.sub(stripped, 1, LOG_LINE_LENGTH_LIMIT - 3) .. '...'
	end

	if GTDB ~= nil and GTDB.log ~= nil then
		local log = {}
		log.timeStamp = time()
		log.logLevel = logLevel
		log.message = message
		while #GTDB.log > LOG_ARCHIVE_LIMIT do
			table.remove(GTDB.log, 1)
		end
		table.insert(GTDB.log, log)
	end

	if logLevel < LOG_LEVEL_FILTER then
		return
	end

	local chatFrame = _G['ChatFrame' .. GT.DB:GetChatFrameNumber()]
	chatFrame:AddMessage(printMessage)
end

--@debug@
function Log:Recap()
	local chatFrame = _G['ChatFrame' .. GT.DB:GetChatFrameNumber()]
	local message = GT.Text:Concat('', L['LOG_TAG'],  COLOR_ERROR,  L['RECAP_HEADER'], '|r')
	chatFrame:AddMessage(message)
	for _, log in pairs(GTDB.log) do
		local timeStamp = date(date('%y-%m-%d %H:%M:%S', log.timeStamp))
		local logLevel = log.logLevel
		message = GT.Text:Concat(DELIMITER, logLevel, timeStamp, log.message)
		chatFrame:AddMessage(GT.Text:Concat('', L['LOG_TAG'], message))
	end
	message = GT.Text:Concat('', L['LOG_TAG'], COLOR_ERROR, L['RECAP_FOOTER'], '|r')
	chatFrame:AddMessage(message)
end
--@end-debug@
