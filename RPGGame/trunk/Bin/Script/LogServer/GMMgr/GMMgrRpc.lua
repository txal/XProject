---------------服务器内部-------------
--GM指令
function Srv2Srv.GMCommandReq(nSrcServer, nSrcService, nOnUsed, sCmd)
	goGMMgr:OnGMCmdReq(0, sCmd)
end
