function Network.CltPBProc.MainTaskListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oMainTask:SyncTaskList()
end

function Network.CltPBProc.DailyTaskListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oDailyTask:SyncTaskList()
end

function Network.CltPBProc.MainTaskAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oMainTask:GetAward(tData.nID)
end

function Network.CltPBProc.DailyTaskAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oDailyTask:GetAward(tData.nID, tData.nType)
end

function Network.CltPBProc.CompleteTaskReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oMainTask:CompleteTaskReq(tData.nID)
end
