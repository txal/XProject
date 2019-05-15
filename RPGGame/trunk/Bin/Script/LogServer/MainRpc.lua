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

--HTTP服务器收到请求
--@cConn 链接
--@sData 数据
--@nType 1:Get; 2:Post
--@sURI 目录
HttpRequestMessage = function(cConn, sData, nType, sURI)
	LuaTrace("HTTP request:", sData, nType, sURI)
	http.Response(cConn, sData)
end
