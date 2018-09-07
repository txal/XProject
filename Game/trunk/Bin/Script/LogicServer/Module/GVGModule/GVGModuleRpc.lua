function CltPBProc.BugHoleIntelligenceReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer.m_oGVGModule:BattleIntelligenceReq()
end
