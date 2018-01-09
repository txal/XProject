local _abs, _sort, _insert, _random, _floor, _max, _min, _time
= math.abs, table.sort, table.insert, math.random, math.floor, math.max, math.min, os.time

--刷怪状态
CMonsterMaker.tMakerState =
{
	eInit = 0,
	eStart = 1,
	eStop = 2,
}

function CMonsterMaker:Ctor(nSceneIndex, nBattleType, nBattleCamp, tBattleData)
	self.m_nSceneIndex = nSceneIndex
	self.m_tGroupConfList= {}
	local tSceneConf = goLuaSceneMgr:GetSceneConfByIndex(nSceneIndex)
	for _, tConf in ipairs(tSceneConf.tMonsterID) do
		local nGroupID = tConf[1]
		local tGroupConf = assert(ctMonsterDistributedConf[nGroupID])
		_insert(self.m_tGroupConfList, tGroupConf)
	end

	self.m_nCurrGroup = 0
	self.m_tGroupMonsterMap = {} --{[group]={maked=0,dead=0,[objid]=1}}
	self.m_nState = self.tMakerState.eInit
	self.m_nLoop = 0 --已循环次数

	self.m_nBattleType = nBattleType
	self.m_nBattleCamp = nBattleCamp
	self.m_tBattleData = tBattleData

	self.m_nMakerTick = nil
end

--开始刷怪
function CMonsterMaker:StartMake()
	if self.m_nState ~= self.tMakerState.eInit then
		return
	end
	if #self.m_tGroupConfList <= 0 then
		return
	end
	self.m_nState = self.tMakerState.eStart
	for nGroupID, tGroupConf in ipairs(self.m_tGroupConfList) do
		if tGroupConf.nPrepType == 0 then
			self:MakeMonster(nGroupID)
		end
	end
end

--刷怪操作
function CMonsterMaker:MakeMonster(nGroupID)
	local nSceneID = goLuaSceneMgr:GetSceneConfID(self.m_nSceneIndex)
	local tGroupConf = self.m_tGroupConfList[nGroupID]
	self.m_nCurrGroup = tGroupConf.nWaveID
	print("刷怪组", "场景:"..nSceneID.." 波:"..self.m_nCurrGroup.." 循环:"..self.m_nLoop)
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
	local nSceneID = goLuaSceneMgr:GetSceneConfID(self.m_nSceneIndex)
	print("创建怪", "场景:"..nSceneID.." 波:"..self.m_nCurrGroup.." 怪物:"..nMonsterID)
	local tGroupConf = self.m_tGroupConfList[self.m_nCurrGroup]
	local tPos = tGroupConf.tPos[1]
	local nPosX, nPosY = table.unpack(tPos)
	if nPosX == 0 and nPosY == 0 then
		local oBattleMgr = goBattleMgr:GetBattleMgr(self.m_nBattleType)
		local oRoom = oBattleMgr:GetRoom(self.m_tBattleData.nRoomID)
		local oPlayer = oRoom:GetRandomPlayer()
		if oPlayer then
			nPosX, nPosY = oPlayer:GetPos()
		end
	end
	local nRndX, nRndY = _random(0, tGroupConf.nRadius), _random(0, tGroupConf.nRadius)
	local tSceneConf = goLuaSceneMgr:GetSceneConfByIndex(self.m_nSceneIndex)
	nPosX = _max(0, _min(tSceneConf.nWidth - 1, nPosX + nRndX))
	nPosY = _max(0, _min(tSceneConf.nHeight - 1, nPosY + nRndY))
	local oMonster = goLuaMonsterMgr:CreateMonster(nMonsterID, self.m_nSceneIndex, nPosX, nPosY, self.m_nBattleType, self.m_nBattleCamp, self.m_tBattleData)
	local sObjID = oMonster:GetObjID()

	local tGroupMonster = self.m_tGroupMonsterMap[self.m_nCurrGroup] 
	if not tGroupMonster then
		tGroupMonster = {nMaked=1,nDead=0,[sObjID]=1}
		self.m_tGroupMonsterMap[self.m_nCurrGroup] = tGroupMonster
	else
		tGroupMonster.nMaked = tGroupMonster.nMaked + 1
		tGroupMonster[sObjID] = 1
	end

	if tGroupMonster.nMaked >= #tGroupConf.tMonsterID then
	--1波怪刷完,检测下1波怪
		if self.m_nCurrGroup < #self.m_tGroupConfList then
			local tNextGroupConf = self.m_tGroupConfList[self.m_nCurrGroup+1]
			if tNextGroupConf.nPrepType == 2 and tNextGroupConf.tPrepID[1][1] == self.m_nCurrGroup then
				if self.m_nMakerTick then
					GlobalExport.CancelTimer(self.m_nMakerTick)
				end
				self.m_nMakerTick = GlobalExport.RegisterTimer(tNextGroupConf.nDelayTime, function() self:MakeMonster(self.m_nCurrGroup+1) end)
			end
		end

	elseif tGroupConf.nIntervalTime > 0 then
		if self.m_nMakerTick then
			GlobalExport.CancelTimer(self.m_nMakerTick)
		end
		local nNextMonsterID = tGroupConf.tMonsterID[tGroupMonster.nMaked+1][1]
		self.m_nMakerTick = GlobalExport.RegisterTimer(tGroupConf.nIntervalTime, function() self:CreateMonster(nNextMonsterID) end)

	end
end

--停止刷怪
function CMonsterMaker:StopMake()
	self.m_nState = self.tMakerState.eStop
	if self.m_nMakerTick then
		GlobalExport.CancelTimer(self.m_nMakerTick)
		self.m_nMakerTick = nil
	end
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
function CMonsterMaker:OnMonsterDead(sObjID)
	local nGroupID, tGroupMonster
	for nTmpGroupID, tTmpGroupMonster in ipairs(self.m_tGroupMonsterMap) do
		if tTmpGroupMonster[sObjID] then
			nGroupID, tGroupMonster = nTmpGroupID, tTmpGroupMonster
			break
		end
	end
	assert(nGroupID)
	tGroupMonster[sObjID] = nil
	tGroupMonster.nDead = tGroupMonster.nDead + 1
	local tGroupConf = self.m_tGroupConfList[nGroupID]
	--1波怪死完
	if tGroupMonster.nDead >= #tGroupConf.tMonsterID then
		if self.m_nCurrGroup >= #self.m_tGroupConfList then
		--已经是最后1波
			if self:IsAllMonsterDead() then
				if tGroupConf.nLoop > self.m_nLoop then
					self.m_nState = self.tMakerState.eInit
					self.m_nLoop = self.m_nLoop + 1
					for _, tGroup in ipairs(self.m_tGroupMonsterMap) do
						tGroup.nDead, tGroup.nMaked = 0, 0
					end
					self:StartMake() --下1刷怪循环
				else
					local oBattleMgr = goBattleMgr:GetBattleMgr(self.m_nBattleType)
					local oRoom = oBattleMgr:GetRoom(self.m_tBattleData.nRoomID)
					if oRoom then
						oRoom:BattleResult(true)
					end
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
						if self.m_nMakerTick then
							GlobalExport.CancelTimer(self.m_nMakerTick)
						end
						self.m_nMakerTick = GlobalExport.RegisterTimer(tNextGroupConf.nDelayTime, function() self:MakeMonster(self.m_nCurrGroup+1) end)
					else
						self:MakeMonster(self.m_nCurrGroup+1)
					end
				end
			end
		end
	end
end

--玩家进入场景
function CMonsterMaker:AfterPlayerEnterScene()
	self:StartMake()
end

--战斗结束
function CMonsterMaker:OnBattleResult()
	self:StopMake()
end

--测试
function CMonsterMaker:KillMonsterTest()
	local oBattleMgr = goBattleMgr:GetBattleMgr(self.m_nBattleType)
	local oRoom = oBattleMgr:GetRoom(self.m_tBattleData.nRoomID)
	if not oRoom then
		return
	end
	local oPlayer = oRoom:GetRandomPlayer()
	local sCharID = oPlayer:GetCharID()

	local bOneDead = false
	for nGroupID, tGroup in ipairs(self.m_tGroupMonsterMap) do
		local tGroupConf = self.m_tGroupConfList[nGroupID]
		if tGroup.nDead < #tGroupConf.tMonsterID then
			for k, v in pairs(tGroup) do
				if k ~= "nMaked" and k ~= "nDead" then
					bOneDead = true
					OnActorDead(k, 2, sCharID, 1)
					break
				end
			end
			if bOneDead then
				break
			end
		end
	end
end
