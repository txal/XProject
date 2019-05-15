--个人节日活动
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CHolidayActivityMgr:Ctor(oRole)
    self.m_oRole = oRole
    self.m_tActObjList = {}

    self.m_nResetDataTimestamp = 0         --清空数据时间戳
    self.m_tActData = 
    {
        --个人活动记录数据(零点清零也要注册)
        nAnswerQuestionIdx = 0,             --学富五车当前题目索引
        nAnswerTimes = 0,                   --学富五车答题次数
        nAnswerEndTimestamp = 0,            --学富五车答题结束时间戳
        tQuestionIDList = {},               --学富五车题目ID列表

        nExperCompTimes = 0,                --江湖历练完成次数
        nExperTaskID = 0,                   --江湖历练任务ID
        nExperEndTimestamp = 0,             --江湖历练结束时间戳
        nExperTaskDupID = 0,                --江湖历练任务场景
        nExperTaskPosX = 0,                 --江湖历练任务坐标X
        nExperTaskPosY = 0,                 --江湖历练任务坐标Y
        nExperTaskItemID = 0,               --江湖历练提交物品ID
        nExperTaskCommNum = 0,              --江湖历练提交物品数量

        nTeachTestCompTimes = 0,            --尊师考验完成次数
        tTeachTestKillMonMap = {},          --尊师考验怪击杀次数映射

        nHorseRaceCompTimes = 0,            --策马奔腾完成次数
        bWasGetReward = false,              --策马奔腾是否已经领过奖励
        nContinuePass = 0,                  --策马奔腾连续答对题目数
    }

    self:Init()
end

function CHolidayActivityMgr:LoadData(tData)
    if tData then
        local tActData = tData.m_tActData
        self.m_nResetDataTimestamp = tData.m_nResetDataTimestamp or 0
        self.m_tActData.nAnswerQuestionIdx = tActData.nAnswerQuestionIdx or 0
        self.m_tActData.nAnswerTimes = tActData.nAnswerTimes or 0            
        self.m_tActData.nAnswerEndTimestamp = tActData.nAnswerEndTimestamp or 0
        for nIndex, nID in ipairs(self.m_tActData.tQuestionIDList) do
            self.m_tActData.tQuestionIDList[nIndex] = nID
        end
        self.m_tActData.nExperCompTimes = tActData.nExperCompTimes or 0
        self.m_tActData.nExperTaskID = tActData.nExperTaskID or 0
        self.m_tActData.nExperEndTimestamp = tActData.nExperEndTimestamp or 0
        self.m_tActData.nExperTaskDupID = tActData.nExperTaskDupID or 0
        self.m_tActData.nExperTaskPosX = tActData.nExperTaskPosX or 0
        self.m_tActData.nExperTaskPosY = tActData.nExperTaskPosY or 0
        self.m_tActData.nTeachTestCompTimes = tActData.nTeachTestCompTimes or 0
        self.m_tActData.nTeachTestTimestamp = tActData.nTeachTestTimestamp or 0
        self.m_tActData.tTeachTestKillMonMap =tActData.tTeachTestKillMonMap or {}

    end

    if self.m_nResetDataTimestamp <= 0 then
        self.m_nResetDataTimestamp = os.time()
        self:MarkDirty(true)
    end
end

function CHolidayActivityMgr:SaveData()
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)
    local tData = {}
    tData.m_nResetDataTimestamp = self.m_nResetDataTimestamp    
    tData.m_tActData = self.m_tActData
    return tData
end

function CHolidayActivityMgr:GetType()
    return gtModuleDef.tHolidayActivityMgr.nID, gtModuleDef.tHolidayActivityMgr.sName
end

function CHolidayActivityMgr:OnRelease()
    -- for _, oActObj in pairs(self.m_tActObjList) do
    --     oActObj:OnRelease()
    -- end
end

--零点清零
function CHolidayActivityMgr:ResetData()
    self.m_tActData.nAnswerQuestionIdx = 0
    self.m_tActData.nAnswerTimes = 0            
    self.m_tActData.nAnswerEndTimestamp = 0
    for nIndex, _ in ipairs(self.m_tActData.tQuestionIDList) do
        self.m_tActData.tQuestionIDList[nIndex] = nil
    end
    self.m_tActData.nExperCompTimes = 0
    self.m_tActData.nExperTaskID = 0
    self.m_tActData.nExperEndTimestamp = 0
    self.m_tActData.nExperTaskDupID = 0
    self.m_tActData.nExperTaskPosX = 0
    self.m_tActData.nExperTaskPosY = 0
    self.m_tActData.nTeachTestCompTimes = 0
    self.m_tActData.nTeachTestTimestamp = 0

    self:MarkDirty(true)
end

function CHolidayActivityMgr:Init()
    --读配置，根据月份配置实例化不同对象
    local nMonth = os.date("*t", os.time()).month
    local nRoleLevel = self.m_oRole:GetLevel()
    local tThisMonthActConf = ctHolidayActivityConf.GetMonthActConf(nMonth, nRoleLevel)
    for _, tConf in pairs(tThisMonthActConf) do
        if tConf.bIsOpen then
            local cClass = gtHolidayActClass[tConf.nHolidayActType]
            assert(cClass, "活动玩法未实现："..tConf.nHolidayActType)
            local oActObj = cClass:new(self.m_oRole, tConf.nActivityID, tConf.nHolidayActType)
            if oActObj then
                self.m_tActObjList[tConf.nActivityID] = oActObj
            end
        end
    end
end

function CHolidayActivityMgr:GetActByHolidayActType(nType)
    for nActID, oAct in pairs(self.m_tActObjList) do
        if oAct:GetActType() == nType then
            return oAct     --同种类型活动不会同一时间开多个
        end
    end
end

function CHolidayActivityMgr:Online()
    for _, oActObj in pairs(self.m_tActObjList) do
        oActObj:Online()
    end

    if not os.IsSameDay(self.m_nResetDataTimestamp, os.time(), 0) then
        self:ResetData()
        self.m_nResetDataTimestamp = os.time()
        self:MarkDirty(true)
    end
end

function CHolidayActivityMgr:OnMinTimer()
    --每分钟检测一次状态，调用所有子类检查
    for _, oActObj in pairs(self.m_tActObjList) do
        oActObj:OnMinTimer()
    end

    if not os.IsSameDay(self.m_nResetDataTimestamp, os.time(), 0) then
        self:ResetData()
        self.m_nResetDataTimestamp = os.time()
        self:MarkDirty(true)
    end
end

function CHolidayActivityMgr:SendAllActInfo()
    local tMsg = {tActInfoList={}}
    for _, oActObj in pairs(self.m_tActObjList) do 
        local tActInfo = oActObj:GetActStatusInfo()
        table.insert(tMsg.tActInfoList, tActInfo)
    end
    --print(">>>>>>>>>>>>>>>>>>>>>>节日活动信息列表")
    --PrintTable(tMsg)
end