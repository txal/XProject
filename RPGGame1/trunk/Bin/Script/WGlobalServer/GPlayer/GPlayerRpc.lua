

------服务器内部------
--角色上线通知
function Network.RpcSrv2Srv.GRoleOnlineReq(nSrcServer, nSrcService, nTarSession, nRoleID, tData)
	goGPlayerMgr:RoleOnlineReq(nRoleID, tData)
end

--角色下线通知
function Network.RpcSrv2Srv.GRoleOfflineReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	goGPlayerMgr:RoleOfflineReq(nRoleID)
end

--角色属性更新通知
function Network.RpcSrv2Srv.GRoleUpdateReq(nSrcServer, nSrcService, nTarSession, nRoleID, tData)
    goGPlayerMgr:RoleUpdateReq(nRoleID, tData)
end