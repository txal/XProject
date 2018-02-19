function CltPBProc.RoleListReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    goLoginMgr:RoleListReq(nSrcServer, nTarSession, tData.nSource, tData.sAccount)
end

function CltPBProc.RoleLoginReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    goLoginMgr:RoleLoginReq(nSrcServer, nTarSession, tData.nAccountID, tData.nRoleID)
end

function CltPBProc.RoleCreateReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    goLoginMgr:RoleCreateReq(nSrcServer, nTarSession, tData.nAccountID, tData.nConfID, tData.sName)
end


------服务器内部------
--路由服务通知有服务断开(网关断开就关服)
function SrvCmdProc.OnServiceClose(nCmd, nSrcServer, nSrcService, nTarSession, nServer, nService)
    goLoginMgr:OnServiceClose(nServer, nService)
end

--客户端断开通知
function SrvCmdProc.OnClientClose(nCmd, nSrcServer, nSrcService, nTarSession)
    goLoginMgr:OnClientClose(nSrcServer, nTarSession)
end
