local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--房间状态
CBugHoleRoom.tRoomState =
{
	eInit = 0,
	eStart = 1,
	eFinish = 2,
}

local nBAO_ZOU = 3	 	--暴走
local nCHAO_SHEN = 6	--超神
local tEtcConf = ctBugHoleEtc[1]

function CBugHoleRoom:Ctor(oBugHoleMgr, nRoomID, nRoomStage)
	assert(oBugHoleMgr and nRoomID and nRoomStage)
	self.m_oBugHoleMgr = oBugHoleMgr
	self.m_nRoomID = nRoomID
	self.m_nRoomStage = nRoomStage
	self.m_nDupID = assert(ctGVGFameLevelConf[nRoomStage]).nDupID
	self.m_nSceneIndex = 0

	--tPlayerMap={[sCharID]={sCharID="",sName="",nObjType=0,nLevel=0,bTeam=false,nFame=0,nFameLevel=0
	--,nDeads=0,nDeadTime=0,nKills=0,nLifeKills=0,nCntKills=0,nCntKillTime=0,tRecentKill={},tWeaponKill={},},}
	self.m_tAtkerTeam = {nTeamMembers=0, nRealCount=0, nCount=0, nTotalKills=0, nKillTime=0, tPlayerMap={}}
	self.m_tDeferTeam = {nTeamMembers=0, nRealCount=0, nCount=0, nTotalKills=0, nKillTime=0, tPlayerMap={}}
	self.m_sLeaderID = nil

	self.m_nState = self.tRoomState.eInit
	self.m_nCreateTime = os.time()
	self.m_nStartTime = 0

	self.m_nBattleTimer = nil
	local tDupConf = assert(ctGVGDupConf[self.m_nDupID])
	self.m_oSceneDropMaker = CSceneDropMaker:new(tDupConf.nSceneDropID, self.OnDropRefresh, self)
end


function CBugHoleRoom:IsRunning() return self.m_nState == CBugHoleRoom.tRoomState.eStart end
function CBugHoleRoom:GetScene() return goLuaSceneMgr:GetSceneByIndex(self.m_nSceneIndex) end
function CBugHoleRoom:SetNewbie(nCurrFights) self.m_bNewbie=true self.m_nCurrFights=nCurrFights end

function CBugHoleRoom:GetID() return self.m_nRoomID end
function CBugHoleRoom:GetStage() return self.m_nRoomStage end
function CBugHoleRoom:IsNewbie() return self.m_bNewbie end
function CBugHoleRoom:GetState() return self.m_nState end
function CBugHoleRoom:GetCreateTime() return self.m_nCreateTime end

function CBugHoleRoom:GetAtkerCount() return self.m_tAtkerTeam.nCount end --人+机器人
function CBugHoleRoom:GetDeferCount() return self.m_tDeferTeam.nCount end --人+机器人
function CBugHoleRoom:GetAtkerRealCount() return self.m_tAtkerTeam.nRealCount end --人
function CBugHoleRoom:GetDeferRealCount() return self.m_tDeferTeam.nRealCount end --人

function CBugHoleRoom:GenNextLeader()
	if self.m_tAtkerTeam.nRealCount > 0 then
		for sCharID, tPlayer in pairs(self.m_tAtkerTeam.tPlayerMap)	do
			if tPlayer.nObjType == gtObjType.ePlayer and not tPlayer.bBackground then
				return sCharID
			end
		end
	end
	if self.m_tDeferTeam.nRealCount > 0 then
		for sCharID, tPlayer in pairs(self.m_tDeferTeam.tPlayerMap)	do
			if tPlayer.nObjType == gtObjType.ePlayer and not tPlayer.bBackground then
				return sCharID
			end
		end
	end
end

function CBugHoleRoom:GetAvgFameValue(nCamp, bLevel)
	local nTotalValue, nTotalPlayer = 0, 0
	if not nCamp or nCamp == gtCampType.eAttacker then
		for sCharID, tPlayer in pairs(self.m_tAtkerTeam.tPlayerMap) do
			local nValue = bLevel and tPlayer.nFameLevel or tPlayer.nFame
			nTotalValue = nTotalValue + nValue
			nTotalPlayer = nTotalPlayer + 1
		end
	end
	if not nCamp or nCamp == gtCampType.eDefender then
		for sCharID, tPlayer in pairs(self.m_tDeferTeam.tPlayerMap) do
			local nValue = bLevel and tPlayer.nFameLevel or tPlayer.nFame
			nTotalValue = nTotalValue + nValue
			nTotalPlayer = nTotalPlayer + 1
		end
	end
	local nAverageValue = math.floor(nTotalValue / math.max(1, nTotalPlayer))
	return nAverageValue
end

function CBugHoleRoom:GetPlayerData(sCharID)
	if self.m_tAtkerTeam.tPlayerMap[sCharID] then
		return self.m_tAtkerTeam.tPlayerMap[sCharID], gtCampType.eAttacker, self.m_tAtkerTeam

	elseif self.m_tDeferTeam.tPlayerMap[sCharID] then
		return self.m_tDeferTeam.tPlayerMap[sCharID], gtCampType.eDefender, self.m_tDeferTeam

	end
end

function CBugHoleRoom:GetSessionList(sException)
	local tSessionList = {}
	for sCharID, tPlayer in pairs(self.m_tAtkerTeam.tPlayerMap) do
		if sCharID ~= sException and tPlayer.nObjType == gtObjType.ePlayer then
			local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
			table.insert(tSessionList, oPlayer:GetSession())
		end
	end

	for sCharID, tPlayer in pairs(self.m_tDeferTeam.tPlayerMap) do
		if sCharID ~= sException and  tPlayer.nObjType == gtObjType.ePlayer then
			local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
			table.insert(tSessionList, oPlayer:GetSession())
		end
	end
	return tSessionList
end

function CBugHoleRoom:CreatePlayer(oPlayer, nCamp, bTeam)
	bTeam = bTeam and true or false
	local sCharID = oPlayer:GetCharID()
	assert(not self.m_tAtkerTeam.tPlayerMap[sCharID])
	assert(not self.m_tDeferTeam.tPlayerMap[sCharID])

	local sName = oPlayer:GetName()
	local nLevel = oPlayer:GetLevel()
	local nWins, nLoses = oPlayer.m_oGVGModule:GetWinsInfo()
	local nFameAdd = GetGVGMatchFameAdd(nWins, nLoses)

	local tPlayer = {sCharID=sCharID, sName=sName, nObjType=gtObjType.ePlayer, nLevel=nLevel, bTeam=bTeam
		, nFame = oPlayer.m_oGVGModule:GetFame()+nFameAdd, nFameLevel = oPlayer.m_oGVGModule:GetFameLevel()
		, nDeads=0, nDeadTime=0, nKills=0, nLifeKills=0, nCntKills=0, nCntKillTime=0
		, tRecentKill={}, tWeaponKill={}}

	local tTeam = nCamp==gtCampType.eAttacker and self.m_tAtkerTeam or self.m_tDeferTeam
	tTeam.tPlayerMap[sCharID] = tPlayer
	tTeam.nCount = tTeam.nCount + 1
	tTeam.nRealCount = tTeam.nRealCount + 1
	if bTeam then
		tTeam.nTeamMembers = tTeam.nTeamMembers + 1
	end
end

function CBugHoleRoom:_sync_leader_()
	if not self.m_sLeaderID then
		return
	end
	local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(self.m_sLeaderID)
	if not oPlayer then
		return
	end
	print("任命队长:", oPlayer:GetName())
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "BattleLeaderSync", {bLeader=true})
end

function CBugHoleRoom:_gen_pos_(tPosList, nIndex)
	local tDupConf = assert(ctGVGDupConf[self.m_nDupID])
	local tSceneConf = assert(ctSceneConf[tDupConf.nSceneID])

	local tPos = assert(tPosList[nIndex])
	local nCenterX, nCenterY, nRadius = table.unpack(tPos)

	local tAOI = gtSceneDef.tAOI
	local nPosX, nPosY = tAOI.eUnitWidth / 2, tAOI.eUnitHeight / 2
	local nMinX, nMaxX = math.max(0, nCenterX - nRadius), math.min(nCenterX + nRadius, tSceneConf.nWidth - 1)
	local nMinY, nMaxY = math.max(0, nCenterY - nRadius), math.min(nCenterY + nRadius, tSceneConf.nHeight- 1)
	for i = 1, 16 do
		local nTmpX = math.random(nMinX, nMaxX)
		local nTmpY = math.random(nMinY, nMaxY)
		if not GlobalExport.IsBlockUnit(tSceneConf.nMapID, nTmpX, nTmpY) then
			nPosX = (math.floor(nTmpX / tAOI.eUnitWidth) + 0.5) * tAOI.eUnitWidth
			nPosY = (math.floor(nTmpY / tAOI.eUnitHeight) + 0.5) * tAOI.eUnitHeight
			break
		end
	end
	return math.max(0, nPosX), math.max(0, nPosY)
end

function CBugHoleRoom:_gen_born_pos_(nCamp, nNum)
	assert(nCamp, "_gen_born_pos_阵营不能为空")
	local tDupConf = assert(ctGVGDupConf[self.m_nDupID])
	local tBornPosList = nCamp==gtCampType.eAttacker and tDupConf.tBornAtk or tDupConf.tBornDef
	local nIndex = nNum or math.random(1, #tBornPosList)
	nIndex = math.min(nIndex, #tBornPosList)
	return self:_gen_pos_(tBornPosList, nIndex)
end

function CBugHoleRoom:JoinRoom(oPlayer, nCamp, bTeam)
	if self.m_nState == self.tRoomState.eFinish then
		return
	end
	local tTeam = nCamp==gtCampType.eAttacker and self.m_tAtkerTeam or self.m_tDeferTeam
	if tTeam.nCount >= tEtcConf.nTeamPlayer then
		return
	end
	if oPlayer:IsBattling() then
		return
	end
	self:CreatePlayer(oPlayer, nCamp, bTeam)

	local tBattle = {nType=gtBattleType.eBugHole, nCamp=nCamp, tData={nRoomStage=self.m_nRoomStage, nRoomID=self.m_nRoomID}}
	if self.m_nState == self.tRoomState.eStart then
		local nPosX, nPosY = self:_gen_born_pos_(nCamp)
		oPlayer:EnterScene(self.m_nSceneIndex, tBattle, nPosX, nPosY)	
	else
		oPlayer:SetBattle(tBattle)
	end
	if not self.m_sLeaderID then
		self.m_sLeaderID = oPlayer:GetCharID()
	end
	return true
end

function CBugHoleRoom:_create_robot(nCamp, tRobotConf)
	assert(nCamp and tRobotConf)
	local tTeam = nCamp == gtCampType.eAttacker and self.m_tAtkerTeam or self.m_tDeferTeam
	local nPosX, nPosY = self:_gen_born_pos_(nCamp, tTeam.nCount + 1)
	local tBattle = {nType=gtBattleType.eBugHole, nCamp=nCamp, tData={nRoomStage=self.m_nRoomStage, nRoomID=self.m_nRoomID}}
	local oSRobot = goLuaSRobotMgr:CreateRobot(tRobotConf.nID, self.m_nSceneIndex, nPosX, nPosY, tBattle)

	local tPlayer = {sCharID=oSRobot:GetObjID(), sName=oSRobot:GetName(), nObjType=gtObjType.eRobot, nLevel=tRobotConf.nLevel, bTeam=false
		, nFame = tRobotConf.nFame, nFameLevel = tRobotConf.nFameLevel
		, nDeads=0, nDeadTime=0, nKills=0, nLifeKills=0, nCntKills=0, nCntKillTime=0
		, tRecentKill={}, tWeaponKill={}}

	tTeam.tPlayerMap[tPlayer.sCharID] = tPlayer
	tTeam.nCount = tTeam.nCount + 1

	return oSRobot
end

function CBugHoleRoom:GetRobotIDRange(nAvgFame, nRobotNum)
	assert(nRobotNum > 0)
	local nRobotID = FindRobotByFame(nAvgFame)
	local nMaxRobotID = #ctRobotConf
	local nLeftRemain = nRobotID - 1
	local nRightRemain = nMaxRobotID - nRobotID

	local nNearbyNum = nRobotNum - 1
	local nLeftNum = math.floor(nNearbyNum / 2)
	local nRightNum = nNearbyNum - nLeftNum
	nLeftNum = nLeftNum + math.max(0, nRightNum - nRightRemain)
	nRightNum = nRightNum + math.max(0, nLeftNum - nLeftRemain)

	local nMinRobotID = math.max(1, nRobotID - nLeftNum)
	local nMaxRobotID = math.min(nMaxRobotID, nRobotID + nRightNum)
	assert(nMaxRobotID >= nMinRobotID)
	return nMinRobotID, nMaxRobotID
end

function CBugHoleRoom:StartRun(nGmAtkNum, nGmDefNum)
	LuaTrace("CBugHoleRoom:StartRun***")
	assert(self.m_nState == self.tRoomState.eInit)
	if self.m_tAtkerTeam.nCount <= 0 and self.m_tDeferTeam.nCount <= 0 then
		return
	end

	local tDupConf = assert(ctGVGDupConf[self.m_nDupID])
	local oScene = goLuaSceneMgr:CreateScene(tDupConf.nSceneID, gtBattleType.eBugHole)
	self.m_nSceneIndex = oScene:GetSceneIndex()

	self.m_nStartTime = os.time()
	self.m_nState = self.tRoomState.eStart
	self.m_nBattleTimer = GlobalExport.RegisterTimer(tEtcConf.nBattleTime*1000, function() self:BattleTimeOut() end )
	
	local nNum = 0 
	local tAtkerList = {}
	local tBattle = {nType=gtBattleType.eBugHole, nCamp=gtCampType.eAttacker, tData={nRoomStage=self.m_nRoomStage, nRoomID=self.m_nRoomID}}
	for sCharID, tPlayer in pairs(self.m_tAtkerTeam.tPlayerMap) do
		nNum = nNum + 1
		local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
		local nPosX, nPosY = self:_gen_born_pos_(gtCampType.eAttacker, nNum)
		oPlayer:EnterScene(self.m_nSceneIndex, tBattle, nPosX, nPosY)	

		table.insert(tAtkerList, {sCharName=oPlayer:GetName(), nLevel=oPlayer:GetLevel()})
	end

	nNum = 0
	tDeferList = {}
	tBattle.nCamp = gtCampType.eDefender
	for sCharID, tPlayer in pairs(self.m_tDeferTeam.tPlayerMap) do
		nNum = nNum + 1
		local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
		local nPosX, nPosY = self:_gen_born_pos_(gtCampType.eDefender, nNum)
		oPlayer:EnterScene(self.m_nSceneIndex, tBattle, nPosX, nPosY)	

		table.insert(tDeferList, {sCharName=oPlayer:GetName(), nLevel=oPlayer:GetLevel()})
	end

	--GM
	if nGmAtkNum and nGmDefNum then
		local nAvgFame = self:GetAvgFameValue()
		local nRobotAtkNum = nGmAtkNum - self.m_tAtkerTeam.nCount
		local nRobotDefNum = nGmDefNum - self.m_tDeferTeam.nCount
		local nRobotNum = nRobotAtkNum + nRobotDefNum
		if nRobotNum > 0 then
			local nMinID, nMaxID = self:GetRobotIDRange(nAvgFame, nRobotNum)
			for k = 1, nRobotAtkNum do
				local nRobotID = math.random(nMinID, nMaxID)
				local oSRobot = self:_create_robot(gtCampType.eAttacker, ctRobotConf[nRobotID])
				table.insert(tAtkerList, {sCharName=oSRobot:GetName(), nLevel=oSRobot:GetLevel()})
			end

			for k = 1, nRobotDefNum do
				local nRobotID = math.random(nMinID, nMaxID)
				local oSRobot = self:_create_robot(gtCampType.eDefender, ctRobotConf[nRobotID])
				table.insert(tDeferList, {sCharName=oSRobot:GetName(), nLevel=oSRobot:GetLevel()})
			end
		end
	else
		if self:IsNewbie() then
			--新手
			local nCurrFights = assert(self.m_nCurrFights)
			local tNewbieConf = assert(ctNewbieConf[nCurrFights])
			local nRobotAtkNum = tEtcConf.nTeamPlayer - self.m_tAtkerTeam.nCount
			local nRobotDefNum = tEtcConf.nTeamPlayer - self.m_tDeferTeam.nCount
			for k = 1, nRobotAtkNum do
				local tConf = tNewbieConf.tSelfRobot[k]
				if tConf then
					local tRobotConf = ctRobotConf[tConf[1]]
					if tRobotConf then
						local oSRobot = self:_create_robot(gtCampType.eAttacker, tRobotConf)
						table.insert(tAtkerList, {sCharName=oSRobot:GetName(), nLevel=oSRobot:GetLevel()})
					end
				end
			end
			for k = 1, nRobotDefNum do
				local tConf = tNewbieConf.tEnemyRobot[k]
				if tConf then
					local tRobotConf = ctRobotConf[tConf[1]]
					if tRobotConf then
						local oSRobot = self:_create_robot(gtCampType.eDefender, tRobotConf)
						table.insert(tDeferList, {sCharName=oSRobot:GetName(), nLevel=oSRobot:GetLevel()})
					end
				end
			end
		else
			--生成ROBOT(NvN)
			local nAvgFame = self:GetAvgFameValue()
			local nRobotAtkNum = tEtcConf.nTeamPlayer - self.m_tAtkerTeam.nCount
			local nRobotDefNum = tEtcConf.nTeamPlayer - self.m_tDeferTeam.nCount
			local nRobotNum = nRobotAtkNum + nRobotDefNum
			if nRobotNum > 0 then
				local nMinID, nMaxID = self:GetRobotIDRange(nAvgFame, nRobotNum)
				for k = 1, nRobotAtkNum do
					local nRobotID = math.random(nMinID, nMaxID)
					local oSRobot = self:_create_robot(gtCampType.eAttacker, ctRobotConf[nRobotID])
					table.insert(tAtkerList, {sCharName=oSRobot:GetName(), nLevel=oSRobot:GetLevel()})
				end

				for k = 1, nRobotDefNum do
					local nRobotID = math.random(nMinID, nMaxID)
					local oSRobot = self:_create_robot(gtCampType.eDefender, ctRobotConf[nRobotID])
					table.insert(tDeferList, {sCharName=oSRobot:GetName(), nLevel=oSRobot:GetLevel()})
				end
			end
		end
	end

	local tSessionList = self:GetSessionList()
	CmdNet.PBBroadcastExter(tSessionList, "BugHoleTeamInfoRet", {tAtkerList=tAtkerList, tDeferList=tDeferList})

	--战场掉落
	self.m_oSceneDropMaker:Start()
	--log
	goLogger:EventLog(gtEvent.eBugHoleStart, nil, self.m_nRoomID, self:GetAtkerCount(), self:GetDeferCount(), self:GetAtkerRealCount(), self:GetDeferRealCount())
end

function CBugHoleRoom:_cancel_relive_timer_(tPlayer)
	if tPlayer.nReliveTimer then
		GlobalExport.CancelTimer(tPlayer.nReliveTimer)
		tPlayer.nReliveTimer = nil
	end
end

function CBugHoleRoom:RemovePlayer(oPlayer)
	local tBattle = oPlayer:GetBattle()
	if tBattle.nType ~= gtBattleType.eBugHole then
		return
	end

	local sCharID = oPlayer:GetCharID()
	local tTeam = tBattle.nCamp == gtCampType.eAttacker and self.m_tAtkerTeam or self.m_tDeferTeam
	if not tTeam.tPlayerMap[sCharID] then
		return
	end

	self:_cancel_relive_timer_(tTeam.tPlayerMap[sCharID])
	tTeam.tPlayerMap[sCharID] = nil
	tTeam.nCount = tTeam.nCount - 1
	tTeam.nRealCount = tTeam.nRealCount - 1
	oPlayer:SetBattle(nil)

	--强退惩罚
	if self.m_nState == self.tRoomState.eStart then
		local nGold = oPlayer:GetGold()
		local nSubNum = math.min(10000, math.floor(nGold * 0.01))
		if nSubNum > 0 then
			oPlayer:SubGold(nSubNum, gtReason.eBugHolePunish)
			local sCont = string.format(ctLang[18], nSubNum)
			oPlayer:ScrollMsg(sCont)
			print(oPlayer:GetName(), sCont)
		end
	end

	if self.m_sLeaderID == sCharID then
		self.m_sLeaderID = self:GenNextLeader()
		self:_sync_leader_()
	end

	local nAtkerCount = self:GetAtkerCount()
	local nDeferCount = self:GetDeferCount()
	if self.m_nState == self.tRoomState.eStart then
		if nDeferCount <= 0 then
			self:BattleResult(gtCampType.eAttacker)

		elseif nAtkerCount <= 0 then
			self:BattleResult(gtCampType.eDefender)

		else
			local nRealCount = self:GetAtkerRealCount() + self:GetDeferRealCount()
			if nRealCount <= 0 then
				self:_judge_battle_result_()
			end
			
		end

	elseif nAtkerCount <= 0 and nDeferCount <= 0 then
		self:BattleResult(0)

	end
end

function CBugHoleRoom:_judge_battle_result_()
	print("CBugHoleRoom:_judge_battle_result_***")
	local nAtkKills, nDefKills = self.m_tAtkerTeam.nTotalKills, self.m_tDeferTeam.nTotalKills
	local nWinCamp = gtCampType.eAttacker
	if nAtkKills == nDefKills then
		if self.m_tAtkerTeam.nKillTime <= self.m_tDeferTeam.nKillTime then
			nWinCamp = gtCampType.eAttacker
		else
			nWinCamp = gtCampType.eDefender
		end
	elseif nAtkKills > nDefKills then
		nWinCamp = gtCampType.eAttacker
	else
		nWinCamp = gtCampType.eDefender
	end
	self:BattleResult(nWinCamp)
end

function CBugHoleRoom:BattleTimeOut()
	print("CBugHoleRoom:BattleTimeOut***")
	self:_judge_battle_result_()
end

function CBugHoleRoom:_gen_award_(tTeam, tPlayer, oPlayer, bWin)
	local tDropItem = {}

	local tEtcConf = ctBugHoleEtc[1]
	local nFameLevel = math.min(#ctGVGFameLevelConf, math.max(1, tPlayer.nFameLevel))
	local tFameLevelConf = assert(ctGVGFameLevelConf[nFameLevel])

	local tNewbieConf
	if self:IsNewbie() then
		local nCurrFights = assert(self.m_nCurrFights)
		tNewbieConf = assert(ctNewbieConf[nCurrFights])
	end

	--掉落
	if bWin then
		if self:IsNewbie() then
			for _, tItem in ipairs(tNewbieConf.tPropAward) do
				if tItem[2] > 0 then
					table.insert(tDropItem, tItem)
				end
			end
		else
			local nDropID = tFameLevelConf.nDropID
			tDropItem = DropMgr:GenDropItem(nDropID)
		end
	end

	--声望
	local nFameID, nFameVal = 0, 0
	if self:IsNewbie() then
		local tFameAward = tNewbieConf.tFameAward[1]
		nFameID, nFameVal = table.unpack(tFameAward)
	else
		local nCamp = tTeam==self.m_tAtkerTeam and gtCampType.eDefender or gtCampType.eAttacker
		local nEnemyAvgFame = self:GetAvgFameValue(nCamp)
		local tFameLimit = tEtcConf.tFameLimit[1]
		local nLocalFameID, nFameLimit = table.unpack(tFameLimit)
		--INT(获得的极限声望*(1-FLOOR(1/(1+10^((敌方队伍平均声望值 – 玩家声望值)/400))，0.0001))) @0.0001是精度
		nFameID = nLocalFameID
		nFameVal = math.floor(nFameLimit*( 1-1/(1+10^((nEnemyAvgFame-tPlayer.nFame)/400)) ))
	end
	if nFameVal > 0 then
		if bWin then
			table.insert(tDropItem, {gtObjType.eProp, nFameID, nFameVal})
		else
			oPlayer.m_oGVGModule:SubFame(nFameVal, gtReason.eBugHoleSubFame)
		end
	end
	
	--金币计算
	local tGoldBase = tFameLevelConf.tGoldBase[1]
	local nGoldID, nGoldBase = table.unpack(tGoldBase)
	local nGoldNum = math.floor(nGoldBase * tPlayer.nKills / (tPlayer.nKills + 5) * 1.5)
	--获得的金币取0.95-1.05倍随机值
	nGoldNum = math.floor(nGoldNum * math.random(95, 105) * 0.01)
	if nGoldNum > 0 then
		table.insert(tDropItem, {gtObjType.eProp, nGoldID, nGoldNum})
	end

	--组队经验加成
	local nTeamExpAdd = 1
	if tTeam.nTeamMembers > 1 and tPlayer.bTeam then
		nTeamExpAdd = 1 + tEtcConf.nTeamExpAdd * 0.0001
	end

	--10倍经验检测
	local nExpMulti = 1
	local nMultiExpFights = oPlayer.m_oGVGModule:GetMultiExpFights()
	if nMultiExpFights > 0 then
		nExpMulti = 10
		oPlayer.m_oGVGModule:SubMultiExpFights()
	end

	--经验计算
	local tExpBase = bWin and tEtcConf.tWinExpBase[1] or tEtcConf.tLoseExpBase[1]
	local nExpID, nExpBase = table.unpack(tExpBase)
	local nExpNum = math.floor(nExpMulti * nTeamExpAdd * nExpBase * tPlayer.nKills / (tPlayer.nKills + 5) * 1.5)
	if nExpNum > 0 then
		table.insert(tDropItem, {gtObjType.eProp, nExpID, nExpNum})
	end

	--发奖
	local tItemList = {}
	for _, tItem in ipairs(tDropItem) do
		local nType, nID, nNum = table.unpack(tItem)
		if nID > 0 then
			local tList = oPlayer:AddItem(nType, nID, nNum, gtReason.eBugHoleAward)
			local oArm 
			if nType == gtObjType.eArm then
				oArm = tList and #tList > 0 and tList[1][2]
			end
			local nColor = GF.GetItemColor(nType, nID, oArm)	
			table.insert(tItemList, {nType=nType, nID=nID, nNum=nNum, nColor=nColor})
		end
	end
	return tItemList, nFameVal
end

--战斗结果详细
function CBugHoleRoom:_battle_result_detail_()
	if not self.tAtkTeamInfo then
		local oScene = self:GetScene()
		local function _fnGetPlayerInfo(tPlayer)
			local tInfo = {}
			tInfo.sName = tPlayer.sName
			tInfo.nDmg = oScene:GetCppScene():GetActorDmg(tPlayer.sCharID)
			tInfo.nKills = tPlayer.nKills
			tInfo.nDeads = tPlayer.nDeads
			tInfo.nArmID = 0
			local nMaxKills = 0
			for k, v in pairs(tPlayer.tWeaponKill) do
				if nMaxKills == 0 or v > nMaxKills then
					nMaxKills = v
					tInfo.nArmID = k
				end
			end
			if tInfo.nArmID == 0 then
				if tPlayer.nObjType == gtObjType.ePlayer then
					local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(tPlayer.sCharID)
					if oPlayer then
						tInfo.nArmID = oPlayer.m_oBattle:GetCurrWeapon().nArmID
					end

				elseif tPlayer.nObjType == gtObjType.eRobot then
					local oSRobot = goLuaSRobotMgr:GetRobot(tPlayer.sCharID)
					if oSRobot then
						tInfo.nArmID = oSRobot:GetCurrWeapon().nArmID
					end

				end
			end
			if tPlayer.nObjType == gtObjType.ePlayer then
				local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(tPlayer.sCharID)
				if oPlayer then
					oPlayer.m_oGVGModule:UpdateDmg(tInfo.nDmg)
				end
			end
			return tInfo
		end

		self.tAtkTeamInfo = {}
		for k, v in pairs(self.m_tAtkerTeam.tPlayerMap) do
			table.insert(self.tAtkTeamInfo, _fnGetPlayerInfo(v))
		end
		self.tDefTeamInfo = {}
		for k, v in pairs(self.m_tDeferTeam.tPlayerMap) do
			table.insert(self.tDefTeamInfo, _fnGetPlayerInfo(v))
		end
	end
	return self.tAtkTeamInfo, self.tDefTeamInfo
end

function CBugHoleRoom:BattleResult(nWinCamp)
	self.m_oSceneDropMaker:Stop()
	if self.m_nBattleTimer then
		GlobalExport.CancelTimer(self.m_nBattleTimer)
		self.m_nBattleTimer = nil
	end

	local nPreState = self.m_nState
	self.m_nState = self.tRoomState.eFinish
	--发奖
	if nPreState == self.tRoomState.eStart then
		local oScene = self:GetScene()
		if oScene then
			oScene:BattleResult()
			GlobalExport.RegisterTimer(tEtcConf.nExitTime * 1000, function() oScene:KickAllPlayer() end)
		end

		--胜利方奖励
		local tWinTeam = nWinCamp == gtCampType.eAttacker and self.m_tAtkerTeam or self.m_tDeferTeam
		for sCharID, tPlayer in pairs(tWinTeam.tPlayerMap) do
			self:_cancel_relive_timer_(tPlayer)

			if tPlayer.nObjType == gtObjType.ePlayer then
				local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
				if oPlayer then
					if self:IsNewbie() then
						--新手不计算连胜连败
						oPlayer.m_oGVGModule:AddFights(0)
					else
						oPlayer.m_oGVGModule:AddFights(1)
					end
					local tItemList = self:_gen_award_(tWinTeam, tPlayer, oPlayer, true)
					local tAtkTeamInfo, tDefTeamInfo = self:_battle_result_detail_()
					local nMultiExpFights = oPlayer.m_oGVGModule:GetMultiExpFights()

					local tSendData = {bWin=true, tItemList=tItemList
						, nAtkKills=self.m_tAtkerTeam.nTotalKills, nDefKills=self.m_tDeferTeam.nTotalKills
						, tAtkTeamInfo=tAtkTeamInfo, tDefTeamInfo=tDefTeamInfo, nMultiExpFights=nMultiExpFights, nLostFame=0}
					CmdNet.PBSrv2Clt(oPlayer:GetSession(), "BugHoleBattleResult", tSendData)
					oPlayer.m_oGVGModule:CheckDmgChange() --最高伤害变化检测
				end
			end
		end

		--失败方奖励
		local tLoseTeam = nWinCamp == gtCampType.eAttacker and self.m_tDeferTeam or self.m_tAtkerTeam
		for sCharID, tPlayer in pairs(tLoseTeam.tPlayerMap) do
			self:_cancel_relive_timer_(tPlayer)

			if tPlayer.nObjType == gtObjType.ePlayer then
				local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
				if oPlayer then
					if self:IsNewbie() then
						--新手不计算连胜连败
						oPlayer.m_oGVGModule:AddFights(0)
					else
						oPlayer.m_oGVGModule:AddFights(2)
					end
					local tItemList, nLostFame = self:_gen_award_(tLoseTeam, tPlayer, oPlayer, false)
					local tAtkTeamInfo, tDefTeamInfo = self:_battle_result_detail_()
					local nMultiExpFights = oPlayer.m_oGVGModule:GetMultiExpFights()

					local tSendData = {bWin=false, tItemList=tItemList
						, nAtkKills=self.m_tAtkerTeam.nTotalKills, nDefKills=self.m_tDeferTeam.nTotalKills
						, tAtkTeamInfo=tAtkTeamInfo, tDefTeamInfo=tDefTeamInfo, nMultiExpFights=nMultiExpFights, nLostFame=nLostFame}
					CmdNet.PBSrv2Clt(oPlayer:GetSession(), "BugHoleBattleResult", tSendData)
					oPlayer.m_oGVGModule:CheckDmgChange() --最高伤害变化检测
				end
			end
		end

	end
	self.m_oBugHoleMgr:OnBattleResult(self, nWinCamp)
	goLogger:EventLog(gtEvent.eBugHoleEnd, nil, self.m_nRoomID, self:GetAtkerCount(), self:GetDeferCount(), self:GetAtkerRealCount(), self:GetDeferRealCount(), nWinCamp)
end

function CBugHoleRoom:_sync_kills_(tSrcPlayer, nSrcCamp, tTarPlayer, nTarCamp, nArmID, nArmType)
	local nAtkKills, nDefKills = self.m_tAtkerTeam.nTotalKills, self.m_tDeferTeam.nTotalKills
	local sAtkName, sDefName = tSrcPlayer.sName, tTarPlayer.sName
	local tSendData = {nAtkKills=nAtkKills, nDefKills=nDefKills, sAtkName=sAtkName, nAtkCamp=nSrcCamp, sDefName=sDefName, nDefCamp=nTarCamp, nArmID=nArmID}
	CmdNet.PBBroadcastExter(self:GetSessionList(), "BugHoleKillsInfoRet", tSendData)
	return nAtkKills, nDefKills
end

function CBugHoleRoom:_on_object_dead_(sTarObjID, nTarObjType, sAtkerID, nAtkerType, nArmID, nArmType)
	local tTarPlayer, nTarCamp, tTarTeam = self:GetPlayerData(sTarObjID)
	local tSrcPlayer, nSrcCamp, tSrcTeam = self:GetPlayerData(sAtkerID)
	if not tTarPlayer or not tSrcPlayer then
		return
	end
	local nNowSec = os.time()
	tTarPlayer.nDeadTime = nNowSec
	tTarPlayer.nDeads = tTarPlayer.nDeads + 1
	tTarPlayer.nCntKills = 0
	tTarPlayer.nLifeKills = 0
	tTarPlayer.nCntKillTime = 0

	tSrcTeam.nKillTime = nNowSec
	tSrcTeam.nTotalKills = tSrcTeam.nTotalKills + 1

	if sTarObjID == sAtkerID then
		print(tTarPlayer.sName, "自杀了")
		self:_sync_kills_(tSrcPlayer, nSrcCamp, tTarPlayer, nTarCamp, nArmID, nArmType)
	else
		tSrcPlayer.nKills = tSrcPlayer.nKills + 1
		tSrcPlayer.nLifeKills = tSrcPlayer.nLifeKills + 1
		tSrcPlayer.tWeaponKill[nArmID] = (tSrcPlayer.tWeaponKill[nArmID] or 0) + 1
		local nIndex = (#tSrcPlayer.tRecentKill % 5) + 1
		tSrcPlayer.tRecentKill[nIndex] = {sName=tTarPlayer.sName, nLevel=tTarPlayer.nLevel, nTime=nNowSec}

		if tSrcPlayer.nCntKillTime == 0 then
			tSrcPlayer.nCntKills = 1
			tSrcPlayer.nCntKillTime = nNowSec

		--5秒内算连杀
		elseif nNowSec - tSrcPlayer.nCntKillTime <= 5 then
			tSrcPlayer.nCntKills = tSrcPlayer.nCntKills + 1

		else
			tSrcPlayer.nCntKills = 0
			tSrcPlayer.nCntKillTime = 0

		end
		self:_sync_kills_(tSrcPlayer, nSrcCamp, tTarPlayer, nTarCamp, nArmID, nArmType)
		--第1血
		if tTarTeam.nTotalKills == 0 and tSrcTeam.nTotalKills == 1 then
			local tSendData = {sCharName=tSrcPlayer.sName, nCamp=nSrcCamp}
			CmdNet.PBBroadcastExter(self:GetSessionList(), "BugHoleFirstKillRet", tSendData)
		end
		--连杀
		if tSrcPlayer.nCntKills > 1 then
			local tSendData = {sCharName=tSrcPlayer.sName, nCntKills=tSrcPlayer.nCntKills, nCamp=nSrcCamp}
			CmdNet.PBBroadcastExter(self:GetSessionList(), "BugHoleCntKillRet", tSendData)
		end
		--1命击杀(暴走/超神)
		if tSrcPlayer.nLifeKills == nBAO_ZOU or tSrcPlayer.nLifeKills == nCHAO_SHEN then
			local tSendData = {sCharName=tSrcPlayer.sName, nLifeKills=tSrcPlayer.nLifeKills, nCamp=nSrcCamp}
			CmdNet.PBBroadcastExter(self:GetSessionList(), "BugHoleLifeKillRet", tSendData)
		end

		--宝箱记录击杀
		if nAtkerType == gtObjType.ePlayer then
			local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sAtkerID)
			if oPlayer then oPlayer.m_oBox:AddKills() end
		end
	end

	--被击杀信息
	if tTarPlayer.nObjType == gtObjType.ePlayer then
		local tSendData = {sKiller=tSrcPlayer.sName, nArmID=nArmID, tMyKillList={}}
		for _, v in ipairs(tTarPlayer.tRecentKill) do
			table.insert(tSendData.tMyKillList, {sCharName=v.sName, nLevel=v.nLevel, nTime=v.nTime})	
		end
		local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sTarObjID)
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "BugHoleKilledRet", tSendData)
	end

	if tSrcTeam.nTotalKills >= tEtcConf.nFinishCond then
		return self:BattleResult(nSrcCamp)	
	end
	tTarPlayer.nReliveTimer = GlobalExport.RegisterTimer(tEtcConf.nReliveTime*1000, function() self:Relive(tTarPlayer, nTarCamp) end )
end

function CBugHoleRoom:Relive(tPlayer, nCamp)
	self:_cancel_relive_timer_(tPlayer)

	if self.m_nState ~= self.tRoomState.eStart then
		return
	end

	if not tPlayer.nDeadTime then
		return
	end

	local nReliveTime = tEtcConf.nReliveTime
	if os.time() - tPlayer.nDeadTime < nReliveTime then
		return
	end
	tPlayer.nDeadTime = nil

	local nPosX, nPosY = self:_gen_born_pos_(nCamp)
	if tPlayer.nObjType == gtObjType.ePlayer then
		local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(tPlayer.sCharID)
		local oBattle = oPlayer.m_oBattle
		if oBattle:Relive(nPosX, nPosY) then
			oBattle:AddBuff(tEtcConf.InvincibleBuff)
		end

	elseif tPlayer.nObjType == gtObjType.eRobot then
		local oSRobot = goLuaSRobotMgr:GetRobot(tPlayer.sCharID)
		if oSRobot:Relive(nPosX, nPosY) then
			oSRobot:AddBuff(tEtcConf.InvincibleBuff)
		end

	end
end

function CBugHoleRoom:CancelMatchReq(oPlayer)
	if self.m_nState ~= self.tRoomState.eInit then
		return
	end
	local sCharID = oPlayer:GetCharID()
	local tPlayer = self:GetPlayerData(sCharID)
	if tPlayer.bTeam then
		for k, v in pairs(self.m_tAtkerTeam.tPlayerMap) do
			if v.bTeam and v.nObjType == gtObjType.ePlayer then
				local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(k)
				self:RemovePlayer(oPlayer)
			end
		end
	else
		self:RemovePlayer(oPlayer)
	end
end

--队伍杀敌统计
function CBugHoleRoom:TeamKillDetailReq(oPlayer)
	local sCharID = oPlayer:GetCharID()
	local tPlayer, nCamp = self:GetPlayerData(sCharID)
	if not tPlayer then
		return
	end
	local oScene = self:GetScene()
	local function _fnGetPlayerInfo(tPlayer)
		local tInfo = {}
		tInfo.nState = (tPlayer.nDeadTime or 0) > 0 and 1 or 0
		if tPlayer.nLifeKills >= nCHAO_SHEN then 
			tInfo.nState = 3
		elseif tPlayer.nLifeKills >= nBAO_ZOU then
			tInfo.nState = 2
		end
		tInfo.sName = tPlayer.sName
		tInfo.nDmg = oScene:GetCppScene():GetActorDmg(tPlayer.sCharID)
		tInfo.nKills = tPlayer.nKills
		tInfo.nDeads = tPlayer.nDeads
		tInfo.nArmID = 0
		if tPlayer.nObjType == gtObjType.ePlayer then
			local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(tPlayer.sCharID)
			if oPlayer then
				tInfo.nArmID = oPlayer.m_oBattle:GetCurrWeapon().nArmID
			end
		elseif tPlayer.nObjType == gtObjType.eRobot then
			local oSRobot = goLuaSRobotMgr:GetRobot(tPlayer.sCharID)
			if oSRobot then
				tInfo.nArmID = oSRobot:GetCurrWeapon().nArmID
			end
		end
		return tInfo
	end
	local tAtkTeamInfo = {}
	for k, v in pairs(self.m_tAtkerTeam.tPlayerMap) do
		table.insert(tAtkTeamInfo, _fnGetPlayerInfo(v))
	end
	local tDefTeamInfo = {}
	for k, v in pairs(self.m_tDeferTeam.tPlayerMap) do
		table.insert(tDefTeamInfo, _fnGetPlayerInfo(v))
	end
	local tSendData = {tAtkTeamInfo=tAtkTeamInfo, tDefTeamInfo=tDefTeamInfo}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "BugHoleTeamKillDetailRet", tSendData)
end

function CBugHoleRoom:_gen_drop_pos_(tDropPosList, tRemainPosIndex)
	local nPosIndex = 1
	if #tRemainPosIndex > 0 then
		local nRnd = math.random(1, #tRemainPosIndex)
		nPosIndex = tRemainPosIndex[nRnd]
		table.remove(tRemainPosIndex, nRnd)
	end
	return self:_gen_pos_(tDropPosList, nPosIndex)
end

--刷新BUFF掉落
function CBugHoleRoom:OnDropRefresh(tDropConf)
	assert(self.m_nState == self.tRoomState.eStart)

	local tDupConf = assert(ctGVGDupConf[self.m_nDupID])
	local tAtkIndex, tDefIndex = {}, {}
	for k = 1, #tDupConf.tDropAtk do
		table.insert(tAtkIndex, k)
	end
	for k = 1, #tDupConf.tDropDef do
		table.insert(tDefIndex, k)
	end

	local tBattle = {nType=gtBattleType.eBugHole, nCamp=gtCampType.eNeutral, tData={nRoomStage=self.m_nRoomStage, nRoomID=self.m_nRoomID}}
	for i = 1, tDropConf.nRefreshNum do
		if i <= tDropConf.nRefreshNum / 2 then
			local nPosX, nPosY = self:_gen_drop_pos_(tDupConf.tDropAtk, tAtkIndex)
			goLuaDropItemMgr:CreateDropItem(tDropConf.nID, self.m_nSceneIndex, nPosX, nPosY, tBattle)
		else
			local nPosX, nPosY = self:_gen_drop_pos_(tDupConf.tDropDef, tDefIndex)
			goLuaDropItemMgr:CreateDropItem(tDropConf.nID, self.m_nSceneIndex, nPosX, nPosY, tBattle)
		end
	end
end

function CBugHoleRoom:Offline(oPlayer)
	self:RemovePlayer(oPlayer)
end

function CBugHoleRoom:OnEnterScene(oPlayer)
	local sCharID = oPlayer:GetCharID()
	local tPlayer = assert(self:GetPlayerData(sCharID))
	local oBattle = oPlayer.m_oBattle
	local nBattleLevel = tEtcConf.nBattleLevel
	nBattleLevel = nBattleLevel > 0 and nBattleLevel or oPlayer:GetLevel()
	local tBattleAttr = oBattle:CalcBattleAttr(nBattleLevel)
	oBattle:UpdateRuntimeBattleAttr(tBattleAttr)
	oBattle:SetBattleLevel(nBattleLevel)
end

function CBugHoleRoom:OnClientSceneReady(oPlayer)
	local nRemainTime = math.max(0, self.m_nStartTime + tEtcConf.nBattleTime - os.time())
	local tSendData = {nAtkKills=self.m_tAtkerTeam.nTotalKills, nDefKills=self.m_tDeferTeam.nTotalKills, nRemainTime=nRemainTime}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "BugHoleBattleInfoRet", tSendData)
	CmdNet.PBBroadcastExter(self:GetSessionList(), "BugHolePlayerEnterRet", {sName=oPlayer:GetName()})

	if oPlayer:GetCharID() == self.m_sLeaderID then
		self:_sync_leader_()
		local oScene = self:GetScene()
		oScene:GetCppScene():StartAI()
	end
end

function CBugHoleRoom:OnLeaveScene(oPlayer)
	print("CBugHoleRoom:OnLeaveScene***")
	self:RemovePlayer(oPlayer)
	CmdNet.PBBroadcastExter(self:GetSessionList(), "BugHolePlayerQuitRet", {sName=oPlayer:GetName()})
end

function CBugHoleRoom:OnPlayerDead(oPlayer, sAtkerID, nAtkerType, nArmID, nArmType)
	if self.m_nState ~= self.tRoomState.eStart then
		return
	end
	local sCharID = oPlayer:GetCharID()
	self:_on_object_dead_(sCharID, gtObjType.ePlayer, sAtkerID, nAtkerType, nArmID, nArmType)
end

function CBugHoleRoom:OnRobotDead(oSRobot, sAtkerID, nAtkerType, nArmID, nArmType)
	if self.m_nState ~= self.tRoomState.eStart then
		return
	end
	local sObjID = oSRobot:GetObjID()
	self:_on_object_dead_(sObjID, gtObjType.eRobot, sAtkerID, nAtkerType, nArmID, nArmType)
end

function CBugHoleRoom:OnEnterBackground(oPlayer)
	print("CBugHoleRoom:OnEnterBackground***")
	if not self:IsRunning() then
		return
	end
	local sCharID = oPlayer:GetCharID()
	local tPlayerData = self:GetPlayerData(sCharID)
	if not tPlayerData then	
		return
	end
	tPlayerData.bBackground = true
	if self.m_sLeaderID == sCharID then
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "BattleLeaderSync", {bLeader=false})	--免除队长
		print("撤销队长:", oPlayer:GetName())
		
		self.m_sLeaderID = self:GenNextLeader()
		self:_sync_leader_()
	end
end

function CBugHoleRoom:OnEnterForeground(oPlayer)
	print("CBugHoleRoom:OnEnterForeground***")
	if not self:IsRunning() then
		return
	end
	local sCharID = oPlayer:GetCharID()
	local tPlayerData = self:GetPlayerData(sCharID)
	if not tPlayerData then
		return
	end
	tPlayerData.bBackground = false
	if not self.m_sLeaderID then
		self.m_sLeaderID = self:GenNextLeader()
		self:_sync_leader_()
	end
end

--发送战场表情请求
function CBugHoleRoom:OnSendBattleFaceReq(oPlayer, nFaceID)
	if not self:IsRunning() then
		return
	end
	local tSessionList = self:GetSessionList(oPlayer:GetCharID())	--不发给自己
	local tSendData = {nAOIID=oPlayer:GetAOIID(), nFaceID=nFaceID, nCamp=nCamp}
	CmdNet.PBBroadcastExter(tSessionList, "SendBattleFaceRet", tSendData)
end

--治疗请求
function CBugHoleRoom:OnCureReq(oPlayer, nAOIID, nPosX, nPosY, nAddHP)
	assert(nAddHP > 0 and nAddHP < nMAX_INTEGER, "HP非法:"..nAddHP)
	if not self:IsRunning() then
		return
	end
	local oScene = self:GetScene()
	local oCppObj = oScene:GetObj(nAOIID)
	if not oCppObj or oCppObj:IsDead() then
		print("目标不存在或已死亡")
		return
	end
	local nCurrPosX, nCurrPosY = oCppObj:GetPos()
	if not GF.AcceptableDistance(nPosX, nPosY, nCurrPosX, nCurrPosY) then
		print("位置非法")
		return
	end
	local nAttrID = gtAttrDef.eHP
	local nCurrHP = oCppObj:GetFightParam(nAttrID)
	local nNewHP = math.max(0, math.min(nMAX_INTEGER, nCurrHP + nAddHP))
	oCppObj:UpdateFightParam(nAttrID, nNewHP)
	local tSessionList = self:GetSessionList()
	CmdNet.PBBroadcastExter(tSessionList, "ActorBattleAttrSync", {nAOIID=nAOIID, tAttr={{nID=nAttrID, nVal=nNewHP}} })
end
