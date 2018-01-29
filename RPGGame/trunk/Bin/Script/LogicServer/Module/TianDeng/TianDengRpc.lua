function CltPBProc.TDQFInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oTianDeng:TDQFInfoReq()
end

function CltPBProc.TDQFReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oTianDeng:TDQFReq(tData.bUseProp)
end
