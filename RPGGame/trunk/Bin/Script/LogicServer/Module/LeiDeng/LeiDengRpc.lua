function CltPBProc.LeiDengStateReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eLeiDeng)
	oAct:SyncState(oPlayer)
end

function CltPBProc.LeiDengInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLeiDeng:InfoReq()  
end

function CltPBProc.LeiDengAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	print("累登tData***", tData)

	oPlayer.m_oLeiDeng:AwardReq(tData.nID)
end
