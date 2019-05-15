function CltPBProc.TestPack(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	-- CmdNet.PBSrv2Clt("TestPackRet", nSrcServer, nSession, tData)
end
function CltCmdProc.Ping(nCmd, nSrcServer, nSrcService, nTarSession)
	CmdNet.Srv2Clt("Ping", nSrcServer, nTarSession)
	LuaTrace("Ping------------")
end


------服务器内部------
--远程调用测试
function Srv2Srv.RemoteCallTestReq(nSrcServer, nSrcService, nTarSession, nValue)
	return nValue
end

--路由服务通知有服务断开
function SrvCmdProc.OnServiceClose(nCmd, nSrcServer, nSrcService, nTarSession, nServer, nService)
	--登录服挂掉就下线对于服的玩家
	for _, tConf in pairs(goServerMgr:GetLoginServiceList()) do
		if tConf.nServer == nServer and tConf.nID == nService then
		    goPlayerMgr:OnServerClose(nServer)
			break
		end
	end
end

--关服准备通知
function SrvCmdProc.PrepCloseServer(nCmd, nSrcServer, nSrcService, nTarSession, nServer, nService)
	if io.FileExist("debug.txt") then
		OnExitServer(nServer, nService)
	else
		xpcall(function() OnExitServer(nServer, nService) end, function(sErr) LuaTrace(sErr, debug.traceback()) end)
	end

	if nServer == gnServerID and nService == GF.GetServiceID() then
		CmdNet.Srv2Srv("PrepCloseServer", nSrcServer, nSrcService, 0, nServer, nService)
	end
end

--关服执行通知
function SrvCmdProc.ImplCloseServer(nCmd, nSrcServer, nSrcService, nTarSession, nServer, nService)
	print("ImplCloseServer***", nServer, nService)
	if nServer == gnServerID and nService == GF.GetServiceID() then
	    NetworkExport.Terminate()
	end
end

