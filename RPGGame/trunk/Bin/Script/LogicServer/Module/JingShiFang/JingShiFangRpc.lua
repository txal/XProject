function CltPBProc.JSFInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJingShiFang:InfoReq()
end

function CltPBProc.JSFOpenGridReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJingShiFang:OpenGridReq(tData.nGridID)
end

function CltPBProc.JSFOpenCardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJingShiFang:OpenCardReq(tData.nGridID)
end

function CltPBProc.JSFFinishReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJingShiFang:FinishReq(tData.nGridID)
end

function CltPBProc.JSFSpeedUpInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJingShiFang:SpeedUpInfoReq(tData.nMCID)
end

function CltPBProc.JSFSpeedUpReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJingShiFang:SpeedUpReq(tData.nMCID, tData.nType)
end

function CltPBProc.JSFDetailReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJingShiFang:DetailReq()
end
