--每日任务
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--配置表预处理
local _ctDailyTaskConf = {}
local function _PreProcessDailyTask()
	for nID, tConf in pairs(ctDailyTaskConf) do
		if not _ctDailyTaskConf[tConf.nType] then
			_ctDailyTaskConf[tConf.nType] = {}
		end
		table.insert(_ctDailyTaskConf[tConf.nType], tConf)
	end
end
_PreProcessDailyTask()

function CDailyTask:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_tProgressMap = {} --进度映射:{[type]={key=x/x}}
	self.m_tTaskMap = {} --{[taskid]=state, ...}
	self.m_nResetTime = 0

	self.m_nActivity = 0
	self.m_tActivityState = {}
end

function CDailyTask:GetType()
	return gtModuleDef.tDailyTask.nID, gtModuleDef.tDailyTask.sName
end

function CDailyTask:LoadData(tData)
	if not tData then 
		return
	end
	self.m_nResetTime = tData.m_nResetTime
	self.m_nActivity = tData.m_nActivity or 0
	self.m_tActivityState = tData.m_tActivityState or {}

	for nType, tInfo in pairs(tData.m_tProgressMap) do
		if next(tInfo) then
			self.m_tProgressMap[nType] = tInfo
		end
	end
	for nID, nState in pairs(tData.m_tTaskMap) do
		local tConf = ctDailyTaskConf[nID]
		if tConf then
			if self.m_tProgressMap[tConf.nType] then
				self.m_tTaskMap[nID] = nState
			end
		end
	end
end

function CDailyTask:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tProgressMap = self.m_tProgressMap
	tData.m_tTaskMap = self.m_tTaskMap
	tData.m_nResetTime = self.m_nResetTime
	tData.m_nActivity = self.m_nActivity
	tData.m_tActivityState = self.m_tActivityState
	return tData
end

function CDailyTask:Online()
	self:CheckReset()
	if not self:CheckActivityState() then
		self:SyncTaskList()
	end
end

function CDailyTask:AddActivity(nVal)
	self:CheckReset()	
	self.m_nActivity = math.min(nMAX_INTEGER, math.max(0, self.m_nActivity+nVal))
	self:MarkDirty(true)
	self:CheckActivityState()
end

function CDailyTask:CheckActivityState()
	local nFinish = 0
	for nID, tConf in ipairs(ctDailyActivityTaskConf) do
		if not self.m_tActivityState[nID] then
			self.m_tActivityState[nID] = 0
			self:MarkDirty(true)
		end
		if self.m_nActivity >= tConf.nActivity then
			if self.m_tActivityState[nID] == 0 then
				self.m_tActivityState[nID] = 1
				self:MarkDirty(true)
				nFinish = nFinish + 1
			end
		end
	end
	if nFinish > 0 then
		self:SyncTaskList()
		return true
	end
end

function CDailyTask:CheckReset()
	local nNowSec = os.time()
	if not os.IsSameDay(self.m_nResetTime, nNowSec, 5*3600) then
		self.m_nResetTime = nNowSec
		self.m_tProgressMap = {}
		self.m_nActivity = 0
		self.m_tTaskMap = {}
		self.m_tActivityState = {}
		self:MarkDirty(true)

		for nID, tConf in pairs(ctDailyTaskConf) do
			if tConf.nPre == 0 then
				self:NewTask(nID)
			end
		end
	end
end

--任务进度记录
function CDailyTask:Progress(nType, nParam1, nParam2, bSet)
	if not _ctDailyTaskConf[nType] then
		return
	end
	local tParam = _ctDailyTaskConf[nType][1].tParam[1]
	if tParam[1] == -1 and tParam[2] > 0 then
		assert(nParam1 and nParam2, "参数非法")
	end
	local tProgress = self.m_tProgressMap[nType]
	if not tProgress then
		return
	end
	self:CheckReset()

	if tParam[1] == -1 and tParam[2] >0 then
		if not tProgress[nParam1] then
			return
		end
		if bSet then
			tProgress[nParam1] = nParam2
		else
			tProgress[nParam1] = tProgress[nParam1] + nParam2
		end
	else
		if bSet then
			tProgress[1] = nParam1
		else
			tProgress[1] = tProgress[1] + nParam1
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


--领取任务奖励(1:普通任务; 2宝箱任务)
function CDailyTask:GetAward(nTaskID, nType)
	print("CDailyTask:GetAward***", nTaskID, nType)

	local tAward = {} 
	if nType == 1 then --普通任务
		local nState = assert(self.m_tTaskMap[nTaskID], "任务不存在")
		if nState ~= gtTaskState.eFinish then
			return self.m_oPlayer:Tips("任务状态错误:"..nState)
		end
		local tConf = ctDailyTaskConf[nTaskID]
		for _, tItem in ipairs(tConf.tAward) do
			self.m_oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "每日任务奖励")
			table.insert(tAward, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
		end
		self.m_tTaskMap[nTaskID] = gtTaskState.eClosed
		self:MarkDirty(true)
		self:OnTaskClosed(nTaskID)

	else --宝箱任务
		if self.m_tActivityState[nTaskID] == 0 then
			return self.m_oPlayer:Tips("活跃度不足")
		end
		if self.m_tActivityState[nTaskID] == 2 then
			return self.m_oPlayer:Tips("宝箱已领取")
		end
		self.m_tActivityState[nTaskID] = 2
		self:MarkDirty(true)

		local tAward = self:MakeActivityAward(nTaskID)
		for _, tItem in ipairs(tAward) do
			self.m_oPlayer:AddItem(tItem.nType, tItem.nID, tItem.nNum, "每日任务奖励")
		end

	end

	--下发领奖成功消息
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "TaskAwardRet", {tAward=tAward})
	self:SyncTaskList()
end

--取到初始值
function CDailyTask:InitValue(nTaskID)
	local nInitVal1, nInitVal2 = 0, 0
	-- local tConf = ctDailyTaskConf[nTaskID]
	-- if gtDailyTaskType.eCond1 == tConf.nType then --从已获得的大臣中随机一名，等级达到X级
	-- 	local oMC = self.m_oPlayer.m_oMingChen:RandObj(1)[1]
	-- 	if oMC then
	-- 		nInitVal1, nInitVal2 = oMC:GetID(), oMC:GetLevel()
	-- 	end

	-- elseif gtDailyTaskType.eCond2 == tConf.nType then --从已获得的妃子中随机一名，亲密度达到X（不随机冷宫中的）
	-- 	local oFZ = self.m_oPlayer.m_oFeiZi:RandObj(1)[1]
	-- 	nInitVal1, nInitVal2 = oFZ:GetID(), oFZ:GetQinMi()

	-- end
	return nInitVal1, nInitVal2
end

--触发新任务
function CDailyTask:NewTask(nTaskID)
	assert(not self.m_tTaskMap[nTaskID], "任务已存在")
	local tConf = assert(ctDailyTaskConf[nTaskID], "任务配置不存在")
	-- if (tConf.nCond or 0) > 0 and not self:IsChapterPass(tConf.nCond) then
	-- 	return
	-- end
	self.m_tTaskMap[nTaskID] = gtTaskState.eInit

	local tParam = tConf.tParam[1]
	local tProgress = self.m_tProgressMap[tConf.nType]
	if tProgress then
		if tParam[1] == -1 and tParam[2] > 0 then
			local nInitVal1, nInitVal2 = self:InitValue(nTaskID)
			tProgress[nInitVal1] = nInitVal2
		end
	else
		local nInitVal1, nInitVal2 = self:InitValue(nTaskID)
		if tParam[1] == -1 and tParam[2] > 0 then
			self.m_tProgressMap[tConf.nType] = {[nInitVal1]=nInitVal2} 
		else
			self.m_tProgressMap[tConf.nType] = {nInitVal1}
		end
	end

	self:MarkDirty(true)
end

--任务达成
function CDailyTask:OnTaskFinish()
	self:SyncTaskList()
end

--任务已领取
function CDailyTask:OnTaskClosed(nTaskID)
	local tConf = ctDailyTaskConf[nTaskID]
	if tConf.nNext > 0 then	
		assert(ctDailyTaskConf[tConf.nNext], "后继任务不存在:"..tConf.nNext)
		self:NewTask(tConf.nNext)
	end
	self:SyncTaskList()
	--日志
	goLogger:EventLog(gtEvent.eDailyTaskFinish, self.m_oPlayer, nTaskID)
end

--检测任务状态
function CDailyTask:CheckState(nTaskID)
	local nState = self.m_tTaskMap[nTaskID]
	if not nState or nState ~= gtTaskState.eInit then
		return
	end

	local tConf = ctDailyTaskConf[nTaskID]
	local tProgress = self.m_tProgressMap[tConf.nType]
	if not tProgress then
		return
	end

	local tParam = tConf.tParam[1]
	if tParam[1] == -1 and tParam[2] > 0 then
		local nObjID, nProgress = next(tProgress)
		if (nProgress or 0) >= tParam[2] then
			self.m_tTaskMap[nTaskID] = gtTaskState.eFinish
			self:MarkDirty(true)
			return true
		end
	elseif (tProgress[1] or 0) >= tParam[1] then
		self.m_tTaskMap[nTaskID] = gtTaskState.eFinish
		self:MarkDirty(true)
		return true
	end
end

--取大臣或者妃子名字
function CDailyTask:GetObjName(nTaskID, nObjID)
	-- local tConf = ctDailyTaskConf[nTaskID]
	-- if tConf.nType == gtDailyTaskType.eCond1 then --随机大臣
	-- 	local oMC = self.m_oPlayer.m_oMingChen:GetObj(nObjID)
	-- 	if oMC then return oMC:GetName() end
	-- 	local tConf = ctMingChenConf[nObjID]
	-- 	if tConf then
	-- 		return tConf.sName 
	-- 	else
	-- 		LuaTrace("大臣配置不存在:", nObjID)
	-- 		return ""
	-- 	end

	-- elseif tConf.nType == gtDailyTaskType.eCond2 then --随机妃子
	-- 	local oFZ = self.m_oPlayer.m_oFeiZi:GetObj(nObjID)
	-- 	if oFZ then return oFZ:GetName() end
	-- 	local tConf = ctFeiZiConf[nObjID]
	-- 	if tConf then
	-- 		return ctFeiZiConf[nObjID].sName 
	-- 	else
	-- 		LuaTrace("妃子配置不存在:", nObjID)
	-- 		return ""
	-- 	end
	-- end
	return ""
end

--活跃任务奖励
function CDailyTask:MakeActivityAward(nTaskID)
	local tConf = ctDailyActivityTaskConf[nTaskID]
	local tAttr = self.m_oPlayer:GetAttr()

	local tAwardMap = {}
	local tYLParam = tConf.tYLParam[1]
	local tWHParam = tConf.tWHParam[1]
	local tBLParam = tConf.tBLParam[1]
	if tYLParam[1] > 0 and tYLParam[2] > 0 then
		local nYL = tYLParam[1] + tYLParam[2] * tAttr[1]
		local nPropID = gtCurrProp[gtCurrType.eYinLiang]
		tAwardMap[nPropID] = (tAwardMap[nPropID] or 0) + nYL
	end
	if tWHParam[1] > 0 and tWHParam[2] > 0 then
		local nWH = tWHParam[1] + tWHParam[2] * tAttr[2]
		local nPropID = gtCurrProp[gtCurrType.eWenHua]
		tAwardMap[nPropID] = (tAwardMap[nPropID] or 0) + nWH
	end
	if tBLParam[1] > 0 and tBLParam[2] > 0 then
		local nBL = tBLParam[1] + tBLParam[2] * tAttr[3]
		local nPropID = gtCurrProp[gtCurrType.eBingLi]
		tAwardMap[nPropID] = (tAwardMap[nPropID] or 0) + nBL
	end
	for _, tItem in ipairs(tConf.tAward) do
		if tItem[1] > 0 then
			tAwardMap[tItem[2]] = (tAwardMap[tItem[2]] or 0) + tItem[3]
		end
	end

	local tAwardList = {}
	for nID, nNum in pairs(tAwardMap) do
		table.insert(tAwardList, {nType=gtItemType.eProp, nID=nID, nNum=nNum})
	end

	return tAwardList
end

--同步任务列表
function CDailyTask:SyncTaskList()
	self:CheckReset()
	local tList = {}
	for nID, v in pairs(self.m_tTaskMap) do
		self:CheckState(nID)
		local nState = self.m_tTaskMap[nID]

		local tConf = ctDailyTaskConf[nID]
		local tParam = tConf.tParam[1]
		local tProgress = self.m_tProgressMap[tConf.nType]

		local tInfo = {nID=nID, nState=nState, nProgress=0, sName=""}
		if tParam[1] == -1 and tParam[2] > 0 then
			local sName = ""
			local nObjID, nProgress = next(tProgress)
			if nObjID > 0 then
				sName = self:GetObjName(nID, nObjID)
			end
			tInfo.sName = sName
			tInfo.nProgress = nProgress or 0

		else
			tInfo.nProgress = tProgress[1]

		end
		table.insert(tList, tInfo)
	end
	
	local tActList = {}
	for nID, tConf in ipairs(ctDailyActivityTaskConf) do
		local tInfo = {
			nID = nID,
			tAward = self:MakeActivityAward(nID),
			nState = (self.m_tActivityState[nID] or 0),
		}
		table.insert(tActList, tInfo)
	end
	local tMsg = {tList=tList, tActList=tActList, nActivity=self.m_nActivity}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "DailyTaskListRet", tMsg)
end

--重置每天任务
function CDailyTask:GMReset()
	self.m_nResetTime = 0
	self:MarkDirty(true)
end