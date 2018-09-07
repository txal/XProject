--活动管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nAutoSaveTime = 5*60
function CHDMgr:Ctor()
	self.m_nSaveTick = nil 		--保存计时器
	self.m_nMinTick = nil 		--分钟计时器
	self.m_tActivityMap = {} 	--活动映射
	self:Init()
end
 
function CHDMgr:Init()
	--self.m_tActivityMap[gtHDDef.eXXX] = CXXX:new(gtHDDef.eXXX)	--例子
end

--加载数据
function CHDMgr:LoadData()
	print("加载活动数据------")
	for k, v in pairs(self.m_tActivityMap) do
		v:LoadData()
	end

	self:StartTick()
	self:OnMinEvent()
end

--注册定时保存
function CHDMgr:StartTick()
	local nNextMinTime = os.NextMinTime(os.time())
	self.m_nMinTick = goTimerMgr:Interval(nNextMinTime, function() self:OnMinEvent() end)
	self.m_nSaveTick = goTimerMgr:Interval(nAutoSaveTime, function() self:SaveData() end)
end

--保存数据
function CHDMgr:SaveData()
	for k, v in pairs(self.m_tActivityMap) do
		v:SaveData()
	end
end

--释放处理
function CHDMgr:OnRelease()
	goTimerMgr:Clear(self.m_nSaveTick)
	self.m_nSaveTick = nil
	goTimerMgr:Clear(self.m_nMinTick)
	self.m_nMinTick = nil
	
	for k, v in pairs(self.m_tActivityMap) do
		v:OnRelease()
	end
end

--分钟计时器
function CHDMgr:OnMinEvent()
	goTimerMgr:Clear(self.m_nMinTick)
	local nNextMinTime = os.NextMinTime(os.time())
	self.m_nMinTick = goTimerMgr:Interval(nNextMinTime, function() self:OnMinEvent() end)

	--更新状态
	for nID, oAct in pairs(self.m_tActivityMap) do
		--为啥要用xpcall呢，因为要防止一个活动出错影响到其他活动的更新
	    xpcall(function() oAct:UpdateState() end, function(sErr) LuaTrace(sErr, debug.traceback()) end)
	end
end

--玩家上线
function CHDMgr:Online(oPlayer)
	for k, v in pairs(self.m_tActivityMap) do
		v:Online(oPlayer)
	end
end

--取活动对象
function CHDMgr:GetHuoDong(nID)
	return self.m_tActivityMap[nID]
end

--GM后台开启活动调用
function CHDMgr:GMOpenAct(nActID, nSubActID, nStartTime, nAwardTime, nEndTime, nExtID1, nExtID2)
	print("CHDMgr:GMOpenAct***", nActID, nStartTime, nEndTime)
	assert(nStartTime <= nEndTime, "时间区间非法")
	if not ctHuoDongConf[nActID] then
		return LuaTrace("活动:", nActID, "不存在")
	end
	if not self.m_tActivityMap[nActID] then
		return LuaTrace("活动:", nActID, "未实现")
	end

	local nAwardTime = nAwardTime or ctHuoDongConf[nActID].nAwardTime
	self.m_tActivityMap[nActID]:OpenAct(nStartTime, nEndTime, nAwardTime, nExtID1, nExtID2)
	return self.m_tActivityMap[nActID]:GetActTime()
end

--取某活动的状态
function CHDMgr:GetActState(nActID, nSubActID)
	return self.m_tActivityMap[nActID]:GetState()
end

--循环活动开启
function CHDMgr:HDCirclActOpen(tList)
	local tSuccList = {}
	for _, tData in ipairs(tList) do
		local nIndex = tData.nIndex
		local nActID = tData.nActID
		local nSubActID = tData.nSubActID
		local nExtID = tData.nExtID1
		local nExtID1 = tData.nExtID2
		local nBeginTime =tData.nBeginTime
		local tEndTime = tData.tEndTime
		local nEndTime = nBeginTime+tEndTime[1]*24*3600+tEndTime[2]*3600+tEndTime[3]*60

		local nState = self:GetActState(nActID, nSubActID)
		if nState == CHDBase.tState.eStart or nState == CHDBase.tState.eAward then
			LuaTrace("CHDMgr:HDCirclActOpen开启循环活动失败(活动进行中)", nState, tData)
		else
			local nBeginTime1, nEndTime1, nAwardTime1 = self:GMOpenAct(nActID, nSubActID, nBeginTime, nEndTime, nil, nExtID1, nExtID2)
			if nBeginTime1 and nEndTime1 and nAwardTime1 then
				table.insert(tSuccList, {nIndex=nIndex, nBeginTime=nBeginTime1, nEndTime=nEndTime1, nAwardTime=nAwardTime1})
				LuaTrace("CHDMgr:HDCirclActOpen开始循环活动成功", tData)
			else
				LuaTrace("CHDMgr:HDCirclActOpen开始循环活动失败", tData)
			end
		end
	end
	return tSuccList
end

goHDMgr = goHDMgr or CHDMgr:new()
