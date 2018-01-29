function CltPBProc.TVReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goTV:_TVSend(tData.sCont)
end
