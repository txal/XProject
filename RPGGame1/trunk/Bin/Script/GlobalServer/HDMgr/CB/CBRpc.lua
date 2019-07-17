--冲榜信息请求
function Network.CltPBProc.CBInfoReq(nCmd, nServer, nSrevice, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	goCBMgr:SyncState(oRole)
	Network.oRemoteCall:Call("SyncCBState", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0,oRole:GetID(),tData)
end

--冲榜活动请求
function Network.CltPBProc.CBInActivityReq(nCmd, nServer, nSrevice, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	if tData.nID < 10 or tData.nID > 20 then
		return oRole:Tips("不是冲榜活动，协议发错了？")
	end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if oAct then
		oAct:InActivityReq(oRole)
	else
		--全服活动
		local tConf = ctHuoDongConf[tData.nID]
		if tConf.bCrossServer then
			Network.oRemoteCall:Call("CBInActivityReq", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0,oRole:GetID(),tData)
		else
			oRole:Tips("活动:"..tData.nID.."不存在")
		end
	end
end

--冲榜榜单请求
function Network.CltPBProc.CBRankingReq(nCmd, nServer, nSrevice, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end 
	if tData.nID < 10 or tData.nID > 20 then
		return oRole:Tips("不是冲榜活动，协议发错了？")
	end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if oAct then
		oAct:RankingReq(oRole, tData.nRankNum)
	else
		local tConf = ctHuoDongConf[tData.nID]
		if tConf.bCrossServer then
			Network.oRemoteCall:Call("CBRankingReq", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0,oRole:GetID(),tData)
		else
			oRole:Tips("活动:"..tData.nID.."不存在")
		end
	end
end

--冲榜领奖请求
function Network.CltPBProc.CBGetAwardReq(nCmd, nServer, nSrevice, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	if tData.nID < 10 or tData.nID > 20 then
		return oRole:Tips("不是冲榜活动，协议发错了？")
	end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if oAct then
		oAct:GetAwardReq(oRole)
	else
		--全服活动
		local tConf = ctHuoDongConf[tData.nID]
		if tConf.bCrossServer then
			Network.oRemoteCall:Call("CBGetAwardReq", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0,oRole:GetID(),tData)
		else
			oRole:Tips("活动:"..tData.nID.."不存在")
		end 
	end
end


-------------服务器内部
--竞技场积分
function Network.RpcSrv2Srv.OnCBJJCReq(nSrcServer, nSrcService, nTarSession, nRoleID, nDiffValue)
	local oAct = goHDMgr:GetActivity(gtHDDef.eArenaCB)
	oAct:UpdateValue(nRoleID, nDiffValue)
end

--仙侣亲密度
function Network.RpcSrv2Srv.OnCBQMDReq(nSrcServer, nSrcService, nTarSession, nRoleID, nDiffValue)
	local oAct = goHDMgr:GetActivity(gtHDDef.eHoneyCB)
	oAct:UpdateValue(nRoleID, nDiffValue)
end

--人气冲榜
function Network.RpcSrv2Srv.OnCBPopularityReq(nSrcServer, nSrcService, nTarSession, nRoleID, nDiffValue)
	local oAct = goHDMgr:GetActivity(gtHDDef.ePopularityCB)
	oAct:UpdateValue(nRoleID, nDiffValue)
end

--冲榜添加机器人数据
function Network.RpcSrv2Srv.OnRobotRechargeCB(nSrcServer,nSrcService,nTarSession,nRoleID,sName,nValue)
	if nValue > 0 then
		--充值冲榜
		local oAct = goHDMgr:GetActivity(gtHDDef.eRechargeCB)
		return oAct:OnRobotRecharge(nRoleID,sName, nValue)
	end
end

