function CltPBProc.XingGongInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oCXData:XingGongInfoReq(oPlayer)
end

function CltPBProc.CreateXingGongReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oCXData:CreateXingGongReq(oPlayer, tData.nXGID)
end

function CltPBProc.CXAddFZReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oCXData:CXAddFZReq(oPlayer, tData.nXGID, tData.nFZID, tData.nGrid)
end

function CltPBProc.CXRemoveFZReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oCXData:CXRemoveFZReq(oPlayer, tData.nXGID, tData.nFZID)
end

function CltPBProc.CXAutoAddFZReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oCXData:CXAutoAddFZReq(oPlayer, tData.nXGID)
end

function CltPBProc.ChuXunReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oCXData:ChuXunReq(oPlayer, tData.nXGID)
end

function CltPBProc.FinishChuXunReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oCXData:FinishChuXunReq(oPlayer, tData.nXGID)
end

function CltPBProc.GDInfoListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oCXData:GDInfoListReq(oPlayer)
end

function CltPBProc.CRInfoListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oCXData:CRInfoListReq(oPlayer, tData.nType)
end

function CltPBProc.StartGDReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oCXData:StartGDReq(oPlayer, tData.nXGID, tData.bUseProp)
end

function CltPBProc.CXFuChouReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oCXData:CXFuChouReq(oPlayer, tData.nXGID, tData.nTarCharID)
end

function CltPBProc.CXCatchReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oCXData:CXCatchReq(oPlayer, tData.nXGID, tData.nTarCharID)
end

function CltPBProc.CXTJListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oCXData:CXTJListReq(oPlayer)
end

function CltPBProc.CXTongJiReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oCXData:CXTongJiReq(oPlayer, tData.nTarCharID)
end

function CltPBProc.CXRankingTJListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oCXData:RankingTJListReq(oPlayer)
end

