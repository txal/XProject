function CltPBProc.TestPack(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	print("TestPack***",tData)
	CmdNet.PBSrv2Clt("TestPackRet", nSrcServer, nSession, tData)
end


------服务器内部------
--路由服务通知有服务断开(网关断开就关服)
function SrvCmdProc.OnServiceClose(nCmd, nSrcServer, nSrcService, nTarSession, nServer, nService)
end


