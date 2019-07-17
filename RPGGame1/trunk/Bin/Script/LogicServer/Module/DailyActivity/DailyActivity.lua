--日程
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

_ctActIDMap = {} --{[nDayIndex] = {nActID}}
local function _PreProDayActIDMap()
    for nActID, tConf in pairs(ctDailyActivity) do
        for i, tDayIndex in pairs(tConf.tOpenList) do
            if not _ctActIDMap[tDayIndex[1]] then
                _ctActIDMap[tDayIndex[1]] = {}
                table.insert(_ctActIDMap[tDayIndex[1]], nActID)
            else
                table.insert(_ctActIDMap[tDayIndex[1]], nActID)
            end
        end
    end
end
_PreProDayActIDMap() --按日期预处理

function CDailyActivity:Ctor(oRole)
    self.m_oRole = oRole
    self.m_tActDataMap = {}                 --个人日程活动信息 {[nActID]={ActType, ActID, CountComp, ActValue, CanJoin, IsComp, IsEnd, eIsClick, eISCanJoin}}
    self.m_nTotalActValue = 0               --当天总活跃值
    self.m_nGetRewardIndex = 0              --已领取活跃奖励的索引
    self.m_nLastResetTimeStamp = 0          --上次清空数据时间戳
    self.m_tRewardData = {}                 --活跃奖励领取记录
    self.m_tRewardState = {}                --活跃奖励是否可以领取状态
    self.m_nTarBattleDupType = 0            --目标副本类型(在日常面板点击记录)

    self.m_nShareGameState = 0              --分享状态(0未分享; 1已分享未领奖; 2已领奖)
    
    --不保存数据
    self.m_tHandleFunc = {}
    self.m_tActData = {0, 0, 0, 0, false, false, false, false, false}    --用于初始化保存数据
    self:RegisterHandle()

    self.m_tShowTipsActList = {}             --针对本次上线,记录当前满足条件的活动是否推送{nActID =  false}
end

function CDailyActivity:LoadData(tData)
    if tData then
        if tData.m_tActDataMap then
            for nActID, tActData in pairs(tData.m_tActDataMap) do
                self.m_tActDataMap[nActID] = table.DeepCopy(tActData)
                self.m_tActDataMap[nActID][gtDailyData.eIsEnd] = self.m_tActDataMap[nActID][gtDailyData.eIsEnd] or false
                self.m_tActDataMap[nActID][gtDailyData.eIsClick] = self.m_tActDataMap[nActID][gtDailyData.eIsClick] or false 
                self.m_tActDataMap[nActID][gtDailyData.eIsCanJoin] = self.m_tActDataMap[nActID][gtDailyData.eIsCanJoin] or false          
            end
        end
        self.m_nTotalActValue = tData.m_nTotalActValue or self.m_nTotalActValue
        self.m_nGetRewardIndex = tData.m_nGetRewardIndex or self.m_nGetRewardIndex
        self.m_nLastResetTimeStamp = tData.m_nLastResetTimeStamp or self.m_nLastResetTimeStamp
        self.m_tRewardData = tData.m_tRewardData or self.m_tRewardData
        self.m_nTarBattleDupType = tData.m_nTarBattleDupType or self.m_nTarBattleDupType
        self.m_nShareGameState = tData.m_nShareGameState or 0
        self.m_tShowTipsActList = tData.m_tShowTipsActList or {}
    end
    if self.m_nLastResetTimeStamp <= 0 then
        self.m_nLastResetTimeStamp = os.time()
        self:MarkDirty(true)
    end
end

function CDailyActivity:SaveData()
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)

    local tData = {}
    tData.m_tActDataMap = self.m_tActDataMap
    tData.m_nTotalActValue = self.m_nTotalActValue
    tData.m_nGetRewardIndex = self.m_nGetRewardIndex
    tData.m_nLastResetTimeStamp = self.m_nLastResetTimeStamp
    tData.m_tRewardData = self.m_tRewardData
    tData.m_nTarBattleDupType = self.m_nTarBattleDupType
    tData.m_nShareGameState = self.m_nShareGameState
    tData.m_tShowTipsActList = self.m_tShowTipsActList
    return tData
end

function CDailyActivity:GetType()
    return gtModuleDef.tDailyActivity.nID, gtModuleDef.tDailyActivity.sName
end

function CDailyActivity:Release()
end

function CDailyActivity:CheckAndSetStatus()
    local bHasAct = false
    local bCanJoinNow = false    --是否是刚刚可以参加
    local nDayIndex = os.WDay(os.time())
    local tShowTipsActList = {} --需要提示开启的活动列表

    for nKey, nActID in pairs(_ctActIDMap[nDayIndex]) do
        local nSysOpenID = ctDailyActivity[nActID].nSysOpenID
        --角色开启该功能才初始化数据，机器人默认初始化所有数据
        if self.m_oRole.m_oSysOpen:IsSysOpen(nSysOpenID) or self.m_oRole:IsRobot() then 
            if not self.m_tActDataMap[nActID] then 
                self.m_tActDataMap[nActID] = table.DeepCopy(self.m_tActData)
                self:SetRecordData(nActID, gtDailyData.eActType, ctDailyActivity[nActID].nActivityType)
                self:SetRecordData(nActID, gtDailyData.eActID, nActID)
            end
        end

        --判断是否能参加
        if self:CheckCanJoinAct(nActID) then
            --可以参加的设置可以参加
            local bCanJoinBefore = self.m_tActDataMap[nActID] ~= nil and self.m_tActDataMap[nActID][gtDailyData.ebCanJoin] or false
            if ctDailyActivity[nActID].nActivityType == 2 then
                if nActID ~= gtDailyID.eUnionArena or 
                    os.time() > (goServerMgr:GetOpenZeroTime(self.m_oRole:GetServer()) + 7*24*3600) then
                    if not self.m_tActDataMap[nActID][gtDailyData.eIsCanJoin] then
                       if os.time() - CDailyActivity:GetStartStamp(nActID) < ctDailyActivity[nActID].nArrivaTime * 60 then
                            table.insert(tShowTipsActList, nActID)
                        else
                            self:JoinActRecord(nActID)
                        end
                    end
                end
            end

            if not bCanJoinBefore then
                self:SetRecordData(nActID, gtDailyData.ebCanJoin, true)
                bHasAct = true
                bCanJoinNow = true
            end
        else
            --已有记录的没开启时设置不能参加
            self:SetRecordData(nActID, gtDailyData.ebCanJoin, false)
        end
    end

    if bHasAct and bCanJoinNow then     --刚刚可以参加的才推送信息
        self:SendAllInfo(nDayIndex)
        self:SendDayActList(nDayIndex)
    end

    if #tShowTipsActList > 0 then
        for k, nID in pairs(tShowTipsActList) do
            if self.m_tShowTipsActList[nID] then
               table.remove(tShowTipsActList, k)
            else
                self.m_tShowTipsActList[nID] = true
            end
        end
        self:MarkDirty(true)
    end

    if #tShowTipsActList > 0 then
        local tOpenEventData = {}
        local tActList = {}
        for k, nID in ipairs(tShowTipsActList) do
            table.insert(tActList, nID)
        end
        tOpenEventData.tActList = tActList
        self.m_oRole:SendMsg("DailyActOpenEventNotifyRet", tOpenEventData)
    end
end

function CDailyActivity:CheckActRewardState()
    for nIndex, tConf in pairs(ctDailyActReward) do
        self.m_tRewardState[nIndex] = self.m_tRewardState[nIndex] or 0
        self.m_tRewardData[nIndex] = self.m_tRewardData[nIndex] or 0
        if self.m_nTotalActValue >= tConf.nNeedActVal and self.m_tRewardData[nIndex] == 0 then
            self.m_tRewardState[nIndex] = 1     --可领取
        elseif self.m_nTotalActValue >= tConf.nNeedActVal and self.m_tRewardData[nIndex] == 1 then
            self.m_tRewardState[nIndex] = 2
        end
    end
end

function CDailyActivity:Online()
    if not os.IsSameDay(self.m_nLastResetTimeStamp, os.time()) then
        self:ResetData()
    end
    if self.m_oRole:IsRobot() then 
        for k, v in pairs(gtDailyID) do 
            if not self.m_tActDataMap[v] then 
                self.m_tActDataMap[v] = table.DeepCopy(self.m_tActData)
            end
        end
    end
    self:CheckAndSetStatus()
    self:CheckActRewardState()
    local nDayIndex = os.WDay(os.time())
    self:SendAllInfo(nDayIndex)
    self:SendDayActList(nDayIndex)
end

function CDailyActivity:Offline()
    self.m_tShowTipsActList = {}
    self:MarkDirty(true)
end

function CDailyActivity:OnRoleLevelChange(nNewLevel)
    self:CheckAndSetStatus()
end

function CDailyActivity:Operation(tData)
    if tData.nOperaType == gtDailyOpera.eAllActInfoReq then
        local nDayIndex = os.WDay(os.time())
        self:SendAllInfo(nDayIndex)

    elseif tData.nOperaType == gtDailyOpera.eOneDayActListReq then
        self:SendDayActList(tData.nParam1)
        
    elseif tData.nOperaType == gtDailyOpera.eJoinAct then
        self:JoinAct(tData.nParam1)

    elseif tData.nOperaType == gtDailyOpera.eGetDailyActReward then
        self:GetDailyActReward(tData.nParam1)

    elseif tData.nOperaType == gtDailyOpera.eClick then
        self:OnClickAct(tData.nParam1)        
    end
end

--注册活动与对应的处理函数(点击参加按钮寻找npc的要注册空处理函数)
function CDailyActivity:RegisterHandle()
    self.m_tHandleFunc[gtDailyID.eZhenYao] = function() self:JoinZhenYao() end
    self.m_tHandleFunc[gtDailyID.eLuanShiYaoMo] = function() self:JoinLuanShiYaoMo() end
    self.m_tHandleFunc[gtDailyID.eXinMoQinShi] = function() self:JoinXinMoQinShi() end
    self.m_tHandleFunc[gtDailyID.eShiMenTask] = function() self:AccpShiMenTask() end
    self.m_tHandleFunc[gtDailyID.eSchoolArena] = function() self:JoinSchoolArenaActivity() end
    self.m_tHandleFunc[gtDailyID.eQimaiArena] = function() self:JoinQimaiArenaActivity() end
    self.m_tHandleFunc[gtDailyID.eUnionArena] = function() self:JoinUnionArenaActivity() end
    self.m_tHandleFunc[gtDailyID.eQingyunBattle] = function () self:JoinQingyunBattleActivity() end
    --self.m_tHandleFunc[gtDailyID.eShenShouLeYuan] = function() self:JoinShenShouLeYuan() end
    self.m_tHandleFunc[gtDailyID.eJueZhanJiuXiao] = function() self:JoinJueZhanJiuXiao() end
    self.m_tHandleFunc[gtDailyID.eMengZhuWuShuang] = function() self:JoinCMengZhuWuShuang() end
    self.m_tHandleFunc[gtDailyID.eHunDunShiLian] = function() self:JoinCHunDunShiLian() end
    self.m_tHandleFunc[gtDailyID.eBaoTu] = function() end
    self.m_tHandleFunc[gtDailyID.eShangJinTask] = function() end
    self.m_tHandleFunc[gtDailyID.eShenMoZhi] = function() self:JoinShenMoZhi() end
    self.m_tHandleFunc[gtDailyID.eKeJu] = function() self:JoinKeJu(1) end
    self.m_tHandleFunc[gtDailyID.eKeJu2] = function() self:JoinKeJu(2) end
    self.m_tHandleFunc[gtDailyID.eKeJu3] = function() self:JoinKeJu(3) end
    self.m_tHandleFunc[gtDailyID.eShiLianTask] = function() end
    self.m_tHandleFunc[gtDailyID.eYaoShouTuXi] = function () self:JoinYaoShouTuXi() end
    self.m_tHandleFunc[gtDailyID.eBaHuangHuoZhen] = function() self:JoinBaHuangHuoZhen() end
end

function CDailyActivity:OnClickAct(ngtDailyID)
    local bWasClick = self:GetRecData(ngtDailyID)[gtDailyData.eIsClick]
    if bWasClick then return end
    self:SetRecordData(ngtDailyID, gtDailyData.eIsClick, true)
    self:MarkDirty(true)
    self:SendActivityInfo(ngtDailyID)
end

--参加活动
function CDailyActivity:JoinAct(nActID)
    if not self.m_tHandleFunc[nActID] then
        return self.m_oRole:Tips("参加活动发生错误")
    end
    self:JoinActRecord(nActID)
    self.m_tHandleFunc[nActID]()
end

function CDailyActivity:JoinActRecord(nActID)
    local tActData = self:GetRecData(nActID)
    if tActData then
        local bWasClick = self:GetRecData(nActID)[gtDailyData.eIsCanJoin]
        if bWasClick then return end
        self:SetRecordData(nActID, gtDailyData.eIsCanJoin, true)
        local nDayIndex = os.WDay(os.time())
        self:SendDayActList(nDayIndex)
    end
end

--领取活跃奖励
function CDailyActivity:GetDailyActReward(nIndex)
    assert(ctDailyActReward[nIndex], "奖励索引不正确")

    self.m_tRewardData[nIndex] = self.m_tRewardData[nIndex] or 0
    if self.m_tRewardData[nIndex] > 0 then
        return self.m_oRole:Tips("该奖励已经领取过")
    end

    if self.m_tRewardState[nIndex] == nil or self.m_tRewardState[nIndex] <= 0 then
        return self.m_oRole:Tips("该奖励还不能领取")
    end

    local tReward = ctDailyActReward[nIndex].tItemReward
    self.m_oRole:AddItem(gtItemType.eProp, tReward[1][1], tReward[1][2], "领取日程活跃奖励")

    self.m_tRewardData[nIndex] = 1      --设置记录领取过
    self.m_tRewardState[nIndex] = 2     --设置状态已领取
    self:MarkDirty(true)
    local nDayIndex = os.WDay(os.time())
    self:SendAllInfo(nDayIndex)
end 

--设置活动数据(有设置taskID不能用加法)
function CDailyActivity:SetRecordData(nActID, nDailyData, nValue)
    assert(nActID and nDailyData, "设置活动记录数据参数有误")

    if self.m_tActDataMap[nActID] then
        local nOldVal = self.m_tActDataMap[nActID][nDailyData] or 0
        self.m_tActDataMap[nActID][nDailyData] = nValue

        --增加活跃度时，同时增加活力
        if nDailyData == gtDailyData.enActValue and nValue > 0 then
            local nVitality = (nValue - nOldVal) * (5 + math.floor(self.m_oRole:GetLevel()/20))
            self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eVitality, nVitality, "日程活跃增加恢复活力")
            self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eDrawSpirit, (nValue - nOldVal)*20, "活跃增加增加灵气")            
            --活跃奖励是否可领取状态做检查
            self:CheckActRewardState()
        end
        self:MarkDirty(true)
    end
end

--完成日程活动一次
function CDailyActivity:OnCompleteDailyOnce(nActID, sReason)
    assert(nActID > 0 and sReason, "日程活动完成记录参数有误")
    if not self.m_tActDataMap[nActID] then
        return
    end
    local nCompTimes = self.m_tActDataMap[nActID][gtDailyData.eCountComp]
    local nMaxTimes = ctDailyActivity[nActID].nTimesReward
    local nNewCompTimes = nCompTimes+1
    self:SetRecordData(nActID, gtDailyData.eCountComp,  nNewCompTimes)
    goLogger:EventLog(gtEvent.eDailyCompTimes, self.m_oRole,  nActID, nNewCompTimes)
    --if nCompTimes >= nMaxTimes then return end

    if nNewCompTimes <= nMaxTimes then
        local nActValue = self.m_tActDataMap[nActID][gtDailyData.enActValue]
        local nReward = ctDailyActivity[nActID].nRewardActValue
        if nActValue < ctDailyActivity[nActID].nMaxActValue then
            self:SetRecordData(nActID, gtDailyData.enActValue,  nActValue+nReward)
            self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eActValue, nReward, sReason)
        end
        if nNewCompTimes >= nMaxTimes then
            if not self.m_tActDataMap[nActID][gtDailyData.eIsComp] then
                self:SetRecordData(nActID, gtDailyData.eIsComp, true)
            end
            if not ctDailyActivity[nActID].bCanJoinContinues then
                self:SetRecordData(nActID, gtDailyData.ebCanJoin, false)
            end
        end
    end
    self:MarkDirty(true)
    self:SendActivityInfo(nActID)
end

function CDailyActivity:ShareGameStatusReq()
    self.m_oRole:SendMsg("ShareGameStatusRet", {nShareState=self.m_nShareGameState})
end

--分享成功请求
function CDailyActivity:ShareGameSuccessReq()
    if self.m_nShareGameState ~= 0 then
        return self.m_oRole:Tips("分享状态错误")
    end
    self.m_nShareGameState = 1
    self:MarkDirty(true)
    self:ShareGameStatusReq()
end

--领取分享游戏奖励
function CDailyActivity:GetShareGameRewardReq()
    do
        return self.m_oRole:Tips("分享功能已屏蔽")
    end 
    
    if self.m_nShareGameState ~= 1 then
        return self.m_oRole:Tips("分享状态错误:"..self.m_nShareGameState)
    end

    local nOpenZeroTime = goServerMgr:GetOpenZeroTime(self.m_oRole:GetServer())
    local nPassTime = os.time() - nOpenZeroTime
    local nPassDays = math.max(1, math.ceil(nPassTime/(24*3600)))
    local nConfID = 0
    for nID, tConf in pairs(ctShareGameReward) do
        if tConf.nMinDay <= nPassDays and nPassDays <= tConf.nMaxDay then
            nConfID = nID
            break
        end
    end

    for nIndex, tItem in pairs(ctShareGameReward[nConfID].tRewardList) do
        self.m_oRole:AddItem(tItem[1], tItem[2], tItem[3], "分享游戏奖励领取")
    end
    self.m_nShareGameState = 2
    self:MarkDirty(true)
    self:ShareGameStatusReq()
end

--零点清空数据
function CDailyActivity:ResetData()
     --找回奖励模块调用(引用到部分活动参加的数据,统计用)
    self.m_oRole.m_oFindAward:FindAwardInfo()

    for nActID, tData in pairs(self.m_tActDataMap) do
        tData[gtDailyData.eCountComp] = 0
        tData[gtDailyData.enActValue] = 0
        tData[gtDailyData.ebCanJoin] = false
        tData[gtDailyData.eIsComp] = false
        tData[gtDailyData.eIsEnd] = false
        tData[gtDailyData.eIsClick] = false
        tData[gtDailyData.eIsCanJoin] = false               
    end
    for nIndex, _ in ipairs(self.m_tRewardData) do
        self.m_tRewardData[nIndex] = 0
    end
    self.m_nTotalActValue = 0
    self.m_nGetRewardIndex = 0
    self.m_nLastResetTimeStamp = os.time()
    self.m_nShareGameState = 0
    self.m_tShowTipsActList = {}
    self:MarkDirty(true)
end

--发送某天活动列表
function CDailyActivity:SendDayActList(nDayIndex)
    assert(_ctActIDMap[nDayIndex], "该天没日程活动")
    if self.m_oRole:IsRobot() then
        return
    end
    local tMsg = {nDayIndex = nDayIndex, tActIDList = {}, tActInfoList = {}}
    for k, nActID in pairs(_ctActIDMap[nDayIndex]) do
        local bLevelEnough = self.m_oRole:GetLevel() >= ctDailyActivity[nActID].nLevelLimit
        table.insert(tMsg.tActIDList, nActID)
        local tInfo = {}
        if self:CheckCanJoinAct(nActID) and nDayIndex == os.WDay(os.time()) then --能参加
            tInfo.nActType=self.m_tActDataMap[nActID][gtDailyData.eActType]
            tInfo.nActID=self.m_tActDataMap[nActID][gtDailyData.eActID]
            tInfo.nCountComp=self.m_tActDataMap[nActID][gtDailyData.eCountComp]
            tInfo.nActValue=self.m_tActDataMap[nActID][gtDailyData.enActValue]
            tInfo.bCanJoin=self.m_tActDataMap[nActID][gtDailyData.ebCanJoin]
            tInfo.bIsComp=self.m_tActDataMap[nActID][gtDailyData.eIsComp]
            tInfo.bIsEnd=self.m_tActDataMap[nActID][gtDailyData.eIsEnd]
            tInfo.bClick=self.m_tActDataMap[nActID][gtDailyData.eIsClick]
            tInfo.bIsCanJoin =self.m_tActDataMap[nActID][gtDailyData.eIsCanJoin]
            table.insert(tMsg.tActInfoList, tInfo)   

        elseif nDayIndex == os.WDay(os.time()) and  bLevelEnough then   --等级足够，但活动尚未开启
            tInfo.nActType=ctDailyActivity[nActID].nActivityType
            tInfo.nActID=nActID
            tInfo.nCountComp=self.m_tActData[gtDailyData.eCountComp]
            tInfo.nActValue=self.m_tActData[gtDailyData.enActValue]
            tInfo.bCanJoin=self.m_tActData[gtDailyData.ebCanJoin]
            tInfo.bIsComp=self.m_tActData[gtDailyData.eIsComp] 
            tInfo.bIsEnd=self.m_tActData[gtDailyData.eIsEnd]
            tInfo.bClick=self.m_tActData[gtDailyData.eIsClick]
            tInfo.bIsCanJoin =self.m_tActData[gtDailyData.eIsCanJoin]      
            table.insert(tMsg.tActInfoList, tInfo)
        end
    end
    self.m_oRole:SendMsg("DayActListRet", tMsg)
end

--发送今天能参加的活动的信息(allinfo请求)
function CDailyActivity:SendAllInfo(nDayIndex)
    local tMsg = {nTotalActValue=self.m_nTotalActValue, tActInfoList={}, tActRewardState={}}
    for _, nActID in pairs(_ctActIDMap[nDayIndex]) do 
        --if self.m_oRole:GetLevel() >= ctDailyActivity[nActID].nLevelLimit and self.m_tActDataMap[nActID] then
        local nSysOpenID = ctDailyActivity[nActID].nSysOpenID
        if self.m_oRole.m_oSysOpen:IsSysOpen(nSysOpenID) and self.m_tActDataMap[nActID] then 
            local tInfo = 
            {
                nActType=self.m_tActDataMap[nActID][gtDailyData.eActType],
                nActID=self.m_tActDataMap[nActID][gtDailyData.eActID],
                nCountComp=self.m_tActDataMap[nActID][gtDailyData.eCountComp],
                nActValue=self.m_tActDataMap[nActID][gtDailyData.enActValue],
                bCanJoin=self.m_tActDataMap[nActID][gtDailyData.ebCanJoin],
                bIsComp=self.m_tActDataMap[nActID][gtDailyData.eIsComp],
                bIsEnd=self.m_tActDataMap[nActID][gtDailyData.eIsEnd],
                bClick=self.m_tActDataMap[nActID][gtDailyData.eIsClick], 
                bIsCanJoin =self.m_tActDataMap[nActID][gtDailyData.eIsCanJoin],                                                       
            }
            table.insert(tMsg.tActInfoList, tInfo)
        end
    end
    self:CheckActRewardState()      --数据不保存  切换逻辑服不走Online 这里检查一次
    for _, nState in ipairs(self.m_tRewardState) do
        table.insert(tMsg.tActRewardState, nState)
    end
    self.m_oRole:SendMsg("ActivityInfoListRet", tMsg)
    --PrintTable(tMsg)
end

--发送新信息
function CDailyActivity:SendActivityInfo(nActID)
    assert(self.m_tActDataMap[nActID], "没有保存的数据")

    local tMsg = { ActivityInfo = {} }
    tMsg.ActivityInfo.nActType=self.m_tActDataMap[nActID][gtDailyData.eActType]
    tMsg.ActivityInfo.nActID=self.m_tActDataMap[nActID][gtDailyData.eActID]
    tMsg.ActivityInfo.nCountComp=self.m_tActDataMap[nActID][gtDailyData.eCountComp]
    tMsg.ActivityInfo.nActValue=self.m_tActDataMap[nActID][gtDailyData.enActValue]
    tMsg.ActivityInfo.bCanJoin=self.m_tActDataMap[nActID][gtDailyData.ebCanJoin]
    tMsg.ActivityInfo.bIsComp=self.m_tActDataMap[nActID][gtDailyData.eIsComp]
    tMsg.ActivityInfo.bIsEnd=self.m_tActDataMap[nActID][gtDailyData.eIsEnd]
    tMsg.ActivityInfo.bClick=self.m_tActDataMap[nActID][gtDailyData.eIsClick]
    tMsg.ActivityInfo.bIsCanJoin = self.m_tActDataMap[nActID][gtDailyData.eIsCanJoin] 
    tMsg.nTotalActValue=self.m_nTotalActValue
    
    self.m_oRole:SendMsg("ActivitySingleInfoRet", tMsg)
end

function CDailyActivity:CheckOpenTime(nActID) --检查开启时间
    local bIsAct = false
    assert(ctDailyActivity[nActID], "没有该日程活动配置")
    local nDayIndex = os.WDay(os.time())
    for _, nCanJoinID in pairs(_ctActIDMap[nDayIndex]) do
        if nCanJoinID == nActID then
            bIsAct = true
        end
    end
    if not bIsAct then
        return false
    end
    local nOpenTime = ctDailyActivity[nActID].nOpenTime
    local nCloseTime = ctDailyActivity[nActID].nCloseTime
    local nCurrHour = os.date("%H")
    local nCurrMin = os.date("%M")
    local nCurrTime = tonumber(nCurrHour .. nCurrMin)
    if nCurrTime < nOpenTime or nCurrTime >= nCloseTime then
        if nCurrTime >= nCloseTime then  --活动时间结束设置活动结束
            self:SetRecordData(nActID, gtDailyData.eIsEnd, true)
        end
        return false
    end

    return true
end

--获取当天的活动开启时间
function CDailyActivity:GetStartStamp(nActID)
    local tConf = ctDailyActivity[nActID]
    local nOpenTime = math.max(tConf.nOpenTime, 0) --配置0000(时分)
    local tDate = os.date("*t", os.time())
    if nOpenTime >= 2400 then
        tDate.hour = 23
        tDate.min = 59
        tDate.sec = 59
    else
        tDate.hour = math.floor(nOpenTime / 100)
        tDate.min = math.floor(nOpenTime % 100)
        tDate.sec = 0
    end
   return os.MakeTime(tDate.year, tDate.month, tDate.day, tDate.hour, tDate.min, tDate.sec) 
end

--获取当天的活动结束时间
function CDailyActivity:GetEndStamp(nActID)
    local tConf = ctDailyActivity[nActID]
    local nCloseTime = math.max(tConf.nCloseTime, 0) --配置0000(时分)
    local tDate = os.date("*t", os.time())
    if nCloseTime >= 2400 then --策划某些结束时间喜欢配置成2400
        tDate.hour = 23
        tDate.min = 59
        tDate.sec = 59
    else
        tDate.hour = math.floor(nCloseTime / 100)
        tDate.min = math.floor(nCloseTime % 100)
        tDate.sec = 0
    end
   return os.MakeTime(tDate.year, tDate.month, tDate.day, tDate.hour, tDate.min, tDate.sec) 
end

function CDailyActivity:CheckCanJoinAct(nActID)
    --机器人都允许通过
    if self.m_oRole:IsRobot() then
        return true
    end
    
    --检查今天是否已经完成
    if self.m_tActDataMap[nActID] then
        local bIsComp = self.m_tActDataMap[nActID][gtDailyData.eIsComp]
        local bCanJoinContinues = ctDailyActivity[nActID].bCanJoinContinues
        if bIsComp and not bCanJoinContinues then
            return false
        end
    end

    -- --检查等级
    -- assert(ctDailyActivity[nActID], "没有该日程活动配置")
    -- if self.m_oRole:GetLevel() < ctDailyActivity[nActID].nLevelLimit then
    --     return false
    -- end

    -- --检查开启条件
    -- local nOpenType = ctDailyActivity[nActID].nOpenType
    -- if nOpenType == gtDailyActOpenType.eServerLevel then
    --     if goServerMgr:GetServerLevel(self.m_oRole:GetServer()) < ctDailyActivity[nActID].nOpenLimit then
    --         return false
    --     end
    -- end

    --检查开放系统中是否开放
    local nSysOpenID = ctDailyActivity[nActID].nSysOpenID
    if not self.m_oRole.m_oSysOpen:IsSysOpen(nSysOpenID) then
        return false
    end


    if not self.m_tHandleFunc[nActID] then 
        return false
    end

    --检查开启时间
    return self:CheckOpenTime(nActID)
end

--整时计时器作数据清空
function CDailyActivity:OnHourTimer()
   if not os.IsSameDay(self.m_nLastResetTimeStamp, os.time()) then
        self:ResetData()
  end
   self:CheckAndSetStatus()
end

function CDailyActivity:OnSysOpen()
    self:CheckAndSetStatus()
end

--整分计时器只做活动开启检查
function CDailyActivity:OnMinTimer()
    self:CheckAndSetStatus()
end

function CDailyActivity:GetRecData(nActID)
    return self.m_tActDataMap[nActID]
end

function CDailyActivity:SetTarBattleDupType(nType)
    if nType then
        if not self.m_nTarBattleDupType or (self.m_nTarBattleDupType ~= nType) then 
            self.m_nTarBattleDupType = nType
            self:MarkDirty(true)
        end
    end
end

function CDailyActivity:GetTarBattleDupType()
    return self.m_nTarBattleDupType
end

function CDailyActivity:JoinZhenYao()
    if not self:CheckCanJoinAct(gtDailyID.eZhenYao) then
        return self.m_oRole:Tips("未达参加活动所需条件")
    end
    goBattleDupMgr:EnterBattleDupReq(self.m_oRole, gtBattleDupType.eZhenYao)
    self:MarkDirty(true)
end

function CDailyActivity:JoinShenMoZhi()
   if not self:CheckCanJoinAct(gtDailyID.eShenMoZhi) then
        return self.m_oRole:Tips("未达参加活动所需条件")
    end
    goBattleDupMgr:EnterBattleDupReq(self.m_oRole, gtBattleDupType.eShenMoZhi)
    self:MarkDirty(true) 
end

function CDailyActivity:JoinLuanShiYaoMo()
    if not self:CheckCanJoinAct(gtDailyID.eLuanShiYaoMo) then
        return self.m_oRole:Tips("未达参加活动所需条件")
    end
    goBattleDupMgr:EnterBattleDupReq(self.m_oRole, gtBattleDupType.eLuanShiYaoMo)
    self:MarkDirty(true)
end

function CDailyActivity:JoinXinMoQinShi()
    if not self:CheckCanJoinAct(gtDailyID.eXinMoQinShi) then
        return self.m_oRole:Tips("未达参加活动所需条件")
    end
    goBattleDupMgr:EnterBattleDupReq(self.m_oRole, gtBattleDupType.eXinMoQinShi)
    self:MarkDirty(true)
end

--后端 #5675
-- 前端 #5488: 【神兽乐园】神兽乐园入口修改（同步所有项目）
-- function CDailyActivity:JoinShenShouLeYuan()
--     if not self:CheckCanJoinAct(gtDailyID.eShenShouLeYuan) then
--         return self.m_oRole:Tips("未达参加活动所需条件")
--     end

--     goBattleDupMgr:EnterBattleDupReq(self.m_oRole, gtBattleDupType.eShenShouLeYuan)
-- end

function CDailyActivity:JoinJueZhanJiuXiao()
  -- if not self:CheckCanJoinAct(gtDailyID.eJueZhanJiuXiao) and goPVEActivityMgr.m_nCurrOpenActID == 0 then
  --       return self.m_oRole:Tips("未达参加活动所需条件")
  -- end
    goBattleDupMgr:EnterBattleDupReq(self.m_oRole, gtBattleDupType.eJueZhanJiuXiao)
end

function CDailyActivity:JoinCHunDunShiLian()
    --  if not self:CheckCanJoinAct(gtDailyID.eHunDunShiLian) then
    --     return self.m_oRole:Tips("未达参加活动所需条件")
    -- end
    goBattleDupMgr:EnterBattleDupReq(self.m_oRole, gtBattleDupType.eHunDunShiLian)
end

function CDailyActivity:JoinCMengZhuWuShuang()
     if not self:CheckCanJoinAct(gtDailyID.eMengZhuWuShuang) then
        return self.m_oRole:Tips("未达参加活动所需条件")
    end
    goBattleDupMgr:EnterBattleDupReq(self.m_oRole, gtBattleDupType.eMengZhuWuShuang)
end

function CDailyActivity:AccpShiMenTask()
    self.m_oRole.m_oShiMenTask:AccepteTask()
end

function CDailyActivity:JoinBaHuangHuoZhen()
     if not self:CheckCanJoinAct(gtDailyID.eBaHuangHuoZhen) then
        return self.m_oRole:Tips("未达参加活动所需条件")
    end
    --self.m_oRole.m_oBaHuangHuoZhen:TaskInfoReq()
end

function CDailyActivity:JoinSchoolArenaActivity()
    goPVPActivityMgr:EnterReq(self.m_oRole, gtDailyID.eSchoolArena) --和活动表同ID
end
function CDailyActivity:JoinQimaiArenaActivity()
    goPVPActivityMgr:EnterReq(self.m_oRole, gtDailyID.eQimaiArena)
end

function CDailyActivity:JoinQingyunBattleActivity()
    goPVPActivityMgr:EnterReq(self.m_oRole, gtDailyID.eQingyunBattle)
end

function CDailyActivity:JoinUnionArenaActivity()
    goPVPActivityMgr:EnterReq(self.m_oRole,gtDailyID.eUnionArena)
end

function CDailyActivity:JoinYaoShouTuXi()
    self.m_oRole.m_oYaoShouTuXi:JoinYaoShouTuXi()
end

function CDailyActivity:JoinKeJu(nKejuType)
    local nDialyType
    if nKejuType == 1 then
        nDialyType = 111
    elseif nKejuType == 2 then
        nDialyType = 112
    elseif nKejuType == 3 then
        nDialyType = 113
    end
   if not self:CheckCanJoinAct(nDialyType) then
        return self.m_oRole:Tips("未达参加活动所需条件")
    end
    self.m_oRole.m_oKeju:JoinKeJu(nKejuType)
end