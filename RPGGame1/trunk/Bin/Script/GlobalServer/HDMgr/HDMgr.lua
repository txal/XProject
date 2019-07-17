--活动管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CHDMgr:Ctor()
	self.m_nSaveTick = nil 		--保存计时器
	self.m_nMinTick = nil 		--分钟计时器
	self.m_tActivityMap = {} 	--活动映射
	self:Init()
end
 
function CHDMgr:Init()
	self.m_tActivityMap[gtHDDef.ePowerCB] = CPowerCB:new(gtHDDef.ePowerCB)
	self.m_tActivityMap[gtHDDef.eArenaCB] = CArenaCB:new(gtHDDef.eArenaCB)
	self.m_tActivityMap[gtHDDef.eHoneyCB] = CHoneyCB:new(gtHDDef.eHoneyCB)
	self.m_tActivityMap[gtHDDef.eUnionExpCB] = CUnionExpCB:new(gtHDDef.eUnionExpCB)
	self.m_tActivityMap[gtHDDef.ePopularityCB] = CPopularityCB:new(gtHDDef.ePopularityCB)
	self.m_tActivityMap[gtHDDef.eSmallGameCB] = CSmallGameCB:new(gtHDDef.eSmallGameCB)
	self.m_tActivityMap[gtHDDef.eRechargeCB] = CRechargeCB:new(gtHDDef.eRechargeCB)
	self.m_tActivityMap[gtHDDef.eResumeYBCB] = CResumeYBCB:new(gtHDDef.eResumeYBCB)

	self.m_tActivityMap[gtHDDef.eHSXS] = CHSXS:new(gtHDDef.eHSXS)
	self.m_tActivityMap[gtHDDef.eTDBK] = CTDBK:new(gtHDDef.eTDBK)
	self.m_tActivityMap[gtHDDef.eMHDJ] = CMHDJ:new(gtHDDef.eMHDJ)
	self.m_tActivityMap[gtHDDef.eHDQF] = CHDQF:new(gtHDDef.eHDQF)
	self.m_tActivityMap[gtHDDef.eZXJZ] = CZXJZ:new(gtHDDef.eZXJZ)
	self.m_tActivityMap[gtHDDef.eDHLN] = CDHLN:new(gtHDDef.eDHLN)

	self.m_tActivityMap[gtHDDef.eLD] = CLD:new(gtHDDef.eLD)
	self.m_tActivityMap[gtHDDef.eLC] = CLC:new(gtHDDef.eLC)
	self.m_tActivityMap[gtHDDef.eTimeAward] = CTimeAward:new(gtHDDef.eTimeAward)
	self.m_tActivityMap[gtHDDef.eSC] = CSC:new(gtHDDef.eSC)
	self.m_tActivityMap[gtHDDef.eDC] = CDC:new(gtHDDef.eDC)
	self.m_tActivityMap[gtHDDef.eLY] = CLY:new(gtHDDef.eLY)
	self.m_tActivityMap[gtHDDef.eZeroYuan] = CZeroYuan:new(gtHDDef.eZeroYuan)
	self.m_tActivityMap[gtHDDef.eMarriage] = CMarriageAct:new(gtHDDef.eMarriage)
	
	self.m_tActivityMap[gtHDDef.eGTEquStrength] = CGrowthTargetBase:new(gtHDDef.eGTEquStrength)
	self.m_tActivityMap[gtHDDef.eGTPetPower] = CGrowthTargetBase:new(gtHDDef.eGTPetPower)
	self.m_tActivityMap[gtHDDef.eGTPartnerPower] = CGrowthTargetBase:new(gtHDDef.eGTPartnerPower)
	self.m_tActivityMap[gtHDDef.eGTFormationLv] = CGrowthTargetBase:new(gtHDDef.eGTFormationLv)
	self.m_tActivityMap[gtHDDef.eGTEquGemLv] = CGrowthTargetBase:new(gtHDDef.eGTEquGemLv)
	self.m_tActivityMap[gtHDDef.eGTMagicEquPower] = CGrowthTargetBase:new(gtHDDef.eGTMagicEquPower)
	self.m_tActivityMap[gtHDDef.eGTDrawSpiritLv] = CGrowthTargetBase:new(gtHDDef.eGTDrawSpiritLv)
	self.m_tActivityMap[gtHDDef.eGTPetSkillPower] = CGrowthTargetBase:new(gtHDDef.eGTPetSkillPower)
	self.m_tActivityMap[gtHDDef.eGTPricticeLv] = CGrowthTargetBase:new(gtHDDef.eGTPricticeLv)
	self.m_tActivityMap[gtHDDef.eGTGodEquPower] = CGrowthTargetBase:new(gtHDDef.eGTGodEquPower)
	self.m_tActivityMap[gtHDDef.eGTTreasureSearchScore] = CGrowthTargetBase:new(gtHDDef.eGTTreasureSearchScore)
	self.m_tActivityMap[gtHDDef.eGTArenaScore] = CGrowthTargetBase:new(gtHDDef.eGTArenaScore)
	self.m_tActivityMap[gtHDDef.eGTPersonUnionContri] = CGrowthTargetBase:new(gtHDDef.eGTPersonUnionContri)
	self.m_tActivityMap[gtHDDef.eGTDrawSpiritScore] = CGrowthTargetBase:new(gtHDDef.eGTDrawSpiritScore)
	self.m_tActivityMap[gtHDDef.eGTDressPower] = CGrowthTargetBase:new(gtHDDef.eGTDressPower)
	self.m_tActivityMap[gtHDDef.eTC] = CTC:new(gtHDDef.eTC)
	--self.m_tActivityMap[gtHDDef.eFB] = CFB:new(gtHDDef.eFB) --已屏蔽(单子5010)
end

--加载数据
function CHDMgr:LoadData()
	print("加载活动数据------")
	for k, oAct in pairs(self.m_tActivityMap) do
		oAct:LoadData()
	end

	self:StartTick()
	self:OnMinEvent()
end

--注册定时保存
function CHDMgr:StartTick()
	local nNextMinTime = os.NextMinTime(os.time())
	self.m_nMinTick = GetGModule("TimerMgr"):Interval(nNextMinTime, function() self:OnMinEvent() end)
	self.m_nSaveTick = GetGModule("TimerMgr"):Interval(gtGDef.tConst.nAutoSaveTime, function() self:SaveData() end)
end

--保存数据
function CHDMgr:SaveData()
	for k, oAct in pairs(self.m_tActivityMap) do
		oAct:SaveData()
	end
end

--释放处理
function CHDMgr:Release()
	GetGModule("TimerMgr"):Clear(self.m_nSaveTick)
	self.m_nSaveTick = nil
	GetGModule("TimerMgr"):Clear(self.m_nMinTick)
	self.m_nMinTick = nil
	
	for k, oAct in pairs(self.m_tActivityMap) do
		oAct:Release()
	end
end

--分钟计时器
function CHDMgr:OnMinEvent()
	GetGModule("TimerMgr"):Clear(self.m_nMinTick)
	local nNextMinTime = os.NextMinTime(os.time())
	self.m_nMinTick = GetGModule("TimerMgr"):Interval(nNextMinTime, function() self:OnMinEvent() end)

	--更新状态
	for nID, oAct in pairs(self.m_tActivityMap) do
		--为啥要用xpcall呢，因为要防止一个活动出错影响到其他活动的更新
	    xpcall(function() oAct:UpdateState() end, function(sErr) LuaTrace(sErr, debug.traceback()) end)
	end
end

--玩家上线
function CHDMgr:Online(oRole)
	for k, oAct in pairs(self.m_tActivityMap) do
		oAct:Online(oRole)
	end
end

--取活动对象
function CHDMgr:GetActivity(nID)
	return self.m_tActivityMap[nID]
end

--取某活动的状态
function CHDMgr:GetActState(nActID, nSubActID)
	local tConf = ctHuoDongConf[nActID]
	local oAct = self.m_tActivityMap[nActID]
	if not oAct then
		return 0
	end
	if tConf.bSubAct then
		local oSubAct = oAct:GetAct(nSubActID)
		if not oSubAct then
			return 0
		end
		return oSubAct:GetState()
	end
	return oAct:GetState()
end

--GM后台开启活动调用 nExtID:轮次/其他， nExtID1:替换的物品ID
function CHDMgr:GMOpenAct(nActID, nSubActID, nStartTime, nEndTime, nAwardTime, nExtID, nExtID1)
	print("CHDMgr:GMOpenAct***", nActID, nStartTime, nEndTime)
	assert(nStartTime <= nEndTime, "时间区间非法")
	local tConf = ctHuoDongConf[nActID]
	if not tConf then
		return LuaTrace("活动不存在:", nActID)
	end
	if tConf.bClose then
		return LuaTrace("活动已屏蔽:", nActID, tConf.sName)
	end

	if tConf.bCrossServer then
		Network.oRemoteCall:Call("GMOpenAct", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0
			, nActID, nSubActID, nStartTime, nEndTime, nAwardTime, nExtID, nExtID1)
		return
	end

	if not self.m_tActivityMap[nActID] then
		return LuaTrace("活动:", nActID, "未实现")
	end
	nAwardTime = ctHuoDongConf[nActID].nAwardTime
	nAwardTime = math.min(nAwardTime, ctHuoDongConf[nActID].nAwardTime)
	nExtID = math.max(1, nExtID or 1)
	nExtID1 = nExtID1 or 0


	--关闭活动
	local bCloseAct = false
	if nStartTime == nEndTime then
		nStartTime, nEndTime, nAwardTime = os.time(), os.time(), 0
		bCloseAct = true
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

	--开启/关闭子活动
	if ctHuoDongConf[nActID].bSubAct then
		local oSubAct = self.m_tActivityMap[nActID]:OpenAct(nSubActID, nStartTime, nEndTime, nAwardTime, nExtID, nExtID1)
		if oSubAct then
			return oSubAct:GetActTime()
		end
		return LuaTrace("子活动不存在", nActID, nSubActID)
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
		local nBeginTime = tData.nBeginTime
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

--战力变化
function CHDMgr:OnPowerChange(oRole, nOldPower, nNewPower)
	local oAct = self:GetActivity(gtHDDef.ePowerCB)
	oAct:UpdateValue(oRole:GetID(), nNewPower-nOldPower)
end

function CHDMgr:OnRechargeSuccess(oRole, nRechargeID, nMoney, nYuanBao, nBYuanBao, nTime) 
	local tGrowthTargetActList = goGrowthTargetMgr:GetActList()
	for _, nActID in ipairs(tGrowthTargetActList) do 
		local oAct = self:GetActivity(nActID)
		if oAct and oAct:IsOpen() then 
			oAct:AddRechargeVal(oRole:GetID(), nMoney)
		end
	end

	--充值相关活动
	local tActivityID = {gtHDDef.eLC, gtHDDef.eSC, gtHDDef.eDC, gtHDDef.eTC}
	for _,nActivityID in pairs(tActivityID) do
		local oAct = goHDMgr:GetActivity(nActivityID)
		if oAct then
			oAct:OnRechargeSuccess(oRole, nMoney)
		end
	end
end

--元宝变化
function CHDMgr:OnYuanBaoChange(oRole, nYuanBao, bBind)
    print("CHDMgr:OnYuanBaoChange*******", nYuanBao, bBind) 
	local nRoleID = oRole:GetID()
	if nYuanBao > 0 then
		if not bBind then
			--充值冲榜
			local oAct = goHDMgr:GetActivity(gtHDDef.eRechargeCB)
			if oAct then
				oAct:UpdateValue(nRoleID, nYuanBao)
			end
		end
		return
	end

	if nYuanBao < 0 then
		--消耗元宝冲榜
		local oAct = goHDMgr:GetActivity(gtHDDef.eResumeYBCB)
		if oAct then
			oAct:UpdateValue(nRoleID, math.abs(nYuanBao))
		end

		--累积消耗元宝
		local oAct = goHDMgr:GetActivity(gtHDDef.eLY)
		if oAct then
			oAct:OnYYResumeYuanBao(oRole, math.abs(nYuanBao))
		end
		return
	end
end
