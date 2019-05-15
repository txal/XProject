--远程调用测试
function Srv2Srv.RemoteCallTestReq(nSrcServer, nSrcService, nTarSession, nValue)
	return nValue
end

--服务断开通知(ROUTER)
function SrvCmdProc.OnServiceClose(nCmd, nSrcServer, nSrcService, nTarSession, nServer, nService)
    goLoginMgr:OnServiceClose(nServer, nService)
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
	local nTryTimes = 0
	goTimerMgr:Interval(1, function(nTimeID)
		nTryTimes = nTryTimes + 1
		if goWatcher:IsSignOuted() or nTryTimes >= 10 then
			goTimerMgr:Clear(nTimeID)
		    NetworkExport.Terminate()
		end
	end)
end
