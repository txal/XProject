--预约活动开启
function Network.RpcSrv2Srv.BookActOpenReq(nSrcServer, nSrcService, nTarSession, tActList)
	return goHDMgr:HDCircleActOpen(tActList)
end