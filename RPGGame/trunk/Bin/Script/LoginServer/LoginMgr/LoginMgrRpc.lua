--客户端->服务器
function CltPBProc.RoleListReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    goLoginMgr:RoleListReq(nSrcServer, nTarSession, tData.nSource, tData.sAccount, tData.nServerID)
end

function CltPBProc.RoleLoginReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    goLoginMgr:RoleLoginReq(nSrcServer, nTarSession, tData.nAccountID, tData.nRoleID)
end

function CltPBProc.RoleCreateReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    goLoginMgr:RoleCreateReq(nSrcServer, nTarSession, tData)
end


------服务器内部------
--客户端断开通知(GATEWAY)
function SrvCmdProc.OnClientClose(nCmd, nSrcServer, nSrcService, nTarSession)
    goLoginMgr:OnClientClose(nSrcServer, nTarSession)
end

--更新角色摘要(LOGIC)
function Srv2Srv.RoleUpdateSummaryReq(nSrcServer, nSrcService, nTarSession, nAccountID, nRoleID, tSummary)
	goLoginMgr:RoleUpdateSummaryReq(nAccountID, nRoleID, tSummary)
end

--更新账号属性([W]GLOBAL)
function Srv2Srv.UpdateAccountValueReq(nSrcServer, nSrcService, nTarSession, nAccountID, tData)
	return goLoginMgr:UpdateAccountValueReq(nAccountID, tData)
end

--取账号属性([W]GLOBAL)
function Srv2Srv.AccountValueReq(nSrcServer, nSrcService, nTarSession, nAccountID, sKey)
	local oAccount = goLoginMgr:GetAccountByID(nAccountID)
    if not oAccount then return end
    return oAccount[sKey]
end

--删除角色请求
function Srv2Srv.DeleteRoleReq(nSrcServer, nSrcService, nTarSession, nAccountID, nRoleID)
	goLoginMgr:DeleteRoleReq(nAccountID, nRoleID)
end
