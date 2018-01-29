function CltPBProc.CXGInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oChuXiuGong:SyncInfo()
end

function CltPBProc.CXGDrawReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oChuXiuGong:DrawReq(tData.nDrawType, tData.bUseProp)
end
