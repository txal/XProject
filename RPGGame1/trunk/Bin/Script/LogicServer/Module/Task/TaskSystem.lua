--任务系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

CTaskSystem.tTaskType = 
{
    ePrinTask = 1,                  --主线任务类型
    eBranchTask = 2,                --支线任务类型
    eGuideTask = 3,                 --引导任务类型
}

CTaskSystem.tTaskTargetType = 
{
    eBattleTask = 1,                --战斗任务
    eTalkWithNpc = 2,               --寻找npc
    eCommintItem = 3,               --提交物品
    eGatherTask = 4,                --采集物品
}

CTaskSystem.tTaskGatherStatus = 
{
    eStartGather = 1,               --开始采集
    eStopGather = 2,                --停止采集
    eFinishGather =3,               --采集完成
}

CTaskSystem.tParamType = 
{
    eNpcID = 1,
    eTaskStatus = 2,
    eProgressNum = 3,
    eIsRewarded = 4,    
}

function CTaskSystem:Ctor(oRole)
    self.m_oRole = oRole
    self.m_nCurrBattleTaskID = 0    --正在战斗的战斗任务id
    self.m_nCurrPrinTaskID = 0      --当前主线任务id
    self.m_nCurrBranchTaskID = 0    --当前支线任务id
    self.m_tGuideTaskID = {}        --激活的引导任务id

    self.m_tCurrPrinTaskParam = {}      --主线任务记录
    self.m_tCurrBranchTaskParam = {}    --支线任务记录
    self.m_tGuideTaskParam = {}         --引导任务记录

    self.m_nGatherTimestamp = 0     --开始采集时间戳
end

function CTaskSystem:LoadData(tData)
    if tData then
        --检查配置(由测试第一时间发现，减少错误, 当任务配置出错时，不能兼容错误数据，比如从新设置开始任务造成领取重复奖励，设置完成所有任务造成目标任务不能完成)
        if tData.m_nCurrPrinTaskID and tData.m_nCurrPrinTaskID > 0 then
            if not ctTaskSystemConf[tData.m_nCurrPrinTaskID] then
                local sTips = "主线任务:"..tData.m_nCurrPrinTaskID.." 配置不存在,清除旧任务数据"
                self.m_oRole:Tips(sTips)
                LuaTrace(self.m_oRole:GetID(), sTips)
                self:OnLoaded()
                return
            end
            -- assert(ctTaskSystemConf[tData.m_nCurrPrinTaskID], "配置错误, 没有主线任务："..tData.m_nCurrPrinTaskID)
        end

        if tData.m_nCurrBranchTaskID and tData.m_nCurrBranchTaskID > 0 then
            if not ctTaskSystemConf[tData.m_nCurrBranchTaskID] then
                local sTips = "支线任务:"..tData.m_nCurrBranchTaskID.." 配置不存在,清除旧数据"
                self.m_oRole:Tips(sTips)
                LuaTrace(self.m_oRole:GetID(), sTips)
                self:OnLoaded()
                return
            end
            -- assert(ctTaskSystemConf[tData.m_nCurrBranchTaskID], "配置错误, 没有支线任务："..tData.m_nCurrBranchTaskID)
        end

        self.m_nCurrPrinTaskID = tData.m_nCurrPrinTaskID or self.m_nCurrPrinTaskID
        self.m_nCurrBranchTaskID = tData.m_nCurrBranchTaskID or self.m_nCurrBranchTaskID
        self.m_tGuideTaskID = tData.m_tGuideTaskID or self.m_tGuideTaskID
    
        self.m_tCurrPrinTaskParam = tData.m_tCurrPrinTaskParam or self.m_tCurrPrinTaskParam
        self.m_tCurrBranchTaskParam = tData.m_tCurrBranchTaskParam or self.m_tCurrBranchTaskParam
        self.m_tGuideTaskParam = tData.m_tGuideTaskParam or self.m_tGuideTaskParam
    end

    self:OnLoaded()
end

function CTaskSystem:SaveData()
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)

    local tData = {}
    tData.m_nCurrPrinTaskID = self.m_nCurrPrinTaskID 
    tData.m_nCurrBranchTaskID = self.m_nCurrBranchTaskID
    tData.m_tGuideTaskID = self.m_tGuideTaskID 

    tData.m_tCurrPrinTaskParam = self.m_tCurrPrinTaskParam 
    tData.m_tCurrBranchTaskParam = self.m_tCurrBranchTaskParam 
    tData.m_tGuideTaskParam = self.m_tGuideTaskParam 
    return tData
end


function CTaskSystem:OnLoaded()
    local function _InitMainTask()
        self.m_nCurrPrinTaskID = _ctTaskSystemConf[CTaskSystem.tTaskType.ePrinTask][1].nTaskId
        self.m_tCurrPrinTaskParam.nNpcID = 0
        self.m_tCurrPrinTaskParam.nTaskStatus = 0
        self.m_tCurrPrinTaskParam.nProgressNum = 0
        self.m_tCurrPrinTaskParam.bIsRewarded = false
    end

    --初始化主线任务
    if self.m_nCurrPrinTaskID == 0 then
        _InitMainTask()
        self:MarkDirty(true)
    end
end

function CTaskSystem:GetType()
	return gtModuleDef.tTaskSystem.nID, gtModuleDef.tTaskSystem.sName
end

function CTaskSystem:Online()
    --追加任务时
    local nNextPrinTaskID = ctTaskSystemConf[self.m_nCurrPrinTaskID] and ctTaskSystemConf[self.m_nCurrPrinTaskID].nNextTask or 0
    if self.m_nCurrPrinTaskID > 0 and self.m_tCurrPrinTaskParam.bIsRewarded and nNextPrinTaskID > 0 then
        self:SetCurrTaskID(CTaskSystem.tTaskType.ePrinTask, self.m_nCurrPrinTaskID)
    end

    local nNextBranchTaskID = ctTaskSystemConf[self.m_nCurrBranchTaskID] and ctTaskSystemConf[self.m_nCurrBranchTaskID].nNextTask or 0
    if self.m_nCurrBranchTaskID > 0 and self.m_tCurrBranchTaskParam.bIsRewarded and nNextBranchTaskID > 0 then
        self:SetCurrTaskID(CTaskSystem.tTaskType.eBranchTask, self.m_nCurrBranchTaskID)
    end
    self:SendAllTaskInfo()
end

function CTaskSystem:TaskOpera(nTaskID, nTaskType, nTaskTargetType, nNpcID, nTaskStatus)
    local tTaskConf = ctTaskSystemConf[nTaskID]
    if not tTaskConf or tTaskConf.nTaskType ~= nTaskType then
        return self.m_oRole:Tips("任务不存在或类型错误:"..nTaskID..","..nTaskType)
    end
    if tTaskConf.nTargetType ~= nTaskTargetType then
        return self.m_oRole:Tips("任务目标类型错误:"..nTaskID..","..tTaskConf.nTargetType)
    end

    --判断当前任务中是否包含请求的任务
	if self.tTaskType.ePrinTask == nTaskType then
		if self.m_nCurrPrinTaskID ~= nTaskID then
			return
        end
        
	elseif self.tTaskType.eBranchTask == nTaskType then
		if self.m_nCurrBranchTaskID ~= nTaskID then
			return
        end
        
	elseif self.tTaskType.eGuideTask == nTaskType then
		if self.m_tGuideTaskID[nTaskID] == false then
			return
		end
    end

    --判断等级限制检查
    if self.m_oRole:GetLevel() < ctTaskSystemConf[nTaskID].nLevelLimit then
        return self.m_oRole:Tips("角色等级不足"..ctTaskSystemConf[nTaskID].nLevelLimit.."级，不能完成该任务")
    end

    --执行任务操作
    if CTaskSystem.tTaskTargetType.eBattleTask == nTaskTargetType then
        self:BattleTask(nTaskID, nTaskType, nNpcID)

    elseif CTaskSystem.tTaskTargetType.eTalkWithNpc == nTaskTargetType then
        self:TalkWithNpc(nTaskID, nTaskType, nNpcID)

    elseif CTaskSystem.tTaskTargetType.eCommintItem == nTaskTargetType then
        self:CommitItemToNpc(nTaskID, nTaskType, nNpcID)

    elseif CTaskSystem.tTaskTargetType.eGatherTask == nTaskTargetType then
        self:OnGather(nTaskID, nTaskType, nNpcID, nTaskStatus)
    end
end

--战斗任务
function CTaskSystem:BattleTask(nTaskID, nTaskType, nNpcID)
    self:SetTaskParam(nTaskID, nTaskType, CTaskSystem.tParamType.eNpcID, nNpcID)
    self.m_nCurrBattleTaskID = nTaskID      --设置即将进入的战斗属于哪个任务，结束战斗时以此判断任务
    self:MarkDirty(true)
    
    local oMonster = goMonsterMgr:CreateTaskMonster(CMonsterTaskNpc.tOnBattleEndType.eTaskSystem, self.m_nCurrBattleTaskID)
    if not oMonster then
        return
    end

    local tExtData = {}
    tExtData.tBattleFromModule = CMonsterTaskNpc.tOnBattleEndType.eTaskSystem
    if self.tTaskType.ePrinTask == nTaskType then
        tExtData.nBattleDupType = gtBattleType.ePrinTask
    elseif self.tTaskType.eBranchTask == nTaskType then
        tExtData.nBattleDupType = gtBattleType.eBranchTask
    end
    self.m_oRole:PVE(oMonster, tExtData)
end

function CTaskSystem:OnBattleEnd(bIsRoleWin)
    --判断当前任务是不是战斗任务
    if self.m_nCurrBattleTaskID == 0 or self.m_nCurrBattleTaskID == nil then return end

    if CTaskSystem.tTaskTargetType.eBattleTask ~= ctTaskSystemConf[self.m_nCurrBattleTaskID].nTargetType then
        return
    end

    local nTaskType = ctTaskSystemConf[self.m_nCurrBattleTaskID].nTaskType

    self:SetTaskParam(self.m_nCurrBattleTaskID, nTaskType, CTaskSystem.tParamType.eTaskStatus, bIsRoleWin)
    self:CalAcceptTask(self.m_nCurrBattleTaskID, nTaskType, self:fnHandlerCallBack(self.CheckBattleTask, self))
    self.m_nCurrBattleTaskID = 0
    self:MarkDirty(true)
end

--提交物品任务
function CTaskSystem:CommitItemToNpc(nTaskID, nTaskType, nNpcID)
    self:SetTaskParam(nTaskID, nTaskType, CTaskSystem.tParamType.eNpcID, nNpcID)

    local nTaskItemID = ctTaskSystemConf[nTaskID].nParam2
    local nTaskItemNum = ctTaskSystemConf[nTaskID].nParam3

    if nTaskItemID == 0 or nTaskItemNum == 0 then
        return
    end

    local bSucc = self.m_oRole:CheckSubItem(gtItemType.eProp, nTaskItemID, nTaskItemNum, "任务扣除")
    if not bSucc then
        self.m_oRole:Tips(string.format("%s不足", CKnapsack:PropName(nTaskItemID)))
        return
    end

    if bSucc then
        self:SetTaskParam(nTaskID, nTaskType, CTaskSystem.tParamType.eProgressNum, nTaskItemNum)
        self:CalAcceptTask(nTaskID, nTaskType, self:fnHandlerCallBack(self.CheckCommitItemTask, self))
    end
    
end

--采集任务
function CTaskSystem:OnGather(nTaskID, nTaskType, nNpcID, nTaskStatus)
    --开始时，判断现在的坐标是不是在任务坐标上，如果是在正确坐标开始采集
    if CTaskSystem.tTaskGatherStatus.eStartGather == nTaskStatus then
        self.m_nGatherTimestamp = os.time()
        self:MarkDirty(true)

    elseif CTaskSystem.tTaskGatherStatus.eStopGather == nTaskStatus then --这里可要可不要
        self.m_nGatherTimestamp = 0
        self:MarkDirty(true)

    elseif CTaskSystem.tTaskGatherStatus.eFinishGather == nTaskStatus then
        local nGatherTime = ctTaskSystemConf[nTaskID].nParam2 --一个物品耗时
        if os.time() < self.m_nGatherTimestamp+nGatherTime or os.time() >= self.m_nGatherTimestamp+nGatherTime*3 then
            return self.m_oRole:Tips("采集耗时非法，请重新采集")
        end
        self.m_nGatherTimestamp = 0
        self:SetTaskParam(nTaskID, nTaskType, CTaskSystem.tParamType.eProgressNum, 1)
        self:CalAcceptTask(nTaskID, nTaskType, self:fnHandlerCallBack(self.CheckGatherTask, self))
        self:MarkDirty(true)

    else
        return self.m_oRole:Tips("采集状态错误:"..nTaskStatus)

    end
end

--对话任务
function CTaskSystem:TalkWithNpc(nTaskID, nTaskType, nNpcID)
    self:SetTaskParam(nTaskID, nTaskType, CTaskSystem.tParamType.eNpcID, nNpcID)
    self:CalAcceptTask(nTaskID, nTaskType, self:fnHandlerCallBack(self.CheckTalkWithNpcTask, self))
end

--计算是否能接新任务
function CTaskSystem:CalAcceptTask(nTaskID, nTaskType, fnCallBack)
    if nil == fnCallBack then return end

    local bFinishTask = false
    local nProgressNum = 0
    if CTaskSystem.tTaskType.ePrinTask == nTaskType then
        nProgressNum = self.m_tCurrPrinTaskParam.nProgressNum
        bFinishTask = fnCallBack(self.m_tCurrPrinTaskParam, nTaskID)

    elseif CTaskSystem.tTaskType.eBranchTask == nTaskType then
        nProgressNum = self.m_tCurrBranchTaskParam.nProgressNum
        bFinishTask = fnCallBack(self.m_tCurrBranchTaskParam, nTaskID)

    elseif CTaskSystem.tTaskType.eGuideTask == nTaskType then
        nProgressNum = self.m_tGuideTaskParam[nTaskID].nProgressNum
        bFinishTask = fnCallBack(self.m_tGuideTaskParam[nTaskID], nTaskID)
    end

    --发奖励 更新任务
    if bFinishTask then
        self:TaskReward(nTaskID)
        self:SetCurrTaskID(nTaskType, nTaskID)
    end

    self:SendSingleTaskInfo(nTaskID, nTaskType, bFinishTask, nProgressNum)
    self:SendAllTaskInfo()
end

--设置任务保存的数据
function CTaskSystem:SetTaskParam(nTaskID, nTaskType, nParamType, nValue )
    if CTaskSystem.tTaskType.ePrinTask == nTaskType then
        self:SetTaskData(nParamType, nValue, self.m_tCurrPrinTaskParam)

    elseif CTaskSystem.tTaskType.eBranchTask == nTaskType then
        self:SetTaskData(nParamType, nValue, self.m_tCurrBranchTaskParam)

    elseif CTaskSystem.tTaskType.eGuideTask == nTaskType then
        self:SetTaskData(nParamType, nValue, self.m_tGuideTaskParam[nTaskID])
    end
    self:MarkDirty(true)
end

function CTaskSystem:SetTaskData(nParamType, nValue, tTaskParam)
    if CTaskSystem.tParamType.eNpcID == nParamType then
        tTaskParam.nNpcID = nValue

    elseif CTaskSystem.tParamType.eTaskStatus == nParamType then
        tTaskParam.nTaskStatus = nValue

    elseif CTaskSystem.tParamType.eProgressNum == nParamType then
        local nProgressNum = tTaskParam.nProgressNum
        tTaskParam.nProgressNum = nProgressNum + nValue
        
    -- elseif CTaskSystem.tParamType.eIsRewarded == nParamType then
    --     tTaskParam.bIsRewarded = nValue
    end
    self:MarkDirty(true)
end

function CTaskSystem:CheckBattleTask(tTaskParam, nTaskID)
    local bNpcIDValid = (tTaskParam.nNpcID == ctTaskSystemConf[nTaskID].nParam1)
    local bStatusValid = (tTaskParam.nTaskStatus == true)

    return (bNpcIDValid and bStatusValid)
end

function CTaskSystem:CheckTalkWithNpcTask(tTaskParam, nTaskID)
    local bNpcIDValid = (tTaskParam.nNpcID == ctTaskSystemConf[nTaskID].nParam1)

    return bNpcIDValid
end

function CTaskSystem:CheckCommitItemTask(tTaskParam, nTaskID)
    local bNpcIDValid = (tTaskParam.nNpcID == ctTaskSystemConf[nTaskID].nParam1)
    local bCommitItemEnough = (tTaskParam.nProgressNum >= ctTaskSystemConf[nTaskID].nParam3)

    return (bNpcIDValid and bCommitItemEnough)
end

function CTaskSystem:CheckGatherTask(tTaskParam, nTaskID)
    local bGatherEnough = (tTaskParam.nProgressNum >= ctTaskSystemConf[nTaskID].nParam3)
    return bGatherEnough
end

function CTaskSystem:TaskReward(nTaskID)
    local nType = ctTaskSystemConf[nTaskID].nTaskType
    local tData = nil
    if CTaskSystem.tTaskType.ePrinTask == nType then
        tData = self.m_tCurrPrinTaskParam
        goLogger:EventLog(gtEvent.eCompleteTask, self.m_oRole,  nTaskID) 

    elseif CTaskSystem.tTaskType.eBranchTask == nType then
        tData = self.m_tCurrBranchTaskParam

    elseif CTaskSystem.tTaskType.eGuideTask == nType then
        tData = self.m_tGuideTaskParam[nTaskID]
    end
    if tData.bIsRewarded then return end

    local tRewardConf = ctTaskSystemConf[nTaskID].tTaskReward
    for i, tConf in pairs(tRewardConf) do
        local nType = tConf[1]
        if nType == 0 or nType == self.m_oRole:GetConfID() then
            self.m_oRole:AddItem(tConf[2], tConf[3], tConf[4], "任务奖励", true)
        end
        --self.m_oRole:AddItem(tConf[1], tConf[2], tConf[3], "任务奖励", true)
    end
    tData.bIsRewarded = true
    self:MarkDirty(true)
    print("完成任务：" .. nTaskID)

    if nType == CTaskSystem.tTaskType.ePrinTask then
        CEventHandler:OnCompPrinTask(self.m_oRole, {nTaskID=nTaskID})
    elseif nType == CTaskSystem.tTaskType.eBranchTask then
        CEventHandler:OnCompBranchTask(self.m_oRole, {nTaskID=nTaskID})
    end
end

function CTaskSystem:SetCurrTaskID(nFinishTaskType, nFinishTaskID)
    --引导任务要判断等级开放
    local tConf = ctTaskSystemConf[nFinishTaskID]
    local nNextTaskID = tConf.nNextTask
    if nNextTaskID == 0 then
        local sTaskType = ""
        if tConf.nTaskType == CTaskSystem.tTaskType.ePrinTask then
            sTaskType = "主线"
        elseif tConf.nTaskType == CTaskSystem.tTaskType.eBranchTask then
            sTaskType = "支线"            
        end
        return self.m_oRole:Tips("所有"..sTaskType.."任务完成")
    end
    assert(ctTaskSystemConf[nNextTaskID], "下个任务不存在")    

    if CTaskSystem.tTaskType.ePrinTask == nFinishTaskType then
        --找到下个主线任务，赋值
        self.m_nCurrPrinTaskID = nNextTaskID
        goLogger:EventLog(gtEvent.eAccepTask, self.m_oRole,  self.m_nCurrPrinTaskID)
        self:ResetTaskParam(nFinishTaskID, self.m_tCurrPrinTaskParam)

    elseif CTaskSystem.tTaskType.eBranchTask == nFinishTaskType then
        self.m_nCurrBranchTaskID = nNextTaskID
        self:ResetTaskParam(nFinishTaskID, self.m_tCurrBranchTaskParam)

    elseif CTaskSystem.tTaskType.eGuideTask == nFinishTaskType then
        self.m_tGuideTaskID[nFinishTaskID] = nil
        self.m_tGuideTaskID[nNextTaskID] =  self.m_tGuideTaskID[nNextTaskID] or true
        self.m_tGuideTaskParam[nNextTaskID] = self.m_tGuideTaskParam[nNextTaskID] or {nNpcID = 0, nTaskStatus = 0, nProgressNum = 0}
        self:ResetTaskParam(nFinishTaskID, self.m_tGuideTaskParam)
    end
    self:MarkDirty(true)
end

function CTaskSystem:OnRoleLevelChange(nOldLevel, nNewLevel)
    --检查等级，开启支线任务
    -- local function _InitBranchTask()
    --     local tTaskConfList = _ctTaskSystemConf[CTaskSystem.tTaskType.eBranchTask]
    --     if tTaskConfList and next(tTaskConfList) then
    --         self.m_nCurrBranchTaskID = tTaskConfList[1].nTaskId
    --     else
    --         self.m_nCurrBranchTaskID = 0
    --     end
    --     self.m_tCurrBranchTaskParam.nNpcID = 0
    --     self.m_tCurrBranchTaskParam.nTaskStatus = 0
    --     self.m_tCurrBranchTaskParam.nProgressNum = 0
    --     self.m_tCurrBranchTaskParam.bIsRewarded = false 
    --     self:MarkDirty(true)
    --     if self.m_nCurrBranchTaskID > 0 then
    --         self:SendAllTaskInfo()
    --     end
    -- end
    -- local nBranchTaskID, tFristTaskConf = next(_ctTaskSystemConf[CTaskSystem.tTaskType.eBranchTask])
    -- if self.m_nCurrBranchTaskID == 0 and self.m_oRole.m_oSysOpen:IsSysOpen(5) then --and self.m_oRole:GetLevel() >= tFristTaskConf.nLevelLimit then
    --     _InitBranchTask()
    -- end

    --检查等级，加入引导任务
    if not _ctTaskSystemConf[CTaskSystem.tTaskType.eGuideTask] then return end
    for _, tConf in pairs(_ctTaskSystemConf[CTaskSystem.tTaskType.eGuideTask]) do 
        if nOldLevel <= tConf.nLevelLimit and tConf.nLevelLimit <= nNewLevel then
            self.m_tGuideTaskParam[tConf.nTaskId] = {nNpcID = 0, nTaskStatus = 0, nProgressNum = 0}
            self:MarkDirty(true)
        end
    end
end

function CTaskSystem:SendSingleTaskInfo(nTaskID, tTaskType, bCompelete, nCompeletNum)
    local tMsg = {tSingTaskInfo = {},}
    tMsg.tSingTaskInfo.nTaskID = nTaskID
    tMsg.tSingTaskInfo.nTaskType = tTaskType
    tMsg.tSingTaskInfo.bTaskCompelete = bCompelete
    tMsg.tSingTaskInfo.nParam1 = nCompeletNum or 0

    self.m_oRole:SendMsg("TaskSingleInfoRet", tMsg)
    --print(">>>>>>>>>>>>>>>>TaskSingleInfoRet")
    --PrintTable(tMsg)
end

function CTaskSystem:SendAllTaskInfo()
    local tMsg = {tTaskInfoList={}}

    local nRoleLevel = self.m_oRole:GetLevel()
    if self.m_nCurrPrinTaskID > 0 then
        local tPrinTemp = {}
        tPrinTemp.nTaskID = self.m_nCurrPrinTaskID
        tPrinTemp.nTaskType = CTaskSystem.tTaskType.ePrinTask
        tPrinTemp.bTaskCompelete = self.m_tCurrPrinTaskParam.bIsRewarded
        tPrinTemp.nParam1 = self.m_tCurrPrinTaskParam.nProgressNum
        local tConf = ctTaskSystemConf[self.m_nCurrPrinTaskID]
        local nNextID = tConf.nNextTask
        if nNextID <= 0 and self.m_tCurrPrinTaskParam.bIsRewarded then
            --最后一个任务，并且领取过奖励了就不发协议
        else
            table.insert(tMsg.tTaskInfoList, tPrinTemp)
        end
    end

    if self.m_nCurrBranchTaskID > 0 then
        local tBranchTemp = {}
        tBranchTemp.nTaskID = self.m_nCurrBranchTaskID
        tBranchTemp.nTaskType = CTaskSystem.tTaskType.eBranchTask
        tBranchTemp.bTaskCompelete = self.m_tCurrBranchTaskParam.bIsRewarded
        tBranchTemp.nParam1 = self.m_tCurrBranchTaskParam.nProgressNum
        local tConf = ctTaskSystemConf[self.m_nCurrBranchTaskID]
        local nNextID = tConf.nNextTask
        if nNextID <= 0 and self.m_tCurrBranchTaskParam.bIsRewarded then
            --最后一个任务，并且领取过奖励了就不发协议
        else
            table.insert(tMsg.tTaskInfoList, tBranchTemp)
        end
    end

    --目前没有第三种类型任务
    for nTaskID, tTaskParam in pairs(self.m_tGuideTaskParam) do
        local tGuideTemp = {}
        tGuideTemp.nTaskID = nTaskID
        tGuideTemp.nTaskType = CTaskSystem.tTaskType.eGuideTask
        tGuideTemp.bTaskCompelete = self.m_tGuideTaskParam[nTaskID].bIsRewarded
        tGuideTemp.nParam1 = self.m_tGuideTaskParam[nTaskID].nProgressNum
        table.insert(tMsg.tTaskInfoList, tGuideTemp)
    end

   self.m_oRole:SendMsg("TaskAllInfoRet", tMsg)
   --PrintTable(tMsg)
end

function CTaskSystem:fnHandlerCallBack(fnFunc, param1)
    if type(fnFunc) ~= "function" then
        return nil 
    end

    return function(...)
        return fnFunc(param1, ...)
    end
end

function CTaskSystem:ResetTaskParam(nFinishTaskID, tFinishTaskParam)
    if self.tTaskType.eGuideTask == ctTaskSystemConf[nFinishTaskID].nTaskType then
        self.m_tGuideTaskParam[nFinishTaskID] = nil

    else
        tFinishTaskParam.nNpcID = 0
        tFinishTaskParam.nTaskStatus = 0
        tFinishTaskParam.nProgressNum = 0
        tFinishTaskParam.bIsRewarded = false
    end
    self:MarkDirty(true)
end

function CTaskSystem:ClearAllParamInfo()
    self.m_nCurrPrinTaskID = 0
    self.m_nCurrBranchTaskID = 0
    self:ResetTaskParam(3, self.m_tCurrPrinTaskParam)
    self:ResetTaskParam(3, self.m_tCurrBranchTaskParam)
    self:MarkDirty(true)
end

function CTaskSystem:OnSysOpen(nSysID)
    if nSysID == 5 then         --目前只控制支线，主线客户端已控制是否可见
        local function _InitBranchTask()
            local tTaskConfList = _ctTaskSystemConf[CTaskSystem.tTaskType.eBranchTask]
            if tTaskConfList and next(tTaskConfList) then
                self.m_nCurrBranchTaskID = tTaskConfList[1].nTaskId
            else
                self.m_nCurrBranchTaskID = 0
            end
            self.m_tCurrBranchTaskParam.nNpcID = 0
            self.m_tCurrBranchTaskParam.nTaskStatus = 0
            self.m_tCurrBranchTaskParam.nProgressNum = 0
            self.m_tCurrBranchTaskParam.bIsRewarded = false 
            self:MarkDirty(true)
            if self.m_nCurrBranchTaskID > 0 then
                self:SendAllTaskInfo()
            end
        end
        local nBranchTaskID, tFristTaskConf = next(_ctTaskSystemConf[CTaskSystem.tTaskType.eBranchTask])
        if self.m_nCurrBranchTaskID == 0 and self.m_oRole.m_oSysOpen:IsSysOpen(5) then --and self.m_oRole:GetLevel() >= tFristTaskConf.nLevelLimit then
            _InitBranchTask()
        end
    end
end
