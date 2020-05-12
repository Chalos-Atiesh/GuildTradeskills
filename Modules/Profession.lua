local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnName, true)

local Profession = GT:NewModule('Profession')
GT.Profession = Profession

Profession.adding = false

function Profession:InitAddProfession()
	GT.Log:Info('Profession_AddProfession')
	if not Profession.adding then
		GT.Log:PlayerInfo(L['PROFESSION_ADD_INIT'])
		Profession.adding = true
	else
		GT.Log:PlayerInfo(L['PROFESSION_ADD_CANCEL'])
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
		GT.Log:Info('Profession_AddProfession', professionName)
		profession = GT.DB:AddProfession(characterName, professionName)

		local msg = L['PROFESSION_ADD_SUCCESS']
		msg = string.gsub(msg, '%{{character_name}}', characterName)
		msg = string.gsub(msg, '%{{profession_name}}', professionName)
		GT.Log:PlayerInfo(msg)
	else
		profession = GT.DB:GetProfession(characterName, professionName)
	end
	if profession == nil then
		GT.Log:Info('Profession_AddProfession_NilProfession', professionName)
		return
	end

	if Profession.adding then
	    CloseTradeSkill()
	    CloseCraft()
	end

	local updated = Profession:UpdateProfession(profession)

	GT.Comm:SendTimestamps()

	Profession.adding = false
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
			local newSkill = false
			if GT.DB:GetSkill(characterName, profession.professionName, skillName) == nil then
				GT.Log:Info('Profession_UpdateProfession_AddSkill', characterName, profession.professionName, skillName, skillLink)
				skill = GT.DB:AddSkill(characterName, profession.professionName, skillName, skillLink)
				profession.lastUpdate = time()
				updated = true
				newSkill = true
			end

			if newSkill then
				for j = 1, GetTradeSkillNumReagents(i) do
					local reagentName, _, reagentCount = GetTradeSkillReagentInfo(i, j)
					if reagentName then
						GT.Log:Info('Profession_UpdateProfession_AddReagent', profession.professionName, skillName, reagentName, reagentCount)
						GT.DB:AddReagent(profession.professionName, skillName, reagentName, reagentCount)
					end
				end
			end
		end
	end

	return updated
end

function Profession:DeleteProfession(characterName, professionName)
	GT.Log:Info('Profession_RemoveProfession', characterName, professionName)
	if professionName == nil then
		GT.Log:PlayerError(L['PROFESSION_REMOVE_NIL_PROFESSION'])
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
		local message = string.gsub(L['PROFESSION_REMOVE_SUCCESS'], '%{{character_name}}', characterName)
		message = string.gsub(message, '%{{profession_name}}', professionName)
		GT.Log:PlayerInfo(message)
		GT.Comm:SendDeletions()
	else
		local message = string.gsub(L['PROFESSION_REMOVE_NOT_FOUND'], '%{{character_name}}', characterName)
		message = string.gsub(message, '%{{profession_name}}', professionName)
		GT.Log:PlayerError(message)
	end
end
