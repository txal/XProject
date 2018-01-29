function CltPBProc.QingAnZheReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oQingAnZhe:QingAnZheCountReq()
end

function CltPBProc.QAZInfoReq(nCmd, nSrc, nSession, tData)     
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oQingAnZhe:InfoReq()
end

