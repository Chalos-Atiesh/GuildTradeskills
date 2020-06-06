local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local CommValidator = GT:NewModule('CommValidator')
GT.CommValidator = CommValidator

function CommValidator:IsOutgoingRequestValid(characterName, nilTemplate, notSelfTemplate, notGuildTemplate)
	if characterName == nil then
		GT.Log:PlayerWarn(nilTemplate)
		return false
	end

	if GT:IsCurrentCharacter(characterName) then
		GT.Log:PlayerWarn(notSelfTemplate)
		return false
	end

	if GT:IsGuildMember(characterName) then
		local message = string.gsub(notGuildTemplate, '%{{character_name}}', characterName)
		GT.Log:PlayerWarn(message)
		return false
	end

	if GT.DBComm:IsIgnored(GT.CommWhisper.INCOMING, uuid, characterName) then
		-- We were ignored by them.
		local message = string.gsub(GT.L['IGNORE_INCOMING'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)
		return false
	end
	return true
end

function CommValidator:IsIncomingRequestValid(distribution, sender, uuid)
	if distribution ~= GT.Comm.WHISPER then
		GT.Log:Error('CommValidator_IsIncomingRequestValid_InvalidDistribution', distribution, sender, uuid)
		return false
	end

	if sender == nil then
		GT.Log:Error('CommValidator_IsIncomingRequestValid_SenderNil', uuid)
		return false
	end

	if not Text:IsUUIDValid(uuid) then
		GT.Log:Error('CommValidator_IsIncomingRequestValid_InvalidUUID', sender, uuid)
		return false
	end

	if GT:IsCurrentCharacter(sender) then
		GT.Log:Error('CommValidator_IsIncomingRequestValid_FromSelf', sender, uuid)
		return false
	end

	if GT:IsGuildMember(sender) then
		GT.Log:Warn('CommValidator_IsIncomingRequestValid_FromGuildmate', sender, uuid)
		return false
	end

	if GT.DBComm:IsIgnored(CommWhisper.OUTGOING, uuid, sender) then
		GT.Log:Info('CommWhisper_OnRequestReceived_Ignored', sender, uuid)
		return false
	end
	return true
end

function CommValidator:IsTimestampValid(message)
	-- GT.Log:Info('CommValidator_IsTimestampValid', message)
	local tokens = Text:Tokenize(message, GT.Comm.DELIMITER)
	
	while #tokens > 0 do
		local characterName, tokens = Table:RemoveToken(tokens)
		local professionName, tokens = Table:RemoveToken(tokens)
		local lastUpdate, tokens = Table:RemoveToken(tokens)

		if characterName == nil
			or tonumber(characterName) ~= nil
			or string.find(characterName, ']')
		then
			GT.Log:Error('CommValidator_IsTimestampValidFormat_InvalidCharacterName', characterName)
			return false
		end

		if professionName == nil
			or tonumber(professionName) ~= nil
			or string.find(professionName, ']')
		then
			GT.Log:Error('CommValidator_IsTimestampValidFormat_InvalidProfessionName', professionName)
			return false
		end

		if lastUpdate == nil
			or tonumber(lastUpdate) == nil
			or string.find(lastUpdate, ']')
		then
			GT.Log:Error('CommValidator_IsTimestampValidFormat_InvalidTimestamp', lastUpdate)
			return false
		end
	end
	return true
end

function CommValidator:IsVoteValid(message)
	-- GT.Log:Info('CommValidator_IsVoteValid', message)
	local tokens = Text:Tokenize(message, GT.Comm.DELIMITER)
	
	while #tokens > 0 do
		local characterName, tokens = Table:RemoveToken(tokens)
		local professionName, tokens = Table:RemoveToken(tokens)
		local vote, tokens = Table:RemoveToken(tokens)

		if characterName == nil
			or tonumber(characterName) ~= nil
			or string.find(characterName, ']')
		then
			GT.Log:Error('CommValidator_IsVoteValid_InvalidCharacterName', characterName)
			return false
		end

		if professionName == nil
			or tonumber(professionName) ~= nil
			or string.find(characterName, ']')
		then
			GT.Log:Error('CommValidator_IsVoteValid_InvalidProfessionName', professionName)
			return false
		end

		if vote == nil
			or tonumber(vote) ~= nil
			or string.find(vote, ']')
		then
			GT.Log:Error('CommValidator_IsVoteValid_InvalidVoteName', vote)
			return false
		end
	end
	return true
end

function CommValidator:IsGetValid(message)
	-- GT.Log:Info('CommValidator_IsGetValid', message)
	local tokens = Text:Tokenize(message, GT.Comm.DELIMITER)

	while #tokens > 0 do
		local characterName, tokens = Table:RemoveToken(tokens)
		local professionName, tokens = Table:RemoveToken(tokens)

		if characterName == nil
			or tonumber(characterName) ~= nil
			or string.find(characterName, ']')
		then
			GT.Log:Error('CommValidator_IsGetValid_InvalidCharacterName', characterName)
			return false
		end

		if professionName == nil
			or tonumber(professionName) ~= nil
			or string.find(professionName, ']')
		then
			GT.Log:Error('CommValidator_IsGetValid_InvalidProfessionName', professionName)
			return false
		end
	end
	return true
end

function CommValidator:IsPostValid(message)
	-- GT.Log:Info('CommValidator_IsPostValid', message)
	local tokens = Text:Tokenize(message, GT.Comm.DELIMITER)
	
	local characterName, tokens = Table:RemoveToken(tokens)
	local professionName, tokens = Table:RemoveToken(tokens)
	local lastUpdate, tokens = Table:RemoveToken(tokens)

	-- GT.Log:Info('Comm_IsPostValidFormat_IntroCheck', characterName, professionName, lastUpdate)

	if characterName == nil then
		GT.Log:Error('Comm_IsPostValidFormat_NilCharacterName')
		return false
	end

	if professionName == nil
		or tonumber(professionName) ~= nil
		or string.find(professionName, ']')
	then
		GT.Log:Error('Comm_IsPostValidFormat_NilProfessionName')
		return false
	end

	if lastUpdate == nil
		or tonumber(lastUpdate) == nil
	then
		GT.Log:Error('Comm_IsPostValidFormat_InvalidLastUpdate', Text:ToString(lastUpdate))
		return false
	end

	-- GT.Log:Info('Comm_IsPostValidFormat_ValidIntro', characterName, professionName, lastUpdate)

	while #tokens > 0 do
		local skillName, tokens = Table:RemoveToken(tokens)
		local skillLink, tokens = Table:RemoveToken(tokens)
		local uniqueReagentCount, tokens = Table:RemoveToken(tokens)

		-- GT.Log:Info('Comm_IsPostValidFormat_SkillCheck', skillName, skillLink, Text:ToString(uniqueReagentCount))

		if skillName == nil
			or string.find(skillName, ']')
			or tonumber(skillName) ~= nil
		then
			GT.Log:Error('Comm_IsPostValidFormat_NilSkillName')
			return false
		end

		if skillLink == nil
			or not string.find(skillLink, ']')
			or tonumber(skillLink) ~= nil
		then
			GT.Log:Error('Comm_IsPostValidFormat_NilSkillLink')
			return false
		end

		if uniqueReagentCount == nil
			or tonumber(uniqueReagentCount) == nil
		then
			GT.Log:Error('Comm_IsPostValidFormat_InvalidReagentCount', Text:ToString(uniqueReagentCount))
			return false
		end
		uniqueReagentCount = tonumber(uniqueReagentCount)

		local actualReagentCount = 0
		for i = 1, uniqueReagentCount do
			local reagentName, tokens = Table:RemoveToken(tokens)
			local thisReagentCount, tokens = Table:RemoveToken(tokens)

			-- GT.Log:Info('Comm_IsPostValidFormat_ReagentCheck', reagentName, Text:ToString(thisReagentCount))

			if reagentName == nil
				or string.find(reagentName, ']')
				or tonumber(reagentName) ~= nil
			then
				GT.Log:Error('Comm_IsPostValidFormat_InvalidReagentName', Text:ToString(reagentName))
				return false
			end

			if thisReagentCount == nil
				or string.find(reagentName, ']')
				or tonumber(thisReagentCount) == nil then
				GT.Log:Error('Comm_IsPostValidFormat_InvalidReagentCount', Text:ToString(reagentCount))
				return false
			end
			actualReagentCount = actualReagentCount + 1
		end

		if tonumber(uniqueReagentCount) ~= actualReagentCount then
			GT.Log:Error('Comm_IsPostValidFormat_ReagentCountMismatch',uniqueReagentCount, actualReagentCount)
		end
	end
	return true
end