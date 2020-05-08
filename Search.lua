local GT_Name, GT = ...
RCC = RAID_CLASS_COLORS

GT.search = {}
GT.search.mainFrame = nil
GT.search.skillScrollFrame = nil
GT.search.reagentScrollFrame = nil
GT.search.characterScrollFrame = nil

GT.search.lastSkillClicked = nil
GT.search.lastSkillLinkClicked = nil
GT.search.lastReagentClicked = nil
GT.search.lastCharacterClicked = nil

GT.search.skillSearchText = nil
GT.search.reagentSearchText = nil
GT.search.characterSearchText = nil

GT.search.skillSearchBox = nil
GT.search.reagentSearchBox = nil
GT.search.characterSearchBox = nil

local AceGUI = LibStub('AceGUI-3.0')

local PROFESSIONS = {}

function GT.search.init()
	PROFESSIONS = {
		GT.L['ALCHEMY'],
		GT.L['BLACKSMITHING'],
		GT.L['ENCHANTING'],
		GT.L['ENGINEERING'],
		GT.L['LEATHERWORKING'],
		GT.L['TAILORING'],
		GT.L['COOKING']
	}
end

function GT.search.openSearch(tokens)
	GT.logging.info('GT_Search_OpenSearch: ' .. table.concat(tokens, ', '))
	if GT.search.state == nil then
		GT.search.state = {}
	end
	if GT.search.state.professions == nil then
		GT.search.state.professions = {}
	end

	if GT.search.mainFrame ~= nil then
		GT.search.mainFrame:Hide()
		GT.search.mainFrame = nil
		GT.search.skillScrollFrame = nil
		GT.search.reagentScrollFrame = nil
		GT.search.characterScrollFrame = nil
		return
	end

	local mainFrame = AceGUI:Create('Frame')
	mainFrame:SetCallback('OnClose',function(widget) AceGUI:Release(widget) end)
	mainFrame:SetTitle(GT.L['LONG_TAG'])
	mainFrame:SetLayout('Flow')
	mainFrame:ClearAllPoints()
	mainFrame:SetCallback('OnClose', function()
		GT.search.lastSkillClicked = nil
		GT.search.lastSkillLinkClicked = nil
		GT.search.lastReagentClicked = nil
		GT.search.lastCharacterClicked = nil

		GT.search.mainFrame = nil
		GT.search.skillScrollFrame = nil
		GT.search.reagentScrollFrame = nil
		GT.search.characterScrollFrame = nil
	end)
	_G['GT_SearchMainFrame'] = mainFrame.frame
	tinsert(UISpecialFrames, 'GT_SearchMainFrame')

	local editLine = AceGUI:Create('SimpleGroup')
	editLine:SetFullWidth(true)
	editLine:SetLayout('Flow')
	mainFrame:AddChild(editLine)

	local resetFiltersButton = AceGUI:Create('Button')
	resetFiltersButton:SetRelativeWidth(1/4)
	resetFiltersButton:SetText(GT.L['BUTTON_FILTERS_RESET'])
	resetFiltersButton:SetCallback('OnClick', function()
		GT.search.lastSkillClicked = nil
		GT.search.lastSkillLinkClicked = nil
		GT.search.lastReagentClicked = nil
		GT.search.lastCharacterClicked = nil

		GT.search.skillSearchBox:SetText(nil)
		GT.search.reagentSearchBox:SetText(nil)
		GT.search.characterSearchBox:SetText(nil)

		GT.search.populateSkills(true)
	end)
	editLine:AddChild(resetFiltersButton)

	local skillSearchContainer = AceGUI:Create('SimpleGroup')
	skillSearchContainer:SetRelativeWidth(1/4)
	skillSearchContainer:SetHeight(40)
	skillSearchContainer:SetLayout('Fill')
	editLine:AddChild(skillSearchContainer)
	skillSearchContainer:ClearAllPoints()

	local skillSearchBox = AceGUI:Create('EditBox')
	skillSearchBox:SetLabel(GT.L['SEARCH_SKILLS'])
	skillSearchBox:DisableButton(true)
	if GT.search.skillSearchText ~= nil then
		skillSearchBox:SetText(GT.search.skillSearchText)
	end
	skillSearchBox:SetCallback('OnTextChanged', function(widget, event, value)
		GT.search.skillSearchText = value
		GT.search.populateSkills(true)
	end)
	skillSearchContainer:AddChild(skillSearchBox)
	skillSearchBox:ClearAllPoints()
	GT.search.skillSearchBox = skillSearchBox

	local reagentSearchContainer = AceGUI:Create('SimpleGroup')
	reagentSearchContainer:SetRelativeWidth(1/4)
	reagentSearchContainer:SetHeight(40)
	reagentSearchContainer:SetLayout('Fill')
	editLine:AddChild(reagentSearchContainer)
	reagentSearchContainer:ClearAllPoints()

	local reagentSearchBox = AceGUI:Create('EditBox')
	reagentSearchBox:SetLabel(GT.L['SEARCH_REAGENTS'])
	reagentSearchBox:DisableButton(true)
	if GT.search.reagentSearchText ~= nil then
		reagentSearchBox:SetText(GT.search.reagentSearchText, true)
	end
	reagentSearchBox:SetCallback('OnTextChanged', function(widget, event, value)
		GT.search.reagentSearchText = value
		GT.search.populateReagents(true)
	end)
	reagentSearchContainer:AddChild(reagentSearchBox)
	reagentSearchBox:ClearAllPoints()
	GT.search.reagentSearchBox = reagentSearchBox

	local characterSearchContainer = AceGUI:Create('SimpleGroup')
	characterSearchContainer:SetRelativeWidth(1/4)
	characterSearchContainer:SetHeight(40)
	characterSearchContainer:SetLayout('Fill')
	editLine:AddChild(characterSearchContainer)
	characterSearchContainer:ClearAllPoints()

	local characterSearchBox = AceGUI:Create('EditBox')
	characterSearchBox:SetLabel(GT.L['SEARCH_CHARACTERS'])
	characterSearchBox:DisableButton(true)
	if GT.search.characterSearchText ~= nil then
		characterSearchBox:SetText(GT.search.characterSearchText)
	end
	characterSearchBox:SetCallback('OnTextChanged', function(widget, event, value)
		GT.search.characterSearchText = value
		GT.search.lastSkillClicked = nil
		GT.search.lastSkillLinkClicked = nil
		GT.search.lastReagentClicked = nil
		GT.search.lastCharacterClicked = nil
		GT.search.populateCharacters(true)
	end)
	characterSearchContainer:AddChild(characterSearchBox)
	characterSearchBox:ClearAllPoints()
	GT.search.characterSearchBox = characterSearchBox

	local labelLine = AceGUI:Create('SimpleGroup')
	labelLine:SetFullWidth(true)
	labelLine:SetLayout('Flow')
	mainFrame:AddChild(labelLine)

	local profLabel = AceGUI:Create('Label')
	profLabel:SetText('Professions')
	profLabel:SetRelativeWidth(1/4)
	profLabel:SetColor(255, 255, 0)
	labelLine:AddChild(profLabel)
	profLabel:ClearAllPoints()

	local skillLabel = AceGUI:Create('Label')
	skillLabel:SetText(GT.L['LABEL_SKILLS'])
	skillLabel:SetRelativeWidth(1/4)
	skillLabel:SetColor(255, 255, 0)
	labelLine:AddChild(skillLabel)
	skillLabel:ClearAllPoints()

	local reagentLabel = AceGUI:Create('Label')
	reagentLabel:SetText(GT.L['LABEL_REAGENTS'])
	reagentLabel:SetRelativeWidth(1/4)
	reagentLabel:SetColor(255, 255, 0)
	labelLine:AddChild(reagentLabel)
	reagentLabel:ClearAllPoints()

	local characterLabel = AceGUI:Create('Label')
	characterLabel:SetText(GT.L['LABEL_CHARACTERS'])
	characterLabel:SetRelativeWidth(1/4)
	characterLabel:SetColor(255, 255, 0)
	labelLine:AddChild(characterLabel)
	characterLabel:ClearAllPoints()
	characterLabel:SetPoint('RIGHT')

	local profScrollContainer = AceGUI:Create('SimpleGroup')
	profScrollContainer:SetRelativeWidth(1/4)
	profScrollContainer:SetFullHeight(true)
	profScrollContainer:SetLayout('Fill')
	mainFrame:AddChild(profScrollContainer)
	profScrollContainer:ClearAllPoints()

	local profScrollFrame = AceGUI:Create('ScrollFrame')
	profScrollFrame:SetFullWidth(true)
	profScrollFrame:SetFullHeight(true)
	profScrollFrame:SetLayout('Flow')
	profScrollContainer:AddChild(profScrollFrame)

	for _, profName in pairs(PROFESSIONS) do
		local profCheckBox = AceGUI:Create('CheckBox')
		profCheckBox:SetFullWidth(true)
		profCheckBox:SetLabel(profName)
		local checked = true
		if GT.search.state.professions[profName] == nil then
			GT.search.state.professions[profName] = true
		else
			checked = GT.search.state.professions[profName]
		end
		profCheckBox:SetValue(checked)
		profCheckBox:SetCallback('OnValueChanged', function(widget, callback, value)
			local professionName = widget.text:GetText()
			GT.search.lastSkillClicked = nil
			GT.search.lastSkillLinkClicked = nil
			GT.search.lastReagentClicked = nil
			GT.search.lastCharacterClicked = nil
			GT.search.state.professions[professionName] = value
			GT.search.populateSkills(true)
		end)
		profScrollFrame:AddChild(profCheckBox)
	end

	local skillScrollContainer = AceGUI:Create('SimpleGroup')
	skillScrollContainer:SetRelativeWidth(1/4)
	skillScrollContainer:SetFullHeight(true)
	skillScrollContainer:SetLayout('Fill')
	mainFrame:AddChild(skillScrollContainer)
	skillScrollContainer:ClearAllPoints()

	local skillScrollFrame = AceGUI:Create('ScrollFrame')
	skillScrollFrame:SetLayout('Flow')
	skillScrollContainer:AddChild(skillScrollFrame)

	local reagentScrollContainer = AceGUI:Create('SimpleGroup')
	reagentScrollContainer:SetRelativeWidth(1/4)
	reagentScrollContainer:SetFullHeight(true)
	reagentScrollContainer:SetLayout('Fill')
	mainFrame:AddChild(reagentScrollContainer)
	reagentScrollContainer:ClearAllPoints()

	local reagentScrollFrame = AceGUI:Create('ScrollFrame')
	reagentScrollFrame:SetLayout('Flow')
	reagentScrollContainer:AddChild(reagentScrollFrame)

	local characterScrollContainer = AceGUI:Create('SimpleGroup')
	characterScrollContainer:SetRelativeWidth(1/4)
	characterScrollContainer:SetFullHeight(true)
	characterScrollContainer:SetLayout('Fill')
	mainFrame:AddChild(characterScrollContainer)
	characterScrollContainer:SetPoint('RIGHT')

	local characterScrollFrame = AceGUI:Create('ScrollFrame')
	characterScrollFrame:SetLayout('Flow')
	characterScrollContainer:AddChild(characterScrollFrame)

	GT.search.mainFrame = mainFrame
	GT.search.skillScrollFrame = skillScrollFrame
	GT.search.reagentScrollFrame = reagentScrollFrame
	GT.search.characterScrollFrame = characterScrollFrame

	GT.search.populateSkills(true)
end

function GT.search.populateSkills(shouldCascade)
	GT.logging.info('GT_Search_PopulateSkills: ' .. GT.textUtils.textValue(shouldCascade))

	GT.search.skillScrollFrame:ReleaseChildren()

	local characters = GT.database.getGuild(
		GT_Character.realmName,
		GT_Character.factionName,
		GT_Character.guildName
	).characters

	skillsToAdd = {}
	if GT.search.lastReagentClicked ~= nil then
		for characterName, _ in pairs(characters) do
			local professions = characters[characterName].professions
			for professionName, _ in pairs(professions) do
				if GT.search.state.professions[professionName] then
					local skills = professions[professionName].skills
					for skillName, _ in pairs(skills) do
						local reagents = skills[skillName].reagents
						for reagentName, _ in pairs(reagents) do
							if reagentName == GT.search.lastReagentClicked then
								local skill = skills[skillName]
								local tempSkillName = GT.textUtils.getTextBetween(skill.skillLink, '%[', ']')
								local searchMatch = true
								if GT.search.skillSearchText ~= nil and not string.find(string.lower(tempSkillName), string.lower(GT.search.skillSearchText)) then
									searchMatch = false
								end
								if not GT.tableUtils.tableContains(skillsToAdd, tempSkillName) and searchMatch then
									skillsToAdd[tempSkillName] = skill.skillLink
								end
							end
						end
					end
				end
			end
		end
	elseif GT.search.lastCharacterClicked ~= nil then
		for characterName, _ in pairs(characters) do
			local professions = characters[characterName].professions
			for professionName, _ in pairs(professions) do
				if GT.search.state.professions[professionName] then
					local skills = professions[professionName].skills
					for skillName, _ in pairs(skills) do
						local skill = skills[skillName]
						local tempSkillName = GT.textUtils.getTextBetween(skill.skillLink, '%[', ']')
						local searchMatch = true
						if GT.search.skillSearchText ~= nil and not string.find(string.lower(tempSkillName), string.lower(GT.search.skillSearchText)) then
							searchMatch = false
						end
						if not GT.tableUtils.tableContains(skillsToAdd, tempSkillName) and searchMatch then
							skillsToAdd[tempSkillName] = skill.skillLink
						end
					end
				end
			end
		end
	else
		for characterName, _ in pairs(characters) do
			local professions = characters[characterName].professions
			for professionName, _ in pairs(professions) do
				if GT.search.state.professions[professionName] then
					local skills = professions[professionName].skills
					for skillName, _ in pairs(skills) do
						local skill = skills[skillName]
						local tempSkillName = GT.textUtils.getTextBetween(skill.skillLink, '%[', ']')
						local searchMatch = true
						if GT.search.skillSearchText ~= nil and not string.find(string.lower(tempSkillName), string.lower(GT.search.skillSearchText)) then
							searchMatch = false
						end
						if not GT.tableUtils.tableContains(skillsToAdd, tempSkillName) and searchMatch then
							skillsToAdd[tempSkillName] = skill.skillLink
						end
					end
				end
			end
		end
	end

	local sortedKeys = GT.tableUtils.getSortedKeys(skillsToAdd, function(a, b) return a < b end, true)
	for _, key in ipairs(sortedKeys) do
		local skillLink = skillsToAdd[key]
		local skillLabel = AceGUI:Create('InteractiveLabel')
		skillLabel:SetText(skillLink)
		skillLabel:SetHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		skillLabel:SetCallback('OnClick', function(widget, event, button)
			local skillLink = widget.label:GetText()
			local skillName = GT.textUtils.getTextBetween(skillLink, '%[', ']')

			GT.search.lastSkillClicked = skillName
			GT.search.lastSkillLinkClicked = skillLink
			GT.search.lastReagentClicked = nil
			GT.search.lastCharacterClicked = nil

			GT.search.populateReagents(false)
			GT.search.populateCharacters(false)
		end) 
		GT.search.skillScrollFrame:AddChild(skillLabel)
	end

	if shouldCascade then
		GT.search.populateReagents(false)
		GT.search.populateCharacters(false)
	end
end

function GT.search.populateReagents(shouldCascade)
	GT.logging.info('GT_Search_PopulateReagents: ' .. GT.textUtils.textValue(shouldCascade))

	if GT.search.lastReagentClicked == nil then
		GT.search.reagentScrollFrame:ReleaseChildren()
	end

	local reagentsToAdd = {}
	if GT.search.lastSkillClicked ~= nil then
		local characters = GT.database.getGuild(
			GT_Character.realmName,
			GT_Character.factionName,
			GT_Character.guildName
		).characters
		local reagentsAdded = false
		for characterName, _ in pairs(characters) do
			if not reagentsAdded then
				local professions = characters[characterName].professions
				for professionName, _ in pairs(professions) do
					local skills = professions[professionName].skills
					for skillName, _ in pairs(skills) do
						local skill = skills[skillName]
						local tempSkillName = GT.textUtils.getTextBetween(skill.skillLink, '%[', ']')
						if tempSkillName == GT.search.lastSkillClicked then
							local reagents = skills[skillName].reagents
							for reagentName, _ in pairs(reagents) do
								local searchMatch = true
								if GT.search.reagentSearchText ~= nil and not string.find(string.lower(reagentName), string.lower(GT.search.reagentSearchText)) then
									searchMatch = false
								end
								if searchMatch then
									local reagent = reagents[reagentName]
									reagentsToAdd[reagent.reagentName] = reagent.reagentCount
								end
							end
							reagentsAdded = true
						end
					end
					if reagentsAdded then
						break
					end
				end
			end
			if reagentsAdded then
				break
			end
		end
	elseif GT.search.lastCharacterClicked ~= nil then
	elseif GT.search.lastReagentClicked ~= nil then
	else
		local characters = GT.database.getGuild(
			GT_Character.realmName,
			GT_Character.factionName,
			GT_Character.guildName
		).characters
		local reagentsAdded = false
		for characterName, _ in pairs(characters) do
			if not reagentsAdded then
				local professions = characters[characterName].professions
				for professionName, _ in pairs(professions) do
					local skills = professions[professionName].skills
					for skillName, _ in pairs(skills) do
						local skill = skills[skillName]
						local tempSkillName = GT.textUtils.getTextBetween(skill.skillLink, '%[', ']')
						if tempSkillName == GT.search.lastSkillClicked then
							local reagents = skills[skillName].reagents
							for reagentName, _ in pairs(reagents) do
								local searchMatch = false
								if GT.search.reagentSearchText ~= nil and string.find(string.lower(reagentName), string.lower(GT.search.reagentSearchText)) then
									searchMatch = true
								end
								if searchMatch then
									local reagent = reagents[reagentName]
									reagentsToAdd[reagent.reagentName] = reagent.reagentCount
								end
							end
							reagentsAdded = true
						end
					end
					if reagentsAdded then
						break
					end
				end
			end
			if reagentsAdded then
				break
			end
		end
	end

	local sortedKeys = GT.tableUtils.getSortedKeys(reagentsToAdd, function(a, b) return a < b end, true)
	for _, reagentName in ipairs(sortedKeys) do
		local reagentCount = reagentsToAdd[reagentName]
		local reagentLabel = AceGUI:Create('InteractiveLabel')
		reagentLabel:SetText(reagentName .. ' (' .. reagentCount .. ')')
		reagentLabel:SetHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		reagentLabel:SetCallback('OnClick', function(widget, event, button)
			local text = widget.label:GetText()
			local tokens = GT.textUtils.tokenize(text, ' ')
			table.remove(tokens, #tokens)
			local reagentName = table.concat(tokens, ' ')

			GT.search.lastSkillClicked = nil
			GT.search.lastSkillLinkClicked = nil
			GT.search.lastReagentClicked = reagentName
			GT.search.lastCharacterClicked = nil

			GT.search.populateSkills(false)
			GT.search.populateCharacters(false)
		end)
		GT.search.reagentScrollFrame:AddChild(reagentLabel)
	end
	if shouldCascade then
		GT.search.populateSkills(false)
		GT.search.populateCharacters(false)
	end
end

function GT.search.populateCharacters(shouldCascade)
	GT.logging.info('GT_Search_PopulateCharacters: ' .. GT.textUtils.textValue(shouldCascade))

	if GT.search.lastCharacterClicked == nil then
		GT.search.characterScrollFrame:ReleaseChildren()
	end

	local charactersToAdd = {}
	if GT.search.lastSkillClicked ~= nil then
		local characters = GT.database.getGuild(
			GT_Character.realmName,
			GT_Character.factionName,
			GT_Character.guildName
		).characters
		for characterName, _ in pairs(characters) do
			local addCharacter = false
			local professions = characters[characterName].professions
			for professionName, _ in pairs(professions) do
				local skills = professions[professionName].skills
				for skillName, _ in pairs(skills) do
					local skill = skills[skillName]
					local tempSkillName = GT.textUtils.getTextBetween(skill.skillLink, '%[', ']')
					if tempSkillName == GT.search.lastSkillClicked then
						addCharacter = true
						break
					end
				end
			end
			if addCharacter and not GT.tableUtils.tableContains(charactersToAdd, characterName) then
				table.insert(charactersToAdd, characterName)
			end
		end
	elseif GT.search.lastReagentClicked ~= nil then
	elseif GT.search.lastCharacterClicked ~= nil then
	else
		local characters = GT.database.getGuild(
			GT_Character.realmName,
			GT_Character.factionName,
			GT_Character.guildName
		).characters
		for characterName, _ in pairs(characters) do
			local searchMatch = false
			if GT.search.characterSearchText ~= nil and string.find(string.lower(characterName), string.lower(GT.search.characterSearchText)) then
				searchMatch = true
			end
			if searchMatch and not GT.tableUtils.tableContains(charactersToAdd, characterName) then
				table.insert(charactersToAdd, characterName)
			end
		end
	end

	local onlineGuildMembers = {}
	local classColors = {}
	local countTotalMembers, countOnlineMembers = GetNumGuildMembers()
	for i=1,countTotalMembers do
		local characterName, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(i)
		if online then
			characterName = GT.textUtils.convertCharacterName(characterName)
			table.insert(onlineGuildMembers, characterName)
			classColors[characterName] = RCC[string.upper(class)]['colorStr']
		end
	end

	local sortedKeys = GT.tableUtils.getSortedKeys(charactersToAdd, function(a, b) return a < b end)
	for _, key in ipairs(sortedKeys) do
		local characterName = charactersToAdd[key]
		local characterLabel = AceGUI:Create('InteractiveLabel')
		local labelText = string.gsub(GT.L['GUILD_OFFLINE'], '%{{guild_member}}', characterName)
		if GT.tableUtils.tableContains(onlineGuildMembers, characterName) then
			labelText = string.gsub(GT.L['GUILD_ONLINE'], '%{{guild_member}}', characterName)
			labelText = string.gsub(labelText, '%{{class_color}}', classColors[characterName])
		end
		characterLabel:SetText(labelText)
		characterLabel:SetHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		characterLabel:SetCallback('OnClick', function(widget, event, button)
			local labelText = widget.label:GetText()
			local characterName = GT.textUtils.convertCharacterName(labelText)
			characterName = string.sub(characterName, 11)
			characterName = string.sub(characterName, 0, #characterName - 3)
			if button == 'RightButton' then
				local online = string.gsub(labelText, characterName, '')
				online = string.gsub(online, '- ' , '')
				online = string.sub(online, 24)
				online = string.sub(online, 0, #online - 2)
				if string.lower(online) == 'online' and GT.search.lastSkillLinkClicked ~= nil then
					local msg = GT.L['WHISPER_REQUEST']
					msg = string.gsub(msg, '%{{character_name}}', characterName)
					msg = string.gsub(msg, '%{{item_link}}', GT.search.lastSkillLinkClicked)

					local whisperSent = false
					local totalGuildMembers = GetNumGuildMembers()
					for i = 1, totalGuildMembers do
						local guildCharacterName, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(i)
						local tempCharacterName = GT.textUtils.convertCharacterName(guildCharacterName)
						if online and tempCharacterName == characterName then
							SendChatMessage(msg, 'WHISPER', 7, guildCharacterName)
							whisperSent = true
						end
					end
					if not whisperSent then
						GT.logging.playerWarn(string.gsub(GT.L['WHISPER_NO_CHARACTER_FOUND'], '%{{character_name}}', characterName))
					end

				elseif GT.search.lastSkillLinkClicked == nil then
					GT.logging.playerWarn(GT.L['WHISPER_SELECT_REQUIRED'])
				end
			end
			
			GT.search.lastSkillClicked = nil
			GT.search.lastSkillLinkClicked = nil
			GT.search.lastReagentClicked = nil
			GT.search.lastCharacterClicked = characterName
			GT.search.populateSkills(false)
			GT.search.populateReagents(false)
		end)
		GT.search.characterScrollFrame:AddChild(characterLabel)
	end

	if shouldCascade then
		GT.search.populateSkills(false)
		GT.search.populateReagents(false)
	end
end