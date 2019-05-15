
--不同类型的活动，接口存在些许差异，很多不在HDBase中定义的
--所以, 相关活动操作, 都在goGrowthTargetMgr中查找活动处理, 以确保活动类型正确

--活动信息请求
function CltPBProc.GrowthTargetActInfoReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    --主动请求活动数据时，都触发一次
    local fnCallback = function()
        --不论是否成功，都给玩家发送数据
        goGrowthTargetMgr:SyncActInfo(oRole, tData.nID)
    end
    goGrowthTargetMgr:TriggerRoleActInfo(oRole, fnCallback)
end

--活动信息列表请求
function CltPBProc.GrowthTargetActInfoListReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    --主动请求活动数据时，都触发一次
    local fnCallback = function()
        --不论是否成功，都给玩家发送数据
        goGrowthTargetMgr:SyncActInfoList(oRole:GetID())
    end
    goGrowthTargetMgr:TriggerRoleActInfo(oRole, fnCallback)
end

--活动排行榜信息请求
function CltPBProc.GrowthTargetActRankInfoReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	goGrowthTargetMgr:ActRankInfoReq(oRole, tData.nActID, tData.nPageID)
end

--活动奖励领取请求
function CltPBProc.GrowthTargetActRewardReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goGrowthTargetMgr:TargetAwardReq(oRole, tData.nActID, tData.nRewardID)
end

--活动排名奖励领取请求
function CltPBProc.GrowthTargetActRankRewardReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goGrowthTargetMgr:RankingAwardReq(oRole, tData.nActID)
end

--活动充值奖励领取请求
function CltPBProc.GrowthTargetActRechargeRewardReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goGrowthTargetMgr:RechargeAwardReq(oRole, tData.nActID, tData.nRewardID)
end

--活动商店信息请求
function CltPBProc.GrowthTargetActShopReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
	goGrowthTargetMgr:SyncActShop(oRole)
end

--活动商店购买请求
function CltPBProc.GrowthTargetActShopPurchaseReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	goGrowthTargetMgr:ActShopPurchaseReq(oRole, tData.nIndexID, tData.nNum)
end


--------------------------------------------
function Srv2Srv.UpdateGrowthTargetActValReq(nSrcServer, nSrcService, nTarSession, nRoleID, eActType, nVal)
    local oAct = goGrowthTargetMgr:GetActivity(eActType)
    if not oAct or not oAct:IsOpen() then 
        return 
    end
    oAct:UpdateTargetVal(nRoleID, nVal)
end

function Srv2Srv.AddGrowthTargetActValReq(nSrcServer, nSrcService, nTarSession, nRoleID, eActType, nVal)
    local oAct = goGrowthTargetMgr:GetActivity(eActType)
    if not oAct or not oAct:IsOpen() then 
        return 
    end
    oAct:AddTargetVal(nRoleID, nVal)
end

