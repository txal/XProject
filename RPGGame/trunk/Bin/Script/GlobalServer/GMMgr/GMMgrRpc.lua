---------客户端服务器---------
function CltPBProc.GMCmdReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	goGMMgr:OnGMCmdReq(nSrcServer, nSrcService, nTarSession, tData.sCmd)
end

--------服务器之间-----------
--GM指令
function Srv2Srv.GMCommandReq(nSrcServer, nSrcService, nTarSession, sCmd)
    goGMMgr:OnGMCmdReq(nSrcServer, nSrcService, nTarSession, sCmd, true)
end
