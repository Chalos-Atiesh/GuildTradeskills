local AddOnName = ...

local CallbackHandler = LibStub("CallbackHandler-1.0")

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local Profession = GT:NewModule('Profession')
GT.Profession = Profession

Profession.callbacks = Profession.callbacks or CallbackHandler:New(Profession)

local ADD_PROFESSION = 'ADD_PROFESSION'
local STATIC_PROFESSION_ADD = 'STATIC_PROFESSION_ADD'

local adding = false
local callbackQueue = {}
local profession = nil

local staticProfessionAdd = {
	text = GT.L[STATIC_PROFESSION_ADD],
	button1 = GT.L['OKAY'],
	timeout = 5,
	hideOnEscape = true
}

function Profession:InitAddProfession(callback)
	GT.Log:Info('Profession_AddProfession')
	if not adding then
		StaticPopupDialogs[STATIC_PROFESSION_ADD] = staticProfessionAdd
		StaticPopup_Show(STATIC_PROFESSION_ADD)
		adding = true
		if callback ~= nil then
			Profession:RegisterCallback(ADD_PROFESSION, callback)
			table.insert(callbackQueue, callback)
		end
	else
		StaticPopup_Hide(STATIC_PROFESSION_ADD)
		GT.Log:PlayerInfo(GT.L['PROFESSION_ADD_CANCEL'])
		adding = false
	end
end

function Profession:AddProfession()
	GT.Log:Info('Profession_UpdateProfession')

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
		GT.Log:Info('Profession_AddProfession', characterName, professionName)
		profession = GT.DBCharacter:AddProfession(characterName, professionName)
	end

	GT:ScheduleTimer(Profession['UpdateProfession'], 1)
end

function Profession:UpdateProfession()
	if profession == nil then return end
	GT.Log:Info('Profession_UpdateProfession' , profession.professionName)

	local GetNumTradeSkills = GetNumTradeSkills
	local GetTradeSkillInfo = GetTradeSkillInfo
	local GetTradeSkillItemLink = GetTradeSkillItemLink
	local GetTradeSkillNumReagents = GetTradeSkillNumReagents
	local GetTradeSkillReagentInfo = GetTradeSkillReagentInfo

	if profession.professionName == 'Enchanting' then
		GetNumTradeSkills = GetNumCrafts
		GetTradeSkillItemLink = GetCraftItemLink
		GetTradeSkillNumReagents = GetCraftNumReagents
		GetTradeSkillReagentInfo = GetCraftReagentInfo

		GetTradeSkillInfo = function(i)
			local name, _, kind, num = GetCraftInfo(i)

			return name, kind, num
		end
	end

	local characterName = UnitName('player')

	local trackingProfession = GT.DBCharacter:ProfessionExists(characterName, profession.professionName)

	local updated = false
	for i = 1, GetNumTradeSkills() do
		local skillName, kind, num = GetTradeSkillInfo(i)

		if kind ~= nil and kind ~= 'header' and kind ~= 'subheader' then
			local skillLink = GetTradeSkillItemLink(i)
			GT.DBProfession:AddSkill(profession.professionName, skillName, skillLink)

			if adding or trackingProfession then
				if not GT.DBCharacter:SkillExists(characterName, profession.professionName, skillName) then
					GT.Log:Info('Profession_UpdateProfession_AddSkill', characterName, profession.professionName, skillName, skillLink)
					skill = GT.DBCharacter:AddSkill(characterName, profession.professionName, skillName, skillLink)
					profession.lastUpdate = time()
					updated = true
				end
			end

			for j = 1, GetTradeSkillNumReagents(i) do
				local reagentAdded = false
				local retries = 0
				while not reagentAdded and retries < 10 do
					local reagentName, _, reagentCount = GetTradeSkillReagentInfo(i, j)
					if reagentName ~= nil then
						reagentAdded = true
						if not GT.DBProfession:ReagentExists(profession.professionName, skillName, reagentName) then
							GT.Log:Info('Profession_UpdateProfession_AddReagent', profession.professionName, skillName, reagentName, reagentCount)
							local reagentLink = GetTradeSkillReagentItemLink(i, j)
							GT.DBProfession:AddReagent(profession.professionName, skillName, reagentName, reagentLink, reagentCount)
							reagentAdded = true
						end
					end
					retries = retries + 1
				end
				if not reagentAdded then
					GT.Log:Error('Profession_UpdateProfession_ReagentFailure', skillName, j)
				end
			end
		end
	end

	if adding then
	    CloseTradeSkill()
	    CloseCraft()

		local msg = GT.L['PROFESSION_ADD_SUCCESS']
		msg = string.gsub(msg, '%{{profession_name}}', profession.professionName)
		GT.Log:PlayerInfo(msg)
	end

	adding = false
	StaticPopup_Hide(STATIC_PROFESSION_ADD)
	Profession.callbacks:Fire(ADD_PROFESSION, profession)
	Profession.UnregisterCallback(ADD_PROFESSION, ADD_PROFESSION)

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
