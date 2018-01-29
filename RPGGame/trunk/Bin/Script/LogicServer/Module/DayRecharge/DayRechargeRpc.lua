function CltPBProc.DayRechargeStateReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eDayRecharge)
	oAct:SyncState(oPlayer)
end

function CltPBProc.DayRechargeInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oDayRecharge:InfoReq()
end

function CltPBProc.DayRechargeAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oDayRecharge:AwardReq(tData.nID)
end
