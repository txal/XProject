function Network.CltPBProc.AchievementsInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oAchievements:InfoReq()
end

function Network.CltPBProc.AchievementsStateReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oAchievements:EachAchieStateReq(tData.nType)
end

function Network.CltPBProc.tAchievementsAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oAchievements:AchievementsAwardReq(tData.nType, tData.nID)
end