function CltPBProc.WFSFInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oWeiFuSiFang:InfoReq()
end

function CltPBProc.XXunFangReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oWeiFuSiFang:XunFangReq(tData.bUseProp, tData.nBuildID)
end

function CltPBProc.XFBuildEventAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oWeiFuSiFang:BuildEventAwardReq(tData.nSelect)
end

function CltPBProc.XFBlankEventAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oWeiFuSiFang:BlankEventAwardReq(tData.bBuy)
end

function CltPBProc.XXunBaoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oWeiFuSiFang:XunBaoReq()
end

function CltPBProc.XFSpecifyBuildInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oWeiFuSiFang:SpecifyBuildInfoReq(tData.nBuildID)
end

function CltPBProc.XFSpecifyXunFangReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oWeiFuSiFang:SpecifyXunFangReq(tData.nBuildID)
end