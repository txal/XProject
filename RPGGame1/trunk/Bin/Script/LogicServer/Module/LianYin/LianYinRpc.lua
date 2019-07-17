function Network.CltPBProc.LYListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLianYin:LYListReq()
end

function Network.CltPBProc.LYPlayerSendReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLianYin:PlayerLianYinReq(tData.nHZID, tData.nTarCharID, tData.nCostType)
end

function Network.CltPBProc.LYServerSendReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLianYin:ServerLianYinReq(tData.nHZID, tData.nCostType)
end

function Network.CltPBProc.LYCancelReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLianYin:CancelLianYin(tData.nHZID)
end

function Network.CltPBProc.LYRejectReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLianYin:RejectLianYin(tData.nTarCharID, tData.nTarHZID)
end

function Network.CltPBProc.LYAgreeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLianYin:AgreeLianYin(tData.nSrcHZID, tData.nTarCharID, tData.nTarHZID, tData.nCostType)
end

function Network.CltPBProc.LYHZMatchListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLianYin:MatchHZReq(tData.nTarCharID, tData.nTarHZID)
end
