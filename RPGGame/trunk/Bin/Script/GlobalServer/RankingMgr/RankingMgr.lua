--排行榜管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CRankingMgr:Ctor()

	self.m_nSaveTick = nil
	self.m_tRankingMap = {}
	self:Init()
end

function CRankingMgr:Init()
	for nID, cClass in pairs(gtRankingClassDef) do
		self.m_tRankingMap[nID] = cClass:new(nID)
	end
end

--加载数据
function CRankingMgr:LoadData()
	for _, oRanking in pairs(self.m_tRankingMap) do
		oRanking:LoadData()
	end
	self:AutoSave()
end

function CRankingMgr:AutoSave()
	self.m_nSaveTick = goTimerMgr:Interval(gnAutoSaveTime, function() self:SaveData() end)
	local nCheckTime = os.NextDayTime(os.time(),0,0,0)
	self.m_nCheckTick = goTimerMgr:Interval(nCheckTime,function ()	self:NewDay() end)
end

--保存数据
function CRankingMgr:SaveData()
	for _, oRanking in pairs(self.m_tRankingMap) do
		oRanking:SaveData()
	end
end

--释放
function CRankingMgr:OnRelease()
	goTimerMgr:Clear(self.m_nSaveTick)
	self.m_nSaveTick = nil
	goTimerMgr:Clear(self.m_nCheckTick)
	self.m_nCheckTick = nil

	for _,oRanking in pairs(self.m_tRankingMap) do
		oRanking:OnRelease()
	end
	
end

--取排行榜
function CRankingMgr:GetRanking(nID)
	return self.m_tRankingMap[nID]
end

--GM重置排行榜
function CRankingMgr:GMResetRanking()
	for _, oRanking in pairs(self.m_tRankingMap) do
		if oRanking.ResetRanking then
			oRanking:ResetRanking()
		end
	end
end

--角色上线
function CRankingMgr:Online(oRole)
	for _, oRanking in pairs(self.m_tRankingMap) do
		if oRanking.Online then
			oRanking:Online(oRole)
		end
	end
end

function CRankingMgr:NewDay()
	goTimerMgr:Clear(self.m_nCheckTick)
	self.m_nCheckTick = nil

	local nCheckTime = os.NextDayTime(os.time(),0,0,0)
	self.m_nCheckTick = goTimerMgr:Interval(nCheckTime,function ()	self:NewDay() end)

	for _,oRanking in pairs(self.m_tRankingMap) do
		oRanking:NewDay()
	end
end

--角色战力变化
function CRankingMgr:OnPowerChange(oRole, nPower)
	if oRole:IsRobot() then return end
	local oRanking = self:GetRanking(gtRankingDef.eRolePowerRanking)
	oRanking:Update(oRole:GetID(), nPower)
end

--综合战力变化
function CRankingMgr:OnColligatePowerChange(oRole, nColligatePower)
	if not oRole or oRole:IsRobot() then 
		return 
	end
	local oRanking = goRankingMgr:GetRanking(gtRankingDef.eColligatePowerRanking)
	oRanking:Update(oRole:GetID(), nColligatePower)
end

--角色等级变化
function CRankingMgr:OnLevelChange(oRole, nLevel)
	if oRole:IsRobot() then return end
	local oRanking = self:GetRanking(gtRankingDef.eRoleLevelRanking)
	oRanking:Update(oRole:GetID(), nLevel)
end

--帮派解散
function CRankingMgr:OnUnionDismiss(nUnionID)
	local oRanking = self:GetRanking(gtRankingDef.eUnionLevelRanking)
	oRanking:RemoveKey(nUnionID)
end

--帮派创建
function CRankingMgr:OnUnionCreate(nUnionID)
	local oRanking = self:GetRanking(gtRankingDef.eUnionLevelRanking)
	oRanking:Update(nUnionID, 1)
end


goRankingMgr = goRankingMgr or CRankingMgr:new()
