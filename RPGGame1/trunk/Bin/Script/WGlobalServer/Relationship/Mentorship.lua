--师徒关系
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


--师徒关系
function CMentorship:Ctor(nRoleID, nStatus)
    self.m_nRoleID = nRoleID                                     --玩家ID
    -- self.m_nStatus = nStatus or gtMentorshipStatus.eApprentice   --目标玩家和自己的师徒关系(eMaster，对方是自己的师父)
    -- if self.m_nStatus ~= gtMentorshipStatus.eMaster and 
    --     self.m_nStatus ~= gtMentorshipStatus.eApprentice then 
    --     assert(false, "参数错误")
    -- end
    assert(nStatus)  --必须提供，防止发生错误
    self.m_nStatus = nStatus
    self.m_bUpgraded = false                               --是否已出师
    self.m_nActiveNum = 0                                  --徒弟活跃度
    self.m_tActiveRewardRecord = {}                        --活跃度奖励领取记录
    self.m_tTaskList = {}                                  --任务列表
    self.m_nTaskFlushCount = 0                             --任务刷新次数
    self.m_bTaskPublished = false                          --是否已发布
    self.m_nLastGreetTime = 0                              --最近一次给师父请安时间
    self.m_nLastTeachTime = 0                              --最近一次给徒弟指点时间
    self.m_nStamp = 0                                      --师徒关系时间戳
    self.m_bPublishTaskRemind = false
end

function CMentorship:LoadData(tData)
    if not tData then return end 
    self.m_nStatus = tData.nStatus or self.m_nStatus
    self.m_bUpgraded = tData.bUpgraded
    self.m_nActiveNum = tData.nActiveNum
    self.m_tActiveRewardRecord = tData.tActiveRewardRecord or {}
    self.m_tTaskList = tData.tTaskList
    self.m_nTaskFlushCount = tData.nTaskFlushCount
    self.m_bTaskPublished = tData.bTaskPublished
    self.m_nLastGreetTime = tData.nLastGreetTime or 0
    self.m_nLastTeachTime = tData.nLastTeachTime or 0
    self.m_nStamp = tData.nStamp
    self.m_bPublishTaskRemind = tData.bPublishTaskRemind or false
end

function CMentorship:SaveData()
    local tData = {}
    tData.nRoleID = self.m_nRoleID
    tData.nStatus = self.m_nStatus
    tData.bUpgraded = self.m_bUpgraded
    tData.nActiveNum = self.m_nActiveNum
    tData.tActiveRewardRecord = self.m_tActiveRewardRecord
    tData.tTaskList = self.m_tTaskList
    tData.nTaskFlushCount = self.m_nTaskFlushCount
    tData.bTaskPublished = self.m_bTaskPublished
    tData.nLastGreetTime = self.m_nLastGreetTime
    tData.nLastTeachTime = self.m_nLastTeachTime
    tData.nStamp = self.m_nStamp
    tData.bPublishTaskRemind = self.m_bPublishTaskRemind
    return tData
end

function CMentorship:GetID() return self.m_nRoleID end
function CMentorship:GetStamp() return self.m_nStamp end
function CMentorship:GetTime(nTimeStamp)
    nTimeStamp = nTimeStamp or os.time()
    return nTimeStamp - self.m_nStamp
end
--是否是(自己的)师父
function CMentorship:IsMaster() return self.m_nStatus == gtMentorshipStatus.eMaster end
--是否是(自己的)徒弟
function CMentorship:IsApprentice() return self.m_nStatus == gtMentorshipStatus.eApprentice end
--是否已出师
function CMentorship:IsUpgraded() return self.m_bUpgraded end
--是否是(自己的)已出师徒弟
function CMentorship:IsUpgradedApprentice() 
    return (self.m_nStatus == gtMentorshipStatus.eApprentice and self.m_bUpgraded)
end
--是否是(自己的)未出师徒弟
function CMentorship:IsFreshApprentice()
    return (self.m_nStatus == gtMentorshipStatus.eApprentice and not self.m_bUpgraded)
end

function CMentorship:SetUpgraded(bUpgraded) self.m_bUpgraded = bUpgraded end

function CMentorship:GetLastGreetTime() return self.m_nLastGreetTime end
function CMentorship:SetLastGreetTime(nTimeStamp)
    nTimeStamp = nTimeStamp or os.time()
    self.m_nLastGreetTime = nTimeStamp
end
function CMentorship:GetLastTeachTime() return self.m_nLastTeachTime end
function CMentorship:SetLastTeachTime(nTimeStamp) 
    nTimeStamp = nTimeStamp or os.time()
    self.m_nLastTeachTime = nTimeStamp
end

function CMentorship:CheckCanFlushTask()
    if self:IsUpgraded() then 
        return 
    end
    local oRole = goGPlayerMgr:GetRoleByID(self.m_nRoleID)
    if not oRole then 
        return 
    end
    if oRole:GetLevel() >= 70 then 
        return false
    end
    return true
end

function CMentorship:GetTask(nTaskID)
    for k, v in pairs(self.m_tTaskList) do
        if v.nID == nTaskID then
            return v 
        end
    end
end

--刷新师徒任务  --延迟到玩家获取师徒任务数据时才调用刷新
function CMentorship:FlushTask() 
    if self:IsUpgraded() then 
        return 
    end
    if not self:IsFreshApprentice() then
        return 
    end
    local fnGetWeight = function(tConf) return tConf.nWeight end
    local tConfTbl = ctMentorshipTaskConf
    local tRandResult = CWeightRandom:Random(tConfTbl, fnGetWeight, 3, true)
    assert(tRandResult and #tRandResult == 3)
    self.m_tTaskList = {}
    for _, tConf in pairs(tRandResult) do 
        local tTask = {}
        tTask.nID = tConf.nID
        tTask.nState = gtMentorshipTaskState.eUnpublished
        table.insert(self.m_tTaskList, tTask)
    end
end

function CMentorship:GetMaxActiveNum()
    local nConfMax = 0;
    for k, v in pairs(ctMentorActiveRewardConf) do 
        if v.nNum > nConfMax then 
            nConfMax = v.nNum
        end
    end
    return nConfMax
end

function CMentorship:IsActiveNumMax()
    local nConfMax = self:GetMaxActiveNum()
    return self.m_nActiveNum >= nConfMax
end

--添加活跃值
function CMentorship:AddActiveNum(nVal)
    if nVal == 0 then 
        return 
    end
    local nConfMax = self:GetMaxActiveNum()
    self.m_nActiveNum = math.max(math.min(self.m_nActiveNum + nVal, nConfMax), 0)
end

function CMentorship:SetTaskState(nTaskID, nState)
    assert(nTaskID > 0 and nState)
    for k, v in pairs(self.m_tTaskList) do 
        if v.nID == nTaskID then 
            v.nState = nState
            return true
        end
    end
    return false
end

function CMentorship:DailyReset()
    self.m_nActiveNum = 0                                  --徒弟活跃度
    self.m_tActiveRewardRecord = {}                        --活跃度奖励领取记录
    self.m_tTaskList = {}                                  --任务列表
    self.m_nTaskFlushCount = 0                             --任务刷新次数
    self.m_bTaskPublished = false                          --是否已发布
    self.m_bPublishTaskRemind = false                      --是否已提醒发布任务
end

function CMentorship:GetInfo()
    local tData = {}
    tData.nRoleID = self.m_nRoleID
    local oRole = goGPlayerMgr:GetRoleByID(self.m_nRoleID)
    tData.sName = oRole:GetName()
    tData.sHeader = oRole:GetHeader()
    tData.nGender = oRole:GetGender()
    tData.nSchool = oRole:GetSchool()
    tData.nLevel = oRole:GetLevel()
    tData.nTimeStamp = self.m_nStamp
    tData.nStatus = self.m_nStatus
    tData.bUpgraded = self.m_bUpgraded
    return tData
end

function CMentorship:GetRemainTaskFlushCount()
    local nRemain = 0
    nRemain = math.max(3 - self.m_nTaskFlushCount, 0)
    return nRemain
end

function CMentorship:AddTaskFlushCount(nNum)
    nNum = nNum or 1
    self.m_nTaskFlushCount = self.m_nTaskFlushCount + 1
end

function CMentorship:GetTaskData()
    local tData = {}
    tData.nRoleID = self.m_nRoleID
    local oRole = goGPlayerMgr:GetRoleByID(self.m_nRoleID)
    tData.sName = oRole:GetName()
    tData.sHeader = oRole:GetHeader()
    tData.nGender = oRole:GetGender()
    tData.nSchool = oRole:GetSchool()
    tData.sModel = oRole:GetModel()
    tData.nLevel = oRole:GetLevel()
    tData.nTimeStamp = self.m_nStamp
    tData.nStatus = self.m_nStatus
    tData.bUpgraded = self.m_bUpgraded
    tData.nActiveNum = self.m_nActiveNum
    tData.tActiveRewardRecord = {}
    for k, v in pairs(self.m_tActiveRewardRecord) do 
        table.insert(tData.tActiveRewardRecord, v)
    end
    if self:IsFreshApprentice() and self:CheckCanFlushTask() then --是自己的徒弟，则自己是师父
        tData.bTaskPublished = self.m_bTaskPublished
        tData.nTaskFlushCount = self:GetRemainTaskFlushCount()
        if #self.m_tTaskList <= 0 then 
            self:FlushTask()
        end
    end
    if self:IsMaster() then --是自己的师父，则自己是徒弟
        tData.bPublishTaskRemind = self.m_bPublishTaskRemind
    end
    tData.tTaskList = {}
    if #self.m_tTaskList > 0 then 
        for k, v in ipairs(self.m_tTaskList) do 
            local tTemp = {}
            tTemp.nTaskID = v.nID
            tTemp.nTaskState = v.nState
            table.insert(tData.tTaskList, tTemp)
        end
    end

    tData.tShapeData = oRole:GetShapeData()
    return tData
end


--------------------------------------------------------
--------------------------------------------------------
function CRoleMentorship:Ctor(nRoleID)
    self.m_nRoleID = nRoleID
    self.m_bUpgraded = false                  --自己是否已出师
    self.m_tRelationMap = {}                  --师徒数据{nRoleID:CMentorship, ...}
    self.m_nUpgradedApprenticeCount = 0       --总的出师徒弟数量
    self.m_nLastDeleteMaster = 0              --最近一次主动解除和师父关系的时间戳 
    self.m_nLastDeleteApprentice = 0          --最近一次主动解除和徒弟关系时间戳
    self.m_nLastInviteTalkStamp = 0           --最近一次招募发言时间戳，不存DB
    self.m_bDirty = false

    self.m_tInviteMasterSilenceMap = {}
    self.m_tInviteApprentSilenceMap = {}
end

function CRoleMentorship:MarkDirty(bDirty)
    self.m_bDirty = bDirty
    if self.m_bDirty then 
        goMentorshipMgr.m_tDirtyQueue:Push(self:GetID(), self)
    end
end
function CRoleMentorship:GetID() return self.m_nRoleID end
function CRoleMentorship:IsDirty() return self.m_bDirty end
function CRoleMentorship:LoadData(tData)
    if not tData then 
        return 
    end
    self.m_bUpgraded = tData.bUpgraded
    self.m_tRelationMap = {}
    for k, v in pairs(tData.tRelationMap) do 
        local nStatus = tData.nStatus or gtMentorshipStatus.eApprentice  --兼容旧的错误数据
        local oTemp = CMentorship:new(k, nStatus)
        oTemp:LoadData(v)
        self.m_tRelationMap[k] = oTemp
    end
    self.m_nUpgradedApprenticeCount = tData.nUpgradedApprenticeCount
    self.m_nLastDeleteMaster = tData.nLastDeleteMaster
    self.m_nLastDeleteApprentice = tData.nLastDeleteApprentice
    -- self.m_nLastInviteTalkStamp = tData.nLastInviteTalkStamp or self.m_nLastInviteTalkStamp
end
--自己是否已出师
function CRoleMentorship:IsUpgraded() return self.m_bUpgraded end

function CRoleMentorship:SaveData()
    local tData = {}
    tData.nRoleID = self.m_nRoleID
    tData.bUpgraded = self.m_bUpgraded
    tData.tRelationMap = {}
    for k, v in pairs(self.m_tRelationMap) do 
        local tTemp = v:SaveData()
        tData.tRelationMap[k] = tTemp
    end
    tData.nUpgradedApprenticeCount = self.m_nUpgradedApprenticeCount
    tData.nLastDeleteMaster = self.m_nLastDeleteMaster
    tData.nLastDeleteApprentice = self.m_nLastDeleteApprentice
    -- tData.nLastInviteTalkStamp = self.m_nLastInviteTalkStamp
    return tData
end

function CRoleMentorship:GetID() return self.m_nRoleID end
function CRoleMentorship:GetMentorship(nTarID) return self.m_tRelationMap[nTarID] end

function CRoleMentorship:OnAddMaster(nTarID)
	assert(nTarID and nTarID > 0)
	local oRole = goGPlayerMgr:GetRoleByID(self:GetID())
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
	assert(oRole and oTarRole)
	local nAppeID = gtAppellationIDDef.eApprentice
    oRole:AddAppellation(nAppeID, {tNameParam={oTarRole:GetName()}}, oTarRole:GetID())
end

function CRoleMentorship:OnRemoveMaster(nTarID)
    local oRole = goGPlayerMgr:GetRoleByID(self:GetID())
    assert(oRole)
    --可能未出师就断绝关系
	local nAppeID = gtAppellationIDDef.eApprentice
    oRole:RemoveAppellation(nAppeID, nTarID)
    local nAppeID = gtAppellationIDDef.eUpgradedApprentice
    oRole:RemoveAppellation(nAppeID, nTarID)
end

--移除师徒关系
function CRoleMentorship:RemoveMentorship(nTarID, bActive, nTimeStamp)
    nTimeStamp = nTimeStamp or os.time()
    local oMentorship = self:GetMentorship(nTarID)
    assert(oMentorship, "关系数据不存在")
    if bActive then 
        if oMentorship:IsMaster() then
            self.m_nLastDeleteMaster = nTimeStamp
        else
            self.m_nLastDeleteApprentice = nTimeStamp
        end
    end
    self.m_tRelationMap[nTarID] = nil
        
    if oMentorship:IsMaster() then 
        self:OnRemoveMaster(nTarID)
    end
    self:MarkDirty(true)
    goMentorshipMgr:SyncLogicCache(self:GetID())
end

function CRoleMentorship:IsExistMaster()
    for k, v in pairs(self.m_tRelationMap) do 
        if v:IsMaster() then 
            return true 
        end
    end
    return false
end

--获取师父数据  --当前只有一个师父
function CRoleMentorship:GetMaster()
    for k, v in pairs(self.m_tRelationMap) do 
        if v:IsMaster() then 
            return v
        end
    end
end

--获取徒弟数据
function CRoleMentorship:GetApprentice(nTarID)
    local oMentorship = self:GetMentorship(nTarID)
    if oMentorship then 
        if oMentorship:IsApprentice() then 
            return oMentorship
        else
            -- assert(false, "目标玩家不是徒弟")
        end
    end
end

--是否是自己师父
function CRoleMentorship:IsMaster(nTarID) 
    local oMentorship = self:GetMentorship(nTarID) 
    if oMentorship then 
        return oMentorship:IsMaster()
    end
    return false 
end

--是否是自己未出师的徒弟
function CRoleMentorship:IsFreshApprentice(nTarID)
    local oMentorship = self:GetMentorship(nTarID)
    if oMentorship then 
        return oMentorship:IsFreshApprentice()
    end
    return false
end

--获取未出师徒弟数量
function CRoleMentorship:GetFreshApprenticeCount()
    local nCount = 0
    for k, v in pairs(self.m_tRelationMap) do 
        if v:IsFreshApprentice() then 
            nCount = nCount + 1
        end
    end
    return nCount
end

function CRoleMentorship:GetApprenticeCount()
    local nCount = 0
    for k, v in pairs(self.m_tRelationMap) do 
        if v:IsApprentice() then 
            nCount = nCount + 1
        end
    end
    return nCount
end

--是否是师徒关系
function CRoleMentorship:IsMentorship(nTarID)
    if self:GetMentorship(nTarID) then 
        return true 
    end
    return false
end

--自己作为徒弟，晋级(出师)
function CRoleMentorship:OnUpgrade(nTarID)
    assert(nTarID and nTarID > 0)
	local oRole = goGPlayerMgr:GetRoleByID(self:GetID())
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
    assert(oRole and oTarRole)
    
	local nAppeID = gtAppellationIDDef.eApprentice
    oRole:RemoveAppellation(nAppeID, nTarID)

	local nAppeID = gtAppellationIDDef.eUpgradedApprentice
    oRole:AddAppellation(nAppeID, {tNameParam={oTarRole:GetName()}}, oTarRole:GetID())
end

--徒弟晋级(出师)
function CRoleMentorship:OnApprenticeUpgrade(nApprenticeID)
    self.m_nUpgradedApprenticeCount = self.m_nUpgradedApprenticeCount + 1
    --do something
end

--添加活跃值
function CRoleMentorship:AddActiveNum(nVal)
    if not nVal or nVal == 0 then 
        return 
    end
    -- if self:IsUpgraded() then --已出师的，不关注
    --     return 
    -- end
    -- local oMaster = self:GetMaster()
    -- if not oMaster or oMaster:IsActiveNumMax() then 
    --     return 
    -- end
    -- local nMasterID = oMaster:GetID()
    -- local oMasterData = goMentorshipMgr:GetRoleMentorship(nMasterID)
    -- assert(oMasterData)
    -- local oApprentice = oMasterData:GetMentorship(self:GetID())
    -- assert(oMasterData)
    -- oMaster:AddActiveNum(nVal)
    -- oApprentice:AddActiveNum(nVal)
    -- goMentorshipMgr:UpdateMentorshipTaskData(self:GetID(), nMasterID)
    -- goMentorshipMgr:UpdateMentorshipTaskData(nMasterID, self:GetID())
    -- self:MarkDirty(true)
    -- oMasterData:MarkDirty(true)

    --师徒关系活跃度逻辑修改为 
    --自己是师父，就看自己三个徒弟的活跃（从每个徒弟那各自可以领取一次）
    --自己是徒弟，就看自己师父的活跃

    --检查自己是否出师, 查找是否有师父, 给自己师父的玩家数据中的徒弟数据(ID自己)增加活跃值
    if not self:IsUpgraded() then 
        local oMaster = self:GetMaster()
        if oMaster then 
            local nMasterID = oMaster:GetID()
            local oMasterData = goMentorshipMgr:GetRoleMentorship(nMasterID)
            assert(oMasterData)
            local oApprentice = oMasterData:GetMentorship(self:GetID())
            assert(oMasterData)
            if not oApprentice:IsActiveNumMax() then 
                oApprentice:AddActiveNum(nVal)
                oMasterData:MarkDirty(true)
                goMentorshipMgr:UpdateMentorshipTaskData(nMasterID, self:GetID())
            end
        end
    end

    --查找是否有未出师徒弟, 如果有徒弟, 给自己徒弟的玩家数据中的师父数据(ID自己)增加活跃值
    for nTarID, oSelfApprentice in pairs(self.m_tRelationMap) do 
        if oSelfApprentice:IsFreshApprentice() then 
            local oApprenticeData = goMentorshipMgr:GetRoleMentorship(nTarID)
            if oApprenticeData then 
                local oApprentMaster = oApprenticeData:GetMaster()
                if oApprentMaster and oApprentMaster:GetID() == self:GetID() then 
                    if not oApprentMaster:IsActiveNumMax() then 
                        oApprentMaster:AddActiveNum(nVal)
                        oApprenticeData:MarkDirty(true)
                        goMentorshipMgr:UpdateMentorshipTaskData(nTarID, self:GetID())
                    end
                else
                    LuaTrace("玩家师徒数据错误!!!")
                    if gbInnerServer then 
                        assert(false, "数据错误")
                    end
                end
            end
        end
    end
end

function CRoleMentorship:DailyReset()
    local bChange = false
    for k, v in pairs(self.m_tRelationMap) do 
        v:DailyReset()
        bChange = true
    end
    if bChange then
        self:MarkDirty(true)
    end
end

function CRoleMentorship:CheckMentorshipTimeLimit(bMaster, nTimeStamp)
    nTimeStamp = nTimeStamp or os.time()
    if bMaster then 
        return math.abs(nTimeStamp - self.m_nLastDeleteApprentice) >= 24*3600
    else
        return math.abs(nTimeStamp - self.m_nLastDeleteMaster) >= 24*3600
    end
end

function CRoleMentorship:DoUpgrade(nTarID)
    local oMentorship = self:GetMentorship(nTarID)
    if not oMentorship then 
        return 
    end
    oMentorship.m_bUpgraded = true
    oMentorship.m_nActiveNum = 0
    oMentorship.m_tTaskList = {}
    if oMentorship:IsMaster() then  --对方是自己的师父，即自己出师了
        self.m_bUpgraded = true
        self:OnUpgrade(nTarID)
    else
        self:OnApprenticeUpgrade()
    end
    self:MarkDirty(true)
    goMentorshipMgr:SyncLogicCache(self:GetID())
end

--添加徒弟
function CRoleMentorship:AddApprentice(nTarID, nTimeStamp)
    nTimeStamp = nTimeStamp or os.time()
    local oApprentice = CMentorship:new(nTarID, gtMentorshipStatus.eApprentice)
    oApprentice.m_nStamp = nTimeStamp
    self.m_tRelationMap[nTarID] = oApprentice
    if oApprentice:CheckCanFlushTask() then 
        oApprentice:FlushTask()
    end
    self:MarkDirty(true)
    goMentorshipMgr:SyncLogicCache(self:GetID())
end

--添加师父
function CRoleMentorship:AddMaster(nTarID, nTimeStamp)
    if self:IsExistMaster() then 
        assert(false, "数据错误，当前已有师父")
    end
    nTimeStamp = nTimeStamp or os.time()
    local oMaster = CMentorship:new(nTarID, gtMentorshipStatus.eMaster)
    oMaster.m_nStamp = nTimeStamp
    self.m_tRelationMap[nTarID] = oMaster
    self:OnAddMaster(nTarID)
    self:MarkDirty(true)
    goMentorshipMgr:SyncLogicCache(self:GetID())
end

--插入邀请屏蔽列表
function CRoleMentorship:InsertMasterInviteSilenceMap(nRoleID)
	self.m_tInviteMasterSilenceMap[nRoleID] = os.time()
end

function CRoleMentorship:IsInMasterInviteSilenceMap(nRoleID)
	if not nRoleID then 
		return false 
	end
	return self.m_tInviteMasterSilenceMap[nRoleID] and true or false
end

function CRoleMentorship:CleanMasterInviteSilenceMap()
	self.m_tInviteMasterSilenceMap = {}
end

function CRoleMentorship:InsertApprentInviteSilenceMap(nRoleID)
	self.m_tInviteApprentSilenceMap[nRoleID] = os.time()
end

function CRoleMentorship:IsInApprentInviteSilenceMap(nRoleID)
	if not nRoleID then 
		return false 
	end
	return self.m_tInviteApprentSilenceMap[nRoleID] and true or false
end

function CRoleMentorship:CleanApprentInviteSilenceMap()
	self.m_tInviteApprentSilenceMap = {}
end

--------------------------------------------------------
--------------------------------------------------------
--师徒关系管理
function CMentorshipMgr:Ctor()
    self.m_tRoleMap = {}               --玩家数据列表
    self.m_tDirtyQueue = CUniqCircleQueue:new()
    self.m_nLastDailyResetStamp = 0
    self.m_bDirty = false
    self.m_nTimer = nil
end

function CMentorshipMgr:Init()
    self:LoadData()
    self.m_nTimer =  GetGModule("TimerMgr"):Interval(20, function () self:OnTimer() end)
end

function CMentorshipMgr:Release()
    GetGModule("TimerMgr"):Clear(self.m_nTimer)
    self:SaveData()
end

function CMentorshipMgr:MarkDirty(bDirty) 
    self.m_bDirty = bDirty
end
function CMentorshipMgr:IsDirty() return self.m_bDirty end

function CMentorshipMgr:SaveSysData()
    if not self:IsDirty() then 
        return 
    end
    local tData = {}
    tData.nLastDailyResetStamp = self.m_nLastDailyResetStamp
    local oDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
    oDB:HSet(gtDBDef.sMentorshipDB, "sysdata", cjson.encode(tData))

    self:MarkDirty(false)
end

--停服保存所有
function CMentorshipMgr:SaveData()
    self:SaveSysData()
    local oDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
    while self.m_tDirtyQueue:Count() > 0 do
		local oRoleMentorData, nRoleID = self.m_tDirtyQueue:Head()
		local tData = oRoleMentorData:SaveData()
        oDB:HSet(gtDBDef.sRoleMentorDB, oRoleMentorData:GetID(), cjson.encode(tData))
        self.m_tDirtyQueue:Pop() --成功后才pop，防止DB断开连接，导致数据丢失
	end
end

function CMentorshipMgr:LoadSysData()
    local oDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
    local sData = oDB:HGet(gtDBDef.sMentorshipDB, "sysdata")
    if sData ~= "" then 
        local tData = cjson.decode(sData)
        if tData then 
            self.m_nLastDailyResetStamp = tData.nLastDailyResetStamp or self.m_nLastDailyResetStamp
        end
    end
end

function CMentorshipMgr:LoadData()
    self:LoadSysData()

    local oDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
    local tKeys = oDB:HKeys(gtDBDef.sRoleMentorDB)
	for _, sRoleID in ipairs(tKeys) do
		local sData = oDB:HGet(gtDBDef.sRoleMentorDB, sRoleID)
		local tData = cjson.decode(sData)
		local nRoleID = tData.nRoleID
		local oRoleMentorData = CRoleMentorship:new(nRoleID)
		oRoleMentorData:LoadData(tData)
        self.m_tRoleMap[nRoleID] = oRoleMentorData
    end
    
    self:CheckDailyReset()
end

function CMentorshipMgr:TickSave()
    self:SaveSysData()
    local oDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
    local nDirtyNum = self.m_tDirtyQueue:Count()
    if nDirtyNum <= 0 then 
        return 
    end
    local nSaveNum = math.min(nDirtyNum, 2000)
	for i = 1, nSaveNum do
        local oRoleMentorData = self.m_tDirtyQueue:Head()
		if oRoleMentorData then
			local tData = oRoleMentorData:SaveData()
			oDB:HSet(gtDBDef.sRoleMentorDB, oRoleMentorData:GetID(), cjson.encode(tData))
            oRoleMentorData:MarkDirty(false)
        end
        self.m_tDirtyQueue:Pop()
	end
end

function CMentorshipMgr:DailyReset(nTimeStamp)
    nTimeStamp = nTimeStamp or os.time()
    print("师徒数据跨天清理")
    for k, oRoleData in pairs(self.m_tRoleMap) do 
        oRoleData:DailyReset()
    end
    self.m_nLastDailyResetStamp = nTimeStamp
    self:MarkDirty(true)
end

function CMentorshipMgr:CheckDailyReset()
    local nTimeStamp = os.time()
    if os.IsSameDay(nTimeStamp, self.m_nLastDailyResetStamp) then 
        return
    end
    self:DailyReset(nTimeStamp)
end

function CMentorshipMgr:OnTimer()
    self:CheckDailyReset()
    self:TickSave()
end

function CMentorshipMgr:GetRoleMentorship(nRoleID) return self.m_tRoleMap[nRoleID] end
function CMentorshipMgr:GetMentorship(nRoleID, nTarID)
    local oRoleData = self:GetRoleMentorship(nRoleID)
    if not oRoleData then 
        return 
    end
    return oRoleData:GetMentorship(nTarID)
end

--是否存在师徒关系
function CMentorshipMgr:IsMentorship(nRoleID, nTarID)
    assert(nRoleID and nTarID and nRoleID > 0 and nTarID > 0, "参数错误")
    local oRoleMent = self:GetMentorship(nRoleID, nTarID)
    local oTarMent = self:GetMentorship(nTarID, nRoleID)
    if oRoleMent and oTarMent then 
        return true 
    end
    return false
end

function CMentorshipMgr:InsertRoleData(nRoleID) 
    assert(nRoleID and nRoleID > 0, "参数错误")
    if self:GetRoleMentorship(nRoleID) then 
        assert(false, "数据已存在")
    end
    local oRoleData = CRoleMentorship:new(nRoleID)
    self.m_tRoleMap[nRoleID] = oRoleData
    oRoleData:MarkDirty(true)
end

function CMentorshipMgr:OnRoleOnline(oRole)
    if oRole:IsRobot() then 
        return 
    end
    local nRoleID = oRole:GetID()
    if not self:GetRoleMentorship(nRoleID) then 
        self:InsertRoleData(nRoleID)
    end
    local oRoleMent = self:GetRoleMentorship(oRole:GetID())
    oRoleMent:CleanMasterInviteSilenceMap()
    oRoleMent:CleanApprentInviteSilenceMap()
    self:SyncLogicCache(nRoleID)
    self:SyncMentorshipTaskData(nRoleID)
end

function CMentorshipMgr:OnRoleOffline(oRole)
    local oRoleMent = self:GetRoleMentorship(oRole:GetID())
    if not oRoleMent then 
        return 
    end
    oRoleMent:CleanMasterInviteSilenceMap()
    oRoleMent:CleanApprentInviteSilenceMap()
end

--角色活跃度变化
function CMentorshipMgr:OnActiveNumChange(nRoleID, nVal)
    assert(nRoleID and nVal)
    local oRoleMentorship = self:GetRoleMentorship(nRoleID)
    if not oRoleMentorship then 
        return 
    end
    -- local bUpgraded = oRoleMentorship:IsUpgraded()
    -- local oMaster = oRoleMentorship:GetMaster()  -- CMentorship  玩家身上的师父关系
    -- if bUpgraded or not oMaster then --已出师或者不存在师父的，不需要关注活跃值变化
    --     return
    -- end
    --[[ local nMasterID = oMaster:GetID()
    local oRoleMaster = goGPlayerMgr:GetRoleByID(nMasterID)
    local oMasterMentorship = self:GetRoleMentorship(nMasterID)
    assert(oRoleMaster and oMasterMentorship) --todo 师父角色删除后，也会找不到
    local oApprentice = oMasterMentorship:GetApprentice(nRoleID)  --师父身上的徒弟关系
    assert(oApprentice)
    oMaster:AddActiveNum(nVal)
    oApprentice:AddActiveNum(nVal) ]]
    oRoleMentorship:AddActiveNum(nVal)
end

function CMentorshipMgr:MentorshipCheck(nMasterID, nApprenticeID)
    assert(nMasterID > 0 and nApprenticeID > 0 and nMasterID ~= nApprenticeID, "参数错误")
    local oRoleMaster = goGPlayerMgr:GetRoleByID(nMasterID)
    local oRoleApprentice = goGPlayerMgr:GetRoleByID(nApprenticeID)
    assert(oRoleMaster and oRoleApprentice)

    local bCanMentorship = false
    local tCheckList = 
    {
        bOnline = true,               --两人组队，师父为队长，且两人处于非暂离或离线状态
        bLevel = true,              --徒弟等级>=25级，师父等级>=徒弟等级
        bMasterAndUpgraded = true,  --徒弟当前没有师父，且没有出师
        bApprenticeLimit = true,    --师父徒弟数量未满
        bMentorship = true,         --双方之间不存在师徒关系，且24小时内没有解除过师徒关系
        bFriend = true,             --双方互为好友，且亲密度>=50
    }

    if not oRoleMaster:IsOnline() or not oRoleApprentice:IsOnline() then 
		tCheckList.bOnline = false
	end

    --检查等级
	if not (oRoleApprentice:GetLevel() >= 25 and oRoleMaster:GetLevel() >= oRoleApprentice:GetLevel()) then
		tCheckList.bLevel = false
    end

    if CUtil:IsRobot(nMasterID) or CUtil:IsRobot(nApprenticeID) then 
        tCheckList.bMasterAndUpgraded = false
        tCheckList.bApprenticeLimit = false
        tCheckList.bMentorship = false
        tCheckList.bFriend = false
    else
        --检查徒弟当前没有师父且没有出师
        local oMasterMent = self:GetRoleMentorship(nMasterID)
        local oApprenticeMent = self:GetRoleMentorship(nApprenticeID)
        assert(oMasterMent and oApprenticeMent, "数据错误") --因为队伍关系保存，外网可能有玩家长时间未上线
        if oApprenticeMent:IsExistMaster() or oApprenticeMent:IsUpgraded() then 
            tCheckList.bMasterAndUpgraded = false
        end
        --检查师父的未出师徒弟数量
        if oMasterMent:GetFreshApprenticeCount() >= 3 then 
            tCheckList.bApprenticeLimit = false
        end
        --双方不存在师徒关系且24小时内没主动解除过师徒关系
        if self:IsMentorship(nMasterID, nApprenticeID) then 
            tCheckList.bMentorship = false
        end
        local nTimeStamp = os.time()
        if not oMasterMent:CheckMentorshipTimeLimit(true, nTimeStamp) 
            or not oApprenticeMent:CheckMentorshipTimeLimit(false, nTimeStamp) then 
            tCheckList.bMentorship = false
        end
        --检查好友关系及亲密度
        local oMasterFriend = goFriendMgr:GetFriend(nMasterID, nApprenticeID)
        local oApprenticeFriend = goFriendMgr:GetFriend(nApprenticeID, nMasterID)
        if not oMasterFriend or not oApprenticeFriend then  --如果角色被删除，也会不存在
            tCheckList.bFriend = false	
        else
            if oMasterFriend:GetDegrees() < 50 or oApprenticeFriend:GetDegrees() < 50 then
                tCheckList.bFriend = false
            end
        end
    end

    bCanMentorship = true
	for k, v in pairs(tCheckList) do
		if v == false then
			bCanMentorship = false
			break
		end
    end
    return bCanMentorship, tCheckList
end

--出师条件检查
function CMentorshipMgr:UpgradeCheck(nRoleID)
    assert(nRoleID, "参数错误")
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    assert(oRole)
    local oRoleMentorship = self:GetRoleMentorship(nRoleID)
    assert(oRoleMentorship)
    local bCanUpgrade = false
    local tCheckList = {
        bLevel = true,           --徒弟方达到50级
        bTime = true,            --拜师时间达到7天
        bFriendDegree = true,    --师徒双方亲密度>=300
    }
    local bUpgraded = oRoleMentorship:IsUpgraded()
    local oMaster = oRoleMentorship:GetMaster()  -- CMentorship
    if bUpgraded or  not oMaster then  --如果已出师或者没有师父，所有都置false
        for k, v in pairs(tCheckList) do
			tCheckList[k] = false
		end
		return bCanUpgrade, tCheckList
    end
    local nMasterID = oMaster:GetID()
    local oRoleMaster = goGPlayerMgr:GetRoleByID(nMasterID)
    local oMasterMentorship = self:GetRoleMentorship(nMasterID)
    assert(oRoleMaster and oMasterMentorship) --todo 师父角色删除后，会找不到

    --等级达到50级
    if oRole:GetLevel() < 50 then 
        tCheckList.bLevel = false
    end
    --拜师时间达到7天
    if oMaster:GetTime() < (7*24*3600) then 
        tCheckList.bTime = false
    end
    --师徒双方亲密度>=300
    local oRoleFriend = goFriendMgr:GetFriend(nRoleID, nMasterID)
    local oMasterFriend = goFriendMgr:GetFriend(nMasterID, nRoleID)
	if not oRoleFriend or not oMasterFriend then
		tCheckList.bFriendDegree = false	
	else
		if oRoleFriend:GetDegrees() < 300 or oMasterFriend:GetDegrees() < 300 then
			tCheckList.bFriendDegree = false
		end
	end

    bCanUpgrade = true
	for k, v in pairs(tCheckList) do
		if v == false then
			bCanUpgrade = false
			break
		end
    end
    return bCanUpgrade, tCheckList
end

---------------------------------------------------------------
--同步师徒数据
function CMentorshipMgr:SyncRoleMentorshipData(nRoleID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole or not oRole:IsOnline() then 
        return 
    end
    local oRoleMentorship = self:GetRoleMentorship(nRoleID)
    if not oRoleMentorship then 
        self:InsertRoleData(nRoleID)
        oRoleMentorship = self:GetRoleMentorship(nRoleID)
    end
    local tMsg = {}
    tMsg.tApprenticeList = {}
    tMsg.tSchoolList = {}
    for k, v in pairs(oRoleMentorship.m_tRelationMap) do 
        if v:IsApprentice() then 
            local tTemp = v:GetInfo()
            table.insert(tMsg.tApprenticeList, tTemp)
        end
    end
    local oMaster = oRoleMentorship:GetMaster()
    if oMaster then 
        local nMasterID = oMaster:GetID()
        tMsg.tMaster = oMaster:GetInfo()
        --同门信息
        local oMasterMentorship = self:GetRoleMentorship(nMasterID)
        if oMasterMentorship then --可能删号
             for k, v in pairs(oMasterMentorship.m_tRelationMap) do 
                if k ~= nRoleID then 
                    local tTemp = v:GetInfo()
                    table.insert(tMsg.tSchoolList, tTemp)
                end
            end
        end
    end
    tMsg.bUpgraded = oRoleMentorship:IsUpgraded()
    oRole:SendMsg("MentorshipInfoRet", tMsg)
end

--同步师徒任务数据   --针对在线玩家，跨天结算时，需要发送下，清理掉任务
function CMentorshipMgr:SyncMentorshipTaskData(nRoleID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole or not oRole:IsOnline() then 
        return 
    end
    local oRoleMentorship = self:GetRoleMentorship(nRoleID)
    assert(oRoleMentorship)
    local tMsg = {}
    local oMaster = oRoleMentorship:GetMaster()
    if oMaster then 
        tMsg.tMaster = oMaster:GetTaskData()
    end
    tMsg.tApprenticeList = {}
    for k, v in pairs(oRoleMentorship.m_tRelationMap) do 
        if v:IsFreshApprentice() then 
            local tTemp = v:GetTaskData()
            table.insert(tMsg.tApprenticeList, tTemp)
        end
    end
    oRole:SendMsg("MentorshipTaskDataListRet", tMsg)
    -- print("MentorshipTaskDataListRet:", tMsg)
end

--更新师徒任务数据
function CMentorshipMgr:UpdateMentorshipTaskData(nRoleID, nTarID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole or not oRole:IsOnline() then 
        return 
    end
    local oRoleMentorship = self:GetRoleMentorship(nRoleID)
    assert(oRoleMentorship)
    local oMentorship = oRoleMentorship:GetMentorship(nTarID)
    assert(oMentorship)
    local tMsg = {}
    tMsg.tData = oMentorship:GetTaskData()
    oRole:SendMsg("MentorshipTaskDataUpdateRet", tMsg)
end

--师徒关系检查请求
function CMentorshipMgr:MentorshipCheckReq(oRole, nTarRoleID, bTarMaster)
    local nRoleID = oRole:GetID()
    if nTarRoleID <= 0 or nRoleID == nTarRoleID then 
        oRole:Tips("参数错误")
        return
    end
    local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID) 
    if not oTarRole then --防止对离线机器人发起申请或者错误数据
        oRole:Tips("对方已离线")
        return 
    end
    local bCanMentorship, tCheckList
    if bTarMaster then 
        bCanMentorship, tCheckList = self:MentorshipCheck(nTarRoleID, nRoleID)
    else
        bCanMentorship, tCheckList = self:MentorshipCheck(nRoleID, nTarRoleID)
    end
    local tMsg = {}
    tMsg.bOnline = tCheckList.bOnline
    tMsg.bLevel = tCheckList.bLevel
    tMsg.bMasterAndUpgraded = tCheckList.bMasterAndUpgraded
    tMsg.bApprenticeLimit = tCheckList.bApprenticeLimit
    tMsg.bMentorship = tCheckList.bMentorship
    tMsg.bFriend = tCheckList.bFriend
    tMsg.nTarRoleID = nTarRoleID
    tMsg.bTarMaster = bTarMaster and true or false
    oRole:SendMsg("MentorshipCheckRet", tMsg)
end

function CMentorshipMgr:IsSysOpen(oRole, bTips)
    if not oRole then 
        return false 
    end
    return oRole:IsSysOpen(58, bTips)
end

--拜师请求
function CMentorshipMgr:MentorshipDealMasterReq(oRole, nMasterID)
    assert(oRole, "参数错误")
    if not nMasterID or nMasterID <= 0 then 
        oRole:Tips("参数错误")
        return 
    end
    local oRoleMaster = goGPlayerMgr:GetRoleByID(nMasterID)
    if not oRoleMaster then 
        oRole:Tips("对方已离线")
        return 
    end

    local nRoleID = oRole:GetID()
    local nApprenticeID = nRoleID
    local oRoleApprentice = oRole

    local bCanMentorship, tCheckList = self:MentorshipCheck(nMasterID, nApprenticeID)
    if not bCanMentorship then 
        return oRole:Tips("结成师徒条件不满足")
    end

    if not self:IsSysOpen(oRoleMaster, true) then 
        oRoleApprentice:Tips("对方功能未开启")
        return 
    end
    if not self:IsSysOpen(oRoleApprentice, true) then 
        oRoleMaster:Tips("对方功能未开启")
        return 
    end

    local oMasterData = self:GetRoleMentorship(nMasterID)
    local oApprenticeData = self:GetRoleMentorship(nApprenticeID)
    assert(oMasterData and oApprenticeData)
    if oMasterData:IsInMasterInviteSilenceMap(nApprenticeID) then 
        oRole:Tips("对方婉拒了你的请求")
        return 
    end

    local nApprenticeNum = oMasterData:GetApprenticeCount()
    if nApprenticeNum >= 100 then  --暂时加个保护限制，等外网存在100个徒弟，再询问策划，防止数据无限膨胀
        if nRoleID == nMasterID then 
            oRole:Tips("当前徒弟数量已达系统限制，无法继续收徒")
        else
            oRole:Tips("对方徒弟数量已达系统限制，无法继续收徒")
        end
        return
    end

    local fnConfirmCallback = function (tData)
        if not tData then 
            return oRole:Tips("申请已超时，请重新申请")
        end
        if tData.nSelIdx == 1 then  --拒绝
            oRole:Tips("对方婉拒了你的请求")
            if tData.nTypeParam and tData.nTypeParam > 0 then 
                oMasterData:InsertMasterInviteSilenceMap(oRole:GetID())
            end
			return
        elseif tData.nSelIdx == 2 then  --确定
            if self:IsMentorship(nMasterID, nApprenticeID) then --可能重复多次请求
                return
            end
            local nTimeStamp = os.time()
            oMasterData:AddApprentice(nApprenticeID, nTimeStamp)
            oApprenticeData:AddMaster(nMasterID, nTimeStamp)
            self:SyncRoleMentorshipData(nMasterID)
            self:SyncRoleMentorshipData(nApprenticeID)
            oRoleMaster:Tips(string.format("恭喜你收%s为徒", oRoleApprentice:GetName()))
            oRoleApprentice:Tips(string.format("恭喜你拜%s为师", oRoleMaster:GetName()))
            local sMailTitle = "拜师信息"
            local sMasterMailConf = ctTalkConf["mastertipsmail"].sContent
            local sMasterMailContent = string.format(sMasterMailConf, oRoleApprentice:GetName(), nApprenticeID)
            oRoleMaster:SendSysMail(sMailTitle, sMasterMailContent, {})
            local sApprentMailConf = ctTalkConf["apprenttipsmail"].sContent
            local sApprenticeMailContent = string.format(sApprentMailConf, oRoleMaster:GetName())
            oRoleApprentice:SendSysMail(sMailTitle, sApprenticeMailContent, {})

            self:SyncMentorshipTaskData(nMasterID)
            self:SyncMentorshipTaskData(nApprenticeID)
        end
    end

    local sCont = string.format("%s想拜你为师，是否同意？", oRole:GetName())
    local tMsg = {sCont=sCont, tOption={"拒绝", "确定"}, nTimeOut=30, nType=5, nTypeParam=nRoleID}
    goClientCall:CallWait("ConfirmRet", fnConfirmCallback, oRoleMaster, tMsg)
    oRole:Tips(string.format("已请求拜%s为师，正在等待回复", oRoleMaster:GetName()))
end

--收徒请求
function CMentorshipMgr:MentorshipDealApprentReq(oRole, nApprenticeID)
    assert(oRole, "参数错误")
    if not nApprenticeID or nApprenticeID <= 0 then 
        oRole:Tips("参数错误")
        return 
    end
    local oRoleApprentice = goGPlayerMgr:GetRoleByID(nApprenticeID)
    if not oRoleApprentice then 
        oRole:Tips("对方已离线")
        return 
    end

    local nRoleID = oRole:GetID()
    local nMasterID = nRoleID
    local oRoleMaster = oRole

    local bCanMentorship, tCheckList = self:MentorshipCheck(nMasterID, nApprenticeID)
    if not bCanMentorship then 
        return oRole:Tips("结成师徒条件不满足")
    end

    if not self:IsSysOpen(oRoleMaster, true) then 
        oRoleApprentice:Tips("对方功能未开启")
        return 
    end
    if not self:IsSysOpen(oRoleApprentice, true) then 
        oRoleMaster:Tips("对方功能未开启")
        return 
    end

    local oMasterData = self:GetRoleMentorship(nMasterID)
    local oApprenticeData = self:GetRoleMentorship(nApprenticeID)
    assert(oMasterData and oApprenticeData)
    if oApprenticeData:IsInApprentInviteSilenceMap(oRole:GetID()) then 
        oRole:Tips("对方婉拒了你的请求")
        return 
    end

    local nApprenticeNum = oMasterData:GetApprenticeCount()
    if nApprenticeNum >= 100 then  --暂时加个保护限制，等外网存在100个徒弟，再询问策划，防止数据无限膨胀
        if nRoleID == nMasterID then 
            oRole:Tips("当前徒弟数量已达系统限制，无法继续收徒")
        else
            oRole:Tips("对方徒弟数量已达系统限制，无法继续收徒")
        end
        return
    end

    local fnConfirmCallback = function (tData)
        if not tData then 
            return oRole:Tips("申请已超时，请重新申请")
        end
        if tData.nSelIdx == 1 then  --拒绝
            oRole:Tips("对方婉拒了你的请求")
            if tData.nTypeParam and tData.nTypeParam > 0 then 
                oApprenticeData:InsertApprentInviteSilenceMap(oRole:GetID())
            end
			return
        elseif tData.nSelIdx == 2 then  --确定
            if self:IsMentorship(nMasterID, nApprenticeID) then --可能重复多次请求
                return
            end
            local nTimeStamp = os.time()
            oMasterData:AddApprentice(nApprenticeID, nTimeStamp)
            oApprenticeData:AddMaster(nMasterID, nTimeStamp)
            self:SyncRoleMentorshipData(nMasterID)
            self:SyncRoleMentorshipData(nApprenticeID)
            oRoleMaster:Tips(string.format("恭喜你收%s为徒", oRoleApprentice:GetName()))
            oRoleApprentice:Tips(string.format("恭喜你拜%s为师", oRoleMaster:GetName()))
            local sMailTitle = "拜师信息"
            local sMasterMailConf = ctTalkConf["mastertipsmail"].sContent
            local sMasterMailContent = string.format(sMasterMailConf, oRoleApprentice:GetName(), nApprenticeID)
            oRoleMaster:SendSysMail(sMailTitle, sMasterMailContent, {})
            local sApprentMailConf = ctTalkConf["apprenttipsmail"].sContent
            local sApprenticeMailContent = string.format(sApprentMailConf, oRoleMaster:GetName())
            oRoleApprentice:SendSysMail(sMailTitle, sApprenticeMailContent, {})

            self:SyncMentorshipTaskData(nMasterID)
            self:SyncMentorshipTaskData(nApprenticeID)
        end
    end

    local sCont = string.format("%s想收你为徒，是否同意？", oRole:GetName())
    local tMsg = {sCont=sCont, tOption={"拒绝", "确定"}, nTimeOut=30, nType=6, nTypeParam=nRoleID}
    goClientCall:CallWait("ConfirmRet", fnConfirmCallback, oRoleApprentice, tMsg)
    oRole:Tips(string.format("已请求收%s为徒，正在等待回复", oRoleApprentice:GetName()))
end

--解除和师父的关系
function CMentorshipMgr:DeleteMasterReq(oRole)
    assert(oRole, "参数错误")
    local nRoleID  = oRole:GetID()
    local oRoleMentorship = self:GetRoleMentorship(nRoleID)
    assert(oRoleMentorship)
    local oMaster = oRoleMentorship:GetMaster()  -- CMentorship
    if not oMaster then 
        return oRole:Tips("当前没有师父")
    end
--[[     if oMaster:IsUpgraded() then 
        return oRole:Tips("不能和亲传师父解除关系")
    end ]]
    local nMasterID = oMaster:GetID()
    local oRoleMaster = goGPlayerMgr:GetRoleByID(nMasterID)
    local oMasterMentorship = self:GetRoleMentorship(nMasterID)
    assert(oRoleMaster and oMasterMentorship) --todo 师父角色删除后，会找不到
    local fnConfirmCallback = function(tData)
        if not tData then 
            return
        end
        if tData.nSelIdx == 1 then  --再考虑下
            return 
        else
            local nTimeStamp = os.time()
            oRoleMentorship:RemoveMentorship(nMasterID, true, nTimeStamp)
            oMasterMentorship:RemoveMentorship(nRoleID, false, nTimeStamp)
            oRole:Tips(string.format("你已经解除了和%s的师徒关系", oRoleMaster:GetName()))
            self:SyncRoleMentorshipData(nRoleID)
            self:SyncRoleMentorshipData(nMasterID)
            self:SyncMentorshipTaskData(nRoleID)
            self:SyncMentorshipTaskData(nMasterID)
            -- TODO 删除双方称号
        end
    end
    local sCont = string.format("你真的要解除和%s的师徒关系吗？解除后24小时内无法再拜师", oRoleMaster:GetName())
    local tMsg = {sCont=sCont, tOption={"再考虑下", "残忍解除"}, nTimeOut=30}
    goClientCall:CallWait("ConfirmRet", fnConfirmCallback, oRole, tMsg)
end

--解除和徒弟的关系
function CMentorshipMgr:DeleteApprenticeReq(oRole, nTarID)
    if not oRole or not nTarID or nTarID <= 0 then 
        return
    end
    local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
    if not oTarRole then  --玩家删号可能也会导致找不到
        return oRole:Tips("目标玩家不存在")
    end
    local nRoleID  = oRole:GetID()
    local oRoleMentorship = self:GetRoleMentorship(nRoleID)
    assert(oRoleMentorship)
    local oApprentice = oRoleMentorship:GetApprentice(nTarID)  -- CMentorship
    if not oApprentice then 
        return oRole:Tips("和目标玩家不存在师徒关系")
    end
    local oTarMentorship = self:GetRoleMentorship(nTarID)
    assert(oTarMentorship)
    local fnConfirmCallback = function(tData)
        if not tData then 
            return
        end
        if tData.nSelIdx == 1 then  --再考虑下
            return 
        else
            local nTimeStamp = os.time()
            oRoleMentorship:RemoveMentorship(nTarID, true, nTimeStamp)
            oTarMentorship:RemoveMentorship(nRoleID, false, nTimeStamp)
            oRoleMentorship:MarkDirty(true)
            oTarMentorship:MarkDirty(true)
            oRole:Tips(string.format("你已经解除了和%s的师徒关系", oTarRole:GetName()))
            self:SyncRoleMentorshipData(nRoleID)
            self:SyncRoleMentorshipData(nTarID)
            self:SyncMentorshipTaskData(nRoleID)
            self:SyncMentorshipTaskData(nTarID)
            local sMailContent = string.format("你的师父%s已经和你解除了师徒关系", oRole:GetName())
            oTarRole:SendSysMail("拜师信息", sMailContent, {})
        end
    end
    local sCont = string.format("你真的要解除和%s的师徒关系吗？", oTarRole:GetName())
    local tMsg = {sCont=sCont, tOption={"再考虑下", "残忍解除"}, nTimeOut=30}
    goClientCall:CallWait("ConfirmRet", fnConfirmCallback, oRole, tMsg)

end

--出师条件检查请求
function CMentorshipMgr:UpgradeCheckReq(oRole)
    local nRoleID = oRole:GetID()
    local bCanUpgrade, tCheckList = self:UpgradeCheck(nRoleID)
    local tMsg = {}
    tMsg.bLevel = tCheckList.bLevel
    tMsg.bTime = tCheckList.bTime
    tMsg.bFriendDegree = tCheckList.bFriendDegree
    oRole:SendMsg("MentorshipUpgradeCheckRet", tMsg)
end

--出师请求
function CMentorshipMgr:UpgradeReq(oRole)
    local nRoleID = oRole:GetID()
    local bCanUpgrade, tCheckList = self:UpgradeCheck(nRoleID)
    if not bCanUpgrade then 
        return oRole:Tips("晋级条件不满足")
    end
    local oRoleMentorship = self:GetRoleMentorship(nRoleID)
    local oMaster = oRoleMentorship:GetMaster()
    assert(oMaster, "数据错误")
    local nMasterID = oMaster:GetID()
    local oMasterMentorship = self:GetRoleMentorship(nMasterID)
    assert(oMasterMentorship)
    oRoleMentorship:DoUpgrade(nMasterID)
    oMasterMentorship:DoUpgrade(nRoleID)
    oRole:Tips("恭喜你晋级成功")
    oRoleMentorship:MarkDirty(true)
    oMasterMentorship:MarkDirty(true)
    self:SyncMentorshipTaskData(nRoleID)  --出师后，任务发生变化，原来的师徒任务要通知客户端删除
    self:SyncMentorshipTaskData(nMasterID)
    -- self:SyncRoleMentorshipData(nRoleID)
    -- self:SyncRoleMentorshipData(nMasterID)
end

--主动刷新徒弟任务
function CMentorshipMgr:FlushApprenticeTaskReq(oRole, nTarID)
    assert(oRole and nTarID)
    local nRoleID = oRole:GetID()
    local oRoleData = self:GetRoleMentorship(nRoleID)
    assert(oRoleData)
    local oApprentice = oRoleData:GetApprentice(nTarID)
    assert(oApprentice)
    if oApprentice:IsUpgraded() then 
        return oRole:Tips("对方已出师，无法刷新任务")
    end
    if not oApprentice:CheckCanFlushTask() then 
        return oRole:Tips("徒弟已不可领取师徒任务，无法刷新")
    end
    if oApprentice.bTaskPublished then 
        return oRole:Tips("今日已发布了任务，无法刷新")
    end
    if oApprentice:GetRemainTaskFlushCount() <= 0 then 
        return oRole:Tips("今日刷新次数已用完")
    end
    oApprentice:FlushTask()
    oApprentice:AddTaskFlushCount(1)
    oRole:Tips("刷新成功")
    oRoleData:MarkDirty(true)
    self:UpdateMentorshipTaskData(nRoleID, nTarID)
end

--给徒弟发布任务
function CMentorshipMgr:PublishApprenticeTaskReq(oRole, nTarID)
    assert(oRole and nTarID, "参数不正确")
    local nRoleID = oRole:GetID()
    local oRoleData = self:GetRoleMentorship(nRoleID)
    local oRoleMentorship = oRoleData:GetMentorship(nTarID)
    if not oRoleMentorship or not oRoleMentorship:IsFreshApprentice() then
        return 
    end
    -- assert(#oRoleMentorship.m_tTaskList > 0, "数据错误") 
    if #oRoleMentorship.m_tTaskList <= 0 then 
        oRole:Tips("没有可发布的任务")
        return
    end
    if oRoleMentorship.m_bTaskPublished then 
        return oRole:Tips("今天已发布了师徒任务，不可重复发布")
    end
    local oTarData = self:GetRoleMentorship(nTarID)
    assert(oTarData)
    local oTarMentorship = oTarData:GetMentorship(nRoleID)
    assert(oTarMentorship)
    for k, v in pairs(oRoleMentorship.m_tTaskList) do 
        v.nState = gtMentorshipTaskState.eNotAccepted
    end
    oRoleMentorship.m_bTaskPublished = true
    oTarMentorship.m_tTaskList = table.DeepCopy(oRoleMentorship.m_tTaskList)
    oTarMentorship.m_bTaskPublished = true
    self:UpdateMentorshipTaskData(nRoleID, nTarID)
    oRole:Tips("发布任务成功")
    oRoleData:MarkDirty(true)
    oTarData:MarkDirty(true)
    --通知徒弟，师父给徒弟发布了任务
    self:SyncMentorshipTaskData(nTarID)
end

--徒弟接取任务
function CMentorshipMgr:AcceptTaskReq(oRole, nTaskID)
    assert(oRole and nTaskID > 0)
    local nRoleID = oRole:GetID()
    local oRoleData = self:GetRoleMentorship(nRoleID)
    assert(oRoleData)
    if oRoleData:IsUpgraded() then 
        return oRole:Tips("当前已出师")
    end
    local oMaster = oRoleData:GetMaster()
    local nMasterID = oMaster:GetID()
    assert(oMaster and not oMaster:IsUpgraded())
    for k, v in pairs(oMaster.m_tTaskList) do 
        if v.nState == gtMentorshipTaskState.eUnfinished then 
            return oRole:Tips("当前已接取了任务")
        end
    end
    local tTask = oMaster:GetTask(nTaskID)
    if not tTask then 
        return oRole:Tips("任务不存在")
    end
    if tTask.nState ~= gtMentorshipTaskState.eNotAccepted then 
        return oRole:Tips("任务不可接取")
    end
    tTask.nState = gtMentorshipTaskState.eUnfinished

    local oRoleMasterData = self:GetRoleMentorship(nMasterID)
    assert(oRoleMasterData)
    local oApprentice = oRoleMasterData:GetMentorship(nRoleID)
    assert(oApprentice)
    oApprentice:SetTaskState(tTask.nID, gtMentorshipTaskState.eUnfinished)
    oRoleData:MarkDirty(true)
    oRoleMasterData:MarkDirty(true)
    self:UpdateMentorshipTaskData(nRoleID, nMasterID)
    self:UpdateMentorshipTaskData(nMasterID, nRoleID)
    oRole:Tips("已领取师徒任务，快去完成吧")

    local tMsg = {}
    tMsg.nTaskID = nTaskID
    oRole:SendMsg("MentorshipTaskAcceptRet", tMsg)
end

function CMentorshipMgr:TaskBattleReq(oRole)
    assert(oRole)
    local nRoleID = oRole:GetID()
    local oRoleData = self:GetRoleMentorship(nRoleID)
    assert(oRoleData)
    if oRoleData:IsUpgraded() then 
        return oRole:Tips("已出师")
    end
    local oMaster = oRoleData:GetMaster()
    if not oMaster then 
        return 
    end
    ----------
    local tTask = nil
    for k, tTaskData in pairs(oMaster.m_tTaskList) do 
        if tTaskData.nState == gtMentorshipTaskState.eUnfinished and tTaskData.nID > 0 then 
            tTask = tTaskData
            break
        end
    end
    if not tTask then 
        return oRole:Tips("任务不存在")
    end
    local nTaskID = tTask.nID
    if tTask.nState ~= gtMentorshipTaskState.eUnfinished then 
        if tTask.nState == gtMentorshipTaskState.eNotAccepted then 
            oRole:Tips("请先领取任务")
        elseif tTask.nState == gtMentorshipTaskState.eUnfinished then 
            oRole:Tips("任务已完成")
        else
            oRole:Tips("任务状态不正确")
        end
        return
    end
    Network.oRemoteCall:Call("MentorshipTaskBattleReq", oRole:GetStayServer(), oRole:GetLogic(), 
        oRole:GetSession(), nRoleID, {nTaskID = nTaskID, nTimeStamp = os.time(), nSrcService = CUtil:GetServiceID()})
end

function CMentorshipMgr:OnTaskBattleEnd(oRole, nTaskID, bWin, nTimeStamp)
    if not os.IsSameDay(os.time(), nTimeStamp) then --战斗跨天了，任务已刷新
        return 
    end
    if not bWin then 
        return 
    end
    local nRoleID = oRole:GetID()
    local oRoleData = self:GetRoleMentorship(nRoleID)
    assert(oRoleData)
    if oRoleData:IsUpgraded() then 
        return
    end
    local oMaster = oRoleData:GetMaster()
    if not oMaster then --被解除师徒关系???
        return 
    end
    local tTask = oMaster:GetTask(nTaskID)
    if not tTask then 
        return oRole:Tips("任务不存在")
    end
    if tTask.nState ~= gtMentorshipTaskState.eUnfinished then 
        assert(false, "未知错误")
    end
    tTask.nState = gtMentorshipTaskState.eFinished
    local nMasterID = oMaster:GetID()
    local oMasterData = self:GetRoleMentorship(nMasterID)
    assert(oMasterData)
    local oApprentice = oMasterData:GetMentorship(nRoleID)
    assert(oApprentice)
    oApprentice:SetTaskState(nTaskID, gtMentorshipTaskState.eFinished)
    oRoleData:MarkDirty(true)
    oMasterData:MarkDirty(true)
    -- self:UpdateMentorshipTaskData(nRoleID, oMaster:GetID())
    self:UpdateMentorshipTaskData(oMaster:GetID(), nRoleID)
    self:ReceiveTaskRewardReq(oRole, nTaskID)  --徒弟自动领取奖励
end

--徒弟领取任务奖励
function CMentorshipMgr:ReceiveTaskRewardReq(oRole, nTaskID)
    assert(oRole and nTaskID > 0)
    local tTaskConf = ctMentorshipTaskConf[nTaskID]
    if not tTaskConf then 
        return 
    end
    local nRoleID = oRole:GetID()
    local oRoleData = self:GetRoleMentorship(nRoleID)
    assert(oRoleData)
    if oRoleData:IsUpgraded() then 
        return oRole:Tips("已出师")
    end
    local oMaster = oRoleData:GetMaster()
    if not oMaster then 
        return 
    end
    local tTask = oMaster:GetTask(nTaskID)
    if not tTask then 
        return oRole:Tips("任务不存在")
    end
    if tTask.nState ~= gtMentorshipTaskState.eFinished then 
        if tTask.nState == gtMentorshipTaskState.eReceiveReward then 
            return oRole:Tips("奖励已领取")
        end
        return oRole:Tips("非法操作")
    end
    tTask.nState = gtMentorshipTaskState.eReceiveReward

    local tReward = {}
    for k, v in pairs(tTaskConf.tReward) do 
        if v[1] > 0 and v[2] > 0 then 
            table.insert(tReward, {nType = gtItemType.eProp, nID = v[1], nNum = v[2]})
        end
    end
    local nExpVal = tTaskConf.fnExp(oRole:GetLevel())
    if nExpVal > 0 then 
        table.insert(tReward, {nType = gtItemType.eCurr, nID = gtCurrType.eExp, nNum = nExpVal})
    end
    if #tReward > 0 then 
        oRole:AddItem(tReward, "师徒活跃度奖励")
    end
    oRoleData:MarkDirty(true)
    self:UpdateMentorshipTaskData(nRoleID, oMaster:GetID())
end

--师父领取任务奖励
function CMentorshipMgr:ReceiveTaskMasterRewardReq(oRole, nApprenticeID, nTaskID)
    assert(oRole and nTaskID > 0)
    local tTaskConf = ctMentorshipTaskConf[nTaskID]
    if not tTaskConf then 
        return 
    end
    local nRoleID = oRole:GetID()
    local oRoleData = self:GetRoleMentorship(nRoleID)
    assert(oRoleData)
    local oApprentice = oRoleData:GetMentorship(nApprenticeID)
    if not oApprentice then 
        return 
    end
    if oApprentice:IsUpgraded() then 
        return oRole:Tips("徒弟已出师")
    end
    local tTask = oApprentice:GetTask(nTaskID)
    if not tTask then 
        return oRole:Tips("任务不存在")
    end
    if tTask.nState ~= gtMentorshipTaskState.eFinished then 
        if tTask.nState == gtMentorshipTaskState.eReceiveReward then 
            return oRole:Tips("奖励已领取")
        end
        return oRole:Tips("非法操作")
    end
    tTask.nState = gtMentorshipTaskState.eReceiveReward

    local tReward = {}
    for k, v in pairs(tTaskConf.tMasterReward) do 
        if v[1] > 0 and v[2] > 0 then 
            table.insert(tReward, {nType = gtItemType.eProp, nID = v[1], nNum = v[2]})
        end
    end
    if #tReward > 0 then 
        oRole:AddItem(tReward, "师徒活跃度奖励")
    end
    oRoleData:MarkDirty(true)
    self:UpdateMentorshipTaskData(nRoleID, oApprentice:GetID())
end

--徒弟领取活跃度奖励
function CMentorshipMgr:GetApprenticeActiveReward(oRole, nConfID)
    assert(oRole and nConfID > 0)
    local nRoleID = oRole:GetID()
    local tConf = ctMentorActiveRewardConf[nConfID]
    if not tConf then 
        return oRole:Tips("参数错误")
    end
    local oRoleData = self:GetRoleMentorship(nRoleID)
    assert(oRoleData)
    local oMaster = oRoleData:GetMaster()
    if not oMaster then 
        return 
    end
    if oMaster.m_tActiveRewardRecord[nConfID] then
        return oRole:Tips("奖励已领取")
    end
    if oMaster.m_nActiveNum < tConf.nNum then 
        return oRole:Tips("未达到领取条件")
    end
    oMaster.m_tActiveRewardRecord[nConfID] = nConfID
    local tReward = {}
    for k, v in pairs(tConf.tApprenticeReward) do 
        if v[1] > 0 and v[2] > 0 then 
            table.insert(tReward, {nType = gtItemType.eProp, nID = v[1], nNum = v[2]})
        end
    end
    if #tReward > 0 then 
        oRole:AddItem(tReward, "师徒活跃度奖励")
    end
    oRoleData:MarkDirty(true)
    self:UpdateMentorshipTaskData(nRoleID, oMaster:GetID())
end

--师父领取活跃度奖励
function CMentorshipMgr:GetMasterActiveReward(oRole, nTarID, nConfID)
    assert(oRole and nConfID > 0)
    local nRoleID = oRole:GetID()
    local tConf = ctMentorActiveRewardConf[nConfID]
    if not tConf then 
        return oRole:Tips("参数错误")
    end

    local oRoleData = self:GetRoleMentorship(nRoleID)
    assert(oRoleData)
    local oApprentice = oRoleData:GetMentorship(nTarID)
    if not oApprentice then 
        return oRole:Tips("对方不是徒弟，无法领取")
    end
    if not oRoleData:IsFreshApprentice(nTarID) then 
        return oRole:Tips("不是未出师徒弟，无法领取")
    end
    if oApprentice.m_tActiveRewardRecord[nConfID] then
        return oRole:Tips("奖励已领取")
    end
    if oApprentice.m_nActiveNum < tConf.nNum then 
        return oRole:Tips("未达到领取条件")
    end
    
    oApprentice.m_tActiveRewardRecord[nConfID] = nConfID
    local tReward = {}
    for k, v in pairs(tConf.tMasterReward) do 
        if v[1] > 0 and v[2] > 0 then 
            table.insert(tReward, {nType = gtItemType.eProp, nID = v[1], nNum = v[2]})
        end
    end
    if #tReward > 0 then 
        oRole:AddItem(tReward, "师徒活跃度奖励")
    end
    oRoleData:MarkDirty(true)
    self:UpdateMentorshipTaskData(nRoleID, nTarID)
end

function CMentorshipMgr:GreetMasterReq(oRole, bOffline)
    assert(oRole and bOffline)
    local nRoleID = oRole:GetID()
    local oRoleMent = self:GetRoleMentorship(nRoleID)
    assert(oRoleMent)
    local oMaster = oRoleMent:GetMaster()
    if not oMaster then 
        return oRole:Tips("当前没有拜师哦，快去找一个师父吧")
    end
    local nLastGreetTime = oMaster:GetLastGreetTime()
    local nCurTime = os.time()
    if os.IsSameDay(nLastGreetTime, nCurTime, 0) then 
        return oRole:Tips("今天已经给师父请安了哦")
    end

    local nMasterID = oMaster:GetID()
    local oRoleMaster = goGPlayerMgr:GetRoleByID(nMasterID)
    if not oRoleMaster then 
        return oRole:Tips("师父不存在")  --可能删号
    end
    if not oRoleMaster:IsOnline() and not bOffline then 
        local tMsg = {}
        tMsg.bOffline = true
        oRole:SendMsg("MentorshipGreetMasterRet", tMsg)
        return 
    end

    local sTalkTemplate = ctTalkConf["greetmaster"].sContent
    local sTalkCont = string.format(sTalkTemplate, oRole:GetName(), nRoleID)
    local oRoleFriend = goFriendMgr:GetFriend(nRoleID, nMasterID)
    local oMasterFriend = goFriendMgr:GetFriend(nMasterID, nRoleID)
    local tTalkMsg = CFriendMgr:MakeTalkMsg(nRoleID, sTalkCont)
    oRole:SendMsg("FriendTalkRet", {tTalk=tTalkMsg})
    if oRoleMaster:IsOnline() then 
	    oRoleMaster:SendMsg("FriendTalkRet", {tTalk=tTalkMsg})
    end
    oRoleFriend:AddTalk(tTalkMsg)
    oMasterFriend:AddTalk(tTalkMsg)
    
    oMaster:SetLastGreetTime(nCurTime) --只在徒弟玩家的师父数据上保存一下此数据
    oRoleMent:MarkDirty(true)
end

function CMentorshipMgr:TeachApprenticeReq(oRole, nApprenticeID)
    assert(oRole and nApprenticeID)
    local nRoleID = oRole:GetID()
    if nRoleID == nApprenticeID then  --可能徒弟点击自己的聊天消息，前端没做屏蔽
        return 
    end
    local oRoleMent = self:GetRoleMentorship(nRoleID)
    assert(oRoleMent)
    local oApprentice = oRoleMent:GetApprentice(nApprenticeID)
    if not oApprentice then 
        return oRole:Tips("徒弟不存在")
    end
    -- if oApprentice:IsUpgraded() then 
    --     return oRole:Tips("徒弟已出师")
    -- end
    local oRoleApprentice = goGPlayerMgr:GetRoleByID(oApprentice:GetID())
    if not oRoleApprentice then 
        return oRole:Tips("徒弟不存在")  --可能删号
    end

    --判断徒弟今天是否有给师父请安
    local oApprMent = self:GetRoleMentorship(nApprenticeID)
    assert(oApprMent)
    local oMaster = oApprMent:GetMaster()
    assert(oMaster:GetID() == nRoleID, "数据错误")
    local nLastGreetTime = oMaster:GetLastGreetTime()
    local nCurTime = os.time()
    if not os.IsSameDay(nLastGreetTime, nCurTime, 0) then 
        --今天徒弟没有给师父请安
        return --不响应
    end
    local nLastTeachTime = oApprentice:GetLastTeachTime()
    if os.IsSameDay(nLastTeachTime, nCurTime, 0) then 
        return oRole:Tips("今天已经指点过了哦")
    end

    if not oRoleApprentice:IsOnline() then 
        return oRole:Tips("徒弟不在线")
    end

    local sTalkCont = "师父指点"   --TODO
    local oRoleFriend = goFriendMgr:GetFriend(nRoleID, nApprenticeID)
    local oApprenticeFriend = goFriendMgr:GetFriend(nApprenticeID, nRoleID)
    local tTalkMsg = CFriendMgr:MakeTalkMsg(nRoleID, sTalkCont)
    oRole:SendMsg("FriendTalkRet", {tTalk=tTalkMsg})
    if oRoleApprentice:IsOnline() then 
	    oRoleApprentice:SendMsg("FriendTalkRet", {tTalk=tTalkMsg})
    end
    oRoleFriend:AddTalk(tTalkMsg)
    oApprenticeFriend:AddTalk(tTalkMsg)

    oApprentice:SetLastTeachTime(nCurTime)  --只在师父玩家的徒弟数据中保存下此数据
    oRoleMent:MarkDirty(true)

    oRoleFriend:AddDegrees(6, "师父指点")
    oApprenticeFriend:AddDegrees(6, "师父指点")

    local nLevel = oRoleApprentice:GetLevel()
    local nExpVal = 5000+150*150*3+nLevel*nLevel*5
    oRoleApprentice:AddItem({{nType = gtItemType.eCurr, nID = gtCurrType.eExp,
        nNum = nExpVal,}}, "师父指点")
end

--提醒发布师徒任务
function CMentorshipMgr:PublishTaskRemindReq(oRole)
    local oRoleMent = self:GetRoleMentorship(oRole:GetID())
    assert(oRoleMent)
    local oMaster = oRoleMent:GetMaster()
    if not oMaster then 
        return oRole:Tips("当前没有拜师哦，快去找一个师父吧")
    end
    if oMaster.m_bPublishTaskRemind then 
        return oRole:Tips("今天已经提醒过师父啦~")
    end
    local oRoleMaster = goGPlayerMgr:GetRoleByID(oMaster:GetID())
    if not oRoleMaster then 
        return oRole:Tips("大事不好啦，师父被妖怪抓走了！")
    end

    local sContent = ctTalkConf["mentortaskpublishremind"].sContent or ""
    goFriendMgr:TalkReq(oRole, oRoleMaster:GetID(), sContent, true)
    oMaster.m_bPublishTaskRemind = true 
    oRoleMent:MarkDirty(true)
end

--拜师信息
function CMentorshipMgr:MasterInviteTalkReq(oRole)
    if not oRole then return end
    if not self:IsSysOpen(oRole, true) then 
		return 
	end
    local oRoleMent = self:GetRoleMentorship(oRole:GetID())
    assert(oRoleMent)
    local nCurTime = os.time()
    local nPasTime = nCurTime - (oRoleMent.m_nLastInviteTalkStamp or 0)
    if nPasTime < 60 then 
        oRole:Tips(string.format("操作频繁，请%s秒后再试", 60 - nPasTime))
        return
    end
    local fnQueryCallback = function(sPreStr)
        if not sPreStr then 
			return 
		end
        local tTalkConf = ctTalkConf["masterinvite"]
        assert(tTalkConf)
        local sContentTemplate = tTalkConf.tContentList[math.random(#tTalkConf.tContentList)][1]
        local nTeamID = goTeamMgr:GetRoleTeamID(oRole:GetID())
        local sContent = string.format(sContentTemplate, oRole:GetID())

        oRoleMent.m_nLastInviteTalkStamp = nCurTime
        local sMsgContent = sPreStr..sContent
        CUtil:SendWorldTalk(oRole:GetID(), sMsgContent, true)
        oRole:Tips("消息发布成功")
    end
    oRole:QueryRelationshipInvitePreStr(fnQueryCallback)
end

--收徒信息
function CMentorshipMgr:ApprenticeInviteTalkReq(oRole)
    if not oRole then return end
    local oRoleMent = self:GetRoleMentorship(oRole:GetID())
    assert(oRoleMent)
    local nCurTime = os.time()
    local nPasTime = nCurTime - (oRoleMent.m_nLastInviteTalkStamp or 0)
    if nPasTime < 60 then 
        oRole:Tips(string.format("操作频繁，请%s秒后再试", 60 - nPasTime))
        return
    end
    local fnQueryCallback = function(sPreStr)
        local tTalkConf = ctTalkConf["apprenticeinvite"]
        assert(tTalkConf)
        local sContentTemplate = tTalkConf.tContentList[math.random(#tTalkConf.tContentList)][1]
        local nTeamID = goTeamMgr:GetRoleTeamID(oRole:GetID())
        local sContent = string.format(sContentTemplate, oRole:GetID())
        oRoleMent.m_nLastInviteTalkStamp = nCurTime
        local sMsgContent = sPreStr..sContent
        CUtil:SendWorldTalk(oRole:GetID(), sMsgContent, true)
        oRole:Tips("消息发布成功")
    end
    oRole:QueryRelationshipInvitePreStr(fnQueryCallback)
end

function CMentorshipMgr:SyncLogicCache(nRoleID, nSrcServer, nSrcService, nTarSession) 
    assert(nRoleID and nRoleID >  0)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then 
        return 
    end
    nSrcServer = nSrcServer or oRole:GetStayServer()
    nSrcService = nSrcService or oRole:GetLogic()
    nTarSession = nTarSession or oRole:GetSession()

    local oRoleMentorship = self:GetRoleMentorship(nRoleID)
    if not oRoleMentorship then
        return
    end
    local tData = {}
    tData.bUpgraded = oRoleMentorship:IsUpgraded()
    tData.tMentorshipList = {}
    for nTempRoleID, tMentorship in pairs(oRoleMentorship.m_tRelationMap) do
        local tMentorData = {}
        tMentorData.nStatus = tMentorship.m_nStatus
        tMentorData.bUpgrade = tMentorship:IsUpgraded()
        local oTempRole = goGPlayerMgr:GetRoleByID(nTempRoleID)
        if oTempRole then 
            tMentorData.sName = oTempRole:GetName()
        end
        tData.tMentorshipList[nTempRoleID] = tMentorData
    end
    Network.oRemoteCall:Call("RoleMentorshipUpdateReq", nSrcServer, nSrcService, nTarSession, nRoleID, tData)
end

function CMentorshipMgr:OnNameChange(oRole)
    local nRoleID = oRole:GetID()
    local oRoleMentorship = self:GetRoleMentorship(nRoleID)
    if not oRoleMentorship then
        return
    end
    for nTempRoleID, tMentorship in pairs(oRoleMentorship.m_tRelationMap) do
        if tMentorship:IsApprentice() then 
            local oTempRole = goGPlayerMgr:GetRoleByID(nTempRoleID)
            if oTempRole then 
                local nAppeID = gtAppellationIDDef.eApprentice
                oTempRole:UpdateAppellation(nAppeID, {tNameParam={oRole:GetName()}}, oRole:GetID())
                local nAppeID = gtAppellationIDDef.eUpgradedApprentice
                oTempRole:UpdateAppellation(nAppeID, {tNameParam={oRole:GetName()}}, oRole:GetID())
            end
        end
    end
end

function CMentorshipMgr:GetRoleInfoMentorshipInfo(nRoleID) 
    local tMentorshipInfo = nil
    local oRoleMentorship = self:GetRoleMentorship(nRoleID)
    if oRoleMentorship then 
        tMentorshipInfo = {}

        local oMaster = oRoleMentorship:GetMaster()
        if oMaster then 
            local nMasterID = oMaster:GetID()
            local oRoleMaster = goGPlayerMgr:GetRoleByID(nMasterID)
            if oRoleMaster then --可能删号
                local tMasterInfo = {}
                tMasterInfo.nID = oRoleMaster:GetID()
                tMasterInfo.sName = oRoleMaster:GetName()
                tMasterInfo.sModel = oRoleMaster:GetModel()
                tMasterInfo.sHeader = oRoleMaster:GetHeader()
                tMasterInfo.nLevel = oRoleMaster:GetLevel()
                tMasterInfo.nGender = oRoleMaster:GetGender()
                tMasterInfo.nSchool = oRoleMaster:GetSchool()

                tMentorshipInfo.tMaster = tMasterInfo
            end
        end

        local tApprentList = {}
        for k, v in pairs(oRoleMentorship.m_tRelationMap) do 
            if v:IsApprentice() and not v:IsUpgraded() then 
                local oRoleApprent = goGPlayerMgr:GetRoleByID(v:GetID())
                if oRoleApprent then 
                    local tApprentInfo = {}
                    tApprentInfo.nID = oRoleApprent:GetID()
                    tApprentInfo.sName = oRoleApprent:GetName()
                    tApprentInfo.sModel = oRoleApprent:GetModel()
                    tApprentInfo.sHeader = oRoleApprent:GetHeader()
                    tApprentInfo.nLevel = oRoleApprent:GetLevel()
                    tApprentInfo.nGender = oRoleApprent:GetGender()
                    tApprentInfo.nSchool = oRoleApprent:GetSchool()
                    tApprentInfo.bUpgraded = false
                    table.insert(tApprentList, tApprentInfo)
                end
            end
        end
        for k, v in pairs(oRoleMentorship.m_tRelationMap) do 
            if v:IsApprentice() and v:IsUpgraded() then 
                local oRoleApprent = goGPlayerMgr:GetRoleByID(v:GetID())
                if oRoleApprent then 
                    local tApprentInfo = {}
                    tApprentInfo.nID = oRoleApprent:GetID()
                    tApprentInfo.sName = oRoleApprent:GetName()
                    tApprentInfo.sHeader = oRoleApprent:GetHeader()
                    tApprentInfo.nLevel = oRoleApprent:GetLevel()
                    tApprentInfo.nGender = oRoleApprent:GetGender()
                    tApprentInfo.nSchool = oRoleApprent:GetSchool()
                    tApprentInfo.bUpgraded = true
                    table.insert(tApprentList, tApprentInfo)
                end
            end
        end
        tMentorshipInfo.tApprentList = tApprentList
    end

    return tMentorshipInfo
end
