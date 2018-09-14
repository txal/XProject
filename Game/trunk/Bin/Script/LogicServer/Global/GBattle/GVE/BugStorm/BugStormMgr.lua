local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CBugStormMgr:Ctor()
	self.m_tRoomMap = {}
end

function CBugStormMgr:CreateRoom(nRoomID)
	local nRoomID = nRoomID or goBattleCnt:MakeRoomID()
	assert(not self.m_tRoomMap[nRoomID])
	local oRoom = CBugStormRoom:new(self, nRoomID)
	self.m_tRoomMap[nRoomID] = oRoom
	return oRoom
end

function CBugStormMgr:GetRoom(tBattleData)
	return self.m_tRoomMap[tBattleData.nRoomID]
end

function CBugStormMgr:OnBattleResult(nRoomID, bWin)
	local oRoom = self.m_tRoomMap[nRoomID]
	if not oRoom then return end
	self.m_tRoomMap[nRoomID] = nil
	print("CBugStormMgr:BattleResult***", nRoomID, bWin)

	local tEtcConf = assert(ctBugStormEtc[1])
	if bWin then
		for sCharID, tPlayer in pairs(oRoom.m_tPlayerMap) do
			local tItemList = {}
			local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
			local oGVEModule = oPlayer.m_oGVEModule
			oGVEModule:OnBattleResult(bWin)
			--掉落奖励
			local nFameLevel = oGVEModule:GetFameLevel()
			local tLevelConf = assert(ctGVEFameLevelConf[nFameLevel])
			local tDropItem = DropMgr:GenDropItem(tLevelConf.nDropID)
			--玩家经验
			local nLevel = oPlayer:GetLevel()
			local nRound, nPassTimes = oGVEModule:GetRoundInfo()
			local nFixVal = nRound <= 2 and 1 or 0.25
			local nExp = math.floor((nLevel * 10 + 5) * (1 + nPassTimes * 0.5) * nFixVal)
			table.insert(tDropItem, {gtObjType.eProp, tEtcConf.nExpProp, nExp})
			--获得挑战声望
			local nFame = math.random(80, 120)
			table.insert(tDropItem, {gtObjType.eProp, tEtcConf.nFameProp, nFame})

			for _, tItem in ipairs(tDropItem) do
				local nType, nID, nNum = table.unpack(tItem)
				if nType > 0 and nID > 0 and nNum > 0 then
					oPlayer:AddItem(nType, nID, nNum, gtReason.eBugStormAward)
					table.insert(tItemList, {nType=nType, nID=nID, nNum=nNum})
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
	local oGVE = oPlayer.m_oGVEModule
	local nFameLevel = oGVE:GetFameLevel()

	local tRoomList = {}
	local nMaxPlayer = ctBugStormEtc[1].nRoomPlayer
	for nRoomID, oRoom in pairs(self.m_tRoomMap) do
		if oRoom:GetState() ~= CBugStormRoom.tRoomState.eFinish then
			local nPlayerCount = oRoom:GetPlayerCount()
			if nPlayerCount < nMaxPlayer then
				table.insert(tRoomList, {oRoom=oRoom, nCreateTime=oRoom:GetCreateTime(), nPeople=nPlayerCount,
					nLevelDiff=math.abs(oRoom:GetAvgFameLevel()-nFameLevel)})
			end
		end
	end
	if #tRoomList == 0 then
		return
	end
	table.sort(tRoomList, _fn_room_sort)
	return tRoomList[1].oRoom
end

--单人匹配
function CBugStormMgr:SingleMatchReq(oPlayer)
	print("CBugStormMgr:SingleMatchReq***")
	self:CancelMatchReq(oPlayer)
	if oPlayer:IsBattling() then
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

--取消匹配
function CBugStormMgr:CancelMatchReq(oPlayer)
	local tBattle = oPlayer:GetBattle()
	if tBattle.nType ~= gtBattleType.eBugStorm then
		return
	end
	local oRoom = self.m_tRoomMap[tBattle.tData.nRoomID]
	if not oRoom or oRoom:GetState() ~= CBugStormRoom.tRoomState.eInit then
		return
	end
	oRoom:CancelMatchReq(oPlayer)
end

--开始战斗
function CBugStormMgr:StartBattleReq(oPlayer)
	local tBattle = oPlayer:GetBattle()
	if tBattle.nType ~= gtBattleType.eBugStorm then
		return
	end
	local oRoom = self.m_tRoomMap[tBattle.tData.nRoomID]
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
