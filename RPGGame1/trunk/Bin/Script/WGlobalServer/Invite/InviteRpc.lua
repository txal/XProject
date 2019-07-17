------客户端服务器
function Network.CltPBProc.InviteAwardReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	goInvite:InviteAwardReq(oRole, tData.nType)
end


------服务器内部
function Network.RpcSrv2Srv.OnInviteMasterTaskCompleteReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	goInvite:OnMasterTaskComplete(oRole)
end
