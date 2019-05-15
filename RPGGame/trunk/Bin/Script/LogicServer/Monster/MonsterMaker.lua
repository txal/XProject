--刷怪模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--刷怪状态
local tMState = 
{
	eInit = 0,
	eStart = 1,
	eStop = 2,
}

--预处理表
local _ctMonsterDistributeConf = {}
local function _PreProcessConf()
	for _, tConf in pairs(ctMonsterDistributeConf) do
		if not _ctMonsterDistributeConf[tConf.nDupID] then
			_ctMonsterDistributeConf[tConf.nDupID] = {}
		end
		_ctMonsterDistributeConf[tConf.nDupID][tConf.nWaveID] = tConf
		if tConf.nPrepType == 0 then
			assert(tConf.nDelayTime == 0, "怪物分布表nDelayTime错误")
		end
	end
	for nDupID, tConfList in pairs(_ctMonsterDistributeConf) do
		local nCount = 0
		for k, v in pairs(tConfList) do
			nCount = nCount + 1
		end
		assert(nCount == #tConfList, "副本"..nDupID.."nWaveID不连续")
	end
end
_PreProcessConf()

function CMonsterMaker:Ctor(nDupMixID)
	self.m_tGroupConfList= {}
	self.m_nDupMixID = nDupMixID
    local nDupID = GF.GetDupID(nDupMixID)
    local tDupConf = assert(ctDupConf[nDupID], "副本不存在")
	self.m_tGroupConfList = _ctMonsterDistributeConf[tDupConf.nID] or {}

	self.m_nCurrGroup = 0
	self.m_tGroupMonsterMap = {} --{[group]={maked=0,dead=0,[objid]=1}}
	self.m_nState = tMState.eInit
	self.m_nLoop = 0 --已循环次数

	self.m_nMakerTick = nil
end

--开始刷怪
function CMonsterMaker:StartMake()
	if self.m_nState ~= tMState.eInit then
		return
	end
	if #self.m_tGroupConfList <= 0 then
		return
	end
	self.m_nState = tMState.eStart
	for nGroupID, tGroupConf in ipairs(self.m_tGroupConfList) do
		if tGroupConf.nPrepType == 0 then
			self:MakeMonster(nGroupID)
		end
	end
end

--刷怪操作
function CMonsterMaker:MakeMonster(nGroupID)
    local nDupID = GF.GetDupID(self.m_nDupMixID)
	local tGroupConf = self.m_tGroupConfList[nGroupID]
	self.m_nCurrGroup = tGroupConf.nWaveID
	print("刷怪组", "副本:"..nDupID.." 波:"..self.m_nCurrGroup.." 循环:"..self.m_nLoop)
	assert(#tGroupConf.tMonsterID > 0)

	if tGroupConf.nIntervalTime > 0 then
		self:CreateMonster(tGroupConf.tMonsterID[1][1])
	else
		for _, tMonsterID in ipairs(tGroupConf.tMonsterID) do
			self:CreateMonster(tMonsterID[1])
		end
	end
end

--创建怪物
function CMonsterMaker:CreateMonster(nMonsterID)
    local nDupID = GF.GetDupID(self.m_nDupMixID)
	print("创建怪", "副本:"..nDupID.." 波:"..self.m_nCurrGroup.." 怪物:"..nMonsterID)
	local tGroupConf = self.m_tGroupConfList[self.m_nCurrGroup]

	--以中心点刷怪
	local nRnd = math.random(#tGroupConf.tPos)
	local nPosX, nPosY = table.unpack(tGroupConf.tPos[nRnd])
	local nOffsetX = math.random(-tGroupConf.nRadius, tGroupConf.nRadius)
	local nOffsetY = math.random(-tGroupConf.nRadius, tGroupConf.nRadius)
	nPosX, nPosY = nPosX+nOffsetX, nPosY+nOffsetY

	local tDupConf = ctDupConf[nDupID]
	local tMapConf = ctMapConf[tDupConf.nMapID]
	nPosX = math.max(0, math.min(tMapConf.nWidth - 1, nPosX))
	nPosY = math.max(0, math.min(tMapConf.nHeight - 1, nPosY))

	local oMonster = goMonsterMgr:CreateMonster(nMonsterID, self.m_nDupMixID, nPosX, nPosY)
	local nObjID = oMonster:GetID()

	local tGroupMonster = self.m_tGroupMonsterMap[self.m_nCurrGroup] 
	if not tGroupMonster then
		tGroupMonster = {nMaked=1,nDead=0,[nObjID]=1}
		self.m_tGroupMonsterMap[self.m_nCurrGroup] = tGroupMonster
	else
		tGroupMonster.nMaked = tGroupMonster.nMaked + 1
		tGroupMonster[nObjID] = 1
	end

	if tGroupMonster.nMaked >= #tGroupConf.tMonsterID then
	--1波怪刷完,检测下1波怪
		if self.m_nCurrGroup < #self.m_tGroupConfList then
			local tNextGroupConf = self.m_tGroupConfList[self.m_nCurrGroup+1]
			if tNextGroupConf.nPrepType == 2 and tNextGroupConf.tPrepID[1][1] == self.m_nCurrGroup then
				goTimerMgr:Clear(self.m_nMakerTick)
				self.m_nMakerTick = goTimerMgr:Interval(tNextGroupConf.nDelayTime*0.001, function() self:MakeMonster(self.m_nCurrGroup+1) end)
			end
		end

	elseif tGroupConf.nIntervalTime > 0 then
		goTimerMgr:Clear(self.m_nMakerTick)
		local nNextMonsterID = tGroupConf.tMonsterID[tGroupMonster.nMaked+1][1]
		self.m_nMakerTick = goTimerMgr:Interval(tGroupConf.nIntervalTime*0.001, function() self:CreateMonster(nNextMonsterID) end)

	end
end

--停止刷怪
function CMonsterMaker:StopMake()
	self.m_nState = tMState.eStop
	goTimerMgr:Clear(self.m_nMakerTick)
end

--是否当前所有怪已死完
function CMonsterMaker:IsAllMonsterDead()
	for nGroup, tGroup in ipairs(self.m_tGroupMonsterMap) do
		local tGroupConf = self.m_tGroupConfList[nGroup]
		if tGroup.nDead < #tGroupConf.tMonsterID then
			return
		end
	end
	return true
end

--怪物死亡
function CMonsterMaker:OnMonsterDead(nObjID)
	local nGroupID, tGroupMonster
	for nTmpGroupID, tTmpGroupMonster in ipairs(self.m_tGroupMonsterMap) do
		if tTmpGroupMonster[nObjID] then
			nGroupID, tGroupMonster = nTmpGroupID, tTmpGroupMonster
			break
		end
	end
	if not nGroupID then
		return
	end
	tGroupMonster[nObjID] = nil
	tGroupMonster.nDead = tGroupMonster.nDead + 1
	local tGroupConf = self.m_tGroupConfList[nGroupID]
	--1波怪死完
	if tGroupMonster.nDead >= #tGroupConf.tMonsterID then
		if self.m_nCurrGroup >= #self.m_tGroupConfList then
		--已经是最后1波
			if self:IsAllMonsterDead() then
				if tGroupConf.nLoop > self.m_nLoop then
					self.m_nState = tMState.eInit
					self.m_nLoop = self.m_nLoop + 1
					for _, tGroup in ipairs(self.m_tGroupMonsterMap) do
						tGroup.nDead, tGroup.nMaked = 0, 0
					end
					self:StartMake() --下1刷怪循环
				else
					--所有怪物已刷完
					self:StopMake()
				end
			end
		else
			local tNextGroupConf = self.m_tGroupConfList[self.m_nCurrGroup+1]
			if tNextGroupConf.nPrepType == 1 then
				local tPrepID = tNextGroupConf.tPrepID
				local bPrepCond = true
				for _, v in ipairs(tPrepID) do
					local nGroupID = v[1]
					local tGroupMonster = self.m_tGroupMonsterMap[nGroupID]
					local tGroupConf = self.m_tGroupConfList[nGroupID]
					if not tGroupMonster or not tGroupConf or tGroupMonster.nDead < #tGroupConf.tMonsterID then
						bPrepCond = false
						break
					end
				end
				if bPrepCond then
					if tNextGroupConf.nDelayTime > 0 then
						goTimerMgr:Clear(self.m_nMakerTick)
						self.m_nMakerTick = goTimerMgr:Interval(tNextGroupConf.nDelayTime*0.001, function() self:MakeMonster(self.m_nCurrGroup+1) end)
					else
						self:MakeMonster(self.m_nCurrGroup+1)
					end
				end
			end
		end
	end
end
