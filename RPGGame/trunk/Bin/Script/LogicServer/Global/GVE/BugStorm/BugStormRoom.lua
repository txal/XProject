local _abs, _sort, _insert, _random, _floor, _max, _min, _time
= math.abs, table.sort, table.insert, math.random, math.floor, math.max, math.min, os.time

--房间状态
CBugStormRoom.tRoomState =
{
	eInit = 0,
	eStart = 1,
	eFinish = 2,
}

function CBugStormRoom:Ctor(oBugStormMgr, nRoomID)
	self.m_oBugStormMgr = oBugStormMgr
	self.m_nState = self.tRoomState.eInit
	self.m_nRoomID = nRoomID
	self.m_nCreateTime = _time()
	self.m_nSceneIndex = 0
	self.m_tPlayerMap = {}	--{[sCharID]={nLevel=0,nExp=0,sCharID="",bTeam=true},...}
	self.m_nPlayerCount = 0
	self.m_sEnergyStoneID = nil
	self.m_oMonsterMaker = nil
	self.m_sLeaderID = nil --队长
end

function CBugStormRoom:GetID() return self.m_nRoomID end
function CBugStormRoom:GetState() return self.m_nState end
function CBugStormRoom:GetScene() return goLuaSceneMgr:GetSceneByIndex(self.m_nSceneIndex) end
function CBugStormRoom:GetPlayerCount() return self.m_nPlayerCount end
function CBugStormRoom:GetPlayer(sCharID) return self.m_tPlayerMap[sCharID] end
function CBugStormRoom:GetCreateTime() return self.m_nCreateTime end

function CBugStormRoom:GetSessionList()
	local tSessionList = {}
	for sCharID, tPlayer in pairs(self.m_tPlayerMap) do
		local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
		if oPlayer then
			local nSession = oPlayer:GetSession()
			_insert(tSessionList, nSession)
		end
	end
	return tSessionList
end

function CBugStormRoom:GetRandomPlayer()
	if self.m_nPlayerCount <= 0 then
		return
	end
	local nRnd = _random(1, self.m_nPlayerCount)
	local sCharID
	for k = 1, nRnd do
		sCharID = next(self.m_tPlayerMap, sCharID)
	end
	local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
	return oPlayer
end

function CBugStormRoom:GetAvgFameLevel()
	local nTotalFameLevel = 0
	for sCharID, tPlayer in pairs(self.m_tPlayerMap) do
		local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
		local oGVE = oPlayer:GetModule(CGVEModule:GetType())
		nTotalFameLevel = nTotalFameLevel + oGVE:GetFameLevel()
	end
	local nAvgFameLevel = _floor(nTotalFameLevel / _max(1, self.m_nPlayerCount))
	return nAvgFameLevel
end

function CBugStormRoom:JoinRoom(oPlayer, bTeam)
	if self.m_nState == self.tRoomState.eFinish then
		return
	end
	if self.m_nPlayerCount >= ctBugStormEtc[1].nRoomPlayer then
		return
	end
	local oBattle = oPlayer:GetModule(CBattle:GetType())
	if oBattle:IsBattling() then
		return
	end

	self:CreatePlayer(oPlayer, bTeam)
	if self.m_nState == self.tRoomState.eStart then
		oBattle:EnterScene(self.m_nSceneIndex, gtBattleType.eBugStorm, gtCampType.eDefender, {nRoomID=self.m_nRoomID})	
	else
		oBattle:SetBattleType(gtBattleType.eBugStorm, gtCampType.eDefender, {nRoomID=self.m_nRoomID})
	end
	if not self.m_sLeaderID then
		self.m_sLeaderID = oPlayer:GetCharID()
	end
	return true
end

function CBugStormRoom:StartRun()
	assert(self.m_nState == self.tRoomState.eInit)
	assert(self.m_nPlayerCount > 0)

	local nDupID = ctBugStormEtc[1].nDupID
	local tDupConf = assert(ctGVEDupConf[nDupID])
	assert(#tDupConf.tSceneID > 0)
	local nIndex = _random(1, #tDupConf.tSceneID)
	local nSceneID = tDupConf.tSceneID[nIndex][1]
	local oScene = goLuaSceneMgr:CreateScene(nSceneID, gtBattleType.eBugStorm)
	self.m_nSceneIndex = oScene:GetSceneIndex()
	self.m_oMonsterMaker = CMonsterMaker:new(self.m_nSceneIndex, gtBattleType.eBugStorm, gtCampType.eAttacker, {nRoomID=self.m_nRoomID})

	for sCharID, tPlayer in pairs(self.m_tPlayerMap) do
		local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
		local oBattle = oPlayer:GetModule(CBattle:GetType())
		oBattle:EnterScene(self.m_nSceneIndex, gtBattleType.eBugStorm, gtCampType.eDefender, {nRoomID=self.m_nRoomID})	
	end

	self.m_nState = self.tRoomState.eStart
	goLogger:EventLog(gtEvent.eBugStormStart, nil, self.m_nRoomID, self.m_nPlayerCount, self.m_sLeaderID)

	self:SyncLeader()
end

function CBugStormRoom:RemovePlayer(oPlayer)
	local sCharID = oPlayer:GetCharID()
	if not self.m_tPlayerMap[sCharID] then
		return
	end
	self.m_tPlayerMap[sCharID] = nil
	self.m_nPlayerCount = self.m_nPlayerCount - 1
	oPlayer:GetModule(CBattle:GetType()):SetBattleType(0, 0)

	if self.m_nPlayerCount <= 0 then
		self:BattleResult(false)

	elseif sCharID == self.m_sLeaderID then
		self.m_sLeaderID = next(self.m_tPlayerMap)	
		self:SyncLeader()

	end
end

function CBugStormRoom:SyncLeader()
	local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(self.m_sLeaderID)
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "BattleLeaderSync", {})
end

function CBugStormRoom:CreatePlayer(oPlayer, bTeam)
	bTeam = bTeam and true or false
	local sCharID = oPlayer:GetCharID()
	assert(not self.m_tPlayerMap[sCharID])

	local nMinLevel = 0
	for sCharID, tPlayer in pairs(self.m_tPlayerMap) do
		if nMinLevel == 0 or tPlayer.nLevel < nMinLevel then
			nMinLevel = tPlayer.nLevel
		end
	end
	nMinLevel = _max(1, nMinLevel)

	local tLevelConf = assert(ctBugStormLevelConf[nMinLevel])
	local tPlayer = {nExp=0, nLevel=nMinLevel, sCharID=sCharID, bTeam=bTeam}
	self.m_tPlayerMap[sCharID] = tPlayer
	self.m_nPlayerCount = self.m_nPlayerCount + 1
end

function CBugStormRoom:OnEnterScene(oPlayer)
	local sCharID = oPlayer:GetCharID()
	local tPlayer = assert(self.m_tPlayerMap[sCharID])
	local oBattle = oPlayer:GetModule(CBattle:GetType())
	local tBattleAttr = oBattle:CalcBattleAttr(tPlayer.nLevel)
	oBattle:UpdateRuntimeBattleAttr(tBattleAttr)
	oBattle:SetBattleLevel(tPlayer.nLevel)
end

function CBugStormRoom:AfterEnterScene(oPlayer)
	self:MakeEnergyStone()
	self.m_oMonsterMaker:AfterPlayerEnterScene()
end

function CBugStormRoom:MakeEnergyStone()
	if self.m_sEnergyStoneID then
		return
	end
	print("刷能源水晶***")
	local nMonsterID = ctBugStormEtc[1].nEnergyStoneID
	local tConf = assert(ctMonsterConf[nMonsterID])
	local tBornPos = ctBugStormEtc[1].tEnergyStonePos[1]
	local oMonster = goLuaMonsterMgr:CreateMonster(nMonsterID, self.m_nSceneIndex, tBornPos[1], tBornPos[2], gtBattleType.eBugStorm, gtCampType.eDefender, {nRoomID=self.m_nRoomID})
	self.m_sEnergyStoneID = oMonster:GetObjID()
end

function CBugStormRoom:Offline(oPlayer)
	self:RemovePlayer(oPlayer)
end

function CBugStormRoom:OnLeaveScene(oPlayer)
	self:RemovePlayer(oPlayer)
end

function CBugStormRoom:BattleResult(bWin)
	self.m_nState = self.tRoomState.eFinish
	if self.m_oMonsterMaker then
		self.m_oMonsterMaker:OnBattleResult(bWin)
	end
	local oScene = self:GetScene()
	if oScene then
		oScene:BattleResult()
	end
	self.m_oBugStormMgr:OnBattleResult(self.m_nRoomID, bWin)
	goLogger:EventLog(gtEvent.eBugStormEnd, nil, self.m_nRoomID, self.m_nPlayerCount, self.m_sLeaderID, bWin)
end

function CBugStormRoom:OnPlayerDead(oPlayer)
	local tPlayer = assert(self.m_tPlayerMap[oPlayer:GetCharID()])
	tPlayer.nDeadTime = _time()

	for sCharID, tPlayer in pairs(self.m_tPlayerMap) do
		if not tPlayer.nDeadTime then	
			return
		end
	end

	--所有玩家死光战斗结束
	self:BattleResult(false)
end

function CBugStormRoom:CheckUpgrade(tPlayer)
	local nCurrLevel = tPlayer.nLevel
	if nCurrLevel >= #ctBugStormLevelConf then
		return
	end
	local nNextLevel = nCurrLevel + 1
	local tNextConf = ctBugStormLevelConf[nNextLevel]
	if tPlayer.nExp >= tNextConf.nExp then
		tPlayer.nLevel = nNextLevel
		tPlayer.nExp = tPlayer.nExp - tNextConf.nExp
		local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(tPlayer.sCharID)
		local oBattle = oPlayer:GetModule(CBattle:GetType())
		local tSessionList = self:GetSessionList()
		--设置战斗等级
		oBattle:SetBattleLevel(tPlayer.nLevel)

		--广播玩家升级(包括自己)
		local nAOIID = oBattle:GetAOIID()
		local tLevelData = {nAOIID=nAOIID, nLevel=tPlayer.nLevel}
		CmdNet.PBBroadcastExter(tSessionList, "PlayerBattleLevelSync", tLevelData)

		--更新属性
		local tCurrAttr = oBattle:GetBattleAttr()
		local tRuntimeAttr = oBattle:GetRuntimeBattleAttr()
		local nLostHP = _max(0, tCurrAttr[gtAttrDef.eHP] - tRuntimeAttr[gtAttrDef.eHP])
		local tNewAttr = oBattle:CalcBattleAttr(tPlayer.nLevel)
		tNewAttr[gtAttrDef.eHP] = _max(0, tNewAttr[gtAttrDef.eHP] - nLostHP)
		oBattle:UpdateRuntimeBattleAttr(tNewAttr)

		local tAttrSync = {}
		for k, v in pairs(tNewAttr) do
			_insert(tAttrSync, {nID=k, nVal=v})
		end

		--广播战斗属性变化广播
		local tAttrData = {nAOIID=oBattle:GetAOIID(),tAttr=tAttrSync}
		CmdNet.PBBroadcastExter(tSessionList, "ActorBattleAttrSync", tAttrData)
		print(oPlayer:GetName(), "升级", tNewAttr)
	end
end

function CBugStormRoom:OnMonsterDead(oMonster, sAtkerID, nAtkerType)
	local oEnergyStone = goLuaMonsterMgr:GetMonster(self.m_sEnergyStoneID)
	if not oEnergyStone or oMonster:GetConfID() == oEnergyStone:GetConfID() then
		self.m_sEnergyStoneID = nil
		self:BattleResult(false)
		return
	end
	self.m_oMonsterMaker:OnMonsterDead(oMonster:GetObjID())
	
	if nAtkerType == gtObjType.ePlayer and self.m_nState == self.tRoomState.eStart then
		local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sAtkerID)
		if oPlayer then
			local tPlayer = self.m_tPlayerMap[sAtkerID]
			local nConfID = oMonster:GetConfID()
			local tMonsterConf = ctMonsterConf[nConfID]
			local nKillExp = tMonsterConf.nKillExp
			local nOtherExp = _floor(nKillExp * 0.5)

			tPlayer.nExp = tPlayer.nExp + nKillExp
			self:CheckUpgrade(tPlayer)

			for sCharID, tPlayer in pairs(self.m_tPlayerMap) do
				if sCharID ~= sAtkerID then
					tPlayer.nExp = tPlayer.nExp + nOtherExp
					self:CheckUpgrade(tPlayer)
				end
			end
		end
	end
end

function CBugStormRoom:OnReliveReq(oPlayer)
	local sCharID = oPlayer:GetCharID()
	local tPlayer = self.m_tPlayerMap[sCharID]
	if not tPlayer.nDeadTime then
		return
	end
	local nReliveTime = ctBugStormEtc[1].nReliveTime
	local nReliveProp = ctBugStormEtc[1].nReliveProp
	if _time() - tPlayer.nDeadTime < nReliveTime then
		local oBagModule = oPlayer:GetModule(CBattle:GetType())
		if not oBagModule:SubItem(gtObjType.eProp, nReliveProp, 1, gtReason.eRelive) then
			local tSendData = {nCode=-1,nValue=nReliveProp}
			CmdNet.PBSrv2Clt(oPlayer:GetSession(), "PlayerReliveRet", tSendData)
			return
		end
	end
	tPlayer.nDeadTime = nil
	local oBattle = oPlayer:GetModule(CBattle:GetType())
	oBattle:Relive()
end

function CBugStormRoom:CancelMatchReq(oPlayer)
	if self.m_nState ~= self.tRoomState.eInit then
		return
	end
	if oPlayer:GetCharID() ~= self.m_sLeaderID then
		return
	end
	self:RemovePlayer(oPlayer)
end

--测试
function CBugStormRoom:KillMonsterTest()
	if self.m_nState ~= self.tRoomState.eStart then
		return
	end
	self.m_oMonsterMaker:KillMonsterTest()
end