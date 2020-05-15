local AddOnName = ...
RCC = RAID_CLASS_COLORS

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnName, true)

local AceGUI = LibStub('AceGUI-3.0')

local Search = GT:NewModule('Search')
GT.Search = Search

Search.mainFrame = nil
Search.skillScrollFrame = nil
Search.reagentScrollFrame = nil
Search.characterScrollFrame = nil

Search.lastSkillClicked = nil
Search.lastSkillLinkClicked = nil
Search.lastReagentClicked = nil
Search.lastCharacterClicked = nil

Search.skillSearchText = nil
Search.reagentSearchText = nil
Search.characterSearchText = nil

Search.skillSearchBox = nil
Search.reagentSearchBox = nil
Search.characterSearchBox = nil

-- Who in the hell measures RGB values 0-1?
Search.labelR = 255/255
Search.labelG = 209/255
Search.labelB = 0

Search.scrollLimit = 200

local PROFESSIONS = {}

function Search:OnEnable()
	GT.Log:Info('Search_OnEnable')
	PROFESSIONS = {
		L['ALCHEMY'],
		L['BLACKSMITHING'],
		L['ENCHANTING'],
		L['ENGINEERING'],
		L['LEATHERWORKING'],
		L['TAILORING'],
		L['COOKING']
	}
end

function Search:OpenSearch(tokens)
	GT.Log:Info('Search_OpenSearch', tokens)
	if Search.state == nil then
		Search.state = {}
	end

	if Search.mainFrame ~= nil then
		Search.mainFrame:Hide()
		Search.mainFrame = nil
		Search.skillScrollFrame = nil
		Search.reagentScrollFrame = nil
		Search.characterScrollFrame = nil
		return
	end

	local mainFrame = AceGUI:Create('Frame')
	mainFrame:SetTitle(L['LONG_TAG'])
	mainFrame:SetLayout('Flow')
	mainFrame:ClearAllPoints()
	mainFrame:SetCallback('OnClose', function(widget)

		Search.lastSkillClicked = nil
		Search.lastSkillLinkClicked = nil
		Search.lastReagentClicked = nil
		Search.lastCharacterClicked = nil

		Search.mainFrame = nil
		Search.skillScrollFrame = nil
		Search.reagentScrollFrame = nil
		Search.characterScrollFrame = nil
		
		widget:ReleaseChildren()
		AceGUI:Release(widget)
	end)
	_G['GT_SearchMainFrame'] = mainFrame.frame
	tinsert(UISpecialFrames, 'GT_SearchMainFrame')

	local editLine = AceGUI:Create('SimpleGroup')
	editLine:SetFullWidth(true)
	editLine:SetLayout('Flow')
	mainFrame:AddChild(editLine)

	local resetFiltersButton = AceGUI:Create('Button')
	resetFiltersButton:SetRelativeWidth(1/4)
	resetFiltersButton:SetText(L['BUTTON_FILTERS_RESET'])
	resetFiltersButton:SetCallback('OnClick', function()
		Search.lastSkillClicked = nil
		Search.lastSkillLinkClicked = nil
		Search.lastReagentClicked = nil
		Search.lastCharacterClicked = nil

		Search.skillSearchBox:SetText(nil)
		Search.reagentSearchBox:SetText(nil)
		Search.characterSearchBox:SetText(nil)

		Search:PopulateSkills(true)
	end)
	editLine:AddChild(resetFiltersButton)

	local skillSearchContainer = AceGUI:Create('SimpleGroup')
	skillSearchContainer:SetRelativeWidth(1/4)
	skillSearchContainer:SetHeight(40)
	skillSearchContainer:SetLayout('Fill')
	editLine:AddChild(skillSearchContainer)
	skillSearchContainer:ClearAllPoints()

	local skillSearchBox = AceGUI:Create('EditBox')
	skillSearchBox:SetLabel(L['SEARCH_SKILLS'])
	skillSearchBox:DisableButton(true)
	if Search.skillSearchText ~= nil then
		skillSearchBox:SetText(Search.skillSearchText)
	end
	skillSearchBox:SetCallback('OnTextChanged', function(widget, event, value)
		Search.skillSearchText = value
		Search:PopulateSkills(true)
	end)
	skillSearchContainer:AddChild(skillSearchBox)
	skillSearchBox:ClearAllPoints()
	Search.skillSearchBox = skillSearchBox

	local reagentSearchContainer = AceGUI:Create('SimpleGroup')
	reagentSearchContainer:SetRelativeWidth(1/4)
	reagentSearchContainer:SetHeight(40)
	reagentSearchContainer:SetLayout('Fill')
	editLine:AddChild(reagentSearchContainer)
	reagentSearchContainer:ClearAllPoints()

	local reagentSearchBox = AceGUI:Create('EditBox')
	reagentSearchBox:SetLabel(L['SEARCH_REAGENTS'])
	reagentSearchBox:DisableButton(true)
	if Search.reagentSearchText ~= nil then
		reagentSearchBox:SetText(Search.reagentSearchText, true)
	end
	reagentSearchBox:SetCallback('OnTextChanged', function(widget, event, value)
		Search.reagentSearchText = value
		Search:PopulateReagents(true)
	end)
	reagentSearchContainer:AddChild(reagentSearchBox)
	reagentSearchBox:ClearAllPoints()
	Search.reagentSearchBox = reagentSearchBox

	local characterSearchContainer = AceGUI:Create('SimpleGroup')
	characterSearchContainer:SetRelativeWidth(1/4)
	characterSearchContainer:SetHeight(40)
	characterSearchContainer:SetLayout('Fill')
	editLine:AddChild(characterSearchContainer)
	characterSearchContainer:ClearAllPoints()

	local characterSearchBox = AceGUI:Create('EditBox')
	characterSearchBox:SetLabel(L['SEARCH_CHARACTERS'])
	characterSearchBox:DisableButton(true)
	if Search.characterSearchText ~= nil then
		characterSearchBox:SetText(Search.characterSearchText)
	end
	characterSearchBox:SetCallback('OnTextChanged', function(widget, event, value)
		Search.characterSearchText = value
		Search.lastSkillClicked = nil
		Search.lastSkillLinkClicked = nil
		Search.lastReagentClicked = nil
		Search.lastCharacterClicked = nil
		Search:PopulateCharacters(true)
	end)
	characterSearchContainer:AddChild(characterSearchBox)
	characterSearchBox:ClearAllPoints()
	Search.characterSearchBox = characterSearchBox

	local labelLine = AceGUI:Create('SimpleGroup')
	labelLine:SetFullWidth(true)
	labelLine:SetLayout('Flow')
	mainFrame:AddChild(labelLine)

	local profLabel = AceGUI:Create('Label')
	profLabel:SetText(L['LABEL_PROFESSIONS'])
	profLabel:SetRelativeWidth(1/4)
	profLabel:SetColor(Search.labelR, Search.labelG, Search.labelB)
	labelLine:AddChild(profLabel)
	profLabel:ClearAllPoints()

	local skillLabel = AceGUI:Create('Label')
	skillLabel:SetText(L['LABEL_SKILLS'])
	skillLabel:SetRelativeWidth(1/4)
	skillLabel:SetColor(1, 0.82, 0)
	labelLine:AddChild(skillLabel)
	skillLabel:ClearAllPoints()

	local reagentLabel = AceGUI:Create('Label')
	reagentLabel:SetText(L['LABEL_REAGENTS'])
	reagentLabel:SetRelativeWidth(1/4)
	reagentLabel:SetColor(Search.labelR, Search.labelG, Search.labelB)
	labelLine:AddChild(reagentLabel)
	reagentLabel:ClearAllPoints()

	local characterLabel = AceGUI:Create('Label')
	characterLabel:SetText(L['LABEL_CHARACTERS'])
	characterLabel:SetRelativeWidth(1/4)
	characterLabel:SetColor(Search.labelR, Search.labelG, Search.labelB)
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
		if GT.DB:GetSearch(profName) == nil then
			GT.DB:SetSearch(profName, true)
		end
		profCheckBox:SetValue(GT.DB:GetSearch(profName))
		profCheckBox:SetCallback('OnValueChanged', function(widget, callback, value)
			local professionName = widget.text:GetText()
			Search.lastSkillClicked = nil
			Search.lastSkillLinkClicked = nil
			Search.lastReagentClicked = nil
			Search.lastCharacterClicked = nil

			GT.DB:SetSearch(professionName, value)

			Search:PopulateSkills(true)
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

	Search.mainFrame = mainFrame
	Search.skillScrollFrame = skillScrollFrame
	Search.reagentScrollFrame = reagentScrollFrame
	Search.characterScrollFrame = characterScrollFrame

	Search:PopulateSkills(true)
end

function Search:PopulateSkills(shouldCascade)
	GT.Log:Info('Search_PopulateSkills', shouldCascade)

	Search.skillScrollFrame:ReleaseChildren()

	local characters = GT.DB:GetCharacters()

	skillsToAdd = {}
	local count = 0
	if Search.lastReagentClicked ~= nil then
		GT.Log:Info('Search_PopulateSkills_LastReagentClicked', Search.lastReagentClicked)
		for characterName, _ in pairs(characters) do
			GT.Log:Info('Search_PopulateSkills_Character', characterName)
			local professions = characters[characterName].professions
			for professionName, _ in pairs(professions) do
				GT.Log:Info('Search_PopulateSkills_Profession', professionName)
				if GT.DB:GetSearch(professionName) then
					local skills = professions[professionName].skills
					for _, skillName in pairs(skills) do
						GT.Log:Info('Search_PopulateSkills_Skill', skillName)
						local skill = GT.DB:GetSkill(characterName, professionName, skillName)
						local reagents = skill.reagents
						for reagentName, _ in pairs(reagents) do
							if reagentName == Search.lastReagentClicked then
								GT.Log:Info('Search_PopulateSkills_Reagent', reagentName)
								local skill = GT.DB:GetSkill(characterName, professionName, skillName)
								local tempSkillName = GT.Text:GetTextBetween(skill.skillLink, '%[', ']')
								local searchMatch = true
								if Search.skillSearchText ~= nil and not string.find(string.lower(tempSkillName), string.lower(Search.skillSearchText)) then
									GT.Log:Info('Search_PopulateSkills_ReagentMatch', reagentName)
									searchMatch = false
								end
								if not GT.Table:Contains(skillsToAdd, tempSkillName) and searchMatch and count < Search.scrollLimit then
									GT.Log:Info('Search_PopulateSkills_AddSkill', tempSkillName)
									count = count + 1
									skillsToAdd[tempSkillName] = skill.skillLink
								end
							end
						end
					end
				end
			end
		end
	elseif Search.lastCharacterClicked ~= nil then
		GT.Log:Info('Search_PopulateSkills_LastCharacterClicked', Search.lastCharacterClicked)
		for characterName, _ in pairs(characters) do
			if characterName == Search.lastCharacterClicked then
				GT.Log:Info('Search_PopulateSkills_Character', characterName)
				local professions = characters[characterName].professions
				for professionName, _ in pairs(professions) do
					if GT.DB:GetSearch(professionName) then
						local skills = professions[professionName].skills
						for _, skillName in pairs(skills) do
							local skill = GT.DB:GetSkill(characterName, professionName, skillName)
							local tempSkillName = GT.Text:GetTextBetween(skill.skillLink, '%[', ']')
							local searchMatch = true
							if Search.skillSearchText ~= nil and not string.find(string.lower(tempSkillName), string.lower(Search.skillSearchText)) then
								searchMatch = false
							end
							if not GT.Table:Contains(skillsToAdd, tempSkillName) and searchMatch and count < Search.scrollLimit then
								skillsToAdd[tempSkillName] = skill.skillLink
								count = count + 1
							end
						end
					end
				end
			end
		end
	else
		for characterName, _ in pairs(characters) do
			local professions = characters[characterName].professions
			for professionName, _ in pairs(professions) do
				if GT.DB:GetSearch(professionName) then
					local skills = professions[professionName].skills
					for _, skillName in pairs(skills) do
						local skill = GT.DB:GetSkill(characterName, professionName, skillName)
						local tempSkillName = GT.Text:GetTextBetween(skill.skillLink, '%[', ']')
						local searchMatch = true
						if Search.skillSearchText ~= nil and not string.find(string.lower(tempSkillName), string.lower(Search.skillSearchText)) then
							searchMatch = false
						end
						if not GT.Table:Contains(skillsToAdd, tempSkillName) and searchMatch and count < Search.scrollLimit then
							skillsToAdd[tempSkillName] = skill.skillLink
							count = count + 1
						end
					end
				end
			end
		end
	end

	local sortedKeys = GT.Table:GetSortedKeys(skillsToAdd, function(a, b) return a < b end, true)
	for _, key in ipairs(sortedKeys) do
		local skillLink = skillsToAdd[key]
		local skillLabel = AceGUI:Create('InteractiveLabel')
		skillLabel:SetText(skillLink)
		skillLabel:SetHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		skillLabel:SetCallback('OnClick', function(widget, event, button)
			local skillLink = widget.label:GetText()
			local skillName = GT.Text:GetTextBetween(skillLink, '%[', ']')

			Search.lastSkillClicked = skillName
			Search.lastSkillLinkClicked = skillLink
			Search.lastReagentClicked = nil
			Search.lastCharacterClicked = nil

			Search:PopulateReagents(false)
			Search:PopulateCharacters(false)
		end) 
		Search.skillScrollFrame:AddChild(skillLabel)
	end

	if shouldCascade then
		Search:PopulateReagents(false)
		Search:PopulateCharacters(false)
	end
end

function Search:PopulateReagents(shouldCascade)
	GT.Log:Info('Search_PopulateReagents', shouldCascade)

	if Search.lastReagentClicked == nil then
		Search.reagentScrollFrame:ReleaseChildren()
	end

	local reagentsToAdd = {}
	if Search.lastSkillClicked ~= nil then
		local characters = GT.DB:GetCharacters()
		local reagentsAdded = false
		for characterName, _ in pairs(characters) do
			if not reagentsAdded then
				local professions = characters[characterName].professions
				for professionName, _ in pairs(professions) do
					local skills = professions[professionName].skills
					for _, skillName in pairs(skills) do
						local skill = GT.DB:GetSkill(characterName, professionName, skillName)
						local tempSkillName = GT.Text:GetTextBetween(skill.skillLink, '%[', ']')
						if tempSkillName == Search.lastSkillClicked then
							local reagents = skill.reagents
							for reagentName, _ in pairs(reagents) do
								local searchMatch = true
								if Search.reagentSearchText ~= nil and not string.find(string.lower(reagentName), string.lower(Search.reagentSearchText)) then
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
	elseif Search.lastCharacterClicked ~= nil then
	elseif Search.lastReagentClicked ~= nil then
	else
		local characters = GT.DB:GetCharacters()
		local reagentsAdded = false
		for characterName, _ in pairs(characters) do
			if not reagentsAdded then
				local professions = characters[characterName].professions
				for professionName, _ in pairs(professions) do
					local skills = professions[professionName].skills
					for _, skillName in pairs(skills) do
						local skill = GT.DB:GetSkill(characterName, professionName, skillName)
						local tempSkillName = GT.Text:GetTextBetween(skill.skillLink, '%[', ']')
						if tempSkillName == Search.lastSkillClicked then
							local reagents = skills[skillName].reagents
							for reagentName, _ in pairs(reagents) do
								local searchMatch = false
								if Search.reagentSearchText ~= nil and string.find(string.lower(reagentName), string.lower(Search.reagentSearchText)) then
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

	local sortedKeys = GT.Table:GetSortedKeys(reagentsToAdd, function(a, b) return a < b end, true)
	for _, reagentName in ipairs(sortedKeys) do
		local reagentCount = reagentsToAdd[reagentName]
		local reagentLabel = AceGUI:Create('InteractiveLabel')
		reagentLabel:SetText(reagentName .. ' (' .. reagentCount .. ')')
		reagentLabel:SetHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		reagentLabel:SetCallback('OnClick', function(widget, event, button)
			local text = widget.label:GetText()
			local tokens = GT.Text:Tokenize(text, ' ')
			table.remove(tokens, #tokens)
			local reagentName = table.concat(tokens, ' ')

			Search.lastSkillClicked = nil
			Search.lastSkillLinkClicked = nil
			Search.lastReagentClicked = reagentName
			Search.lastCharacterClicked = nil

			Search:PopulateSkills(false)
			Search:PopulateCharacters(false)
		end)
		Search.reagentScrollFrame:AddChild(reagentLabel)
	end
	if shouldCascade then
		Search:PopulateSkills(false)
		Search:PopulateCharacters(false)
	end
end

function Search:PopulateCharacters(shouldCascade)
	GT.Log:Info('Search_PopulateCharacters', shouldCascade)

	if Search.lastCharacterClicked == nil then
		Search.characterScrollFrame:ReleaseChildren()
	end

	local charactersToAdd = {}
	local count = 0
	if Search.lastSkillClicked ~= nil then
		local characters = GT.DB:GetCharacters()
		for characterName, _ in pairs(characters) do
			local addCharacter = false
			local professions = characters[characterName].professions
			for professionName, _ in pairs(professions) do
				local skills = professions[professionName].skills
				for _, skillName in pairs(skills) do
					local skill = GT.DB:GetSkill(characterName, professionName, skillName)
					local tempSkillName = GT.Text:GetTextBetween(skill.skillLink, '%[', ']')
					if tempSkillName == Search.lastSkillClicked then
						addCharacter = true
						break
					end
				end
			end
			if addCharacter and not GT.Table:Contains(charactersToAdd, characterName) and count < Search.scrollLimit then
				table.insert(charactersToAdd, characterName)
				count = count + 1
			end
		end
	elseif Search.lastReagentClicked ~= nil then
	elseif Search.lastCharacterClicked ~= nil then
	else
		local characters = GT.DB:GetCharacters()
		for characterName, _ in pairs(characters) do
			local searchMatch = false
			if Search.characterSearchText ~= nil and string.find(string.lower(characterName), string.lower(Search.characterSearchText)) then
				searchMatch = true
			end
			if searchMatch and not GT.Table:Contains(charactersToAdd, characterName) and count < Search.scrollLimit then
				table.insert(charactersToAdd, characterName)
				count = count + 1
			end
		end
	end

	local onlineGuildMembers = {}
	local classColors = {}
	local countTotalMembers, countOnlineMembers = GetNumGuildMembers()
	for i=1,countTotalMembers do
		local characterName, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(i)
		if online then
			characterName = GT.Text:ConvertCharacterName(characterName)
			table.insert(onlineGuildMembers, characterName)
			classColors[characterName] = RCC[string.upper(class)]['colorStr']
		end
	end

	local sortedKeys = GT.Table:GetSortedKeys(charactersToAdd, function(a, b) return a < b end)
	for _, key in ipairs(sortedKeys) do
		local characterName = charactersToAdd[key]
		local characterLabel = AceGUI:Create('InteractiveLabel')
		local labelText = string.gsub(L['GUILD_OFFLINE'], '%{{guild_member}}', characterName)
		if GT.Table:Contains(onlineGuildMembers, characterName) then
			labelText = string.gsub(L['GUILD_ONLINE'], '%{{guild_member}}', characterName)
			labelText = string.gsub(labelText, '%{{class_color}}', classColors[characterName])
		end
		characterLabel:SetText(labelText)
		characterLabel:SetHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		characterLabel:SetCallback('OnClick', function(widget, event, button)
			local labelText = widget.label:GetText()
			local characterName = GT.Text:ConvertCharacterName(labelText)
			characterName = string.sub(characterName, 11)
			characterName = string.sub(characterName, 0, #characterName - 3)
			if button == 'RightButton' then
				local online = string.gsub(labelText, characterName, '')
				online = string.gsub(online, '- ' , '')
				online = string.sub(online, 24)
				online = string.sub(online, 0, #online - 2)
				if string.lower(online) == 'online' and Search.lastSkillLinkClicked ~= nil then
					local whisperSent = false
					local totalGuildMembers = GetNumGuildMembers()
					for i = 1, totalGuildMembers do
						local guildCharacterName, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(i)
						local tempCharacterName = GT.Text:ConvertCharacterName(guildCharacterName)
						if online and tempCharacterName == characterName then
							local msg = L['WHISPER_REQUEST']
							msg = string.gsub(msg, '%{{character_name}}', characterName)
							msg = string.gsub(msg, '%{{item_link}}', Search.lastSkillLinkClicked)
							ChatThrottleLib:SendChatMessage('ALERT', 'GT', msg, 'WHISPER', 'Common', guildCharacterName)
							whisperSent = true
						end
					end
					if not whisperSent then
						GT.Log:PlayerWarn(string.gsub(L['WHISPER_NO_CHARACTER_FOUND'], '%{{character_name}}', characterName))
					end

				elseif Search.lastSkillLinkClicked == nil then
					GT.Log:PlayerWarn(L['WHISPER_SELECT_REQUIRED'])
				end
			else
				Search.lastSkillClicked = nil
				Search.lastSkillLinkClicked = nil
				Search.lastReagentClicked = nil
				Search.lastCharacterClicked = characterName
				Search:PopulateSkills(false)
				Search:PopulateReagents(false)
			end
		end)
		Search.characterScrollFrame:AddChild(characterLabel)
	end

	if shouldCascade then
		Search:PopulateSkills(false)
		Search:PopulateReagents(false)
	end
end
