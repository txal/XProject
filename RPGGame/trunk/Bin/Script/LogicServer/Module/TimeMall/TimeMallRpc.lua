function CltPBProc.TimeMallInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oTimeMall:InfoReq()
end

function CltPBProc.TimeMallBuyReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oTimeMall:BuyReq(tData.nID)
end
