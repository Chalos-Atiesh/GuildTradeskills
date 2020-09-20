local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local AceGUI = LibStub('AceGUI-3.0')

local PREFIX = 'GT'

local Search = GT:NewModule('Search')
GT.Search = Search

if Search.frames == nil then
	Search.frames = {}
end

if Search.frames.text == nil then
	Search.frames.text = {}
end

if Search.frames.scroll == nil then
	Search.frames.scroll = {}
end

if Search.professions == nil then
	Search.professions = {}
end

if Search.professions.radios == nil then
	Search.professions.radios = {}
end

if Search.skills == nil then
	Search.skills = {}
end

if Search.skills.skills == nil then
	Search.skills.skills = {}
end

if Search.skills.radios == nil then
	Search.skills.radios = {}
end

if Search.reagents == nil then
	Search.reagents = {}
end

if Search.reagents.reagents == nil then
	Search.reagents.reagents = {}
end

if Search.reagents.radios == nil then
	Search.reagents.radios = {}
end

if Search.characters == nil then
	Search.characters = {}
end

if Search.characters.characters == nil then
	Search.characters.characters = {}
end

if Search.characters.radios == nil then
	Search.characters.radios = {}
end

if Search.state == nil then
	Search.state = {}
end

if Search.state.text == nil then
	Search.state.text = {}
end

if Search.state.clicks == nil then
	Search.state.clicks = {}
end

local RCC = RAID_CLASS_COLORS

local NAME_FRAME = AddOnName .. ' Search'
local LABEL_FRAME = GT.L['LONG_TAG'] .. ' Search'

local NAME_PROFESSIONS = 'professions'
local NAME_SKILLS = 'skills'
local NAME_REAGENTS = 'reagents'
local NAME_CHARACTERS = 'characters'

local SEARCH_NAMES = {}

local UNKNOWN_CLASS_COLOR = 'ff7f7f7f'

local LABEL_R = 224/255
local LABEL_G = 202/255
local LABEL_B = 10/255

function Search:OnEnable()
	GT.Log:Info('Search_OnEnable')

	table.insert(SEARCH_NAMES, NAME_SKILLS)
	table.insert(SEARCH_NAMES, NAME_REAGENTS)
	table.insert(SEARCH_NAMES, NAME_CHARACTERS)
end

----- POPULATION START -----

function Search:PopulateSkills()
	GT.Log:Info('Search_PopulateSkills')
	Search.skills.radios = {}

	local professions = GT.DBProfession:GetProfessions()
	for professionName, profession in pairs(professions) do
		GT.Log:Info('Search_PopulateSkills_Profession', professionName)
		local skills = GT.DBProfession:GetSkills(professionName)
		for skillName, skill in pairs(skills) do
			local tempSkillName = Text:GetTextBetween(skill.skillLink, '%[', ']')
			Search.skills.skills[tempSkillName] = skill
			Search.skills.radios[tempSkillName] = {}

			local allowed = true

			if Search.state.text[NAME_SKILLS] ~= nil then
				local searchText = Search.state.text[NAME_SKILLS]
				if not string.find(string.lower(tempSkillName), searchText) then
					allowed = false
				end
			end

			if Search.state.text[NAME_REAGENTS] ~= nil then
				local searchText = Search.state.text[NAME_REAGENTS]
				local hasAnyReagent = false
				for reagentName, _ in pairs(skill.reagents) do
					if string.find(string.lower(reagentName), searchText)  then
						hasAnyReagent = true
						break
					end
				end
				if not hasAnyReagent then
					allowed = false
				end
			end

			if Search.state.text[NAME_CHARACTERS] ~= nil then
				local searchText = Search.state.text[NAME_CHARACTERS]
				local characters = GT.DBCharacter:GetCharacters()
				local anyCharacterHasSkill = false
				for characterName, _ in pairs(characters) do
					if string.find(string.lower(characterName), searchText)
						and GT.DBCharacter:SkillExists(characterName, professionName, skillName)
					then
						anyCharacterHasSkill = true
					end
				end
				if not anyCharacterHasSkill then
					allowed = false
				end
			end

			-- Do not filter on skill clicks.

			if Search.state.clicks[NAME_REAGENTS] ~= nil then
				local reagent = Search.state.clicks[NAME_REAGENTS]
				local allowedByReagent = false
				for reagentName, _ in pairs(skill.reagents) do
					if reagentName == reagent.reagentName then
						allowedByReagent = true
						break
					end
				end

				if not allowedByReagent then
					allowed = false
				end
			end

			if Search.state.clicks[NAME_CHARACTERS] ~= nil then
				local character = Search.state.clicks[NAME_CHARACTERS]
				if not GT.DBCharacter:SkillExists(character.characterName, professionName, skillName) then
					allowed = false
				end
			end

			if not GT.DB:GetSearch(professionName) then
				allowed = false
			end

			local characters = GT.DBCharacter:GetCharacters()
			local anyCharacterHasSkill = false
			for characterName, _ in pairs(characters) do
				if GT.DBCharacter:SkillExists(characterName, professionName, skillName) then
					anyCharacterHasSkill = true
				end
			end
			if not anyCharacterHasSkill then
				allowed = false
			end
			
			Search.skills.radios[tempSkillName].shown = allowed
		end
	end

	local sortedKeys = Table:GetSortedKeys(Search.skills.skills, function(a, b) return a < b end, true)
	Search.frames.scroll[NAME_SKILLS]:Clear()
	for _, skillName in ipairs(sortedKeys) do
		local searchRadio = Search.skills.radios[skillName]
		if searchRadio ~= nil and searchRadio.shown then
			local skill = Search.skills.skills[skillName]

			local radio = {}
			radio.type = 'CheckBox'
			radio.subType = 'radio'
			radio.shown = searchRadio.shown
			radio.label = skill.skillLink
			radio.callbacks = {
				OnValueChanged = function(widget, event, value) Search:OnSkillClick(widget, event, value) end,
				OnEnter = function(widget, event, value) Search:OnSkillEnter(widget, event, value) end,
				OnLeave = function(widget, event, value) Search:OnSkillLeave(widget, event, value) end
			}
			radio.data = {
				skill = skill
			}

			if Search.state.clicks[NAME_SKILLS] ~= nil then
				local tempSkill = Search.state.clicks[NAME_SKILLS]
				if tempSkill.skillName == skill.skillName then
					GT.Log:Info('Search_PopulateSkills_ThisSkill', tempSkill.skillName)
					radio.value = true
				else
					radio.value = false
				end
			end

			Search.skills.radios[skillName] = radio
			Search.frames.scroll[NAME_SKILLS]:Add(radio)
		end
	end
end

function Search:PopulateReagents()
	GT.Log:Info('Search_PopulateReagents')
	Search.reagents.radios = {}
	Search.reagents.reagents = {}

	Search.frames.scroll[NAME_REAGENTS]:ReleaseChildren()

	local professions = GT.DBProfession:GetProfessions()
	for professionName, _ in pairs(professions) do
		-- GT.Log:Info('Search_PopulateReagents_Profession', professionName)
		local skills = GT.DBProfession:GetSkills(professionName)
		for skillName, skill in pairs(skills) do
			-- GT.Log:Info('Search_PopulateReagents_Skill', skillName)
			local tempSkillName = Text:GetTextBetween(skill.skillLink, '%[', ']')
			local reagents = GT.DBProfession:GetReagents(professionName, skillName)

			for reagentName, reagent in pairs(reagents) do
				-- GT.Log:Info('Search_PopulateReagents_Reagent', reagentName)
				local allowed = true

				if Search.state.text[NAME_SKILLS] ~= nil then
					local searchText = Search.state.text[NAME_SKILLS]
					if not string.find(string.lower(tempSkillName), searchText) then
						-- GT.Log:Info('Search_PopulateReagents_DisallowedBySkillSearch', tempSkillName)
						allowed = false
					end
				end

				if Search.state.text[NAME_REAGENTS] ~= nil then
					local searchText = Search.state.text[NAME_REAGENTS]
					if not string.find(string.lower(reagentName), searchText) then
						-- GT.Log:Info('Search_PopulateReagents_DisallowedByReagentSearch', reagentName)
						allowed = false
					end
				end

				if Search.state.text[NAME_CHARACTERS] ~= nil then
					local searchText = Search.state.text[NAME_CHARACTERS]
					local characters = GT.DBCharacter:GetCharacters()
					local anyCharacterHasSkill = false
					for characterName, _ in pairs(characters) do
						if string.find(string.lower(characterName), searchText)
							and GT.DBCharacter:SkillExists(characterName, professionName, skillName)
						then
							anyCharacterHasSkill = true
						end
					end
					if not anyCharacterHasSkill then
						-- GT.Log:Info('Search_PopulateReagents_DisallowedByCharacterSearch', reagentName)
						allowed = false
					end
				end

				if Search.state.clicks[NAME_SKILLS] ~= nil then
					local tempSkill = Search.state.clicks[NAME_SKILLS]
					if tempSkill.skillName ~= skillName then
						-- GT.Log:Info('Search_PopulateReagents_DisallowedBySkillClick', reagentName)
						allowed = false
					end
				end

				-- Do not filter on reagent clicks.

				if Search.state.clicks[NAME_CHARACTERS] ~= nil then
					local character = Search.state.clicks[NAME_CHARACTERS]
					if not GT.DBCharacter:SkillExists(character.characterName, professionName, skillName) then
						-- GT.Log:Info('Search_PopulateReagents_DisallowedByCharacterClick', characterName, professionName, skillName, reagentName)
						allowed = false
					end
				end

				if not GT.DB:GetSearch(professionName) then
					allowed = false
				end

				local characters = GT.DBCharacter:GetCharacters()
				local anyCharacterHasSkill = false
				for characterName, _ in pairs(characters) do
					if GT.DBCharacter:SkillExists(characterName, professionName, skillName) then
						anyCharacterHasSkill = true
					end
				end
				if not anyCharacterHasSkill then
					allowed = false
				end

				if allowed then
					Search.reagents.radios[reagentName] = {}
					Search.reagents.radios[reagentName].shown = true
					Search.reagents.reagents[reagentName] = reagent
				else
					if Search.reagents.radios[reagentName] == nil then
						Search.reagents.radios[reagentName] = {}
						Search.reagents.radios[reagentName].shown = false
					end
				end
			end
		end
	end

	local sortedKeys = Table:GetSortedKeys(Search.reagents.reagents, function(a, b) return a < b end, true)
	Search.frames.scroll[NAME_REAGENTS]:Clear()
	for _, reagentName in ipairs(sortedKeys) do
		-- GT.Log:Info('Search_PopulateReagents_SortedReagent', reagentName)
		local searchRadio = Search.reagents.radios[reagentName]
		if searchRadio ~= nil and searchRadio.shown then
			-- GT.Log:Info('Search_PopulateReagents_Shown', reagentName)
			local reagent = Search.reagents.reagents[reagentName]

			local radio = {}
			radio.type = 'CheckBox'
			radio.subType = 'radio'
			radio.shown = searchRadio.shown
			radio.callbacks = {
				OnValueChanged = function(widget, event, value) Search:OnReagentClick(widget, event, value) end,
				OnEnter = function(widget, event, value) Search:OnReagentEnter(widget, event, value) end,
				OnLeave = function(widget, event, value) Search:OnReagentLeave(widget, event, value) end
			}
			radio.data = {
				reagent = reagent
			}

			label = nil
			if reagent.reagentLink ~= nil then
				label = reagent.reagentLink
			else
				label = reagentName
			end
			if Search.state.clicks[NAME_SKILLS] ~= nil then
				label = Text:Concat('', reagent.reagentCount, GT.L['X'], label)
			end
			radio.label = label

			if Search.state.clicks[NAME_REAGENTS] ~= nil then
				local tempReagent = Search.state.clicks[NAME_REAGENTS]
				if tempReagent.reagentName == reagent.reagentName then
					-- GT.Log:Info('Search_PopulateSkills_ThisSkill', tempReagent.reagentName)
					radio.value = true
				else
					radio.value = false
				end
			end
			Search.reagents.radios[reagentName] = radio
			Search.frames.scroll[NAME_REAGENTS]:Add(radio)
		end
	end
end

function Search:PopulateCharacters()
	GT.Log:Info('Search_PopulateCharacters')
	Search.characters.radios = {}

	Search.frames.scroll[NAME_CHARACTERS]:ReleaseChildren()

	local characters = GT.DBCharacter:GetCharacters()
	for characterName, character in pairs(characters) do
		GT.Log:Info('Search_PopulateCharacters_Character', characterName)
		Search.characters.characters[characterName] = character
		Search.characters.radios[characterName] = {}

		local allowed = true

		if Search.state.text[NAME_SKILLS] ~= nil then
			local searchText = Search.state.text[NAME_SKILLS]
			local hasAnySkill = false
			local professions = GT.DBProfession:GetProfessions()
			for professionName, _ in pairs(professions) do
				local skills = GT.DBProfession:GetSkills(professionName)
				for skillName, _ in pairs(skills) do
					if string.find(string.lower(skillName), searchText)
						and GT.DBCharacter:SkillExists(characterName, professionName, skillName)
					then
						hasAnySkill = true
					end
				end
			end
			if not hasAnySkill then
				allowed = false
			end
		end

		if Search.state.text[NAME_REAGENTS] ~= nil then
			local searchText = Search.state.text[NAME_REAGENTS]
			local hasAnyReagent = true
			local professions = GT.DBProfession:GetProfessions()
			for professionName, _ in pairs(professions) do
				local skills = GT.DBProfession:GetSkills(professionName)
				for skillName, _ in pairs(skills) do
					local reagents = GT.DBProfession:GetReagents(professionName, skillName)
					for reagentName, _ in pairs(reagents) do
						if string.find(string.lower(reagentName), searchText) then
							hasAnyReagent = true
						end
					end
				end
			end
			if not hasAnyReagent then
				allowed = false
			end
		end

		if Search.state.text[NAME_CHARACTERS] ~= nil then
			local searchText = Search.state.text[NAME_CHARACTERS]
			if not string.find(string.lower(characterName), searchText) then
				allowed = false
			end
		end

		if Search.state.clicks[NAME_SKILLS] ~= nil then
			local skill = Search.state.clicks[NAME_SKILLS]
			-- GT.Log:Info('Search_PopulateCharacters_SpecificSkill', characterName, skillName)
			if not GT.DBCharacter:HasSkill(characterName, skill.skillName) then
				-- GT.Log:Info('Search_PopulateCharacters_HasSkill', characterName, skillName)
				allowed = false
			end
		end

		if Search.state.clicks[NAME_REAGENTS] ~= nil then
			local reagent = Search.state.clicks[NAME_REAGENTS]
			local professions = GT.DBProfession:GetProfessions()
			for professionName, _ in pairs(professions) do
				local skills = GT.DBProfession:GetSkills(professionName)
				for skillName, _ in pairs(skills) do
					local reagents = GT.DBProfession:GetReagents(professionName, skillName)
					for tempReagentName, _ in pairs(reagents) do
						if tempReagentName == reagent.reagentName then
							hasAnyReagent = true
						end
					end
				end
			end
			if not hasAnyReagent then
				allowed = false
			end
		end

		-- Do not filter on character clicks.

		local professions = GT.DBProfession:GetProfessions()
		local hasAnySkill = false
		for professionName, _ in pairs(professions) do
			local skills = GT.DBProfession:GetSkills(professionName)
			for skillName, skill in pairs(skills) do
				local tempSkillName = Text:GetTextBetween(skill.skillLink, '%[', ']')
				local skillRadio = Search.skills.radios[tempSkillName]
				if skillRadio ~= nil and skillRadio.shown and GT.DBCharacter:SkillExists(characterName, professionName, skillName) then
					hasAnySkill = true
				end
			end
		end
		if not hasAnySkill then
			allowed = false
		end

		Search.characters.radios[characterName].shown = allowed
	end

	local sortedKeys = Table:GetSortedKeys(Search.characters.characters, function(a, b) return a < b end, true)
	Search.frames.scroll[NAME_CHARACTERS]:Clear()
	for _, characterName in pairs(sortedKeys) do
		GT.Log:Info('Search_PopulateCharacters_SortedCharacter', characterName)
		local searchRadio = Search.characters.radios[characterName]
		if searchRadio ~= nil and searchRadio.shown then
			GT.Log:Info('Search_PopulateCharacters_PopulateCharacter', characterName)
			local character = Search.characters.characters[characterName]

			local radio = {}
			radio.type = 'CheckBox'
			radio.subType = 'radio'
			radio.shown = searchRadio.shown
			radio.callbacks = {
				OnValueChanged = function(widget, event, value) Search:OnCharacterClick(widget, event, value) end,
				OnEnter = function(widget, event, value) Search:OnCharacterEnter(widget, event, value) end,
				OnLeave = function(widget, event, value) Search:OnCharacterLeave(widget, event, value) end
			}
			radio.data = {
				character = character
			}

			local label = nil
			if character.isBroadcasted then
				label = GT.L['BROADCASTED_TAG']
			else
				label = GT.L['OFFLINE_TAG']
			end
			if character.isOnline then
				label = GT.L['ONLINE_TAG']
			end
			label = string.gsub(label, '%{{guild_member}}', characterName)

			local classColor = UNKNOWN_CLASS_COLOR
			if character.class ~= nil and character.class ~= 'UNKNOWN' then
				classColor = RCC[character.class].colorStr
			end
			label = string.gsub(label, '%{{class_color}}', classColor)
			radio.label = label

			if Search.state.clicks[NAME_CHARACTERS] ~= nil then
				local tempCharacter = Search.state.clicks[NAME_CHARACTERS]
				if tempCharacter.characterName == characterName then
					radio.value = true
				else
					radio.value = false
				end
			end

			-- GT.Log:Info('Search_PopulateCharacters_AddChild', labelText)
			Search.frames.scroll[NAME_CHARACTERS]:Add(radio)
		end
	end
end

----- POPULATION END -----
----- START RADIO MANAGEMENT -----
	----- START CLICK MANAGEMENT -----

	function Search:OnSkillClick(widget, event, value)
		local skill = widget.skill
		local skillName = skill.skillName
		local skillLinkName = Text:GetTextBetween(skill.skillLink, '%[', ']')
		GT.Log:Info('Search_OnSkillClick', skillName, value)

		if value == true then
			Search.state.clicks[NAME_SKILLS] = skill
		else
			Search.state.clicks[NAME_SKILLS] = nil
		end

		local offset = Search.frames.scroll[NAME_SKILLS]:GetScroll()
		Search:PopulateSkills()
		Search.frames.scroll[NAME_SKILLS]:SetScroll(offset)
		Search:PopulateReagents()
		Search:PopulateCharacters()
	end

	function Search:OnReagentClick(widget, event, value)
		local reagent = widget.reagent
		local reagentName = reagent.reagentName
		GT.Log:Info('Search_OnReagentClick', reagentName, value)

		if value == true then
			Search.state.clicks[NAME_REAGENTS] = reagent
		else
			Search.state.clicks[NAME_REAGENTS] = nil
		end

		Search:PopulateSkills()
		local offset = Search.frames.scroll[NAME_REAGENTS]:GetScroll()
		Search:PopulateReagents()
		Search.frames.scroll[NAME_REAGENTS]:SetScroll(offset)
		Search:PopulateCharacters()
	end

	function Search:OnCharacterClick(widget, event, value)
		local character = widget.character
		local characterName = character.characterName
		GT.Log:Info('Search_OnCharacterClick', characterName, event, value)


		if GetMouseButtonClicked() == 'RightButton' and not value then
			GT.Log:Info('Search_OnCharacterClick_RightButton')

			local character = GT.DBCharacter:GetCharacter(characterName)
			if character.isOnline then
				value = not value
				Search:SendWhisper(characterName)
			end
		end
		if value == true then
			Search.state.clicks[NAME_CHARACTERS] = character
			local offset = Search.frames.scroll[NAME_CHARACTERS]:GetScroll()
			Search:PopulateCharacters()
			Search.frames.scroll[NAME_CHARACTERS]:SetScroll(offset)
			Search:PopulateSkills()
			Search:PopulateReagents()
		else
			Search.state.clicks[NAME_CHARACTERS] = nil
			Search:PopulateSkills()
			Search:PopulateReagents()
			Search:PopulateCharacters()
		end
	end

	function Search:SendWhisper(characterName)
		GT.Log:Info('Search_SendWhisper', characterName)
		if Search.state.clicks[NAME_SKILLS] == nil then
			GT.Log:PlayerWarn(GT.L['NO_SKILL_SELECTED'])
			return
		end

		local skill = Search.state.clicks[NAME_SKILLS]
		GT.Log:Info('Search_SendWhisper_SkillSelected', skill.skillName)
		local message = string.gsub(GT.L['SEND_WHISPER'], '%{{character_name}}', characterName)
		message = string.gsub(message, '%{{skill_link}}', skill.skillLink)
		ChatThrottleLib:SendChatMessage('ALERT', PREFIX, message, 'WHISPER', 'Common', characterName)
	end

	----- END CLICK MANAGEMENT -----
	----- START HOVER MANAGEMENT -----

	function Search:OnSkillEnter(widget, event, value)
		-- GT.Log:Info('Search_OnSkillEnter', widget.skillName)
		GameTooltip:Hide()
		GameTooltip:SetOwner(widget.frame, 'ANCHOR_RIGHT')
		GameTooltip:SetHyperlink(widget.text:GetText())

		GameTooltip:Show()
	end

	function Search:OnSkillLeave(widget, event, value)
		-- GT.Log:Info('Search_OnSkillLeave', widget.skillName)
		GameTooltip:Hide()
	end

	function Search:OnReagentEnter(widget, event, value)
		local reagent = widget.reagent
		-- GT.Log:Info('Search_OnReagentEnter', reagent.reagentName)
		GameTooltip:Hide()
		if reagent.reagentLink ~= nil then
			GameTooltip:SetOwner(widget.frame, 'ANCHOR_RIGHT')
			GameTooltip:SetHyperlink(widget.text:GetText())
			GameTooltip:Show()
		end
	end

	function Search:OnReagentLeave(widget, event, value)
		local reagent = widget.reagent
		-- GT.Log:Info('Search_OnReagentLeave', reagent.reagentName)
		GameTooltip:Hide()
	end

	function Search:OnCharacterEnter(widget, event, value)
		local character = widget.character
		local characterName = character.characterName
		GT.Log:Info('Search_OnCharacterEnter', characterName)

		GameTooltip:Hide()
		if Search.state.clicks[NAME_SKILLS] ~= nil then
			local skill = Search.state.clicks[NAME_SKILLS]
			local tooltip = string.gsub(GT.L['QUERY_TOOLTIP'], '%{{skill}}', skill.skillLink)
			GameTooltip:SetOwner(widget.frame, 'ANCHOR_RIGHT')
			GameTooltip:SetText(tooltip)
			GameTooltip:Show()
		end
	end

	function Search:OnCharacterLeave(widget, event, value)
		local character = widget.character
		local characterName = character.characterName
		GT.Log:Info('Search_OnCharacterLeave', characterName)
		GameTooltip:Hide()
	end

	----- END HOVER MANAGEMENT -----
----- END RADIO MANAGEMENT -----
----- SEARCH START -----

function Search:ResetSearch()
	Search:ResetText()
	Search:ResetClicks()

	Search:PopulateSkills()
	Search:PopulateReagents()
	Search:PopulateCharacters()
end

function Search:ResetText()
	for _, name in pairs(SEARCH_NAMES) do
		Search.state.text[name] = nil
	end
end

function Search:ResetClicks()
	for _, name in pairs(SEARCH_NAMES) do
		Search.state.clicks[name] = nil
	end
end

function Search:OnProfessionSearch(widget, event, value)
	GT.Log:Info('Search_OnProfessionSearch', widget.text:GetText(), value)
	local professionName = widget.text:GetText()

	GT.DB:SetSearch(professionName, value)

	local offset = Search.frames.scroll[NAME_SKILLS]:GetScroll()
	Search:PopulateSkills()
	Search.frames.scroll[NAME_SKILLS]:SetScroll(offset)
	
	offset = Search.frames.scroll[NAME_REAGENTS]:GetScroll()
	Search:PopulateReagents()
	Search.frames.scroll[NAME_REAGENTS]:SetScroll(offset)

	offset = Search.frames.scroll[NAME_CHARACTERS]:GetScroll()
	Search:PopulateCharacters()
	Search.frames.scroll[NAME_CHARACTERS]:SetScroll(offset)
end

function Search:OnSkillSearch(widget, event, value)
	if event == '' then event = nil end
	event = Text:Lower(event)
	GT.Log:Info('Search_OnSkillSearch', Text:ToString(event))
	Search.state.text[NAME_SKILLS] = event
	Search:PopulateSkills()
	Search:PopulateReagents()
	Search:PopulateCharacters()
end

function Search:OnReagentSearch(widget, event, value)
	if event == '' then event = nil end
	event = Text:Lower(event)
	GT.Log:Info('Search_OnReagentSearch', Text:ToString(event))
	Search.state.text[NAME_REAGENTS] = event
	Search:PopulateReagents()
	Search:PopulateSkills()
	Search:PopulateCharacters()
end

function Search:OnCharacterSearch(widget, event, value)
	if event == '' then event = nil end
	event = Text:Lower(event)
	GT.Log:Info('Search_OnCharacterSearch', Text:ToString(event))
	Search.state.text[NAME_CHARACTERS] = event
	Search:PopulateCharacters()
	Search:PopulateSkills()
	Search:PopulateReagents()
end

----- SEARCH END -----
----- FRAME MANAGEMENT START -----

function Search:ToggleFrame()
	GT.Log:Info('Search_ToggleFrame')

	if Search.mainFrame ~= nil then
		Search:OnClose()
		return nil
	end
	return Search:CreateFrame()
end

function Search:OnClose()
	GT.Log:Info('Search_OnClose')

	if Search.mainFrame == nil then return false end

	Search:ResetText()
	Search:ResetClicks()

	GT.Log:Info('Search_OnClose_Release')
	Search.mainFrame:ReleaseChildren()
	AceGUI:Release(Search.mainFrame)

	Search.frames.scroll = {}

	Search.mainFrame = nil
	return true
end

function Search:CreateFrame()
	GT.Log:Info('Search_CreateFrame')
	local mainFrame = AceGUI:Create('Frame')
	mainFrame:SetTitle(LABEL_FRAME)
	mainFrame:SetLayout('Flow')
	mainFrame:SetCallback('OnClose', function(frame) Search:OnClose() end)

	Search.mainFrame = mainFrame

	_G[NAME_FRAME] = mainFrame.frame
	tinsert(UISpecialFrames, NAME_FRAME)

	Search:CreateSearchRow()
	Search:CreateLabelRow()

	Search:CreateScrollFrame(NAME_PROFESSIONS)
	Search:CreateScrollFrame(NAME_SKILLS)
	Search:CreateScrollFrame(NAME_REAGENTS)
	Search:CreateScrollFrame(NAME_CHARACTERS, 'RIGHT')

	Search:CreateProfessionCheckBoxes()

	Search:PopulateSkills()
	Search:PopulateReagents()
	Search:PopulateCharacters()

	return mainFrame
end

function Search:CreateProfessionCheckBoxes()
	for _, professionName in pairs(GT.L['PROFESSIONS_LIST']) do
		local checkBox = AceGUI:Create('CheckBox')
		checkBox:SetFullWidth(true)
		checkBox:SetLabel(professionName)
		local checked = true
		if GT.DB:GetSearch(professionName) == nil then
			GT.DB:SetSearch(professionName, true)
		end
		local value = GT.DB:GetSearch(professionName)
		-- GT.Log:Info('Search_CreteProfessionCheckBoxes_Set', professionName, value)
		checkBox:SetValue(value)
		checkBox:SetCallback('OnValueChanged', function(widget, event, value) Search:OnProfessionSearch(widget, event, value) end)
		Search.frames.scroll[NAME_PROFESSIONS]:AddChild(checkBox)
		Search.professions.radios[professionName] = {}
		Search.professions.radios[professionName].radio = checkBox
	end
end

function Search:CreateScrollFrame(name, point)
	local scrollContainer = AceGUI:Create('SimpleGroup')
	scrollContainer:SetRelativeWidth(1/4)
	scrollContainer:SetFullHeight(true)
	scrollContainer:SetLayout('Fill')
	Search.mainFrame:AddChild(scrollContainer)
	if point ~= nil then
		scrollContainer:SetPoint(point)
	else
		scrollContainer:ClearAllPoints()
	end

	local scrollFrame = AceGUI:Create('InfiniteScrollFrame')
	scrollFrame:SetLayout('Flow')
	scrollContainer:AddChild(scrollFrame)

	Search.frames.scroll[name] = scrollFrame

	return scrollFrame
end

function Search:CreateSearchRow()
	local searchRow = AceGUI:Create('SimpleGroup')
	searchRow:SetFullWidth(true)
	searchRow:SetLayout('Flow')
	Search.mainFrame:AddChild(searchRow)

	local resetSearchButton = AceGUI:Create('Button')
	resetSearchButton:SetRelativeWidth(1/4)
	resetSearchButton:SetText(GT.L['BUTTON_FILTERS_RESET'])
	resetSearchButton:SetCallback('OnClick', function() Search:ResetSearch() end)
	searchRow:AddChild(resetSearchButton)

	Search:CreateSearchBox(searchRow, NAME_SKILLS, GT.L['SEARCH_SKILLS'], Search['OnSkillSearch'])
	Search:CreateSearchBox(searchRow, NAME_REAGENTS, GT.L['SEARCH_REAGENTS'], Search['OnReagentSearch'])
	Search:CreateSearchBox(searchRow, NAME_CHARACTERS, GT.L['SEARCH_CHARACTERS'], Search['OnCharacterSearch'])
	return searchRow
end

function Search:CreateSearchBox(searchRow, name, label, callback)
	local searchContainer = AceGUI:Create('SimpleGroup')
	searchContainer:SetRelativeWidth(1/4)
	searchContainer:SetHeight(40)
	searchContainer:SetLayout('Fill')
	searchRow:AddChild(searchContainer)

	local searchBox = AceGUI:Create('EditBox')
	searchBox:SetLabel(label)
	searchBox:DisableButton(true)
	if Search.state.text[name] ~= nil then
		local value = Search.state.text[name]
		GT.Log:Info('Search_CreateSearchBox', name, value)
		searchBox:SetText(value)
	end
	searchBox:SetCallback('OnTextChanged', function(widget, event, value) callback(widget, event, value) end)
	searchContainer:AddChild(searchBox)

	Search.frames.text[name] = searchBox

	return searchBox
end

function Search:CreateLabelRow()
	local labelRow = AceGUI:Create('SimpleGroup')
	labelRow:SetFullWidth(true)
	labelRow:SetLayout('Flow')
	Search.mainFrame:AddChild(labelRow)

	Search:CreateLabel(labelRow, GT.L['LABEL_PROFESSIONS'])
	Search:CreateLabel(labelRow, GT.L['LABEL_SKILLS'])
	Search:CreateLabel(labelRow, GT.L['LABEL_REAGENTS'])
	Search:CreateLabel(labelRow, GT.L['LABEL_CHARACTERS'])
	return labelRow
end

function Search:CreateLabel(labelRow, text)
	local label = AceGUI:Create('Label')
	label:SetText(text)
	label:SetRelativeWidth(1/4)
	label:SetColor(LABEL_R, LABEL_G, LABEL_B)
	labelRow:AddChild(label)
	return label
end

----- FRAME MANAGEMENT END