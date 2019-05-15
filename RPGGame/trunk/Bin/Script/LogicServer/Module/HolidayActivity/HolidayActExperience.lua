--江湖历练
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

gtExperienceType = 
{
    eTalk = 1,
    eBattle = 2,
    eGather = 3,
    eCommit = 4,
}

gtExpeGatherState = 
{
    eBegin = 1,
    eEnd = 2
}

function CHolidayActExperience:Ctor(oRole, nActID, nActType)
    self.m_oRole = oRole
    CHolidayActivityBase.Ctor(self, nActID, nActType)

    self.m_nGatherStartTimeStamp = 0
end

function CHolidayActExperience:GetHolidayActData()
    return self.m_oRole.m_oHolidayActMgr.m_tActData
end

function CHolidayActExperience:CheckCanJoin()
    --能参加条件已开启，等级足够，次数未用完
    local bIsActBegin = self:GetActIsBegin()
    --print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>江湖历练关闭时间"..os.date("%c",self.m_nEndTimestamp))
    --print(">>>>>>>>>>>>>>>>>>>>>>>>江湖历练活动是否开启: "..tostring(bIsActBegin))
    local bLevelEnouht = self.m_oRole:GetLevel() >= ctHolidayActivityConf[self.m_nActID].nLevelLimit
    local tData = self:GetHolidayActData()
    local nMaxHuanshu = ctExperienceConf[1].nMaxHuanshu
    local bOldStatus = self.m_bCanJoin
    if bIsActBegin and bLevelEnouht and tData.nExperCompTimes < nMaxHuanshu then
        local bNewStatus = true
        if bOldStatus ~= bNewStatus then
            self.m_bCanJoin = bNewStatus
            self:OnActStart()
            self:SendActStatusInfo()  
        end
    else
        local bNewStatus = false
        if bOldStatus ~= bNewStatus then
            self.m_bCanJoin = bNewStatus
            self:SendActStatusInfo()            
        end
    end
end

function CHolidayActExperience:OnActStart()
    local tData = self:GetHolidayActData()
    if tData.nExperEndTimestamp > 0 and os.time() >= tData.nExperEndTimestamp then
        self:ClearData()
    end
end

function CHolidayActExperience:RandItem()
    local function GetItemWeight(tNode)
        return tNode.nWeight
    end
    local tItemList = CWeightRandom:Random(ctExpeCommItemConf, GetItemWeight, 1, false)
    return {tItemList[1].nItemID, tItemList[1].nNeedNum}
end

function CHolidayActExperience:SelectAndSetTask()
    local tData = self:GetHolidayActData()
    local function GetTaskWeight()
        return 1
    end
    local tTaskList = CWeightRandom:Random(ctExperienceTaskConf, GetTaskWeight, 1, false)
    tData.nExperTaskID = tTaskList[1].nTaskID

    local nTaskType = ctExperienceTaskConf[tData.nExperTaskID].nTaskType
    if nTaskType == gtExperienceType.eCommit then
        local tItem = self:RandItem()
        tData.nExperTaskItemID = tItem[1]
        tData.nExperTaskCommNum = tItem[2]
    else
        local function GetPosWeight()
            return 100
        end
        local tPosConf = ctRandomPoint.GetPool(ctExperienceTaskConf[tData.nExperTaskID].nRandPosType, self.m_oRole:GetLevel())
        local tResult = CWeightRandom:Random(tPosConf, GetPosWeight, 1, false)
        tData.nExperTaskDupID = tResult[1].nDupID
        tData.nExperTaskPosX = tResult[1].tPos[1][1]
        tData.nExperTaskPosY = tResult[1].tPos[1][2]
    end
    self:SendTaskInfo()    
end

function CHolidayActExperience:AcceptTaskReq()
    local tData = self:GetHolidayActData()
    if tData.nExperCompTimes >= ctExperienceConf[1].nMaxHuanshu then
        return self.m_oRole:Tips("今天江湖历练次数已达到上限")
    end

    self:SelectAndSetTask()
    --发送消息
end

function CHolidayActExperience:CheckPos(nPosX, nPosY)
    assert(nDupID and nPosX and nPosY, "判断位置参数有误")
    local tData = self:GetHolidayActData()
    local nCurrDupID = self.m_oRole:GetDupID()
    if nCurrDupID ~= tData.nExperTaskDupID then
        self.m_oRole:Tips("不在任务目标场景")
        return false
    end
    local nRolePosX, nRolePosY = self.m_oRole:GetPos()
    local nDisX = math.abs(nRolePosX - tData.nExperTaskPosX)
    local nDisY = math.abs(nRolePosY - tData.nExperTaskPosY)        
    if nDisX^2 + nDisY^2 > 100^2 then
        self.m_oRole:Tips("位置不正确"..nRolePosX .. nRolePosY)
        return false
    end
    return true
end

function CHolidayActExperience:CommitTaskReq(nItemID, nState)
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>提交任务"..nItemID.."      "..nState)
    local tData = self:GetHolidayActData()
    assert(ctExperienceTaskConf[tData.nExperTaskID], "江湖历练提交任务参数错误")
    local tTaskConf = ctExperienceTaskConf[tData.nExperTaskID]
    local nTaskType = tTaskConf.nTaskType
    if gtExperienceType.eGather == nTaskType then
        assert(1<=nState and nState<=2, "江湖历练提交任务状态参数错误")
    end

    if gtExperienceType.eTalk == nTaskType then
        --if not self:CheckPos() then return end
        self:CompTaskReward()
        self:SelectAndSetTask()

    elseif gtExperienceType.eBattle == nTaskType then
        --if not self:CheckPos() then return end
        local nMonsterID = tTaskConf.nMonsterID
        local oMonster = goMonsterMgr:CreateInvisibleMonster(nMonsterID)
        self.m_oRole:PVE(oMonster, {bJiangHuLiLian=true})

    elseif gtExperienceType.eGather == nTaskType then 
        --if not self:CheckPos() then return end
        if gtExpeGatherState.eBegin == nState then
            self.m_nGatherStartTimeStamp = os.time()

        elseif gtExpeGatherState.eEnd == nState then
            local nGatherTime = ctExperienceTaskConf[tData.nExperTaskID].nTimeLimit
            -- if os.time() < self.m_nGatherStartTimeStamp or os.time() >= self.m_nGatherStartTimeStamp+nGatherTime*2 then
            --     return self.m_oRole:Tips("采集时间非法，请重新采集")
            -- end
            self:CompTaskReward()
            self:SelectAndSetTask()
        end

    elseif gtExperienceType.eCommit == nTaskType then
        --if not self:CheckPos() then return end
        --检查提交的物品是否是同一种类型,子类型的
        assert(ctPropConf[tData.nExperTaskItemID], "需要提交的物品不存在")
        local nNeedType = ctPropConf[tData.nExperTaskItemID].nType
        local nNeedSubType = ctPropConf[tData.nExperTaskItemID].nSubType
        local nItemType = ctPropConf[nItemID].nType
        local nItemSubType = ctPropConf[nItemID].nSubType
        if nNeedType ~= nItemType and nNeedSubType ~= nItemSubType then 
            return self.m_oRole:Tips("提交的物品不符合")
        end

        local oItem = self.m_oRole.m_oKnapsack:GetItemByPropID(nItemID)
        if not oItem then
            return self.m_oRole:Tips("背包没有该物品")
        end
        local bSucc = self.m_oRole:CheckSubItem(gtItemType.eProp, nItemID, 1, "任务扣除")
        if not bSucc then
            self.m_oRole:Tips(string.format("%s不足", CKnapsack:PropName(nTaskItemID)))
            return
        end
        self:CompTaskReward()
        self:SelectAndSetTask()
    end
end

function CHolidayActExperience:OnBattleEnd(bIsRoleWin)
    if bIsRoleWin then
        self:CompTaskReward()
        self:SelectAndSetTask()
    end
end

function CHolidayActExperience:CompTaskReward()
    local tData = self:GetHolidayActData()
    local nRoleLevel = self.m_oRole:GetLevel()
    local nHuanshu = tData.nExperCompTimes + 1
    local fnRoleExp = ctExperienceTaskConf[tData.nExperTaskID].fnRoleExp
    local fnPetExp = ctExperienceTaskConf[tData.nExperTaskID].fnPetExp
    local fnYinBi = ctExperienceTaskConf[tData.nExperTaskID].fnYinBi
    local nRoleExp = fnRoleExp(nRoleLevel, nHuanshu)
    local nPetExp = fnPetExp(nRoleLevel, nHuanshu)
    local nYinBi = fnYinBi(nHuanshu, nRoleLevel)
    local tRewardItem = ctExperienceTaskConf[tData.nExperTaskID].tRewardItem
    self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleExp, "江湖历练奖励")
    self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nPetExp, "江湖历练奖励")
    self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nYinBi, "江湖历练奖励")
    self.m_oRole:AddItem(gtItemType.eProp, tRewardItem[1][1], tRewardItem[1][2], "江湖历练奖励")    
    if nHuanshu == ctExperienceConf[1].nMaxHuanshu then
        local tExtraReward = ctExperienceConf[1].tExtraReward
        local tPool = ctAwardPoolConf.GetPool(tExtraReward[1], nRoleLevel)
        local function GetItemWeight(tNode)
            return tNode.nWeight
        end
        local tItemList = CWeightRandom:Random(tPool, GetItemWeight, tExtraReward[2], true)
        for _, tConf in pairs(tItemList) do
            self.m_oRole:AddItem(gtItemType.eProp, tConf.nItemID, tConf.nItemNum, "江湖历练奖励")
        end
    end
    tData.nExperCompTimes = tData.nExperCompTimes + 1
end

function CHolidayActExperience:ClearData()
    nExperCompTimes = 0
    nExperTaskID = 0
    nExperEndTimestamp = 0
    nExperTaskDupID = 0
    nExperTaskPosX = 0
    nExperTaskPosY = 0
end

function CHolidayActExperience:OnMinTimer()
    CHolidayActivityBase.OnMinTimer(self)
    self:CheckCanJoin()
end

function CHolidayActExperience:Online()
    self:CheckCanJoin()
end

function CHolidayActExperience:GetActStatusInfo()
    local tData = self:GetHolidayActData()
    local tActInfo = {}
    tActInfo.nActivityID = self.m_nActID
    tActInfo.nTodayCompTimes = tData.nExperCompTimes
    tActInfo.nTotalTimes = ctHolidayActivityConf[self.m_nActID].nCanJoinTimes
    tActInfo.bCanJoin = self:GetCanJoin()
    tActInfo.bIsComp = tData.nExperCompTimes >= ctExperienceConf[1].nMaxHuanshu
    tActInfo.bIsEnd = os.time() >= self:GetEndTimestamp()
    return tActInfo
end

function CHolidayActExperience:SendActStatusInfo()
    local tMsg = {tActSingleInfo = {}}    
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>活动状态信息")
    --PrintTable(self:GetActStatusInfo())
    local tActInfo = self:GetActStatusInfo()
    tMsg.tActSingleInfo.nActivityID = tActInfo.nActivityID
    tMsg.tActSingleInfo.nTodayCompTimes = tActInfo.nTodayCompTimes
    tMsg.tActSingleInfo.nTotalTimes = tActInfo.nTotalTimes
    tMsg.tActSingleInfo.bCanJoin = tActInfo.bCanJoin
    tMsg.tActSingleInfo.bIsComp = tActInfo.bIsComp
    tMsg.tActSingleInfo.bIsEnd = tActInfo.bIsEnd
    self.m_oRole:SendMsg("HolidayActSingleInfoRet", tMsg)
    --lkx todo 发信息
    --PrintTable(tMsg)
end

function CHolidayActExperience:SendTaskInfo()
    local tData = self:GetHolidayActData()
    local tMsg = {}
    tMsg.nMsgType = 2
	tMsg.bComplete = tData.nExperCompTimes >= ctExperienceConf[1].nMaxHuanshu
	tMsg.nTotalComplete = tData.nExperCompTimes
	tMsg.nTaskID = tData.nExperTaskID
	tMsg.nTaskDupID = tData.nExperTaskDupID
	tMsg.nTaskPosX = tData.nExperTaskPosX
    tMsg.nTaskPosY = tData.nExperTaskPosY
    tMsg.nParam1 = tData.nExperTaskItemID
    tMsg.nParam2 = tData.nExperTaskCommNum
    self.m_oRole:SendMsg("ExperienceTaskRet", tMsg)
    --print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>江湖历练任务信息")
    --PrintTable(tMsg)
end