function CltPBProc.MoBaiReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oMoBai:MoBaiReq(tData.nRankID)
end
