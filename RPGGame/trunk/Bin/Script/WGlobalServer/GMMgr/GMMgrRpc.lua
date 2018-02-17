---------客户端服务器---------
function CltPBProc.GMCmdReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	goGMMgr:OnGMCmdReq(nSrcServer, nSrcService, nTarSession, tData.sCmd)
end

--------服务器之间-----------
