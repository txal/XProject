------客户端服务器------

--获取伙伴模块数据
function CltPBProc.PartnerBlockDataReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oPartner:SyncPartnerBlockData()
end

--获取伙伴详细数据
function CltPBProc.PartnerDetailReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oPartner:SyncPartnerDetailData(tData.nID)
end

--获取所有伙伴详细数据
function CltPBProc.PartnerDetailListReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oPartner:SyncPartnerListDetailData()
end

--招募伙伴请求
function CltPBProc.PartnerRecruitReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oPartner:RecruitPartnerReq(tData.nPartnerID)
end

--购买灵石采集许可次数
function CltPBProc.PartnerAddMaterialCollectCountReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oPartner:AddMaterialCollectCountReq(tData.nCount)
end

--灵石采集请求
function CltPBProc.PartnerStoneCollectReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oPartner:CollectPartnerStone(tData.nPropID, tData.nGridID, tData.nCount, tData.bMax)
end

--伙伴上阵请求
function CltPBProc.PartnerBattleActiveReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oPartner:BattleActiveReq(tData.nPlanID, tData.nPartnerID)
end

--伙伴下阵请求
function CltPBProc.PartnerBattleRestReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oPartner:BattleRestReq(tData.nPlanID, tData.nPos)
end

--伙伴上阵方案切换请求
function CltPBProc.PartnerSwitchPlanReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oPartner:SwitchPlanReq(tData.nPlanID)
end

--点亮伙伴星级星星请求
function CltPBProc.PartnerAddStarCountReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oPartner:AddStarCountReq(tData.nPartnerID)
end

--伙伴星级升级请求
function CltPBProc.PartnerStarLevelUpReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oPartner:StarLevelUpReq(tData.nPartnerID)
end

--给指定伙伴送礼请求
function CltPBProc.PartnerSendGiftReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	--[[
	message PropIDNum
	{
		required int32 nPropID = 1;   // 道具ID
		required int32 nPropNum = 2;  // 道具数量
	}
	message PartnerSendGiftReq
	{
		required int32 nPartnerID = 1;       // 伙伴ID
		repeated PropIDNum tPropList = 2;    // 送礼的道具列表
	}
	]]
	local tPropList = {}
	for k, tPropData in pairs(tData.tPropList) do
		tPropList[tPropData.nPropID] = tPropData.nPropNum
	end
	oRole.m_oPartner:SendGiftReq(tData.nPartnerID, tPropList)
end

--给指定伙伴增加灵气请求
function CltPBProc.PartnerAddSpiritReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oPartner:AddSpiritReq(tData.nPartnerID, tData.nConfID)
end

--交换上阵伙伴位置请求
function CltPBProc.PartnerPlanSwapPosReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oPartner:PlanSwapPosReq(tData.nPlanID, tData.nPos1, tData.nPos2)
end

--关闭伙伴招募提示请求
function CltPBProc.PartnerRecruitTipsCloseReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oPartner:CloseRecruitTips()
end

function CltPBProc.PartnerXianzhenInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oPartner:SyncXianzhenData()
end

function CltPBProc.PartnerXianzhenLevelUpReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oPartner:XianzhenLevelUpReq()
end

function CltPBProc.PartnerReviveLevelUpReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oPartner:ReviveLevelUpReq(tData.nPartnerID, tData.nPropID, tData.nPropNum)
end

------服务器之间-------
function Srv2Srv.WGlobalTeamPartnerReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	return oRole.m_oPartner:WGlobalTeamPartnerReq()
end

function Srv2Srv.WGlobalHousePartnerReq(nSrcServer,nSrcService,nTarSession,nRoleID)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	return oRole.m_oPartner:WGlobalHousePartnerReq()
end

function Srv2Srv.WGlobalHousePartnerIntimacyReq(nSrcServer,nSrcService,nTarSession,nRoleID,nPartnerID)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	local oPartnerObj = oRole.m_oPartner:GetObj(nPartnerID)
	local nIntimacy = 0
	if oPartnerObj then
		nIntimacy = oPartnerObj:GetIntimacy()
	end
	return nIntimacy
end



