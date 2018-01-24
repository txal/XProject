function CGPlayerMgr:Ctor()
	self.m_tCharIDMap = {}
	self.m_tSessionMap = {}
end

function CGPlayerMgr:CreatePlayer(nSession, nCharID, sCharName, nLogicService)
	print("CGPlayerMgr:CreatePlayer***", sCharName, nLogicService)
	if self.m_tSessionMap[nSession] or self.m_tCharIDMap[nCharID] then
		return
	end
	local oPlayer = CGPlayer:new(nSession, nCharID, sCharName, nLogicService)
	self.m_tCharIDMap[nCharID] = oPlayer
	self.m_tSessionMap[nSession] = oPlayer
end

function CGPlayerMgr:GetPlayerBySession(nSession)
	local oPlayer = self.m_tSessionMap[nSession]
	if not oPlayer then
		for nService, tConf in pairs(gtNetConf.tLogicService) do
			Srv2Srv.GlobalPlayerStateReq(nService, nSession, "")
		end
	end
	return oPlayer
end

function CGPlayerMgr:GetPlayerByCharID(nCharID)
	local oPlayer = self.m_tCharIDMap[nCharID]
	if not oPlayer then
		for nService, tConf in pairs(gtNetConf.tLogicService) do
			Srv2Srv.GlobalPlayerStateReq(nService, 0, nCharID)
		end
	end
	return oPlayer
end

function CGPlayerMgr:RemovePlayer(nSession)
	print("CGPlayerMgr:RemovePlayer***", nSession)
	local oPlayer = self.m_tSessionMap[nSession]
	if oPlayer then
		local nCharID = oPlayer:GetCharID()
		self.m_tCharIDMap[nCharID] = nil
		self.m_tSessionMap[nSession] = nil
	end
end


goGPlayerMgr = goGPlayerMgr or CGPlayerMgr:new()