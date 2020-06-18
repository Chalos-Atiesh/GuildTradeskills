local AddOnName = ...

local CallbackHandler = LibStub("CallbackHandler-1.0")

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local Profession = GT:NewModule('Profession')
GT.Profession = Profession

Profession.callbacks = Profession.callbacks or CallbackHandler:New(Profession)

local ADD_PROFESSION = 'ADD_PROFESSION'
local PROFESSION_ADD_INIT = 'PROFESSION_ADD_INIT'
local PROFESSION_ADD_PROGRESS = 'PROFESSION_ADD_PROGRESS'
local PROFESSION_ADD_SUCCESS = 'PROFESSION_ADD_SUCCESS'
local FRAME_DELAY = 10
local CANCEL_TIMER = 10

local callbackQueue = {}
local adding = false
local progressShown = false
local profession = nil

local POPUP_PROFESSION_ADD_INIT = {
	text = GT.L[PROFESSION_ADD_INIT],
	button1 = GT.L['OKAY'],
	timeout = 5,
	hideOnEscape = true
}

local POPUP_PROFESSION_ADD_PROGRESS = {
	text = GT.L[PROFESSION_ADD_PROGRESS],
	button1 = GT.L['OKAY'],
	timeout = 10,
	hideOnEscape = true
}

local POPUP_PROFESSION_ADD_SUCCESS = {
	text = GT.L[PROFESSION_ADD_SUCCESS],
	button1 = GT.L['OKAY'],
	timeout = 5,
	hideOnEscape = true
}

function Profession:InitAddProfession(callback)
	if not adding then
		GT.Log:Info('Profession_InitAddProfession')
		StaticPopupDialogs[PROFESSION_ADD_INIT] = POPUP_PROFESSION_ADD_INIT
		GT.Log:PlayerInfo(GT.L[PROFESSION_ADD_INIT])
		StaticPopup_Show(PROFESSION_ADD_INIT)

		adding = true

		GT:ScheduleTimer(Profession['CancelAddProfession'], CANCEL_TIMER)

		if callback ~= nil then
			GT.Log:Info('Profession_InitAddProfession_RegisterCallback')
			Profession:RegisterCallback(ADD_PROFESSION, callback)
			table.insert(callbackQueue, callback)
		end
	else
		StaticPopup_Hide(PROFESSION_ADD_INIT)
		GT.Log:PlayerInfo(GT.L['PROFESSION_ADD_CANCEL'])
		adding = false
	end
end

function Profession:CancelAddProfession()
	GT.Log:Info('Profession_CancelAddProfession')
	adding = false
end

function Profession:AddProfession()
	-- GT.Log:Info('Profession_AddProfession')
	StaticPopup_Hide(PROFESSION_ADD_INIT)

	local professionName = GetTradeSkillLine()
	if professionName == 'UNKNOWN' then
		professionName = GetCraftDisplaySkillLine()
	end
	if professionName == nil then
		GT.Log:Error('Profession_UpdateProfession_ProfessionNameNil')
		return
	end
	profession = GT.DBProfession:AddProfession(professionName)

	local characterName = UnitName('player')
	if adding then
		-- GT.Log:Info('Profession_AddProfession', characterName, professionName)
		if not progressShown then
			StaticPopupDialogs[PROFESSION_ADD_PROGRESS] = POPUP_PROFESSION_ADD_PROGRESS
			GT.Log:PlayerInfo(GT.L[PROFESSION_ADD_PROGRESS])
			StaticPopup_Show(PROFESSION_ADD_PROGRESS)
			progressShown = true
		end
		profession = GT.DBCharacter:AddProfession(characterName, professionName)
	end

	GT:FrameDelay(FRAME_DELAY, Profession['UpdateProfession'])
	-- GT:ScheduleTimer(Profession['UpdateProfession'], 1)
end

function Profession:UpdateProfession()
	if profession == nil then return end
	-- GT.Log:Info('Profession_UpdateProfession' , profession.professionName)

	local GetNumTradeSkills = GetNumTradeSkills
	local GetTradeSkillInfo = GetTradeSkillInfo
	local GetTradeSkillItemLink = GetTradeSkillItemLink
	local GetTradeSkillNumReagents = GetTradeSkillNumReagents
	local GetTradeSkillReagentInfo = GetTradeSkillReagentInfo
	local GetTradeSkillReagentItemLink = GetTradeSkillReagentItemLink

	if profession.professionName == 'Enchanting' then
		GetNumTradeSkills = GetNumCrafts
		GetTradeSkillItemLink = GetCraftItemLink
		GetTradeSkillNumReagents = GetCraftNumReagents
		GetTradeSkillReagentInfo = GetCraftReagentInfo
		GetTradeSkillReagentItemLink = GetCraftReagentItemLink

		GetTradeSkillInfo = function(i)
			local name, _, kind, num = GetCraftInfo(i)
			return name, kind, num
		end
	end

	local characterName = UnitName('player')

	local trackingProfession = GT.DBCharacter:ProfessionExists(characterName, profession.professionName)

	local _, kind = GetTradeSkillInfo(1)
	if kind == nil or (kind ~= 'header' and kind ~= 'optimal') then
		-- GT.Log:Warn('Profession_UpdateProfession_UnexpectedHeader', Text:ToString(kind))
		return
	end

	local updated = false
	for i = 1, GetNumTradeSkills() do
		local skillName, kind, num = GetTradeSkillInfo(i)

		if kind ~= nil and kind ~= 'header' and kind ~= 'subheader' then
			local skillLink = GetTradeSkillItemLink(i)
			GT.DBProfession:AddSkill(profession.professionName, skillName, skillLink)

			if adding or trackingProfession then
				if not GT.DBCharacter:SkillExists(characterName, profession.professionName, skillName) then
					-- GT.Log:Info('Profession_UpdateProfession_AddSkill', characterName, profession.professionName, skillName, skillLink)
					skill = GT.DBCharacter:AddSkill(characterName, profession.professionName, skillName, skillLink)
					profession.lastUpdate = time()
					updated = true
				end
			end

			for j = 1, GetTradeSkillNumReagents(i) do
				local reagent = nil
				local reagentName, _, reagentCount = GetTradeSkillReagentInfo(i, j)
				if reagentName == nil then
					-- GT.Log:Warn('Profession_UpdateProfession_UncookedData', profession.professionName, skillName, j)
					-- GT:ScheduleTimer(Profession['UpdateProfession'], 1)
					return
				else
					if not GT.DBProfession:ReagentExists(profession.professionName, skillName, reagentName) then
						local reagentLink = GetTradeSkillReagentItemLink(i, j)
						-- GT.Log:Info('Profession_UpdateProfession_AddReagent', profession.professionName, skillName, reagentName, reagentCount)
						reagent = GT.DBProfession:AddReagent(profession.professionName, skillName, reagentName, reagentLink, reagentCount)
						updated = true
					else
						reagent = GT.DBProfession:GetReagent(profession.professionName, skillName, reagentName)
					end
				end
				if reagent == nil then
					-- GT.Log:Error('Profession_UpdateProfession_ReagentFailure', skillName, j)
				end
			end
		end
	end

	StaticPopup_Hide(PROFESSION_ADD_PROGRESS)
	progressShown = false

	for _, callback in pairs(callbackQueue) do
		-- GT.Log:Info('Profession_UpdateProfession_Callback')
		Profession.callbacks:Fire(ADD_PROFESSION, profession)
		Profession.UnregisterCallback(callback, ADD_PROFESSION)
	end

	if adding then
	    CloseTradeSkill()
	    CloseCraft()

		message = string.gsub(GT.L['PROFESSION_ADD_SUCCESS'], '%{{profession_name}}', profession.professionName)
		POPUP_PROFESSION_ADD_SUCCESS.text = message
		StaticPopupDialogs[PROFESSION_ADD_SUCCESS] = POPUP_PROFESSION_ADD_SUCCESS

		GT.Log:PlayerInfo(message)
		StaticPopup_Show(PROFESSION_ADD_SUCCESS)
	end

	adding = false

	--[===[@non-debug@
	if updated then
	--@end-non-debug@]===]
		GT.CommGuild:RequestStartVote()
	--[===[@non-debug@
	end
	--@end-non-debug@]===]
end

function Profession:DeleteProfession(tokens)
	GT.Log:Info('Profession_RemoveProfession', tokens)

	local characterName = UnitName('player')
	local professionName = Table:RemoveToken(tokens)
	
	if professionName == nil then
		GT.Log:PlayerError(GT.L['PROFESSION_REMOVE_NIL_PROFESSION'])
		return
	end

	local professions = GT.DBCharacter:GetProfessions(characterName)

	local removed = false
	for dbProfessionName, _ in pairs(professions) do
		if string.lower(dbProfessionName) == string.lower(professionName) then
			removed = GT.DBCharacter:DeleteProfession(characterName, dbProfessionName)
			professionName = dbProfessionName
			break
		end
	end

	if removed then
		local message = string.gsub(GT.L['PROFESSION_REMOVE_SUCCESS'], '%{{character_name}}', characterName)
		message = string.gsub(message, '%{{profession_name}}', professionName)
		GT.Log:PlayerInfo(message)
		GT.Comm:SendDeletions()
	else
		local message = string.gsub(GT.L['PROFESSION_REMOVE_NOT_FOUND'], '%{{character_name}}', characterName)
		message = string.gsub(message, '%{{profession_name}}', professionName)
		GT.Log:PlayerError(message)
	end
end

function Profession:_GetProfessionName()

end