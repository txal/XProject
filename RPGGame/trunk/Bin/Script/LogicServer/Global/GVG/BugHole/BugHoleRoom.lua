local _abs, _sort, _insert, _random, _floor, _max, _min, _time
= math.abs, table.sort, table.insert, math.random, math.floor, math.max, math.min, os.time

--房间状态
CBugHoleRoom.tRoomState =
{
	eInit = 0,
	eStart = 1,
	eFinish = 2,
}

local nBAO_ZOU = 3	 	--暴走
local nCHAO_SHEN = 6	--超神
function CBugHoleRoom:Ctor(oBugHoleMgr, nRoomID)
	self.m_oBugHoleMgr = oBugHoleMgr
	self.m_nRoomID = nRoomID
	self.m_nSceneIndex = 0

	--tPlayerMap={[sCharID]={sCharID="",sName="",nObjType=0,nLevel=0,bTeam=false
	--,nDeads=0,nDeadTime=0,nKills=0,nLifeKills=0,nCntKills=0,nCntKillTime=0,tRecentKill={},tWeaponKill={},},}
	self.m_tAtkerTeam = {nTeamMebers=0, nRealCount=0, nCount=0, nTotalKills=0, nKillTime=0, tPlayerMap={}}
	self.m_tDeferTeam = {nTeamMebers=0, nRealCount=0, nCount=0, nTotalKills=0, nKillTime=0, tPlayerMap={}}
	self.m_sLeaderID = nil

	self.m_nState = self.tRoomState.eInit
	self.m_nCreateTime = _time()
	self.m_nStartTime = 0

	self.m_nBattleTimer = nil
	self.m_oSceneDropMaker = CSceneDropMaker:new(ctBugHoleEtc[1].nSceneDropID, self.OnDropRefresh, self)
end

function CBugHoleRoom:GetID() return self.m_nRoomID end
function CBugHoleRoom:GetState() return self.m_nState end
function CBugHoleRoom:GetCreateTime() return self.m_nCreateTime end
function CBugHoleRoom:GetScene() return goLuaSceneMgr:GetSceneByIndex(self.m_nSceneIndex) end
function CBugHoleRoom:GetAtkerCount() return self.m_tAtkerTeam.nCount end
function CBugHoleRoom:GetDeferCount() return self.m_tDeferTeam.nCount end
function CBugHoleRoom:GetAtkerRealCount() return self.m_tAtkerTeam.nRealCount end
function CBugHoleRoom:GetDeferRealCount() return self.m_tDeferTeam.nRealCount end
function CBugHoleRoom:GetNextLeader()
	if self.m_tAtkerTeam.nRealCount > 0 then
		for k, v in pairs(self.m_tAtkerTeam.tPlayerMap)	do
			if v.nObjType == gtObjType.ePlayer then
				return k
			end
		end
	end
	if self.m_tDeferTeam.nRealCount > 0 then
		for k, v in pairs(self.m_tDeferTeam.tPlayerMap)	do
			if v.nObjType == gtObjType.ePlayer then
				return k
			end
		end
	end
end

function CBugHoleRoom:GetAvgFameValue(bLevel)
	local nTotalValue, nTotalPlayer = 0, 0
	local function _fnCalcFame(sCharID)
		local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
		local oGVG = oPlayer:GetModule(CGVGModule:GetType())
		local nValue = bLevel and oGVG:GetFameLevel() or oGVG:GetFame()
		nTotalValue = nTotalValue + nValue
		nTotalPlayer = nTotalPlayer + 1
	end
	for sCharID, tPlayer in pairs(self.m_tAtkerTeam.tPlayerMap) do
		if tPlayer.nObjType == gtObjType.ePlayer then
			_fnCalcFame(sCharID)
		end
	end
	for sCharID, tPlayer in pairs(self.m_tDeferTeam.tPlayerMap) do
		if tPlayer.nObjType == gtObjType.ePlayer then
			_fnCalcFame(sCharID)
		end
	end
	local nAverageValue = _floor(nTotalValue / _max(1, nTotalPlayer))
	return nAverageValue
end

function CBugHoleRoom:GetPlayerData(sCharID)
	if self.m_tAtkerTeam.tPlayerMap[sCharID] then
		return self.m_tAtkerTeam.tPlayerMap[sCharID], gtCampType.eAttacker

	elseif self.m_tDeferTeam.tPlayerMap[sCharID] then
		return self.m_tDeferTeam.tPlayerMap[sCharID], gtCampType.eDefender

	end
end

function CBugHoleRoom:GetSessionList(nCamp)
	local tSessionList = {}
	if not nCamp or nCamp == gtCampType.eAttacker then
		for sCharID, tPlayer in pairs(self.m_tAtkerTeam.tPlayerMap) do
			if tPlayer.nObjType == gtObjType.ePlayer then
				local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
				_insert(tSessionList, oPlayer:GetSession())
			end
		end
	end

	if not nCamp or nCamp == gtCampType.eDefender then
		for sCharID, tPlayer in pairs(self.m_tDeferTeam.tPlayerMap) do
			if tPlayer.nObjType == gtObjType.ePlayer then
				local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
				_insert(tSessionList, oPlayer:GetSession())
			end
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
	local tPlayer = {sCharID=sCharID, sName=sName, nObjType=gtObjType.ePlayer, nLevel=nLevel, bTeam=bTeam
	, nDeads=0, nDeadTime=0, nKills=0, nLifeKills=0, nCntKills=0, nCntKillTime=0
	, tRecentKill={}, tWeaponKill={}}

	local tTeam = nCamp==gtCampType.eAttacker and self.m_tAtkerTeam or self.m_tDeferTeam
	tTeam.tPlayerMap[sCharID] = tPlayer
	tTeam.nCount = tTeam.nCount + 1
	tTeam.nRealCount = tTeam.nRealCount + 1
	if bTeam then
		tTeam.nTeamMebers = tTeam.nTeamMebers + 1
	end
end

function CBugHoleRoom:_sync_leader()
	if not self.m_sLeaderID then
		return
	end
	local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(self.m_sLeaderID)
	if not oPlayer then
		return
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "BattleLeaderSync", {})
end

function CBugHoleRoom:_gen_pos(tPosList, nIndex)
	local tDupConf = assert(ctGVGDupConf[ctBugHoleEtc[1].nDupID])
	local tSceneConf = assert(ctSceneConf[tDupConf.nSceneID])

	local tPos = assert(tPosList[nIndex])
	local nCenterX, nCenterY, nRadius = table.unpack(tPos)

	local tAOI = gtSceneDef.tAOI
	local nPosX, nPosY = tAOI.eUnitWidth / 2, tAOI.eUnitHeight / 2
	for i = 1, 16 do
		local nTmpX = _random(nCenterX - nRadius, nCenterX + nRadius)
		local nTmpY = _random(nCenterY - nRadius, nCenterY + nRadius)
		if not GlobalExport.IsBlockUnit(tSceneConf.nMapID, nTmpX, nTmpY) then
			nPosX = (_floor(nTmpX / tAOI.eUnitWidth) + 0.5) * tAOI.eUnitWidth
			nPosY = (_floor(nTmpY / tAOI.eUnitHeight) + 0.5) * tAOI.eUnitHeight
			break
		end
	end
	return _max(0, nPosX), _max(0, nPosY)
end

function CBugHoleRoom:_gen_born_pos(nCamp, nNum)
	assert(nCamp, "_gen_born_pos阵营不能为空")
	local tDupConf = assert(ctGVGDupConf[ctBugHoleEtc[1].nDupID])
	local tBornPosList = nCamp==gtCampType.eAttacker and tDupConf.tBornAtk or tDupConf.tBornDef
	local nIndex = nNum or _random(1, #tBornPosList)
	nIndex = _min(nIndex, #tBornPosList)
	return self:_gen_pos(tBornPosList, nIndex)
end

function CBugHoleRoom:_gen_drop_pos(nCamp)
	assert(nCamp, "_gen_drop_pos阵营不能为空")
	local tDupConf = assert(ctGVGDupConf[ctBugHoleEtc[1].nDupID])
	local tDropPosList = nCamp==gtCampType.eAttacker and tDupConf.tDropAtk or tDupConf.tDropDef
	local nIndex = _random(1, #tDropPosList)
	return self:_gen_pos(tDropPosList, nIndex)
end

function CBugHoleRoom:JoinRoom(oPlayer, nCamp, bTeam)
	if self.m_nState == self.tRoomState.eFinish then
		return
	end
	local tTeam = nCamp==gtCampType.eAttacker and self.m_tAtkerTeam or self.m_tDeferTeam
	if tTeam.nCount >= ctBugHoleEtc[1].nTeamPlayer then
		return
	end
	local oBattle = oPlayer:GetModule(CBattle:GetType())
	if oBattle:IsBattling() then
		return
	end
	self:CreatePlayer(oPlayer, nCamp, bTeam)
	local tData = {nRoomID = self.m_nRoomID}
	if self.m_nState == self.tRoomState.eStart then
		local nPosX, nPosY = self:_gen_born_pos(nCamp)
		oBattle:EnterScene(self.m_nSceneIndex, gtBattleType.eBugHole, nCamp, tData, nPosX, nPosY)	
	else
		oBattle:SetBattleType(gtBattleType.eBugHole, nCamp, tData)
	end
	if not self.m_sLeaderID then
		self.m_sLeaderID = oPlayer:GetCharID()
	end
	return true
end

function CBugHoleRoom:_create_robot(nCamp, nAvgFameLevel)
	local tTeam = nCamp == gtCampType.eAttacker and self.m_tAtkerTeam or self.m_tDeferTeam
	local nPosX, nPosY = self:_gen_born_pos(nCamp, tTeam.nCount + 1)
	local tRobotGroup = GetRobotGroupByFameLevel(nAvgFameLevel)
	assert(#tRobotGroup > 0, "机器人配置错误")
	local nRnd = _random(1, #tRobotGroup)
	local tRobotConf = tRobotGroup[nRnd]
	local oSRobot = goLuaSRobotMgr:CreateRobot(tRobotConf.nID, self.m_nSceneIndex, nPosX, nPosY, gtBattleType.eBugHole, nCamp, {nRoomID=self.m_nRoomID})

	local tPlayer = {sCharID=oSRobot:GetObjID(), sName=oSRobot:GetName(), nObjType=gtObjType.eRobot, nLevel=tRobotConf.nLevel, bTeam=false
	, nDeads=0, nDeadTime=0, nKills=0, nLifeKills=0, nCntKills=0, nCntKillTime=0
	, tRecentKill={}, tWeaponKill={}}

	tTeam.tPlayerMap[tPlayer.sCharID] = tPlayer
	tTeam.nCount = tTeam.nCount + 1

	return oSRobot
end

function CBugHoleRoom:StartRun(nGmAtkNum, nGmDefNum)
	assert(self.m_nState == self.tRoomState.eInit)
	if self.m_tAtkerTeam.nCount <= 0 and self.m_tDeferTeam.nCount <= 0 then
		return
	end

	local tDupConf = assert(ctGVGDupConf[ctBugHoleEtc[1].nDupID])
	local oScene = goLuaSceneMgr:CreateScene(tDupConf.nSceneID, gtBattleType.eBugHole)
	self.m_nSceneIndex = oScene:GetSceneIndex()

	self.m_nState = self.tRoomState.eStart
	self.m_nStartTime = _time()
	
	local nNum = 0 
	local tAtkerList, tDeferList = {}, {}
	for sCharID, tPlayer in pairs(self.m_tAtkerTeam.tPlayerMap) do
		nNum = nNum + 1
		local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
		local oBattle = oPlayer:GetModule(CBattle:GetType())
		local nPosX, nPosY = self:_gen_born_pos(gtCampType.eAttacker, nNum)
		oBattle:EnterScene(self.m_nSceneIndex, gtBattleType.eBugHole, gtCampType.eAttacker, {nRoomID=self.m_nRoomID}, nPosX, nPosY)	

		_insert(tAtkerList, {sCharName=oPlayer:GetName(), nLevel=oPlayer:GetLevel()})
	end

	nNum = 0
	for sCharID, tPlayer in pairs(self.m_tDeferTeam.tPlayerMap) do
		nNum = nNum + 1
		local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
		local oBattle = oPlayer:GetModule(CBattle:GetType())
		local nPosX, nPosY = self:_gen_born_pos(gtCampType.eDefender, nNum)
		oBattle:EnterScene(self.m_nSceneIndex, gtBattleType.eBugHole, gtCampType.eDefender, {nRoomID=self.m_nRoomID}, nPosX, nPosY)	

		_insert(tDeferList, {sCharName=oPlayer:GetName(), nLevel=oPlayer:GetLevel()})
	end

	--GM
	if nGmAtkNum and nGmDefNum then
		local nAvgFameLevel = self:GetAvgFameValue(true)
		for k = 1, nGmAtkNum - self.m_tAtkerTeam.nCount do
			local oSRobot = self:_create_robot(gtCampType.eAttacker, nAvgFameLevel)
			_insert(tAtkerList, {sCharName=oSRobot:GetName(), nLevel=oSRobot:GetLevel()})
		end

		for k = 1, nGmDefNum - self.m_tDeferTeam.nCount do
			local oSRobot = self:_create_robot(gtCampType.eDefender, nAvgFameLevel)
			_insert(tDeferList, {sCharName=oSRobot:GetName(), nLevel=oSRobot:GetLevel()})
		end
	else
	--生产NPC(5v5)
		local nAvgFameLevel = self:GetAvgFameValue(true)
		for k = 1, ctBugHoleEtc[1].nTeamPlayer - self.m_tAtkerTeam.nCount do
			local oSRobot = self:_create_robot(gtCampType.eAttacker, nAvgFameLevel)
			_insert(tAtkerList, {sCharName=oSRobot:GetName(), nLevel=oSRobot:GetLevel()})
		end

		for k = 1, ctBugHoleEtc[1].nTeamPlayer - self.m_tDeferTeam.nCount do
			local oSRobot = self:_create_robot(gtCampType.eDefender, nAvgFameLevel)
			_insert(tDeferList, {sCharName=oSRobot:GetName(), nLevel=oSRobot:GetLevel()})
		end
	end

	self.m_nBattleTimer = GlobalExport.RegisterTimer(ctBugHoleEtc[1].nBattleTime*1000, function() self:BattleTimeOut() end )
	goLogger:EventLog(gtEvent.eBugHoleStart, nil, self.m_nRoomID, self:GetAtkerCount(), self:GetDeferCount(), self:GetAtkerRealCount(), self:GetDeferRealCount())

	local tSessionList = self:GetSessionList()
	local tSendData = {tAtkerList=tAtkerList, tDeferList=tDeferList}
	CmdNet.PBBroadcastExter(tSessionList, "BugHoleTeamInfoRet", tSendData)

	--战场掉落
	self.m_oSceneDropMaker:Start()
end

function CBugHoleRoom:_cancel_relive_timer(tPlayer)
	if tPlayer.nReliveTimer then
		GlobalExport.CancelTimer(tPlayer.nReliveTimer)
		tPlayer.nReliveTimer = nil
	end
end

function CBugHoleRoom:RemovePlayer(oPlayer)
	local sCharID = oPlayer:GetCharID()
	local oBattle = oPlayer:GetModule(CBattle:GetType())
	local nBattleType, nBattleCamp = oBattle:GetBattleType()
	assert(nBattleType == gtBattleType.eBugHole)

	local tTeam = nBattleCamp==gtCampType.eAttacker and self.m_tAtkerTeam or self.m_tDeferTeam
	if not tTeam.tPlayerMap[sCharID] then
		return
	end

	self:_cancel_relive_timer(tTeam.tPlayerMap[sCharID])
	tTeam.tPlayerMap[sCharID] = nil
	tTeam.nCount = tTeam.nCount - 1
	tTeam.nRealCount = tTeam.nRealCount - 1
	oBattle:SetBattleType(0, 0)

	--强退惩罚
	if self.m_nState == self.tRoomState.eStart then
		local nGold = oPlayer:GetGold()
		local nSubNum = _min(10000, _floor(nGold * 0.01))
		if nSubNum > 0 then
			oPlayer:SubGold(nSubNum, gtReason.eBugHolePunish)
			local sCont = string.format(ctLang[18], nSubNum)
			oPlayer:ScrollMsg(sCont)
			print(oPlayer:GetName(), sCont)
		end
	end

	if self.m_sLeaderID == sCharID then
		self.m_sLeaderID = self:GetNextLeader()
		self:_sync_leader()
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
				self:_judge_battle_result()
			end
			
		end

	elseif nAtkerCount <= 0 and nDeferCount <= 0 then
		self:BattleResult(0)

	end
end

function CBugHoleRoom:OnEnterScene(oPlayer)
	local sCharID = oPlayer:GetCharID()
	local tPlayer = assert(self:GetPlayerData(sCharID))
	local oBattle = oPlayer:GetModule(CBattle:GetType())
	local nBattleLevel = ctBugHoleEtc[1].nBattleLevel
	local tBattleAttr = oBattle:CalcBattleAttr(nBattleLevel)
	oBattle:UpdateRuntimeBattleAttr(tBattleAttr)
	oBattle:SetBattleLevel(nBattleLevel)
end

function CBugHoleRoom:AfterEnterScene(oPlayer)
end

function CBugHoleRoom:ClientSceneReady(oPlayer)
	local nRemainTime = _max(0, self.m_nStartTime + ctBugHoleEtc[1].nBattleTime - _time())
	local tSendData = {nAtkKills=self.m_tAtkerTeam.nTotalKills, nDefKills=self.m_tDeferTeam.nTotalKills, nRemainTime=nRemainTime}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "BugHoleBattleInfoRet", tSendData)
	CmdNet.PBBroadcastExter(self:GetSessionList(), "BugHolePlayerEnterRet", {sName=oPlayer:GetName()})

	if oPlayer:GetCharID() == self.m_sLeaderID then
		self:_sync_leader()

		local oScene = self:GetScene()
		oScene:GetCppScene():StartAI()
	end
end

function CBugHoleRoom:Offline(oPlayer)
	self:RemovePlayer(oPlayer)
end

function CBugHoleRoom:OnLeaveScene(oPlayer)
	self:RemovePlayer(oPlayer)
	CmdNet.PBBroadcastExter(self:GetSessionList(), "BugHolePlayerQuitRet", {sName=oPlayer:GetName()})
end

function CBugHoleRoom:_judge_battle_result()
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
	self:_judge_battle_result()
end

function CBugHoleRoom:_gen_award_(tTeam, tPlayer, oPlayer, bWin)
	local tDropItem = {}
	--掉落
	if bWin then
		local nFameLevel = oPlayer.m_oGVGModule:GetFameLevel()
		local tLevelConf = assert(ctGVGFameLevelConf[nFameLevel])
		tDropItem = DropMgr:GenDropItem(tLevelConf.nDropID)
	end

	--声望
	local tEtcConf = assert(ctBugHoleEtc[1])
	local tFame = bWin and tEtcConf.tWinFame[1] or tEtcConf.tLoseFame[1]
	local nFameID, nFameNum = table.unpack(tFame)
	if bWin then
		_insert(tDropItem, {gtObjType.eProp, nFameID, nFameNum})
	else
		oPlayer.m_oGVGModule:SubFame(nFameNum, gtReason.eBugHoleSubFame)
	end

	--经验
	local nTeamExpAdd = 1
	if tTeam.nTeamMebers > 1 and tPlayer.bTeam then
		nTeamExpAdd = 1 + tEtcConf.nTeamExpAdd * 0.0001
	end
	local nDailyFightsExpAdd = 1
	local nMultExpDailyFights = tEtcConf.nMultExpDailyFights
	local nDailyFights = oPlayer.m_oGVGModule:GetFights()
	if nDailyFights <= nMultExpDailyFights then
		nDailyFightsExpAdd = 10
	end

	local tExpBase = bWin and tEtcConf.tWinExpBase[1] or tEtcConf.tLoseExpBase[1]
	local nExpID, nExpBase = table.unpack(tExpBase)
	local nExpNum = _floor(nDailyFightsExpAdd * nTeamExpAdd * nExpBase * tPlayer.nKills / (tPlayer.nKills + 10) * 2)
	if nExpNum > 0 then
		_insert(tDropItem, {gtObjType.eProp, nExpID, nExpNum})
	end

	local tItemList = {}
	for _, tItem in ipairs(tDropItem) do
		local nType, nID, nNum = table.unpack(tItem)
		local tList = oPlayer:AddItem(nType, nID, nNum, gtReason.eBugHoleAward)
		local oArm 
		if nType == gtObjType.eArm then
			oArm = #tList > 0 and tList[1][2] or nil
		end
		local nColor = GetItemColor(nType, nID, oArm)	
		_insert(tItemList, {nType=nType, nID=nID, nNum=nNum, nColor=nColor})
	end
	return tItemList
end

--战斗结果详细
function CBugHoleRoom:_battle_result_detail()
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
						tInfo.nArmID = oPlayer:GetModule(CBattle:GetType()):GetCurrWeapon()
					end
				elseif tPlayer.nObjType == gtObjType.eRobot then
					local oSRobot = goLuaSRobotMgr:GetRobot(tPlayer.sCharID)
					if oSRobot then
						tInfo.nArmID = oSRobot:GetCurrWeapon()
					end
				end
			end
			return tInfo
		end
		self.tAtkTeamInfo = {}
		for k, v in pairs(self.m_tAtkerTeam.tPlayerMap) do
			_insert(self.tAtkTeamInfo, _fnGetPlayerInfo(v))
		end
		self.tDefTeamInfo = {}
		for k, v in pairs(self.m_tDeferTeam.tPlayerMap) do
			_insert(self.tDefTeamInfo, _fnGetPlayerInfo(v))
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
			GlobalExport.RegisterTimer(ctBugHoleEtc[1].nExitTime * 1000, function() oScene:KickAllPlayer() end)
		end

		--胜利方奖励
		local tWinTeam = nWinCamp == gtCampType.eAttacker and self.m_tAtkerTeam or self.m_tDeferTeam
		for sCharID, tPlayer in pairs(tWinTeam.tPlayerMap) do
			self:_cancel_relive_timer(tPlayer)

			if tPlayer.nObjType == gtObjType.ePlayer then
				local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
				oPlayer.m_oGVGModule:AddFights()
				local tItemList = self:_gen_award_(tWinTeam, tPlayer, oPlayer, true)
				local tAtkTeamInfo, tDefTeamInfo = self:_battle_result_detail()

				local tSendData = {bWin=true, tItemList=tItemList
				, nAtkKills=self.m_tAtkerTeam.nTotalKills, nDefKills=self.m_tDeferTeam.nTotalKills
				, tAtkTeamInfo=tAtkTeamInfo, tDefTeamInfo=tDefTeamInfo}
				CmdNet.PBSrv2Clt(oPlayer:GetSession(), "BugHoleBattleResult", tSendData)
			end
		end

		--失败方奖励
		local tLoseTeam = nWinCamp == gtCampType.eAttacker and self.m_tDeferTeam or self.m_tAtkerTeam
		for sCharID, tPlayer in pairs(tLoseTeam.tPlayerMap) do
			self:_cancel_relive_timer(tPlayer)

			if tPlayer.nObjType == gtObjType.ePlayer then
				local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
				oPlayer.m_oGVGModule:AddFights()
				local tItemList = self:_gen_award_(tLoseTeam, tPlayer, oPlayer, false)
				local tAtkTeamInfo, tDefTeamInfo = self:_battle_result_detail()

				local tSendData = {bWin=false, tItemList=tItemList
				, nAtkKills=self.m_tAtkerTeam.nTotalKills, nDefKills=self.m_tDeferTeam.nTotalKills
				, tAtkTeamInfo=tAtkTeamInfo, tDefTeamInfo=tDefTeamInfo}
				CmdNet.PBSrv2Clt(oPlayer:GetSession(), "BugHoleBattleResult", tSendData)
			end
		end

	end
	self.m_oBugHoleMgr:OnBattleResult(self.m_nRoomID, nWinCamp)
	goLogger:EventLog(gtEvent.eBugHoleEnd, nil, self.m_nRoomID, self:GetAtkerCount(), self:GetDeferCount(), self:GetAtkerRealCount(), self:GetDeferRealCount(), nWinCamp)
end

function CBugHoleRoom:_sync_kills(tSrcPlayer, nSrcCamp, tTarPlayer, nTarCamp, nArmID, nArmType)
	local nAtkKills, nDefKills = self.m_tAtkerTeam.nTotalKills, self.m_tDeferTeam.nTotalKills
	local sAtkName, sDefName = tSrcPlayer.sName, tTarPlayer.sName
	local tSendData = {nAtkKills=nAtkKills, nDefKills=nDefKills, sAtkName=sAtkName, nAtkCamp=nSrcCamp, sDefName=sDefName, nDefCamp=nTarCamp, nArmID=nArmID}
	CmdNet.PBBroadcastExter(self:GetSessionList(), "BugHoleKillsInfoRet", tSendData)
	return nAtkKills, nDefKills
end

function CBugHoleRoom:_on_object_dead(sTarObjID, nTarObjType, sAtkerID, nAtkerType, nArmID, nArmType)
	local tPlayer, nCamp = assert(self:GetPlayerData(sTarObjID))
	tPlayer.nDeadTime = _time()
	tPlayer.nDeads = tPlayer.nDeads + 1
	tPlayer.nLifeKills = 0
	tPlayer.nCntKills = 0
	tPlayer.nCntKillTime = 0

	local tTeam = nCamp == gtCampType.eAttacker and self.m_tAtkerTeam or self.m_tDeferTeam
	local nSrcCamp = nCamp == gtCampType.eAttacker and gtCampType.eDefender or gtCampType.eAttacker
	local tSrcTeam = nCamp == gtCampType.eAttacker and self.m_tDeferTeam or self.m_tAtkerTeam

	tSrcTeam.nTotalKills = tSrcTeam.nTotalKills + 1
	tSrcTeam.nKillTime = _time()

	local tSrcPlayer
	if sTarObjID == sAtkerID then
		print(tPlayer.sName, "自杀了")
		self:_sync_kills(tPlayer, nCamp, tPlayer, nCamp, nArmID, nArmType)
		tSrcPlayer = tPlayer
	else
		tSrcPlayer = tSrcTeam.tPlayerMap[sAtkerID]
		tSrcPlayer.nKills = tSrcPlayer.nKills + 1
		tSrcPlayer.nLifeKills = tSrcPlayer.nLifeKills + 1
		tSrcPlayer.tWeaponKill[nArmID] = (tSrcPlayer.tWeaponKill[nArmID] or 0) + 1
		local nIndex = (#tSrcPlayer.tRecentKill % 5) + 1
		tSrcPlayer.tRecentKill[nIndex] = {sName=tPlayer.sName, nLevel=tPlayer.nLevel, nTime=_time()}

		if tSrcPlayer.nCntKillTime == 0 then
			tSrcPlayer.nCntKills = 1
			tSrcPlayer.nCntKillTime = _time()

		elseif _time() - tSrcPlayer.nCntKillTime <= 5 then
			tSrcPlayer.nCntKills = tSrcPlayer.nCntKills + 1

		else
			tSrcPlayer.nCntKills = 0
			tSrcPlayer.nCntKillTime = 0

		end
		self:_sync_kills(tSrcPlayer, nSrcCamp, tPlayer, nCamp, nArmID, nArmType)
		--1血
		if tTeam.nTotalKills == 0 and tSrcTeam.nTotalKills == 1 then
			local tSendData = {sCharName=tSrcPlayer.sName, nCamp=nSrcCamp}
			CmdNet.PBBroadcastExter(self:GetSessionList(), "BugHoleFirstKillRet", tSendData)
		end
		--连杀
		if tSrcPlayer.nCntKills > 1 then
			local tSendData = {sCharName=tSrcPlayer.sName, nCntKills=tSrcPlayer.nCntKills, nCamp=nSrcCamp}
			CmdNet.PBBroadcastExter(self:GetSessionList(), "BugHoleCntKillRet", tSendData)
		end
		--1命击杀(超神/暴走)
		if tSrcPlayer.nLifeKills == nBAO_ZOU or tSrcPlayer.nLifeKills == nCHAO_SHEN then
			local tSendData = {sCharName=tSrcPlayer.sName, nLifeKills=tSrcPlayer.nLifeKills, nCamp=nSrcCamp}
			CmdNet.PBBroadcastExter(self:GetSessionList(), "BugHoleLifeKillRet", tSendData)
		end
	end

	--被击杀信息
	if tPlayer.nObjType == gtObjType.ePlayer then
		local tSendData = {sKiller=tSrcPlayer.sName, nArmID=nArmID, tMyKillList={}}
		for _, v in ipairs(tPlayer.tRecentKill) do
			_insert(tSendData.tMyKillList, {sCharName=v.sName, nLevel=v.nLevel, nTime=v.nTime})	
		end
		local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sTarObjID)
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "BugHoleKilledRet", tSendData)
	end

	if tSrcTeam.nTotalKills >= ctBugHoleEtc[1].nFinishCond then
		return self:BattleResult(nSrcCamp)	
	end
	tPlayer.nReliveTimer = GlobalExport.RegisterTimer(ctBugHoleEtc[1].nReliveTime*1000, function() self:Relive(tPlayer, nCamp) end )
end

function CBugHoleRoom:OnPlayerDead(oPlayer, sAtkerID, nAtkerType, nArmID, nArmType)
	if self.m_nState ~= self.tRoomState.eStart then
		return
	end
	local sCharID = oPlayer:GetCharID()
	self:_on_object_dead(sCharID, gtObjType.ePlayer, sAtkerID, nAtkerType, nArmID, nArmType)
end

function CBugHoleRoom:OnRobotDead(oSRobot, sAtkerID, nAtkerType, nArmID, nArmType)
	if self.m_nState ~= self.tRoomState.eStart then
		return
	end
	local sObjID = oSRobot:GetObjID()
	self:_on_object_dead(sObjID, gtObjType.eRobot, sAtkerID, nAtkerType, nArmID, nArmType)
end

function CBugHoleRoom:Relive(tPlayer, nCamp)
	self:_cancel_relive_timer(tPlayer)

	if self.m_nState ~= self.tRoomState.eStart then
		return
	end

	if not tPlayer.nDeadTime then
		return
	end

	local nReliveTime = ctBugHoleEtc[1].nReliveTime
	if _time() - tPlayer.nDeadTime < nReliveTime then
		return
	end
	tPlayer.nDeadTime = nil

	local nPosX, nPosY = self:_gen_born_pos(nCamp)
	if tPlayer.nObjType == gtObjType.ePlayer then
		local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(tPlayer.sCharID)
		local oBattle = oPlayer:GetModule(CBattle:GetType())
		if oBattle:Relive(nPosX, nPosY) then
			oBattle:AddBuff(ctBugHoleEtc[1].InvincibleBuff)
		end

	elseif tPlayer.nObjType == gtObjType.eRobot then
		local oSRobot = goLuaSRobotMgr:GetRobot(tPlayer.sCharID)
		if oSRobot:Relive(nPosX, nPosY) then
			oSRobot:AddBuff(ctBugHoleEtc[1].InvincibleBuff)
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
				tInfo.nArmID = oPlayer:GetModule(CBattle:GetType()):GetCurrWeapon()
			end
		elseif tPlayer.nObjType == gtObjType.eRobot then
			local oSRobot = goLuaSRobotMgr:GetRobot(tPlayer.sCharID)
			if oSRobot then
				tInfo.nArmID = oSRobot:GetCurrWeapon()
			end
		end
		return tInfo
	end
	local tAtkTeamInfo = {}
	for k, v in pairs(self.m_tAtkerTeam.tPlayerMap) do
		_insert(tAtkTeamInfo, _fnGetPlayerInfo(v))
	end
	local tDefTeamInfo = {}
	for k, v in pairs(self.m_tDeferTeam.tPlayerMap) do
		_insert(tDefTeamInfo, _fnGetPlayerInfo(v))
	end
	local tSendData = {tAtkTeamInfo=tAtkTeamInfo, tDefTeamInfo=tDefTeamInfo}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "BugHoleTeamKillDetailRet", tSendData)
end

--刷新BUFF掉落
function CBugHoleRoom:OnDropRefresh(tDropConf)
	assert(self.m_nState == self.tRoomState.eStart)
	for i = 1, tDropConf.nRefreshNum do
		if i <= tDropConf.nRefreshNum / 2 then
			local nPosX, nPosY = self:_gen_drop_pos(gtCampType.eAttacker)
			goLuaDropItemMgr:CreateDropItem(tDropConf.nID, self.m_nSceneIndex, nPosX, nPosY, gtBattleType.eBugHole, gtCampType.eNeutral, {nRoomID=self.m_nRoomID})
		else
			local nPosX, nPosY = self:_gen_drop_pos(gtCampType.eDefender)
			goLuaDropItemMgr:CreateDropItem(tDropConf.nID, self.m_nSceneIndex, nPosX, nPosY, gtBattleType.eBugHole, gtCampType.eNeutral, {nRoomID=self.m_nRoomID})
		end
	end
end