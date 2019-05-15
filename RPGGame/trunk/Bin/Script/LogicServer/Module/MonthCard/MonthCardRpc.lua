function CltPBProc.MonthCardInfoReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oMonthCard:MonthCardInfoReq()
end

function CltPBProc.MonthCardAwardReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oMonthCard:MonthCardAwardReq(tData.nID)
end

function CltPBProc.TrialMonthCardReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oMonthCard:TrialMonthCardReq()
end
