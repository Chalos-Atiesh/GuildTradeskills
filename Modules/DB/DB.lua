local AddOnName = ...

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local DB = GT:NewModule('DB')
GT.DB = DB

DB.valid = true

local DEFAULT_SHOULD_PRINT_LOGIN_MESSAGE = true

function DB:OnEnable()
	DB.db = DB.db or LibStub('AceDB-3.0'):New('GTDB')

	if DB.db.char == nil then
		DB.db.char = {}
	end

	if DB.db.char.search == nil then
		DB.db.char.search = {}
	end

	if DB.db.global == nil then
		DB.db.global = {}
	end

	if DB.db.global.versionNotification == nil then
		DB.db.global.versionNotification = GT:GetCurrentVersion()
	end

	if DB.db.global.chatFrameNumber == nil then
		DB.db.global.chatFrameNumber = GT.Log.DEFAULT_CHAT_FRAME
	end

	if DB.db.global.shouldPrintLoginMessage == nil then
		DB.db.global.shouldPrintLoginMessage = DEFAULT_SHOULD_PRINT_LOGIN_MESSAGE
	end

	GT.DBProfession:Enable()
	GT.DBCharacter:Enable()
	GT.DBComm:Enable()

	DB.valid = DB:Validate()
end

function DB:Reset()
	GT.Log:Info('DB_Reset')
	DB.db.global.versionNotification = 0
	DB.db.global.chatFrameNumber = GT.Log.DEFAULT_CHAT_FRAME

	DB.db.char.search = {}

	GT.DBProfession:Reset()
	GT.DBCharacter:Reset()
	GT.DBComm:Reset()
end

----- START VERSION -----

function DB:GetVersionNotification()
	return DB.db.global.versionNotification
end

function DB:SetVersionNotification(version)
	if version > DB.db.global.versionNotification then
		DB.db.global.versionNotification = version
		return true
	end
	return false
end

----- END VERSION -----
----- START LOGIN MESSAGE -----

function DB:GetShouldPrintLoginMessage()
	return DB.db.global.shouldPrintLoginMessage
end

function DB:SetShouldPrintLoginMessage(shouldPrintLoginMessage)
	DB.db.global.shouldPrintLoginMessage = shouldPrintLoginMessage
end

----- END LOGIN MESSAGE -----
----- START CHAT FRAME -----

function DB:GetChatFrameNumber()
	if DB.db == nil then
		return GT.Log.DEFAULT_CHAT_FRAME
	end
	return DB.db.global.chatFrameNumber
end

function DB:SetChatFrameNumber(frameNumber)
	DB.db.global.chatFrameNumber = frameNumber
end

----- END CHAT FRAME -----
----- SEARCH START -----

function DB:GetSearch(searchField)
	if DB.db.char.search[searchField] == nil then
		return nil
	end
	return DB.db.char.search[searchField]
end

function DB:SetSearch(searchField, searchTerm)
	DB.db.char.search[searchField] = searchTerm
end

----- SEARCH END -----

----- VALIDATION START -----

function DB:Validate()
	GT.Log:Info('DB_Validate', 'DBProfession', GT.DBProfession.valid, 'DBCharacter', GT.DBCharacter.valid, 'DBComm', GT.DBComm.valid)
	return GT.DBProfession.valid and GT.DBCharacter.valid and GT.DBComm.valid
end

----- VALIDATION END -----