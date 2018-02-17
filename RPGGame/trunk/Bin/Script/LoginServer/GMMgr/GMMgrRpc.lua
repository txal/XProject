---------------服务器内部-------------
--GM指令
function Srv2Srv.GMCommandReq(nServer, nService, nSession, sCmd)
	goGMMgr:OnGMCmdReq(nServer, nService, nSession, sCmd)
end
