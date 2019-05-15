--赏金任务
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nShangJinSysOpenID = 48       --系统开放ID
function CShangJinTask:Ctor(oRole)
    self.m_oRole = oRole
    self.m_tTaskList = {}       --{[taskID] = {}}
    self.m_nCurrTaskID = 0      --当前接受的任务id
    self.m_nCompTimes = 0       --已完成次数
    self.m_nLastResetTimeStamp = 0      --上次重置时间戳
    self.m_nUseFreeRefleshTimes = 0     --已经使用的免费刷新次数
end

function CShangJinTask:LoadData(tData)
    if tData then
        self.m_tTaskList = tData.m_tTaskList or self.m_tTaskList
        self.m_nCurrTaskID = tData.m_nCurrTaskID or self.m_nCurrTaskID
        self.m_nCompTimes = tData.m_nCompTimes or self.m_nCompTimes
        self.m_nLastResetTimeStamp = tData.m_nLastResetTimeStamp or self.m_nLastResetTimeStamp
        self.m_nUseFreeRefleshTimes = tData.m_nUseFreeRefleshTimes or self.m_nUseFreeRefleshTimes
    end

    self:OnLoaded()
end

function CShangJinTask:OnLoaded()
    local nLevelLimit = ctDailyActivity[gtDailyID.eShangJinTask].nLevelLimit
    --if self.m_oRole:GetLevel() >= nLevelLimit and self.m_nLastResetTimeStamp <= 0 then
    if self.m_oRole.m_oSysOpen:IsSysOpen(nShangJinSysOpenID) and self.m_nLastResetTimeStamp <= 0 then
        --初始化接受任务
        local tTaskList = self:CalTask()
        self:SetTaskList(tTaskList)
        self.m_nLastResetTimeStamp = os.time()
        self:MarkDirty(true)
    end    

    --万一保存的坐标配置修改了，纠正一下坐标
    for nTaskID, tData in pairs(self.m_tTaskList) do
        local nPointID = tData.nPointID or 0
        if nPointID > 0 then
            local nTaskDupID = self.m_tTaskList[nTaskID].nDupID
            local nTaskPosX = self.m_tTaskList[nTaskID].nPosX
            local nTaskPosY = self.m_tTaskList[nTaskID].nPosY
            local tPointConf = ctRandomPoint[nPointID]
            self.m_tTaskList[nTaskID].nDupID = nTaskDupID == tPointConf.nDupID and nTaskDupID or tPointConf.nDupID
            self.m_tTaskList[nTaskID].nPosX = nTaskPosX == tPointConf.tPos[1][1] and nTaskPosX or tPointConf.tPos[1][1]
            self.m_tTaskList[nTaskID].nPosY = nTaskPosY == tPointConf.tPos[1][2] and nTaskPosY or tPointConf.tPos[1][2]
        else
            local nTaskDupID = self.m_tTaskList[nTaskID].nDupID
            local tDupConf = ctDupConf[nTaskDupID]
            if tDupConf then
                local nTaskPosX = math.max(50, math.min(tDupConf.nWidth-50, self.m_tTaskList[nTaskID].nPosX))
                local nTaskPosY = math.max(50, math.min(tDupConf.nHeight-50, self.m_tTaskList[nTaskID].nPosY))
                self.m_tTaskList[nTaskID].nPosX = nTaskPosX
                self.m_tTaskList[nTaskID].nPosY = nTaskPosY
            end
        end
    end
end

function CShangJinTask:SaveData()
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)

    local tData = {}
    tData.m_tTaskList = self.m_tTaskList
    tData.m_nCurrTaskID = self.m_nCurrTaskID
    tData.m_nCompTimes = self.m_nCompTimes 
    tData.m_nLastResetTimeStamp = self.m_nLastResetTimeStamp
    tData.m_nUseFreeRefleshTimes = self.m_nUseFreeRefleshTimes
    return tData
end

function CShangJinTask:GetType()
    return gtModuleDef.tShangJinTask.nID, gtModuleDef.tShangJinTask.sName
end

function CShangJinTask:SetCurrTask(nTaskID)
    assert(ctShangJinTaskConf[nTaskID], "不存在该任务")
    assert(self.m_tTaskList[nTaskID], "此次刷新没有该任务")
    assert(not self.m_tTaskList[nTaskID].bCompleted, "该任务已经完成")
    self.m_nCurrTaskID = nTaskID    
    self:MarkDirty(true)
end

function CShangJinTask:SetTaskList(tTaskList)
    assert(next(tTaskList), "设置任务列表参数错误")

    --保存数据
    for nNewTaskID, nPointID in pairs(tTaskList) do
        self.m_tTaskList[nNewTaskID] = {}
        self.m_tTaskList[nNewTaskID].nTaskID = nNewTaskID
        self.m_tTaskList[nNewTaskID].bCompleted = false
        self.m_tTaskList[nNewTaskID].nStart = ctShangJinTaskConf[nNewTaskID].nStart
        self.m_tTaskList[nNewTaskID].nDupID = ctRandomPoint[nPointID].nDupID
        self.m_tTaskList[nNewTaskID].nPosX = ctRandomPoint[nPointID].tPos[1][1]
        self.m_tTaskList[nNewTaskID].nPosY = ctRandomPoint[nPointID].tPos[1][2]
        self.m_tTaskList[nNewTaskID].nPointID = nPointID
    end
    self:MarkDirty(true)
end

function CShangJinTask:ClearTask()
    for nTaskID, tData in pairs(self.m_tTaskList) do
        self.m_tTaskList[nTaskID] = nil
        self:MarkDirty(true)
    end
end

--请求所有任务信息
function CShangJinTask:AllTaskReq()
    local bIsAllComp = true
    for _, tData in pairs(self.m_tTaskList) do
        if not tData.bCompleted then
            bIsAllComp = false
            break
        end
    end
    if bIsAllComp then
        self.m_oRole:Tips("您上一批的赏金任务已经全部完成，获取新的任务")
        local tTaskList = self:CalTask()
        self:ClearTask()
        self:SetTaskList(tTaskList)
    end
    self:SendShangJinAllInfo()
end

--接取任务
function CShangJinTask:TaskAccepReq(nTaskID, bIsYuanBaoComp)
    local nShangJinSysOpenID = 48
    if not self.m_oRole.m_oSysOpen:IsSysOpen(nShangJinSysOpenID, true) then
        -- return self.m_oRole:Tips("赏金任务未开启")
        return
    end

    if self.m_nCurrTaskID > 0 then
        return self.m_oRole:Tips("已经接取赏金任务")
    end
    if self.m_nCompTimes >= ctDailyActivity[gtDailyID.eShangJinTask].nTimesReward then
        return self.m_oRole:Tips("赏金任务已达到完成上限，不能接取")
    end
    if self.m_tTaskList[nTaskID].bCompleted then
        return self.m_oRole:Tips("该任务已完成")
    end

    self:SetCurrTask(nTaskID)
    if not bIsYuanBaoComp then
        self:SendShangJinTask()
    end
end

--元宝完成
function CShangJinTask:UseYuanBaoComp(nTaskID)
    local nShangJinSysOpenID = 48
    if not self.m_oRole.m_oSysOpen:IsSysOpen(nShangJinSysOpenID, true) then
        -- return self.m_oRole:Tips("赏金任务未开启")
        return
    end

    local nWillCompTaskID = 0
    local bAlreadyAccepTask = false
    if not nTaskID then
        if self.m_nCurrTaskID <= 0 then
            return self.m_oRole:Tips("没有要完成的任务")
        end
        nWillCompTaskID = self.m_nCurrTaskID
        bAlreadyAccepTask = true
    else
        --先判断能不能接(如果能接，接下来判断元宝够不够，够，才能接，主要避免元宝够了消耗了却发现不能接了，或者接却发现元宝不够了)
        nWillCompTaskID = nTaskID
        if self.m_nCompTimes >= ctDailyActivity[gtDailyID.eShangJinTask].nTimesReward then
            return self.m_oRole:Tips("您今日的赏金任务已经全部完成，请明天再来领取赏金任务")
        end
        if self.m_tTaskList[nTaskID].bCompleted then
            return self.m_oRole:Tips("该任务已完成")
        end
    end

    local nStar = self.m_tTaskList[nWillCompTaskID].nStart
    local tConf = assert(ctShangJinConf[nStar], "赏金任务元宝完成错误，任务ID:"..nWillCompTaskID)
    local bCostSucc = self.m_oRole:CheckSubShowNotEnoughTips({{gtItemType.eCurr, gtCurrType.eAllYuanBao, tConf.nYuanBaoComp}}, "赏金任务元宝完成消耗", true, false)
    if not bCostSucc then
        return
    end

    if not bAlreadyAccepTask then
        self:TaskAccepReq(nWillCompTaskID, true)
    end
    self:Reward()
end

--请求刷新任务
function CShangJinTask:TaskRefreshReq(bUseGold)
    if self.m_nCurrTaskID > 0 then 
        return self.m_oRole:Tips("已接取了任务，不能刷新")
    end

    if self.m_nCompTimes >= ctDailyActivity[gtDailyID.eShangJinTask].nTimesReward then
        return self.m_oRole:Tips("赏金任务已达到完成上限，不能刷新")
    end

    local nShangJinSysOpenID = 48
    if not self.m_oRole.m_oSysOpen:IsSysOpen(nShangJinSysOpenID, true) then
        -- return self.m_oRole:Tips("赏金任务未开启")
        return
    end
    
    local nRemainTimes = self:GetNotCompTaskNum()

    -- local function FreshTask(bCostSucc)
    --     if bCostSucc then
    --         local tTaskList = self:CalTask()
    --         self:ClearTask()
    --         self:SetTaskList(tTaskList)
    --         self:SendShangJinAllInfo()
    --     end
    -- end
    --消耗物品
    if nRemainTimes > 0 then
        if self.m_nUseFreeRefleshTimes >= 5 then
            local nStuffID = ctShangJinOtherConf[nRemainTimes].nStuffID
            local nCostStuffNum = ctShangJinOtherConf[nRemainTimes].nNumStuff
            local nHadStuffNum = self.m_oRole:ItemCount(gtItemType.eProp, nStuffID)
            local nNeedGold = 0
            local nYuanBaoType = 0
            if nHadStuffNum < nCostStuffNum then
                if not bUseGold then
                    return self.m_oRole:Tips("刷新材料不足")
                end
                local nNeedNum = math.max(0, nCostStuffNum - nHadStuffNum)
                local nHadGold = self.m_oRole:ItemCount(gtItemType.eCurr, gtCurrType.eAllYuanBao)
                nNeedGold = nNeedNum * ctPropConf[nStuffID].nBuyPrice
                nYuanBaoType = ctPropConf[nStuffID].nYuanBaoType
                if nHadGold < nNeedGold then
                    return self.m_oRole:YuanBaoTips()
                end
            end
            local nCostNum = nHadStuffNum > nCostStuffNum and nCostStuffNum or nHadStuffNum
            self.m_oRole:AddItem(gtItemType.eProp, nStuffID, -nCostNum, "刷新赏金任务消耗")
            if bUseGold and nNeedGold > 0 then
                self.m_oRole:AddItem(gtItemType.eCurr, nYuanBaoType, -nNeedGold, "刷新赏金任务消耗")
            end

            -- local tItemList = {{gtItemType.eProp, nStuffID, nCostStuffNum}}
            -- self.m_oRole:SubItemByYuanbao(tItemList, "刷新赏金任务消耗", FreshTask, not bUseGold)
        end
    end
    self.m_nUseFreeRefleshTimes = self.m_nUseFreeRefleshTimes + 1
    local tTaskList = self:CalTask()
    self:ClearTask()
    self:SetTaskList(tTaskList)
    self.m_oRole:Tips("任务刷新完毕")
    self:SendShangJinAllInfo()
end

--赏金任务攻击请求
function CShangJinTask:ShangJinAttReq()
    --判断是否有任务
    if self.m_nCurrTaskID == 0 then
        return self.m_oRole:Tips("没有接受赏金任务")
    end

    --判断地点
    local nTaskDupID = self.m_tTaskList[self.m_nCurrTaskID].nDupID
    local tCurrDup = self.m_oRole:GetCurrDup()
    if nTaskDupID ~= tCurrDup[1] then               --刷怪在普通场景可以直接用配置ID
        return self.m_oRole:Tips("场景错误，未达目的地")
    end
    local nRolePosX, nRolePosY = self.m_oRole:GetPos()
    local nPosX = self.m_tTaskList[self.m_nCurrTaskID].nPosX
    local nPosY = self.m_tTaskList[self.m_nCurrTaskID].nPosY
    local nDisX = math.abs(nPosX - nRolePosX)
    local nDisY = math.abs(nPosY - nRolePosY)
    if nDisX^2 + nDisY^2  > 100^2 then
        return self.m_oRole:Tips("坐标错误，未达目的地")
    end

    local oMonster = goMonsterMgr:CreateInvisibleMonster(ctShangJinTaskConf[self.m_nCurrTaskID].nMonsterID)
    self.m_oRole:PVE(oMonster, {bShangJinTask = true, nBattleDupType=gtBattleType.eShangJin})
end

function CShangJinTask:OnBattleEnd(bIsWin)
    if bIsWin then
        self:Reward()
    end
end

function CShangJinTask:Reward()
    local nStart = ctShangJinTaskConf[self.m_nCurrTaskID].nStart
    local fnRoleExp = ctShangJinConf[nStart].fnRoleExp
    local fnPetExp = ctShangJinConf[nStart].fnPetExp
    local fnYinBi = ctShangJinConf[nStart].fnYinBi
    local nRoleExp = fnRoleExp(self.m_oRole:GetLevel())
    local nYinBi = fnYinBi(gnSilverRatio)
    local oFightPet = self.m_oRole.m_oPet:GetCombatPet()
    local nPetExp = 0
    if oFightPet then
        nPetExp = fnPetExp(oFightPet.nPetLv)
    end

    self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleExp, "赏金任务奖励")        
    self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nPetExp, "赏金任务奖励")
    self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nYinBi, "赏金任务奖励")
    goLogger:EventLog(gtEvent.eCompShangJin, self.m_oRole,  self.m_nCurrTaskID)

    --设置日活跃、成就
    local oDailyActivity = self.m_oRole.m_oDailyActivity
    oDailyActivity:OnCompleteDailyOnce(gtDailyID.eShangJinTask,"完成赏金任务")
    self.m_oRole:PushAchieve("赏金任务次数",{nValue = 1}) 
    
    self.m_tTaskList[self.m_nCurrTaskID].bCompleted = true
    self.m_nCompTimes = self.m_nCompTimes + 1
    local nCompTaskID = self.m_nCurrTaskID
    self.m_nCurrTaskID = 0
    self:MarkDirty(true)
    self:SendShangJinTask()
    self:SendShangJinAllInfo()

    --有的任务没有奖励物品
    local nAwardPoolID = ctShangJinConf[nStart].tReward[1][1]        
    local nRewardNum = ctShangJinConf[nStart].tReward[1][2]

    local tItemIDList = {}
    if ctAwardPoolConf[nAwardPoolID] then
        local function GetWeight(tNode)
            return tNode.nWeight
        end
        local tPool = ctAwardPoolConf.GetPool(nAwardPoolID, self.m_oRole:GetLevel(), self.m_oRole:GetConfID())
        local tResult = CWeightRandom:Random(tPool, GetWeight, nRewardNum, false)
        assert(next(tResult), "赏金奖励为空, 人物等级："..self.m_oRole:GetLevel())
        for nCount = 1, nRewardNum do
            self.m_oRole:AddItem(gtItemType.eProp, tResult[nCount].nItemID, tResult[nCount].nItemNum, "赏金任务奖励")
            table.insert(tItemIDList, tResult[nCount].nItemID)
        end
    end 
    local tData = {}
    tData.bIsHearsay = true
    tData.nTaskID = nCompTaskID
    tData.tItemIDList = tItemIDList
    CEventHandler:OnCompShangJin(self.m_oRole, tData) 
end

--获取赏金榜上未完成任务个数
function CShangJinTask:GetNotCompTaskNum()
    local nNumNotComp = 0
    for _, tData in pairs(self.m_tTaskList) do
        if not tData.bCompleted then
            nNumNotComp = nNumNotComp + 1
        end
    end 
    return nNumNotComp      --赏金榜上未完成任务个数
end

--计算任务
function CShangJinTask:CalTask()
    local tTaskIDSet = {}
    local tRetRand = {} --随机结果
    local nMaxTimes = ctDailyActivity[gtDailyID.eShangJinTask].nTimesReward

    --定义抽任务函数
    local function GetShangJinTaskWeight(tNode)
        return 1
    end

    local function GetShangJinTask(tTaskPool, GetShangJinTaskWeight)
        --抽星数
        local bAgain = false
        local function GetShangJinTaskStartWeight(tNode)
            return tNode.nWeight
        end
        local tResult = CWeightRandom:Random(ctShangJinConf, GetShangJinTaskStartWeight, 1, false)
        
        local tTaskPool = ctShangJinTaskConf:GetPool(tResult[1].nStart)
        local tTaskList = CWeightRandom:Random(tTaskPool, GetShangJinTaskWeight, 1, false)
        local nTaskIDSel = tTaskList[1].nTaskID
        if tTaskIDSet[nTaskIDSel]then         --抽过的不能抽了
            bAgain = true
        else
            tTaskIDSet[nTaskIDSel] = true
            bAgain = false
        end
        return bAgain, tTaskList
    end

    local function GetPosWeight(tNode)
        return 1
    end

    --随机任务    
    for nCount = 1, nMaxTimes do
        local bNeedAgain = true
        local tTask = nil
        for nTimes = 1, 100 do        --100次随机，抽出在任务列表的任务时循环
            bNeedAgain, tTask = GetShangJinTask(tTaskPool, GetShangJinTaskWeight)
            if not bNeedAgain then break end    --不用再次抽选，跳出循环
        end

        --随机坐标点
        local nRandPosType = ctShangJinTaskConf[tTask[1].nTaskID].nPosType
        local tPosPool = ctRandomPoint.GetPool(nRandPosType, self.m_oRole:GetLevel())
        assert(next(tPosPool), "赏金任务随机坐标，人物等级："..self.m_oRole:GetLevel())
        local tPosConf = CWeightRandom:Random(tPosPool, GetPosWeight, 1, false)
        tRetRand[tTask[1].nTaskID] = tPosConf[1].nID  --{[nTaskID]=ctRandomPoint.nID}
    end

    return tRetRand
end

function CShangJinTask:Online()
    local nRoleLevel = self.m_oRole:GetLevel()
    local nLevelLimit = ctDailyActivity[gtDailyID.eShangJinTask].nLevelLimit
    --if nRoleLevel >= nLevelLimit then
    if self.m_oRole.m_oSysOpen:IsSysOpen(nShangJinSysOpenID) then
        if not os.IsSameDay(self.m_nLastResetTimeStamp, os.time(), 0) then
            self.m_nCompTimes = 0
            self.m_nLastResetTimeStamp = os.time()
            self.m_nUseFreeRefleshTimes = 0
            self:MarkDirty(true)
        end
        if self.m_nCompTimes < ctDailyActivity[gtDailyID.eShangJinTask].nTimesReward then
            self:SendShangJinTask()
        end
    end
end

function CShangJinTask:OnRoleLevelChange(nNewLevel)
    -- local nLevelLimit = ctDailyActivity[gtDailyID.eShangJinTask].nLevelLimit
    -- --if self.m_oRole:GetLevel() >= nLevelLimit and self.m_nLastResetTimeStamp <= 0 then
    -- if self.m_oRole.m_oSysOpen:IsSysOpen(nShangJinSysOpenID) and self.m_nLastResetTimeStamp <= 0 then
    --     local nMaxTimes = ctDailyActivity[gtDailyID.eShangJinTask].nTimesReward
    --     local nRemainTimes = nMaxTimes - self.m_nCompTimes
    --     if nRemainTimes <= 0 then return end
    --     self.m_nLastResetTimeStamp = os.time()
    --     local tTaskList = self:CalTask()
    --     self:SetTaskList(tTaskList)
    --     self:SendShangJinTask()
    -- end
end

function CShangJinTask:OnHourTimer()
    if self.m_nLastResetTimeStamp > 0 and not os.IsSameDay(self.m_nLastResetTimeStamp, os.time(), 0) then
        self.m_nCompTimes = 0
        self.m_nUseFreeRefleshTimes = 0
        self:SendShangJinTask()
        self:MarkDirty(true)
    end
end

function CShangJinTask:SendShangJinAllInfo()
    local nStuffID = ctShangJinOtherConf[1].nStuffID 
    local nHadStuffNum = self.m_oRole:ItemCount(gtItemType.eProp, nStuffID)
    local tMsg = { tShangJinTaskList = {} }
    for _, tData in pairs(self.m_tTaskList) do
        local tTaskInfo = {}
        tTaskInfo.nTaskID = tData.nTaskID
        tTaskInfo.nStart = tData.nStart
        tTaskInfo.bCompleted = tData.bCompleted
        table.insert(tMsg.tShangJinTaskList, tTaskInfo)
    end
    tMsg.nNumShangJinLing = nHadStuffNum
    tMsg.nLeftFreeReflashTimes = 5 - self.m_nUseFreeRefleshTimes  --默认每天5次免费刷新，没地方配，写死
    self.m_oRole:SendMsg("ShangJinAllTaskRet", tMsg)
    --PrintTable(tMsg)
end

function CShangJinTask:SendShangJinTask()
    local tMsg = {}
    tMsg.nTaskID = self.m_nCurrTaskID
    tMsg.nCompTimes = self.m_nCompTimes
    tMsg.nDupID = self.m_nCurrTaskID == 0 and 0 or self.m_tTaskList[self.m_nCurrTaskID].nDupID
    tMsg.nPosX = self.m_nCurrTaskID == 0 and 0 or self.m_tTaskList[self.m_nCurrTaskID].nPosX
    tMsg.nPosY = self.m_nCurrTaskID == 0 and 0 or self.m_tTaskList[self.m_nCurrTaskID].nPosY
    self.m_oRole:SendMsg("ShangJinAccepRet", tMsg)
    --print("CShangJinTask:SendShangJinTask***", tMsg)
end

function CShangJinTask:OnSysOpen(nSysOpenID)
    if nSysOpenID ~= 48 then return end --48系统开放ID
    if self.m_oRole.m_oSysOpen:IsSysOpen(nShangJinSysOpenID) and self.m_nLastResetTimeStamp <= 0 then
        local nMaxTimes = ctDailyActivity[gtDailyID.eShangJinTask].nTimesReward
        local nRemainTimes = nMaxTimes - self.m_nCompTimes
        if nRemainTimes <= 0 then return end
        self.m_nLastResetTimeStamp = os.time()
        local tTaskList = self:CalTask()
        self:SetTaskList(tTaskList)
        self:SendShangJinTask()
    end
end