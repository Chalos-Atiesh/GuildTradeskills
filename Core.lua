local AddOnName, GT = ...

GT = LibStub('AceAddon-3.0'):NewAddon(AddOnName, 'AceComm-3.0', 'AceConsole-3.0', 'AceEvent-3.0')

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnName, true)

---------- START LOAD LIBRARIES ----------

GT.Text = LibStub:GetLibrary('GTText')
GT.Table = LibStub:GetLibrary('GTTable')

---------- END LOAD LIBRARIES ----------

GT.resetWarned = false
GT.version = '@project-version@'

local INITIAL_DELAY = 15

function GT:OnInitialize()
	GT.Log:Enable()

	GT.Log:Info('GT_OnInitialize')

	GT.Command:Enable()
	GT.Event:Enable()

	GT:Wait(INITIAL_DELAY, GT['InitMessages'], 'Hello')
end

local waitTable = {};
local waitFrame = nil;

function GT:InitMessages()
	GT.Log:PlayerInfo(L['WELCOME'])
	GT.Comm:SendTimestamps()
	GT.Comm:SendVersion()
	if not GT.DB.valid then
		GT.Log:PlayerError(L['CORRUPTED_DATABASE'])
	end
end

function GT:OnDisable()
	GT.Log:Info('GT_OnDisable')
end

function GT:InitReset(tokens)
	tokens = GT.Table:Lower(tokens)
	GT.Log:Info('GT_InitReset', tokens)
	local force = false
	--@debug@
	if GT.Table:Contains(tokens, L['FORCE']) then
		GT.Log:PlayerWarn('Forcing reset.')
		tokens = GT.Table:RemoveByValue(tokens, L['FORCE'])
		force = true
	end
	--@end-debug@
	if not GT.resetWarned and not force then
		GT.Log:PlayerWarn(L['RESET_WARN'])
		GT.resetWarned = true
		return
	end
	GT.resetWarned = false

	if GT.Table:Contains(tokens, L['RESET_CANCEL']) then
		GT.Log:PlayerInfo(L['RESET_CANCEL'])
		return
	end

	if not GT.Table:Contains(tokens, L['RESET_EXPECT_COMFIRM']) and not force then
		local message = string.gsub(L['RESET_UNKNOWN'], '%{{token}}', GT.Text:Concat(' ', tokens))
		GT.Log:PlayerWarn(message)
		return
	end

	if GT.Table:Contains(tokens, L['CHARACTER']) then
		tokens = GT.Table:RemoveByValue(tokens, L['CHARACTER'])
		local characterName = GT.Table:RemoveToken(tokens)
		local message = string.gsub(L['RESET_CHARACTER'], '%{{character_name}}', characterName)
		GT.Log:PlayerWarn(message)
		GT:ResetCharacter(characterName)
		return
	end

	if GT.Table:Contains(tokens, L['PROFESSION']) then
		tokens = GT.Table:RemoveByValue(tokens, L['PROFESSION'])
		local professionName = GT.Table:RemoveToken(tokens)
		GT.Log:Info(tokens)
		GT.Log:Info(professionName)
		local message = string.gsub(L['RESET_PROFESSION'], '%{{profession_name}}', professionName)
		GT.Log:PlayerWarn(message)
		GT:ResetProfession(professionName)
		return
	end

	GT:Reset(force)
end

function GT:Reset(force)
	GT.Log:PlayerWarn(L['RESET_FINAL'])

	GT.Log:Reset(force)
	GT.DB:Reset(force)
end

function GT:ResetProfession(professionName, force)
	local reset = GT.DB:ResetProfession(professionName)
	if not reset then
		local message = string.gsub(L['PROFESSION_RESET_NOT_FOUND'], '%{{profession_name}}', professionName)
		GT.Log:PlayerError(message)
		return
	end
	local message = string.gsub(L['PROFESSION_RESET_FINAL'], '%{{profession_name}}', professionName)
	GT.Log:PlayerInfo(message)
end

function GT:ResetCharacter(characterName, force)
	local reset GT.DB:ResetCharacter(characterName)
	if not reset then
		local message = string.gsub(L['CHARACTER_RESET_NOT_FOUND'], '%{{character_name}}', characterName)
		GT.Log:PlayerError(message)
		return
	end
	local message = string.gsub(L['CHARACTER_RESET_FINAL'], '%{{character_name}}', characterName)
	GT.Log:PlayerInfo(message)
end

function GT:ConvertVersion(releaseVersion, betaVersion, alphaVersion)
	local rVersion = tonumber(releaseVersion) * 10000
	local bVersion = tonumber(betaVersion) * 100
	local aVersion = tonumber(alphaVersion)

	return rVersion + bVersion + aVersion
end

function GT:DeconvertVersion(version)
	GT.Log:Info('v', version)
	local rVersion = math.floor(version / 10000)
	GT.Log:Info('rVersion', rVersion)
	version = version - (rVersion * 10000)
	GT.Log:Info('v', version)
	local bVersion = math.floor(version / 100)
	GT.Log:Info('bVersion', bVersion)
	local aVersion = version - (bVersion * 100)
	GT.Log:Info('aVersion', aVersion)
	return rVersion, bVersion, aVersion
end

function GT:GetCurrentVersion()
	local version = GT:ConvertVersion(98, 99, 99)
	--@debug@
	if true then
		GT.DB:InitVersion(version)
		GT.Log:Info('GT_GetCurrentVersion', version)
		return version
	end
	--@end-debug@
	local tokens = GT.Text:Tokenize(GT.version, '_')
	local version = tokens[2]
	tokens = GT.Text:Tokenize(version, '.')
	rVersion, tokens = GT.Table:RemoveToken(tokens)
	bVersion, tokens = GT.Table:RemoveToken(tokens)
	aVersion, tokens = GT.Table:RemoveToken(tokens)

	version = GT:ConvertVersion(rVersion, bVersion, aVersion)
	GT.Log:Info('GT_GetCurrentVersion', version)

	GT.DB:InitVersion(version)

	return version
end

function GT:Wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
    waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{...}});
  return true;
end