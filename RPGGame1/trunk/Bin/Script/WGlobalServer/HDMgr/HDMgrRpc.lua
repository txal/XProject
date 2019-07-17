--GM开启活动
function Network.RpcSrv2Srv.GMOpenAct(nSrcServer, nSrcService, nTarSession,nActID, nSubActID, nStartTime, nEndTime, nAwardTime, nExtID, nExtID1)
	return goHDMgr:GMOpenAct(nActID, nSubActID, nStartTime, nEndTime, nAwardTime, nExtID, nExtID1)
end

--预约活动开启
function Network.RpcSrv2Srv.BookActOpenReq(nSrcServer, nSrcService, nTarSession, tActList)
	return goHDMgr:HDCircleActOpen(tActList)
end