------服务器内部------
--远程调用测试
function Srv2Srv.RemoteCallTestReq(nSrcServer, nSrcService, nTarSession, nValue)
    return nValue
end

--路由服务通知有服务断开
function SrvCmdProc.OnServiceClose(nCmd, nSrcServer, nSrcService, nTarSession, nServer, nService)
end

--关服准备通知
function SrvCmdProc.PrepCloseServer(nCmd, nSrcServer, nSrcService, nTarSession, nServer, nService)
	assert(nServer == gnServerID and GF.GetServiceID() == nService, "参数错误")
    if io.FileExist("debug.txt") then
        OnExitServer(nServer, nService)
    else
        xpcall(function() OnExitServer(nServer, nService) end, function(sErr) LuaTrace(sErr, debug.traceback()) end)
    end
	CmdNet.Srv2Srv("PrepCloseServer", nSrcServer, nSrcService, 0, nServer, nService)
end

--关服执行通知
function SrvCmdProc.ImplCloseServer(nCmd, nSrcServer, nSrcService, nTarSession, nServer, nService)
	assert(nServer == gnServerID and GF.GetServiceID() == nService, "参数错误")
    NetworkExport.Terminate()
end

--非法字检测
function Srv2Srv.HasBadWordReq(nSrcServer, nSrcService, nTarSession, sCont)
    local sLowerCont = string.lower(sCont)
    if GlobalExport.HasWord(sLowerCont) then
        return true
    end
    return false
end

--非法字过滤
function Srv2Srv.FilterBadWordReq(nSrcServer, nSrcService, nTarSession, sCont)
    local sLowerCont = string.lower(sCont)
    if GlobalExport.HasWord(sLowerCont) then
        return GlobalExport.ReplaceWord(sLowerCont, "*")
    else
        return sCont
    end
end
