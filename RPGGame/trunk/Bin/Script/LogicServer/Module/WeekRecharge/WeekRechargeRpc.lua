function CltPBProc.WeekRechargeInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oWeekRecharge:InfoReq()
end

function CltPBProc.WeekRechargeAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oWeekRecharge:AwardReq(tData.nID)
end
