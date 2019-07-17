function Network.CltPBProc.LDInfoReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oLeiDeng:InfoReq()  
end

function Network.CltPBProc.LDAwardReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oLeiDeng:AwardReq(tData.nID)
end
