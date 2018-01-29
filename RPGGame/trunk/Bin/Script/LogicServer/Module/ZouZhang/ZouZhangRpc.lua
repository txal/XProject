function CltPBProc.ZZZouZhangReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oZouZhang:ZouZhangCountReq()
end

function CltPBProc.ZZInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oZouZhang:InfoReq()
end

function CltPBProc.ZZAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oZouZhang:AwardReq(tData.nSelect)
end

function CltPBProc.ZZAddZouZhangTimesReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oZouZhang:AddZouZhangTimesReq(tData.nNum)
end