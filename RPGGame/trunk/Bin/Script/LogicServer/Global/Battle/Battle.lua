--战斗模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--战斗状态
CBattle.tBTS = 
{
	eNN = 0,	--初始 
	eBS = 1,	--战斗开始
	eRP = 2,	--回合准备
	eRS = 3, 	--回合开始
	eBE = 4,	--战斗结束
}

--最大回合数
local nMaxRounds = 30
--准备时间
local nReadyTime = 30

function CBattle:Ctor(nID, nType, tBattleInfo)
	self.m_nID = nID
	self.m_nType = nType
	self.m_nCreateTime = os.time()
	self.m_sMusic = tBattleInfo.sMusic
	self.m_nLimitRounds = tBattleInfo.nLimitRounds or nMaxRounds
	self.m_nBattleGroup = tBattleInfo.nBattleGroup or 0

	self.m_nRound = 0
	self.m_tUnitAtkMap = {}			--攻方单元(1xx)	{[1xx]=battle, ...}
	self.m_tUnitDefMap = {}			--守方单元(2xx)	{[2xx]=battle, ...}
	self.m_tRoleMap = {} 			--角色列表
	self.m_nTeamID1 = tBattleInfo.nTeamID1 		--队伍ID1
	self.m_nTeamID2 = tBattleInfo.nTeamID2 		--队伍ID2
	self.m_nLeaderID1 = tBattleInfo.nLeaderID1 	--攻方队长ID
	self.m_nLeaderID2 = tBattleInfo.nLeaderID2 	--守方队长ID
	self.m_sLeaderName1 = tBattleInfo.sLeaderName1 --攻方队长名字
	self.m_sLeaderName2 = tBattleInfo.sLeaderName2 --攻方队长名字
	self.m_nFmtID1 = tBattleInfo.nFmtID1 or 0 		--攻方阵法
	self.m_nFmtLv1 = tBattleInfo.nFmtLv1 or 0 		
	self.m_tFmtAttr1 = tBattleInfo.tFmtAttr1 or {} 	
	self.m_nFmtID2 = tBattleInfo.nFmtID2 or 0 		--守方
	self.m_nFmtLv2 = tBattleInfo.nFmtLv2 or 0 		
	self.m_tFmtAttr2 = tBattleInfo.tFmtAttr2 or {} 	
	self.m_tExtData = tBattleInfo.tExtData or {} 	--额外数据
	self.m_tLeaderData1 = tBattleInfo.tLeaderData1 	--队长数据1
	self.m_tLeaderData2 = tBattleInfo.tLeaderData2 	--队长数据2
	self.m_tOtherAttrAddRatio = tBattleInfo.tOtherAttrAddRatio or {} --其他模块属性加成百分比{[type]=ratio,...}

	self.m_nUnitCount = 0 				--战斗单位数
	self.m_nReadyCount = 0 				--准备就绪数
	self.m_tClientPlayFinishMap = {} 	--客户端通知回合播放完毕映射

	self.m_nBattleState = 0 		--战斗状态
	self.m_nStateStartTime = 0		--状态开始时间
	self.m_tBattleResult = {bEnd=false, nWinner=0}

	self.m_nRoundActTime = 0
	self.m_tRoundData = {nRound=0, nRoundTime=0, tAction={}}
	self.m_tTeamTotalHurt = {0, 0} 	--造成的总伤害

	self.m_nReadyTimer = nil 	--准备计时器
	self.m_nRoundTimer = nil 	--回合计时器
	self.m_nDelayTimer = nil    --战斗结束，延迟结算定时器
	self.m_nStartTimer = nil 	--战斗开始计时器
	self.m_nSecondTimer = nil 	--每秒检测播放完成情况

	self.m_tBTRes = {			--战斗结果数据
		nBattleID = self:GetID(),
		nBattleType = self.m_nType,
		nLeaderID1 = self.m_nLeaderID1,
		nLeaderID2 = self.m_nLeaderID2,
		nTeamID1 = self.m_nTeamID1,
		tTeamID2 = self.m_nTeamID2,

		nEndType = gtBTRes.eNormal, 	--结束类型
		tTeamRoleList = {}, 	--队友类别
		bAuto = false, 			--是否自动
		bWin = false, 			--是否胜利
		nMP = 0, 				--剩余MP
		nHP = 0, 				--剩余HP
		nAtkCount = 0, 			--攻击次数
		nBeAtkCount = 0,		--被攻击次数
		bLastCallback = false,	--是否最后角色回调
		nManualSkill = 0, 	--手动技能
		nAutoInst = 0, 		--自动战斗默认指令
		nAutoSkill = 0,  	--自动战斗默认技能
		nRound = self.m_tRoundData.nRound --战斗回合数
	}

end

function CBattle:GetType() return self.m_nType end
function CBattle:SetCreateTime(nTime) self.m_nCreateTime = nTime end
function CBattle:GetBattleTime() return os.time()-self.m_nCreateTime end
function CBattle:AddTeamHurt(nTeamFlag, nHurt) self.m_tTeamTotalHurt[nTeamFlag]=self.m_tTeamTotalHurt[nTeamFlag]+math.abs(nHurt) end
function CBattle:GetTeamHurt(nTeamFlag) return self.m_tTeamTotalHurt[nTeamFlag] end
function CBattle:GetBattleState() return self.m_nBattleState end
function CBattle:GetExtData() return self.m_tExtData end
function CBattle:GetLeader1() return self.m_nLeaderID1 end
function CBattle:GetLeader2() return self.m_nLeaderID2 end
function CBattle:GetAtkTeam() return self.m_tUnitAtkMap end
function CBattle:GetDefTeam() return self.m_tUnitDefMap end

--指挥界面信息
function CBattle:GetCommandFmtInfo(oUnit)
	local nUnitID = oUnit:GetUnitID()
	local nTeamFlag = self:TeamFlag(nUnitID)
	local nFmtID = nTeamFlag == 1 and self.m_nFmtID1 or self.m_nFmtID2
	local tAttrPosAdd = nTeamFlag == 1 and self.m_tFmtAttr1 or self.m_tFmtAttr2
	if nFmtID <= 0 then
		return 
	end

	local nUnitPos = oUnit:GetUnitPos()
	if not tAttrPosAdd[nUnitPos] then
		return
	end

	local tAtrrList = {}
	for nAttrID, nAttrVal in pairs(tAttrPosAdd[nUnitPos]) do
		table.insert(tAtrrList, {nID=nAttrID, nVal=nAttrVal})
	end

	local tConf = ctFormationConf[nFmtID]
	local tInfo = {
		nFmtID = nFmtID,
		nUnitPos = nUnitPos,	
		sName = tConf.sName,
		tAtrrList = tAtrrList,
	}
	return tInfo
end

function CBattle:AddUnit(nUnitID, oUnit)
	local tUnitMap = self:GetTeam(nUnitID)
	assert(not tUnitMap[nUnitID], "单位已存在")
	tUnitMap[nUnitID] = oUnit
	self.m_nUnitCount = self.m_nUnitCount + 1

	if self:IsRealRole(oUnit) then
		self.m_tRoleMap[oUnit:GetObjID()] = oUnit
	end

	oUnit:InitUnit()
end

function CBattle:GetLeaderUnit(nTeamFlag)
	if nTeamFlag == 1 then
		return self.m_tUnitAtkMap[101]
	else
		return self.m_tUnitDefMap[201]
	end
end

function CBattle:GetLeaderData(nTeamFlag)
	if nTeamFlag == 1 then
		return self.m_tLeaderData1
	else
		return self.m_tLeaderData2
	end
end

--生成战斗结果数据
function CBattle:GenBTRes(oUnit, nEndType, bWin, nEndTime)
	local tBTRes = table.DeepCopy(self.m_tBTRes)
	tBTRes.bWin = bWin
	tBTRes.nEndType = nEndType
	tBTRes.nRound = self.m_tRoundData.nRound

	if oUnit then --怪物为nil
		tBTRes.bAuto = oUnit:IsAuto()
		tBTRes.nHP = oUnit:GetAttr(gtBAT.eQX)
		tBTRes.nMP = oUnit:GetAttr(gtBAT.eMF)
		tBTRes.nAtkCount = oUnit:GetAtkCount()
		tBTRes.nBeAtkCount = oUnit:GetBeAtkCount()
		tBTRes.tTeamRoleList = self:GetTeamRoleList(oUnit:GetUnitID())
		tBTRes.nManualSkill = oUnit.m_nManualSkill
		tBTRes.nAutoInst = oUnit.m_nAutoInst
		tBTRes.nAutoSkill = oUnit.m_nAutoSkill
		tBTRes.nEndTime = nEndTime or os.time()
	end
	return tBTRes
end

--释放战斗对象
function CBattle:OnRelease(bClear)
	goTimerMgr:Clear(self.m_nReadyTimer)
	self.m_nReadyTimer = nil
	goTimerMgr:Clear(self.m_nRoundTimer)
	self.m_nRoundTimer = nil
	goTimerMgr:Clear(self.m_nDelayTimer)
	self.m_nDelayTimer = nil
	goTimerMgr:Clear(self.m_nStartTimer)
	self.m_nStartTimer = nil
	goTimerMgr:Clear(self.m_nSecondTimer)
	self.m_nSecondTimer = nil

	local tRoleUnitList = {}
	for nID, oUnit in pairs(self.m_tUnitAtkMap) do
		oUnit:OnRelease()
		if self:IsRealRole(oUnit) or self:IsRobot(oUnit) then
			if self:IsLeader(oUnit:GetObjID()) then
				table.insert(tRoleUnitList, 1, oUnit)
			else
				table.insert(tRoleUnitList, oUnit)
			end
		end
	end
	for nID, oUnit in pairs(self.m_tUnitDefMap) do
		oUnit:OnRelease()
		if self:IsRealRole(oUnit) or self:IsRobot(oUnit) then
			if self:IsLeader(oUnit:GetObjID()) then
				table.insert(tRoleUnitList, 1, oUnit)
			else
				table.insert(tRoleUnitList, oUnit)
			end
		end
	end

	if bClear then
		LuaTrace("清理无效战斗", self:GetID())
		local nEndTime = os.time()

		if self:IsPVE() then
			local oMonster = goMonsterMgr:GetMonster(self.m_nLeaderID2)	
			if oMonster then
				local tBTRes = self:GenBTRes(nil, gtBTRes.eExcept, false, nEndTime)
				oMonster:OnBattleEnd(tBTRes, self.m_tExtData)
			end
		end

		for _, oUnit in ipairs(tRoleUnitList) do
			local tBTRes = self:GenBTRes(oUnit, gtBTRes.eExcept, false, nEndTime)
			local oRole = goPlayerMgr:GetRoleByID(oUnit:GetObjID())
			if oRole then
				--宠物处理
				local oPetUnit = self:GetSubUnit(oUnit:GetUnitID())
				if oPetUnit then
					local tBTRes = self:GenBTRes(oPetUnit, gtBTRes.eExcept, false, nEndTime)
					oRole.m_oPet:OnBattleEnd(oPetUnit:GetPetPos(), tBTRes, self.m_tExtData)
				end
				
				oRole:OnBattleEnd(tBTRes, self.m_tExtData)
				oRole:SendMsg("BattleEndRet", {nWinner=0, nBattleType=self:GetType(), nEndType=gtBTRes.eExcept, nSubBattleType=self.m_tExtData.nBattleDupType})
			end
		end
	end

end

--是否队长
function CBattle:IsLeader(nObjID)
	if self:IsPVE() then
		return self.m_nLeaderID1 == nObjID
	else
		return (self.m_nLeaderID1 == nObjID) or (self.m_nLeaderID2 == nObjID)
	end
end

--取房间会话列表
function CBattle:SessionList(nTeamFlag)
	nTeamFlag = nTeamFlag or 0

	local tSessionList = {}
	for nRoleID, oUnit in pairs(self.m_tRoleMap) do
		if self:IsRealRole(oUnit) and (nTeamFlag==0 or self:TeamFlag(oUnit:GetUnitID()) == nTeamFlag) then
			local oRole = goPlayerMgr:GetRoleByID(nRoleID)
			if not oRole then
				LuaTrace("角色不存在:", self.m_tExtData, oUnit:GetUnitID(), oUnit:GetObjName(), oUnit:GetObjID(), debug.traceback())
			elseif oRole:IsOnline() then
				local nServer, nSession = oRole:GetServer(), oRole:GetSession()
				table.insert(tSessionList, nServer)
				table.insert(tSessionList, nSession)
			end
		end
	end
	return tSessionList
end

--开始战斗
function CBattle:BattleBegin()
	self:WriteLog("战斗开始", self:GetID())
	self.m_nBattleState = CBattle.tBTS.eBS	
	self.m_nStateStartTime = os.time()

	local oRole = goPlayerMgr:GetRoleByID(self.m_nLeaderID1)
	local nBattleCount = oRole:GetBattleCount()

	local tMsg = {nBattleID=self:GetID()
		, nRound=self.m_nRound
		, tAtk={}
		, tDef={}
		, bReconnect=false
		, nAtkFmt=self.m_nFmtID1
		, nDefFmt=self.m_nFmtID2
		, sMusic = self.m_sMusic
		, nBattleType = self:GetType()
		, nBattleCount = nBattleCount
		, nSubBattleType = self.m_tExtData.nBattleDupType or 0
	}

	for nUnitID, oUnit in pairs(self.m_tUnitAtkMap) do
		table.insert(tMsg.tAtk, oUnit:GetInfo())
	end
	for nUnitID, oUnit in pairs(self.m_tUnitDefMap) do
		table.insert(tMsg.tDef, oUnit:GetInfo())
	end
	self:Broadcast("BattleStartRet", tMsg)	
	self:SyncPreloadSkillRet()
	--同步自动信息
	for _, oUnit in pairs(self.m_tRoleMap) do
		self:SyncCurrAutoInst(oUnit)
	end
	--战斗开始被动技能喊招
	self:CheckSkillTips()
	--每秒检测播放完成
	self.m_nSecondTimer = goTimerMgr:Interval(1, function() self:CheckPlayFinish() end)
end

--战斗开始被动技能喊招
function CBattle:CheckSkillTips()
	if #self.m_tRoundData.tAction > 0 then
		self:WriteLog("战斗开始前喊招数据:", self.m_tRoundData)
		self:Broadcast("RoundDataRet", self.m_tRoundData)

		local nRoundTime = math.max(1, self.m_tRoundData.nRoundTime)
		assert(not self.m_nStartTimer)
		self.m_nStartTimer = goTimerMgr:Interval(nRoundTime, function() self:RoundPrepare() end)
	else
		self:RoundPrepare()
	end
end

--返回到战斗(断线重连)
function CBattle:ReturnBattle(oRole)
	LuaTrace(oRole:GetID(), oRole:GetName(), "重连返回战斗")

	local nRoleID = oRole:GetID()
	local oTarUnit = self.m_tRoleMap[nRoleID]
	if not oTarUnit then
		return LuaTrace("重连战斗失败,角色单位不存在")
	end
	local nBattleCount = oRole:GetBattleCount()

	local tMsg = {
		nBattleID = self:GetID(),
		nRound = self.m_nRound,
		tAtk = {},
		tDef = {},
		bReconnect = true,
		nAtkFmt = self.m_nFmtID1,
		nDefFmt = self.m_nFmtID2,
		sMusic = self.m_sMusic,
		nBattleType = self:GetType(),
		nBattleCount = nBattleCount,
		nSubBattleType = self.m_tExtData.nBattleDupType or 0, 
	}

	for nUnitID, oUnit in pairs(self.m_tUnitAtkMap) do
		if not oUnit:IsLeave() then
			table.insert(tMsg.tAtk, oUnit:GetInfo())
		end
	end
	for nUnitID, oUnit in pairs(self.m_tUnitDefMap) do
		if not oUnit:IsLeave() then
			table.insert(tMsg.tDef, oUnit:GetInfo())
		end
	end

	self:SendMsg("BattleStartRet", tMsg, oTarUnit)
	self:SyncPreloadSkillRet()
	self:SyncCurrAutoInst(oTarUnit)

	if self.m_nBattleState == CBattle.tBTS.eRP then
		oTarUnit:OnRoundPrepare(self.m_nRound, os.time()-self.m_nStateStartTime, true)

	elseif self.m_nBattleState == CBattle.tBTS.eRS then
		oTarUnit:SetReconnectRound(true)

	end
end

--清理已经离开的单位
function CBattle:ClearLeaveUnit()
	for nUnitID, oUnit in pairs(self.m_tUnitAtkMap) do
		if oUnit:IsLeave() then self:OnUnitLeave(nUnitID) end
	end
	for nUnitID, oUnit in pairs(self.m_tUnitDefMap) do
		if oUnit:IsLeave() then self:OnUnitLeave(nUnitID) end
	end
end

--回合开始
function CBattle:RoundPrepare()
	if self.m_nBattleState == CBattle.tBTS.eRP then
		return LuaTrace("重复调用了RoundPrepare", debug.traceback())
	end
	self.m_nRound = self.m_nRound + 1
	self.m_nBattleState = CBattle.tBTS.eRP
	self.m_nStateStartTime = os.time()
	self:WriteLog("\n\n回合开始", self.m_nRound)

	--重置
	self.m_nReadyCount = 0
	self.m_tClientPlayFinishMap = {}
	self.m_tRoundData = {nRound=self.m_nRound, nRoundTime=0, tAction={}}

	--清除战斗开始计时器
	goTimerMgr:Clear(self.m_nStartTimer)
	self.m_nStartTimer = nil

	--倒计时
	goTimerMgr:Clear(self.m_nReadyTimer)
	self.m_nReadyTimer = goTimerMgr:Interval(nReadyTime, function() self:OnReadyTimer() end)

	--单位顺序调用
	local tUnitOrderList = {}
	for nID, oUnit in pairs(self.m_tUnitAtkMap) do
		if oUnit:IsRealRole() then
			table.insert(tUnitOrderList, 1, oUnit)
		else
			table.insert(tUnitOrderList, oUnit)
		end
	end
	for nID, oUnit in pairs(self.m_tUnitDefMap) do
		if oUnit:IsRealRole() then
			table.insert(tUnitOrderList, 1, oUnit)
		else
			table.insert(tUnitOrderList, oUnit)
		end
	end
	for _, oUnit in ipairs(tUnitOrderList) do
		oUnit:OnRoundPrepare(self.m_nRound, nReadyTime)
		oUnit:SetReconnectRound(false)
	end
end

--下达指令倒计时结束
function CBattle:OnReadyTimer()
	goTimerMgr:Clear(self.m_nReadyTimer)
	self.m_nReadyTimer = nil

	for nID, oUnit in pairs(self.m_tUnitAtkMap) do
		if not oUnit:IsReady() then
			oUnit:OnAutoTimer()
		end
	end
	for nID, oUnit in pairs(self.m_tUnitDefMap) do
		if not oUnit:IsReady() then
			oUnit:OnAutoTimer()
		end
	end
end

--回合结束
function CBattle:OnRoundEnd()
	self.m_tRoundData.nRoundTime = self.m_nRoundActTime
	self:WriteLog("回合数据", "回合:"..self.m_tRoundData.nRound, "用时:"..self.m_tRoundData.nRoundTime)
	for _, tAct in ipairs(self.m_tRoundData.tAction) do
		self:WriteLog(tAct)
	end
end

function CBattle:GetID() return self.m_nID end
function CBattle:IsPVE() return self.m_nType == gtBTT.ePVE end
function CBattle:IsPVP() return self.m_nType == gtBTT.ePVP end
function CBattle:IsArena() return self.m_nType == gtBTT.eArena end
function CBattle:GetRound() return self.m_nRound end
function CBattle:GetRoundData() return self.m_tRoundData end 
function CBattle:GetRoundActTime() return self.m_nRoundActTime end
function CBattle:IsBattleEnd() return self.m_tBattleResult.bEnd end
--是否真实玩家
function CBattle:IsRealRole(oUnit)
	if not oUnit:IsRole() then
		return false
	end
	--镜像(竞技场)
	if oUnit:IsMirror() then
		return false
	end
	--机器人
	if oUnit:IsRobot() then
		return false
	end
	--兼容旧数据
	if self:IsArena() and self:TeamFlag(oUnit:GetUnitID())==2 then
		return false
	end
	return true
end

function CBattle:IsRobot(oUnit)
	return oUnit:IsRobot()
end

function CBattle:SetBattleEnd(nWinner) 
	self.m_tBattleResult.bEnd = true
	self.m_tBattleResult.nWinner = nWinner
end

--取战斗单位
function CBattle:GetUnit(nUnitID)
	local tUnitMap = self:GetTeam(nUnitID)
	return tUnitMap[nUnitID]
end

--取队伍映射
function CBattle:GetTeam(nUnitID)
	if self:TeamFlag(nUnitID) == 1 then
		return self.m_tUnitAtkMap
	end
	return self.m_tUnitDefMap
end


--取队伍映射
function CBattle:GetEnemyTeam(nUnitID)
	if self:TeamFlag(nUnitID) == 1 then
		return self.m_tUnitDefMap
	end
	return self.m_tUnitAtkMap
end

--是否同一阵营
function CBattle:IsSameTeam(nUnitID1, nUnitID2)
	return (math.floor(nUnitID1/100) == math.floor(nUnitID2/100))
end

--单元下达指令完毕
function CBattle:OnUnitReady(nUnitID)
	self.m_nReadyCount = self.m_nReadyCount + 1
	if self.m_nUnitCount == self.m_nReadyCount then
		self:OnRoundStart()
	end
end

--排序战斗单位(速度升序)
function CBattle:SortUnit(tList)
	local tTmpSpeed = {}
	for _, oUnit in ipairs(tList) do
		tTmpSpeed[oUnit:GetUnitID()] = oUnit:CalcSpeed()
	end
	local function fnSort(oUnit1, oUnit2)
		local nSpeed1 = tTmpSpeed[oUnit1:GetUnitID()] 
		local nSpeed2 = tTmpSpeed[oUnit2:GetUnitID()]
		if nSpeed1 ~= nSpeed2 then
			return nSpeed1 < nSpeed2
		end
		local nObjType1 = oUnit1:GetObjType()
		local nObjType2 = oUnit2 :GetObjType()
		if nObjType1 ~= nObjType2 then
			return nObjType1 > nObjType2
		end
		local nLevel1 = oUnit1:GetLevel()
		local nLevel2 = oUnit2:GetLevel()
		if nLevel1 ~= nLevel2 then
			return nLevel1 < nLevel2
		end
		local nExp1 = oUnit1:GetExp()
		local nExp2 = oUnit2:GetExp()
		if nExp1 ~= nExp2 then
			return nExp1 < nExp2
		end
		return oUnit1:GetUnitID() < oUnit2:GetUnitID()
	end
	table.sort(tList, fnSort)
	self:WriteLog("战斗单位速度", tTmpSpeed)
end

--添加回合动作时间
function CBattle:AddReactActTime(tParentAct, tReactAct, sFrom, bFront)
	if bFront then
		table.insert(tParentAct.tReact, 1, tReactAct)
	else
		table.insert(tParentAct.tReact, tReactAct)
	end
	self.m_nRoundActTime = self.m_nRoundActTime + tReactAct.nTime
	self:WriteLog("增加反馈动作时间:", tReactAct.nTime, self.m_nRoundActTime, (sFrom or ""), tReactAct)
end

--添加回合动作并加时间
function CBattle:AddRoundAction(tRoundAct, sFrom)
	self.m_nRoundActTime = self.m_nRoundActTime + tRoundAct.nTime
	self:WriteLog("增加回合动作时间:", tRoundAct.nTime, self.m_nRoundActTime, (sFrom or ""), tRoundAct)
	table.insert(self.m_tRoundData.tAction, tRoundAct)
end

--所有人下完指令
function CBattle:OnRoundStart()
	if self.m_nBattleState == CBattle.tBTS.eRS then
		return LuaTrace("回合已经开始:", self.m_nRound)
	end
	self.m_nRoundActTime = 0
	self.m_nBattleState = CBattle.tBTS.eRS
	self.m_nStateStartTime = os.time()

	goTimerMgr:Clear(self.m_nReadyTimer)
	self.m_nReadyTimer = nil
	goTimerMgr:Clear(self.m_nRoundTimer)
	self.m_nRoundTimer = nil

	--两个排序列表
	local tUnitList = {} 	--总表
	local tSortList1 = {} 	--正常列表
	local tSortList2 = {}	--死亡且错过指令列表

	for nID, oUnit in pairs(self.m_tUnitAtkMap) do
		assert(oUnit:IsReady(), oUnit:GetObjName().."未下指令")
		table.insert(tUnitList, oUnit)
		table.insert(tSortList1, oUnit)
	end
	for nID, oUnit in pairs(self.m_tUnitDefMap) do
		assert(oUnit:IsReady(), oUnit:GetObjName().."未下指令")
		table.insert(tUnitList, oUnit)
		table.insert(tSortList1, oUnit)
	end

	--回合前结算(BUFF/技能)
	for _, oUnit in ipairs(tUnitList) do
		oUnit:BeforeRound(self.m_nRound)
	end

	--排序战斗单元
	self:SortUnit(tSortList1)

	--执行1回合
	while #tSortList1 > 0 do
		--速度1
		local oUnit = table.remove(tSortList1)	

		--行动前BUFF结算
		oUnit:BeforeAction()

		--执行指令
		oUnit:ExecInst()

		--战斗是否结束
		if self:IsBattleEnd() then
			break
		end

		--行动后BUFF结算
		if not oUnit:IsLeave() then
			oUnit:AfterAction()
		end

		--因死亡错过了指令
		if oUnit:IsInstMiss() then
			assert(not oUnit:IsLeave())
			table.insert(tSortList2, oUnit)
		end

		--未行动存活单位重新排序判定
		if #tSortList1 > 0 then
			for _, oUnit in ipairs(tSortList1) do
				if oUnit:GetRoundFlag(CUnit.tRoundFlag.eSPC) then
					self:SortUnit(tSortList1)
					break
				end
			end

		else
		--过了指令且复活目标排序
			for _, oUnit in ipairs(tSortList2) do
				if not oUnit:IsDeadOrLeave() then
					table.insert(tSortList1, oUnit)
				end
			end
			tSortList2 = {}
			if #tSortList1 <= 0 then	
				break
			end
			self:SortUnit(tSortList1)

		end
	end

	--回合后结算(BUFF/技能)
	if not self:IsBattleEnd() then
		for _, oUnit in ipairs(tUnitList) do
			if not oUnit:IsLeave() then
				oUnit:AfterRound(self.m_nRound)
			end
		end
	end

	self:OnRoundEnd()
	self:Broadcast("RoundDataRet", self.m_tRoundData)
	local nRoundTime = math.max(1, self.m_tRoundData.nRoundTime)
	self.m_nRoundTimer = goTimerMgr:Interval(nRoundTime, function() self:OnRoundTimer() end)
end

function CBattle:OnRoundLimitEnd()
	if self:IsArena() or self:IsPVP() then 
		local sTipsContent = "战斗已达最大回合，%s累计伤害更高，判定胜利"
		if self.m_tBattleResult.nWinner == 1 then 
			sTipsContent = string.format(sTipsContent, self.m_sLeaderName1)
		else
			sTipsContent = string.format(sTipsContent, self.m_sLeaderName2)
		end
		local _, tAtkRoleUnitList = self:GetTeamRoleList(101)
		for k, oUnit in ipairs(tAtkRoleUnitList) do 
			local oRole = goPlayerMgr:GetRoleByID(oUnit:GetObjID())
			oRole:Tips(sTipsContent)
		end

		local _, tDefRoleUnitList = self:GetTeamRoleList(201)
		for k, oUnit in ipairs(tDefRoleUnitList) do
			local oRole = goPlayerMgr:GetRoleByID(oUnit:GetObjID())
			oRole:Tips(sTipsContent)
		end

		--防止延迟结算期间，活动通知战斗主动结束
		self.m_nDelayTimer = goTimerMgr:Interval(2, function(nTimerID)
			goTimerMgr:Clear(nTimerID) 
			self.m_nDelayTimer = nil
			self:BattleResult(gtBTRes.eRounds) 
		end)
	else
		self:BattleResult(gtBTRes.eRounds)
	end
end

--回合时间到
function CBattle:OnRoundTimer()
	goTimerMgr:Clear(self.m_nRoundTimer)
	self.m_nRoundTimer = nil

	--清理离开的单位
	self:ClearLeaveUnit()

	if self:IsBattleEnd() then --战斗结束
		self:BattleResult()

	else --进入下一回合
		if self.m_nRound >= self.m_nLimitRounds then
			if self:GetTeamHurt(1) > self:GetTeamHurt(2) then
				self:SetBattleEnd(1)
			else
				self:SetBattleEnd(2)
			end
			self:OnRoundLimitEnd()
			
		else
			self:RoundPrepare()

		end
	end
end

--单位离开战斗事件
function CBattle:OnUnitLeave(nUnitID)
	local tUnitMap = self:GetTeam(nUnitID)
	local oUnit = tUnitMap[nUnitID]
	if not oUnit then
		return
	end
	oUnit:OnRelease()

	self.m_nUnitCount = self.m_nUnitCount - 1
	tUnitMap[nUnitID] = nil

	--竞技场守方
	if self:IsArena() and nUnitID>200 then
		return
	end

	local nEndTime = os.time()
	if oUnit:IsRole() then
		self.m_tRoleMap[oUnit:GetObjID()] = nil

		local tBTRes = self:GenBTRes(oUnit, gtBTRes.eEscape, false, nEndTime)
		local oRole = goPlayerMgr:GetRoleByID(oUnit:GetObjID())
		oRole:OnBattleEnd(tBTRes, self.m_tExtData)
		oRole:SendMsg("BattleEndRet", {nWinner=self:EnemyFlag(nUnitID), nBattleType=self:GetType(), nEndType=gtBTRes.eEscape
			, nSubBattleType=self.m_tExtData.nBattleDupType})

	elseif oUnit:IsPartner() then
		self:WriteLog("伙伴离开战场", oUnit:GetUnitID(), oUnit:GetObjName())
		local tBTRes = self:GenBTRes(oUnit, gtBTRes.eEscape, false, nEndTime)
		local oRole = goPlayerMgr:GetRoleByID(oUnit:GetRoleID())
		if oRole then
			oRole.m_oPartner:GetObj(oUnit:GetObjID()):OnBattleEnd(tBTRes, self.m_tExtData)
		else
			LuaTrace("角色不存在:", self.m_tExtData, oUnit:GetUnitID(), oUnit:GetObjName(), oUnit:GetRoleID(), debug.traceback())
		end

	elseif oUnit:IsPet() then
		self:WriteLog("宠物离开战场", oUnit:GetUnitID(), oUnit:GetObjName())
		local tBTRes = self:GenBTRes(oUnit, gtBTRes.eEscape, false, nEndTime)
		local oRole = goPlayerMgr:GetRoleByID(oUnit:GetRoleID())
		if oRole then
			oRole.m_oPet:OnBattleEnd(oUnit:GetPetPos(), tBTRes, self.m_tExtData)
		else
			LuaTrace("角色不存在:", self.m_tExtData, oUnit:GetUnitID(), oUnit:GetObjName(), oUnit:GetRoleID(), debug.traceback())
		end

	end
end

--单元死亡事件
function CBattle:OnUnitDead(oUnit)
	local nUnitID = oUnit:GetUnitID()
	if self:IsTeamDead(nUnitID) then
		self:SetBattleEnd(self:EnemyFlag(nUnitID))
	end
end

--通过主单位位置取副单位编号
function CBattle:GetSubUnitID(nUnitID)
	local nTeamFlag = self:TeamFlag(nUnitID)
	local nMainPos = nUnitID-nTeamFlag*100
	assert(nMainPos >= 1 and nMainPos <= 5, "主单位位置错误")

	local nSubPos = nMainPos+5
	local nSubUnit = nTeamFlag*100+nSubPos
	return nSubUnit
end

--通过副单位取主单位位置
function CBattle:GetMainUnitID(nUnitID)
	local nTeamFlag = self:TeamFlag(nUnitID)
	local nSubPos = nUnitID-nTeamFlag*100
	assert(nSubPos >= 6 and nSubPos <= 10, "副单位位置错误")

	local nMainPos = nSubPos-5
	local nMainUnit = nTeamFlag*100+nMainPos
	return nMainUnit
end

--取主单位的副单位
function CBattle:GetSubUnit(nUnitID)
	local tUnitMap = self:GetTeam(nUnitID)
	local nSubUnit = self:GetSubUnitID(nUnitID)
	local oSubUnit = tUnitMap[nSubUnit]
	return oSubUnit
end

--取副单位的主单位
function CBattle:GetMainUnit(nUnitID)
	local tUnitMap = self:GetTeam(nUnitID)
	local nMainUnit = self:GetMainUnitID(nUnitID)
	local oMainUnit = tUnitMap[nMainUnit]
	return oMainUnit
end

--是否死光了
function CBattle:IsTeamDead(nUnitID)
	local tUnitMap = self:GetTeam(nUnitID)
	for _, oUnit in pairs(tUnitMap) do
		if not oUnit:IsDeadOrLeave() then
			return false
		end
	end
	return true
end

--取队伍标识
function CBattle:TeamFlag(nUnitID)
	return math.floor(nUnitID/100)
end

--取敌人标识
function CBattle:EnemyFlag(nUnitID)
	return (self:TeamFlag(nUnitID)==1) and 2 or 1
end

--单位撤退成功事件
function CBattle:OnUnitCT(oUnit, tParentAct)
	local nUnitID = oUnit:GetUnitID()
	if oUnit:IsRole() then
		--伙伴和宠物先撤退
		local tTeamMap = self:GetTeam(nUnitID)
		for nTmpUnitID, oTmpUnit in pairs(tTeamMap) do
			if nTmpUnitID ~= nUnitID and oTmpUnit:GetRoleID() == oUnit:GetObjID() and not oTmpUnit:IsLeave() then
				local tCTAct = {nAct=gtACT.eCT, nSrcUnit=nTmpUnitID, bLeave=true, nTime=GetActTime(gtACT.eCT), tReact={}}
				oUnit:AddReactAct(tParentAct, tCTAct, "伙伴或宠物跟随主角逃跑")
				oTmpUnit:SetLeave()
			end
		end
		--角色撤退
		oUnit:SetLeave()

		if self:IsTeamDead(nUnitID) then
			self:SetBattleEnd(self:EnemyFlag(nUnitID))

		end

	else
		oUnit:SetLeave()

		if self:IsTeamDead(nUnitID) then
			self:SetBattleEnd(self:EnemyFlag(nUnitID))
		end

	end
end

--取队伍角色ID列表
function CBattle:GetTeamRoleList(nUnitID)
	local tUnitMap = self:GetTeam(nUnitID)
	
	local tRoleList = {}
	local tRoleUnitList = {}
	for nUnitID, oUnit in pairs(tUnitMap) do
		if self:IsRealRole(oUnit) then
			if self:IsLeader(oUnit:GetObjID()) then
				table.insert(tRoleList, 1, oUnit:GetObjID())
				table.insert(tRoleUnitList, 1, oUnit)
			else
				table.insert(tRoleList, oUnit:GetObjID())
				table.insert(tRoleUnitList, oUnit)
			end
		 end
	end
	return tRoleList, tRoleUnitList
end

--取战斗结算对象ID列表
function CBattle:GetBattleResultRoleList(nUnitID)
	local tUnitMap = self:GetTeam(nUnitID)

	local tRoleList = {}
	local tRoleUnitList = {}
	for nUnitID, oUnit in pairs(tUnitMap) do
		if oUnit:IsRole() and not oUnit:IsMirror() then
			if self:IsLeader(oUnit:GetObjID()) then
				table.insert(tRoleList, 1, oUnit:GetObjID())
				table.insert(tRoleUnitList, 1, oUnit)
			else
				table.insert(tRoleList, oUnit:GetObjID())
				table.insert(tRoleUnitList, oUnit)
			end
		 end
	end
	return tRoleList, tRoleUnitList
end

--取队伍角色门派列表
function CBattle:GetTeamSchoolList(nTeamFlag)
	local tUnitMap = nTeamFlag==1 and self.m_tUnitAtkMap or self.m_tUnitDefMap
	local tRoleSchoolList = {}
	for nUnitID, oUnit in pairs(tUnitMap) do
		if oUnit:IsRole() then
			table.insert(tRoleSchoolList, oUnit.m_nSchool)
		 end
	end
	return tRoleSchoolList
end

--战斗结束
function CBattle:BattleResult(nEndType)
	nEndType = nEndType or gtBTRes.eNormal
	 --可能重复调用
	if self.m_nBattleState == CBattle.tBTS.eBE then
		return LuaTrace("重复调用战斗结束，忽略")
	end
	self.m_nBattleState = CBattle.tBTS.eBE
	goBattleMgr:RemoveBattle(self:GetID())
	self:WriteLog("战斗结束", self:GetID(), self.m_tBattleResult)

	--战斗结束通知
	local _, tAtkRoleUnitList = self:GetBattleResultRoleList(101)
	for k, oUnit in ipairs(tAtkRoleUnitList) do
		local oRole = goPlayerMgr:GetRoleByID(oUnit:GetObjID())

		if oRole then
			local nTmpEndType = oUnit:IsLeave() and gtBTRes.eEscape or nEndType
			oRole:SendMsg("BattleEndRet", {nWinner=self.m_tBattleResult.nWinner, nBattleType=self:GetType(), nEndType=nTmpEndType
				, nSubBattleType=self.m_tExtData.nBattleDupType})
		else
			local sStr = string.format("角色不存在 unit:%d objid:%d robot:%s", oUnit:GetUnitID(), oUnit:GetObjID(), oUnit:IsRobot(), oUnit:IsMirror())
			LuaTrace(sStr, debug.traceback())
		end
	end
	local _, tDefRoleUnitList = self:GetBattleResultRoleList(201)
	for k, oUnit in ipairs(tDefRoleUnitList) do
		local oRole = goPlayerMgr:GetRoleByID(oUnit:GetObjID())
		if oRole then
			local nTmpEndType = oUnit:IsLeave() and gtBTRes.eEscape or nEndType
			oRole:SendMsg("BattleEndRet", {nWinner=self.m_tBattleResult.nWinner, nBattleType=self:GetType(), nEndType=nTmpEndType
				, nSubBattleType=self.m_tExtData.nBattleDupType})
		else
			local sStr = string.format("角色不存在 unit:%d objid:%d robot:%s", oUnit:GetUnitID(), oUnit:GetObjID(), oUnit:IsRobot(), oUnit:IsMirror())
			LuaTrace(sStr, debug.traceback())
		end
	end

	--战斗结束回调
	local nEndTime = os.time()
	--怪物
	if self:IsPVE() then
		local oMonster = goMonsterMgr:GetMonster(self.m_nLeaderID2)
		local bWin = self.m_tBattleResult.nWinner == 2
		local tBTRes = self:GenBTRes(nil, nEndType, bWin, nEndTime)
		oMonster:OnBattleEnd(tBTRes, self.m_tExtData)
	end
	--角色
	local function fnBattleCallback(oUnit, bLastCallback)
		local oRole = goPlayerMgr:GetRoleByID(oUnit:GetObjID())
		if not oRole then
			return
		end
		local nTmpEndType = oUnit:IsLeave() and gtBTRes.eEscape or nEndType

		--宠物处理
		local bWin = self.m_tBattleResult.nWinner == self:TeamFlag(oUnit:GetUnitID())
		local oPetUnit = self:GetSubUnit(oUnit:GetUnitID())
		if oPetUnit then
			local tBTRes = self:GenBTRes(oPetUnit, nTmpEndType, bWin, nEndTime)
			oRole.m_oPet:OnBattleEnd(oPetUnit:GetPetPos(), tBTRes, self.m_tExtData)
		end
		
		local tBTRes = self:GenBTRes(oUnit, nTmpEndType, bWin, nEndTime)
		tBTRes.bLastCallback = bLastCallback
		oRole:OnBattleEnd(tBTRes, self.m_tExtData)
	end
	for k, oUnit in ipairs(tAtkRoleUnitList) do
		fnBattleCallback(oUnit, k==#tAtkRoleUnitList)
	end
	for k, oUnit in ipairs(tDefRoleUnitList) do
		fnBattleCallback(oUnit, k==#tDefRoleUnitList)
	end
end

--TIPS
function CBattle:Tips(oUnit, sCont)
	if not self:IsRealRole(oUnit) then
		return
	end
	local nRoleID = oUnit:GetObjID()
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then
		return
	end
	oRole:Tips(sCont)
end

--发送单独消息
function CBattle:SendMsg(sCmd, tMsg, oUnit)
	if not self:IsRealRole(oUnit) then
		return
	end
	local nRoleID = oUnit:GetObjID()
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then
		return
	end
	oRole:SendMsg(sCmd, tMsg)
end

--广播房间
function CBattle:Broadcast(sCmd, tMsg, nTeamFlag)
	local tSessionList = self:SessionList(nTeamFlag)
	CmdNet.PBBroadcastExter(sCmd, tSessionList, tMsg)
end

--下达指令请求
function CBattle:AddInstReq(oRole, tData)
	local oUnit = self:GetUnit(tData.nUnitID)
	if not oUnit then
		return oRole:Tips("战斗单位不存在:"..tData.nUnitID)
	end
	assert(oUnit:IsRole() or oUnit:IsPet(), "单位类型错误:"..tData.nUnitID.."-"..oUnit:GetObjType().."-"..(self.m_tExtData.nBattleDupType or 0))
	
	local nInst = tData.nInst
	if nInst == CUnit.tINST.eFS then
		assert(oUnit:IsRole() or oUnit:IsPet(), "目标类型错误")
		oUnit:SetInst(nInst, tData.nTarUnit, tData.nSkillID)	

	elseif nInst == CUnit.tINST.eGJ then
		oUnit:SetInst(nInst, tData.nTarUnit)

	elseif nInst == CUnit.tINST.eWP then
		oUnit:SetInst(nInst, tData.nTarUnit, tData.nGridID)

	elseif nInst == CUnit.tINST.eZH then
		oUnit:SetInst(nInst, tData.nPosID)

	elseif nInst == CUnit.tINST.eZD then
		oUnit:SetInst(nInst, tData.bAuto)

	elseif nInst == CUnit.tINST.eFY then
		oUnit:SetInst(nInst)

	elseif nInst == CUnit.tINST.eBH then
		oUnit:SetInst(nInst, tData.nTarUnit)

	elseif nInst == CUnit.tINST.eBZ then
		oRole:Tips("指令未定义:"..nInst)

	elseif nInst == CUnit.tINST.eCT then
		oUnit:SetInst(nInst)

	else
		oRole:Tips("指令未定义:"..nInst)
	end
end

--技能列表请求
function CBattle:SkillListReq(oRole, nUnitID)
	local oUnit = self:GetUnit(nUnitID)
	if not oUnit then
		return
	end
	assert(oUnit:IsRole() or oUnit:IsPet(), "单位类型错误")
	if oUnit:IsRole() then
		assert(oUnit:GetObjID() == oRole:GetID(), "角色ID错误")
	end

	--普通技能
	local tList = {}
	local tSkillMap = oUnit:GetActSkillMap()
	for nID, tSkill in pairs(tSkillMap) do
		table.insert(tList, oUnit:GetSkillInfo(nID))
	end
	table.sort(tList, function(t1, t2)
		if t1.nLearnLevel == t2.nLearnLevel then
			return t1.nID < t2.nID
		end
		return t1.nLearnLevel < t2.nLearnLevel
	end)

	--法宝技能
	local tFBList = {}
	local tFBSkillMap = oUnit:GetFBSkillMap()
	for nID, tSkill in pairs(tFBSkillMap) do
		table.insert(tFBList, oUnit:GetSkillInfo(nID))
	end
	table.sort(tFBList, function(t1, t2)
		if t1.nLearnLevel == t2.nLearnLevel then
			return t1.nID < t2.nID
		end
		return t1.nLearnLevel < t2.nLearnLevel
	end)
	oRole:SendMsg("BattleSkillListRet", {tList=tList, tFBList=tFBList, nUnitID=nUnitID})
end

--物品列表请求
function CBattle:PropListReq(oRole, nUnitID)
	local oUnit = self:GetUnit(nUnitID)
	if not oUnit then
		return
	end
	assert(oUnit:IsRole() or oUnit:IsPet(), "单位类型错误")

	local oRoleUnit = oUnit
	if oUnit:IsPet() then
		oRoleUnit = self:GetMainUnit(oUnit:GetUnitID())
	end
	assert(oRoleUnit:GetObjID() == oRole:GetID(), "角色ID错误")

	local tList = {}
	local tPropList = oRole.m_oKnapsack:GetBattlePropList()
	for _, oProp in pairs(tPropList) do
		if oUnit:IsPet() then
			if oProp:GetPropConf().nSubType ~= gtMedType.eWine then
				local _, sEffect = oUnit.m_oPropHelper:CalcEffect(oUnit, oProp)
				table.insert(tList, {nGrid=oProp:GetGrid(), nID=oProp:GetID(), nNum=oProp:GetNum(), nStar=oProp:GetStar(), sEffect=sEffect})
			end
		else
			local _, sEffect = oUnit.m_oPropHelper:CalcEffect(oUnit, oProp)
			table.insert(tList, {nGrid=oProp:GetGrid(), nID=oProp:GetID(), nNum=oProp:GetNum(), nStar=oProp:GetStar(), sEffect=sEffect})
		end
	end
	local tMsg = {tList=tList, nRemains=oRoleUnit:RemainPropTimes()}
	oRole:SendMsg("BattlePropListRet", tMsg)
end

--检测客户端播放完毕
function CBattle:CheckPlayFinish()
	if not (self.m_nBattleState == CBattle.tBTS.eRS or self.m_nBattleState == CBattle.tBTS.eBS) then
		return
	end
	self.m_tClientPlayFinishMap = self.m_tClientPlayFinishMap or {}
	--统计活跃角色
	local nWaitRoleCount = 0
	local nFinishRoleCount = 0
	for nRoleID, oTmpUnit in pairs(self.m_tRoleMap) do
		local oRole = goPlayerMgr:GetRoleByID(nRoleID)
		if oRole and oRole:IsOnline() and oRole:IsActiveRole() and not oTmpUnit:IsReconnectRound() then
			if not self.m_tClientPlayFinishMap[nRoleID] then
				nWaitRoleCount = nWaitRoleCount + 1
			end
		end
	end
	for k, v in pairs(self.m_tClientPlayFinishMap) do
		nFinishRoleCount = nFinishRoleCount + 1
	end
	print("wait:", nWaitRoleCount, "finish:", nFinishRoleCount, "***####")

	--2/3人播放完成
	--神武的，以前每个技能相对可控简单，时间都可以估算（由策划在编辑技能的时候填上，会分单体和非单体等等），所以所有时间轴都是服务器控制（不会要求客户端发播完）
	--后来的项目，因为技能时间涉及因素比较多，所以服务器只控制最大最小时间，会要求客户端发播完（完美情况是在最大时间内收集全，假设最大时间没收集完则有具体策略）
	if nWaitRoleCount <= 0 and nFinishRoleCount <= 0 then
		local nRoundTime = math.max(1, self.m_tRoundData.nRoundTime)
		local nPassRoundTime = os.time() - self.m_nStateStartTime
		print("roundtime:", nRoundTime, "passtime:", nPassRoundTime, "***####")
		if nPassRoundTime >= math.ceil(nRoundTime/3*2) then
			self:OnRoundTimer()

		end

	elseif nFinishRoleCount >= math.ceil(nWaitRoleCount/3*2) then
		self:OnRoundTimer()

	end
end

--客户端播放完毕请求
function CBattle:RoundPlayFinishReq(oRole, nUnitID)
	if not (self.m_nBattleState == CBattle.tBTS.eRS or self.m_nBattleState == CBattle.tBTS.eBS) then
		return
	end
	self.m_tClientPlayFinishMap = self.m_tClientPlayFinishMap or {}
	local oUnit = self:GetUnit(nUnitID)
	if not oUnit then
		return
	end

	assert(oRole:GetID() == oUnit:GetObjID(), "单位错误:"..oUnit:GetUnitID())
	self.m_tClientPlayFinishMap[oRole:GetID()] = 1
	self:CheckPlayFinish()
end

--同步用到的技能列表
function CBattle:SyncPreloadSkillRet(nUnitID)
	local tList = {}
	if nUnitID then
		local oUnit = self:GetUnit(nUnitID)
		if not oUnit then return end
		table.insert(tList, {nUnitID=nUnitID, tSkillList=oUnit:GetPreloadSkillList()})

	else
		for nUnitID, oUnit in pairs(self.m_tUnitAtkMap) do
			table.insert(tList, {nUnitID=nUnitID, tSkillList=oUnit:GetPreloadSkillList()})
		end
		for nUnitID, oUnit in pairs(self.m_tUnitDefMap) do
			table.insert(tList, {nUnitID=nUnitID, tSkillList=oUnit:GetPreloadSkillList()})
		end
	end
	self:Broadcast("BattlePreloadSkillRet", {tList=tList})
end

--宠物列表请求
function CBattle:PetListReq(oRole, nUnitID)
	if self.m_nBattleState ~= CBattle.tBTS.eRP then
		return oRole:Tips("战斗状态错误")
	end
	local oUnit = self:GetUnit(nUnitID)
	if not oUnit then
		return
	end
	assert(oRole:GetID() == oUnit:GetObjID())

	local tList = {}
	local tPetMap = oUnit:GetPetMap()
	for nPosID, tPetData in pairs(tPetMap) do
		local tInfo = {nPosID=nPosID, nPetID=tPetData.nObjID, bUsed=tPetData.bUsed}
		table.insert(tList, tInfo)
	end
	local nRemains =  oUnit:GetRemainPet()
	oRole:SendMsg("BattlePetListRet", {tList=tList, nRemains=nRemains})
end

--逃跑结束请求
function CBattle:EscapeFinishReq(oRole, nUnitID)
	if self.m_nBattleState ~= CBattle.tBTS.eRS then
		return LuaTrace("战斗状态错误,回合已经结束")
	end
	local oUnit = self:GetUnit(nUnitID)
	if not oUnit or not oUnit:IsLeave() then
		return
	end
	assert(oUnit:IsPet() or oUnit:IsRole())

	local oRoleUnit = oUnit
	if oUnit:IsPet() then
		oRoleUnit = self:GetMainUnit(nUnitID)
	end
	assert(oRoleUnit:GetObjID() == oRole:GetID(), "角色错误")
	--角色逃跑完毕,伙伴和宠物先逃跑,不等计时器
	if oUnit:IsRole() then
		local tTeamMap = self:GetTeam(nUnitID)
		for nTmpUnitID, oTmpUnit in pairs(tTeamMap) do
			if (oTmpUnit:IsPet() or oTmpUnit:IsPartner()) and oTmpUnit:IsLeave() and oTmpUnit:GetRoleID() == oRole:GetID() then
				self:OnUnitLeave(nTmpUnitID)
			end
		end
	end
	self:OnUnitLeave(nUnitID)
end

--强制结束战斗
function CBattle:ForceFinish()
	goBattleMgr:RemoveBattle(self:GetID(), true)
end

--自动战斗指令列表
function CBattle:BattleAutoInstListReq(oRole, nUnitID)
	local oUnit = self:GetUnit(nUnitID)
	if not oUnit or oUnit:IsLeave() then
		return
	end
	assert(oUnit:IsPet() or oUnit:IsRole(), "单位类型错误")
	local tInstList = oUnit:GetAutoInstList()
	oRole:SendMsg("BattleAutoInstListRet", {tInstList=tInstList, nUnitID=nUnitID})
	-- print("CBattle:BattleAutoInstListReq***", nUnitID, tInstList)
end

--设置自动战斗默认指令
function CBattle:BattleSetAutoInstReq(oRole, nUnitID, nInst, nSkillID)
	if nInst <= 0 then
		return oRole:Tips("指令错误"..nInst)
	end
	if nInst == CUnit.tINST.eFS then
		if nSkillID == 0 then
			return oRole:Tips("技能ID不能为0")
		end
	end
	local oUnit = self:GetUnit(nUnitID)
	if not oUnit or oUnit:IsLeave() then
		return oRole:Tips("战斗单位不存在:"..nUnitID)
	end
	assert(oUnit:IsPet() or oUnit:IsRole(), "角色错误:"..nUnitID)
	oUnit.m_nAutoInst = nInst
	oUnit.m_nAutoSkill = nSkillID
	self:SyncCurrAutoInst(oUnit)
end

--同步自动战斗默认指令
function CBattle:SyncCurrAutoInst(oUnit)
	local oRoleUnit, oPetUnit
	if oUnit:IsRole() then 
		oRoleUnit = oUnit
		oPetUnit = self:GetSubUnit(oUnit:GetUnitID())
	elseif oUnit:IsPet() then
		oRoleUnit = self:GetMainUnit(oUnit:GetUnitID())
		oPetUnit = oUnit
	end
	if not oRoleUnit and not oPetUnit then
		return
	end
	local tInstList = {}
	if oRoleUnit then
		local tSkill
		if oRoleUnit.m_nAutoSkill > 0 then
			tSkill = oRoleUnit:GetSkillInfo(oRoleUnit.m_nAutoSkill)
		end
		table.insert(tInstList, {nUnitID=oRoleUnit:GetUnitID(), nInst=oRoleUnit.m_nAutoInst, tSkill=tSkill})
	end
	if oPetUnit then
		local tSkill
		if oPetUnit.m_nAutoSkill > 0 then
			tSkill = oPetUnit:GetSkillInfo(oPetUnit.m_nAutoSkill)
		end
		table.insert(tInstList, {nUnitID=oPetUnit:GetUnitID(), nInst=oPetUnit.m_nAutoInst, tSkill=tSkill})
	end
	self:SendMsg("BattleSetAutoInstRet", {tInstList=tInstList}, oRoleUnit)
end

--写战斗日志
function CBattle:WriteLog(...)
	-- if not goBattleMgr:IsBattleLog() then
	-- 	return
	-- end
	local oRole = goPlayerMgr:GetRoleByID(self.m_nLeaderID1)
	if not (oRole and oRole:GetID() == 10595) then
		return
	end
	
	local t = {...}
	local sLog = ""
	for _, v in ipairs(t) do
		sLog = sLog..tostring(v).."\t"
	end
	sLog = sLog.."\n"

	local nRoleID = oRole and oRole:GetID() or 0
	local sFile = string.format("../battlelog/%s_%d.log", nRoleID, self:GetID())
	GlobalExport.AddBattleLog(sFile, sLog)
end

--取阵法信息
function CBattle:GetFmtData()
	if not self.m_tTmpFmtData then
		self.m_tTmpFmtData = {
			nAtkFmtID = self.m_nFmtID1,
			nAtkFmtLv = self.m_nFmtLv1,
			tAtkFmtAttr = self.m_tFmtAttr1,
			nDefFmtID = self.m_nFmtID2,
			nDefFmtLv = self.m_nFmtLv2,
			tDefFmtAttr = self.m_tFmtAttr2,
		}
	end
	return self.m_tTmpFmtData
end

--取ExtData
function CBattle:GetExtData()
	return self.m_tExtData or {}
end

--取其他模块属性加成百分比
function CBattle:GetOtherAttrAddRatio()
	return self.m_tOtherAttrAddRatio
end

--战斗指挥请求
function CBattle:BattleCommandInfoReq(oRole, nTarUnit)
	local nRoleID = oRole:GetID()	
	local oUnit = self.m_tRoleMap[nRoleID]
	if not oUnit or oUnit:IsLeave() then
		return oRole:Tips("您已离开战斗")
	end
	local oTarUnit = self:GetUnit(nTarUnit)
	if not oTarUnit then
		return oRole:Tips("目标不存在")
	end
	local tMsg = oTarUnit:GetCommandInfo(oUnit)
	local tEnemyCommandList, tFriendCommandList = oRole.m_oBattleCommand:GetCommandList()
	tMsg.tEnemyCommandList = tEnemyCommandList
	tMsg.tFriendCommandList = tFriendCommandList
	oRole:SendMsg("BattleCommandInfoRet", tMsg)
end

--修改战斗指挥
function CBattle:ChangeBattleCommandReq(oRole, nCmdID, sCmdName)
	local nLen = string.len(sCmdName)
	if nLen <= 0 or nLen > 4*3 then
		return oRole:Tips("指令名字长度错误")
	end
	GF.HasBadWord(sCmdName, function(bRes)
		if bRes == nil or bRes then
			return oRole:Tips("指令名包含非法字")
		end
		if not oRole:IsOnline() then
			return
		end
		if oRole:GetBattleID() ~= self:GetID() then
			return
		end
		local nRoleID = oRole:GetID()	
		local oUnit = self.m_tRoleMap[nRoleID]
		if not oUnit or oUnit:IsLeave() then
			return oRole:Tips("您已离开战斗")
		end
		local bRet = false
		if math.floor(nCmdID/100) == 1 then
			bRet = oRole.m_oBattleCommand:SetEnemyCommand(nCmdID, sCmdName)
		else
			bRet = oRole.m_oBattleCommand:SetFriendCommand(nCmdID, sCmdName)
		end
		if not bRet then
			return oRole:Tips("修改指令失败:"..nCmdID.."-"..sCmdName)
		end
		oRole:SendMsg("ChangeBattleCommandRet", {nCmdID=nCmdID, sCmdName=sCmdName})
	end)
end

--下达战斗指挥
function CBattle:SetBattleCommandReq(oRole, nCmdID, nTarUnit)
	local nRoleID = oRole:GetID()	
	local oUnit = self.m_tRoleMap[nRoleID]
	if not oUnit or oUnit:IsLeave() then
		return oRole:Tips("您已离开战斗")
	end
	local oTarUnit = self:GetUnit(nTarUnit)
	if not oTarUnit then
		return oRole:Tips("目标不存在")
	end
	if nCmdID == 0 then
		if oTarUnit:SetCommand(0, "") then
			self:Broadcast("SetBattleCommandRet", {nSrcUnitID=oUnit:GetUnitID(), nUnitID=nTarUnit, nCmdID=0, sCmdName=""}, self:TeamFlag(oUnit:GetUnitID()))
		end
		return
	else
		local nCmdFlag = math.floor(nCmdID/100)
		local bFriend = self:IsSameTeam(oUnit:GetUnitID(), nTarUnit)
		if (bFriend and nCmdFlag == 1) or (not bFriend and nCmdFlag == 2) then
			return oRole:Tips("指令目标错误")
		end

		local sCmdName
		if nCmdFlag == 1 then
			sCmdName = oRole.m_oBattleCommand:GetEnemyCommand(nCmdID)
		else
			sCmdName = oRole.m_oBattleCommand:GetFriendCommand(nCmdID)
		end
		if not sCmdName then
			return oRole:Tips("指令不存在")
		end
		if not oTarUnit:SetCommand(nCmdID, sCmdName) then
			return oRole:Tips("已设置了同一指令")
		end
		self:Broadcast("SetBattleCommandRet", {nSrcUnitID=oUnit:GetUnitID(), nUnitID=nTarUnit, nCmdID=nCmdID, sCmdName=sCmdName}, self:TeamFlag(oUnit:GetUnitID()))
		return
	end
end

--GM移除战斗
--指定nRoleID所在的一方胜利
function CBattle:GMRemove(nRoleID) 
	if self:IsBattleEnd() then
		return 
	end
	local _, tAtkRoleUnitList = self:GetBattleResultRoleList(101)
	local nWin = 2
	for k, oUnit in ipairs(tAtkRoleUnitList) do
		if nRoleID == oUnit:GetObjID() then 
			nWin = 1
			break 
		end
	end
	self:SetBattleEnd(nWin)
	self:BattleResult(gtBTRes.eExcept)
end


