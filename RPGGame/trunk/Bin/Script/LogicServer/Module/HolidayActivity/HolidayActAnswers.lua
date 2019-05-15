--学富五车
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CHolidayActAnswers:Ctor(oRole, nActID, nActType)
    self.m_oRole = oRole
    CHolidayActivityBase.Ctor(self, nActID, nActType)
end

function CHolidayActAnswers:GetHolidayActData()
    return self.m_oRole.m_oHolidayActMgr.m_tActData
end

function CHolidayActAnswers:CheckCanJoin()
    --能参加条件已开启，等级足够，次数未用完
    local nEndTimestamp = self:GetEndTimestamp()
    --print(">>>>>>>>>>>>>>>>>>>>>>>>>>学富五车结束时间:"..os.date("%c",nEndTimestamp))
    local bIsActOpen = self:GetActIsBegin()
    --print(">>>>>>>>>>>>>>>>>>>>>>>>学富五车活动是否开启: "..tostring(bIsActOpen))
    local bLevelEnouht = self.m_oRole:GetLevel() >= ctHolidayActivityConf[self.m_nActID].nLevelLimit
    local tData = self:GetHolidayActData()
    local nMaxAnswer = ctAnswerConf[1].nQuestionNum
    local bOldStatus = self.m_bCanJoin
    if bIsActOpen and bLevelEnouht and tData.nAnswerTimes < nMaxAnswer then
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

function CHolidayActAnswers:OnActStart()
    --开启后，推送通知界面
    self:CanJoinNotice()
    local tData = self:GetHolidayActData()
    if tData.nAnswerEndTimestamp > 0 and os.time() >= tData.nAnswerEndTimestamp then
        self:ClearData()
    end
    self:SelectQuestion()
end

function CHolidayActAnswers:GetAnswerTimes()
    local tData = self:GetHolidayActData()
    return tData.nAnswerTimes
end

function CHolidayActAnswers:GetQuestionID()
    local tData = self:GetHolidayActData()
    local nQuestionIndex = tData.nAnswerQuestionIdx
    return tData.tQuestionIDList[nQuestionIndex] or 0
end

function CHolidayActAnswers:AddQuestion(nQuestionID)
    local tData = self:GetHolidayActData()
    table.insert(tData.tQuestionIDList, nQuestionID)
    self.m_oRole.m_oHolidayActMgr:MarkDirty(true)
end



function CHolidayActAnswers:SelectQuestion()
    local function GetQuestionWeight()
        return 1
    end
    local tResult = CWeightRandom:Random(ctQuestionConf, GetQuestionWeight,  ctAnswerConf[1].nQuestionNum, true)
    for _, tConf in pairs(tResult) do
        self:AddQuestion(tConf.nQuestionID)
    end
    local tData = self:GetHolidayActData()
    tData.nAnswerQuestionIdx = 1
    self.m_oRole.m_oHolidayActMgr:MarkDirty(true)
end

function CHolidayActAnswers:AnswerReq(nAnswerIndex)
    --答对后奖励并刷新题目
    if os.time() >= self:GetEndTimestamp() then
        return self.m_oRole:Tips("活动已结束，答题无效")
    end
    local nMaxAnswer = ctAnswerConf[1].nQuestionNum    
    local tData = self:GetHolidayActData()
    local nIndex = tData.nAnswerQuestionIdx
    local nQuestionID = tData.tQuestionIDList[nIndex]
    if tData.nAnswerTimes >= nMaxAnswer then
        return self.m_oRole:Tips("所有题目已答完")
    end
    assert(ctQuestionConf[nQuestionID], "学富五车题目ID不存在："..nQuestionID)
    local nConfAnswer = ctQuestionConf[nQuestionID].nAnswer
    local fnRoleExp = ctAnswerConf[1].fnRoleExp
    local fnPetExp = ctAnswerConf[1].fnPetExp
    local fnYinBi = ctAnswerConf[1].fnYinBi
    local nRoleLevel = self.m_oRole:GetLevel()
    local nRoleExp = fnRoleExp(nRoleLevel)
    local nPetExp = fnPetExp(nRoleLevel)
    local nYinBi = fnYinBi(goServerMgr:GetServerLevel(self.m_oRole:GetServer()))
    local tPool = ctAwardPoolConf.GetPool(ctAnswerConf[1].nAwardPoolID, nRoleLevel)
    local function GetWeight(tNode)
        return tNode.nWeight
    end
    local tReward = CWeightRandom:Random(tPool, GetWeight, 1, false)
    if nAnswerIndex == nConfAnswer then
        self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleExp, "学富五车奖励")
        self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nPetExp, "学富五车奖励")
        self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nYinBi, "学富五车奖励")
        for nIndex, tConf in pairs(tReward) do
            self.m_oRole:AddItem(gtItemType.eProp, tConf.nItemID, tConf.nItemNum, "学富五车奖励")
            self.m_oRole:Tips("恭喜答对，获得奖励"..ctPropConf[tConf.nItemID].sName)
        end
    else
        local fnErrorReward = ctAnswerConf[1].fnErrorReward
        local nXishu = fnErrorReward()
        self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleExp*nXishu, "学富五车奖励")
        self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nPetExp*nXishu, "学富五车奖励")
        self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nYinBi*nXishu, "学富五车奖励")
        self.m_oRole:Tips("回答错误，获得奖励经验银币")
    end
    tData.nAnswerTimes = tData.nAnswerTimes + 1
    tData.nAnswerQuestionIdx = tData.nAnswerQuestionIdx + 1
    tData.nAnswerQuestionIdx =  tData.nAnswerQuestionIdx <= nMaxAnswer and tData.nAnswerQuestionIdx or 0
    --客户端根据题目ID为0和答题次数为10关闭界面
    self:SendActAllInfo()
end

--清空上次数据
function CHolidayActAnswers:ClearData()
    local tData = self:GetHolidayActData()
    tData.nAnswerQuestionIdx = 0
    tData.nAnswerTimes = 0            
    tData.nAnswerEndTimestamp = 0
    for nIndex, _ in ipairs(self.m_tActData.tQuestionIDList) do
        tData.tQuestionIDList[nIndex] = nil
    end
end

function CHolidayActAnswers:OnMinTimer()
    CHolidayActivityBase.OnMinTimer(self)
    self:CheckCanJoin()
end

function CHolidayActAnswers:Online()
    self:CheckCanJoin()
end

function CHolidayActAnswers:GetActStatusInfo()
    local tData = self:GetHolidayActData()
    local tActInfo = {}
    tActInfo.nActivityID = self.m_nActID
    tActInfo.nTodayCompTimes = self:GetAnswerTimes()
    tActInfo.nTotalTimes = ctHolidayActivityConf[self.m_nActID].nCanJoinTimes
    tActInfo.bCanJoin = self:GetCanJoin()
    tActInfo.bIsComp = tData.nAnswerTimes >= ctAnswerConf[1].nQuestionNum
    tActInfo.bIsEnd = os.time() >= self:GetEndTimestamp()
    return tActInfo
end

function CHolidayActAnswers:SendActStatusInfo()
    --单独改变的信息
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
    --PrintTable(tMsg)
end

function CHolidayActAnswers:SendActAllInfo()
    local tData = self:GetHolidayActData()
    local tMsg = {}
    tMsg.nQuestionID = self:GetQuestionID() or 0
    tMsg.nEndTimestamp = self:GetEndTimestamp()
    tMsg.nCountAnswer = tData.nAnswerTimes
    self.m_oRole:SendMsg("AnswerAllInfoRet", tMsg)

    print(">>>>>>>>>>>>>>>>>>>>>>>>学富五车界面信息")
    --PrintTable(tMsg)
end

function CHolidayActAnswers:CanJoinNotice()
    print(">>>>>>>>>>>>>>>>>>>>>>>可参加学富五车活动")
    self.m_oRole:SendMsg("AnswerNoticeRet", {})
end

-- function CHolidayActAnswers:OnChangeJoinStatus(nActStatus)
--     CHolidayActivityBase.OnChangeJoinStatus(self)       --通知父类下发信息
--     if nActStatus == gtHolidayActStatus.eBegin then
--     elseif nActStatus == gtHolidayActStatus.eEnd then
--     end
-- end