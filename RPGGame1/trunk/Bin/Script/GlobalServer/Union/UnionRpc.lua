--请求联盟信息
function Network.CltPBProc.UnionDetailReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end

	oUnion:UnionDetailReq(oRole)
end

--联盟列表请求
function Network.CltPBProc.UnionListReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	goUnionMgr:UnionListReq(oRole, tData.sUnionKey, tData.nPageIndex)
end

--申请加入联盟请求
function Network.CltPBProc.UnionApplyReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local oUnion = goUnionMgr:GetUnion(tData.nID)
	if not oUnion then return end

	oUnion:UnionApplyReq(oRole)
end

--创建联盟请求
function Network.CltPBProc.UnionCreateReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	goUnionMgr:UnionCreateReq(oRole, tData.sName, tData.sNotice)
end

--退出联盟请求
function Network.CltPBProc.UnionExitReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end

	oUnion:UnionExitReq(oRole)
end

--设置联盟宣言请求
function Network.CltPBProc.UnionSetDeclarationReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end

	oUnion:SetDeclarationReq(oRole, tData.sDeclaration)
end

--审批设置
function Network.CltPBProc.UnionSetAutoJoinReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end

	oUnion:SetAutoJoinReq(oRole, tData.nAutoJoin)
end

--申请列表请求
function Network.CltPBProc.UnionApplyListReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end

	oUnion:ApplyListReq(oRole)
end

--接受申请
function Network.CltPBProc.UnionAcceptApplyReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end

	oUnion:AcceptApplyReq(oRole, tData.nRoleID)
end

--拒绝申请
function Network.CltPBProc.UnionRefuseApplyReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end

	oUnion:RefuseApplyReq(oRole, tData.nRoleID)
end

--队员列表请求
function Network.CltPBProc.UnionMemberListReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end

	oUnion:MemberListReq(oRole)
end

--移除队员
function Network.CltPBProc.UnionKickMemberReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end

	oUnion:KickMemberReq(oRole, tData.nRoleID)
end

--任命职位请求
function Network.CltPBProc.UnionAppointReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end
	
	oUnion:AppointReq(oRole, tData.nRoleID, tData.nPos)
end

--联盟升级请求
function Network.CltPBProc.UnionUpgradeReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end
	
	oUnion:UpgradeReq(oRole)
end

--成员详细信息请求
function Network.CltPBProc.MemberDetailReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end
	
	oUnion:MemberDetailReq(oRole, tData.nRoleID)
end

--随机加入联盟
function Network.CltPBProc.UnionJoinRandReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	goUnionMgr:UnionJoinRandReq(oRole)
end

--联盟兑换列表请求
function Network.CltPBProc.UnionExchangeListReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end

	oUnion:ExchangeListReq(oRole)
end

--联盟兑换请求
function Network.CltPBProc.UnionExchangeReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end

	oUnion:ExchangeReq(oRole, tData.nID)
end

--联盟管理信息请求
function Network.CltPBProc.UnionManagerInfoReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end

	oUnion:ManagerInfoReq(oRole)
end

--联盟签到请求
function Network.CltPBProc.UnionSignReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end

	oUnion:SignReq(oRole)
end

--改职位名请求
function Network.CltPBProc.UnionModPosNameReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end

	oUnion:ModPosNameReq(oRole, tData.nPos, tData.sPos)
end

--领取俸禄请求
function Network.CltPBProc.UnionGetSalaryReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end

	oUnion:GetSalaryReq(oRole)
end

function Network.CltPBProc.UnionSetPurposeReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then
		return
	end

	oUnion:SetPurposeReq(oRole, tData.sCont)
end

--联盟公告已读请求
function Network.CltPBProc.UnionDeclarationReadedReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end
	oUnion:UnionDeclarationReadedReq(oRole)
end

function Network.CltPBProc.UnionPowerRankingReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	goUnionMgr:UnionPowerRankingReq(oRole, tData.nRankNum)
end

function Network.CltPBProc.UnionOpenGiftBoxReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end
	oUnion:UnionOpenGiftBoxReq(oRole)
end

function Network.CltPBProc.UnionDispatchGiftReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end
	oUnion:UnionDispatchGiftReq(oRole,tData.tRoleID)
end

function Network.CltPBProc.UnionEnterSceneReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then
		oRole:Tips("没有帮派")
		return
	end
	if not oUnion then return end
	oUnion:UnionEnterSceneReq(oRole)
end

-----------------------服务器内部-----------------------------
--取今日已使用联盟神诏数量[W]LOGIC
function Network.RpcSrv2Srv.UsedShenZhaoNumReq(nSrcServer, nSrcService, nTarSession, nRoleID, nPropID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end

	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end

	return oUnion:GetUsedShenZhaoNum(oRole, nPropID)
end

--使用联盟神诏事件[W]LOGIC
function Network.RpcSrv2Srv.OnUseShenZhaoReq(nSrcServer, nSrcService, nTarSession, nRoleID, nPropID, nPropNum, nMaxNum)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end

	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then return end

	return oUnion:OnUseShenZhao(oRole, nPropID, nPropNum, nMaxNum)
end

--取联盟贡献[W]LOGIC
function Network.RpcSrv2Srv.UnionContriReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end

	return oRole:GetUnionContri()
end

--联盟聊天WGLOBAL
function Network.RpcSrv2Srv.UnionTalkReq(nSrcServer, nSrcService, nTarSession, nRoleID, tTalk)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end

	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then
		return oRole:Tips("请先加入帮派")
	end

	oUnion:BroadcastUnionMsg("TalkRet", {tList={tTalk}})
end

--联盟成员列表请求WGLOBAL
function Network.RpcSrv2Srv.UnionMemberListReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	local tMemberList = goUnionMgr:GetMemberList(nRoleID)
	return tMemberList
end

--角色联盟信息请求
function Network.RpcSrv2Srv.RoleUnionInfoReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then
		return
	end
	return {nUnionID=oUnion:GetID(), sUnionName=oUnion:GetName()}
end

--获取联盟列表信息
function Network.RpcSrv2Srv.PackUnionArenaData(nSrcServer, nSrcService, nTarSession)
	local tArenaData = goUnionMgr:PackUnionArenaData()
	return tArenaData
end

--帮战匹配信息
function Network.RpcSrv2Srv.MatchUnionArena(nSrcServer,nSrcService,nTarSession,tData)
	goUnionMgr:SetMatchArenaData(tData)
end

--获取玩家所属联盟名
function Network.RpcSrv2Srv.GetPlayerUnionNameReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if oUnion then
		return oUnion:GetName()
	end
end

--获取玩家帮派ID
function Network.RpcSrv2Srv.GetPlayerUnionReq(nSrcServer, nSrcService, nTarSession, nRoleID, nTarRoleID)
	if nTarRoleID then	
		local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
		local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
		if not oRole or  not oTarRole then return end
		local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
		local oTarUnion = goUnionMgr:GetUnionByRoleID(nTarRoleID)
		if oUnion and oTarUnion then
			return oUnion:GetID(), oTarUnion:GetID()
		end	
	else
		local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
		if not oRole then return end
		local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
		if oUnion then
			return oUnion:GetID()
		end
	end
end

function Network.RpcSrv2Srv.BroadcastUnionTalk(nSrcServer,nSrcService,nTarSession,nRoleID,sCont)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if oUnion then
		oUnion:BroadcastUnionTalk(sCont)
	end
end

function Network.RpcSrv2Srv.AddUnionGiftBoxCnt(nSrcServer,nSrcService,nTarSession,nUnionID,sType,nBoxCnt)
	local oUnion = goUnionMgr:GetUnion(nUnionID)
	if oUnion then
		oUnion:AddGiftBoxCnt(sType,nBoxCnt)
	end
end

function Network.RpcSrv2Srv.AddUnionGiftBoxCntByRole(nSrcServer,nSrcService,nTarSession, nRoleID, sType, nBoxCnt)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID) 
	assert(oRole)
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if oUnion then
		oUnion:AddGiftBoxCnt(sType,nBoxCnt)
	end
end

--逻辑服已经启动
function Network.RpcSrv2Srv.OnLogicStart(nSrcServer,nSrcService,nTarSession)
	goUnionMgr:CreateUnionScene()
end

--减少帮贡
function Network.RpcSrv2Srv.SubUnionContri(nSrcServer,nSrcService,nTarSession,nRoleID,nContri,sReason)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oUnionRole = goUnionMgr:GetUnionRole(nRoleID)
	if not oUnionRole then return end
	if oRole:GetUnionContri() < nContri then
		return false
	end
	oRole:AddUnionContri(-nContri,sReason)
	return true
end

