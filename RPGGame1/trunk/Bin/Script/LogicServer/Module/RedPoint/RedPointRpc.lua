function Network.CltPBProc.SyncStateReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oRedPoint:SyncStateReq()
end