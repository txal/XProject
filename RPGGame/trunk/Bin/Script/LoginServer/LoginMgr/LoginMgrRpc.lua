function CltPBProc.RoleListReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    goLoginMgr:RoleListReq(nSrcServer, nTarSession, tData.nSource, tData.sAccount)
end

function CltPBProc.RoleLoginReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    print("CltPBProc.RoleLoginReq***", nSrcServer, nSrcService, nTarSession)
    goLoginMgr:RoleLoginReq(nSrcServer, nTarSession, tData.nAccountID, tData.nRoleID)
end

function CltPBProc.RoleCreateReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    goLoginMgr:RoleCreateReq(nSrcServer, nTarSession, tData.nAccountID, tData.nConfID, tData.sName)
end


------服务器内部------
--服务断开通知(ROUTER)
function SrvCmdProc.OnServiceClose(nCmd, nSrcServer, nSrcService, nTarSession, nServer, nService)
    goLoginMgr:OnServiceClose(nServer, nService)
end

--客户端断开通知(GATEWAY)
function SrvCmdProc.OnClientClose(nCmd, nSrcServer, nSrcService, nTarSession)
    goLoginMgr:OnClientClose(nSrcServer, nTarSession)
end

--更新角色摘要(LOGIC)
function Srv2Srv.RoleUpdateSummaryReq(nSrcServer, nSrcService, nTarSession, nAccountID, nRoleID, tSummary)
	goLoginMgr:RoleUpdateSummaryReq(nAccountID, nRoleID, tSummary)
end
