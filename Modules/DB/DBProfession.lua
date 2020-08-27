local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local DBProfession = GT:NewModule('DBProfession')
GT.DBProfession = DBProfession

DBProfession.valid = true

function DBProfession:OnEnable()
	GT.Log:Info('DBProfession_OnEnable')
	DBProfession.db = DBProfession.db or LibStub('AceDB-3.0'):New('GTDB')

	if DBProfession.db.global.professions == nil then
		DBProfession.db.global.professions = {}
	end

	--@debug@
	-- DBProfession.db.global.professions = {}
	--@end-debug@

	DBProfession.valid = DBProfession:Validate()
end

function DBProfession:Reset()
	GT.Log:Info('DBProfession_Reset')
	DBProfession.db.global.professions = {}
end
----- PROFESSION START -----

function DBProfession:ProfessionExists(professionName)
	if professionName == nil then return false end
	professionName = string.lower(professionName)

	local professions = DBProfession.db.global.professions
	for tempProfessionName, _ in pairs(professions) do
		if string.lower(tempProfessionName) == professionName then
			return true
		end
	end
	return false
end

function DBProfession:GetProfessions()
	return DBProfession.db.global.professions
end

function DBProfession:GetProfession(professionName)
	if not DBProfession:ProfessionExists(professionName) then return nil end
	professionName = string.lower(professionName)

	local professions = DBProfession:GetProfessions()
	for tempProfessionName, profession in pairs(professions) do
		if string.lower(tempProfessionName) == professionName then
			return profession
		end
	end
	return nil
end

function DBProfession:AddProfession(professionName)
	if professionName == nil then return nil end
	local professions = DBProfession:GetProfessions()
	professions = Table:InsertField(professions, professionName)

	local profession = DBProfession:GetProfession(professionName)

	profession.professionName = professionName

	if profession.skills == nil then
		profession.skills = {}
	end
	return profession
end

function DBProfession:DeleteProfession(professionName)
	if not DBProfession:ProfessionExists(professionName) then return false end
	professionName = string.lower(professionName)

	local professions = DBProfession:GetProfessions()
	for tempProfessionName, _ in pairs(professions) do
		if string.lower(tempProfessionName) == professionName then
			professions[tempProfessionName] = nil
			return true
		end
	end
	return false
end

----- PROFESSION END -----
----- SKILL START -----

function DBProfession:SkillExists(professionName, skillName)
	if skillName == nil then return false end
	if not DBProfession:ProfessionExists(professionName) then return false end
	skillName = string.lower(skillName)

	local skills = DBProfession:GetSkills(professionName, skillName)
	for tempSkillName, _ in pairs(skills) do
		if string.lower(tempSkillName) == skillName then
			return true
		end
	end
	return false
end

function DBProfession:GetSkills(professionName)
	if not DBProfession:ProfessionExists(professionName) then return nil end
	return DBProfession:GetProfession(professionName).skills
end

function DBProfession:GetSkill(professionName, skillName)
	if not DBProfession:SkillExists(professionName, skillName) then return nil end
	skillName = string.lower(skillName)

	local skills = DBProfession:GetSkills(professionName)
	for tempSkillName, skill in pairs(skills) do
		if string.lower(tempSkillName) == skillName then
			return skill
		end
	end
	return nil
end

function DBProfession:AddSkill(professionName, skillName, skillLink)
	if skillName == nil then return nil end
	if skillLink == nil then return nil end
	if not DBProfession:ProfessionExists(professionName) then return nil end

	local skills = DBProfession:GetSkills(professionName)
	skills = Table:InsertField(skills, skillName)

	local skill = DBProfession:GetSkill(professionName, skillName)

	skill.skillName = skillName
	skill.skillLink = skillLink

	if skill.reagents == nil then
		skill.reagents = {}
	end
end

function DBProfession:DeleteSkill(professionName, skillName)
	if not DBProfession:SkillExists(professionName, skillName) then return false end
	skillName = string.lower(skillName)

	local skills = DBProfession:GetSkills(professionName)
	for tempSkillName, _ in pairs(skills) do
		if string.lower(tempSkillName) == skillName then
			skills[tempSkillName] = nil
			return true
		end
	end
	return false
end

----- SKILL END -----
----- REAGENTS START -----

function DBProfession:ReagentExists(professionName, skillName, reagentName)
	if reagentName == nil then return false end
	if not DBProfession:SkillExists(professionName, skillName) then return false end
	reagentName = string.lower(reagentName)

	local reagents = DBProfession:GetReagents(professionName, skillName)
	for tempReagentName, _ in pairs(reagents) do
		if string.lower(tempReagentName) == reagentName then
			return true
		end
	end
	return false
end

function DBProfession:GetReagents(professionName, skillName)
	if not DBProfession:SkillExists(professionName, skillName) then return nil end
	return DBProfession:GetSkill(professionName, skillName).reagents
end

function DBProfession:GetReagent(professionName, skillName, reagentName)
	if not DBProfession:ReagentExists(professionName, skillName, reagentName) then return nil end
	reagentName = string.lower(reagentName)

	local reagents = DBProfession:GetReagents(professionName, skillName)
	for tempReagentName, reagent in pairs(reagents) do
		if string.lower(tempReagentName) == reagentName then
			return reagent
		end
	end
	return nil
end

function DBProfession:AddReagent(professionName, skillName, reagentName, reagentLink, reagentCount)
	if reagentName == nil then return nil end
	if reagentCount == nil then return nil end
	if not DBProfession:SkillExists(professionName, skillName) then return nil end

	local reagents = DBProfession:GetReagents(professionName, skillName)
	reagents = Table:InsertField(reagents, reagentName)

	local reagent = DBProfession:GetReagent(professionName, skillName, reagentName)

	reagent.reagentName = reagentName
	if reagentLink ~= nil then
		reagent.reagentLink = reagentLink
	end
	reagent.reagentCount = tonumber(reagentCount)

	return reagent
end

function DBProfession:DeleteReagent(professionName, skillName, reagentName)
	if not DBProfession:ReagentExists(professionName, skillName, reagentName) then return false end
	reagentName = string.lower(reagentName)

	local reagents = DBProfession:GetReagents(professionName, skillName)
	for tempReagentName, _ in pairs(reagents) do
		if string.lower(tempReagentName) == reagentName then
			reagents[tempReagentName] = nil
			return true
		end
	end
	return false
end

----- REAGENTS END -----
----- VALIDATION START -----

function DBProfession:Validate()
	DBProfession:_ValidateStructure()
	return DBProfession:_ValidateData()
end

function DBProfession:_ValidateStructure()
	local professions = DBProfession.db.global.professions
	for professionName, profession in pairs(professions) do
		if profession.skills == nil then
			profession.skills = {}
		end
		local skills = profession.skills
		for skillName, skill in pairs(skills) do
			if skill.reagents == nil then
				skill.reagents = {}
			end
		end
	end
end

function DBProfession:_ValidateData()
	local valid = true

	local professions = DBProfession.db.global.professions
	for professionName, profession in pairs(professions) do

		if GTText:IsNumber(professionName) or GTText:IsLink(professionName) then
			GT.Log:Error('Invalid professionName', professionName)
			valid = false
		end

		if profession.professionName == nil then
			profession.professionName = professionName
		end
		local lastUpdate = profession.lastUpdate
		if lastUpdate == nil or not GTText:IsNumber(lastUpdate) then
			lastUpdate = time()
		end

		local tempProfessionName = profession.professionName
		if GTText:IsNumber(tempProfessionName) or GTText:IsLink(tempProfessionName) then
			GT.Log:Error('Invalid profession.professionName', tempProfessionName)
			valid = false
		end

		local skills = profession.skills
		for skillName, skill in pairs(skills) do

			if GTText:IsNumber(skillName) or GTText:IsLink(skillName) then
				GT.Log:Error('Invalid skillName', skillName)
				valid = false
			end

			if skill.skillName == nil then
				skill.skillName = skillName
			end

			local tempSkillName = skill.skillName
			if GTText:IsNumber(tempSkillName) or GTText:IsLink(tempSkillName) then
				GT.Log:Error('Invalid skill.skillName', tempSkillName)
				valid = false
			end

			if skill.skillLink == nil or GTText:IsNumber(skill.skillLink) or not GTText:IsLink(skill.skillLink) then
				GT.Log:Error('Invalid skill.skillLink', GTText:ToString(skill.skillLink))
				valid = false
			end

			local reagents = skill.reagents
			for reagentName, reagent in pairs(reagents) do
				if GTText:IsNumber(reagentName) or GTText:IsLink(reagentName) then
					GT.Log:Error('Invalid reagentName', reagentName)
					valid = false
				end

				if reagent.reagentName == nil then
					reagent.reagentName = reagentName
				end

				local tempReagentName = reagent.reagentName
				if GTText:IsNumber(tempReagentName) or GTText:IsLink(tempReagentName) then
					GT.Log:Error('Invalid reagent.reagentName', reagentName)
					valid = false
				end

				if reagent.reagentCount ~= nil and type(reagent.reagentCount) ~= 'number' then
					reagent.reagentCount = tonumber(reagent.reagentCount)
				end

				if reagent.reagentCount == nil then
					reagent.reagentCount = 0
				end

				local reagentCount = reagent.reagentCount
				if not GTText:IsNumber(reagentCount) or reagentCount <= 0 then
					GT.Log:Error('Invalid reagentCount', reagentCount)
					valid = false
				end
			end
		end
	end
	return valid
end

----- VALIDATION END -----