------服务器内部------
--远程调用测试
function Network.RpcSrv2Srv.RemoteCallTestReq(nSrcServer, nSrcService, nTarSession, nValue)
    return nValue
end

--路由服务通知有服务断开
function Network.SrvCmdProc.OnServiceClose(nCmd, nSrcServer, nSrcService, nTarSession, nServerID, nServiceID)
    goGModuleMgr:OnServiceClose(nServerID, nServiceID)  
end

--关服准备通知
function Network.SrvCmdProc.PrepCloseServer(nCmd, nSrcServer, nSrcService, nTarSession, nServerID, nServiceID)
    if io.FileExist("debug.txt") then
        OnServerClose(nServerID)
    else
        xpcall(function() OnServerClose(nServerID, nServiceID) end, function(sErr) LuaTrace(sErr, debug.traceback()) end)
    end

    local oServerMgr = GetGModule("ServerMgr")
    if nServerID == oServerMgr:GetServerID() and nServiceID == CUtil:GetServiceID() then
        Network.CmdSrv2Srv("PrepCloseServer", nSrcServer, nSrcService, 0, nServerID, nServiceID)
    end
end

--关服执行通知
function Network.SrvCmdProc.ImplCloseServer(nCmd, nSrcServer, nSrcService, nTarSession, nServerID, nServiceID)
    local oServerMgr = GetGModule("ServerMgr")
    if nServerID == oServerMgr:GetServerID() and nServiceID == CUtil:GetServiceID() then
        NetworkExport.Terminate()
    end
end


--非法字检测
function Network.RpcSrv2Srv.HasBadWordReq(nSrcServer, nSrcService, nTarSession, sCont)
    assert(GlobalExport.HasWord, "该服务没导出相关模块")
    local sLowerCont = string.lower(sCont)
    local bHasBadWrod = false
    CUtil:HasBadWord(sLowerCont, function(bReturn)
        bHasBadWrod = bReturn
    end)
    return bHasBadWrod 
end

--非法字过滤
function Network.RpcSrv2Srv.FilterBadWordReq(nSrcServer, nSrcService, nTarSession, sCont)
    assert(GlobalExport.HasWord, "该服务没导出相关模块")
    local sLowerCont = string.lower(sCont)
    local sFilterCont = sCont
    CUtil:FilterBadWord(sLowerCont, function(sReturnCnt)
        sFilterCont = sReturnCnt
    end)
    return sFilterCont
end
