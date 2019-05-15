function CltPBProc.UpgradeBagInfoReq(nCmd, nServer, nService, nSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oUpgradeBag:UpgradeBagInfoReq()
end

function CltPBProc.GetUpgradeBagAwardReq(nCmd, nServer, nService, nSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oUpgradeBag:GetUpgradeBagAwardReq(tData.nID)
end

