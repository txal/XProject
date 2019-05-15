--预约活动开启
function Srv2Srv.BookActOpenReq(nSrcServer, nSrcService, nTarSession, tActList)
	return goHDMgr:HDCircleActOpen(tActList)
end