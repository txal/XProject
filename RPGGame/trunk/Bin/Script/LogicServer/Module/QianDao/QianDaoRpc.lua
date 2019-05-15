function CltPBProc.QDInfoReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oQianDao:InfoReq()
end

function CltPBProc.QDAwardReq(nCmd, nServer, nService, nSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oQianDao:QianDaoAwardReq(tData.nID)    
end

function CltPBProc.QDTiredSignAwardReq(nCmd, nServer, nService, nSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oQianDao:TiredSignAwardReq(tData.nID)    
end
