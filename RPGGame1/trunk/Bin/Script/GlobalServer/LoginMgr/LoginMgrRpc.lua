--客户端->服务器
function Network.CltPBProc.RoleListReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oLoginMgr = GetGModule("LoginMgr")
    oLoginMgr:RoleListReq(nSrcServer, nTarSession, tData.nSource, tData.sAccount, tData.nServerID)
end

function Network.CltPBProc.RoleLoginReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oLoginMgr = GetGModule("LoginMgr")
    oLoginMgr:RoleLoginReq(nSrcServer, nTarSession, tData.nAccountID, tData.nRoleID)
end

function Network.CltPBProc.RoleCreateReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oLoginMgr = GetGModule("LoginMgr")
    oLoginMgr:RoleCreateReq(nSrcServer, nTarSession, tData)
end


------服务器内部------
--客户端断开通知(GATEWAY)
function Network.SrvCmdProc.OnClientClose(nCmd, nSrcServer, nSrcService, nTarSession)
    local oLoginMgr = GetGModule("LoginMgr")
    oLoginMgr:OnClientClose(nSrcServer, nTarSession)
end

--更新角色摘要(LOGIC)
function Network.RpcSrv2Srv.RoleUpdateSummaryReq(nSrcServer, nSrcService, nTarSession, nAccountID, nRoleID, tSummary)
    local oLoginMgr = GetGModule("LoginMgr")
	oLoginMgr:RoleUpdateSummaryReq(nAccountID, nRoleID, tSummary)
end

--更新账号属性([W]GLOBAL)
function Network.RpcSrv2Srv.UpdateAccountValueReq(nSrcServer, nSrcService, nTarSession, nAccountID, tData)
    local oLoginMgr = GetGModule("LoginMgr")
	return oLoginMgr:UpdateAccountValueReq(nAccountID, tData)
end

--取账号属性([W]GLOBAL)
function Network.RpcSrv2Srv.AccountValueReq(nSrcServer, nSrcService, nTarSession, nAccountID, sKey)
    local oLoginMgr = GetGModule("LoginMgr")
	local oAccount = oLoginMgr:GetAccountByID(nAccountID)
    if not oAccount then return end
    return oAccount[sKey]
end

--删除角色请求
function Network.RpcSrv2Srv.DeleteRoleReq(nSrcServer, nSrcService, nTarSession, nAccountID, nRoleID)
    local oLoginMgr = GetGModule("LoginMgr")
	oLoginMgr:DeleteRoleReq(nAccountID, nRoleID)
end
