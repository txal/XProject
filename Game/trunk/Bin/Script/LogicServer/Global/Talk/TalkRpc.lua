function CltPBProc.TalkMsgReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goTalk:TalkReq(oPlayer, tData.nChannel, tData.sCont)
end
