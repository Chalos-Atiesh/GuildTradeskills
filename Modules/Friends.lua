local AddOnName = ...

local CallbackHandler = LibStub("CallbackHandler-1.0")

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local Friends = GT:NewModule('Friends')
GT.Friends = Friends

Friends.callbacks = Friends.callbacks or CallbackHandler:New(Friends)

local ADD_FRIEND = 'ADD_FRIEND'
local FRIEND_ADDED = 'FRIEND_ADDED'
local IS_ONLINE = 'IS_ONLINE'
local GET_NAME = 'GET_NAME'
local GET_CLASS = 'GET_CLASS'

local friendsToRemove = {}
local addedFriends = {}
local pendingFriends = {}

local callbackQueue = {}

local initialized = false

function Friends:OnEnable()
	if initialized then return end
	-- GT.Log:Info('Friends_OnEnable')

	ChatFrame_AddMessageEventFilter('CHAT_MSG_SYSTEM', Friends['FakeFriendFilter'])
	Friends:PurgeFriendList()
	initialized = true
end

function Friends:AddFriend(characterName, callbackPrefix, callback)
	characterName = string.lower(characterName)

	if callback ~= nil then
		callbackQueue = GT.Table:Insert(callbackQueue, nil, callbackPrefix)
		local tempCallbackPrefix = GT.Text:Concat('_', callbackPrefix, ADD_FRIEND, characterName)
		Friends:RegisterCallback(tempCallbackPrefix, callback)
	end

	if not GT.Table:Contains(pendingFriends, characterName)
		and not GT.Table:Contains(addedFriends, characterName)
	then
		-- GT.Log:Info('Friends_AddFriend', characterName, callbackPrefix)
		pendingFriends = GT.Table:Insert(pendingFriends, nil, characterName)
		-- -- GT.Log:Info('Friends_AddFriend', characterName, callbackPrefix, pendingFriends)
		if not Friends:IsFriend(characterName) then
			friendsToRemove = GT.Table:Insert(friendsToRemove, nil, characterName)
		end
		Friends:RegisterCallback(GT.Text:Concat('_', FRIEND_ADDED, characterName), Friends['FriendAdded'])
		C_FriendList.AddFriend(characterName, AddOnName)
	end
end

function Friends:FriendAdded(info)
	local characterName = info.name
	local didFind = info.didFind
	-- GT.Log:Info('Friends_FriendAdded', characterName, didFind)

	local tempCharacterName = string.lower(characterName)
	pendingFriends = GT.Table:RemoveByValue(pendingFriends, tempCharacterName)
	if didFind then
		addedFriends = GT.Table:Insert(addedFriends, nil, tempCharacterName)
		for _, characterName in pairs(addedFriends) do
			local friendInfo = C_FriendList.GetFriendInfo(characterName)
			friendInfo.exists = true

			Friends:RemoveFriend(characterName)
			addedFriends = GT.Table:RemoveByValue(addedFriends, characterName)

			for i, callbackPrefix in pairs(callbackQueue) do
				local tempCallbackPrefix = GT.Text:Concat('_', callbackPrefix, ADD_FRIEND, tempCharacterName)
				Friends.callbacks:Fire(tempCallbackPrefix, friendInfo)
				Friends.UnregisterCallback(tempCallbackPrefix, tempCallbackPrefix)
				callbackQueue[i] = nil
			end
		end
	else
		for i, callbackPrefix in pairs(callbackQueue) do
			local tempCallbackPrefix = GT.Text:Concat('_', callbackPrefix, ADD_FRIEND, tempCharacterName)
			info.connected = false
			info.exists = false
			info.className = 'UNKNOWN'
			Friends.callbacks:Fire(tempCallbackPrefix, info)
			Friends.UnregisterCallback(tempCallbackPrefix, tempCallbackPrefix)
			callbackQueue[i] = nil
		end
	end
end

function Friends:GetCharacterName(characterName, callback)
	characterName = string.lower(characterName)
	local callbackPrefix = GT.Text:Concat('_', GET_NAME, characterName)
	Friends:RegisterCallback(callbackPrefix, callback)
	Friends:AddFriend(characterName, GET_NAME, Friends['_GetCharacterName'])
end

function Friends:_GetCharacterName(info)
	local tempCharacterName = string.lower(info.name)
	local callbackPrefix = GT.Text:Concat('_', GET_NAME, string.lower(tempCharacterName))
	Friends.callbacks:Fire(callbackPrefix, info)
	Friends.UnregisterCallback(callbackPrefix, callbackPrefix)
end

function Friends:GetCharacterClass(characterName, callback)
	characterName = string.lower(characterName)
	local callbackPrefix = GT.Text:Concat('_', GET_CLASS, characterName)
	Friends:RegisterCallback(callbackPrefix, callback)
	Friends:AddFriend(characterName, GET_CLASS, Friends['_GetCharacterClass'])
end

function Friends:_GetCharacterClass(info)
	local callbackPrefix = GT.Text:Concat('_', GET_CLASS, string.lower(info.name))
	Friends.callbacks:Fire(callbackPrefix, info)
	Friends.UnregisterCallback(callbackPrefix, callbackPrefix)
end

function Friends:IsOnline(characterName, callback)
	-- GT.Log:Info('Friends_IsOnline', characterName)
	characterName = string.lower(characterName)
	Friends:RegisterCallback(GT.Text:Concat('_', IS_ONLINE, characterName), callback)
	Friends:AddFriend(characterName, IS_ONLINE, Friends['_IsOnline'])
end

function Friends:_IsOnline(info)
	-- GT.Log:Info('Friends__IsOnline', info)
	local callbackPrefix = GT.Text:Concat('_', IS_ONLINE, string.lower(info.name))
	Friends.callbacks:Fire(callbackPrefix, info)
	Friends.UnregisterCallback(callbackPrefix, callbackPrefix)
end

function Friends:CancelIsOnline(characterName)
	if characterName == nil then
		for _, characterName in pairs(pendingFriends) do
			local callbackPrefix = GT.Text:Concat('_', IS_ONLINE, characterName)
			Friends.UnregisterCallback(callbackPrefix, callbackPrefix)
			pendingFriends = GT.Table:RemoveByValue(pendingFriends, characterName)
		end
		for _, characterName in pairs(addedFriends) do
			local callbackPrefix = GT.Text:Concat('_', IS_ONLINE, characterName)
			Friends.UnregisterCallback(callbackPrefix, callbackPrefix)
			addedFriends = GT.Table:RemoveByValue(addedFriends, characterName)
		end
		return
	end

	characterName = string.lower(characterName)
	local callbackPrefix = GT.Text:Concat('_', IS_ONLINE, characterName)
	Friends.UnregisterCallback(callbackPrefix, callbackPrefix)

	pendingFriends = GT.Table:RemoveByValue(pendingFriends, characterName)
	addedFriends = GT.Table:RemoveByValue(addedFriends, characterName)
end

function Friends:IsFriend(characterName)
	local friendInfo = C_FriendList.GetFriendInfo(characterName)
	if friendInfo == nil then return false end
	return true
end

function Friends:PurgeFriendList()
	for i = 1, C_FriendList.GetNumFriends() do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		Friends:RemoveFriend(friendInfo.name)
	end
end

function Friends:RemoveFriend(characterName)
	characterName = string.lower(characterName)

	for i = 1, C_FriendList.GetNumFriends() do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)

		if string.lower(friendInfo.name) == characterName and friendInfo.notes == AddOnName then
			C_FriendList.RemoveFriendByIndex(i)
			friendsToRemove = GT.Table:RemoveByValue(friendsToRemove, characterName)
			return true
		end
	end
	return false
end

function Friends:FakeFriendFilter(...)
	local message = select(2, ...)
	if string.find(message, ERR_FRIEND_NOT_FOUND) then
		-- GT.Log:Info('Friends_FakeFriendFilter_NotFound')
		for _, characterName in pairs(pendingFriends) do
			local callbackPrefix = GT.Text:Concat('_', FRIEND_ADDED, characterName)
			-- GT.Log:Info('Friends_FakeFriendFilter_Callbacks', callbackPrefix)
			local info = {}
			info.name = characterName
			info.didFind = false
			Friends.callbacks:Fire(callbackPrefix, info)
			Friends.UnregisterCallback(callbackPrefix, callbackPrefix)
		end
		return true
	end
	local characterName = message:match(string.gsub(ERR_FRIEND_ADDED_S, "(%%s)", "(.+)"))
    if characterName == nil then
    	characterName = message:match(string.gsub(ERR_FRIEND_ALREADY_S, "(%%s)", "(.+)"))
    end
	if characterName ~= nil then
		-- GT.Log:Info('Friends_FakeFriendFilter_Found', characterName)
		local callbackPrefix = GT.Text:Concat('_', FRIEND_ADDED, string.lower(characterName))
		local info = {}
		info.name = characterName
		info.didFind = true
		Friends.callbacks:Fire(callbackPrefix, info)
		Friends.UnregisterCallback(callbackPrefix, callbackPrefix)
		return true
	end
	return false
end