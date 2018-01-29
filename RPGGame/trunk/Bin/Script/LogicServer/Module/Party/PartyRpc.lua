function CltPBProc.PartySceneReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oPartyData:PartySceneReq(oPlayer)
end

function CltPBProc.PartyOpenReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oPartyData:PartyOpenReq(oPlayer, tData.nID, tData.bPublic)
end

function CltPBProc.PartyInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oPartyData:PartyInfoReq(oPlayer, tData.nCharID)
end

function CltPBProc.PartyQueryReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oPartyData:PartyQueryReq(oPlayer, tData.nCharID)
end

function CltPBProc.PartyJoinReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oPartyData:PartyJoinReq(oPlayer, tData.nJoinType, tData.nCharID, tData.nDesk, tData.bFC)
end

function CltPBProc.PartyMessageReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oPartyData:PartyMessageReq(oPlayer)
end

function CltPBProc.PartyGoodsListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oParty:PartyGoodsListReq()
end

function CltPBProc.PartyRefreshGoodsReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oParty:PartyRefreshGoodsReq()
end

function CltPBProc.PartyExchangeGoodsReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oParty:PartyExchangeGoodsReq(tData.nAutoIndex)
end
