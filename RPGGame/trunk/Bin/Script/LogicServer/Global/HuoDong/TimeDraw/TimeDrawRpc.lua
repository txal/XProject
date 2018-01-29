function CltPBProc.TimeDrawStateReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eTimeDraw)
	oAct:SyncState(oPlayer)
end

function CltPBProc.TimeDrawReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eTimeDraw)
	oAct:TimeDrawReq(oPlayer, tData.nDrawType)
end

function CltPBProc.TimeDrawRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eTimeDraw)
	oAct:PlayerRankingReq(oPlayer, tData.nRankNum)	
end

