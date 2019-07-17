function Network.CltPBProc.FundAwardProgressReq(nCmd, nServer, nService, nSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFund:FundAwardProgressReq()
end

function Network.CltPBProc.FundAwardReq(nCmd, nServer, nService, nSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFund:GetAwardReq(tData.nID)
end

