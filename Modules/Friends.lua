local AddOnName = ...

local CallbackHandler = LibStub('CallbackHandler-1.0')

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local Friends = GT:NewModule('Friends')
GT.Friends = Friends

Friends.callbacks = Friends.callbacks or CallbackHandler:New(Friends)

local ADD_FRIEND = 'ADD_FRIEND'
local FRIEND_ADDED = 'FRIEND_ADDED'
local IS_ONLINE = 'IS_ONLINE'
local GET_NAME = 'GET_NAME'
local GET_CLASS = 'GET_CLASS'

local NOTE = nil

local pendingFriendsQueue = {}
local friendsAddedQueue = {}
local isOnlineQueue = {}

local initialized = false

function Friends:OnEnable()
	if initialized then return end
	-- GT.Log:Info('Friends_OnEnable')

	NOTE = GT.Text:Concat(' ', GT.L['ADDED_BY'], AddOnName)

	ChatFrame_AddMessageEventFilter('CHAT_MSG_SYSTEM', Friends['FakeFriendFilter'])
	Friends:PurgeFriendList()
	initialized = true
end

function Friends:AddFriend(characterName, callback)
	characterName = string.lower(characterName)

	local uuid = GT.Text:UUID()
	if callback ~= nil then
		pendingFriendsQueue = GT.Table:InsertField(pendingFriendsQueue, characterName)
		local queue = pendingFriendsQueue[characterName]
		pendingFriendsQueue[characterName] = GT.Table:Insert(queue, uuid, callback)
		-- GT.Log:Info('Friends_AddFriend_RegisterCallback', characterName, uuid)
		Friends:RegisterCallback(uuid, callback)
	end

	if not GT.Table:Contains(friendsAddedQueue, characterName) then
		C_FriendList.AddFriend(characterName, NOTE)
		uuid = GT.Text:UUID()
		friendsAddedQueue = GT.Table:InsertField(friendsAddedQueue, characterName)
		local queue = friendsAddedQueue[characterName]
		friendsAddedQueue[characterName] = GT.Table:Insert(queue, uuid, callback)
		-- GT.Log:Info('Friends_FriendAdded_RegisterCallback', characterName, uuid)
		Friends:RegisterCallback(uuid, Friends['FriendAdded'])
	end
end

function Friends:FriendAdded(info)
	-- GT.Log:Info('Friends_FriendAdded', info.name, info.exists)

	local tempCharacterName = string.lower(info.name)
	if info.exists then
		local friendInfo = C_FriendList.GetFriendInfo(info.name)
		for k, v in pairs(friendInfo) do
			info[k] = v
		end
		info.className = string.upper(info.className)
		info.exists = true
	else
		info.className = 'UNKNOWN'
		info.connected = false
		info.exists = false
	end

	local characterToRemove = nil
	if pendingFriendsQueue[tempCharacterName] ~= nil then
		local callbacks = pendingFriendsQueue[tempCharacterName]
		for uuid, callback in pairs(callbacks) do
			-- GT.Log:Info('Friends_FriendAdded_Callback', info.name, uuid)
			Friends.callbacks:Fire(uuid, info)
			Friends.UnregisterCallback(callback, uuid)
		end
	end
	pendingFriendsQueue[tempCharacterName] = nil
	if info.exists then
		Friends:RemoveFriend(info.name)
	end
end

function Friends:IsOnline(characterName, callback)
	characterName = string.lower(characterName)
	local uuid = GT.Text:UUID()
	isOnlineQueue = GT.Table:InsertField(isOnlineQueue, characterName)
	isOnlineQueue[characterName] = GT.Table:Insert(isOnlineQueue[characterName], uuid, callback)
	-- GT.Log:Info('Friends_IsOnline', characterName, uuid)
	Friends:RegisterCallback(uuid, callback)
	Friends:AddFriend(characterName, Friends['_IsOnline'])
end

function Friends:_IsOnline(info)
	local characterName = string.lower(info.name)
	if isOnlineQueue[characterName] ~= nil then
		local callbacks = isOnlineQueue[characterName]
		for uuid, callback in pairs(callbacks) do
			-- GT.Log:Info('Friends__IsOnline_Callback', info.name, uuid)
			Friends.callbacks:Fire(uuid, info)
			Friends.UnregisterCallback(uuid, uuid)
		end
		isOnlineQueue[characterName] = nil
	end
end

function Friends:CancelIsOnline(characterName)
	if characterName == nil then
		for characterName, callbacks in pairs(pendingFriendsQueue) do
			for uuid, callback in pairs(callbacks) do
				Friends.UnregisterCallback(uuid, uuid)
			end
		end
		pendingFriendsQueue = {}
		return
	end

	characterName = string.lower(characterName)

	if pendingFriendsQueue[characterName] == nil then return end

	for uuid, callback in pairs(pendingFriendsQueue[characterName]) do
		Friends.UnregisterCallback(callback, uuid)
	end
	pendingFriendsQueue = {}
end

function Friends:IsFriend(characterName)
	local friendInfo = C_FriendList.GetFriendInfo(characterName)
	if friendInfo == nil then
		-- GT.Log:Info('Friends_IsFriend_No', characterName)
		return false
	end
	-- GT.Log:Info('Friends_IsFriend_Yes', characterName)
	return true
end

function Friends:PurgeFriendList()
	-- GT.Log:Info('Friends_PurgeFriendList')
	for i = 1, C_FriendList.GetNumFriends() do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		Friends:RemoveFriend(friendInfo.name)
	end
end

function Friends:RemoveFriend(characterName)
	characterName = string.lower(characterName)

	for i = 1, C_FriendList.GetNumFriends() do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		if friendInfo.notes == NOTE then
			-- GT.Log:Info('Friends_RemoveFriend', friendInfo.name)
			C_FriendList.RemoveFriendByIndex(i)
			return true
		end
	end
	return false
end

function Friends:FakeFriendFilter(...)
	local message = select(2, ...)
	if string.find(message, ERR_FRIEND_NOT_FOUND) then
		for characterName, callbacks in pairs(friendsAddedQueue) do
			for uuid, callback in pairs(callbacks) do
				-- GT.Log:Info('Friends_FakeFriendFilter_NotFound', characterName, uuid)
				local info = {}
				info.name = characterName
				info.exists = false
				Friends.callbacks:Fire(uuid, info)
				Friends.UnregisterCallback(callback, uuid)
			end
		end
		friendsAddedQueue = {}
		return true
	end
	local characterName = message:match(string.gsub(ERR_FRIEND_ADDED_S, '(%%s)', '(.+)'))
    if characterName == nil then
    	characterName = message:match(string.gsub(ERR_FRIEND_ALREADY_S, '(%%s)', '(.+)'))
    end
	if characterName ~= nil then
		-- GT.Log:Info('Friends_FakeFriendFilter_Found', characterName)

		local tempCharacterName = string.lower(characterName)
		if friendsAddedQueue[tempCharacterName] ~= nil then
			-- GT.Log:Info('Friends_FakeFriendFilter_InQueue', friendsAddedQueue)
			local callbacks = friendsAddedQueue[tempCharacterName]
			for uuid, callback in pairs(callbacks) do
				local info = {}
				info.name = characterName
				info.exists = true

				Friends.callbacks:Fire(uuid, info)
				-- GT.Log:Info('Friends_FakeFriendFilter_Callback', characterName, uuid)
				Friends.UnregisterCallback(callback, uuid)
			end
			friendsAddedQueue = GT.Table:RemoveByValue(friendsAddedQueue, tempCharacterName, true)
		end
	end
	return true
end