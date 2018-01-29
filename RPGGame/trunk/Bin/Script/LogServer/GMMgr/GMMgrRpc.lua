---------------服务器内部-------------
--GM指令
function Srv2Srv.GMCommandReq(nSrc, nSession, sCmd)
	goGMMgr:OnGMCmdReq(nSession, sCmd)
end
