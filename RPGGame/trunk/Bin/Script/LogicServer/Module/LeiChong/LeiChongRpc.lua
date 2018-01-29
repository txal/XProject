function CltPBProc.LeiChongStateReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eLeiChong)
	oAct:SyncState(oPlayer)
end

function CltPBProc.LeiChongInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLeiChong:LCInfoReq()  
end

function CltPBProc.LeiChongAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLeiChong:LCAwardReq(tData.nID)
end

function CltPBProc.LCGameInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLeiChong:LCGameInfoReq()
end

function CltPBProc.LCGameRefreshReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLeiChong:LCGameRefreshReq()
end

function CltPBProc.LCGameBuyPropReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLeiChong:LCGameBuyPropReq()
end

function CltPBProc.LCGameUsePropReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLeiChong:LCGameUsePropReq()
end
