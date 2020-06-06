local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local AceGUI = LibStub('AceGUI-3.0')

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

	Search.frames.scroll[NAME_SKILLS]:ReleaseChildren()
	Search.state.clicks[NAME_SKILLS] = nil

	local professions = GT.DBProfession:GetProfessions()
	for professionName, profession in pairs(professions) do
		local allowedByProfession = GT.DB:GetSearch(professionName)
		GT.Log:Info('Search_PopulateSkills_Profession', professionName)
		local skills = GT.DBProfession:GetSkills(professionName)
		if skills ~= nil then
			for skillName, skill in pairs(skills) do
				local allowedBySkill = Search:IsAllowedBy(skillName, NAME_SKILLS)
				local allowedByReagent = false
				local allowedByCharacter = false

				local reagents = GT.DBProfession:GetReagents(professionName, skillName)
				for reagentName, _ in pairs(reagents) do
					allowedByReagent = Search:IsAllowedBy(reagentName, NAME_REAGENTS)
					if allowedByReagent then break end
				end

				local characters = GT.DBCharacter:GetCharacters()
				for characterName, _ in pairs(characters) do
					if GT.DBCharacter:HasSkill(characterName, skillName) then
						allowedByCharacter = Search:IsAllowedBy(characterName, NAME_CHARACTERS)
						if allowedByCharacter then break end
					end
				end

				local tempSkillName = Text:GetTextBetween(skill.skillLink, '%[', ']')
				if Search.skills[tempSkillName] == nil then
					Search.skills[tempSkillName] = {}
					Search.skills.skills[tempSkillName] = skill

					Search.skills.radios[tempSkillName] = {}
				end
				
				local radio = Search.skills.radios[tempSkillName]
				-- GT.Log:Info('Search_PopulateSkills_Allowed', NAME_PROFESSIONS, allowedByProfession, NAME_SKILLS, allowedBySkill, NAME_REAGENTS, allowedByReagent, NAME_CHARACTERS, allowedByCharacter)
				if allowedByProfession and (allowedBySkill or allowedByReagent or allowedByCharacter) then
					radio.shown = true
				else
					radio.shown = false
				end
			end
		end
	end

	local sortedKeys = Table:GetSortedKeys(Search.skills.skills, function(a, b) return a < b end, true)
	for _, skillName in ipairs(sortedKeys) do
		local searchRadio = Search.skills.radios[skillName]
		if searchRadio.shown then
			-- GT.Log:Info('Search_PopulateSkills_AddSkill', skillName, searchSkill.shown)
			local skill = Search.skills.skills[skillName]

			local radio = AceGUI:Create('CheckBox')
			radio:SetType('radio')
			radio:SetCallback('OnValueChanged', function(widget, event, value) Search:OnSkillClick(widget, event, value) end)
			radio:SetCallback('OnEnter', function(widget, event, value) Search:OnSkillEnter(widget, event, value) end)
			radio:SetCallback('OnLeave', function(widget, event, value) Search:OnSkillLeave(widget, event, value) end)
			radio:SetLabel(skill.skillLink)
			radio.skill = skill

			searchRadio.radio = radio


			Search.frames.scroll[NAME_SKILLS]:AddChild(radio)
		end
	end
end

function Search:PopulateReagents()
	if Search.state.clicks[NAME_SKILLS] == nil then return end

	Search.reagents.reagents = {}
	Search.reagents.radios = {}

	Search.frames.scroll[NAME_REAGENTS]:ReleaseChildren()

	local skill = Search.state.clicks[NAME_SKILLS]
	GT.Log:Info('Search_PopulateReagents', skill.skillName)

	local sortedKeys = Table:GetSortedKeys(skill.reagents, function(a, b) return a < b end, true)
	for _, reagentName in pairs(sortedKeys) do
		local reagent = skill.reagents[reagentName]
		GT.Log:Info(reagent)
		Search.reagents.reagents[reagentName] = reagent
		local searchReagent = Search.reagents.reagents[reagentName]

		local radio = AceGUI:Create('CheckBox')
		radio:SetType('radio')
		radio:SetCallback('OnValueChanged', function(widget, event, value) Search:OnReagentClick(widget, event, value) end)
		radio:SetCallback('OnEnter', function(widget, event, value) Search:OnReagentEnter(widget, event, value) end)
		radio:SetCallback('OnLeave', function(widget, event, value) Search:OnReagentLeave(widget, event, value) end)
		radio:SetLabel(reagentName)

		radio.reagent = reagent

		if reagent.reagentLink ~= nil then
			local reagentLink = raegent.reagentLink
			radio:SetLabel(reagentLink)
			radio.reagentLink = reagentLink
		end

		Search.reagents.radios[reagentName].radio = radio

		Search.frames.scroll[NAME_REAGENTS]:AddChild(radio)
	end
end

function Search:PopulateCharacters()
	GT.Log:Info('Search_PopulateCharacters')
	Search.characters.characters = {}
	Search.characters.radios = {}

	Search.frames.scroll[NAME_CHARACTERS]:ReleaseChildren()

	local characters = GT.DBCharacter:GetCharacters()
	for characterName, character in pairs(characters) do
		GT.Log:Info('Search_PopulateCharacters_Character', characterName)

		Search.characters.characters[characterName] = character

		for tempSkillName, _ in pairs(Search.skills) do
			local tempSkill = Search.skills[tempSkillName]
			if tempSkill.radio ~= nil then
				local skillName = tempSkill.skill.skillName
				if GT.DBCharacter:HasSkill(characterName, skillName) then
					GT.Log:Info('Search_PopulateCharacters_HasSkill', characterName, skillName)
					local radio = AceGUI:Create('CheckBox')
					radio:SetType('radio')
					radio:SetCallback('OnValueChanged', function(widget, event, value) Search:OnCharacterClick(widget, event, value) end)
					radio:SetCallback('OnEnter', function(widget, event, value) Search:OnCharacterEnter(widget, event, value) end)
					radio:SetCallback('OnLeave', function(widget, event, value) Search:OnCharacterLeave(widget, event, value) end)

					local labelText = GT.L['OFFLINE_TAG']
					if character.isOnline then
						labelText = GT.L['ONLINE_TAG']
					end
					local labelText = string.gsub(labelText, '%{{guild_member}}', characterName)

					local classColor = UNKNOWN_CLASS_COLOR
					if character.class ~= 'UNKNOWN' then
						classColor = RCC[character.class]
					end
					labelText = string.gsub(labelText, '%{{class_color}}', classColor)

					radio:SetLabel(labelText)

					radio.character = character

					Search.characters.radios[characterName].radio = radio

					Search.frames.scroll[NAME_CHARACTERS]:AddChild(radio)
				end
			end
		end
	end
end

function Search:IsAllowedBy(itemName, searchName)
	itemName = string.lower(itemName)
	local click = Text:Lower(Search.state.clicks[searchName])
	local text = Text:Lower(Search.state.text[searchName])

	local allowedByClick = false
	local allowedByText = false

	if click == nil or click == itemName then
		allowedByClick = true
	end

	if text == nil or string.find(itemName, text) then
		allowedByText = true
	end
	return allowedByClick or allowedByText
end

----- POPULATION END -----
----- START RADIO MANAGEMENT -----
	----- START SKILL RADIO MANAGEMENT -----

	function Search:OnSkillClick(widget, event, value)
		local skill = widget.skill
		local skillName = skill.skillName
		GT.Log:Info('Search_OnSkillClick', skillName, value)

		for tempSkillName, _ in pairs(Search.skills.skills) do
			if tempSkillName ~= Text:GetTextBetween(skill.skillLink, '%[', ']') then
				local radio = Search.skills.radios[tempSkillName].radio
				if radio ~= nil then
					radio:SetValue(false)
				end
			end
		end

		if value == true then
			Search.state.clicks[NAME_SKILLS] = skill
		else
			Search.state.clicks[NAME_SKILLS] = nil
		end
		Search:PopulateReagents()
	end

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

	----- END SKILL RADIO MANAGEMENT -----
	----- START REAGENT RADIO MANAGEMENT -----

	function Search:OnReagentClick(widget, event, value)
		local reagent = widget.reagent
		local reagentName = reagent.reagentName
		GT.Log:Info('Search_OnReagentClick', reagentName, value)

		for tempReagentName, _ in pairs(Search.reagents.reagents) do
			if tempReagentName ~= reagentName then
				Search.reagents.radios[tempReagentName].radio:SetValue(false)
			end
		end

		if value == true then
			Search.state.clicks[NAME_REAGENTS] = reagent
		else
			Search.state.clicks[NAME_REAGENTS] = nil
		end
	end

	function Search:OnReagentEnter(widget, event, value)
		local reagent = widget.reagent
		GT.Log:Info('Search_OnReagentEnter', reagent.reagentName)
		GameTooltip:Hide()
		if reagent.reagentLink ~= nil then
			GameTooltip:SetOwner(widget.frame, 'ANCHOR_RIGHT')
			GameTooltip:SetHyperlink(widget.text:GetText())
			GameTooltip:Show()
		end
	end

	function Search:OnReagentLeave(widget, event, value)
		local reagent = widget.reagent
		GT.Log:Info('Search_OnReagentLeave', reagent.reagentName)
		GameTooltip:Hide()
	end

	----- START REAGENT RADIO MANAGEMENT -----
	----- START CHARACTER RADIO MANAGEMENT -----

	function Search:OnCharacterClick(widget, event, value)
		local character = widget.character
		GT.Log:Info('Search_OnCharacterClick', character.characterName)
	end

	function Search:OnCharacterEnter(widget, event, value)
		local character = widget.character
		GT.Log:Info('Search_OnCharacterEnter', character.characterName)
	end

	function Search:OnCharacterLeave(widget, event, value)
		local character = widget.character
		GT.Log:Info('Search_OnCharacterLeave', character.characterName)
	end

	----- END CHARACER RADIO MANAGEMENT -----
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
	Search:ResetClicks()

	GT.DB:SetSearch(professionName, value)

	Search:PopulateSkills()
	Search:PopulateReagents()
	Search:PopulateCharacters()
end

function Search:OnSkillSearch(widget, event, value)
	if event == '' then event = nil end
	GT.Log:Info('Search_OnSkillSearch', Text:ToString(event))
	Search.state.text[NAME_SKILLS] = event
	-- Search:PopulateSkills(true)
end

function Search:OnReagentSearch(widget, event, value)
	if event == '' then event = nil end
	GT.Log:Info('Search_OnReagentSearch', Text:ToString(event))
	Search.state.text[NAME_REAGENTS] = event
end

function Search:OnCharacterSearch(widget, event, value)
	if event == '' then event = nil end
	GT.Log:Info('Search_OnCharacterSearch', Text:ToString(event))
	Search.state.text[NAME_CHARACTERS] = event
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
	Search.lastSkillClicked = nil
	Search.lastSkillLinkClicked = nil
	Search.lastReagentClicked = nil
	Search.lastCharacterClicked = nil

	if Search.mainFrame == nil then return false end
	
	GT.Log:Info('Search_OnClose_Release')
	Search.mainFrame:ReleaseChildren()
	AceGUI:Release(Search.mainFrame)

	Search.mainFrame = nil
	Search.skillScrollFrame = nil
	Search.reagentScrollFrame = nil
	Search.characterScrollFrame = nil
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
	Search:CreateScrollFrame(NAME_CHARACTERS)

	Search:CreateProfessionCheckBoxes()

	Search:PopulateSkills()
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
	end
end

function Search:CreateScrollFrame(name)
	local scrollContainer = AceGUI:Create('SimpleGroup')
	scrollContainer:SetRelativeWidth(1/4)
	scrollContainer:SetFullHeight(true)
	scrollContainer:SetLayout('Fill')
	Search.mainFrame:AddChild(scrollContainer)
	scrollContainer:ClearAllPoints()

	local scrollFrame = AceGUI:Create('ScrollFrame')
	scrollFrame:SetFullWidth(true)
	scrollFrame:SetFullHeight(true)
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