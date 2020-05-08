local GT_Name, GT = ...

GT.logging = {}
GT.logging.state = {}
GT.logging.initialized = false
GT.logging.TABLE_SPACING = '  '

local LOG_COLOR_MAP = {}

function GT.logging.init(force)
	if GT.logging.initialized and not force then
		return
	end
	GT.logging.INFO = 0
	GT.logging.DEBUG = 1
	GT.logging.WARN = 2
	GT.logging.ERROR = 3
	GT.logging.PLAYER_INFO = 4
	GT.logging.PLAYER_WARN = 5
	GT.logging.PLAYER_ERROR = 6

	GT.logging.PLAYER = GT.logging.PLAYER_INFO

	GT.logging.state.logLevelFilter = GT.logging.PLAYER_INFO
	--@debug@ 
	GT.logging.state.logLevelFilter = GT.logging.INFO
	--@end-debug@
	GT.logging.state.logLevelDefault = GT.logging.INFO

	LOG_COLOR_MAP[GT.logging.INFO] = '7f7f7f'
	LOG_COLOR_MAP[GT.logging.DEBUG] = 'ffffff'
	LOG_COLOR_MAP[GT.logging.WARN] = 'ff9900'
	LOG_COLOR_MAP[GT.logging.ERROR] = 'ff9900'
	LOG_COLOR_MAP[GT.logging.PLAYER_INFO] = 'ffffff'
	LOG_COLOR_MAP[GT.logging.PLAYER_WARN] = 'ff9900'
	LOG_COLOR_MAP[GT.logging.PLAYER_ERROR] = 'ff9900'

	GT.logging.info('GT_Logging_Init')

	GT.logging.initialized = true
end

function GT.logging.print(msg, logLevel, limit)
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
	if GT.logging.initialized and logLevel >= GT.logging.state.logLevelFilter then
		if type(msg) == 'table' then
			GT.logging._printTable(msg, color, 0, limit)
		else
			print(GT.L['CHAT_TAG'] .. '|cff' .. color .. msg .. '|r')
		end
	else
		-- if type(msg) == 'table' then
		-- 	GT.logging._printTable(msg, color, 0, limit)
		-- else
		-- 	print(GT.L['CHAT_TAG'] .. '|cff' .. color .. msg .. '|r')
		-- end
	end
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
			print(spacing .. GT.L['CHAT_TAG'] .. '|cff' .. color .. k .. '|r')
			GT.logging._printTable(v, color, depth + 1, limit)
		else
			if type(v) == 'boolean' then
				if v then
					v = 'true'
				else
					v = 'false'
				end
			end
			print(spacing .. GT.L['CHAT_TAG'] .. '|cff' .. color .. k .. ', ' .. v .. '|r')
		end
		i = i + 1
	end
	if i <= 0 then
		print(spacing .. GT.L['CHAT_TAG'] .. '|cff' .. color .. 'Empty|r')
	end
end

function GT.logging.info(msg, limit)
	GT.logging.print(msg, GT.logging.INFO, limit)
end

function GT.logging.debug(msg, limit)
	GT.logging.print(msg, GT.logging.DEBUG, limit)
end

function GT.logging.warn(msg, limit)
	GT.logging.print(msg, GT.logging.WARN, limit)
end

function GT.logging.error(msg, limit)
	GT.logging.print(msg, GT.logging.ERROR, limit)
end

function GT.logging.playerInfo(msg, limit)
	GT.logging.print(msg, GT.logging.PLAYER_INFO, limit)
end

function GT.logging.playerWarn(msg, limit)
	GT.logging.print(msg, GT.logging.PLAYER_WARN, limit)
end

function GT.logging.playerError(msg, limit)
	GT.logging.print(msg, GT.logging.PLAYER_ERROR, limit)
end

function GT.logging.reset()
	GT.logging.info('GT_Logging_Reset')
end