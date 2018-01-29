function CltPBProc.AwardRecordReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goAwardRecordMgr:AwardRecordReq(oPlayer, tData.nType)
end