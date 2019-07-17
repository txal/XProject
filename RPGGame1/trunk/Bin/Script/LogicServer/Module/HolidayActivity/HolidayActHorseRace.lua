--策马奔腾
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CHolidayActHorseRace:Ctor(oRole, nActID, nActType)
    self.m_oRole = oRole
    CHolidayActivityBase.Ctor(self, nActID, nActType)

    self.m_nQuestionID = 0          --题目索引
    self.m_tRandIndex = {}          --题目随机索引
    self.m_nDistance = 0            --距离
    self.m_nClickValue = 0          --上次点击索引对应的值
    self.m_nContinuePass = 0        --连续答对题目数
    self.m_bIsFail = false          --本次参与是否已经失败
    self.m_bIsStart = false
    self.m_nSecTimer = 0            --计时器
    self.m_nAnswerEndTimestamp = 0  --结束回答时间戳
end

function CHolidayActHorseRace:GetHolidayActData()
    return self.m_oRole.m_oHolidayActMgr.m_tActData
end

function CHolidayActHorseRace:Release()
    if self.m_nSecTimer and self.m_nSecTimer > 0 then
        GetGModule("TimerMgr"):Clear(self.m_nSecTimer)
    end
    self.m_nSecTimer = nil
end

function CHolidayActHorseRace:RegSecTimer()
    GetGModule("TimerMgr"):Clear(self.m_nSecTimer)
    self.m_nSecTimer = GetGModule("TimerMgr"):Interval(5, function() self:OnOutTime() end)
end

function CHolidayActHorseRace:CheckCanJoin()
    --能参加条件已开启，等级足够，次数未用完
    local nEndTimestamp = self:GetEndTimestamp()
    --print(">>>>>>>>>>>>>>>>>>>>>>>>>>尊师考验时间:"..os.date("%c",nEndTimestamp))
    local bIsActOpen = self:GetActIsBegin()
    --print(">>>>>>>>>>>>>>>>>>>>>>>>尊师考验是否开启: "..tostring(bIsActOpen))
    local bLevelEnouht = self.m_oRole:GetLevel() >= ctHolidayActivityConf[self.m_nActID].nLevelLimit
    local tData = self:GetHolidayActData()
    local nActID = self:GetActID()
    assert(ctHolidayActivityConf[nActID], "配置没有此活动")
    local nMaxJoin = ctHolidayActivityConf[nActID].nCanJoinTimes
    local bOldStatus = self.m_bCanJoin
    if bIsActOpen and bLevelEnouht and tData.nHorseRaceCompTimes < nMaxJoin then
        local bNewStatus = true
        if bOldStatus ~= bNewStatus then
            self.m_bCanJoin = bNewStatus
        end
    else
        local bNewStatus = false
        if bOldStatus ~= bNewStatus then
            self.m_bCanJoin = bNewStatus
        end
    end
end

function CHolidayActHorseRace:ResetData()
    self.m_nQuestionID = 0
    self.m_nDistance = 0
    self.m_nClickValue = 0
    self.m_bIsFail = false
    self.m_bIsStart = false
    self.m_nSecTimer = 0
    self.m_nAnswerEndTimestamp = 0
    for nIndex, _ in pairs(self.m_tRandIndex) do
        self.m_tRandIndex[nIndex] = nil
    end 
end

function CHolidayActHorseRace:RandQuestion()
    local function GetQuestionWeight(tNode)
        return 1
    end
    local tQuestion = CWeightRandom:Random(ctHorseRaceConf, GetQuestionWeight, 1, false)
    self.m_nQuestionID = tQuestion[1].m_nQuestionID
    local tIndex = {1, 2, 3, 4, 5}
    local function GetIndexWeight(tNode)
        return 1
    end
    local tRandIndex = CWeightRandom:Random(tIndex, GetIndexWeight, 5, true)
    table.DeepCopy(self.m_tRandIndex, tRandIndex)
    self.m_nAnswerEndTimestamp = os.time() + 5
    self:RegSecTimer()
    self:SendHorseRaceInfo()
end

function CHolidayActHorseRace:StartReq()
    if self.m_bIsStart then
        return self.m_oRole:Tips("策马奔腾已经开始")
    end
    self:ResetData()
    self:RandQuestion()
    self.m_bIsStart = true
end

function CHolidayActHorseRace:AnswerReq(nIndex)
    assert(1<=nIndex and nIndex<=5, "策马奔腾点击索引错误")
    local nOldValue = self.m_nClickValue
    local nValue = self.m_tRandIndex[nIndex]
    if nValue == nOldValue+1 then  --是否是按顺序点
        self:SendAnswerResult(true)
        self.m_nClickValue = nValue
        if self.m_nClickValue == 5 then
            self.m_nClickValue = 0
            self.m_nDistance = self.m_nDistance + 100
            GetGModule("TimerMgr"):Clear(self.m_nSecTimer)
            self:RandQuestion()
        end
    else
        self.m_nClickValue = 0
        GetGModule("TimerMgr"):Clear(self.m_nSecTimer)
        self:CheckReward()
        self:SendAnswerResult(false)        --显示结果
        --self:OutTimeNotic()                 --提示结束
        return
    end
end

function CHolidayActHorseRace:LeaveReq()
    --有效时间内离开通知停止
    GetGModule("TimerMgr"):Clear(self.m_nSecTimer)
    self:CheckReward()
end

function CHolidayActHorseRace:OnOutTime()
    GetGModule("TimerMgr"):Clear(self.m_nSecTimer)
    --时间到也检查发奖励
    self:CheckReward()
    --客户端根据时间戳，超时时自行处理
    self:OutTimeNotic()
end

function CHolidayActHorseRace:CheckReward()
    local tData = self:GetHolidayActData()
    if not tData.bWasGetReward then
        local tConf = self:GetRewardConf(tData.nContinuePass)
        if tConf then
            local nRoleLevel = self.m_oRole:GetLevel()
            local nRoleExp = tConf.fnRoleExp(nRoleLevel)
            local nPetExp = tConf.fnPetExp(nRoleLevel)
            local nYinBi = tConf.fnYinBi(nRoleLevel)
            self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleLevel, "策马奔腾奖励")
            self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nPetExp, "策马奔腾奖励")
            self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nYinBi, "策马奔腾奖励") 
            for _, tFixReward in pairs(tConf.tRewardItem) do
                self.m_oRole:AddItem(gtItemType.eProp, tFixReward[1], tFixReward[2], "策马奔腾奖励")
            end 
            local tPool = ctAwardPoolConf.GetPool(tConf.tRandReward[1], nRoleLevel)
            local function GetItemWeight(tNode)
                return tNode.nWeight
            end
            local tRandReward = CWeightRandom:Random(tPool, GetItemWeight, tConf.tRandReward[2], false)              
            for _, tConf in pairs(tRandReward) do
                self.m_oRole:AddItem(gtItemType.eProp, tConf.nItemID, tConf.nItemNum, "策马奔腾奖励")
            end
            local nOldTimes = tData.nHorseRaceCompTimes or 0
            tData.nHorseRaceCompTimes = nOldTimes + 1
            tData.bWasGetReward = true
        end
    end
    tData.nContinuePass = 0     --每次上线连续记录都要清零
    self.m_oRole.m_oHolidayActMgr:MarkDirty(true)
end

function CHolidayActHorseRace:Online()
    --检查上次数据发奖励
    self:CheckReward()
end

function CHolidayActHorseRace:GetRewardConf(nContinuePass)
    assert(nContinuePass, "策马奔腾连续答对题数有误")
    for nSeq, tConf in pairs(ctHorseRaceConf) do
        if tConf.nMinLimit <= nContinuePass and nContinuePass <= tConf.nMaxLimit then
            return tConf            
        end
    end
end

function CHolidayActHorseRace:SendHorseRaceInfo()
    local tMsg = {tQueIndexList = {}}
    for _, nValue in pairs(self.m_tRandIndex) do
        table.insert(tMsg.tQueIndexList, {nIndex=nValue})
    end
    tMsg.nEndTimestamp = self.m_nAnswerEndTimestamp
    tMsg.nDistance = self.m_nDistance
    tMsg.nQuestionID = self.m_nQuestionID
    self.m_oRole:SendMsg("HorseRaceInfoRet", tMsg)
end

function CHolidayActHorseRace:SendAnswerResult(bIsTrue)
    self.m_oRole:SendMsg("HorseRaceAnswerRet", {bIsTrue=bIsTrue})
end

function CHolidayActHorseRace:OutTimeNotic()
    self.m_oRole:SendMsg("HorseRaceEndNoticRet", {})
end