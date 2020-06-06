local majorVersion = 'Friends'
local minorVersion = 1

local Friends, oldMinor = LibStub:NewLibrary(majorVersion, minorVersion)

local CallbackHandler = LibStub('CallbackHandler-1.0')
local Text = assert(Text, "Friends-1.0 requires the Text Friendsrary.")
local Table = assert(Table, 'Friends-1.0 requires the Table library.')

Friends.callbacks = Friends.callbacks or CallbackHandler:New(Friends)

local NOTE = majorVersion

local pendingFriendsQueue = {}
local friendsAddedQueue = {}
local isOnlineQueue = {}
local playerFriends = {}
local addonFriends = {}

function Friends:Init()
	NOTE = majorVersion .. '-' .. minorVersion
	ChatFrame_AddMessageEventFilter('CHAT_MSG_SYSTEM', Friends['FakeFriendFilter'])
end

function Friends:AddFriend(characterName, callback)
	characterName = string.lower(characterName)
	Friends:PurgeFriendList()

	local uuid = Text:UUID()
	if callback ~= nil then
		pendingFriendsQueue = Table:InsertField(pendingFriendsQueue, characterName)
		local queue = pendingFriendsQueue[characterName]
		pendingFriendsQueue[characterName] = Table:Insert(queue, uuid, callback)
		Friends:RegisterCallback(uuid, callback)
	end

	if not Table:Contains(friendsAddedQueue, characterName) then
		C_FriendList.AddFriend(characterName, NOTE)
		uuid = Text:UUID()
		friendsAddedQueue = Table:InsertField(friendsAddedQueue, characterName)
		local queue = friendsAddedQueue[characterName]
		friendsAddedQueue[characterName] = Table:Insert(queue, uuid, callback)
		Friends:RegisterCallback(uuid, Friends['FriendAdded'])
	end
end

function Friends:FriendAdded(info)
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
	local uuid = Text:UUID()
	isOnlineQueue = Table:InsertField(isOnlineQueue, characterName)
	isOnlineQueue[characterName] = Table:Insert(isOnlineQueue[characterName], uuid, callback)
	Friends:RegisterCallback(uuid, callback)
	Friends:AddFriend(characterName, Friends['_IsOnline'])
end

function Friends:_IsOnline(info)
	local characterName = string.lower(info.name)
	if isOnlineQueue[characterName] ~= nil then
		local callbacks = isOnlineQueue[characterName]
		for uuid, callback in pairs(callbacks) do
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
		return false
	end
	return true
end

function Friends:PurgeFriendList()
	for i = 1, C_FriendList.GetNumFriends() do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		local removed = Friends:RemoveFriend(friendInfo.name)
		if not removed then
			playerFriends = Table:Insert(playerFriends, nil, friendInfo.name)
		end
	end
end

function Friends:RemoveFriend(characterName)
	characterName = string.lower(characterName)

	for i = 1, C_FriendList.GetNumFriends() do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		if friendInfo.notes == NOTE and string.lower(friendInfo.name) == characterName then
			C_FriendList.RemoveFriendByIndex(i)
			return true
		end
	end
	return false
end

function Friends:GetFriendNames(getPlayerFriends)
	local returnFriends = {}
	for i = 1, C_FriendList.GetNumFriends() do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		if friendInfo.notes == NOTE and not getPlayerFriends then
			returnFriends = Table:Insert(returnFriends, nil, friendInfo.name)
		elseif friendInfo.notes ~= NOTE and getPlayerFriends then
			returnFriends = Table:Insert(returnFriends, nil, friendInfo.name)
		end
	end
end

function Friends:FakeFriendFilter(...)
	local message = select(2, ...)
	-- print('Friends_FakeFriendFilter')
	if string.find(message, ERR_FRIEND_NOT_FOUND) then
		-- print('Friends_FakeFriendFilter_NotFound', message)
		for characterName, callbacks in pairs(friendsAddedQueue) do
			for uuid, callback in pairs(callbacks) do
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
		-- print('Friends_FakeFriendFilter_Found: ', characterName)
		local tempCharacterName = string.lower(characterName)
		if friendsAddedQueue[tempCharacterName] ~= nil then
			local callbacks = friendsAddedQueue[tempCharacterName]
			for uuid, callback in pairs(callbacks) do
				local info = {}
				info.name = characterName
				info.exists = true

				Friends.callbacks:Fire(uuid, info)
				Friends.UnregisterCallback(callback, uuid)
			end
			friendsAddedQueue = Table:RemoveByValue(friendsAddedQueue, tempCharacterName, true)
			addonFriends = Table:Insert(addonFriends, nil, characterName)
			return true
		end
		if Table:Contains(addonFriends, characterName) then
			-- print('Friends_FakeFriendFilter_AddonFriend', characterName)
			return true
		end
		if not Table:Contains(playerFriends, characterName) then
			-- print('Friends_FakeFriendFilter_CharacterFriend', characterName)
			playerFriends = Table:Insert(playerFriends, nil, characterName)
			return false
		end
	end
	return false
end

Friends:Init()