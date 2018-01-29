function CltPBProc.TimeAwardStateReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eTimeAward)
	oAct:SyncState(oPlayer)
end

function CltPBProc.TimeAwardProgressReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eTimeAward)
	local oSubAct = oAct:GetObj(tData.nID)
	oSubAct:ProgressReq(oPlayer)
end

function CltPBProc.TimeAwardRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eTimeAward)
	local oSubAct = oAct:GetObj(tData.nID)
	oSubAct:RankingReq(oPlayer, tData.nRankNum)
end

function CltPBProc.TimeAwardAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eTimeAward)
	local oSubAct = oAct:GetObj(tData.nID)
	oSubAct:AwardReq(oPlayer, tData.nAwardID)
end
