function Network.CltPBProc.FmtListReq(nCmd, nServer, Srevice, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFormation:FmtListReq()
end

function Network.CltPBProc.FmtBuyReq(nCmd, nServer, Srevice, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFormation:FmtBuyReq()
end

function Network.CltPBProc.FmtUseReq(nCmd, nServer, Srevice, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFormation:FmtUseReq(tData.nID)
end

function Network.CltPBProc.FmtUpgradeReq(nCmd, nServer, Srevice, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFormation:FmtUpgradeReq(tData.nID, tData.tList)
end
