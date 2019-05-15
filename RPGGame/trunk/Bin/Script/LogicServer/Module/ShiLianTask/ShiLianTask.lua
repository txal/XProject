--试炼任务
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nShiLianSysOpenID = 56
CShiLianTask.Type = 
{
    eSearch = 1,            --寻人
    eChalleng = 2,          --挑战
    eCommit = 3,            --提交
}

function CShiLianTask:Ctor(oRole)
    self.m_oRole = oRole
    self.m_nCompTimes = 0               --完成次数
    self.m_nTaskID = 0
    self.m_nChuanShuoTimeStamp = 0      --传说有效时间戳
    self.m_bWasDrop = false             --传说时间内是否掉落了要求提交的物品
    self.m_nLastResetTimeStamp = 0
    self.m_nCommitItemID = 0              --要提交物品ID
    self.m_bIsItemSet = false             --提交的物品是否是集合
    self.m_nCommitNum = 0
    self.m_nItemSetID = 0                 --集合组ID

    --不保存
    self.m_tWeight = {}         --{{nType, nWeight}}
    self:InitWeight()
end

function CShiLianTask:LoadData(tData)
    if tData then
        self.m_nCompTimes = tData.m_nCompTimes or 0
        self.m_nTaskID = tData.m_nTaskID or 0
        self.m_nChuanShuoTimeStamp = tData.m_nChuanShuoTimeStamp or 0
        self.m_bWasDrop = tData.m_bWasDrop or false
        self.m_nLastResetTimeStamp = tData.m_nLastResetTimeStamp or self.m_nLastResetTimeStamp
        self.m_nCommitItemID = tData.m_nCommitItemID or 0
        self.m_bIsItemSet = tData.m_bIsItemSet or false
        self.m_nCommitNum = tData.m_nCommitNum or 0
        self.m_nItemSetID = tData.m_nItemSetID or self.m_nItemSetID
    end
    if self.m_nLastResetTimeStamp <= 0 then
        self.m_nLastResetTimeStamp = os.time()
        self:MarkDirty(true)
    end
    -- print(">>>>>>>>>>>>试炼任务数据库数据")
    -- PrintTable(tData)
end

function CShiLianTask:SaveData()
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)

    local tData = {}
    tData.m_nCompTimes = self.m_nCompTimes
    tData.m_nTaskID = self.m_nTaskID
    tData.m_nChuanShuoTimeStamp = self.m_nChuanShuoTimeStamp
    tData.m_bWasDrop = self.m_bWasDrop
    tData.m_nLastResetTimeStamp = self.m_nLastResetTimeStamp
    tData.m_nCommitItemID = self.m_nCommitItemID
    tData.m_bIsItemSet = self.m_bIsItemSet
    tData.m_nCommitNum = self.m_nCommitNum
    tData.m_nItemSetID = self.m_nItemSetID
    return tData
end

function CShiLianTask:GetType()
    return gtModuleDef.tShiLianTask.nID, gtModuleDef.tShiLianTask.sName
end

function CShiLianTask:InitWeight()
    table.insert(self.m_tWeight, {CShiLianTask.Type.eSearch, ctShiLianOtherConf[1].nSearchWeight})
    table.insert(self.m_tWeight, {CShiLianTask.Type.eChalleng, ctShiLianOtherConf[1].nChallWeight})
    table.insert(self.m_tWeight, {CShiLianTask.Type.eCommit, ctShiLianOtherConf[1].nCommitWeight})        
end

function CShiLianTask:SetCurrTask(nTaskID)
    self.m_nTaskID = nTaskID
    local nTaskType = ctShiLianTaskConf[nTaskID] and ctShiLianTaskConf[nTaskID].nTaskType or 0
    if nTaskType == CShiLianTask.Type.eCommit then
        local nChuanShuoTime = ctShiLianOtherConf[1].nChuanShuoTime
        self.m_nChuanShuoTimeStamp = os.time() + nChuanShuoTime*60
        self:SetWasDrop(false)
    end
    self:MarkDirty(true)
end

function CShiLianTask:AddCompTimes(nAdd)
    if nAdd == 0 then return end
    self.m_nCompTimes = math.max(0, math.min(gnMaxInteger, self.m_nCompTimes+nAdd))
    self:MarkDirty(true)
end

function CShiLianTask:SetWasDrop(nWasDrop)
    self.m_bWasDrop = nWasDrop
end

function CShiLianTask:TaskAccepReq()
    if self.m_nTaskID > 0 then
        return self.m_oRole:Tips("已领取了任务")
    end
    if self.m_nCompTimes >= ctShiLianOtherConf[1].nMaxTimes then
        return self.m_oRole:Tips("已完成所有试炼任务")        
    end

    -- local nServerLevel = goServerMgr:GetServerLevel(self.m_oRole:GetServer())
    -- local nRoleLevel = self.m_oRole:GetLevel()
    -- local tConf = ctDailyActivity[gtDailyID.eShiLianTask]
    -- local bServerLevelPermit = nServerLevel >= tConf.nOpenLimit
    -- local bRoleLevelPermit = nRoleLevel >= tConf.nLevelLimit
    -- if not bServerLevelPermit or not bRoleLevelPermit then
    --     if not bServerLevelPermit then
    --         return self.m_oRole:Tips("未达到服务器开放等级")
    --     end
    --     if bServerLevelPermit and not bRoleLevelPermit then
    --         return self.m_oRole:Tips("领取试炼需要人物等级达到"..tConf.nLevelLimit.."级")
    --     end
    -- end

    if not self.m_oRole.m_oSysOpen:IsSysOpen(nShiLianSysOpenID, true) then
        -- return self.m_oRole:Tips("该功能未开放")
        return
    end    

    local nCostItemID = ctShiLianOtherConf[1].nCostItemID
    local nAcceptCost = ctShiLianOtherConf[1].nAcceptCost
    local bCostSucc = self.m_oRole:CheckSubShowNotEnoughTips({{gtItemType.eCurr, gtCurrType.eYinBi, nAcceptCost}}, "接取试炼任务消耗", true, false)
    if not bCostSucc then return end 
    local nTaskID = self:RandTask()
    self:SetCurrTask(nTaskID)
    self:MarkDirty(true)
    self:SendTaskInfo()
end

function CShiLianTask:TaskCommitReq(nNpcID, nItemID, nCommitNum, nGridID, bUseJinBi)
    if self.m_nTaskID <= 0 then
         return self.m_oRole:Tips("没有要提交的任务") 
    end
    local tConf = ctShiLianTaskConf[self.m_nTaskID]

    if bUseJinBi and tConf.nTaskType ~= CShiLianTask.Type.eChalleng then
        return self.m_oRole:Tips("战斗任务方可任性一下")
    end

    if bUseJinBi and tConf.nTaskType == CShiLianTask.Type.eChalleng then       --使用金币跳过任务
        local nCostJinBi = ctShiLianOtherConf[1].fnAutoCompCost(self.m_nCompTimes)
        local sTips = string.format("您是否需要花费%d金币跳过该环任务？", nCostJinBi)
        local tMsg = {sCont=sTips, tOption={"取消", "确定"}, nTimeOut=30}
        goClientCall:CallWait("ConfirmRet", function(tData)
            if tData.nSelIdx == 1 then
                return
            elseif tData.nSelIdx == 2 then
                local bCostSucc = self.m_oRole:CheckSubShowNotEnoughTips({{gtItemType.eCurr, gtCurrType.eJinBi, nCostJinBi}}, "试炼任务任性一下", true, false)
                if bCostSucc then
                    self:OnTaskComplete()
                else
                    return
                end
            end
        end, self.m_oRole, tMsg)        

    else                    --正常流程完成任务
        if nNpcID ~= tConf.nNpcID then
            return self.m_oRole:Tips("试炼任务提交NPC错误" ..nNpcID)
        end
        
        if tConf.nTaskType == CShiLianTask.Type.eSearch then
            self:OnTaskComplete()

        elseif tConf.nTaskType == CShiLianTask.Type.eChalleng then
            local oMonster = goMonsterMgr:CreateInvisibleMonster(tConf.nMonsterID)
            if not oMonster  then return end
            self.m_oRole:PVE(oMonster, {bShiLian=true, nAddAttrModType=gtAddAttrModType.eShiLianTask, nBattleDupType = gtBattleType.eShiLianTask})

        elseif tConf.nTaskType == CShiLianTask.Type.eCommit then
            if not self:CommitTaksItem(nItemID, nCommitNum, nGridID) then return end
            self:OnTaskComplete()
        end
    end
end

function CShiLianTask:OnBattleEnd(bIsRoleWin)
    if bIsRoleWin then
        self:OnTaskComplete()
    end
end

function CShiLianTask:OnTaskComplete()
    self:AddCompTimes(1)
    self:Reward()
    self:SetCurrTask(self:RandTask())
    self:SendTaskInfo()
end

function CShiLianTask:RandTask()
    --抽任务类型
    if self.m_nCompTimes >= ctShiLianOtherConf[1].nMaxTimes then
        return 0
    end
    --local tConf = ctShiLianTaskConf[self.m_nTaskID]
    local function GetTaskTypeWeight(tConf)
        return tConf[2]
    end
    local tRandTaskType = CWeightRandom:Random(self.m_tWeight, GetTaskTypeWeight, 1, false)

    --抽任务
    local nTaskType = tRandTaskType[1][1]
    local tTaskPool = ctShiLianTaskConf.GetPool(nTaskType, self.m_oRole:GetLevel())
    assert(next(tTaskPool), "试炼任务等级匹配任务为空")
    local function GetTaskWeight(tTaskConf)
        return tTaskConf.nTaskWeight
    end
    local tTaskList = CWeightRandom:Random(tTaskPool, GetTaskWeight, 1, false)

    --如果任务类型是提交物品，随机出要提交的物品
    if nTaskType == CShiLianTask.Type.eCommit then
        --随机提交物品的序列
        local tSeqList = ctShiLianTaskConf[tTaskList[1].nTaskID].tCommitItem
        local function GetSeqWeight()
            return 1
        end
        local tCommitItemList = CWeightRandom:Random(tSeqList, GetSeqWeight, 1, false)
        local nSeq = tCommitItemList[1][1]
        self.m_nItemSetID = nSeq
        self.m_bIsItemSet = ctItemStaticGroup[nSeq].bGather

        --随机提交的物品(物品集合或固定单一物品)
        local tItemList = ctItemStaticGroup[nSeq].tItemConditionStr
        local function GetItemWeight()
            return 1
        end
        local tRandItemList =  CWeightRandom:Random(tItemList, GetItemWeight, 1, false)
        self.m_nCommitItemID = tRandItemList[1][1]
        self.m_nCommitNum = tRandItemList[1][2]
        self:MarkDirty(true)
    end
    assert(tTaskList[1].nTaskID, "试炼任务ID有误")
    return tTaskList[1].nTaskID
end

function CShiLianTask:Reward()
    if self.m_nCompTimes <= 0 then return end
    local tRewardList = {}
    local fnRoleExp = ctShiLianOtherConf[1].fnRoleExp
    local nRoleLevel = self.m_oRole:GetLevel()
    local nTemp = self.m_nCompTimes % 10
    local nHuanShu = nTemp ~= 0 and nTemp or 10  --当10的倍数时设置为10
    local nRoleExp = fnRoleExp(self.m_nCompTimes, nRoleLevel, nHuanShu)
    self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleExp, "试炼任务奖励")
    table.insert(tRewardList, {gtCurrType.eExp, nRoleExp})

    local nAwardPoolID = 0
    local nRewardNum = 0
    local tConf = ctShiLianOtherConf[1]
    if self.m_nCompTimes == tConf.nCompTimesA then
        nAwardPoolID = tConf.tRewardCompTimesA[1][1]
        nRewardNum = tConf.tRewardCompTimesA[1][2]

    elseif self.m_nCompTimes == tConf.nCompTimesB then
        nAwardPoolID = tConf.tRewardCompTimesB[1][1]
        nRewardNum = tConf.tRewardCompTimesB[1][2]
    end

    if nAwardPoolID > 0 then
        local tRewardPool = ctAwardPoolConf.GetPool(nAwardPoolID, nRoleLevel, self.m_oRole:GetConfID())
        local function GetItemWeight(tConf)
            return tConf.nWeight
        end
        local tRewardItemList = CWeightRandom:Random(tRewardPool, GetItemWeight, nRewardNum, false)
        for nIndex, tReward in pairs(tRewardItemList) do
            self.m_oRole:AddItem(gtItemType.eProp, tReward.nItemID, tReward.nItemNum, "试炼任务奖励")
            table.insert(tRewardList, {tReward.nItemID, tReward.nItemNum})
        end
    end
    self:SendRewardInfo(tRewardList)
    goLogger:EventLog(gtEvent.eCompShiLian, self.m_oRole,  self.m_nTaskID, self.m_nCompTimes)
end

function CShiLianTask:CommitTaksItem(nCommitItemID, nCommitNum, nGridID)
    if nCommitNum < self.m_nCommitNum then
        return self.m_oRole:Tips("提交数量不足")
    end
    local tPropInfo = self.m_oRole.m_oKnapsack:GetItemData(nGridID)
    local nItemID = tPropInfo.m_nID
    assert(ctPropConf[self.m_nCommitItemID], "需要提交的物品不存在")
    assert(ctPropConf[nItemID], "提交的物品不存在")    
    local bCanCommit = false
    if self.m_bIsItemSet then
        for nKey, tItemIDList in pairs(ctItemCategory[self.m_nCommitItemID].tItemStr) do
            if tItemIDList[1] == nItemID then
                bCanCommit = true
            end
        end
    else
        if nItemID == self.m_nCommitItemID then
            bCanCommit = true
        end
    end
    if not bCanCommit then
        return self.m_oRole:Tips("提交的物品不符合")
    end
    local bRet = self.m_oRole.m_oKnapsack:SubGridItem(nGridID, nItemID, self.m_nCommitNum, "试炼任务提交物品")
    if bRet then
        self.m_bIsItemSet = false
        self.m_nCommitItemID = 0
        self.m_nCommitNum = 0
        self.m_nItemSetID = 0
        self.m_nTaskID = 0
        self:MarkDirty(true)
    end
    return bRet
end

function CShiLianTask:OnHourTimer()
    if not os.IsSameWeek(self.m_nLastResetTimeStamp, os.time(), 0) then
        self.m_nCompTimes = 0
        self.m_nTaskID = 0
        self.m_nChuanShuoTimeStamp = 0
        self.m_bWasDrop = false
        self.m_nLastResetTimeStamp = os.time()
        self:MarkDirty(true)
        self:SendTaskInfo()
    end
end

function CShiLianTask:Online()
    if not os.IsSameWeek(self.m_nLastResetTimeStamp, os.time(), 0) then
        self.m_nCompTimes = 0
        self.m_nTaskID = 0
        self.m_nLastResetTimeStamp = os.time()
        self:MarkDirty(true)
        self.m_nChuanShuoTimeStamp = 0
        self.m_bWasDrop = false
    end

    -- local nServerLevel = goServerMgr:GetServerLevel(self.m_oRole:GetServer())
    -- local nRoleLevel = self.m_oRole:GetLevel()
    -- local tConf = ctDailyActivity[gtDailyID.eShiLianTask]
    -- if nServerLevel >= tConf.nOpenLimit and nRoleLevel >= tConf.nLevelLimit then
    --     self:SendTaskInfo()        
    -- end

    if self.m_oRole.m_oSysOpen:IsSysOpen(nShiLianSysOpenID) then
        --删除配置后如果没有该任务重新随机
        if self.m_nTaskID > 0 and not ctShiLianTaskConf[self.m_nTaskID] then
            local nTaskID = self:RandTask()
            self:SetCurrTask(nTaskID)
        end
        self:SendTaskInfo() 
    end 
end

function CShiLianTask:OnLevelChange(nNewLevel)
    -- local nServerLevel = goServerMgr:GetServerLevel(self.m_oRole:GetServer())
    -- local nRoleLevel = self.m_oRole:GetLevel()
    -- local tConf = ctDailyActivity[gtDailyID.eShiLianTask]
    -- if nServerLevel >= tConf.nOpenLimit and nRoleLevel >= tConf.nLevelLimit then
    --     self:SendTaskInfo()        
    -- end
    if self.m_oRole.m_oSysOpen:IsSysOpen(nShiLianSysOpenID) then
        self:SendTaskInfo() 
    end 
end

function CShiLianTask:SendTaskInfo()
    local tMsg = {}
    local tConf = ctShiLianTaskConf[self.m_nTaskID] or {}
    --print(">>>>>>>>>>>shilianID"..self.m_nTaskID)
    local bCommitTask = tConf.nTaskType == CShiLianTask.Type.eCommit or false
    tMsg.nTaskType = tConf.nTaskType or 0
    tMsg.nNpcID = tConf.nNpcID or 0
    tMsg.nCompleteTimes = self.m_nCompTimes
    tMsg.nItmeID = bCommitTask and self.m_nCommitItemID or 0
    tMsg.nItemNum = bCommitTask and self.m_nCommitNum or 0
    tMsg.bIsItemSet = bCommitTask and self.m_bIsItemSet or false
    if ctItemStaticGroup[self.m_nItemSetID] then
        tMsg.nJumpType = ctItemStaticGroup[self.m_nItemSetID].nJump
    end
    tMsg.nChuanShuoTimeStamp = self.m_nChuanShuoTimeStamp
    self.m_oRole:SendMsg("ShiLianTaskInfoRet", tMsg)
    -- print(">>>>>>>>>>>>>>>>>>>>>试炼任务")
    --PrintTable(tMsg)
end

function CShiLianTask:SendRewardInfo(tRewardList)
    local tMsg = { tRewardList = {} }
    for _, tReward in pairs(tRewardList) do
        local tRewardSingle = {}
        tRewardSingle.nItemID = tReward[1]
        tRewardSingle.nItemNum = tReward[2]
        table.insert(tMsg.tRewardList, tRewardSingle)
    end
    self.m_oRole:SendMsg("ShiLianRewardRet", tMsg)

end

function CShiLianTask:GetCommitItem()
    local tItemList = {}
    if self.m_nTaskID == 0 then return tItemList end
    local tConf = ctShiLianTaskConf[self.m_nTaskID]
    if tConf.nTaskType == CShiLianTask.Type.eCommit then
        if self.m_bIsItemSet then
            for nKey, tItem in pairs(ctItemCategory[self.m_nCommitItemID].tItemStr) do
                if ctPropConf[tItem[1]] and ctBourseItem[tItem[1]] then
                    tItemList[tItem[1]] = (tItemList[tItem[1]] or 0) + self.m_nCommitNum
                end
            end
        else
            if ctPropConf[self.m_nCommitItemID] and ctBourseItem[self.m_nCommitItemID] then
                tItemList[self.m_nCommitItemID] = (tItemList[self.m_nCommitItemID] or 0) + self.m_nCommitNum
            end
        end
    end
    return tItemList
end
