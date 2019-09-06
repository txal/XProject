--客户端->服务器
function Network.CltPBProc.RoleListReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    GetGModule("LoginMgr"):RoleListReq(nSrcServer, nTarSession, tData.nSource, tData.sAccount, tData.nServerID)
end

function Network.CltPBProc.RoleLoginReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    GetGModule("LoginMgr"):RoleLoginReq(nSrcServer, nTarSession, tData.nAccountID, tData.nRoleID)
end

function Network.CltPBProc.RoleCreateReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    GetGModule("LoginMgr"):RoleCreateReq(nSrcServer, nTarSession, tData)
end


------服务器内部------
--客户端断开通知(GATEWAY)
function Network.SrvCmdProc.OnClientClose(nCmd, nSrcServer, nSrcService, nTarSession)
    return GetGModule("LoginMgr"):OnClientClose(nSrcServer, nTarSession)
end

--更新角色摘要(LOGIC)
function Network.RpcSrv2Srv.UpdateSimpleRoleReq(nSrcServer, nSrcService, nTarSession, nAccountID, nRoleID, tData)
	return GetGModule("LoginMgr"):UpdateSimpleRoleReq(nAccountID, nRoleID, tData)
end

--更新账号属性([W]GLOBAL)
function Network.RpcSrv2Srv.UpdateAccountDataReq(nSrcServer, nSrcService, nTarSession, nAccountID, tData)
	return GetGModule("LoginMgr"):UpdateAccountDataReq(nAccountID, tData)
end

--取账号属性([W]GLOBAL)
function Network.RpcSrv2Srv.AccountValueReq(nSrcServer, nSrcService, nTarSession, nAccountID, sKey)
	local oAccount = GetGModule("LoginMgr"):GetAccountByID(nAccountID)
    if not oAccount then
        return
    end
    return oAccount[sKey]
end

--删除角色请求
function Network.RpcSrv2Srv.DeleteRoleReq(nSrcServer, nSrcService, nTarSession, nAccountID, nRoleID)
	GetGModule("LoginMgr"):DeleteRoleReq(nAccountID, nRoleID)
end
