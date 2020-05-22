local AddOnName = ...

local CallbackHandler = LibStub("CallbackHandler-1.0")

local GT = LibStub('AceAddon-3.0'):GetAddon(AddOnName)

local Friends = GT:NewModule('Friends')
GT.Friends = Friends

Friends.callbacks = Friends.callbacks or CallbackHandler:New(Friends)

local ADD_FRIEND = 'ADD_FRIEND'
local IS_ONLINE = 'IS_ONLINE'

local friendsAdded = {}

function Friends:OnEnable()
	GT.Log:Info('Friends_OnEnable')
end

function Friends:FriendListUpdate()
	GT.Log:Info('Friends_FriendListUpdate')
	Friends:FriendAdded()
end

function Friends:AddFriend(characterName, callback)
	if not Friends:HasFriend(characterName) then
		GT.Log:Info('Friends_AddFriend', characterName)
		C_FriendList.AddOrRemoveFriend(characterName, AddOnName)
		GT.Table:Insert(friendsAdded, nil, characterName)
	end
	if callback ~= nil then
		Friends:RegisterCallback(ADD_FRIEND, callback)
	end
end

function Friends:FriendAdded()
	for _, characterName in pairs(friendsAdded) do
		local friendInfo = C_FriendList.GetFriendInfo(characterName)
		Friends:RemoveFriend(characterName)
		if friendInfo ~= nil then
			GT.Log:Info('Friends_FriendAdded_FireCallbacks', characterName)
			Friends.callbacks:Fire(ADD_FRIEND, friendInfo)
		end
	end
	friendsAdded = {}
end

function Friends:IsOnline(characterName, callback)
	GT.Log:Info('Friends_IsOnline', characterName)
	Friends:AddFriend(characterName, Friends['_IsOnline'])
	Friends:RegisterCallback(IS_ONLINE, callback)
end

function Friends:CancelIsOnline()
	Friends.UnregisterCallback(IS_ONLINE, IS_ONLINE)
end

function Friends:_IsOnline(friendInfo)
	GT.Log:Info('Friends__IsOnline', friendInfo)
	if friendInfo ~= nil then
		Friends.callbacks:Fire(IS_ONLINE, friendInfo.name, friendInfo.connected)
	else
		Friends.callbacks:Fire(IS_ONLINE, nil, nil)
	end
end

function Friends:HasFriend(characterName)
	local friendInfo = C_FriendList.GetFriendInfo(characterName)
	if friendInfo == nil then return false end
	return true
end

function Friends:PurgeFriendList()
	if #friendsAdded > 0 then
		for _, characterName in pairs(friendsAdded) do
			Friends:RemoveFriend(characterName)
		end
	else
		Friends:RemoveFriend(nil)
	end
	friendsAdded = {}
end

function Friends:RemoveFriend(characterName)
	GT.Log:Info('Friends_RemoveFriend', characterName)
	for i = 1, C_FriendList.GetNumFriends() do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		local remove = false
		if characterName == nil then
			remove = true
		elseif characterName ~= nil
			and string.lower(friendInfo.name) == string.lower(characterName)
		then
			remove = true
		end

		GT.Log:Info('Friends_RemoveFriend_Remove', characterName, friendInfo.name, remove, friendInfo.notes == AddOnName)
		if remove and friendInfo.notes == AddOnName then
			GT.Log:Info('Friends_RemoveFriend', i, characterName)
			C_FriendList.RemoveFriendByIndex(i)
		end
	end
end