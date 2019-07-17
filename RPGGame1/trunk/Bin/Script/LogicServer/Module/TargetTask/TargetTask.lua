--目标任务
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

gtTargetTask =
{
    eCompZhenYao = 1,                   --完成镇妖
    eCompLuanshiYaoMo = 2,              --完成乱世妖魔
    eCompShiMenTask = 3,                --完成师门任务
    eCompBaoTu = 4,                     --完成挖宝次数
    eSignIn = 5,                        --累计签到次数
    eUnionSignIn = 6,                   --累计帮派签到次数
    ePetWashAttr = 7,                   --累计宠物洗髓次数
    ePetLearnSkill = 8,                 --累计宠物学习技能次数
    eCongratulate = 9,                  --累计膜拜大神次数
    eJoinArenaBattle = 10,              --累计参加竞技场次数
    eExcavateStone = 11,                --累计挖取灵石次数
    eGiveSthToPartner = 12,             --累计仙侣赏赐次数
    eGetOnlineGift = 13,                --累计领取在线礼包次数
    eCompShangJin = 14,                 --累计完成赏金次数
    eUseDrawSpirit = 15,                --累计使用摄魂次数
    eFightCapacity = 16,                --战斗力达到指定数值
    eAchievePrinTask = 17,              --达到主线任务章节
    eEquStrenghten = 18,                --任意件装备强化到某等级
    eDrawSpriritLevel = 19,             --摄魂等级达到指定等级
    eFriendNum = 20,                    --好友数量达到指定个数
    eRoleLevel = 21,                    --角色等级达到指定等级
    ePracticeLevel = 22,                --任意修炼技能等级达到指定等级
    eSchoolSkill = 23,                  --门派技能等级达到指定等级
    eBattleTrain = 24,                  --战斗训练
    ePartnerUpStar = 25,                --仙侣升到达星数
    eGem = 26,                          --达到指定等级宝石镶嵌个数
    eEquFaBao = 27,                     --达到装配指定等级法宝个数
    eAssistedSkillUpLevel = 28,         --辅助技能升级任意个辅助技能达到某等级
    eQiLingUpLevel = 29,                --器灵升级达到指定等级
    ePetCompose = 30,                   --宠物合成次数
    ePetLianGu = 31,                    --宠物炼骨次数
    eFaBaoCompose = 32,                 --法宝合成次数
    eQiLingUpGrade = 33,                --器灵达到指定阶数
    eAchieveBranchTask = 34,            --达到支线任务章节
    ePartnerLearn = 35,                 --仙侣学习次数
    eColligatePower = 36,               --综合战斗力
    eCompShenMoZhi = 37,                --完成神魔志
    eCompYaoShouTuXi = 38,              --完成妖兽突袭
    eAddFriendCount = 39,               --添加好友次数
    eInviteMarryCount = 40,             --发布结婚信息统计次数
    eFaZhenLevel = 41,                  --任意个法阵升到某等级
    eEnterGuaJiDup = 42,                --进入挂机场景次数
    eChalGuaJiGuanQia = 43,             --挑战挂机关卡
    eClickChalGuaJiBoss = 44,           --点击挑战挂机boss
    eClickAutoChalBoss = 45,            --点击自动挑战挂机boss
    eEquipEquipment = 46,               --装备X件X级装备
    eCompAllTargetTask = 47,            --完成所有目标任务
}
--新增类型时，TargetTaskConfCheck.lua检查配置要修改类型上限

function CTargetTask:Ctor(oRole)
    self.m_oRole = oRole
    self.m_nTaskID = 0
    self.m_nCurrTarNum = 0
    self.m_bIsComplete = false
    self.m_bCanGetReward = false
    self.m_bIsGetReward = false
    self.m_tCurrTarNumMap = {}              --当前目标数映射{[tasktype]=value}
    self.m_tExecEvent = {}                  --后续执行事件映射

    self:RegisterExecEvent()
end

function CTargetTask:LoadData(tData)
    local nMaxTaskID = self:GetMaxTaskID()
    if tData then
        --完成最后一个任务或突然减少配置任务
        if tData.m_nTaskID > nMaxTaskID  then
            self.m_nTaskID = nMaxTaskID
            self:MarkDirty(true)
        elseif (0 < tData.m_nTaskID and tData.m_nTaskID < nMaxTaskID) and (not ctTargetTaskConf[tData.m_nTaskID]) then
            local nNextTaskID = tData.m_nTaskID + 1
            while (not ctTargetTaskConf[nNextTaskID]) do
                nNextTaskID = nNextTaskID + 1
            end
            self.m_nTaskID = nNextTaskID
            self:MarkDirty(true)
        else
            self.m_nTaskID = tData.m_nTaskID
        end
        self.m_nCurrTarNum = tData.m_nCurrTarNum or 0
        self.m_bIsComplete = tData.m_bIsComplete or false
        self.m_bCanGetReward = tData.m_bCanGetReward or false
        self.m_bIsGetReward = tData.m_bIsGetReward or false
        self.m_tCurrTarNumMap = tData.m_tCurrTarNumMap or {}
    end

    if self.m_nTaskID == 0 then
        for nTaskID, tConf in pairs(ctTargetTaskConf) do
            if tConf.nPre == 0 then
                self.m_nTaskID = nTaskID
                self:MarkDirty(true)
                self:SendTargetTaskInfo()
            end
        end
    end
end

function CTargetTask:SaveData()
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)
    local tData = {}
    tData.m_nTaskID = self.m_nTaskID
    tData.m_nCurrTarNum = self.m_nCurrTarNum
    tData.m_bIsComplete = self.m_bIsComplete
    tData.m_bCanGetReward = self.m_bCanGetReward
    tData.m_bIsGetReward = self.m_bIsGetReward
    tData.m_tCurrTarNumMap = self.m_tCurrTarNumMap
    return tData
end

function CTargetTask:GetType()
    return gtModuleDef.tTargetTask.nID, gtModuleDef.tTargetTask.sName
end

function CTargetTask:GetCurrTargetData(nType)
    return self.m_tCurrTarNumMap[nType]
end

function CTargetTask:GetMaxTaskID()
    local nTempID = 0
    for nTaskID, tConf in pairs(ctTargetTaskConf) do
        if nTaskID > nTempID then
            nTempID = nTaskID
        end
    end
    return nTempID
end

function CTargetTask:CheckState()
    if self.m_nTaskID <= 0 then return end
    local nCurrTaskType = ctTargetTaskConf[self.m_nTaskID].nTaskType
    if type(self.m_tCurrTarNumMap[nCurrTaskType]) == "table" then       --以table做保存记录
        local nCond = ctTargetTaskConf[self.m_nTaskID].tParam[1][2]
        if nCurrTaskType ~= gtTargetTask.eEquipEquipment then               --有0级装备
            assert(nCond > 0, "目标任务目标参数有误, 任务ID:"..self.m_nTaskID)
        end
        --宝石镶嵌类，可以镶嵌、取下做动态统计不宜做过程记录统计
        if nCurrTaskType == gtTargetTask.eGem
            or nCurrTaskType == gtTargetTask.eEquFaBao
            or nCurrTaskType == gtTargetTask.eEquipEquipment then

            local nTotalCount = 0
            for nCondSave, nCountSave in pairs(self.m_tCurrTarNumMap[nCurrTaskType]) do
                if nCondSave >= nCond then
                    nTotalCount = nTotalCount + nCountSave
                end
            end
            self.m_nCurrTarNum = nTotalCount

        --任意件装备强化到某等级类记录过程统计，不宜做动态统计，因为记录的是操作成功的记录
        else
            self.m_nCurrTarNum = self.m_tCurrTarNumMap[nCurrTaskType][nCond] or 0
        end

    else --以数字做累计
        self.m_nCurrTarNum = self.m_tCurrTarNumMap[nCurrTaskType] or 0
    end
    local nTargetNum = ctTargetTaskConf[self.m_nTaskID].tParam[1][1]

    --目前仅针对目标任务初始值跟实际初始值不符，对摄魂升级类型数据同步
    if ctTargetTaskConf[self.m_nTaskID].nTaskType == gtTargetTask.eDrawSpriritLevel then
        self.m_nCurrTarNum = self.m_oRole.m_oDrawSpirit:GetSpiritLevel()
    end

    if self.m_nCurrTarNum >= nTargetNum then
        self.m_bIsComplete = true
        self.m_bCanGetReward = true
        self:MarkDirty(true)
    end
end

function CTargetTask:SetNextTask(nCompTaskID)
    local nNextTaskID = ctTargetTaskConf[nCompTaskID].nNext
    if nNextTaskID == 0 then
        --领取奖励后，没有后续任务，发true表示全部完成
        return self:SendTargetTaskInfo()
    end
    assert(ctTargetTaskConf[nNextTaskID], "没有下个任务")
    self.m_nCurrTarNum = 0
    self.m_bIsComplete = false
    self.m_bCanGetReward = false
    self.m_bIsGetReward = false
    self.m_nTaskID = nNextTaskID
    self:MarkDirty(true)
    self:CheckState()
    self:SendTargetTaskInfo()
end

function CTargetTask:Online()
    local nNextTaskID = ctTargetTaskConf[self.m_nTaskID].nNext
    if nNextTaskID == 0 and self.m_bIsGetReward then
        return
    elseif nNextTaskID ~= 0 and self.m_bIsGetReward then    --追加配置时纠正并继续任务
        self:SetNextTask(self.m_nTaskID)
    else
        --检查状态
        self:CheckState()
        self:SendTargetTaskInfo()
    end
end
--[[
@param nValue   增加的次数或设置的数值或表(2个技能5级)
@param bIsAdd   true代表增加次数; false代表设置数值
]]
function CTargetTask:OnEventHandler(nTaskType, Value, bIsAdd)
    --更加事件类型累计记录
    if bIsAdd then
        local nOldTarNum = self.m_tCurrTarNumMap[nTaskType] or 0
        self.m_tCurrTarNumMap[nTaskType] = math.min(nOldTarNum + Value, 0x7fffffff)
    else
        self.m_tCurrTarNumMap[nTaskType] = Value  --Value= value or table
    end

    --检查
    self:MarkDirty(true)
    self:CheckState()
    if self.m_nTaskID >= self:GetMaxTaskID() and self.m_bIsGetReward then
        return
    else
        local nCurrTaskType = ctTargetTaskConf[self.m_nTaskID] and ctTargetTaskConf[self.m_nTaskID].nTaskType or 0          
        if self.m_nTaskID > 0 and nTaskType == nCurrTaskType then
            self:SendTargetTaskInfo()
        end
    end
end

function CTargetTask:BattleTrainReq()
    if self.m_nTaskID <= 0 then return end
    local tConf = self.m_oRole:GetDupConf()
    if tConf.nType == CDupBase.tType.eDup then
        return self.m_oRole:Tips("副本内不能完成任务")
    end
    local nCurrTaskType = ctTargetTaskConf[self.m_nTaskID].nTaskType
    if nCurrTaskType ~= gtTargetTask.eBattleTrain then
        return self.m_oRole:Tips("当前目标任务不是战斗训练任务")
    end
    local nMonsterID = ctTargetTaskConf[self.m_nTaskID].nMonsterID
    local oMonster = goMonsterMgr:CreateInvisibleMonster(nMonsterID)
    self.m_oRole:PVE(oMonster, {bTargetTask=true})
end

function CTargetTask:OnBattleEnd(bIsRoleWin)
    if bIsRoleWin then
        CEventHandler:OnBattleTrain(self.m_oRole)
    end
end

function CTargetTask:GetReward()
    if not self.m_bCanGetReward then
        return self.m_oRole:Tips("还不能领取奖励")
    end
    if self.m_bIsGetReward then
        return self.m_oRole:Tips("已领取过奖励")
    end
    assert(ctTargetTaskConf[self.m_nTaskID], "没有此任务")
    --固定奖励
    local tFixReward =  ctTargetTaskConf[self.m_nTaskID].tFixReward
    for _, tItem in pairs(tFixReward) do
        local nItemType = tItem[4]        
        self.m_oRole:AddItem(nItemType, tItem[1], tItem[2], "目标任务固定奖励", true, tItem[3])
    end

    --随机奖励
    local nAwardPoolID = ctTargetTaskConf[self.m_nTaskID].nAwardPoolID
    if ctAwardPoolConf.IsPoolExist(nAwardPoolID) then
        local nRoleLevel = self.m_oRole:GetLevel()
        local nRoleTypeID = self.m_oRole:GetConfID()
        local tRewardPool = ctAwardPoolConf.GetPool(nAwardPoolID, nRoleLevel, nRoleTypeID)
        if not next(tRewardPool) or tRewardPool == nil then return end        --奖励库没有符合的奖励
        local function GetWeight(tNode)
            return tNode.nWeight
        end
        local tRewardList = CWeightRandom:Random(tRewardPool, GetWeight, 1, false)
        self.m_oRole:AddItem(gtItemType.eProp, tRewardList[1].nItemID, tRewardList[1].nItemNum, "目标任务奖励")
    end
    self.m_bIsGetReward = true
    if nCurrTaskType ~= gtTargetTask.eCompAllTargetTask then
        CEventHandler:OnCompAllTargetTask(self.m_oRole, {nTargetTaskID=self.m_nTaskID})
    end
    goLogger:EventLog(gtEvent.eCompTargetTask, self.m_oRole,  self.m_nTaskID)

    --判断是否有后续事件(引导事件)
    if ctTargetTaskConf[self.m_nTaskID].bIsExecEvent then
        local nEventType = ctTargetTaskConf[self.m_nTaskID].nEventType
        self.m_tExecEvent[nEventType]()
    end
    self:SetNextTask(self.m_nTaskID)
    self.m_oRole.m_oSysOpen:OnTargetTaskCommit()
end

function CTargetTask:SendTargetTaskInfo()
    local tMsg = {}
    tMsg.nTaskID = self.m_nTaskID
    tMsg.nCurrTarNum = self.m_nCurrTarNum
    tMsg.bIsComplete = self.m_bIsComplete
    tMsg.bCanGetReward = self.m_bCanGetReward
    tMsg.bCompAllTask = (self.m_nTaskID >= self:GetMaxTaskID() and self.m_bIsGetReward) and true or false
    self.m_oRole:SendMsg("TargetTaskInfoRet", tMsg)
    --PrintTable(tMsg)
end

--注册后续执行事件
function CTargetTask:RegisterExecEvent()
    self.m_tExecEvent[1] = function() self:GivePet() end
    self.m_tExecEvent[2] = function() self:GetPartner() end
end

function CTargetTask:GivePet()
    local tConf = ctTargetTaskConf[self.m_nTaskID]
    local nPetID = tConf.tEventConf[1]
    self.m_oRole:AddItem(gtItemType.ePet, nPetID, 1, "目标任务后续的引导任务赠送")
end

function CTargetTask:GetPartner()
    local tConf = ctTargetTaskConf[self.m_nTaskID]
    for _, tPartner in pairs(tConf.tEventConf) do
        local nPlanID = tPartner[1]
        local nPartnerID = tPartner[2]
        self.m_oRole.m_oPartner:RecruitPartnerReq(nPartnerID)
        self.m_oRole.m_oPartner:BattleActiveReq(nPlanID, nPartnerID)
    end
end

function CTargetTask:GetCompTaskID()
    if self.m_nTaskID <= 0 then
        return 0
    else
        return ctTargetTaskConf[self.m_nTaskID].nPre
    end
end