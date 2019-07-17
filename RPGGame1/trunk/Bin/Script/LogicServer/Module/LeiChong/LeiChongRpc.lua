function Network.CltPBProc.LeiChongStateReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eLeiChong)
	oAct:SyncState(oPlayer)
end

function Network.CltPBProc.LeiChongInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLeiChong:LCInfoReq()  
end

function Network.CltPBProc.LeiChongAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLeiChong:LCAwardReq(tData.nID)
end

function Network.CltPBProc.LCGameInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLeiChong:LCGameInfoReq()
end

function Network.CltPBProc.LCGameRefreshReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLeiChong:LCGameRefreshReq()
end

function Network.CltPBProc.LCGameBuyPropReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLeiChong:LCGameBuyPropReq()
end

function Network.CltPBProc.LCGameUsePropReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLeiChong:LCGameUsePropReq()
end
