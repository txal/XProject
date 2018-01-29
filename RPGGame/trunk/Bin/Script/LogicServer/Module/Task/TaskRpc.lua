function CltPBProc.MainTaskListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oMainTask:SyncTaskList()
end

function CltPBProc.DailyTaskListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oDailyTask:SyncTaskList()
end

function CltPBProc.MainTaskAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oMainTask:GetAward(tData.nID)
end

function CltPBProc.DailyTaskAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oDailyTask:GetAward(tData.nID, tData.nType)
end

function CltPBProc.CompleteTaskReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oMainTask:CompleteTaskReq(tData.nID)
end
