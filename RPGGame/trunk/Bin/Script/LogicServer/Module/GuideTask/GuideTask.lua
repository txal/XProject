--指引任务
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

CGuideTask.tTaskType =
{
    eCountSinceBorn = 1,        --出生开始统计
    eCountSinceAccpt = 2,       --触发任务开始统计
}

--从新定义类型，不沿用目标任务的类型主要考虑到两个新增任务时，类型无非同步一致产生分歧
gtGuideTask = 
{
    eWashPetAttr = 1,               --宠物洗髓次数
    ePetCompose = 2,                --宠物合成
    eExcavateStone = 3,             --累计挖取灵石次数
    eGiveSthToPartner = 4,          --赠送东西给仙侣
    eJoinUnion = 5,                 --加入帮派次数
    eFaBaoCompose = 6,              --法宝合成次数
    eMarketItemOnSale = 7,          --摆摊道具上架次数
    eInviteMarryCount = 8,          --发布结婚信息统计次数
    ePetLianGu = 9,                 --宠物炼骨次数
    ePartnerUpStar = 10,            --仙侣升星次数
    ePetLearnSkill = 11,            --累计宠物学习技能次数
    eChamberCoreItemOnSale = 12,    --商会出售东西
}

_ctGuideTaskConf = {}     --{[nLevelLimit]={nTaskID}}

local function _PreProcessConf()
    for nTaskID, tConf in pairs(ctGuideTaskConf)do
        if not _ctGuideTaskConf[tConf.nLevelLimit] then
            _ctGuideTaskConf[tConf.nLevelLimit] = {}
        end
        assert(0 < tConf.nTaskType and tConf.nTaskType <= CGuideTask.tTaskType.eCountSinceAccpt, "指引任务配置任务类型有错，任务ID"..nTaskID)
        table.insert(_ctGuideTaskConf[tConf.nLevelLimit], tConf)
    end
end
_PreProcessConf()       --重导脚本时将配置重新导入预处理表中

function CGuideTask:Ctor(oRole)
    self.m_oRole = oRole
    self.m_tEventDataMap = {}     --任务类型统计数据{[nEventType]={[CGuideTask.tTaskType]=nTimes,}
    self.m_tTaskIDList = {}       --当前任务ID集合
    self.m_tCompTaskIDList = {}   --已经完成的任务 {[nTaskID]=true}
end

function CGuideTask:LoadData(tData)
    if tData then
        self.m_tEventDataMap = tData.m_tEventDataMap or self.m_tEventDataMap
        self.m_tTaskIDList = tData.m_tTaskIDList or self.m_tTaskIDList
        self.m_tCompTaskIDList = tData.m_tCompTaskIDList or self.m_tCompTaskIDList
    end
end

function CGuideTask:SaveData()
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)
    local tData = {}
    tData.m_tEventDataMap = self.m_tEventDataMap
    tData.m_tTaskIDList = self.m_tTaskIDList
    tData.m_tCompTaskIDList = self.m_tCompTaskIDList
    return tData
end

function CGuideTask:GetType()
    return gtModuleDef.tGuideTask.nID, gtModuleDef.tGuideTask.sName
end

function CGuideTask:AcceptTask()
    local nRoleLevel = self.m_oRole:GetLevel()
    for nLevel=0, nRoleLevel do
        --有可能经验太多存在跳级
        if _ctGuideTaskConf[nLevel] then
            for nIndex, tConf in pairs(_ctGuideTaskConf[nLevel]) do
                if not self.m_tCompTaskIDList[tConf.nTaskID] then
                    self.m_tTaskIDList[tConf.nTaskID] = true
                end
            end
        end
    end
    self:MarkDirty(true)
end

function CGuideTask:ClearTask(nTaskID)
    self.m_tTaskIDList[nTaskID] = nil
    self:MarkDirty(true)
end

function CGuideTask:RecordCompTask(nTaskID)
    self.m_tCompTaskIDList[nTaskID] = true
    self:MarkDirty(true)
end

--Data      Data数据类型可能是tabel或number
--bIsAdd    true代表增加次数; false代表设置数值
function CGuideTask:OnEventHandler(nEventType, Data, bIsAdd)
    --分两种情况，每次触发事件都记录出生开始统计的数据和有任务才记录的数据
    for nTaskType = CGuideTask.tTaskType.eCountSinceBorn, CGuideTask.tTaskType.eCountSinceAccpt do
        local bHadTask = false
        if nTaskType ~= CGuideTask.tTaskType.eCountSinceAccpt then
            bHadTask = true
        end
        -- print(">>>>>>>>>>>>任务类型:", nTaskType)
        -- print(">>>>>>>>>>>>是否有2类型任务", bHadTask)

        --记录从接到任务开始统计的数据时，先判断有没有事件的任务        
        if nTaskType == CGuideTask.tTaskType.eCountSinceAccpt then
            for nTaskID, _ in pairs(self.m_tTaskIDList) do
                local tConf = ctGuideTaskConf[nTaskID]
                -- if tConf.nEventType == nEventType then
                --     table.insert(tUpdateInfoTaskIDList, nTaskID)        --可能接了两个类型都一致的任务，任务ID和开放等级不一样
                -- end

                --任务列表中有任务事件类型和任务类型符合的才设置从接任务开始统计的数据                
                if tConf.nEventType == nEventType and tConf.nTaskType == CGuideTask.tTaskType.eCountSinceAccpt then
                    bHadTask = true
                end
            end
        end

        -- print(">>>>>>>>>>>>是否有2类型任务", bHadTask)
        if bHadTask then
            self.m_tEventDataMap[nEventType] = self.m_tEventDataMap[nEventType] or {}
            if bIsAdd then
                local nOldTarNum = self.m_tEventDataMap[nEventType][nTaskType] or 0
                self.m_tEventDataMap[nEventType][nTaskType] = nOldTarNum + Data
            else
                self.m_tEventDataMap[nEventType][nTaskType] = Data
            end
            self:MarkDirty(true)
            --更新任务的状态
            for nTaskID, _ in pairs(self.m_tTaskIDList) do
                local tConf = ctGuideTaskConf[nTaskID]
                --本事件的任务都刷新
                if tConf.nEventType == nEventType and tConf.nTaskType == nTaskType then
                    self:SendSingleTaskInfo(nTaskID)
                end
            end
        end
    end
end

--获取当前目标数
function CGuideTask:GetCurrTarNum(nTaskID)
    assert(ctGuideTaskConf[nTaskID], "任务ID错误:"..nTaskID)
    local nEventType = ctGuideTaskConf[nTaskID].nEventType
    local nTaskType = ctGuideTaskConf[nTaskID].nTaskType
    if not self.m_tEventDataMap[nEventType] then
        return 0
    end

    if type(self.m_tEventDataMap[nEventType][nTaskType]) == "table" then
        local nCond = ctGuideTaskConf[nTaskID].tParam[1][2]
        return self.m_tEventDataMap[nEventType][nTaskType][nCond] or 0
    else
        return (self.m_tEventDataMap[nEventType][nTaskType] or 0)
    end
end

--清空由触发任务开始统计的数据
function CGuideTask:ClearEventData(nTaskID)
    --领取奖励后调用此函数，清空数据, 当有同事件同类型的任务时先不清空数据
    --只能是累计次数的才能按接到任务时开始统计
    assert(ctGuideTaskConf[nTaskID], "任务ID错误:"..nTaskID)
    local nEventType = ctGuideTaskConf[nTaskID].nEventType
    local nTaskType = ctGuideTaskConf[nTaskID].nTaskType
    if self.m_tEventDataMap[nEventType] and self.m_tEventDataMap[nEventType][nTaskType] and nTaskType == CGuideTask.tTaskType.eCountSinceAccpt then
        local bHadSameEventTask = false
        --print(">>>>>>>>>>>>数据的类型", type(self.m_tEventDataMap[nEventType][nTaskType]))
        if type(self.m_tEventDataMap[nEventType][nTaskType]) == "number" then
            for nAccpetTaskID, _ in pairs(self.m_tTaskIDList) do
                local tTaskConf = ctGuideTaskConf[nAccpetTaskID]
                if nAccpetTaskID ~= nTaskID and tTaskConf.nEventType == nEventType and tTaskConf.nTaskType == nTaskType then
                    bHadSameEventTask = true
                    break
                end
            end
        end

        --这个地方有问题  没有清空数据
        --print(">>>>>>>>>>>>>>是否有相同的任务:", bHadSameEventTask)
        if not bHadSameEventTask then
            self.m_tEventDataMap[nEventType][nTaskType] = 0
            self:MarkDirty(true)
        end
    end
end

function CGuideTask:GetReward(nTaskID)
    assert(ctGuideTaskConf[nTaskID], "指引任务领取奖励,任务ID错误:"..nTaskID)
    -- assert(self.m_tTaskIDList[nTaskID], "指引任务领取奖励,任务ID错误:"..nTaskID)
    if not self.m_tTaskIDList[nTaskID] then --网络抖动问题，外网会频繁触发
        return 
    end
    local tConf = ctGuideTaskConf[nTaskID]
    local nEventType = tConf.nEventType
    local nTaskType = tConf.nTaskType
    local nCurrTarNum = self.m_tEventDataMap[nEventType][nTaskType]
    local bIsComplete = nCurrTarNum >= tConf.tParam[1][1] and true or false
    if not bIsComplete then
        self.m_oRole:Tips("该指引任务未完成,不能领取奖励")
        self:SendGetRewardRet(false, nTaskID)
        return
    end
    for nIndex, tItem in pairs(tConf.tReward) do
        self.m_oRole:AddItem(tItem[1], tItem[2], tItem[3], "完成指引任务奖励", false, tItem[4])
    end
    self:RecordCompTask(nTaskID)
    self:ClearEventData(nTaskID)
    self:ClearTask(nTaskID)
    self:SendGetRewardRet(true, nTaskID)
end

function CGuideTask:OnRoleLevelChange(nOldLevel, nNewLevel)
    self:AcceptTask()
    self:SendTaskInfoList()
end

function CGuideTask:Online()
    --上线检查可以接受哪些任务，检查哪些任务已经完成
    self:AcceptTask()
    self:SendTaskInfoList()
end

function CGuideTask:SendTaskInfoList()
    local tMsg = {tTaskList={}}
    for nTaskID, _ in pairs(self.m_tTaskIDList) do
        local tConf = ctGuideTaskConf[nTaskID]
        if tConf then
            local nEventType = tConf.nEventType
            local nTaskType = tConf.nTaskType
            local tTaskInfo = {}
            tTaskInfo.nTaskID = nTaskID
            local nCurrTarNum = self:GetCurrTarNum(nTaskID)
            tTaskInfo.nCurrTarNum = nCurrTarNum
            local bIsComplete = (nCurrTarNum >= tConf.tParam[1][1]) and true or false
            tTaskInfo.bIsComplete = bIsComplete
            tTaskInfo.bCanGetReward = bIsComplete
            table.insert(tMsg.tTaskList, tTaskInfo)
        end
    end
    -- print(">>>>>>>>>>>>>指引任务列表")
    -- PrintTable(tMsg)
    self.m_oRole:SendMsg("GuideTaskInfoListRet", tMsg)
end

function CGuideTask:SendSingleTaskInfo(nTaskID)
    local tMsg = {tTaskInfo={}}
    local tConf = ctGuideTaskConf[nTaskID]
    if tConf then
        local nEventType = tConf.nEventType
        local nTaskType = tConf.nTaskType
        tMsg.tTaskInfo.nTaskID = nTaskID
        local nCurrTarNum = self:GetCurrTarNum(nTaskID)
        tMsg.tTaskInfo.nCurrTarNum = nCurrTarNum
        local bIsComplete = (nCurrTarNum >= tConf.tParam[1][1]) and true or false
        tMsg.tTaskInfo.bIsComplete = bIsComplete
        tMsg.tTaskInfo.bCanGetReward = bIsComplete
        self.m_oRole:SendMsg("GuideTaskInfoRet", tMsg)    
        -- print(">>>>>>>>>>>>>指引任务信息")
        -- PrintTable(tMsg)    
    end
end

function CGuideTask:SendGetRewardRet(bIsGetRewardSucc, nTaskID)
    self.m_oRole:SendMsg("GuideTaskRewardRet", {bIsSucc=bIsGetRewardSucc, nTaskID=nTaskID})
end