--修炼
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--升级获得经验
local nLearnExp = 20
--升级消耗银币
local nLearnCost = 20000

--构造函数
function CPractice:Ctor(oRole)
	self.m_oRole = oRole
	self.m_tPracticeMap = {} 	--修炼映射{[id]={level=0,exp=0},...}
	self.m_nDefault = 0 		--默认修炼技能
	self.m_nUsedProps = 0 		--使用道具数量
	self.m_nResetTime = 0 		--重置时间
	self:Init()
end

function CPractice:Init()
	if self.m_nDefault == 0 then
		self.m_nDefault = 101
	end
	for nID, tConf in pairs(ctPracticeConf) do
		self.m_tPracticeMap[nID] = {nLevel=0, nExp=0}
	end
end

function CPractice:LoadData(tData)
	if not tData then
		return
	end
	self.m_tPracticeMap = {}
	for nID, tPra in pairs(tData.m_tPracticeMap) do
		if ctPracticeConf[nID] then
			self.m_tPracticeMap[nID] = tPra
		end
	end
	self.m_nDefault = tData.m_nDefault
	self.m_nUsedProps = tData.m_nUsedProps
	self.m_nResetTime = tData.m_nResetTime
end

function CPractice:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)
	
	local tData = {}
	tData.m_tPracticeMap = self.m_tPracticeMap
	tData.m_nDefault = self.m_nDefault
	tData.m_nUsedProps = self.m_nUsedProps
	tData.m_nResetTime = self.m_nResetTime
	return tData
end

function CPractice:GetType()
	return gtModuleDef.tPractice.nID, gtModuleDef.tPractice.sName
end

--上线
function CPractice:Online()
	self:SyncInfo()
end

--银币发生变化
function CPractice:OnYinBiChange()
	self:SyncInfo()
end

--角色等级变化
function CPractice:OnRoleLevelChange(nOldLevel, nNewLevel)
	if self:MaxLevel(nOldLevel) ~= self:MaxLevel(nNewLevel) then
		self:SyncInfo()
	end
end

--道具进背包事件
function CPractice:OnAddItem(nPropID)
	local tPropConf = ctPropConf[nPropID]
	if not tPropConf then
		return
	end
	if tPropConf.nType ~= gtPropType.ePraMed then
		return
	end
	self:SyncInfo()
end

--修炼上限
function CPractice:MaxLevel(nLevel)
	local nLevel = nLevel or self.m_oRole:GetLevel()
	local nMaxLevel = math.floor(nLevel/math.max(10-nLevel/20, 5))
	return math.max(4, math.min(35, nMaxLevel))
end

--取经验加成(百分比)
function CPractice:CalcExpAdd(nID, nExp)
	local tPractice = self.m_tPracticeMap[nID]
	if tPractice.nLevel <= self:MaxLevel()-5 then
		return math.floor(nExp*1.3)
	end
	return nExp
end

--检测使用道具重置
function CPractice:CheckReset()
	if not os.IsSameDay(self.m_nResetTime, os.time(), 0) then
		self.m_nUsedProps = 0
		self.m_nResetTime = os.time()
		self:MarkDirty(true)
	end
end

--剩余可使用道具数
function CPractice:RemainProps()
	self:CheckReset()
	-- local nLevel = self.m_oRole:GetLevel()
	-- local nServerLv = goServerMgr:GetServerLevel(self.m_oRole:GetServer())
	-- local nMaxProps = nLevel <= nServerLv-10 and 20 or 10
	local nMaxProps = 999 --策划说没有次数限制了 单子:3290
	return math.max(0, nMaxProps-self.m_nUsedProps)
end

function CPractice:CheckSysOpen(bTips)
	if not self.m_oRole.m_oSysOpen:IsSysOpen(1, bTips) then
		-- if bTips then
		-- 	self.m_oRole:Tips("修炼系统未开启")
		-- end
		return
	end
	return true
end

function CPractice:SyncInfo(nID)
	if not self:CheckSysOpen() then
		return
	end
	
	nID = nID or 0
	local tMsg = {}
	tMsg.tList = {}
	tMsg.nSilver = self.m_oRole:GetYinBi()
	tMsg.nDefault = self.m_nDefault
	tMsg.nMaxLevel = self:MaxLevel()
	tMsg.nRemainProps = self:RemainProps()

	local function _PraInfo(nID, tPractice)
		local tConf = ctPracticeConf[nID]
		local nNextExp = tConf.fnNeedExp(tPractice.nLevel+1)
		local tInfo = {
			nID=nID,
			nLevel=tPractice.nLevel,
			nExp=tPractice.nExp,
			nNextExp=nNextExp,
			nCostSilver=nLearnCost,
			bCanLearn=self:CanLearn(nID, 1),
			bCanUseProp=self:CanUseProp(nID),
		}
		return tInfo
	end

	if nID > 0 then
		local tPractice = self.m_tPracticeMap[nID]
		table.insert(tMsg.tList, _PraInfo(nID, tPractice))
	else
		for nID, tPractice in pairs(self.m_tPracticeMap) do
			table.insert(tMsg.tList, _PraInfo(nID, tPractice))
		end
	end
	self.m_oRole:SendMsg("PracticeInfoRet", tMsg)
end

--修炼信息请求
function CPractice:InfoReq(nID)
	if not self:CheckSysOpen(true) then
		return
	end
	self:SyncInfo(nID)
end

--升级需要经验
function CPractice:NeedExp(nID)
	local tPractice = self.m_tPracticeMap[nID]
	local tConf = ctPracticeConf[nID]
	local nNextExp = tConf.fnNeedExp(tPractice.nLevel+1)
	return nNextExp
end

--角色AddItem调用
function CPractice:AddItem(nExp)
	assert(nExp >= 0)
	if nExp == 0 then
		return
	end
	if not self:CheckSysOpen() then
		return
	end

	local tPractice = self.m_tPracticeMap[self.m_nDefault]
	if not tPractice then
		return self.m_oRole:Tips("请先设置默认修炼技能")
	end

	local nAddExp, nOldLevel, nNewLevel = self:AddExp(self.m_nDefault, nExp, true)
	self:CheckTask(nOldLevel, nNewLevel)
	self:CheckAchieve(nOldLevel, nNewLevel)
	return nAddExp
end

--添加经验
--@bTips =true默认修炼
function CPractice:AddExp(nID, nExp, bDefault)
	local tPractice = self.m_tPracticeMap[nID]
	local nExp = self:CalcExpAdd(nID, nExp)
	tPractice.nExp = tPractice.nExp + nExp
	self:MarkDirty(true)

	if tPractice.nLevel >= self:MaxLevel() then
		if bDefault then
			self.m_oRole:Tips("默认技能已达上限。（获得修炼经验但无法提升技能等级）")
		end
		return nExp, tPractice.nLevel, tPractice.nLevel
	end

	--检测升级
	local nOldLevel = tPractice.nLevel 
	local tConf = ctPracticeConf[nID]
	for k = tPractice.nLevel+1, self:MaxLevel() do
		local nNextExp = tConf.fnNeedExp(k)
		if tPractice.nExp >= nNextExp then
			tPractice.nExp = tPractice.nExp - nNextExp
			tPractice.nLevel = tPractice.nLevel + 1
		end
	end

	return nExp, nOldLevel, tPractice.nLevel
end

--检测任务
function CPractice:CheckTask(nOldLevel, nNewLevel)
	if nOldLevel ~= nNewLevel then
		local tData = {}
		for k = nOldLevel+1, nNewLevel do
			table.insert(tData, {nLevel=k})
		end
		CEventHandler:OnPracticeLevelChange(self.m_oRole, tData)
		self.m_oRole:UpdateActGTPricticeLv()
	end
end

--检测成就
function CPractice:CheckAchieve(nOldLevel, nNewLevel)
	if nOldLevel ~= nNewLevel then
		self.m_oRole:UpdatePower()
		self.m_oRole:PushAchieve("修炼总等级",{nValue = nNewLevel-nOldLevel})
	end
end

--是否可以学习
function CPractice:CanLearn(nID, nTimes, bTips)
	if not self:CheckSysOpen(bTips) then
		return
	end

	local tPractice = self.m_tPracticeMap[nID]
	if not tPractice then
		return false
	end
	local tPracticeConf = ctPracticeConf[nID]
	if tPractice.nLevel >= self:MaxLevel() and tPractice.nExp >= self:NeedExp(nID)*2 then
		if bTips then
			self.m_oRole:Tips(string.format("%s已达到经验上限，无法学习", tPracticeConf.sName))
		end
		return false
	end
	local nCostSilver = nTimes*nLearnCost
	if self.m_oRole:ItemCount(gtItemType.eCurr, gtCurrType.eYinBi) < nCostSilver then
		if bTips then
			return self.m_oRole:YinBiTips()
		end
		return false
	end
	return true
end

--学习请求
function CPractice:LearnReq(nID, nTimes)
	assert(nTimes > 0 and nTimes <= 100, "次数错误")
	if not self:CanLearn(nID, nTimes, true) then
		return
	end
	local nCostSilver = nTimes*nLearnCost
	self.m_oRole:SubItem(gtItemType.eCurr, gtCurrType.eYinBi, nCostSilver, "修炼学习:"..nTimes)
	local nAddExp, nOldLevel, nNewLevel = self:AddExp(nID, nTimes*nLearnExp, false)

	self:InfoReq(nID)
	self:CheckTask(nOldLevel, nNewLevel)
	self:CheckAchieve(nOldLevel, nNewLevel)
end

--是否可以使用道具
function CPractice:CanUseProp(nID, bTips)
	if not self:CheckSysOpen(bTips) then
		return false
	end

	local tPractice = self.m_tPracticeMap[nID]
	if not tPractice then
		if bTips then
			self.m_oRole:Tips("修炼技能不存在:"..nID)
		end
		return false
	end

	local tPracticeConf = ctPracticeConf[nID]
	if tPractice.nLevel >= self:MaxLevel() and tPractice.nExp >= self:NeedExp(nID)*2 then
		if bTips then
			self.m_oRole:Tips(string.format("%s已达经验上限，无法使用", tPracticeConf.sName))
		end
		return false
	end
	if self:RemainProps() <= 0 then
		if bTips then
			self.m_oRole:Tips(string.format("你今天已使用%d个修炼丹，无法继续使用", self.m_nUsedProps))
		end
		return false
	end
	return true
end

--使用道具请求
--@nID nil表示默认修炼
function CPractice:UsePropReq(nID, nPropID, nUseNum)
	if not self:CheckSysOpen(true) then
		return
	end

	nUseNum = math.max(1, nUseNum)
	local tPropConf = ctPropConf[nPropID]
	if tPropConf.nType ~= gtPropType.ePraMed then
		return self.m_oRole:Tips("非修炼丹药道具:"..nPropID)
	end

	nID = nID or self.m_nDefault
	if not self:CanUseProp(nID, true) then
		return 
	end

	nUseNum = self:RemainProps() <= nUseNum and self:RemainProps() or nUseNum
	if self.m_oRole:ItemCount(gtItemType.eProp, nPropID) < nUseNum then
		return self.m_oRole:Tips("道具数量不足")
	end

	local nAddExp, nCostNum, nOldLevel, nNewLevel = self:HandleCost(nID, nUseNum, nPropID)
	self.m_nUsedProps = self.m_nUsedProps + nCostNum
	self:MarkDirty(true)

	self:InfoReq(nID)
	self:CheckTask(nOldLevel, nNewLevel)
	self:CheckAchieve(nOldLevel, nNewLevel)

	--飘字
	if nAddExp > 0 then
		local tPracticeConf = ctPracticeConf[nID]
		self.m_oRole:Tips(string.format("获得%d点%s修炼经验", nAddExp, tPracticeConf.sName))
	end
end

--计算消耗的数量
function CPractice:HandleCost(nID, nUseNum, nPropID)
	local tPropConf = ctPropConf[nPropID]
	local tPractice = self.m_tPracticeMap[nID]
	local nOldLevel = tPractice.nLevel

	local nSumExp = 0
	local nCostNum = 0
	for i = 1, nUseNum, 1 do
		nSumExp = nSumExp + self:AddExp(nID, tPropConf.eParam(), false)
		nCostNum = nCostNum + 1
		if tPractice.nExp >= self:NeedExp(nID)*2 then
			break
		end
	end
	self.m_oRole:SubItem(gtItemType.eProp, nPropID, nCostNum, "使用修炼道具")
	return nSumExp, nCostNum, nOldLevel, tPractice.nLevel
end

--设置默认修炼
function CPractice:SetDefaultReq(nID)
	self.m_nDefault = nID
	self:MarkDirty(true)
	self:InfoReq(nID)
	self:PracticeChange()
end

--取当前修炼技能ID
function CPractice:GetDefauID()
	return self.m_nDefault
end

--取单个技能信息
function CPractice:GetSkillInfo(nID)
	return self.m_tPracticeMap[nID]
end

--取修炼列表,战斗中用
function CPractice:GetPracticeMap()
	local tPracticeMap = {}
	for nID, tPractice in pairs(self.m_tPracticeMap) do
		tPracticeMap[nID] = tPractice.nLevel
	end
	return tPracticeMap
end
--修炼评分
function CPractice:CalcPracticeScore()
	local nScore = 0
	local tAtkPra = {101,201,301} --攻修
	local tDefPra = {102,103,202,203,302} --抗修
	for nID, tPractice in pairs(self.m_tPracticeMap) do
		if table.InArray(nID, tAtkPra) then
			nScore = nScore + (tPractice.nLevel * 1000)
		else
			nScore = nScore + (tPractice.nLevel * 500)
		end
	end
	return nScore
end

--默认修炼变化
function CPractice:PracticeChange()
	self.m_oRole.m_oBaHuangHuoZhen:PracticeChange()
end

function CPractice:GetLvSum()
	local nSum = 0
	for k, tData in pairs(self.m_tPracticeMap) do 
		nSum = nSum + tData.nLevel
	end
	return nSum
end