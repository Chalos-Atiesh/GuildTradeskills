local GT_Name, GT = ...

GT.logging = {}
GT.logging.LOG_LINE_LENGTH_LIMIT = 127
GT.logging.state = {}
GT.logging.initialized = false
GT.logging.TABLE_SPACING = '  '
GT.logging.LOG_FORMAT = '{{tag}}{{start_color}}{{message}}{{end_color}}'

GT.logging.INFO = 0
GT.logging.DEBUG = 1
GT.logging.WARN = 2
GT.logging.ERROR = 3
GT.logging.PLAYER_INFO = 4
GT.logging.PLAYER_WARN = 5
GT.logging.PLAYER_ERROR = 6

GT.logging.COLOR_INFO = '|cff7f7f7f'
GT.logging.COLOR_DEBUG = '|cffffffff'
GT.logging.COLOR_WARN = '|cffff9900'
GT.logging.COLOR_ERROR = '|cffff0000'
GT.logging.COLOR_PLAYER_INFO = ''
GT.logging.COLOR_PLAYER_WARN = '|cffff9900'
GT.logging.COLOR_PLAYER_ERROR = '|cffff9900'

GT.logging.state.logLevelFilter = GT.logging.PLAYER_INFO
--@debug@ 
GT.logging.state.logLevelFilter = GT.logging.INFO
--@end-debug@
GT.logging.state.logLevelDefault = GT.logging.INFO

GT.logging.DELIMITER = ': '

local LOG_COLOR_MAP = {}

function GT.logging.init(force)
	if GT.logging.initialized and not force then
		return
	end

	LOG_COLOR_MAP[GT.logging.INFO] = GT.logging.COLOR_INFO
	LOG_COLOR_MAP[GT.logging.DEBUG] = GT.logging.COLOR_DEBUG
	LOG_COLOR_MAP[GT.logging.WARN] = GT.logging.COLOR_WARN
	LOG_COLOR_MAP[GT.logging.ERROR] = GT.logging.COLOR_ERROR
	LOG_COLOR_MAP[GT.logging.PLAYER_INFO] = GT.logging.COLOR_PLAYER_INFO
	LOG_COLOR_MAP[GT.logging.PLAYER_WARN] = GT.logging.COLOR_PLAYER_WARN
	LOG_COLOR_MAP[GT.logging.PLAYER_ERROR] = GT.logging.COLOR_PLAYER_ERROR

	GT.logging.info('GT_Logging_Init')

	GT.logging.initialized = true
end

function GT.logging.print(msg, logLevel, limit, forceDefaultChatFrame)
	if logLevel == nil then
		logLevel = GT.logging.state.logLevelDefault
	end
	local color = '7f7f7f'
	if GT.logging.initialized then
		color = LOG_COLOR_MAP[logLevel]
	end
	if msg == nil then
		msg = 'nil'
	end

	local chatFrame = _G['ChatFrame1']
	if GT.logging.initialized then
		if forceDefaultChatFrame then
			chatFrame = GT.database.getChatFrame(1)
		else
			chatFrame = GT.database.getChatFrame()
		end
	end

	if not GT.logging.initialized or logLevel < GT.logging.state.logLevelFilter then
		-- Send it to the archive but don't print it.
		return
	end

	if type(msg) == 'table' then
		GT.logging._printTable(msg, color, 0, limit)
		return
	end

	if logLevel < GT.logging.PLAYER_INFO then
		msg = string.gsub(msg, '%|r', '')
		local startColorIndex, endColorIndex = string.find(msg, '%|cff')
		while startColorIndex do
			local colorString = string.sub(msg, startColorIndex, endColorIndex + 6)
			msg = string.gsub(msg, colorString, '', 1)
			startColorIndex, endColorIndex = string.find(msg, '%|cff')
		end

		if string.find(msg, '%|H') then
			local tempMessage = nil
			local tokens = GT.textUtils.tokenize(msg, GT.comm.DELIMITER)
			for _, token in pairs(tokens) do
				itemString, itemName = token:match("|H(.*)|h%[(.*)%]|h")
				if itemName ~= nil then
					tempMessage = GT.textUtils.concat(tempMessage, GT.comm.DELIMITER, '[' .. itemName .. ']')
				else
					tempMessage = GT.textUtils.concat(tempMessage, GT.comm.DELIMITER, token)
				end
			end
			msg = tempMessage
		end

		if #msg >= GT.logging.LOG_LINE_LENGTH_LIMIT then
			msg = string.sub(msg, 1, GT.logging.LOG_LINE_LENGTH_LIMIT - 3) .. '...'
		end
	end

	msg = string.gsub(GT.logging.LOG_FORMAT, '%{{message}}', msg)
	msg = string.gsub(msg, '%{{tag}}', GT.L['LOG_TAG'])
	msg = string.gsub(msg, '%{{start_color}}', color)
	if color == '' then
		msg = string.gsub(msg, '%{{end_color}}', '')
	else
		msg = string.gsub(msg, '%{{end_color}}', '|r')
	end
	chatFrame:AddMessage(msg)
end

function GT.logging._printTable(tbl, color, depth, limit)
	if limit ~= nil and depth >= limit then
		return
	end
	local spacing = ''
	local i = 0
	while i < depth do
		spacing = spacing .. GT.logging.TABLE_SPACING
		i = i + 1
	end
	i = 0
	for k, v in pairs(tbl) do
		if type(v) == 'table' then
			print(spacing .. GT.L['LOG_TAG'] .. '|cff' .. color .. k .. '|r')
			GT.logging._printTable(v, color, depth + 1, limit)
		elseif type(v) == 'function' then
			print(GT.L['LOG_TAG'] .. '|cff' .. color .. spacing .. type(v) .. '|r')
		elseif type(v) == 'boolean' then
			if v then
				print(GT.L['LOG_TAG'] .. '|cff' .. color .. spacing  .. 'true|r')
			else
				print(GT.L['LOG_TAG'] .. '|cff' .. color .. spacing  .. 'false|r')
			end
		else
			if type(k) == 'table' then
				GT.logging._printTable(k, color, depth + 1, limit)
			else
				print(spacing .. GT.L['LOG_TAG'] .. '|cff' .. color .. k .. ', ' .. v .. '|r')
			end
		end
		i = i + 1
	end
	if i <= 0 then
		print(spacing .. GT.L['LOG_TAG'] .. '|cff' .. color .. 'Empty|r')
	end
end

function GT.logging.info(msg, limit, forceDefaultChatFrame)
	GT.logging.print(msg, GT.logging.INFO, limit, forceDefaultChatFrame)
end

function GT.logging.debug(msg, limit, forceDefaultChatFrame)
	GT.logging.print(msg, GT.logging.DEBUG, limit, forceDefaultChatFrame)
end

function GT.logging.warn(msg, limit, forceDefaultChatFrame)
	GT.logging.print(msg, GT.logging.WARN, limit, forceDefaultChatFrame)
end

function GT.logging.error(msg, limit, forceDefaultChatFrame)
	GT.logging.print(msg, GT.logging.ERROR, limit, forceDefaultChatFrame)
end

function GT.logging.playerInfo(msg, limit, forceDefaultChatFrame)
	GT.logging.print(msg, GT.logging.PLAYER_INFO, limit, forceDefaultChatFrame)
end

function GT.logging.playerWarn(msg, limit, forceDefaultChatFrame)
	GT.logging.print(msg, GT.logging.PLAYER_WARN, limit, forceDefaultChatFrame)
end

function GT.logging.playerError(msg, limit, forceDefaultChatFrame)
	GT.logging.print(msg, GT.logging.PLAYER_ERROR, limit, forceDefaultChatFrame)
end

function GT.logging.reset()
	GT.logging.info('GT_Logging_Reset')
end

function GT.logging.setChatFrame(tokens)
	local frameName = tokens[1]
	if frameName then
		local frameSet = GT.database.setChatFrame(tokens[1])
		if frameSet then
			GT.logging.playerInfo(string.gsub(GT.L['CHAT_WINDOW_SUCCESS'], '%{{frame_name}}', frameName))
		else
			GT.logging.playerWarn(string.gsub(GT.L['CHAT_WINDOW_INVALID'], '%{{frame_name}}', frameName))
		end
	else
		GT.logging.playerWarn(GT.L['CHAT_WINDOW_NIL'])
	end
end