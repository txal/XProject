--------------客户端服务器---------------
--@nServer 来源服务器
--@nService 来源服务(客户端通常是0)
--@nSession 目标网络句柄
--@tData PB数据
function CltPBProc.RoleAttrReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole:RoleAttrReq()
end

--参数同上
function CltPBProc.RoleModNameReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole:RoleModNameReq(tData.sName, tData.bProp)
end


function CltPBProc.RoleStuckLevelReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole:StuckLevelReq(tData.bStuck)
end

function CltPBProc.RoleServerLvReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole:RoleServerLvReq()
end


---------------服务器内部----------------
--角色上线通知(LOGIN)
function Srv2Srv.RoleOnlineReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	return goPlayerMgr:RoleOnlineReq(nSrcServer, nTarSession, nRoleID)
end

--角色下线通知(LOGIN)
function Srv2Srv.RoleOfflineReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	return goPlayerMgr:RoleOfflineReq(nRoleID)
end

--角色断线通知(LOGIN)
function Srv2Srv.RoleDisconnectReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    return goPlayerMgr:RoleDisconnectReq(nRoleID)
end

--角色删除检查(LOGIN)
function Srv2Srv.DeleteRoleCheckReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    return goPlayerMgr:DeleteRoleCheckReq(nRoleID)
end

--物品数量请求([W]GLOBAL)
function Srv2Srv.RoleItemCountReq(nSrcServer, nSrcService, nTarSession, nRoleID, nType, nID)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    return oRole:ItemCount(nType, nID)
end

--针对某道具的背包剩余容量([W]GLOBAL)
function Srv2Srv.KnapsackRemainCapacityReq(nSrcServer, nSrcService, nTarSession, nRoleID, nPropID, bBind)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    return oRole.m_oKnapsack:GetRemainCapacity(nPropID, bBind)
end

--物品列表数量请求(GLOBAL)
function Srv2Srv.RoleItemCountListReq(nSrcServer, nSrcService, nTarSession, nRoleID, tItemList)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    local tRet = {}
    for _, tItem in ipairs(tItemList) do
        local nNum = oRole:ItemCount(tItem.nType, tItem.nID)
        table.insert(tRet, {nType = tItem.nType, nID = tItem.nID, nNum = nNum})
    end
    return tRet
end

--检查物品数量请求(GLOBAL)
function Srv2Srv.RoleCheckItemCountReq(nSrcServer, nSrcService, nTarSession, nRoleID, tItemList)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    local bRetFlag = true
    local tTrueList = {}
    local tFalseList = {}
    for _, tItem in ipairs(tItemList) do
        local nNum = oRole:ItemCount(tItem.nType, tItem.nID)
        if nNum < tItem.nNum then
            bRetFlag = false
            table.insert(tFalseList, {nType = tItem.nType, nID = tItem.nID, nNum = nNum})
        else
            table.insert(tTrueList, {nType = tItem.nType, nID = tItem.nID, nNum = nNum})
        end
    end
    return bRetFlag, tTrueList, tFalseList
end

--物品数量增加([W]GLOBAL)
function Srv2Srv.RoleAddItemReq(nSrcServer, nSrcService, nTarSession, nRoleID, tItemList, sReason)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    oRole:AddItemList(tItemList, sReason)
    return true
end

--物品数量扣除([W]GLOBAL)
function Srv2Srv.RoleSubItemReq(nSrcServer, nSrcService, nTarSession, nRoleID, tItemList, sReason)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    local tTransItem = {}
    for _, tItem in ipairs(tItemList) do 
        table.insert(tTransItem, {tItem.nType, tItem.nID, tItem.nNum})
    end
    assert(#tTransItem > 0, "参数错误")
    return oRole:CheckSubShowNotEnoughTips(tTransItem, sReason, true)
end

--扣除指定格子的物品
function Srv2Srv.RoleSubPropByGridReq(nSrcServer, nSrcService, nTarSession, nRoleID, tItemList, sReason)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    local oKnapsack = oRole.m_oKnapsack
    for _, tItem in ipairs(tItemList) do
        local oProp = oKnapsack:GetItem(tItem.nGrid)
        if not oProp or oProp:GetNum() < tItem.nNum then
            return
        end
    end
    for _, tItem in ipairs(tItemList) do
        oKnapsack:SubGridItem(tItem.nGrid, tItem.nID, tItem.nNum, sReason)
    end
    return true
end

--获取并扣除背包指定格子道具
-- {{nID, nGrid, nNum}, ...}
function Srv2Srv.RoleGetPropDataWithSubReq(nSrcServer, nSrcService, nTarSession, nRoleID, tItemList, sReason, bUnbindLimit)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    --check
    for k, v in ipairs(tItemList) do 
        assert(v.nID > 0 and v.nGrid > 0 and v.nNum > 0, "RoleGetPropDataWithSubReq参数错误")
        local tProp = oRole.m_oKnapsack:GetItem(v.nGrid)
        if not tProp then 
            oRole:Tips("道具不存在")
            return
        end
        if tProp:GetID() ~= v.nID then --主要用于验证道具是否正确
            print("道具ID错误，ID:"..v.nID..", tProp:GetID():"..tProp:GetID())
            oRole:Tips("道具ID错误")
            return
        end
        if tProp:GetNum() < v.nNum then 
            oRole:Tips(string.format("%s数量不足", tProp:GetName()))
            return
        end
        if bUnbindLimit then 
            if tProp:IsBind() then 
                oRole:Tips(string.format("%s已绑定", tProp:GetName()))
                return
            end
        end
    end

    local tPropDataList = {}
    --sub
    for k, v in ipairs(tItemList) do 
        local tProp = oRole.m_oKnapsack:GetItem(v.nGrid)
        assert(tProp)
        local tTempData = tProp:SaveData()
        tTempData.m_nFold = v.nNum
        oRole.m_oKnapsack:SubGridItem(v.nGrid, v.nID, v.nNum, sReason)
        table.insert(tPropDataList, tTempData)
    end
    return true, tPropDataList
end

--物品数量扣除提示
function Srv2Srv.RoleSubItemShowNotEnoughTipsReq(nSrcServer, nSrcService, nTarSession, nRoleID, tItemList, sReason, bFirstBreak, bNum)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    local tList = {}
    for k, v in ipairs(tItemList) do
        table.insert(tList, {v.nType, v.nID, v.nNum})
    end
    return oRole:CheckSubShowNotEnoughTips(tList, sReason, bFirstBreak, bNum)
end

--传送物品列表请求([W]GLOBAL)
function Srv2Srv.RoleTransferItemListReq(nSrcServer, nSrcService, nTarSession, nRoleID, tPropDataList, sReason)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    oRole:TransferItemList(tPropDataList, sReason)
    return true
end

--根据道具数据发送物品详细信息给客户端
function Srv2Srv.RolePropDetailInfoReq(nSrcServer, nSrcService, nTarSession, nRoleID, tPropData)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end

	local oProp = oRole.m_oKnapsack:CreateProp(tPropData.m_nID, tPropData.m_nGrid)
	oProp:LoadData(tPropData)
	oProp:SetGrid(0)
    oRole.m_oKnapsack:SendPropDetailInfo(oProp)
    return true
end

--获取物品的详细信息
function Srv2Srv.RoleItemDetailDataReq(nSrcServer, nSrcService, nTarSession, nRoleID, nBelongServer, nItemType, nKey)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then 
        -- return false, "角色不在线"
        --可能异步查询期间，机器人销毁，从而导致触发异常
        if GF.IsRobot(nRoleID) then 
            return false
        end
        oRole = CTempRole:new(nBelongServer, nRoleID)
        assert(oRole, "创建临时角色失败")
    end
    local tDetailData, sReason = oRole:GetItemDetailData(nItemType, nKey)
    if oRole:IsTempRole() then 
        oRole:Release()
    end
    if not tDetailData then 
        return false, sReason
    end
    return true, tDetailData
end

--查询摆摊刷新道具([W]GLOBAL)
function Srv2Srv.QueryMarketFlushItemReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    return oRole:QueryMarketFlushItem()
end

--查询角色的简要信息
function Srv2Srv.RoleInfoDataReq(nSrcServer, nSrcService, nTarSession, nRoleID, nBelongServer)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then 
        -- return false, "角色不在线"
        --可能异步查询期间，机器人销毁，从而导致触发异常
        if GF.IsRobot(nRoleID) then 
            return false
        end
        oRole = CTempRole:new(nBelongServer, nRoleID)
        assert(oRole, "创建临时角色失败")
    end
    local tRoleInfoData, sReason = oRole:GetRoleInfoData()
    if oRole:IsTempRole() then 
        oRole:Release()
    end
    if not tRoleInfoData then 
        return false, sReason
    end
    return true, tRoleInfoData
end

--切换到该逻辑服请求([W]LOGIC)
--@nSrcServer: 来源服务器ID(可能是世界服过来,所以要带上角色自己服务器ID)
--@nTarSession: 目标角色会话ID
--@tSwitch: {nServer=角色所属服务器, nSession=角色会话ID, nRoleID=角色ID, nSrcDupMixID=源副本ID, nTarDupMixID=目标副本ID, nPosX=坐标X, nPosY=坐标Y, nLine=分线, nFace=面向}
function Srv2Srv.SwitchLogicReq(nSrcServer, nSrcService, nTarSession, tSwitch) 
    goPlayerMgr:OnSwitchLogicReq(tSwitch)
end

function Srv2Srv.RobotSwitchLogicReq(nSrcServer, nSrcService, nTarSession, tSwitch, tCreateData, tSaveData)
    goPlayerMgr:OnRobotSwitchLogicReq(tSwitch, tCreateData, tSaveData)
end

--组队切换逻辑服请求([W]GLOBAL)
--@nSrcServer: 来源服务器ID(可能是世界服过来,所以要带上角色自己服务器ID)
--@nTarSession: 目标角色会话ID
function Srv2Srv.WSwitchLogicReq(nSrcServer, nSrcService, nTarSession, tTarget) 
    local oRole = goPlayerMgr:GetRoleByID(tTarget.nRoleID)
    if not oRole then
        return LuaTrace("WSwitchLogicReq角色不存在", tTarget.nRoleID)
    end
    local tSwitch = {nServer=oRole:GetServer(), nSession=oRole:GetSession(), nRoleID=tTarget.nRoleID
        , nSrcDupMixID=oRole:GetDupMixID()
        , nTarDupMixID=tTarget.nTarDupMixID, nPosX=tTarget.nPosX, nPosY=tTarget.nPosY, nLine=tTarget.nLine, nFace=tTarget.nFace}
    goDupMgr:SwitchLogic(tSwitch)
end

--查询角色的副本信息[WGLOBAL]
function Srv2Srv.QueryRoleDupInfoReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then
        return LuaTrace("QueryRoleDupInfoReq角色不存在", nRoleID)
    end
    return oRole:GetDupMixID(), oRole:GetLine(), oRole:GetPos()
end

--更新角色属性([W]GLOBAL)
function Srv2Srv.RoleUpdateReq(nSrcServer, nSrcService, nTarSession, nServerID, nRoleID, tData)
    CRole:RoleUpdateReq(nServerID, nRoleID, tData)
    return true
end

--取角色属性([W]GLOBAL)
function Srv2Srv.RoleValueReq(nSrcServer, nSrcService, nTarSession, nRoleID, sKey)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    return oRole[sKey] or 0
end

--发送邮件奖励
function Srv2Srv.SendMailAwardReq(nSrcServer, nSrcService, nTarSession, nRoleID, tItemList, bNotSync)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    -- if oRole.m_oKnapsack:GetFreeGridCount() < #tItemList then
    --     return oRole:Tips("背包已满，请先清理背包")
    -- end
    local tPropList= {}
    local tTarnsList = {}
    local tFaBaoList = {}

    --道具堆叠处理
    local tTempList = table.DeepCopy(tItemList)
    local function _ItemCheckCount(tItem)
        if tItem.m_nID then
            local tPropConf = ctPropConf[tItem.m_nID]
            if not tPropConf then
                LuaTrace("道具配置不存在:", tItem, oRole:GetID())
            else
                table.insert(tTarnsList, tItem)
            end

        elseif tItem[1] == gtItemType.eProp then
            local tPropConf = ctPropConf[tItem[2]]
            if not tPropConf then
                LuaTrace("道具配置不存在:", tItem, oRole:GetID())

            elseif tPropConf.nType ~= gtPropType.eCurr then
                local bExist = false
                for _, tTmpItem in ipairs(tPropList) do
                    if tTmpItem and tTmpItem[2]==tItem[2] and (tTmpItem[4] or false)==(tItem[4] or false) then
                        tTmpItem[3] = tTmpItem[3] + tItem[3]
                        bExist = true
                        break
                    end
                end
                if not bExist then
                    table.insert(tPropList, tItem)
                end

            end

        --法宝不能叠加
        elseif tItem[1] == gtItemType.eFaBao then
            table.insert(tFaBaoList, tItem)

        end
    end
    for _, tItem in pairs(tTempList) do
        _ItemCheckCount(tItem)
    end

    --检测背包是否放的下
    local nBagFreeGrid = oRole.m_oKnapsack:GetFreeGridCount()
    if nBagFreeGrid < #tTarnsList then
         oRole:Tips("背包已满，请先清理背包")
         return false
    end
    --例如，邮件中有三件不同装备，背包只有一个格子，此时针对三件装备分别检查，都符合，但其实背包是放不下的
    -- for _, tItem in ipairs(tPropList) do 
    --     if oRole.m_oKnapsack:GetRemainCapacity(tItem[2], tItem[4] or false) < tItem[3] then
    --          oRole:Tips("背包已满，请先清理背包")
    --          return false
    --     end
    -- end
    local nNewGridOccupied = 0
    for _, tItem in ipairs(tPropList) do 
        local nOccupiedNum = oRole.m_oKnapsack:CheckNewGridOccupy(tItem[2], tItem[3], tItem[4] and true or false)
        nNewGridOccupied = nNewGridOccupied + nOccupiedNum
    end
    if nNewGridOccupied + #tTarnsList > nBagFreeGrid then 
        oRole:Tips("背包已满，请先清理背包")
        return false 
    end
    if oRole.m_oFaBao:GetOverNum() < #tFaBaoList then
        return oRole:Tips("法宝背包已满,请先清理包裹")
    end

    --帮派神诏需要特殊处理(已屏蔽)
    -- for _, tTrans in ipairs(tTarnsList) do
    --     local tPropConf = ctPropConf[tTrans.m_nID] 
    --     local cClass = gtPropClass[tPropConf.nType]
    --     local nAddNum = cClass:CheckCanAddNum(oRole, tTrans.m_nID, tTrans.m_nFold, true)
    --     if nAddNum <= 0 then
    --         return false
    --     end
    -- end
    -- for _, tItem in ipairs(tPropList) do
    --     local tPropConf = ctPropConf[tItem[2]] 
    --     local cClass = gtPropClass[tPropConf.nType]
    --     local nAddNum = cClass:CheckCanAddNum(oRole, tItem[2], tItem[3], true)
    --     if nAddNum <= 0 then
    --         return false
    --     end
    -- end

    --加到背包
    local tList = {}
    local tTransList = {} --传送物品
    local tNormalList = {} --普通物品
    for _, tItem in ipairs(tItemList) do
        if tItem.m_nID then
            table.insert(tTransList, tItem)
            table.insert(tList, {nType=gtItemType.eProp, nID=tItem.m_nID, nNum=tItem.m_nFold})
        else
            table.insert(tNormalList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3], bBind=tItem[4], tPropExt=tItem[5]})
            table.insert(tList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
        end
    end
    if #tTransList > 0 then
        oRole:TransferItemList(tTransList, "邮件领取", bNotSync)
    end
    if #tNormalList > 0 then
        oRole:AddItemList(tNormalList, "邮件领取", bNotSync)
    end
    return true, tList
end

--设置组队跟随(WGLOBAL)
--@nMixObjID 被跟随者 对象类型+ID : 对象类型<<32 | 对象ID
--@tFollowList 跟随者 对象类型+ID列表,可以是空表(解除所有跟随者); 接口功能: 先解除所有旧跟随者,再设置新的跟随者
function Srv2Srv.SetFollowReq(nSrcServer, nSrcService, nTarSession, nMixObjID, tFollowList)
    tFollowList = tFollowList or {}
    print("跟随带队:", nMixObjID>>32, nMixObjID&0xFFFFFFFF)
    print("跟随者:")
    for _, nTmpObjMixID in ipairs(tFollowList) do
        print(nTmpObjMixID>>32, nTmpObjMixID&0xFFFFFFFF)
    end
    goNativeDupMgr:SetFollow(nMixObjID, tFollowList)
end

--师徒任务战斗
function Srv2Srv.MentorshipTaskBattleReq(nSrcServer, nSrcService, nTarSession, nRoleID, tData)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    if oRole:IsInBattle() then 
        return 
    end
    if not oRole:CheckTeamOp() then 
        return oRole:Tips("请先暂离队伍")
    end
    local nTaskID = tData.nTaskID
    local nTimeStamp = tData.nTimeStamp
    local nSrcService = tData.nSrcService
    local tAsyncData = {} --在玩家战斗结束时，根据此数据发起结算
    tAsyncData.nTaskID = nTaskID
    tAsyncData.nTimeStamp = nTimeStamp
    tAsyncData.nSrcService = nSrcService
	local tExtData = {}
	tExtData.bMentorshipTaskBattle = true
    tExtData.tAsyncData = tAsyncData

    local tTaskConf = ctMentorshipTaskConf[nTaskID]
    assert(tTaskConf and tTaskConf.nBattleMonster > 0)
    local oMonster = goMonsterMgr:CreateInvisibleMonster(tTaskConf.nBattleMonster)
    oRole:PVE(oMonster, tExtData)
end

--更新角色称号数据
--tData{nOpType=, nConfID=, tParam=, nSubKey=}
function Srv2Srv.AppellationUpdateReq(nSrcServer, nSrcService, nTarSession, nRoleID, nServerID, tData)
    return CRole:AppellationUpdateReq(nServerID, nRoleID, tData)
end

--家园属性同步
function Srv2Srv.SyncHouseBattleAttr(nSrcServer, nSrcService, nTarSession,nRoleID,tHouseBattleAttr)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    oRole:SetHouseBattleAttr(tHouseBattleAttr)
end

--家园购买礼物
function Srv2Srv.HouseGiveGiftReq(nSrcServer, nSrcService, nTarSession,nRoleID,nPropID,nAmount,bMoneyAdd)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    return oRole:HouseGiveGiftReq(nRoleID,nPropID,nAmount,bMoneyAdd)
end

--查询角色的副本信息[WGLOBAL]
function Srv2Srv.GetRoleCurrDupInfoReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>获取角色所在副本信息")
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then
        return LuaTrace("GetRoleCurrDupInfoReq角色不存在", nRoleID)
    end
    local nPosX, nPosY = oRole:GetPos()
    local tDupConf = oRole:GetDupConf()
    print(tDupConf)
    local nBattleDupType = tDupConf.nBattleType
    return oRole:GetDupMixID(), oRole:GetLine(), nPosX, nPosY, nBattleDupType
end

function Srv2Srv.UpdateUnionAppellation(nSrcServer, nSrcService, nTarSession, nRoleID, nAppeConfID, tParam, nSubKey)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then  --不写离线数据，帮会职务，可能在玩家非在线期间，变动频繁，上线会更新一次
        return print("UpdateUnionAppellation角色不存在", nRoleID)
    end
    oRole.m_oAppellation:UpdateUnionAppellation(nAppeConfID, tParam, nSubKey)
end

function Srv2Srv.UpdateArenaAppellation(nSrcServer, nSrcService, nTarSession, nRoleID, nAppeConfID, tParam, nSubKey)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then
        return print("UpdateArenaAppellation角色不存在", nRoleID)
    end
    oRole.m_oAppellation:UpdateArenaAppellation(nAppeConfID, tParam, nSubKey)
end

--创建机器人
function Srv2Srv.CreateRobotReq(nSrcServer, nSrcService, nSession, nServer, nRobotID, nRoleID, nRobotType, nDupMixID, tParam)
	return goPlayerMgr:CreateRobotReq(nServer, nRobotID, nRoleID, nRobotType, nDupMixID, tParam)
end


--创建机器人
function Srv2Srv.CreateSysEquCacheReq(nSrcServer, nSrcService, nSession, tPropIDList, nMirrorID)
    local tEquCache = {}
    -- --创建一个临时机器人，利用机器人生成装备
    -- local nRobotDupID = 0
    -- for nDupID, tDupConf in pairs(ctDupConf) do 
    --     if tDupConf.nType == CDupBase.tType.eCity then 
    --         nRobotDupID == nDupID
    --         break 
    --     end
    -- end
    -- local tRobotParam = {}
    -- local oRobot = CRobot:new(gnServerID, 1, 1, gtRobotType.eTeam, nRobotDupID, tRobotParam)
    local oRole = goPlayerMgr:GetRoleByID(nMirrorID)
    if not oRole then 
        oRole = CTempRole:new(gnServerID, nMirrorID)
        assert(oRole) 
    end
    local tPropExt = {nQuality = gtQualityColor.eWhite}
    for _, nEquID in pairs(tPropIDList) do 
        local oTempEqu = oRole.m_oKnapsack:CreateProp(nEquID, 1, false, tPropExt)
        oTempEqu:AddNum(1)
        local tEquData = oTempEqu:SaveData()
        tEquCache[nEquID] = tEquData
    end
    if oRole:IsTempRole() then 
        oRole:Release() 
    end
	return tEquCache
end

--社会关系喊话属性查询
function Srv2Srv.RelationInviteInfoQueryReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    local tData = {}
    tData.nMountsID = oRole:GetFlyMountID() or 0
    tData.nWingID = oRole:GetWingID() or 0
    tData.nHaloID = oRole:GetHaloID() or 0
    local tPetInfo = {}

    local oPet = oRole.m_oPet:GetCombatPet()
    tPetInfo.nPetID = oPet and oPet.nId or 0
    tPetInfo.nPetPos = oRole.m_oPet:PetCombat() or 0
    tData.tPetInfo = tPetInfo
    return tData
end

--查询玩家总充值金额
function Srv2Srv.QueryRoleTotalRechargeReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    local nTotalRechargeRMB = oRole.m_oVIP:GetTotalRecharge()
    return nTotalRechargeRMB
end

--心跳
function CltCmdProc.KeepAlive(nCmd, nSrcServer, nSrcService, nTarSession, nRoleID, nLastKeepAliveTime)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then
        return
    end
    oRole:UpdateLastKeepAliveTime(nLastKeepAliveTime)
end
