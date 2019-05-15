function CltPBProc.FmtListReq(nCmd, nServer, Srevice, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFormation:FmtListReq()
end

function CltPBProc.FmtBuyReq(nCmd, nServer, Srevice, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFormation:FmtBuyReq()
end

function CltPBProc.FmtUseReq(nCmd, nServer, Srevice, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFormation:FmtUseReq(tData.nID)
end

function CltPBProc.FmtUpgradeReq(nCmd, nServer, Srevice, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFormation:FmtUpgradeReq(tData.nID, tData.tList)
end
