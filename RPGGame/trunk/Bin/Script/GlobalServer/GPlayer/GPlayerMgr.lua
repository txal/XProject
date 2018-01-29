function CGPlayerMgr:Ctor()
	self.m_tCharIDMap = {}
	self.m_tSessionMap = {}
end

function CGPlayerMgr:PlayerOnline(tPlayer)
	print("CGPlayerMgr:PlayerOnline***", tPlayer.sName)
	assert(not self.m_tSessionMap[tPlayer.nSession])
	local oOrgPlayer =  self.m_tCharIDMap[tPlayer.nCharID]
	if oOrgPlayer then
		local nOrgSession = oOrgPlayer:GetSession()
		self.m_tSessionMap[nOrgSession] = nil
	end
	local oPlayer = CGPlayer:new(tPlayer)
	self.m_tCharIDMap[tPlayer.nCharID] = oPlayer
	self.m_tSessionMap[tPlayer.nSession] = oPlayer
end

function CGPlayerMgr:GetPlayerBySession(nSession)
	return self.m_tSessionMap[nSession]
end

function CGPlayerMgr:GetPlayerByCharID(nCharID)
	return self.m_tCharIDMap[nCharID]
end

function CGPlayerMgr:PlayerOffline(nSession)
	print("CGPlayerMgr:PlayerOffline***", nSession)
	local oPlayer = self.m_tSessionMap[nSession]
	if oPlayer then
		local nCharID = oPlayer:GetCharID()
		self.m_tSessionMap[nSession] = nil
		self.m_tCharIDMap[nCharID] = nil
	end
end

function CGPlayerMgr:SyncPlayerData(tData)
end

function CGPlayerMgr:GetOnlineCount()
	local nCount = 0
	for nCharID, v in pairs(self.m_tCharIDMap) do
		nCount = nCount + 1
	end
	return nCount
end

function CGPlayerMgr:PrintOnline()
	local nCount = self:GetOnlineCount()
	LuaTrace("online***", nCount)
end


goGPlayerMgr = goGPlayerMgr or CGPlayerMgr:new()