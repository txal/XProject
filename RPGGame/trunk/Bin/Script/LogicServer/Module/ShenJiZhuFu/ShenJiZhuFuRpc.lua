function CltPBProc.ShenJiZhuFuInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oShenJiZhuFu:ShenJiZhuFuInfoReq()
end

function CltPBProc.ShenJiCardInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oShenJiZhuFu:ShenJiCardInfoReq()
end

function CltPBProc.ShenJiCardAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oShenJiZhuFu:ShenJiCardAwardReq(tData.nID)
end

function CltPBProc.TrialMonthCardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oShenJiZhuFu:TrialMonthCardReq()
end
