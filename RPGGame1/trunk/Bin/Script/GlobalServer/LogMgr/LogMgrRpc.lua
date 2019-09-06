--事件日志
function Network.RpcSrv2Srv.EventLogReq(nSrcServer, nSrcService, nTarSession, nEventID, sReason, tRoleInfo, ...)
	GetGModule("LogMgr"):EvenLog(nEventID, sReason, tRoleInfo, ...)
end

--创建账号日志
function Network.RpcSrv2Srv.CreateAccountLogReq(nSrcServer, nSrcService, nTarSession, tAccountInfo)
	GetGModule("LogMgr"):CreateAccountLog(tAccountInfo)
end

--更新账号信息
function Network.RpcSrv2Srv.UpdateAccountLogReq(nSrcServer, nSrcService, nTarSession, nAccountID, tParams)
	GetGModule("LogMgr"):UpdateAccountLog(nAccountID, tParams)
end

--创建角色日志
function Network.RpcSrv2Srv.CreateRoleLogReq(nSrcServer, nSrcService, nTarSession, tRoleInfo)
	GetGModule("LogMgr"):CreateRoleLog(tRoleInfo)
end

--更新账号信息
function Network.RpcSrv2Srv.UpdateRoleLogReq(nSrcServer, nSrcService, nTarSession, nRoleID, tParams)
	GetGModule("LogMgr"):UpdateRoleLog(nRoleID, tParams)
end

--上下线日志
function Network.RpcSrv2Srv.OnlineLogReq(nSrcServer, nSrcService, nTarSession, tRoleInfo, nOnlineType, nKeepTime, nTime)
	GetGModule("LogMgr"):OnlineLog(tRoleInfo, nOnlineType, nKeepTime, nTime)
end

--任务日志
function Network.RpcSrv2Srv.TaskLogReq(nSrcServer, nSrcService, nTarSession, tRoleInfo, nTaskType, nTaskID, nTaskState, nTime)
	GetGModule("LogMgr"):TaskLog(tRoleInfo, nTaskType, nTaskID, nTaskState, nTime)
end

--元宝日志
function Network.RpcSrv2Srv.YuanBaoLogReq(nSrcServer, nSrcService, nTarSession, tRoleInfo, sReason, nYuanBao, nCurrYuanBao, nBindFlag, nTime)
	GetGModule("LogMgr"):YuanBaoLog(tRoleInfo, sReason, nYuanBao, nCurrYuanBao, nBindFlag, nTime)
end
