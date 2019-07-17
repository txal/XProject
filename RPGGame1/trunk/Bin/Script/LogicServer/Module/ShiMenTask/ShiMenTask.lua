--师门任务
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nShiMenSysOpenID = 2      --开放系统中师门系统ID为2
CShiMenTask.tTaskType =         --任务类型
{
    eXunZhao = 0,               --寻找师傅
    eSongXin = 1,
    eZhiDao = 2,
    eWuZi = 3,
    eXiuShan = 4,
}

CShiMenTask.tItemType =         --物资任务物品类型
{
    eYaoPin = 1,
    ePengRen = 2,
    eZhenBao = 3,
}

CShiMenTask.tXiuShanStatus =    --修缮任务修缮状态
{
    eXiuShanBegin = 1,
    eXiuShanEnd = 2,
}

CShiMenTask.tMsgType = 
{
    eTaskUncomplete = 1,
    eTaskReset = 2,
}

CShiMenTask.tReqType = 
{
    eAcceptShiMenTask = 1,
    eCommitShiMenTask = 2,
}

function CShiMenTask:Ctor(oRole)
    self.m_oRole = oRole
    self.m_bAccepted = false            --是否已经接受师门任务
    self.m_nTaskID = 0                  --任务ID
    self.m_nDayCount = 0                --完成任务环日计数
    self.m_nWeekCount = 0               --完成任务天周计数
    self.m_tTaskParam = {nNpcID = 0, nTaskStatus = false, nProgressNum = 0}
    self.m_nCommitItemID = 0            --物资任务物品id
    self.m_nCommitItemNum = 0           --物资任务物品数量
    self.m_nNumStart = 0                --物资任务所需星数
    
    self.m_nLastResetTimeStamp = 0      --上次重置数据时间差
    self.m_bRewardWeek = false          --是否已领取周任务奖励
    self.m_nTaskPosX = 0                --任务坐标X(战斗和修缮任务随机到的坐标)
    self.m_nTaskPosY = 0                --任务坐标Y    
    self.m_nTaskDupID = 0               --任务坐标场景ID

    --不保存数据
    self.m_nTotalTaskWeight = 0         --所有任务类型总权重
    self.m_nXiuShanTimeStamp = 0        --修缮时间戳

    self:CalTotalTaskWeight()
end

function CShiMenTask:LoadData(tData)
    if tData then
        self.m_oRole = tData.m_oRole or self.m_oRole
        self.m_bAccepted = tData.m_nAccepted or self.m_bAccepted
        self.m_nTaskID = tData.m_nTaskID or self.m_nTaskID
        self.m_nDayCount = tData.m_nDayCount or self.m_nDayCount
        self.m_nWeekCount = tData.m_nWeekCount or self.m_nWeekCount
        self.m_tTaskParam = tData.m_tTaskParam or self.m_tTaskParam
        self.m_nCommitItemID = tData.m_nCommitItemID or self.m_nCommitItemID
        self.m_nCommitItemNum = tData.m_nCommitItemNum or self.m_nCommitItemNum
        self.m_nNumStart = tData.m_nNumStart or self.m_nNumStart
        self.m_nLastResetTimeStamp = tData.m_nLastResetTimeStamp or self.m_nLastResetTimeStamp
        self.m_bRewardWeek = tData.m_bRewardWeek or self.m_bRewardWeek
        self.m_nTaskPosX = tData.m_nTaskPosX or self.m_nTaskPosX
        self.m_nTaskPosY = tData.m_nTaskPosY or self.m_nTaskPosY
        self.m_nTaskDupID = tData.m_nTaskDupID or self.m_nTaskDupID
    end
    if self.m_nLastResetTimeStamp <= 0 then
        self.m_nLastResetTimeStamp = os.time()
        self:MarkDirty(true)
    end
    --print(">>>>>>>>数据库数据，是否接受师门任务: ", self.m_bAccepted)
end

function CShiMenTask:SaveData()
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)

    local tData = {}
    tData.m_nTaskID = self.m_nTaskID
    tData.m_nDayCount = self.m_nDayCount
    tData.m_nWeekCount = self.m_nWeekCount
    tData.m_tTaskParam = self.m_tTaskParam
    tData.m_nCommitItemID = self.m_nCommitItemID
    tData.m_nCommitItemNum = self.m_nCommitItemNum
    tData.m_nNumStart = self.m_nNumStart
    tData.m_nLastResetTimeStamp = self.m_nLastResetTimeStamp
    tData.m_bRewardWeek = self.m_bRewardWeek
    tData.m_nAccepted = self.m_bAccepted
    tData.m_nTaskPosX = self.m_nTaskPosX
    tData.m_nTaskPosY = self.m_nTaskPosY
    tData.m_nTaskDupID = self.m_nTaskDupID
    return tData
end

function CShiMenTask:GetType()
    return gtModuleDef.tShiMenTask.nID, gtModuleDef.tShiMenTask.sName
end

--请求过来，接受师门任务
function CShiMenTask:AccepteTask()
    --判断是否到十八级
    --print(">>>>>>>>>>>>>>>>>>>>>>>>>是否已经接受了师门任务: ", self.m_bAccepted)
    if self.m_bAccepted then 
        -- local bIsCompelet = false
        -- if 0 < self.m_nDayCount then
        --     bIsCompelet = true
        -- end
        -- self:SendTaskInfo(CShiMenTask.tMsgType.eTaskReset, bIsCompelet)
        return self.m_oRole:Tips("已经接受师门任务") 
    end
    if not self.m_oRole.m_oSysOpen:IsSysOpen(nShiMenSysOpenID, true) then
        -- return self.m_oRole:Tips("未到接师门任务还未开启")
        return
    else
        self.m_bAccepted = true
        self:MarkDirty(true)
    end

    --计算任务
    self:CalAcceptTask()
end

--计算任务类型总权重
function CShiMenTask:CalTotalTaskWeight()
    local nTotalWeight = 0
    for _, tConf in pairs(ctShiMenTaskWeight) do
        nTotalWeight = nTotalWeight + tConf.nWeight
    end
    self.m_nTotalTaskWeight = nTotalWeight
end

function CShiMenTask:CalAcceptTask()
    assert(self.m_bAccepted, "还没有接受师门任务")

    --计算前先清空数据
    self.m_nTaskID = 0
    self.m_nCommitItemID = 0
    self.m_nCommitItemNum = 0
    self.m_nNumStart = 0
    self.m_tTaskParam.nNpcID = 0
    self.m_tTaskParam.nProgressNum = 0
    self.m_tTaskParam.nTaskStatus = false
    self.m_nTaskPosX = 0
    self.m_nTaskPosY = 0
    self:MarkDirty(true)

    --全部任务完成
    if self.m_nDayCount >= ctShiMenConf[1].nTaskLimit then
        local nActValOnce = ctDailyActivity[gtDailyID.eShiMenTask].nRewardActValue
        self.m_oRole.m_oDailyActivity:SetRecordData(gtDailyID.eShiMenTask, gtDailyData.eIsComp, true)
        self.m_oRole.m_oDailyActivity:SetRecordData(gtDailyID.eShiMenTask, gtDailyData.ebCanJoin, false)        
        self:SendTaskInfo(CShiMenTask.tMsgType.eTaskReset, true)
        self:OnAllTaskComplete()
        self:MarkDirty(true)
        return
    end

    --根据权重随机计算任务类型
    local nTaskType = 0
    local nRandNum = math.random(self.m_nTotalTaskWeight)
    for nType, tConf in ipairs(ctShiMenTaskWeight) do
        if nRandNum <= tConf.nWeight then
            nTaskType = tConf.nTaskType
            break;
        else
            nRandNum = nRandNum - tConf.nWeight
        end
    end

    --根据师门,等级范围和任务类型随机选取一条任务
    local nConfCount = 0
    local nRoleLevel = self.m_oRole:GetLevel()  
    for sLvLimit, tLimitConf in pairs(_ctShiMenTaskConf[self.m_oRole:GetSchool()]) do
        local fnMatch = string.gmatch(sLvLimit, "%d+")
        local nMinLimit = fnMatch()
        local nMaxLimit = fnMatch()
        if (nRoleLevel >= tonumber(nMinLimit) and nRoleLevel < tonumber(nMaxLimit)) then
            if nTaskType then  --非寻找师傅任务才抽得任务
                nConfCount = #tLimitConf[nTaskType]
                local nRandTask = math.random(nConfCount)
                self.m_nTaskID = tLimitConf[nTaskType][nRandTask].nTaskID
                self.m_bAccepted = true
                self:MarkDirty(true)
                break
            end
        end
    end

    --如果是物资任务计算信息
    local tWuZiTaskInfo = nil
    local nTaskType = ctShiMenTaskConf[self.m_nTaskID].nTaskType
    if CShiMenTask.tTaskType.eWuZi == nTaskType then
        tWuZiTaskInfo = self:CalWuZiTaskInfo()
        self.m_nCommitItemID = tWuZiTaskInfo[1]
        self.m_nCommitItemNum = tWuZiTaskInfo[2]
        self.m_nNumStart = tWuZiTaskInfo[3]
    end

    --如果是战斗、采集任务抽取随机坐标; 对话、提交任务固定位置
    if CShiMenTask.tTaskType.eZhiDao == nTaskType or CShiMenTask.tTaskType.eXiuShan == nTaskType then
        local nRandPosType = ctShiMenTaskConf[self.m_nTaskID].nRandPosType
        local tPosPool = ctRandomPoint.GetPool(nRandPosType, self.m_oRole:GetLevel())
        local function GetPosWeight(tNode)
            return 1
        end
        local tPosConfList = CWeightRandom:Random(tPosPool, GetPosWeight, 1, false)
        self.m_nTaskDupID = tPosConfList[1].nDupID
        self.m_nTaskPosX = tPosConfList[1].tPos[1][1]
        self.m_nTaskPosY = tPosConfList[1].tPos[1][2]
    else
        local nNpcID = ctShiMenTaskConf[self.m_nTaskID].nNpcID
        assert(ctNpcConf[nNpcID], "师门任务NpcID错误")
        local nNpcDupID = ctNpcConf[nNpcID].nDupID
        local tNpcPos = ctNpcConf[nNpcID].tPos
        self.m_nTaskDupID = nNpcDupID
        self.m_nTaskPosX = tNpcPos[1][1]
        self.m_nTaskPosY = tNpcPos[1][2]        
    end

    local bIsCompelet = false
    if 0 < self.m_nDayCount then
        bIsCompelet = true
    end
    self:MarkDirty(true)
    self:SendTaskInfo(CShiMenTask.tMsgType.eTaskReset, bIsCompelet)
end

--根据师门,等级范围和任务类型随机选取一条寻找师父的任务
function CShiMenTask:GetXunZhaoTask()
    local nTaskID = 0
    local nRoleLevel = self.m_oRole:GetLevel() 
    local nShimem = self.m_oRole:GetSchool()
    for sLvLimit, tLimitConf in pairs(_ctShiMenTaskConf[self.m_oRole:GetSchool()]) do
        local fnMatch = string.gmatch(sLvLimit, "%d+")
        local nMinLimit = fnMatch()
        local nMaxLimit = fnMatch()
        if (nRoleLevel >= tonumber(nMinLimit) and nRoleLevel < tonumber(nMaxLimit)) then
            if tLimitConf[CShiMenTask.tTaskType.eXunZhao] then  --寻找师傅任务
                nTaskID = tLimitConf[CShiMenTask.tTaskType.eXunZhao][1].nTaskID
                break
            end
        end
    end
    --assert(ctShiMenTaskConf[nTaskID], "任务不存在,人物等级："..nRoleLevel)
    local nNpcID = ctShiMenTaskConf[nTaskID] and ctShiMenTaskConf[nTaskID].nNpcID or 0
    return nTaskID, nNpcID
end

--操作函数
function CShiMenTask:TaskOpera(nNpcID, nItemID, nGatherStatus)
    if not self.m_bAccepted then
        return self.m_oRole:Tips("还没有接到的任务")
    end
    if not ctShiMenTaskConf[self.m_nTaskID] then
        return self.m_oRole:Tips("没有要提交的任务")
    end
    
    local nTaskType = ctShiMenTaskConf[self.m_nTaskID].nTaskType
    
    if CShiMenTask.tTaskType.eSongXin == nTaskType then
        self:SongXin(nNpcID)

    elseif CShiMenTask.tTaskType.eZhiDao == nTaskType then
        self:ZhiDao(nNpcID)

    elseif CShiMenTask.tTaskType.eWuZi == nTaskType then
        self:WuZi(nNpcID, nItemID)

    elseif CShiMenTask.tTaskType.eXiuShan == nTaskType then
        self:XiuShan(nNpcID, nGatherStatus)

    else
        return self.m_oRole:Tips("任务请求错误" .. nTaskType)
    end
end

--送信任务
function CShiMenTask:SongXin(nNpcID)
    self.m_tTaskParam.nNpcID = nNpcID
    self.m_tTaskParam.nTaskStatus = true
    if self:CheckTaskStatus()then
        self.m_nDayCount = self.m_nDayCount + 1
        self:RewardEachTask(false, 0)
        self:CheckRewardDayTask()
        self:CalAcceptTask()
    end
    self:MarkDirty(true)
end

--指导任务
function CShiMenTask:ZhiDao(nNpcID)
    if self.m_tTaskParam.nTaskStatus then
        self:CalAcceptTask()
        return
    end
    self.m_tTaskParam.nNpcID = nNpcID
    self:MarkDirty(true)
    
    local nBelongMod = CMonsterTaskNpc.tOnBattleEndType.eShiMenTask
    assert(ctShiMenTaskConf[self.m_nTaskID], "没有此师门任务, 任务ID:"..self.m_nTaskID)
    local oMonster = goMonsterMgr:CreateTaskMonster(nBelongMod, self.m_nTaskID)
    if not oMonster then return end

    local tExData = {}
    tExData.tBattleFromModule = CMonsterTaskNpc.tOnBattleEndType.eShiMenTask
    tExData.nBattleDupType = gtBattleType.eShiMen
    self.m_oRole:PVE(oMonster, tExData)
end

function CShiMenTask:OnBattleEnd(bIsRoleWin)
    if bIsRoleWin then
        self.m_tTaskParam.nTaskStatus = true
    else
        self.m_tTaskParam.nTaskStatus = false
    end

    if self:CheckTaskStatus()then
        self.m_nDayCount = self.m_nDayCount + 1
        self:RewardEachTask(false, 0)
        self:CheckRewardDayTask()
        self:CalAcceptTask()
    end
    self:MarkDirty(true)
end

--物资任务
function CShiMenTask:WuZi(nNpcID, nItemID)
    assert(ctPropConf[nItemID], "物品不存在")
    self.m_tTaskParam.nNpcID = nNpcID

    --检查提交的物品是否是同一种类型,子类型的
    assert(ctPropConf[self.m_nCommitItemID], "需要提交的物品不存在")
    local nNeedType = ctPropConf[self.m_nCommitItemID].nType
    local nNeedSubType = ctPropConf[self.m_nCommitItemID].nSubType
    local nItemType = ctPropConf[nItemID].nType
    local nItemSubType = ctPropConf[nItemID].nSubType
    if nNeedType ~= nItemType and nNeedSubType ~= nItemSubType then 
        return self.m_oRole:Tips("提交的物品不符合")
    end

    local oItem = self.m_oRole.m_oKnapsack:GetItemByPropID(nItemID)
    if not oItem then
        return self.m_oRole:Tips("背包没有该物品")
    end

    local nStart = 0 
    local nCommItemType = ctShiMenItemWeight[nItemID].nItemType
    if nCommItemType == gtPropType.eMedicine or nCommItemType == gtPropType.eCooking then
        nStart= oItem:GetStar()
    end
    
    local bSucc = self.m_oRole:CheckSubItem(gtItemType.eProp, nItemID, 1, "任务扣除")
    if not bSucc then
        self.m_oRole:Tips(string.format("%s不足", CKnapsack:PropName(nTaskItemID)))
        return
    end

    --一个任务提交一个物品，提交完设置完成(提交多个物品存在奖励修正系数不确定，策划确定只配提交一个物品)
    self.m_tTaskParam.nTaskStatus = true

    if self:CheckTaskStatus() then
        self.m_nDayCount = self.m_nDayCount + 1
        self:RewardEachTask(true, nStart) --星数
        self:CheckRewardDayTask()
        self:CalAcceptTask()
    end
    self:MarkDirty(true)
end

--修缮任务
function CShiMenTask:XiuShan(nNpcID, nXiuShanStatus)
    self.m_tTaskParam.nNpcID = nNpcID
    if CShiMenTask.tXiuShanStatus.eXiuShanBegin == nXiuShanStatus then
        self.m_nXiuShanTimeStamp = os.time()
        return

    elseif CShiMenTask.tXiuShanStatus.eXiuShanEnd == nXiuShanStatus then
        local nNeedTime = ctShiMenTaskConf[self.m_nTaskID].nTimeLimit
        -- if os.time() < self.m_nXiuShanTimeStamp+nNeedTime or os.time() >= self.m_nXiuShanTimeStamp+nNeedTime*3 then
        --     return self.m_oRole:Tips("宣传时间非法，请重新宣传")
        -- end
        self.m_nXiuShanTimeStamp = 0
        
    else
        return self.m_oRole:Tips("宣传状态非法")
    end

    --修缮任务只修一次，直接设置完成
    self.m_tTaskParam.nTaskStatus = true

    if self:CheckTaskStatus() then
        self.m_nDayCount = self.m_nDayCount + 1
        self:RewardEachTask(false, 0)
        self:CheckRewardDayTask()
        self:CalAcceptTask()
    end
    self:MarkDirty(true)
end

function CShiMenTask:CheckTaskStatus()
    --会出现0点前接的任务，0点后提交，这时候任务ID已经清空了
    if not ctShiMenTaskConf[self.m_nTaskID] then
        LuaTrace("没有此师门任务, 任务ID:", self.m_nTaskID)
        return false
    end
    local bNpcValid = (self.m_tTaskParam.nNpcID == ctShiMenTaskConf[self.m_nTaskID].nNpcID)
    if bNpcValid and self.m_tTaskParam.nTaskStatus then
        goLogger:EventLog(gtEvent.eCompShiMen, self.m_oRole,  self.m_nTaskID) 
        return true
    end
    return false
end

--物资任务随机物品
function CShiMenTask:CalWuZiTaskInfo()
    local nTaskItemID = 0
    local nNeedNum = 0
    local nTotalWeight = 0
    local nItemCount = 0
    local sLimit = nil
    local nStart = 0

    local nRoleLevel = self.m_oRole:GetLevel()
    for sLvLimit, tConfList in pairs(_ctTaskItemConf) do
        local fnMatch = string.gmatch(sLvLimit, "%d+")
        local nMinLimit = fnMatch()
        local nMaxLimit = fnMatch()
        if nRoleLevel >= tonumber(nMinLimit) and nRoleLevel < tonumber(nMaxLimit) then
            nItemCount = #tConfList
            sLimit = sLvLimit
            for k, tConf in pairs(tConfList) do
                nTotalWeight = nTotalWeight + tConf.nWeight
            end
            break
        end
    end
    
    local nItemRandNum = math.random(nTotalWeight)
    for _, tConf in ipairs(_ctTaskItemConf[sLimit]) do
        if nItemRandNum <= tConf.nWeight then
            nTaskItemID = tConf.nItemID
            nNeedNum = tConf.nNeedNum
            break
        end

        nItemRandNum = nItemRandNum - tConf.nWeight
    end

    local nNeedItemType = ctShiMenItemWeight[nTaskItemID].nItemType
    if nNeedItemType == gtPropType.eMedicine or nNeedItemType == gtPropType.eCooking then
        nStart = self:CalItemQuality()
    end
    return {nTaskItemID, nNeedNum, nStart}
end

--物品品质计算
function CShiMenTask:CalItemQuality()
    local nServerLevel = goServerMgr:GetServerLevel(self.m_oRole:GetServer())
    local nRoleLevel = self.m_oRole:GetLevel()
    local nStart = 0

    if nRoleLevel >= 90 and nServerLevel >= 90 then
        nStart = math.random(70, 80)

    else
        if nRoleLevel <= nServerLevel then
            nStart = math.random(nRoleLevel-20, nRoleLevel-10)
        else
            nStart = math.random(nServerLevel-20, nServerLevel-10)
        end
    end
    return nStart
end

--环任务奖励
function CShiMenTask:RewardEachTask(bIsWuZiTask, nItemStart)
    if self.m_nDayCount <= 0 then return end

    local nTemp = self.m_nDayCount % 10
    local nHuanShu = nTemp ~= 0 and nTemp or 10  --当10、20环时设置环数为10

    local nXiuZheng = 1
    if bIsWuZiTask and nItemStart >= ctShiMenConf[1].nXiuzhengLimit then
        nXiuZheng = ctShiMenConf[1].nFnXiuzheng
    end

    local fnRoleExp = ctShiMenConf[1].fnRoleExpRewardOnce
    local fnPetExp = ctShiMenConf[1].fnPetExpRewardOnce
    local fnSilverReward = ctShiMenConf[1].fnSilverRewardOnce

    local nRewardExp = fnRoleExp(self.m_oRole:GetLevel(), nHuanShu, nXiuZheng)
    local nRewardPetExp = fnPetExp(self.m_oRole:GetLevel(), nHuanShu, nXiuZheng)
    local nRewardSilver = fnSilverReward(nHuanShu, self.m_oRole:GetLevel(), nXiuZheng)

    self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRewardExp, "师门环任务奖励")
    self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nRewardPetExp, "师门环任务奖励")
    self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eJinBi, ctShiMenConf[1].nGoldRewardOnce, "师门环任务奖励")
    self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nRewardSilver, "师门环任务奖励")
    
    self.m_oRole.m_oDailyActivity:OnCompleteDailyOnce(gtDailyID.eShiMenTask, "完成师门任务")
    self.m_oRole:PushAchieve("完成师门次数",{nValue = 1})
    CEventHandler:OnCompShiMenTask(self.m_oRole, {})
end

--日任务奖励
function CShiMenTask:CheckRewardDayTask()
    if self.m_nDayCount < ctShiMenConf[1].nTaskLimit then return end

    local tReward = ctShiMenConf[1].tItemReward
    for nIndex, tItem in pairs(tReward) do
        self.m_oRole:AddItem(gtItemType.eProp, tItem[1], tItem[2], "师门任务完成20环奖励")
    end
    self.m_nWeekCount = self.m_nWeekCount + 1
    self:CheckRewardWeekTask()
    self:MarkDirty(true)
end

--周任务奖励
function CShiMenTask:CheckRewardWeekTask()
    if self.m_nWeekCount < ctShiMenConf[1].nWeekRewardLimit then return end
    if self.m_bRewardWeek then return end

    local fnRoleExp = ctShiMenConf[1].fnRoleExpRewardWeek
    local fnSilverReward = ctShiMenConf[1].fnSilverRewardWeek
    local nRewardExp = fnRoleExp(self.m_oRole:GetLevel())
    local nRewardSilver = fnSilverReward(self.m_oRole:GetLevel())

    self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRewardExp, "师门周任务奖励")
    self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nRewardSilver, "师门周任务奖励")
    self.m_bRewardWeek = true
    self:MarkDirty(true)
end

function CShiMenTask:OnDayChange()
    self.m_nTaskID = 0
    self.m_bAccepted = false
    self.m_nCommitItemID = 0
    self.m_nCommitItemNum = 0
    self.m_nDayCount = 0
    self.m_nXiuShanTimeStamp = 0
    self.m_tTaskParam.nNpcID = 0
    self.m_tTaskParam.nProgressNum = 0
    self.m_tTaskParam.nTaskStatus = false
    self.m_nLastResetTimeStamp = os.time()
    self:MarkDirty(true)
end

function CShiMenTask:OnWeekChange()
    self.m_nWeekCount = 0
    self.m_bRewardWeek = false
    self:MarkDirty(true)
end

function CShiMenTask:OnHourTimer()
    self:CheckTimeChange()
end

function CShiMenTask:Online()
    self:CheckTimeChange()
    print("self.m_bAccepted------------------------", self.m_bAccepted)
    print("self.m_nTaskID--------------------------", self.m_nTaskID)
    if not self.m_bAccepted then
        --if self.m_oRole:GetLevel() >= ctShiMenConf[1].nOpenLimit then
        if self.m_oRole.m_oSysOpen:IsSysOpen(nShiMenSysOpenID) then
            local nTaskID, nNpcID = self:GetXunZhaoTask()
            if ctShiMenTaskConf[nTaskID] and ctNpcConf[nNpcID] then
                self:SendCanAccpShiMenTask(true, nNpcID, nTaskID)
            end
        end
    elseif self.m_bAccepted and self.m_nTaskID ~= 0 then      --还有任务没完成
        self:SendTaskInfo(CShiMenTask.tMsgType.eTaskReset, false)
    end
end

function CShiMenTask:CheckTimeChange()
    --print(">>>>>>>>>>>>>>>>>>>>>>师门任务上次重置时间", os.date("%c", self.m_nLastResetTimeStamp))
    if not os.IsSameDay(self.m_nLastResetTimeStamp, os.time(), 0) then
        self:OnDayChange()
        --if self.m_oRole:GetLevel() >= ctShiMenConf[1].nOpenLimit then
        if self.m_oRole.m_oSysOpen:IsSysOpen(nShiMenSysOpenID) then
            local nTaskID, nNpcID = self:GetXunZhaoTask()
            if ctShiMenTaskConf[nTaskID] and ctNpcConf[nNpcID] then
                self:SendCanAccpShiMenTask(true, nNpcID, nTaskID)
            end
        end
    end

    if not os.IsSameWeek(self.m_nLastResetTimeStamp, os.time()) then
        self:OnWeekChange()
    end
    --print(">>>>>>>>>>>>>>>>>>>>>>检查后的状态: ", self.m_bAccepted)
end

function CShiMenTask:OnRoleLevelChange(nNewLevel)
    --if not self.m_bAccepted and nNewLevel >= ctShiMenConf[1].nOpenLimit then
    if not self.m_bAccepted and self.m_oRole.m_oSysOpen:IsSysOpen(nShiMenSysOpenID) then
        local nTaskID, nNpcID = self:GetXunZhaoTask()
        if ctShiMenTaskConf[nTaskID] and ctNpcConf[nNpcID] then
            self:SendCanAccpShiMenTask(true, nNpcID, nTaskID)
        end
    end
end

function CShiMenTask:SendCanAccpShiMenTask(bCanAccp, nNpcID, nTaskID)
    local tMsg = {}
    tMsg.bActShiMenTask = true
    tMsg.nNpcID = nNpcID
    tMsg.nTaskID = nTaskID
    print("ShiMenTaskRet------------------",tMsg)
    self.m_oRole:SendMsg("ShiMenTaskActRet", tMsg)
end

function CShiMenTask:SendTaskInfo(nMsgType, bCompTask)
    local tMsg = {}
    tMsg.nMsgType = nMsgType
    tMsg.bComplete = bCompTask
    tMsg.nTotalComplete = self.m_nDayCount
    tMsg.nTaskID = self.m_nTaskID
    tMsg.nParam1 = self.m_nCommitItemID
    tMsg.nParam2 = self.m_nCommitItemNum
    tMsg.nParam3 = self.m_nNumStart or 0
    tMsg.nTaskDupID = self.m_nTaskDupID
    tMsg.nTaskPosX = self.m_nTaskPosX
    tMsg.nTaskPosY = self.m_nTaskPosY
    self.m_oRole:SendMsg("ShiMenTaskRet", tMsg)
    print(">>>>>>>>>>>>>>>>>>>下发师门信息")
    -- PrintTable(tMsg)
end

--完成所有师门任务
function CShiMenTask:OnAllTaskComplete()
    Network.oRemoteCall:Call("OnInviteMasterTaskCompleteReq", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, self.m_oRole:GetID())
end

function CShiMenTask:OnSysOpen(nSysOpenID)
    if nSysOpenID ~= nShiMenSysOpenID then return end
    if not self.m_bAccepted and self.m_oRole.m_oSysOpen:IsSysOpen(nShiMenSysOpenID) then
        local nTaskID, nNpcID = self:GetXunZhaoTask()
        if ctShiMenTaskConf[nTaskID] and ctNpcConf[nNpcID] then
            self:SendCanAccpShiMenTask(true, nNpcID, nTaskID)
        end
    end
end