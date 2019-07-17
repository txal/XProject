--PVP活动管理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPVPActivityMgrBase:Ctor(nActivityID)
	self.m_tInstMap = {}   --活动实例map {SchoolID:ActivityInst}
	self.m_nActivityID = nActivityID
	self.m_bOpen = false
	self.m_nTimer = nil
	self.m_nReleaseTimer = nil
	--------------------------------
	--这2个数据方便GM管理添加的，只在活动开启时，有效
	self.m_nOpenTime = nil
	self.m_nEndTime = nil
	self.m_nStartTime = nil
	--------------------------------
	self.m_nServerStartTime = os.time()

	self:Init()
end

function CPVPActivityMgrBase:Init()
	self.m_nTimer = GetGModule("TimerMgr"):Interval(1, function () self:Tick() end) --为了实时性，1秒一次检查，没其他复杂逻辑，不影响性能
	assert(self.m_nTimer, "创建定时器错误")
end

function CPVPActivityMgrBase:GetActivityID() return self.m_nActivityID end
function CPVPActivityMgrBase:GetConf() return ctPVPActivityConf[self.m_nActivityID] end
function CPVPActivityMgrBase:IsOpen() return self.m_bOpen end
function CPVPActivityMgrBase:SetOpenState(bOpen) self.m_bOpen = bOpen end

function CPVPActivityMgrBase:Release()
	--[[
	for k, oInst in pairs(self.m_tInstMap) do
		oInst:Release()
	end
	self.m_tInstMap = {}
	if self.m_nTimer then
		GetGModule("TimerMgr"):Clear(self.m_nTimer)
		self.m_nTimer = nil
	end
	if self.m_nReleaseTimer then
		GetGModule("TimerMgr"):Clear(self.m_nReleaseTimer)
		self.m_nReleaseTimer = nil
	end
	]]
	self:ReleaseActivityInst()
	if self.m_nTimer then
		GetGModule("TimerMgr"):Clear(self.m_nTimer)
		self.m_nTimer = nil
	end
end

function CPVPActivityMgrBase:CheckActivityOpen()
	local tConf = self:GetConf()
	assert(tConf, "数据错误")
	--local bOpen = CDailyActivity:CheckOpenTime(tConf.nScheduleID) --暂时不依赖，引发bug
	local bOpen = false
	local tDailyActivityConf = ctDailyActivity[tConf.nScheduleID] 
	assert(tDailyActivityConf, "配置错误")
	local nOpenStamp = CDailyActivity:GetStartStamp(tConf.nScheduleID)
	local nEndStamp = CDailyActivity:GetEndStamp(tConf.nScheduleID)
	local nTimeStamp = os.time()
	local nWeekDay = os.WDay(nTimeStamp)
	local bToday = false
	for k, v in pairs(tDailyActivityConf.tOpenList) do
		if v[1] == nWeekDay then
			bToday = true
			break
		end
	end
	if not bToday then
		return false
	end
	if nTimeStamp >= nOpenStamp and nTimeStamp <= nEndStamp then
		bOpen = true
	end
	return bOpen
end

function CPVPActivityMgrBase:GetNextOpenTime()
	local tConf = self:GetConf()
	local tDailyConf = ctDailyActivity[tConf.nScheduleID]
	if not tDailyConf then 
		return 0
	end
	local nOpenTime = tDailyConf.nOpenTime
	if nOpenTime >= 2400 then 
		nOpenTime = 2359
	end
	local nSecs = math.floor(nOpenTime / 100)*3600 + 
		math.floor(math.min(nOpenTime % 100, 59))*60

	local nNextTime = nil
	local nCurTime = os.time() + 1
	for k, v in ipairs(tDailyConf.tOpenList) do 
		if v[1] > 0 and v[1] < 8 then 
			local nTemp = os.WeekDayTime(nCurTime, v[1], nSecs)
			if nTemp > nCurTime then 
				if not nNextTime or nNextTime > nTemp then 
					nNextTime = nTemp
				end
			end
		end
	end
	return nNextTime or 0
end

function CPVPActivityMgrBase:CheckActivityEnd()
	if os.time() >= self:GetEndTime() then --结束时间根据自身设置的结束时间来确定
		return true
	end
	return false
end

--因为流程更改，创建活动实例前，必须要调用这个设置下开启时间
function CPVPActivityMgrBase:SetActivityTime(nOpenTime, nEndTime, nPrepareLastTime)
	self.m_nOpenTime = nOpenTime or CDailyActivity:GetStartStamp(self:GetConf().nScheduleID)
	self.m_nEndTime = nEndTime or CDailyActivity:GetEndStamp(self:GetConf().nScheduleID)
	nPrepareLastTime = nPrepareLastTime or self:GetConfPrepareTime()
	self.m_nStartTime = self.m_nOpenTime + nPrepareLastTime
	assert(self.m_nOpenTime <= self.m_nStartTime and self.m_nStartTime <= self.m_nEndTime, "数据错误")
end
function CPVPActivityMgrBase:GetOpenTime() return self.m_nOpenTime end
function CPVPActivityMgrBase:GetEndTime() return self.m_nEndTime end
function CPVPActivityMgrBase:GetPrepareLastTime() return self.m_nStartTime - self:GetOpenTime() end
function CPVPActivityMgrBase:GetConfPrepareTime() 
	local nScheduleID = self:GetConf().nScheduleID
	local tDailyConf = ctDailyActivity[nScheduleID]

	local nDefaultTime = 600
	if not tDailyConf then 
		return nDefaultTime
	end
	local nPrepareTime = math.floor(tDailyConf.nArrivaTime * 60)
	nPrepareTime = nPrepareTime > 0 and nPrepareTime or nDefaultTime
	return nPrepareTime
end

function CPVPActivityMgrBase:OnActivityStart() 
	self:NotifyActivityOpen()
end

function CPVPActivityMgrBase:NotifyActivityOpen() 
	Network.oRemoteCall:Call("GPVPActivityOpenNotify", gnWorldServerID, 
		goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, self:GetActivityID(), gnServerID)
end

function CPVPActivityMgrBase:NotifyActivityClose() 
	print(string.format("活动(%d)结束，通知销毁NPC", self:GetActivityID()))
	Network.oRemoteCall:Call("GPVPActivityCloseNotify", gnWorldServerID, 
		goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, self:GetActivityID(), gnServerID)
end

function CPVPActivityMgrBase:ReleaseActivityInst() 
	--这里不调用self:Release()，其内部会回收self.m_nTimer，会导致此管理器后续工作不正常
	print("活动管理器开始回收活动实例")
	for k, oInst in pairs(self.m_tInstMap) do
		oInst:Release()
	end
	self.m_tInstMap = {}
	if self.m_nReleaseTimer then
		GetGModule("TimerMgr"):Clear(self.m_nReleaseTimer)
		self.m_nReleaseTimer = nil
	end
	self:SetOpenState(false) --重新置为false --正常情况为false，如果不通过定时器而是外部直接调用，则可能引发状态错误
end

function CPVPActivityMgrBase:OnAcitivityEnd()
	if self.m_nReleaseTimer then 
		GetGModule("TimerMgr"):Clear(self.m_nReleaseTimer)
		self.m_nReleaseTimer = nil
	end
	self.m_nReleaseTimer = GetGModule("TimerMgr"):Interval(150, function () self:ReleaseActivityInst() end) --活动实例保留300秒
	assert(self.m_nReleaseTimer, "创建定时器错误")
	self:NotifyActivityClose()
end

function CPVPActivityMgrBase:Tick()
	local nCurTime = os.time() --防止开服启动活动，rpc失败
	if math.abs(nCurTime - self.m_nServerStartTime) < 60 then 
		return 
	end
	if not self:IsOpen() then  --未开启情况下
		local bOpen =  self:CheckActivityOpen() --检查活动是否应该开启
		if bOpen then
			self:ReleaseActivityInst() --防止GM开启时间和正常配置时间部分重叠，开启前，先尝试清理下旧的，可能旧的已结束，但是没销毁
			self:SetActivityTime() --采用默认配置时间
			self:OnActivityStart()
			self:SetOpenState(true)
		end
	else  --已开启情况下
		local bClose = self:CheckActivityEnd() --检查活动是否应该结束
		if bClose then
			self:OnAcitivityEnd()
			self:SetOpenState(false)
		end
	end
	for k, oInst in pairs(self.m_tInstMap) do
		oInst:Tick()
	end
end

function CPVPActivityMgrBase:GMRestart(nPrepareLastTime, nLastTime)
	nPrepareLastTime = nPrepareLastTime or 15  --准备时长
	nLastTime = nLastTime or 60  --默认一个小时
	if nPrepareLastTime <= 0 then
		return false, "活动准备时长不正确"
	end
	if nLastTime < 0 then
		return false, "活动持续时长不正确"
	end
	print(string.format("准备时间<%d>分钟，战斗时间<%d>分钟", nPrepareLastTime, nLastTime))
	nPrepareLastTime = nPrepareLastTime * 60 --将分钟转换成秒
	nLastTime = nLastTime * 60

	local nTimeStamp = os.time()
	print("正在关闭活动...")
	if self:IsOpen() then 
		self:OnAcitivityEnd() 
	end
	self:ReleaseActivityInst()
	print("准备重新开启活动...")
	self:SetActivityTime(nTimeStamp, nTimeStamp + nPrepareLastTime + nLastTime, nPrepareLastTime)
	self:OnActivityStart()
	self:SetOpenState(true)
	print("活动开启成功，ActivityID:"..self:GetActivityID())
	return true
end

function CPVPActivityMgrBase:GetInst(...) assert(false, "子类未实现") end

--请注意，这里不能使用语法糖的self及活动实例相关数据，玩家分布在不同的逻辑服上，并不确保处于活动所在逻辑服
function CPVPActivityMgrBase:EnterCheck(oRole, nActivityID, fnCallback)  assert(false, "子类未实现") end 
function CPVPActivityMgrBase:EnterReq(oRole, nActivityID) 
	assert(oRole and nActivityID > 0, "参数错误")
	local fnRemoteCheckCallBack = function (bRet, sTipsCon, nMixID)
		if not bRet then
			if sTipsCon then
				oRole:Tips(sTipsCon)
			end
			return
		end
		local tConf = ctPVPActivityConf[nActivityID]
		assert(tConf, "找不到配置")
		local tSceneConf = CPVPActivityMgr:GetActivitySceneConf(nActivityID)
		assert(tSceneConf, "找不到配置")
		-- 随机坐标和面向
		local nXPosMin = math.min(tSceneConf.nWidth, 200)  --避免地图长款不足200的异常情况
		local nXPosMax = math.max(nXPosMin, tSceneConf.nWidth - 200)
		local nYPosMin = math.min(tSceneConf.nHeight, 200)
		local nYPosMax = math.max(nYPosMin, tSceneConf.nHeight - 200)

		local nFace = math.random(0, 3)
		local nXPos = math.random(nXPosMin, nXPosMax) --避免出生在地图边缘
		local nYPos = math.random(nYPosMin, nYPosMax)
		oRole:EnterScene(nMixID, nXPos, nYPos, 0, nFace)
	end
	self:EnterCheck(oRole, nActivityID, fnRemoteCheckCallBack)
end


