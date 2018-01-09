local _abs, _sort, _insert, _random, _floor, _max, _min, _time
= math.abs, table.sort, table.insert, math.random, math.floor, math.max, math.min, os.time

function CBugStormMgr:Ctor()
	self.m_tRoomMap = {}
end

function CBugStormMgr:CreateRoom(nRoomID)
	local nRoomID = nRoomID or goBattleMgr:MakeRoomID()
	assert(not self.m_tRoomMap[nRoomID])
	local oRoom = CBugStormRoom:new(self, nRoomID)
	self.m_tRoomMap[nRoomID] = oRoom
	return oRoom
end

function CBugStormMgr:GetRoom(nRoomID)
	return self.m_tRoomMap[nRoomID]
end

function CBugStormMgr:Offline(oPlayer, tData)
	local sCharID = oPlayer:GetCharID()
	local oRoom = self.m_tRoomMap[tData.nRoomID]
	if oRoom then
		oRoom:Offline(oPlayer)
	end
end

function CBugStormMgr:OnBattleResult(nRoomID, bWin)
	local oRoom = self.m_tRoomMap[nRoomID]
	if not oRoom then
		return
	end
	self.m_tRoomMap[nRoomID] = nil
	print("CBugStormMgr:BattleResult***", nRoomID, bWin)

	local tEtcConf = assert(ctBugStormEtc[1])
	if bWin then
		for sCharID, tPlayer in pairs(oRoom.m_tPlayerMap) do
			local tItemList = {}
			local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
			local oGVEModule = oPlayer:GetModule(CGVEModule:GetType())
			oGVEModule:OnBattleResult(bWin)
			--掉落奖励
			local nFameLevel = oGVEModule:GetFameLevel()
			local tLevelConf = assert(ctGVEFameLevelConf[nFameLevel])
			local tDropItem = DropMgr:GenDropItem(tLevelConf.nDropID)
			--玩家经验
			local nLevel = oPlayer:GetLevel()
			local nRound, nPassTimes = oGVEModule:GetRoundInfo()
			local nFixVal = nRound <= 2 and 1 or 0.25
			local nExp = _floor((nLevel * 10 + 5) * (1 + nPassTimes * 0.5) * nFixVal)
			_insert(tDropItem, {gtObjType.eProp, tEtcConf.nExpProp, nExp})
			--获得挑战声望
			local nFame = _random(80, 120)
			_insert(tDropItem, {gtObjType.eProp, tEtcConf.nFameProp, nFame})

			for _, tItem in ipairs(tDropItem) do
				local nType, nID, nNum = table.unpack(tItem)
				if nType > 0 and nID > 0 and nNum > 0 then
					oPlayer:AddItem(nType, nID, nNum, gtReason.eBugStormAward)
					_insert(tItemList, {nType=nType, nID=nID, nNum=nNum})
				end
			end	
			CmdNet.PBSrv2Clt(oPlayer:GetSession(), "BugStormBattleResult", {bWin=true, tItemList=tItemList})
		end
	else
		local tSessionList = oRoom:GetSessionList()
		CmdNet.PBBroadcastExter(tSessionList, "BugStormBattleResult", {bWin=false, tItemList={}})
	end

	local oScene = oRoom:GetScene()
	if oScene then
		GlobalExport.RegisterTimer(tEtcConf.nExitTime*1000, function() oScene:KickAllPlayer() end)
	end
end

function CBugStormMgr:OnEnterScene(oPlayer, tData)
	local oRoom = self.m_tRoomMap[tData.nRoomID]
	if oRoom then
		oRoom:OnEnterScene(oPlayer)
	end
end	

function CBugStormMgr:AfterEnterScene(oPlayer, tData)
	local oRoom = self.m_tRoomMap[tData.nRoomID]
	if oRoom then
		oRoom:AfterEnterScene(oPlayer)
	end
end	

function CBugStormMgr:OnLeaveScene(oPlayer, tData)
	local oRoom = self.m_tRoomMap[tData.nRoomID]
	if oRoom then
		oRoom:OnLeaveScene(oPlayer)
	end
end

function CBugStormMgr:OnPlayerDead(oPlayer, sAtkerID, nAtkerType, nArmID, nArmType, tData)
	local oRoom = self.m_tRoomMap[tData.nRoomID]	
	if oRoom then
		oRoom:OnPlayerDead(oPlayer)
	end
end

function CBugStormMgr:OnMonsterDead(oMonster, sAtkerID, nAtkerType, nArmID, nArmType, tData)
	local oRoom = self.m_tRoomMap[tData.nRoomID]	
	if oRoom then
		oRoom:OnMonsterDead(oMonster, sAtkerID, nAtkerType)
	end
end

function CBugStormMgr:OnReliveReq(oPlayer, nRoomID)
	local oRoom = self.m_tRoomMap[nRoomID]	
	if oRoom then
		oRoom:OnReliveReq(oPlayer)
	end
end

--排序函数
local function _fn_room_sort(tRoom1, tRoom2)
	if tRoom1.nLevelDiff == tRoom2.nLevelDiff then
		if tRoom1.nPeople == tRoom2.nPeople then
			return tRoom1.nCreateTime < tRoom2.nCreateTime
		else
			return tRoom1.nPeople < tRoom2.nPeople
		end
	end
	return tRoom1.nLevelDiff < tRoom2.nLevelDiff
end

function CBugStormMgr:RoomSelect(oPlayer)
	local oGVE = oPlayer:GetModule(CGVEModule:GetType())
	local nFameLevel = oGVE:GetFameLevel()

	local tRoomList = {}
	local nMaxPlayer = ctBugStormEtc[1].nRoomPlayer
	for nRoomID, oRoom in pairs(self.m_tRoomMap) do
		if oRoom:GetState() ~= CBugStormRoom.tRoomState.eFinish then
			local nPlayerCount = oRoom:GetPlayerCount()
			if nPlayerCount < nMaxPlayer then
				_insert(tRoomList, {oRoom=oRoom, nCreateTime=oRoom:GetCreateTime(), nPeople=nPlayerCount, nLevelDiff=_abs(oRoom:GetAvgFameLevel()-nFameLevel)})
			end
		end
	end
	if #tRoomList == 0 then
		return
	end
	_sort(tRoomList, _fn_room_sort)
	return tRoomList[1].oRoom
end

--单人匹配
function CBugStormMgr:SingleMatchReq(oPlayer)
	print("CBugStormMgr:SingleMatchReq***")
	self:CancelMatchReq(oPlayer)
	local oBattle = oPlayer:GetModule(CBattle:GetType())
	if oBattle:IsBattling() then
		return
	end
	local oRoom = self:RoomSelect(oPlayer)
	if oRoom then
		oRoom:JoinRoom(oPlayer)
		local nRoomState = oRoom:GetState()
		if nRoomState == CBugStormRoom.tRoomState.eInit and oRoom:GetPlayerCount() > 1 then
			oRoom:StartRun()
		end
	else
		oRoom = self:CreateRoom()
		oRoom:JoinRoom(oPlayer)
	end
	return oRoom
end

--购买弹药请求
function CBugStormMgr:BuyBulletReq(oPlayer)
	local nGold = oPlayer:GetGold()
	local nCost = ctBugStormEtc[1].nBuyBulletCost
	local nCode = -1 
	if nGold >= nCost then
		oPlayer:SubGold(nCost, gtReason.eBuyBullet)
		nCode = 0
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "BuyBulletRet", {nCode=nCode})
end

--取消匹配
function CBugStormMgr:CancelMatchReq(oPlayer)
	local oBattle = oPlayer:GetModule(CBattle:GetType())
	local nType, nCamp, tData = oBattle:GetBattleType()
	if nType ~= gtBattleType.eBugStorm then
		return
	end
	local oRoom = self.m_tRoomMap[tData.nRoomID]
	if not oRoom or oRoom:GetState() ~= CBugStormRoom.tRoomState.eInit then
		return
	end
	oRoom:CancelMatchReq(oPlayer)
end

--开始战斗
function CBugStormMgr:StartBattleReq(oPlayer)
	local oBattle = oPlayer:GetModule(CBattle:GetType())
	local nType, nCamp, tData = oBattle:GetBattleType()
	if nType ~= gtBattleType.eBugStorm then
		return
	end
	local oRoom = self.m_tRoomMap[tData.nRoomID]
	if not oRoom or oRoom:GetState() ~= CBugStormRoom.tRoomState.eInit then
		return
	end
	if not oRoom:GetPlayer(oPlayer:GetCharID()) then
		return
	end
	oRoom:StartRun()
end

--玩家自己创建的队伍开始匹配
function CBugStormMgr:TeamStartMatch(nRoomID, tRoom, sLeaderCharID)
	assert(sLeaderCharID)
	local oRoom = self:CreateRoom(nRoomID)

	local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sLeaderCharID)
	oRoom:JoinRoom(oPlayer, true)

	for sCharID, tMember in pairs(tRoom.tPlayerMap)	do
		if sCharID ~= sLeaderCharID then
			local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
			oRoom:JoinRoom(oPlayer, true)
		end
	end
	oRoom:StartRun()
	return oRoom
end
