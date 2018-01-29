function CltPBProc.NeiGeInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oNeiGe:SyncInfo()
end

function CltPBProc.NeiGeCollectReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oNeiGe:CollectReq(tData.nType)
end

function CltPBProc.NeiGeOneKeyCollectReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oNeiGe:OneKeyCollectReq(tData.nType)
end

function CltPBProc.NeiGeCancelCDReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oNeiGe:CancelCDReq(tData.nType)
end

function CltPBProc.NeiGeRecoverReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oNeiGe:NGRecoverReq(tData.nType, tData.nNum)
end

function CltPBProc.NeiGeOneKeyRecoverReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oNeiGe:NGOneKeyRecoverReq()
end
