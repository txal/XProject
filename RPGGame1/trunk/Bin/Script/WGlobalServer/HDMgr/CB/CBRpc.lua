
--冲榜信息请求
function Network.RpcSrv2Srv.SyncCBState(nSrcServer, nSrcService, nTarSession,nRoleID, tData)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	goCBMgr:SyncState(oRole)
end

--冲榜活动请求
function Network.RpcSrv2Srv.CBInActivityReq(nSrcServer, nSrcService, nTarSession,nRoleID, tData)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	if tData.nID < 10 or tData.nID > 20 then
		return oRole:Tips("不是冲榜活动，协议发错了？")
	end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if oAct then
		oAct:InActivityReq(oRole)
	else
		oRole:Tips("活动:"..tData.nID.."不存在")
	end
end

--冲榜榜单请求
function Network.RpcSrv2Srv.CBRankingReq(nSrcServer, nSrcService, nTarSession,nRoleID, tData)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end 
	if tData.nID < 10 or tData.nID > 20 then
		return oRole:Tips("不是冲榜活动，协议发错了？")
	end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if oAct then
		oAct:RankingReq(oRole, tData.nRankNum)
	else
		oRole:Tips("活动:"..tData.nID.."不存在")
	end
end

--冲榜领奖请求
function Network.RpcSrv2Srv.CBGetAwardReq(nSrcServer, nSrcService, nTarSession,nRoleID, tData)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	if tData.nID < 10 or tData.nID > 20 then
		return oRole:Tips("不是冲榜活动，协议发错了？")
	end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if oAct then
		oAct:GetAwardReq(oRole)
	else
		oRole:Tips("活动:"..tData.nID.."不存在") 
	end
end

--机器人单服团购数据事件
function Network.RpcSrv2Srv.OnTCRobotRecharge(nSrcServer,nSrcService,nTarSession, nRobotNum, nServerID)
	if nRobotNum <= 0 or nServerID <= 0 then 
		return 
	end
	local oAct = goHDMgr:GetActivity(gtHDDef.eServerRechargeCB)
	oAct:OnRobotRecharge(nRobotNum, nServerID)
	return
end
