function Network.CltPBProc.MonthCardInfoReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oMonthCard:MonthCardInfoReq()
end

function Network.CltPBProc.MonthCardAwardReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oMonthCard:MonthCardAwardReq(tData.nID)
end

function Network.CltPBProc.TrialMonthCardReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oMonthCard:TrialMonthCardReq()
end
