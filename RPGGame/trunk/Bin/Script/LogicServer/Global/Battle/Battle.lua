--战斗模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--战斗类型
CBattle.tBTT = 
{
	ePVE = 1,
	ePVP = 2,
}

function CBattle:Ctor(nID, nType, nLeaderID1, nLeaderID2)
	self.m_nID = nID
	self.m_nType = nType

	self.m_nRound = 0
	self.m_tUnitAtkMap = {}		--攻方单元(1x)	{[1x]=battle, ...}
	self.m_tUnitDefMap = {}		--守方单元(2x)	{[2x]=battle, ...}
	self.m_nLeaderID1 = 0 		--攻方队长ID
	self.m_nLeaderID2 = 0 		--守方队长ID

	self.m_nUnitCount = 0
	self.m_nReadyCount = 0
	self.m_tBattleResult = {bEnd=false, nWinner=0}

	self.m_nReadyTimer = nil 	--准备计时器
	self.m_nRoundTimer = nil 	--回合计时器
	self.m_tRoundData = {nRound=0, nRoundTime=0, tAction={}}
end

function CBattle:AddUnit(nUnitID, oUnit)
	local tUnitMap = self:GetTeam(nUnitID)
	assert(not tUnitMap[nUnitID], "单位已存在")
	tUnitMap[nUnitID] = oUnit
	self.m_nUnitCount = self.m_nUnitCount + 1
end

--释放战斗对象
function CBattle:OnRelease()
	for nID, oUnit in pairs(self.m_tUnitAtkMap) do
		oUnit:OnRelease()
	end
	for nID, oUnit in pairs(self.m_tUnitDefMap) do
		oUnit:OnRelease()
	end

	goTimerMgr:Clear(self.m_nReadyTimer)
	goTimerMgr:Clear(self.m_nRoundTimer)
end

--取房间会话列表
function CBattle:SessionList()
	local tSessionList = {}
	for nID, oUnit in pairs(self.m_tUnitAtkMap) do
		local nServer, nSession = oUnit:GetServer(), oUnit:GetSession()
		table.insert(tSessionList, nServer)
		table.insert(tSessionList, nSession)
	end
	for nID, oUnit in pairs(self.m_tUnitDefMap) do
		local nServer, nSession = oUnit:GetServer(), oUnit:GetSession()
		table.insert(tSessionList, nServer)
		table.insert(tSessionList, nSession)
	end
	return tSessionList
end

--开始战斗
function CBattle:StartBattle()
	local tMsg = {nID=self:GetID(), nRound=self.m_nRound, tAtk={}, tDef={}}
	for nUnitID, oUnit in pairs(self.m_tUnitAtkMap) do
		table.insert(tMsg.tAtk, oUnit:GetInfo())
	end
	for nUnitID, oUnit in pairs(self.m_tUnitDefMap) do
		table.insert(tMsg.tDef, oUnit:GetInfo())
	end
	self:Broadcast("BattleStartRet", tMsg)	
end

--回合开始
function CBattle:RoundBegin()
	self.m_nRound = self.m_nRound + 1

	--重置
	self.m_nReadyCount = 0
	self.m_tRoundData = {nRound=self.m_nRound, nRoundTime=0, tAction={}}

	--倒计时
	local nReadyTime = 30
	goTimerMgr:Clear(self.m_nReadyTimer)
	self.m_nReadyTimer = goTimerMgr:Interval(nReadyTime, function() self:OnReadyTimer() end)

	--单位调用
	for nID, oUnit in pairs(self.m_tUnitAtkMap) do
		oUnit:OnRoundBegin(self.m_nRound)
	end
	for nID, oUnit in pairs(self.m_tUnitDefMap) do
		oUnit:OnRoundBegin(self.m_nRound)
	end
end

--下达指令倒计时结束
function CBattle:OnReadyTimer()
	goTimerMgr:Clear(self.m_nReadyTimer)
	self.m_nReadyTimer = nil

	for nID, oUnit in pairs(self.m_tUnitAtkMap) do
		if not oUnit:IsReady() then
			oUnit:EnterAuto()
		end
	end
	for nID, oUnit in pairs(self.m_tUnitDefMap) do
		if not oUnit:IsReady() then
			oUnit:EnterAuto()
		end
	end
end

--回合结束
function CBattle:RoundEnd()
end

function CBattle:GetID() return self.m_nID end
function CBattle:IsPVE() return self.m_nType == CBattle.tBTT.ePVE end
function CBattle:IsPVP() return self.m_nType == CBattle.tBTT.ePVP end
function CBattle:GetRound() return self.m_nRound end
function CBattle:GetRoundData() return self.m_tRoundData end 
function CBattle:IsBattleEnd() return self.m_tBattleResult.bEnd end

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
	if nUnitID%100 == 1 then
		return self.m_tUnitAtkMap
	end
	return self.m_tUnitDefMap
end

--是否同一阵营
function CBattle:IsSameTeam(nUnitID1, nUnitID2)
	return (nUnitID1%100 == nUnitID2%100)
end

--单元下达指令完毕
function CBattle:OnUnitReady(nUnitID)
	self.m_nReadyCount = self.m_nReadyCount + 1
	if self.m_nUnitCount == self.m_nReadyCount then
		self:OnRoundReady()
	end
end

--排序战斗单位
function CBattle:SortUnit(tList)
	local function fnSort(oUnit1, oUnit2)
		local nSpeed1 = oUnit1:CalcSpeed()
		local nSpeed2 = oUnit2:CalcSpeed()
		if nSpeed1 == nSpeed2 then
			local nObjType1 = oUnit1:GetObjType()
			local nObjType2 = oUnit2 :GetObjType()
			if nObjType1 == nObjType2 then
				local nExp1 = oUnit1:GetExp()
				local nExp2 = oUnit2:GetExp()
				return nExp1 < nExp2
			end
			return nObjType1 > nObjType2
		end
		return nSpeed1 < nSpeed2
	end
	table.sort(tList, fnSort)	
end

--添加回合动作
function CBattle:AddRoundAction(tAct)
	self.m_tRoundData.nRoundTime = self.m_tRoundData.nRoundTime + tAct.nTime
	table.insert(self.m_tRoundData.tAction, tAct)
end

--所有人下完指令
function CBattle:OnRoundReady()
	goTimerMgr:Clear(self.m_nReadyTimer)
	self.m_nReadyTimer = nil
	goTimerMgr:Clear(self.m_nRoundTimer)
	self.m_nRoundTimer = nil

	--两个排序列表,1个是正常的
	local tUnitList = {} 	--总表
	local tSortList1 = {} 	--正常表列表
	local tSortList2 = {}	--死亡且错过指令列表

	for nID, oUnit in pairs(self.m_tUnitAtkMap) do
		assert(oUnit:IsReady(), "未下指令")
		table.insert(tUnitList, oUnit)
		table.insert(tSortList1, oUnit)
	end
	for nID, oUnit in pairs(self.m_tUnitDefMap) do
		assert(oUnit:IsReady(), "未下指令")
		table.insert(tUnitList, oUnit)
		table.insert(tSortList1, oUnit)
	end

	--排序战斗单元
	self:SortUnit(tSortList1)

	--回合前结算(BUFF)
	for _, oUnit in ipairs(tUnitList) do
		oUnit:BeforeRoundBuff(self.m_nRound)
	end

	--执行1回合
	while #tSortList1 > 0 do
		--速度1
		local oUnit = table.remove(tSortList1)	

		--行动前BUFF结算
		oUnit:BeforeActionBuff()

		--执行指令
		oUnit:ExecInst()

		--战斗是否结束
		if self:IsBattleEnd() then
			break
		end

		--行动后BUFF结算
		if not oUnit:IsLeave() then
			oUnit:AfterActionBuff()
		end

		--因死亡错过了指令
		if oUnit:IsInstMiss() then
			assert(not oUnit:IsLeave())
			table.insert(tSortList2, oUnit)
		end

		--未行动存活单位重新排序判定
		if #tSortList1 > 0 then
			for _, oUnit in ipairs(tSortList1) do
				if oUnit:IsSpeedChange() then
					self:SortUnit(tSortList1)
					break
				end
			end
		else
		--过了令且复活目标排序
			for _, oUnit in ipairs(tSortList2) do
				if not oUnit:IsDead() then
					table.insert(tSortList1, oUnit)
				end
			end
			assert(#tSortList1 > 0)
			self:SortUnit(tSortList1)
		end
	end

	--回合后结算(BUFF)
	if not self:IsBattleEnd() then
		for _, oUnit in ipairs(tUnitList) do
			if not oUnit:IsLeave() then
				oUnit:AfterRoundBuff(self.m_nRound)
			end
		end

	--战斗结束
	else
		self:AddRoundAction({nAct=gtACT.eJS, nWinner=self.m_tBattleResult.nWinner, nTime=1})
		
	end
	self:Broadcast("RoundDataRet", self.m_tRoundData)
	self.m_nRoundTimer = goTimerMgr:Interval(self.m_tRoundData.nRoundTime, function() self:OnRoundTimer() end)

end

--回合时间到
function CBattle:OnRoundTimer()
	goTimerMgr:Clear(self.m_nRoundTimer)
	self.m_nRoundTimer = nil
	if self:IsBattleEnd() then
		self:BattleResult()
	else
		self:RoundBegin()
	end
end

--单位离开战斗事件
function CBattle:OnUnitLeave(nUnitID)
	local tUnitMap = self:GetTeam(nUnitID)
	tUnitMap[nUnitID] = nil
	self.m_nUnitCount = self.m_nUnitCount - 1
end

--单元死亡事件
function CBattle:OnUnitDead(oUnit)
	if not oUnit:IsMonster() or not oUnit:IsPet() then
		return
	end
	self:OnUnitLeave(oUnit:GetUnitID())
	if self:IsTeamDead(nUnitID) then
		self:SetBattleEnd(self:EnemyFlag(nUnitID))
	end
end

--通过角色位置取宠物位置
function CBattle:GetPetUnitID(nRoleUnit)
	local nTeam = nRoleUnit % 100
	local nGrid = nRoleUnit - nTeam*100
	assert(nGrid >= 1 and nGrid <= 5, "角色位置错误")

	local nPetGrid = nGrid + 5
	local nPetUnit = nTeam * 100 + nPetGrid
	return nPetGrid
end

--通过宠物位置取角色位置
function CBattle:GetRoleUnitID(nPetUnit)
	local nTeam = nPetUnit % 100
	local nGrid = nPetUnit - nTeam*100
	assert(nGrid >= 6 and nGrid <= 10, "宠物位置错误")

	local nRoleGrid = nGrid - 5
	local nRoleUnit = nTeam * 100 + nRoleGrid
	return nRoleUnit
end

--取玩家的宠物单位
function CBattle:GetPetUnit(nRoleUnit)
	local tUnitMap = self:GetTeam(nRoleUnit)
	local nPetUnit = self:GetPetUnitID(nRoleUnit)
	local oPetUnit = tUnitMap[nPetUnit]
	if oPetUnit then
		assert(oPetUnit:IsPet())
	end
	return oPetUnit
end

--取宠物的玩家单位
function CBattle:GetRoleUnit(nPetUnit)
	local tUnitMap = self:GetTeam(nPetUnit)
	local nRoleUnit = self:GetPetUnitID(nPetUnit)
	local oRoleUnit = tUnitMap[nRoleUnit]
	if oRoleUnit then
		assert(oRoleUnit:IsRole())
	end
	return oRoleUnit
end

--取随机存活敌人
function CBattle:RandAliveEnemy(nUnitID)
	local tUnitMap = self:GetTeam(nUnitID)
	local tUnitList = {}
	for nUnit, oUnit in pairs(tUnitMap) do
		if not oUnit:IsDead() then
			table.insert(tUnitList, nUnit)
		end
	end
	if #tUnitList == 0 then
		return
	end
	return tUnitList[math.random(#tUnitList)]
end

--是否一方死光(撤退)
function CBattle:IsTeamDead(nUnitID)
	local tUnitMap = self:GetTeam(nUnitID)
	if not next(tUnitMap) then
		return true
	end
	for _, oUnit in pairs(tUnitMap) do
		if not oUnit:IsDead() then
			return false
		end
	end
	return true
end

--取敌人标识
function CBattle:EnemyFlag(nUnit)
	if nUnit % 10 == 1 then
		return 2
	else
		return 1
	end
end

--单位撤退成功事件
function CBattle:OnUnitCT(oUnit)
	local nUnitID = oUnit:GetUnitID()

	if oUnit:IsRole() then
		oUnit:OnCTSuccess()

		local oPetUnit = self:GetPetUnit(nUnitID)
		if oPetUnit then
			oPetUnit:OnCTSuccess()

		end

		if self:IsPVE() then
			self:SetBattleEnd(self:EnemyFlag(nUnitID))
		elseif self:IsTeamDead(nUnitID) then
			self:SetBattleEnd(self:EnemyFlag(nUnitID))
		end

	else
		oUnit:OnCTSuccess()

		if self:IsTeamDead(nUnitID) then
			self:SetBattleEnd(self:EnemyFlag(nUnitID))
		end

	end
end

--战斗结束
function CBattle:BattleResult()
	print("CBattle:BattleResult***", self.m_tBattleResult)
	assert(self.m_tBattleResult.bEnd)
end

--TIPS
function CBattle:Tips(nServer, nSession, sCont)
    CmdNet.PBSrv2Clt("TipsMsgRet", nServer, nSession, {sCont=sCont})
end

--广播房间
function CBattle:Broadcast(sCmd, tMsg)
	local tSessionList = self:SessionList()
	CmdNet.PBBroadcastExter(sCmd, tSessionList, tMsg)
end

--广播房间
function CBattle:SendMsg(sCmd, nServer, nSession, tMsg)
	CmdNet.PBSrv2Clt(sCmd, nServer, nSession, tMsg)
end

--下达指令请求
function CBattle:AddInstReq(oRole, tData)
	local oUnit = self:GetUnit(tData.nUnitID)
	if not oUnit then
		return
	end
	local nInst = tData.nInst
	if nInst == CUnit.tINST.eFS then
		oUnit:SetInst(nInst, tDta.nTarUnit, tData.nSkillID)	

	elseif nInst == CUnit.tINST.eGJ then
		oUnit:SetInst(nInst, tDta.nTarUnit)

	elseif nInst == CUnit.tINST.eWP then
		oUnit:SetInst(nInst, tDta.nPropID)

	elseif nInst == CUnit.tINST.eZH then
		oUnit:SetInst(nInst, tDta.nPetID)

	elseif nInst == CUnit.tINST.eZD then
		oUnit:SetInst(nInst, tDta.bAuto)

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