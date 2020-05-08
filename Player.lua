local GT_Name, GT = ...

GT.player = {}
GT.player.state = {}
GT.player.state.initialized = false
GT.player.state.currentCharacter = nil

function GT.player.init(force)
	if GT.player.state.initialized and not force then
		return
	end
	GT.logging.info('GT_Player_Init')

	if GT_Character == nil then
		GT.logging.info('Current character is nil. Creating it.')
		GT_Character = {}
	end

	if GT_Character.search == nil then
		GT_Character.search = {}
	end

	local realmName = GetRealmName()
	if realmName == nil then
		GT.logging.error('Realm name is nil.')
		return
	elseif GT_Character.realm == nil then
		GT.logging.info('Updating character realm: ' .. realmName)
		GT_Character.realmName = realmName
	end

	local _, factionName = UnitFactionGroup('player')
	if factionName == nil then
		GT.logging.error('Faction is nil.')
	elseif GT_Character.faction == nil then
		GT.logging.info('Updating character faction: ' .. factionName)
		GT_Character.factionName = factionName
	end
	local guildName = GetGuildInfo('player')
	if guildName == nil then
		GT.logging.error('Guild is nil.')
	elseif GT_Character.guildName == nil then
		GT.logging.info('Updating character guild: ' .. guildName)
		GT_Character.guildName = guildName
	end

	local characterName = UnitName('player')
	if GT_Character.characterName == nil then
		GT.logging.info('Updating character name: ' .. characterName)
		GT_Character.characterName = characterName
	end

	GT.logging.info('Setting current character: ' .. GT_Character.characterName)
	GT.player.state.currentCharacter = GT.database.getCharacter(
		realmName,
		factionName,
		guildName,
		playerName
	)

	GT.player.state.initialized = true
end

function GT.player.guildUpdate()
	local guildName = GetGuildInfo('player')
	if guildName ~= nil then
		GT.logging.info('Updating character guild: ' .. guildName)
		GT_Character.guildName = guildName
	end
end

function GT.player.reset()
	GT.logging.info('GT_Player_Reset')
	GT_Character = nil
	GT.player.init(true)
end