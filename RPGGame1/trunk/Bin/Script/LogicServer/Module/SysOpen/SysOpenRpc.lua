function Network.CltPBProc.PracticeListReq(nCmd, nServer, Srevice, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
end

-------------服务器内部
--手动开启系统
function Network.RpcSrv2Srv.OpenSystemReq(nSrcServer, nSrcService, nTarSession, nRoleID, nSysID)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	oRole.m_oSysOpen:OpenSystem(nSysID)
end

--手动关系系统
function Network.RpcSrv2Srv.CloseSystemReq(nSrcServer, nSrcService, nTarSession, nRoleID, nSysID)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	oRole.m_oSysOpen:CloseSystem(nSysID)
end
