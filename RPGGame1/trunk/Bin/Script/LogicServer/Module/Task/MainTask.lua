--主线任务
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--配置表预处理
local _ctMainTaskConf = {}
local function _PreProcessMainTask()
	for nID, tConf in pairs(ctMainTaskConf) do
		if not _ctMainTaskConf[tConf.nType] then
			_ctMainTaskConf[tConf.nType] = {}
		end
		table.insert(_ctMainTaskConf[tConf.nType], tConf)
	end
end
_PreProcessMainTask()

function CMainTask:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_tProgressMap = {} --进度映射:{[type]={key=x/x}}
	self.m_tTaskMap = {} --{[taskid]=state, ...}
end

function CMainTask:GetType()
	return gtModuleDef.tMainTask.nID, gtModuleDef.tMainTask.sName
end

function CMainTask:LoadData(tData)
	if not tData then 
		return
	end
	for nType, tInfo in pairs(tData.m_tProgressMap) do
		if next(tInfo) then
			self.m_tProgressMap[nType] = tInfo
		end
	end

	for nID, nState in pairs(tData.m_tTaskMap) do
		local tConf = ctMainTaskConf[nID]
		if tConf then
			if self.m_tProgressMap[tConf.nType] then
				self.m_tTaskMap[nID] = nState
			end
		end
	end
end

function CMainTask:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tProgressMap = self.m_tProgressMap
	tData.m_tTaskMap = self.m_tTaskMap
	return tData
end

function CMainTask:Online()
	self:InitTask()
	self:SyncTaskList()
end

function CMainTask:InitTask()
	for nID, tConf in pairs(ctMainTaskConf) do
		if tConf.nPre == 0 and not self.m_tTaskMap[nID] then
			self:NewTask(nID)
		end
	end
end

--任务进度记录
function CMainTask:Progress(nType, nParam1, nParam2, bSet)
	print("CMainTask:Progress***", nType, nParam1, nParam2, bSet)
	if not _ctMainTaskConf[nType] then
		return LuaTrace("主线任务类型:"..nType.."不存在")
	end

	local tParam = _ctMainTaskConf[nType][1].tParam[1]
	if tParam[1] > 0 and tParam[2] > 0 then
		assert(nParam1 >= 0 and nParam2 >= 0, "参数非法")
	else
		assert(nParam1 > 0, "参数非法")
	end

	local tProgress = self.m_tProgressMap[nType] or {}
	self.m_tProgressMap[nType] = tProgress
	
	if tParam[1] > 0 and tParam[2] >0 then
		if bSet then
			tProgress[nParam1] = nParam2
		else
			tProgress[nParam1] = (tProgress[nParam1] or 0) + nParam2
		end
	else
		if bSet then
			tProgress[1] = nParam1
		else
			tProgress[1] = (tProgress[1] or 0) + nParam1
		end
	end

	local nFinish = 0
	for nID, nState in pairs(self.m_tTaskMap) do
		if nState == gtTaskState.eInit then
			if self:CheckState(nID) then
				nFinish = nFinish + 1
			end
		end
	end
	if nFinish > 0 then
		self:SyncTaskList()
	end
	
	self:MarkDirty(true)
end


--领取任务奖励
function CMainTask:GetAward(nTaskID)
	local nState = assert(self.m_tTaskMap[nTaskID], "任务不存在:"..nTaskID)
	if nState ~= gtTaskState.eFinish then
		self:SyncTaskList()
		return self.m_oPlayer:Tips("任务状态错误:"..nState)
	end
	local tAward = {}
	local tConf = ctMainTaskConf[nTaskID]
	for _, tItem in ipairs(tConf.tAward) do
		self.m_oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "主线任务奖励")
		table.insert(tAward, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
	end
	self.m_tTaskMap[nTaskID] = gtTaskState.eClosed
	self:MarkDirty(true)
	--下发领奖成功消息
	Network.PBSrv2Clt(self.m_oPlayer:GetSession(), "TaskAwardRet", {tAward=tAward})
	--触发任务链中下一任务
	self:OnTaskClosed(nTaskID)
end

--取到初始值
function CMainTask:InitValue(nTaskID)
	local tConf = ctMainTaskConf[nTaskID]
	if tConf.nType == gtMainTaskType.eCond6 then --某知己达到x级
		local nMCID = tConf.tParam[1][1]
		local oMC = self.m_oPlayer.m_oMingChen:GetObj(nMCID)
		return (oMC and oMC:GetLevel() or 0)

	elseif tConf.nType == gtMainTaskType.eCond29 then --宗人府席位
		return self.m_oPlayer.m_oZongRenFu:GetGrids()

	elseif tConf.nType == gtMainTaskType.eCond33 then --招募某某知己
		local nMCID = tConf.tParam[1][1]
		local oMC = self.m_oPlayer.m_oMingChen:GetObj(nMCID)
		return (oMC and 1 or 0)

	end
	return 0
end

--触发新任务
function CMainTask:NewTask(nTaskID)
	if self.m_tTaskMap[nTaskID] then
		return LuaTrace("任务已存在:"..nTaskID)
	end
	local tConf = assert(ctMainTaskConf[nTaskID], "任务配置不存在")
	if tConf.nCond > 0 and not self:IsChapterPass(tConf.nCond) then
		return
	end
	self.m_tTaskMap[nTaskID] = gtTaskState.eInit

	local tParam = tConf.tParam[1]
	local tProgress = self.m_tProgressMap[tConf.nType]
	if tProgress then
		if tParam[1] > 0 and tParam[2] > 0 then
			local nInitVal = self:InitValue(nTaskID)
			tProgress[tParam[1]] = tProgress[tParam[1]] or nInitVal
		end
	else
		local nInitVal = self:InitValue(nTaskID)
		if tParam[1] > 0 and tParam[2] > 0 then
			self.m_tProgressMap[tConf.nType] = {[tParam[1]]=nInitVal}
		else
			self.m_tProgressMap[tConf.nType] = {nInitVal}
		end
	end
	self:MarkDirty(true)
	self:OnNewTask(nTaskID)
end

--触发任务事件
function CMainTask:OnNewTask(nTaskID)
	if nTaskID == ctPlayTimeEtcConf[1].nOpenTask then
		self.m_oPlayer.m_oChengZhiDiQiu:OpenAct()
	end
	--神秘宝箱
	self.m_oPlayer.m_oShenMiBaoXiang:OnTaskAppear(nTaskID)
	--日志
	goLogger:EventLog(gtEvent.eMainTask, self.m_oPlayer, nTaskID)
end

--任务达成
function CMainTask:OnTaskFinish()
	self:SyncTaskList()
end

--任务已领取事件
function CMainTask:OnTaskClosed(nTaskID)
	local tConf = ctMainTaskConf[nTaskID]
	if tConf.nNext > 0 then	
		assert(ctMainTaskConf[tConf.nNext], "后继任务不存在:"..tConf.nNext)
		self:NewTask(tConf.nNext)
	end
	self:SyncTaskList()
	--日志
	goLogger:EventLog(gtEvent.eMainTaskFinish, self.m_oPlayer, nTaskID)
end

--检测任务状态
function CMainTask:CheckState(nTaskID)
	local nState = self.m_tTaskMap[nTaskID]
	if not nState or nState ~= gtTaskState.eInit then
		return
	end
	local tConf = ctMainTaskConf[nTaskID]
	local tProgress = self.m_tProgressMap[tConf.nType]
	if not tProgress then
		return
	end
	local tParam = tConf.tParam[1]
	if tParam[1] > 0 and tParam[2] > 0 then
		local nProgress = tProgress[tParam[1]] or 0
		if nProgress >= tParam[2] then
			self.m_tTaskMap[nTaskID] = gtTaskState.eFinish
			self:MarkDirty(true)
			return true
		else
			--通关某某关卡特殊处理下
			if tConf.nType == gtMainTaskType.eCond10 then
				if self.m_oPlayer.m_oDup:MaxDupPass() >= tParam[1] then
					self.m_tTaskMap[nTaskID] = gtTaskState.eFinish
					tProgress[tParam[1]] = tParam[2]
					self:MarkDirty(true)
					return true
				end
			end
			--X件时装达到YY级
			if tConf.nType == gtMainTaskType.eCond2 then
				if self.m_oPlayer.m_oFashion:GetLevelFSCount(tParam[1]) >= tParam[2] then
					self.m_tTaskMap[nTaskID] = gtTaskState.eFinish
					self:MarkDirty(true)
					return true
				end
			--X名知己达到YY级
			elseif tConf.nType == gtMainTaskType.eCond3 then
				if self.m_oPlayer.m_oMingChen:GetLevelMCCount(tParam[1]) >= tParam[2] then
					self.m_tTaskMap[nTaskID] = gtTaskState.eFinish
					self:MarkDirty(true)
					return true
				end
			end
		end

	else
		if (tProgress[1] or 0) >= tParam[1] then
			self.m_tTaskMap[nTaskID] = gtTaskState.eFinish
			self:MarkDirty(true)
			return true
		end
	end
end

--取知己名字
function CMainTask:GetObjName(nTaskID, nObjID)
	local tConf = ctMainTaskConf[nTaskID]
	if tConf.nType == gtMainTaskType.eCond6
		or tConf.nType == gtMainTaskType.eCond31
		or tConf.nType == gtMainTaskType.eCond33
		or tConf.nType == gtMainTaskType.eCond39 then --知己

		local oMC = self.m_oPlayer.m_oMingChen:GetObj(nObjID)
		if oMC then
			return oMC:GetName()
		end

		local tConf = ctMingChenConf[nObjID]
		if tConf then
			return tConf.sName 
		else
			LuaTrace("知己配置不存在:", nObjID)
		end
	end
	return ""
end

--同步任务列表
function CMainTask:SyncTaskList()
	local tList = {}
	for nID, v in pairs(self.m_tTaskMap) do
		self:CheckState(nID)
		local nState = self.m_tTaskMap[nID]
		if nState ~= gtTaskState.eClosed then
			local tConf = ctMainTaskConf[nID]
			local tParam = ctMainTaskConf[nID].tParam[1]
			local tProgress = self.m_tProgressMap[tConf.nType] or {}
			local tInfo = {nID=nID, nState=nState, nProgress=0, sName=""}
			if tParam[1] > 0 and tParam[2] > 0 then
				if tConf.nType == gtMainTaskType.eCond2 then
					tInfo.nProgress = self.m_oPlayer.m_oFashion:GetLevelFSCount(tParam[1])
				elseif tConf.nType == gtMainTaskType.eCond3 then
					tInfo.nProgress = self.m_oPlayer.m_oMingChen:GetLevelMCCount(tParam[1])
				else
					tInfo.nProgress = tProgress[tParam[1]] or 0
					tInfo.sName = self:GetObjName(nID, tParam[1])
				end
			else
				tInfo.nProgress = tProgress[1] or 0
			end
			table.insert(tList, tInfo)
		end
	end
	Network.PBSrv2Clt(self.m_oPlayer:GetSession(), "MainTaskListRet", {tList=tList})
end

--前端完成任务请求
function CMainTask:CompleteTaskReq(nTaskID)
	self:CheckState(nTaskID)
	local nState = self.m_tTaskMap[nTaskID]
	if not nState then
		self:SyncTaskList()	
		return self.m_oPlayer:Tips(string.format("没有该任务或者任务状态错误 %s:%s", nTaskID, nState))
	end
	if nState ~= gtTaskState.eInit then
		return
	end
	local tMTType = gtMainTaskType 
	local tConf = ctMainTaskConf[nTaskID]
	local tLimit = {
		tMTType.eCond1,
		tMTType.eCond32,
	}
	if not table.InArray(tConf.nType, tLimit) then
		return self.m_oPlayer:Tips(string.format("该类任务不允许请求完成 %s:%s", nTaskID, tConf.nType))
	end
	self:Progress(tConf.nType, 1, nil, true)
end

--GM完成任务
function CMainTask:GMCompleteTask(nID)
	if nID then
		if not self.m_tTaskMap[nID] then
			return self.m_oPlayer:Tips("没有任务:"..nID)
		end
		local tConf = ctMainTaskConf[nID]
		local tParam = tConf.tParam[1]
		if tParam[1] > 0 and tParam[2] > 0 then
			self:Progress(tConf.nType, tParam[1], tParam[2], true)
		else
			self:Progress(tConf.nType, tParam[1], nil, true)
		end
	else
		for nID, nState in pairs(self.m_tTaskMap) do
			if nState == gtTaskState.eInit then
				local tConf = ctMainTaskConf[nID]
				local tParam = tConf.tParam[1]
				if tParam[1] > 0 and tParam[2] > 0 then
					self:Progress(tConf.nType, tParam[1], tParam[2], true)
				else
					self:Progress(tConf.nType, tParam[1], nil, true)
				end
			end
		end
	end
end

--任务是否存在
function CMainTask:IsTaskExist(nID)
	return self.m_tTaskMap[nID]
end

--GM生成任务
function CMainTask:GMInitTask(nID)
	local tConf = ctMainTaskConf[nID]
	if not tConf then
		return self.m_oPlayer:Tips("请输入正确任务ID")
	end
	local tConf = ctMainTaskConf[nID]
	self.m_tTaskMap[nID] = nil
	self.m_tProgressMap[tConf.nType] = nil
	self:NewTask(nID)
	self:SyncTaskList()
end