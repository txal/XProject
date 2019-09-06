------客户端服务器
function Network.CltPBProc.RoleInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = GetGModule("GRoleMgr"):GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole:RoleInfoReq(tData.nTarRoleID)
end

------服务器内部------
--角色上线通知
function Network.RpcSrv2Srv.GRoleOnlineReq(nSrcServer, nSrcService, nTarSession, nRoleID, tData)
	GetGModule("GRoleMgr"):RoleOnlineReq(nRoleID, tData)
end

--角色断开通知
function Network.RpcSrv2Srv.GRoleDisconnectReq(nSrcServer, nSrcService, nTarSession, nRoleID, tData)
	GetGModule("GRoleMgr"):RoleDisconnectReq(nRoleID, tData)
end

--角色释放通知
function Network.RpcSrv2Srv.GRoleReleasedReq(nSrcServer, nSrcService, nTarSession, nRoleID, tData)
	GetGModule("GRoleMgr"):RoleReleasedReq(nRoleID, tData)
end

--角色属性更新通知
function Network.RpcSrv2Srv.GRoleUpdateDataReq(nSrcServer, nSrcService, nTarSession, nRoleID, tData)
    GetGModule("GRoleMgr"):RoleUpdateDataReq(nRoleID, tData)
end

--删除角色通知
function Network.RpcSrv2Srv.AccountRoleDeleteNotify(nSrcServer, nSrcService, nTarSession, nAccountID, nRoleID)
	return GetGModule("GRoleMgr"):AccountRoleDeleteNotify(nAccountID, nRoleID)
end

--充值成功通知
function Network.RpcSrv2Srv.GRoleRechargeSuccReq(nSrcServer, nSrcService, nTarSession, nRoleID, tData)
	local oRole = GetGModule("GRoleMgr"):GetRoleByID(nRoleID)
	if not oRole then return
	oRole:OnRechargeSucc(tData)
end
