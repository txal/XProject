--活动管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CHDMgr:Ctor()
	self.m_nSaveTick = nil 		--保存计时器
	self.m_nMinTick = nil 		--分钟计时器
	self.m_tActivityMap = {} 	--活动映射
	self:Init()
end
 
function CHDMgr:Init()
	--self.m_tActivityMap[gtHDDef.eXXX] = CXXX:new(gtHDDef.eXXX)	--例子
	self.m_tActivityMap[gtHDDef.eServerRechargeCB] = CRechargeCB:new(gtHDDef.eServerRechargeCB)
	self.m_tActivityMap[gtHDDef.eServerResumYBCB] = CResumeYBCB:new(gtHDDef.eServerResumYBCB)
	-- self.m_tActivityMap[gtHDDef.eTC] = CTC:new(gtHDDef.eTC) --已改成单服
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
	self.m_nSaveTick = goTimerMgr:Interval(gnAutoSaveTime, function() self:SaveData() end) 
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
function CHDMgr:Online(oRole)
	for k, v in pairs(self.m_tActivityMap) do
		v:Online(oRole)
	end
end

--取活动对象
function CHDMgr:GetActivity(nID)
	return self.m_tActivityMap[nID]
end

--取某活动的状态
function CHDMgr:GetActState(nActID, nSubActID)
	local tConf = ctHuoDongConf[nActID]
	if tConf.bSubAct then
		local oSubAct = self.m_tActivityMap[nActID]:GetAct(nSubActID)
		if not oSubAct then
			return 0
		end
		return oSubAct:GetState()
	end
	return self.m_tActivityMap[nActID]:GetState()
end

--GM后台开启活动调用
function CHDMgr:GMOpenAct(nActID, nSubActID, nStartTime, nEndTime, nAwardTime,nExtID, nExtID1)
	print("CHDMgr:GMOpenAct***", nActID, nStartTime, nEndTime)
	assert(nStartTime <= nEndTime, "时间区间非法")
	local tConf = ctHuoDongConf[nActID]
	if not tConf then
		return LuaTrace("活动配置不存在:", nActID)
	end
	if tConf.bClose then
		return LuaTrace("活动已屏蔽:", nActID, tConf.sName)
	end

	if not self.m_tActivityMap[nActID] then
		return LuaTrace("活动不存在:", nActID)
	end

	if not tConf.bCrossServer then
		return LuaTrace("非跨服活动:", nActID)
	end

	nAwardTime = ctHuoDongConf[nActID].nAwardTime
	nAwardTime = math.min(nAwardTime, ctHuoDongConf[nActID].nAwardTime)
	nExtID = math.max(1, nExtID or 1)
	nExtID1 = nExtID1 or 0

	--关闭活动
	local bCloseAct = false
	if nStartTime == nEndTime then
		bCloseAct = true
		nStartTime, nEndTime, nAwardTime = os.time(), os.time(), 0
	end

	--检测是否可以开启活动
	local nState = self:GetActState(nActID, nSubActID)
	if not bCloseAct and (nState == CHDBase.tState.eStart or nState == CHDBase.tState.eAward) then
		if (nState == CHDBase.tState.eStart and nStartTime > os.time()) or nState == CHDBase.tState.eAward then
			return LuaTrace("CHDMgr:GMOpenAct开启活动失败(活动状态会改变)", nState, ctHuoDongConf[nActID], nSubActID)
		end

	elseif bCloseAct and not (nState == CHDBase.tState.eStart or nState == CHDBase.tState.eAward) then
		return

	end

	if ctHuoDongConf[nActID].bSubAct then
		return LuaTrace("CHDMgr:GMOpenAct开启子活动失败", nState, ctHuoDongConf[nActID], nSubActID)
	end
	--开启/关闭活动
	self.m_tActivityMap[nActID]:OpenAct(nStartTime, nEndTime, nAwardTime, nExtID, nExtID1)
	return self.m_tActivityMap[nActID]:GetActTime()
end


--循环活动开启
function CHDMgr:HDCircleActOpen(tList)
	local tSuccList = {}
	for _, tData in ipairs(tList) do
		local nIndex = tData.nIndex
		local nActID = tData.nActID
		local nSubActID = tData.nSubActID
		local nExtID = tData.nExtID
		local nExtID1 = tData.nExtID1
		local nBeginTime =tData.nBeginTime
		local nEndTime = tData.nEndTime

		local nState = self:GetActState(nActID, nSubActID)
		if nState == CHDBase.tState.eStart or nState == CHDBase.tState.eAward then
			LuaTrace("CHDMgr:HDCircleActOpen开启活动失败(活动进行中)", nState, tData)
		else
			local nBeginTime1, nEndTime1, nAwardTime1 = self:GMOpenAct(nActID, nSubActID, nBeginTime, nEndTime, nil, nExtID, nExtID1)
			if nBeginTime1 and nEndTime1 and nAwardTime1 then
				table.insert(tSuccList, {nIndex=nIndex, nBeginTime=nBeginTime1, nEndTime=nEndTime1, nAwardTime=nAwardTime1})
				LuaTrace("CHDMgr:HDCircleActOpen开始活动成功", tData)
			else
				LuaTrace("CHDMgr:HDCircleActOpen开始活动失败", tData)
			end
		end
	end
	return tSuccList
end

function CHDMgr:OnPowerChange(oRole, nOldPower, nNewPower)
end

function CHDMgr:OnRechargeSuccess(oRole, nRechargeID, nMoney, nYuanBao, nBYuanBao, nTime) 
	-- local tActivityID = {gtHDDef.eTC}
	-- for _,nActivityID in pairs(tActivityID) do
	-- 	local oAct = goHDMgr:GetActivity(nActivityID)
	-- 	if oAct then
	-- 		oAct:OnRechargeSuccess(oRole, nMoney)
	-- 	end
	-- end
end

--元宝变化
function CHDMgr:OnYuanBaoChange(oRole, nYuanBao, bBind)
    print("CHDMgr:OnYuanBaoChange*******", nYuanBao, bBind) 
	local nRoleID = oRole:GetID()
	if nYuanBao > 0 then
		if not bBind then
			--全服充值冲榜
			local oAct = goHDMgr:GetActivity(gtHDDef.eServerRechargeCB)
			if oAct then
				oAct:UpdateValue(nRoleID, nYuanBao)
			end
		end
		return
	end

	if nYuanBao < 0 then
		--全服消耗元宝冲榜	
		local oAct = goHDMgr:GetActivity(gtHDDef.eServerResumYBCB)
		if oAct then
			oAct:UpdateValue(nRoleID, math.abs(nYuanBao))
		end
		return
	end
end

goHDMgr = goHDMgr or CHDMgr:new()
