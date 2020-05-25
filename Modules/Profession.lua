local AddOnName = ...

local CallbackHandler = LibStub("CallbackHandler-1.0")

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local Profession = GT:NewModule('Profession')
GT.Profession = Profession

Profession.callbacks = Profession.callbacks or CallbackHandler:New(Profession)

local ADD_PROFESSION = 'ADD_PROFESSION'

Profession.adding = false

local STATIC_PROFESSION_ADD = 'STATIC_PROFESSION_ADD'

local staticProfessionAdd = {
	text = GT.L[STATIC_PROFESSION_ADD],
	button1 = GT.L['OKAY'],
	timeout = 5,
	hideOnEscape = true
}

function Profession:InitAddProfession(callback)
	GT.Log:Info('Profession_AddProfession')
	if not Profession.adding then
		StaticPopupDialogs[STATIC_PROFESSION_ADD] = staticProfessionAdd
		StaticPopup_Show(STATIC_PROFESSION_ADD)
		Profession.adding = true
		if callback ~= nil then
			Profession:RegisterCallback(ADD_PROFESSION, callback)
		end
	else
		StaticPopup_Hide(STATIC_PROFESSION_ADD)
		GT.Log:PlayerInfo(GT.L['PROFESSION_ADD_CANCEL'])
		Profession.adding = false
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

	local characterName = UnitName('player')
	local profession = nil
	if Profession.adding then
		GT.Log:Info('Profession_AddProfession', characterName, professionName)
		profession = GT.DB:AddProfession(characterName, professionName)

		local msg = GT.L['PROFESSION_ADD_SUCCESS']
		msg = string.gsub(msg, '%{{profession_name}}', professionName)
		GT.Log:PlayerInfo(msg)
	else
		GT.Log:Info('Profession_AddProfession_NotAdding', nil, professionName)
		profession = GT.DB:AddProfession(nil, professionName)
	end

	if Profession.adding then
	    CloseTradeSkill()
	    CloseCraft()
	end

	local updated = Profession:UpdateProfession(profession)
	
	if GT.DB:GetProfession(characterName, professionName) == nil then
		GT.Log:Info('Profession_AddProfession_NilProfession', professionName)
		return
	end
	--[===[@non-debug@
	if updated then
	--@end-non-debug@]===]
		GT.CommGuild:RequestStartVote()
	--[===[@non-debug@
	end
	--@end-non-debug@]===]

	Profession.adding = false
	StaticPopup_Hide(STATIC_PROFESSION_ADD)
	Profession.callbacks:Fire(ADD_PROFESSION, profession)
	Profession.UnregisterCallback(ADD_PROFESSION, ADD_PROFESSION)
end

function Profession:UpdateProfession(profession)
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

	local updated = false
	for i = 1, GetNumTradeSkills() do
		local skillName, kind, num = GetTradeSkillInfo(i)

		if kind and kind ~= 'header' and kind ~= 'subheader' then
			local skillLink = GetTradeSkillItemLink(i)

			if Profession.adding then
				if GT.DB:GetSkill(characterName, profession.professionName, skillName) == nil then
					GT.Log:Info('Profession_UpdateProfession_AddProfession', characterName, profession.professionName, skillName, skillLink)
					skill = GT.DB:AddSkill(characterName, profession.professionName, skillName, skillLink)
					profession.lastUpdate = time()
					updated = true
				end
			else
				GT.DB:AddSkill(nil, profession.professionName, skillName, skillLink)
			end

			for j = 1, GetTradeSkillNumReagents(i) do
				local reagentAdded = false
				local retries = 0
				while not reagentAdded and retries < 4 do
					local reagentName, _, reagentCount = GetTradeSkillReagentInfo(i, j)
					if reagentName then
						-- GT.Log:Info('Profession_UpdateProfession_AddReagent', profession.professionName, skillName, reagentName, reagentCount)
						GT.DB:AddReagent(profession.professionName, skillName, reagentName, reagentCount)
						reagentAdded = true
					end
					retries = retries + 1
				end
			end
		end
	end

	return updated
end

function Profession:DeleteProfession(tokens)
	GT.Log:Info('Profession_RemoveProfession', tokens)

	local characterName = UnitName('player')
	local professionName = GT.Table:RemoveToken(tokens)
	
	if professionName == nil then
		GT.Log:PlayerError(GT.L['PROFESSION_REMOVE_NIL_PROFESSION'])
		return
	end

	local professions = GT.DB:GetCharacter(characterName).professions

	local removed = false
	for dbProfessionName, _ in pairs(professions) do
		if string.lower(dbProfessionName) == string.lower(professionName) then
			removed = GT.DB:DeleteProfession(characterName, dbProfessionName)
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
