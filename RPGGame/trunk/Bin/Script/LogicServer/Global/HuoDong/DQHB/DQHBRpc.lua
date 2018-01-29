function CltPBProc.HBInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goHBMgr:SyncState(oPlayer)
end

function CltPBProc.HBInActivityReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(tData.nID)
	oAct:InActivityReq(oPlayer)
end

function CltPBProc.HBRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end 
	local oAct = goHDMgr:GetHuoDong(tData.nID, tData.nRankNum)
	oAct:RankingReq(oPlayer, tData.nRankNum)
end

function CltPBProc.HBGetAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(tData.nID)
	oAct:GetAwardReq(oPlayer)
end

function CltPBProc.GSGInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oGSGData:SyncInfoReq(oPlayer)
end

function CltPBProc.GSGTaoJiaoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oGSGData:TaoJiaoReq(tData.nType, oPlayer)
end
