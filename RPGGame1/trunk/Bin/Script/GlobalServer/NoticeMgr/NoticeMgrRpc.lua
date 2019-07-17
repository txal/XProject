------发送滚动公告[W]LOGIC
function Network.RpcSrv2Srv.SendNoticeReq(nSrcServer, nSrcService, nTarSession, sCont)
	goNoticeMgr:SendNoticeReq(sCont)
end
