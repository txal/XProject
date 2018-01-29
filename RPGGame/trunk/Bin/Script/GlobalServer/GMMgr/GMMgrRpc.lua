---------客户端服务器---------
function CltPBProc.GMCmdReq(nCmd, nSrc, nSession, tData)
	goGMMgr:OnGMCmdReq(nSession, tData.sCmd)
end

--------服务器之间-----------
--修改属性返回
function Srv2Srv.GMModUserRet(nSrc, nSession, nBsrSession, bRes)
	goBrowser:OnModUserRet(nBsrSession, bRes)
end
