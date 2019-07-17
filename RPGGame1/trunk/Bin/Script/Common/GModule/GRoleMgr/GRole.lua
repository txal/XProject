--GLOBAL角色对象(GlobalSrever和WGlobalServer共用)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGRole:Ctor()
    self.m_nID = 0
    self.m_sName = ""
    self.m_nConfID = 0
    self.m_nAccountID = 0
    self.m_sAccountName = ""
    self.m_nCreateTime = 0
    self.m_nServer = 0  --角色所属服务器

    self.m_nVIP = 0
    self.m_nLevel = 0
    self.m_nLastWorldTalkTime = 0   --世界聊天时间
    self.m_nOnlineTime = 0  --上线时间 
    self.m_nOfflineTime = 0 --下线时间 
    self.m_nDupMixID = 0    --当前所在的副本ID
    self.m_nPower = 0           --战力
    self.m_nColligatePower = 0  --综合战力
    self.m_nUnionID = 0
    self.m_nSource = 0


    self.m_nActState = gtRoleActState.eNormal
    self.m_nInviteRoleID = 0   --邀请者角色ID
    self.m_oToday = CToday:new(self.m_nID)
    self.m_tShapeData = {}

    ---->>不保存
    self.m_nSession = 0         --当前会话ID
    self.m_nGateway = 0         --所在网关
    self.m_nBattleID = 0        --战斗ID
    self.m_tBTRes = nil         --战斗结束数据
    self.m_nBattleEndTime = 0   --上次战斗结束时间
    self.m_bRelease = true      --逻辑服中的对象是否已释放(默认释放)
    self.m_nTestMan = 0
    ---<<

    self.m_tOpenSysMap = {}
    self.m_nSrcID = 0
end

--上线时初始化
function CGRole:Init(tData)
    for sKey, xVal in pairs(tData) do
        self[sKey] = xVal
        if sKey == "m_nInviteRoleID" and xVal > 0 then
            self:OnRoleInvite()
        end
    end
end

function CGRole:LoadData(tData)
    for sKey, xVal in pairs(tData) do
        if sKey == "m_oToday" then
            self.m_oToday:LoadData(xVal)
        else
            self[sKey] = xVal
        end
    end

end

function CGRole:SaveData()
    local tData = {}
    tData.m_nID = self.m_nID
    tData.m_sName = self.m_sName
    tData.m_nConfID = self.m_nConfID
    tData.m_nAccountID = self.m_nAccountID
    tData.m_sAccountName = self.m_sAccountName
    tData.m_nCreateTime = self.m_nCreateTime
    tData.m_nServer = self.m_nServer
    tData.m_nLevel = self.m_nLevel
    tData.m_nVIP = self.m_nVIP
    tData.m_nLastWorldTalkTime = self.m_nLastWorldTalkTime
    tData.m_nOnlineTime = self.m_nOnlineTime
    tData.m_nOfflineTime = self.m_nOfflineTime
    tData.m_nDupMixID = self.m_nDupMixID
    tData.m_nPower = self.m_nPower
    tData.m_oToday = self.m_oToday:SaveData()
    tData.m_nUnionID = self.m_nUnionID
    tData.m_tShapeData = self.m_tShapeData
    tData.m_nSource = self.m_nSource
    tData.m_tOpenSysMap = self.m_tOpenSysMap
    tData.m_nColligatePower = self.m_nColligatePower
    return tData
end

--属性更新
function CGRole:UpdateReq(tData)
    for sKey, xVal in pairs(tData) do
        local xOldVal = self[sKey]
        self[sKey] = xVal

        if xOldVal ~= xVal then
            self:MarkDirty(true)
        end

        if sKey == "m_nDupMixID" then
            self:OnEnterScene()
        elseif sKey == "m_bRelease" and xVal then --当前不会被调用到
            self:OnRoleRelease()
        elseif sKey == "m_nLevel" and xOldVal ~= xVal then
            self:OnLevelChange()
        elseif sKey == "m_nPower" and xOldVal ~= xVal then
            self:OnPowerChange(xOldVal, xVal)
        elseif sKey == "m_sName" and xOldVal ~= xVal then 
            self:OnNameChange(xOldVal)
        elseif sKey == "m_nUnionID" and xOldVal ~= xVal then
            self:OnUnionChange(xOldVal, xVal)
        elseif sKey == "m_nColligatePower" and xOldVal ~= xVal then
            self:OnColligatePowerChange(xOldVal, xVal)
        elseif sKey == "m_nBattleID" and xOldVal ~= xVal then
            if xVal == 0 then
                self:OnBattleEnd(tData.m_tBTRes)
            else
                self:OnBattleBegin()
            end
        end
    end
    if goHouseMgr and not self:IsRobot() then
        goHouseMgr:UpdateReq(self:GetID(),tData)
    end
end

--更新角色称号数据
--tData{nOpType=, nConfID=, tParam=, nSubKey=, sReason=, tExtData=, }
function CGRole:AppellationUpdate(tData, fnCallback)
    assert(tData, "参数错误")

    local tParam = tData.tParam
    if tParam then 
        assert(type(tParam) == "table")
    end
    --如果目标逻辑服异常，会导致更新数据失败，包括离线数据
    --内部再加一层回调，如果目标服务器处理失败，做一下后续处理
    local fnUpdateCallback = function(bRet)
        if not bRet then 
            local nServerID = self:GetServer()
            LuaTrace("CGRole:AppellationUpdate***数据更新异常", nServerID, self:GetID(), tData)
        end
        if fnCallback then 
            fnCallback(bRet)
        end
    end
    Network.oRemoteCall:CallWait("AppellationUpdateReq", fnUpdateCallback, self:GetStayServer(), 
            self:GetLogic(), self:GetSession(), self:GetID(), self:GetServer(), tData)
end

--添加称谓
function CGRole:AddAppellation(nConfID, tParam, nSubKey, sReason, tExtData, fnCallback)
    local tAppeData = {}
    tAppeData.nOpType = gtAppellationOpType.eAdd
    tAppeData.nConfID = nConfID
    tAppeData.tParam = tParam or {}
    tAppeData.nSubKey = nSubKey or 0
    tAppeData.sReason = sReason
    tAppeData.tExtData = tExtData
    self:AppellationUpdate(tAppeData, fnCallback)
end

--更新称谓属性
function CGRole:UpdateAppellation(nConfID, tParam, nSubKey, fnCallback)
    local tAppeData = {}
    tAppeData.nOpType = gtAppellationOpType.eUpdate
    tAppeData.nConfID = nConfID
    tAppeData.tParam = tParam or {}
    tAppeData.nSubKey = nSubKey or 0
    self:AppellationUpdate(tAppeData, fnCallback)
end

--删除称谓
function CGRole:RemoveAppellation(nConfID, nSubKey, sReason, fnCallback)
    local tAppeData = {}
    tAppeData.nOpType = gtAppellationOpType.eRemove
    tAppeData.nConfID = nConfID
    tAppeData.tParam = {}
    tAppeData.nSubKey = nSubKey or 0
    tAppeData.sReason = sReason
    self:AppellationUpdate(tAppeData, fnCallback)
end

function CGRole:MarkDirty(bDiry)
    goGPlayerMgr:MarkDirty(self:GetID(), bDiry)
end

function CGRole:IsRobot() return false end
function CGRole:GetID() return self.m_nID end
function CGRole:GetSrcID() return self.m_nSrcID end
function CGRole:GetName() return self.m_sName end
function CGRole:GetFormattedName()
    local tConf = ctTalkConf["rolename"]
    if not tConf then return end
    return string.format(tConf.sContent, self.m_sName)
end
function CGRole:GetConfID() return self.m_nConfID end
function CGRole:GetConf() return ctRoleInitConf[self.m_nConfID] end
function CGRole:GetSchool() return self:GetConf().nSchool end
function CGRole:GetGender() return self:GetConf().nGender end
function CGRole:GetHeader() return self:GetConf().sHeader end
function CGRole:GetModel() return self:GetConf().sModel end
function CGRole:IsOnline() return self.m_nSession>0 end
function CGRole:GetServer() return self.m_nServer end --角色所属服务器ID
function CGRole:GetSession() return self.m_nSession end
function CGRole:GetGateway() return self.m_nGateway end
function CGRole:GetAccountID() return self.m_nAccountID end
function CGRole:GetAccountName() return self.m_sAccountName end
function CGRole:GetCreateTime() return self.m_nCreateTime end
function CGRole:GetVIP() return self.m_nVIP end
function CGRole:GetLevel() return self.m_nLevel end
function CGRole:IsInBattle() return self.m_nBattleID>0 end
function CGRole:GetBattleID() return self.m_nBattleID end
function CGRole:GetDupMixID() return self.m_nDupMixID end
function CGRole:GetDupConf() return ctDupConf[CUtil:GetDupID(self:GetDupMixID())] end
function CGRole:IsReleased() return self.m_bRelease end
function CGRole:GetLastWorldTalkTime() return self.m_nLastWorldTalkTime end
function CGRole:SetLastWorldTalkTime(nTime)
    self.m_nLastWorldTalkTime = nTime
    self:MarkDirty(true)
end
function CGRole:GetOnlineTime() return self.m_nOnlineTime end
function CGRole:GetOfflineTime() return self.m_nOfflineTime end
function CGRole:GetMixObjID() return (gtGDef.tObjType.eRole<<32|self.m_nID) end
function CGRole:SetActState(nState) 
    self.m_nActState = nState 
    if self:IsInMarriageActState() or self:IsInPalanquinActState() then 
        self:OnRoleMarriageActStateEvent()
    end
end

function CGRole:IsInMarriageActState() 
    local nState = self:GetActState()
    if nState == gtRoleActState.eWeddingApply 
    or nState == gtRoleActState.eWedding then
        return true
    end
    return false
end

function CGRole:IsInPalanquinActState() 
    local nState = self:GetActState()
    if nState == gtRoleActState.ePalanquinApply 
    or nState == gtRoleActState.ePalanquinParade then
        return true
    end
    return false
end

function CGRole:GetActState() return self.m_nActState end
function CGRole:GetPower() return self.m_nPower end
function CGRole:GetLastBattleEndTime() return self.m_nBattleEndTime end
function CGRole:GetUnionID() return self.m_nUnionID end
function CGRole:GetShapeData() return self.m_tShapeData end

function CGRole:GetSource() return self.m_nSource end
function CGRole:IsAndroid() return self.m_nSource // 100 == 1 end
function CGRole:IsIOS() return self.m_nSource // 100 == 2 end

function CGRole:IsSysOpen(nSysID, bTips) 
    local tConf = ctSysOpenConf[nSysID] 
	if not tConf then
		return false 
	end
    local nSysData = self.m_tOpenSysMap[nSysID]
    if nSysData and nSysData == gtSysOpenFlag.eOpen then 
        return true 
    end
    if bTips and tConf.sTips ~= "0" then 
        self:Tips(tConf.sTips)
    end
    return false
end

--取未开放提示
function CGRole:SysOpenTips(nSysID)
    local tConf = ctSysOpenConf[nSysID] 
    if tConf and tConf.sTips ~= "0" then
        return tConf.sTips
    end
    return "系统未开启"
end

--所在逻辑服
function CGRole:GetLogic()
    local nDupID = CUtil:GetDupID(self.m_nDupMixID)
    local tConf = ctDupConf[nDupID]
    return (tConf and tConf.nLogic or 0)
end

--是否在世界服(配置中约定世界逻辑服ID>=100)
function CGRole:IsInWorldServer()
    local nLogic = self:GetLogic()
    return (nLogic >= 100)
end

--取目前所在的服务器ID
function CGRole:GetStayServer()
    if self:IsInWorldServer() then
        return gnWorldServerID
    end
    return self:GetServer()
end

--进入场景
function CGRole:OnEnterScene()
    if goTeamMgr then
        goTeamMgr:OnEnterScene(self)
    end
    if goYaoShouTuXiMgr then
        goYaoShouTuXiMgr:OnEnterScene(self)
    end
end

--玩家和机器人通用online
function CGRole:CommOnline()
    if goTeamMgr then
        goTeamMgr:Online(self)
    end
    if goGRobotMgr then 
        goGRobotMgr:Online(self)
    end
end

--上线
function CGRole:Online()
    self:CommOnline()
    if goMarketMgr then
        goMarketMgr:OnRoleOnline(self)
    end
    if goMailMgr then
        goMailMgr:Online(self)
    end
    if goFriendMgr then
        goFriendMgr:Online(self)
    end
    if goUnionMgr then
        goUnionMgr:Online(self)
    end
    if goMarriageMgr then
        goMarriageMgr:OnRoleOnline(self)
    end
    if goBrotherRelationMgr then 
        goBrotherRelationMgr:OnRoleOnline(self)
    end
    if goLoverRelationMgr then 
        goLoverRelationMgr:OnRoleOnline(self)
    end
    if goMentorshipMgr then 
        goMentorshipMgr:OnRoleOnline(self)
    end
    if goInvite then
        goInvite:Online(self)
    end
    if goHouseMgr then
        goHouseMgr:Online(self:GetID())
    end
    if goHallFame then
        goHallFame:Online(self)
    end
    if goTalk then
        goTalk:Online(self)
    end
    if goRankingMgr then
        goRankingMgr:Online(self)
    end
    if goCGiftMgr then 
        goCGiftMgr:Online(self)
    end
    if goHDMgr then
        goHDMgr:Online(self)
    end
    if goExchangeActivityMgr then
        goExchangeActivityMgr:Online(self)
    end
    if goArenaMgr then 
        goArenaMgr:Online(self)
    end
    if goGPVPActivityNpcMgr then 
        goGPVPActivityNpcMgr:Online(self)
    end
    
    if goGPVEActivityNpcMgr then
        goGPVEActivityNpcMgr:Online(self)
    end
end

--离线 --即逻辑服断开连接
function CGRole:Offline()
    self.m_nSession = 0
    if goTeamMgr then
        goTeamMgr:Offline(self)
    end
    if goMarketMgr then
        goMarketMgr:OnRoleOffline(self:GetID())
    end
    if goHouseMgr then
        goHouseMgr:Offline(self:GetID())
    end
    if goGRobotMgr then 
        goGRobotMgr:Offline(self)
    end
    if goGuaJiTimerMgr then
        goGuaJiTimerMgr:Offline(self:GetID())
    end
    if goMarriageMgr then
        goMarriageMgr:OnRoleOffline(self)
    end
    if goBrotherRelationMgr then 
        goBrotherRelationMgr:OnRoleOffline(self)
    end
    if goLoverRelationMgr then 
        goLoverRelationMgr:OnRoleOffline(self)
    end
    if goMentorshipMgr then 
        goMentorshipMgr:OnRoleOffline(self)
    end
end

--角色对象释放
function CGRole:OnRoleRelease()
    self.m_bRelease = true
    if goTeamMgr then
        goTeamMgr:OnRoleRelease(self)
    end
    if goGRobotMgr then 
        goGRobotMgr:OnRoleRelease(self)
    end
    if goGuaJiTimerMgr then
        goGuaJiTimerMgr:OnRoleRelease(self)
    end
end

--取当前离线时长
function CGRole:GetOfflineKeepTime()
    if self:IsOnline() then
        return 0
    end
    return os.time()-self.m_nOfflineTime
end

--发送消息
function CGRole:SendMsg(sCmd, tMsg, nServer, nSession)
    nServer = nServer or self:GetServer()
    nSession = nSession or self:GetSession()
    assert(nServer < gnWorldServerID, "服务器ID错了")
    if nServer > 0 and nSession > 0 then
        Network.PBSrv2Clt(sCmd, nServer, nSession, tMsg)
    end
end

--Tips
function CGRole:Tips(sCont, nServer, nSession)
    nServer = nServer or self.m_nServer
    nSession = nSession or self.m_nSession
    assert(nServer < gnWorldServerID, "服务器ID错了")
    if nServer > 0 and nSession > 0 then
        Network.PBSrv2Clt("TipsMsgRet", nServer, nSession, {sCont=sCont})
    end
end

--背包剩余可容纳某道具的数量
function CGRole:KnapsackRemainCapacity(nPropID, bBind, fnCallback, nBagType)
    assert(nPropID and fnCallback and nBagType, "参数错误")
    bBind = bBind or false
    if nBagType == gtItemType.eFaBao then
        Network.oRemoteCall:CallWait("FaBaoKnapsackRemainCapacityReq", fnCallback, self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID(), nPropID)
    else
         Network.oRemoteCall:CallWait("KnapsackRemainCapacityReq", fnCallback, self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID(), nPropID, bBind)
    end
end

--取物品数量
function CGRole:ItemCount(nType, nID, fnCallback)
    assert(fnCallback, "参数错误")
    Network.oRemoteCall:CallWait("RoleItemCountReq", fnCallback, self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID(), nType, nID)
end

--取多个物品数量
--@tItemList {{nType=0, nID=0}, ...}
--@return {{nType=0, nID=0, nNum=0}, ...}
function  CGRole:ItemCountList(tItemList, fnCallback)
    assert(#tItemList > 0 and fnCallback, "参数错误")
    for _, tItem in ipairs(tItemList) do
        assert(tItem.nID > 0, "物品数量错误")
    end
    Network.oRemoteCall:CallWait("RoleItemCountListReq", fnCallback, self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID(), tItemList)
end

--检查物品
--@tItemList {{nType=0, nID=0, nNum=0}, ...}
--@return retFlag, trueItemList, falseItemList
function CGRole:CheckItemCount(tItemList, fnCallback)
    assert(#tItemList > 0 and fnCallback, "参数错误")
    for _, tItem in ipairs(tItemList) do
        assert(tItem.nID > 0 and tItem.nNum > 0, "物品数据错误")
    end
    Network.oRemoteCall:CallWait("RoleCheckItemCountReq", fnCallback, self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID(), tItemList)
end

--添加物品
--@tItemList {{nType=0,nID=0,nNum=0,bBind=false,tPropExt={}},...}
function CGRole:AddItem(tItemList, sReason, fnCallback)
    assert(#tItemList>0 and sReason, "参数错误")

    for _, tItem in ipairs(tItemList) do
        assert(tItem.nNum > 0, "物品数量错误")
    end
    local function _fnProxyCallback(bRet)
        if not bRet then
            goLogger:EventLog(gtEvent.eLostItem, self, cjson_raw.encode(tItemList), sReason)
            LuaTrace("发放物品失败:", self:GetID(), self:GetName(), sReason, tItemList)
        end --超时或失败
        if fnCallback then fnCallback(bRet) end
    end
    Network.oRemoteCall:CallWait("RoleAddItemReq", _fnProxyCallback, self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID(), tItemList, sReason)
end

function CGRole:AddUnionGiftBox(nType, nNum) 
    local nServerID = self:GetServer()
    local nServiceID = goServerMgr:GetGlobalService(nServerID, 20) 
    --不适用本地缓存帮会数据，防止出错导致数据不一致，导致发放奖励不正确
    if gnServerID == nServerID then 
        Srv2Srv.AddUnionGiftBoxCntByRole(nServerID, nServiceID, 0, self:GetID(), nType, nNum) 
    else
        Network.oRemoteCall:Call("AddUnionGiftBoxCntByRole", nServerID, nServiceID,0, self:GetID(), nType, nNum) 
    end

end

--扣除物品
--@tItemList {{nType=0,nID=0,nNum=0},...}
--@return true成功, 否则失败
function CGRole:SubItem(tItemList, sReason, fnCallback)
    assert(#tItemList>0 and sReason and fnCallback, "参数错误")
    for _, tItem in ipairs(tItemList) do
        assert(tItem.nNum>0, "物品数量错误")
    end
    Network.oRemoteCall:CallWait("RoleSubItemReq", fnCallback, self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID(), tItemList, sReason)
end

--扣除指定格子道具
--@tItemList {{nGrid=0,nID=0,nNum=0},...}
function CGRole:SubPropByGrid(tItemList, sReason, fnCallback, nBagType)
    assert(#tItemList>0 and sReason and fnCallback and nBagType, "参数错误")
    for _, tItem in ipairs(tItemList) do
        assert(tItem.nNum>0, "物品数量错误")
    end
    if nBagType == gtItemType.eFaBao then
        Network.oRemoteCall:CallWait("RoleSubFaBaoByGridReq", fnCallback, self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID(), tItemList, sReason)
    else
         Network.oRemoteCall:CallWait("RoleSubPropByGridReq", fnCallback, self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID(), tItemList, sReason)
    end
   
end

--扣除物品，如果不足则提示
function CGRole:SubItemShowNotEnoughTips(tItemList, sReason, bFirstBreak, bNum, fnCallback)
    assert(#tItemList>0 and sReason and fnCallback, "参数错误")
    for _, tItem in ipairs(tItemList) do
        assert(tItem.nNum>0, "物品数量错误")
    end
    Network.oRemoteCall:CallWait("RoleSubItemShowNotEnoughTipsReq", fnCallback, self:GetStayServer(), self:GetLogic(), 
        self:GetSession(), self:GetID(), tItemList, sReason, bFirstBreak, bNum)
end

--获取并扣除背包指定格子道具
-- {{nID, nGrid, nNum}, ...}
function CGRole:GetPropDataWithSub(tItemList, sReason, bUnbindLimit, fnCallback)
    assert(#tItemList>0 and sReason and bUnbindLimit and fnCallback, "参数错误")
    for _, tItem in ipairs(tItemList) do
        assert(tItem.nNum>0, "物品数量错误")
    end
    Network.oRemoteCall:CallWait("RoleGetPropDataWithSubReq", fnCallback, self:GetStayServer(), self:GetLogic(), 
        self:GetSession(), self:GetID(), tItemList, sReason, bUnbindLimit)
end

--取道具数据
function CGRole:GetPropData(nGrid, fnCallback, nBagType)
    assert(nGrid and fnCallback and nBagType, "参数错误")
    if nBagType == gtItemType.eFaBao then
         Network.oRemoteCall:CallWait("FaBaoItemDataReq", fnCallback, self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID(), nGrid)
    elseif nBagType == gtItemType.eProp then
         Network.oRemoteCall:CallWait("KnapsackItemDataReq", fnCallback, self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID(), nGrid)
    end
end

--取多个道具数据
function CGRole:GetPropDataList(tList, fnCallback)
     assert(tList and fnCallback, "参数错误")
    Network.oRemoteCall:CallWait("KnapsackItemListDataReq", fnCallback, self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID(), tList)
end


--通过ID取所有道具数据
function CGRole:GetPropListDataReq(nPropID, fnCallback, nBagType)
    assert(nPropID and fnCallback and nBagType, "参数错误")
    if nBagType == gtItemType.eFaBao then
         Network.oRemoteCall:CallWait("FaBaoItemListDataReq", fnCallback, self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID(), nPropID)
    elseif nBagType == gtItemType.eProp then
         Network.oRemoteCall:CallWait("KnapsackPropListDataReq", fnCallback, self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID(), nPropID)
    end
end

function CGRole:TransferItemList(tPropDataList, sReason, fnCallback)
    assert(#tPropDataList > 0 and sReason, "参数错误")
    for _, tPropData in ipairs(tPropDataList) do
        assert(tPropData.m_nFold > 0, "物品数量错误")
    end
    local function _fnProxyCallback(bRet)
        if not bRet then goLogger:EventLog(gtEvent.eLostItem, self, cjson_raw.encode(tPropDataList), sReason) end --超时或失败
        if fnCallback then fnCallback(bRet) end
    end
    Network.oRemoteCall:CallWait("RoleTransferItemListReq", _fnProxyCallback, self:GetStayServer(), 
        self:GetLogic(), self:GetSession(), self:GetID(), tPropDataList, sReason)
end 

function CGRole:SendPropDetailInfo(tPropData)
    Network.oRemoteCall:Call("RolePropDetailInfoReq", self:GetStayServer(), 
            self:GetLogic(), self:GetSession(), self:GetID(), tPropData)
end

--取聊天标识
function CGRole:GetTalkIdent()
    local tTalkIdent = {}
    tTalkIdent.nID = self:GetID()
    tTalkIdent.sName = self:GetName()
    tTalkIdent.sHeader = self:GetHeader()
    tTalkIdent.nLevel = self:GetLevel()
    tTalkIdent.nUnionPos = 0
    tTalkIdent.nSchool = self:GetSchool()
    tTalkIdent.nGender = self:GetGender()
    return tTalkIdent
end

--战斗开始
function CGRole:OnBattleBegin()
    if goTeamMgr and goTeamMgr.OnBattleBegin then
        goTeamMgr:OnBattleBegin(self)
    end
end

--战斗结束
function CGRole:OnBattleEnd(tBTRes)
    self.m_nBattleEndTime = os.time()
    if goTeamMgr then
        goTeamMgr:OnBattleEnd(self, tBTRes)
    end
    if goFriendMgr and not self:IsRobot() then 
        goFriendMgr:OnBattleEnd(self:GetID(), tBTRes) 
    end
end

--取背包空闲格子数
function CGRole:GetKnapsackFreeGridCount(fnCallback)
    Network.oRemoteCall:CallWait("KnapsackFreeGridCountReq", fnCallback, self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID())
end

--发放邮件奖励
function CGRole:SendMailAward(tItemList, fnCallback, bNotSync)
    Network.oRemoteCall:CallWait("SendMailAwardReq", fnCallback, self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID(), tItemList, bNotSync)
end

--给玩家发送系统邮件
function CGRole:SendSysMail(sTitle, sContent, tItemList, fnCallback)
    assert(sTitle and sContent and tItemList, "参数错误")
    local nServerID = self:GetServer()
    local nService = goServerMgr:GetGlobalService(nServerID, 20)
    if fnCallback then
        Network.oRemoteCall:CallWait("SendMailReq", fnCallback, nServerID, nService, 0, sTitle, sContent, tItemList, self:GetID())
    else
        Network.oRemoteCall:Call("SendMailReq", nServerID, nService, 0, sTitle, sContent, tItemList, self:GetID())
    end
end

--角色信息请求
function CGRole:RoleInfoReq(nTarRoleID)
    local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
    if not oTarRole then 
        return 
    end
    local nTarServer = oTarRole:GetServer()

    Network.oRemoteCall:CallWait("RoleUnionInfoReq", function(tUnion)

        local tMsg = {}
        tMsg.nID = oTarRole:GetID()
        tMsg.sName = oTarRole:GetName()
        tMsg.sHeader = oTarRole:GetModel()
        tMsg.nLevel = oTarRole:GetLevel()
        tMsg.nGender = oTarRole:GetGender()
        tMsg.nSchool = oTarRole:GetSchool()
        tMsg.sServerName = goServerMgr:GetServerName(oTarRole:GetServer())
        tMsg.sTitleName = ""
        tMsg.sUnionName = tUnion and tUnion.sUnionName or ""
        tMsg.nUnionID = tUnion and tUnion.nUnionID or 0
        tMsg.nHoney = 0
        tMsg.sRelation = ""
        tMsg.bStranger = false
        tMsg.nTeamID = 0
        tMsg.nTeamMembers = 0
        tMsg.bFriend = false

        if goFriendMgr:IsFriend(self:GetID(), oTarRole:GetID()) then
            local oFriend = goFriendMgr:GetFriend(self:GetID(), oTarRole:GetID())
            tMsg.nHoney = oFriend:GetDegrees()
            tMsg.sRelation = "好友"
            tMsg.bFriend = true
        end
        if goFriendMgr:GetStranger(self:GetID(), oTarRole:GetID()) then
            tMsg.bStranger = true
        end
        local oTeam = goTeamMgr:GetTeamByRoleID(oTarRole:GetID())
        if oTeam then
            tMsg.nTeamID = oTeam:GetID()
            tMsg.nTeamMembers = oTeam:GetMembers()
        end

        if not self:IsRobot() then 
            tMsg.tMarriage = goMarriageMgr:GetRoleInfoMarriageInfo(nTarRoleID)
            tMsg.tBrother = goBrotherRelationMgr:GetRoleInfoBrotherInfo(nTarRoleID)
            tMsg.tMentorship = goMentorshipMgr:GetRoleInfoMentorshipInfo(nTarRoleID)
        else
            tMsg.tMarriage = {}
            tMsg.tBrother = {tBrotherList = {}, }
            tMsg.tMentorship = {tApprentList = {}, }
        end

        self:SendMsg("RoleInfoRet", tMsg)

    end, nTarServer, goServerMgr:GetGlobalService(nTarServer, 20), 0, nTarRoleID)
end

--取帮贡
function CGRole:GetUnionContri()
    local oUnionRole = goUnionMgr:GetUnionRole(self:GetID())
    if not oUnionRole then return 0 end
    return oUnionRole:GetUnionContri()
end

--增加/扣除帮贡
function CGRole:AddUnionContri(nNum, sReason)
    assert(sReason, "请写原因")
    local oUnionRole = goUnionMgr:GetUnionRole(self:GetID())
    if not oUnionRole then
        return self:Tips("请先加入帮派")
    end
    local nUnionContri = oUnionRole:AddUnionContri(nNum, sReason)
    self:SyncCurrency(gtCurrType.eUnionContri, nUnionContri)
    self:ChangeUnionContri()
end

--增加帮派经验
function CGRole:AddUnionExp(nNum, sReason)
    assert(sReason, "请写原因")
    local oUnion = goUnionMgr:GetUnionByRoleID(self:GetID())
    if not oUnion then 
        return self:Tips("请先加入帮派")
    end
    oUnion:AddExp(nNum, sReason, self)
end

--获取帮派名
function CGRole:GetUnionName()
    local oUnion = goUnionMgr:GetUnionByRoleID(self:GetID())
    if not oUnion then 
        return self:Tips("请先加入帮派")
    end
    return oUnion:GetName()
end

--同步货币
function CGRole:SyncCurrency(nType, nValue, nValue1, nValue2)
    assert(nType and nValue, "参数错误")
    self:SendMsg("RoleCurrencyRet", {tList={{nType=nType, nValue=nValue, nValue1=nValue1, nValue2=nValue2}}})
end

--推送成就
function CGRole:PushAchieve(sEvent, tArgs, fnCallback)
    if fnCallback then
        Network.oRemoteCall:CallWait("PushAchieve", fnCallback, self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID(), sEvent, tArgs)
    else
        Network.oRemoteCall:Call("PushAchieve", self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID(), sEvent, tArgs)
    end
end

--帮贡变化通知(目前生活技能用到)
function CGRole:ChangeUnionContri()
     Network.oRemoteCall:Call("ChangeUnionContri", self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID(), sEvent, tArgs)
end

--等级变化
function CGRole:OnLevelChange()
    if goTeamMgr then
        goTeamMgr:OnLevelChange(self)
    end
    if goRankingMgr and not self:IsRobot() then
        goRankingMgr:OnLevelChange(self, self:GetLevel())
    end
    if goHDMgr and goHDMgr.OnRoleLevelChange then
        goHDMgr:OnRoleLevelChange(self)
    end
end

--系统开启
function CGRole:OnSysOpen(nSysID, tSysData)
    assert(nSysID and tSysData)
    self.m_tOpenSysMap[nSysID] = tSysData
    self:MarkDirty(true)
end

--系统关闭
function CGRole:OnSysClose(nSysID, tSysData)
    assert(nSysID and tSysData)
    self.m_tOpenSysMap[nSysID] = tSysData
    self:MarkDirty(true)
end

function CGRole:OnNameChange(sOld)
    print(">>>>>> 触发角色改名事件 <<<<<<")
    if goTeamMgr then 
        goTeamMgr:OnNameChange(self)
    end

    if not self:IsRobot() then 
        goGPlayerMgr:OnRoleNameChange(sOld, self.m_sName)
        
        if goMarriageMgr then 
            goMarriageMgr:OnNameChange(self)
        end
        if goLoverRelationMgr then 
            goLoverRelationMgr:OnNameChange(self)
        end
        if goBrotherRelationMgr then 
            goBrotherRelationMgr:OnNameChange(self)
        end
        if goMentorshipMgr then 
            goMentorshipMgr:OnNameChange(self)
        end
    end
end

function CGRole:OnActiveNumChange(nVal)
    if self:IsRobot() then return end
    goMentorshipMgr:OnActiveNumChange(self:GetID(), nVal)
end

--元宝不足弹框
function CGRole:YuanBaoTips()
    self:SendMsg("GoldAllNotEnoughtRet", {})
end

--金币不足通知,客户端会弹相应界面
function CGRole:JinBiTips()
    self:SendMsg("JinBiNotEnoughtRet", {})
end
--银币不足通知,客户端会弹相应的界面
function CGRole:YinBiTips()
    self:SendMsg("YinBiNotEnoughtRet", {})
end

--内丹不足通知,客户端会弹相应的界面
function CGRole:MagicPillTips()
    self:SendMsg("MagicPillNotEnoughtRet", {})
end

--道具不足通知,客户端弹出对应的Tips
function CGRole:PropTips(nPropID)
    self:SendMsg("PropNotEnoughtRet", {nPropID = nPropID})
end

--战力变化
function CGRole:OnPowerChange(nOldPower, nNewPower)
    if self:IsRobot() then return end
    if goUnionMgr then
        goUnionMgr:OnRolePowerChange(self)
    end
    if goHDMgr then
        goHDMgr:OnPowerChange(self, nOldPower, nNewPower)
    end
    if goRankingMgr then
        goRankingMgr:OnPowerChange(self, nNewPower)
    end
end

--综合战力变化            
function CGRole:OnColligatePowerChange(nOldPower, nNewPower)
    if self:IsRobot() then return end
    if goRankingMgr then
        goRankingMgr:OnColligatePowerChange(self, nNewPower)
    end
end
            

--被邀请
function CGRole:OnRoleInvite()
    if goInvite then
        goInvite:AddInvite(self.m_nInviteRoleID, self:GetID())
    end
end

--踢玩家下线
function CGRole:KickOffline()
    if not self:IsOnline() then
        return
    end
    local nTarServer = self:GetServer()
    local nTarSession = self:GetSession()
    Network.CmdSrv2Srv("KickClientReq", nTarServer, nTarSession>>gtGDef.tConst.nServiceShift, nTarSession)
end

--取账号状态gtAccountState 
function CGRole:GetAccountState(fnCallback)
    Network.oRemoteCall:CallWait("AccountValueReq", fnCallback, self:GetServer(), goServerMgr:GetLoginService(self:GetServer()), self:GetSession(), self:GetAccountID(), "m_nAccountState")
end

--gm测试
function CGRole:SetTestMan(nTestMan)
    self.m_nTestMan = nTestMan
end

function CGRole:GetTestMan()
    return self.m_nTestMan
end

--科举回答请求信息
function CGRole:KejuAnswerHelpQuestionReq(tData)
    Network.oRemoteCall:Call("KejuAnswerHelpQuestionReq",self:GetServer(),self:GetLogic(),self:GetSession(),self:GetID(),tData)
end

function CGRole:KejuHelpQuestionDataReq(oRole,nQuestionID)
    local fnCallback = function (tMsg)
        if not tMsg then
            oRole:Tips("求助者已经解答过此题目了")
            return
        end
        oRole:SendMsg("KejuHelpQuestionDataRet",tMsg)
    end
    local nRoleID = oRole:GetID()
    Network.oRemoteCall:CallWait("KejuHelpQuestionDataReq",fnCallback,self:GetServer(),self:GetLogic(),self:GetSession(),self:GetID(),nRoleID,nQuestionID)
end

--求助玩家八荒任务数据请求
function CGRole:BaHuangHuoZhenTaskInfoReq(oRole,nBoxID)
     Network.oRemoteCall:Call("GetHelpRoleDataReq",self:GetServer(),self:GetLogic(),self:GetSession(),self:GetID(),oRole:GetID(),nBoxID)
end

function CGRole:BaHuangHuoZhenPushHelpRoleBoxReq(oRole, tMsg, sReason)
    if sReason and type(sReason) == "string" then
        return oRole:Tips(sReason)
    end
    if tMsg then
        oRole:SendMsg("BaHuangHuoZhenHelpPlayerBoxListRet", tMsg)
    end
end

function CGRole:BaHuangHuoZhenHelpPackingBoxReq(oRole, nBoxID)
    local fnCallback = function (sReason, tSubItem, tAddItem)
        if sReason then
            if type(sReason) == "string" then
                oRole:Tips(sReason)
                return
            end
        else
            return 
        end
        local fnSubItemCallback = function (bRet, tData)
            if not bRet then return end
            local fnPackingBoxCallback = function (tMsg, sTips1, sTips2)
                if tMsg then
                    oRole:SendMsg("BaHuangHuoZhenBoxChangeRet", tMsg)
                end
                if sTips1 and type(sTips1) == "string" then
                    oRole:Tips(sTips1)
                end
                if sTips2 and type(sTips2) == "string" then
                    oRole:Tips(sTips2)
                end
                oRole:AddItem(tAddItem, "八荒火阵装箱获得")
            end
            if tAddItem[1] and tAddItem[1].nID == gtCurrType.ePracticeExp then
                tData.nPracticeExp = tAddItem[1].nNum
            end

            Network.oRemoteCall:CallWait("HelpPackingBoxCheckHandleReq",fnPackingBoxCallback, self:GetServer(),self:GetLogic(),self:GetSession(),self:GetID(),oRole:GetID(), nBoxID, tData)
        end
        Network.oRemoteCall:CallWait("BaHuangHuoZhenSubItemReq",fnSubItemCallback, oRole:GetServer(),oRole:GetLogic(),oRole:GetSession(),oRole:GetID(),tSubItem)
    end
    Network.oRemoteCall:CallWait("BaHuangHuoZhenHelpPackingBoxCheckReq",fnCallback, self:GetServer(),self:GetLogic(),self:GetSession(),self:GetID(),nBoxID)
end

--帮派发生变化
function CGRole:OnUnionChange(nOldUnionID, nNewUnionID)
end

--fnCallback(sPreStr)
function CGRole:QueryRelationshipInvitePreStr(fnCalback)
    assert(fnCalback)
    local fnQueryCallback = function(tData)
        if not tData then 
            return 
        end
        local nMountsID = tData.nMountsID
        local nWingID = tData.nWingID
        local nHaloID = tData.nHaloID
        local tPetInfo = tData.tPetInfo
        assert(nMountsID and nWingID and nHaloID and tPetInfo)

        local tPropertyConf = ctTalkConf["relationproperty"]
        assert(tPropertyConf)
        local tContentTbl = {}
        if nMountsID > 0 then 
            local tMountsConf = ctShiZhuangConf[nMountsID]
            local sContent = string.format(tPropertyConf.tContentList[1][1], nMountsID, tMountsConf.sName)
            table.insert(tContentTbl, sContent)
        end
        if nWingID > 0 then 
            local tWingConf = ctShiZhuangConf[nWingID]
            local sContent = string.format(tPropertyConf.tContentList[2][1], nWingID, tWingConf.sName)
            table.insert(tContentTbl, sContent)
        end
        if nHaloID > 0 then 
            local tHaloConf = ctShiZhuangConf[nHaloID]
            local sContent = string.format(tPropertyConf.tContentList[3][1], nHaloID, tHaloConf.sName)
            table.insert(tContentTbl, sContent)
        end
        if tPetInfo and tPetInfo.nPetID > 0 then 
            local nPetID = tPetInfo.nPetID
            local tPetConf = ctPetInfoConf[nPetID]
            local sContent = string.format(tPropertyConf.tContentList[4][1], 
                tPetInfo.nPetPos, self:GetID(), tPetConf.sName)
            table.insert(tContentTbl, sContent)
        end

        local sPreStr = table.concat(tContentTbl)
        fnCalback(sPreStr)
    end
    Network.oRemoteCall:CallWait("RelationInviteInfoQueryReq", fnQueryCallback, 
        self:GetServer(), self:GetLogic(), self:GetSession(), self:GetID())
end

function CGRole:OnRoleMarriageActStateEvent() 
    if goTeamMgr then 
        goTeamMgr:GetMatchMgr():RemoveMatchByRoleID(self:GetID(), true)
    end
end

--远程调用封装
function CGRole:RemoteCall(sRpcName, fnCallback, ...)
    if fnCallback then
        Network.oRemoteCall:CallWait(sRpcName, fnCallback, self:GetServer(), self:GetLogic(), self:GetSession(), ...)
    else
        Network.oRemoteCall:Call(sRpcName, self:GetServer(), self:GetLogic(), self:GetSession(), ...)
    end
end

function CGRole:OnRechargeSuccess(nID, nMoney, nYuanBao, nBYuanBao, nTime)
    -- print("玩家充值事件")
    if goHDMgr then 
        goHDMgr:OnRechargeSuccess(self, nID, nMoney, nYuanBao, nBYuanBao, nTime)
    end
    if goInvite then
        goInvite:OnRechargeSuccess(self, nYuanBao)
    end
end

--更新开服目标活动数值
function CGRole:UpdateGrowthTargetActVal(eActType, nVal)
    if self:IsRobot() then 
        return 
    end
    local nServer = self:GetServer()
    if gnServerID == nServer then 
        local oAct = goHDMgr:GetActivity(eActType)
        if not oAct or not oAct:IsOpen() then 
            return 
        end
        oAct:UpdateTargetVal(self:GetID(), nVal)
    else
        Network.oRemoteCall:Call("UpdateGrowthTargetActValReq", nServer, goServerMgr:GetGlobalService(nServer, 20), 
            0, self:GetID(), eActType, nVal)
    end
end

--增加开服目标活动数值
function CGRole:AddGrowthTargetActVal(eActType, nVal)
    if self:IsRobot() then 
        return 
    end
    local nServer = self:GetServer()
    if gnServerID == nServer then 
        local oAct = goHDMgr:GetActivity(eActType)
        if not oAct or not oAct:IsOpen() then 
            return 
        end
        oAct:AddTargetVal(self:GetID(), nVal)
    else
        Network.oRemoteCall:Call("AddGrowthTargetActValReq", nServer, goServerMgr:GetGlobalService(nServer, 20), 
            0, self:GetID(), eActType, nVal)
    end
end

local tGrowthTargetActTriggerMap = 
{
    [112] = function(oRole) oRole:UpdateActGTArenaScore() end,
}

function CGRole:TriggerGrowthTargetActData(tActList)
    for _, nActID in pairs(tActList) do 
        local fnTrigger = tGrowthTargetActTriggerMap[nActID]
        if fnTrigger then 
            fnTrigger(self)
        end
    end
end

--开服目标活动 竞技积分
function CGRole:UpdateActGTArenaScore()
    local nScore = goArenaMgr:GetRoleScore(self:GetID()) or 0
    self:UpdateGrowthTargetActVal(112, nScore)
end

--开服目标活动 个人帮贡
function CGRole:AddActGTPersonUnionContri(nVal)
    self:AddGrowthTargetActVal(113, nVal)
end

--检查队员是否能参加闯关
function CGRole:CheckTeamMemCanChuangGuan(fnCallback)
    assert(fnCallback, "参数错误")
    Network.oRemoteCall:CallWait("GetChuangGuanTypeReq", fnCallback, self:GetStayServer(), self:GetLogic(), self:GetSession(), self:GetID())
end

--元宝变化事件
--@bBind 是否绑定元宝
function CGRole:OnYuanBaoChange(nYuanBao, bBind)
    if goHDMgr then
        goHDMgr:OnYuanBaoChange(self, nYuanBao, bBind)
    end
end

--手动同步背包缓存消息
function CGRole:SyncKnapsackCacheMsg()
    self:RemoteCall("KnapsackSyncCachedMsgReq", nil, self:GetID())
end