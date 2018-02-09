---------------服务器内部-------------
--GM指令
function Srv2Srv.GMCommandReq(nSrcServer, nSrcService, nTarSession, sCmd)
	goGMMgr:OnGMCmdReq(nTarSession, sCmd)
end
