local _abs, _sort, _insert, _random, _floor, _max, _min, _time
= math.abs, table.sort, table.insert, math.random, math.floor, math.max, math.min, os.time

function CBugHoleMgr:Ctor()
	self.m_tRoomMap = {}
	self.m_tRoomTimerMap = {}
end

function CBugHoleMgr:CreateRoom(nRoomID)
	local nRoomID = nRoomID or goBattleMgr:MakeRoomID()
	assert(not self.m_tRoomMap[nRoomID])
	local oRoom = CBugHoleRoom:new(self, nRoomID)
	self.m_tRoomMap[nRoomID] = oRoom
	return oRoom
end

function CBugHoleMgr:GetRoom(nRoomID)
	return self.m_tRoomMap[nRoomID]
end

function CBugHoleMgr:GetRoomByPlayer(oPlayer)
	local oBattle = oPlayer:GetModule(CBattle:GetType())
	local nType, nCamp, tData = oBattle:GetBattleType()
	if nType ~= gtBattleType.eBugHole then
		return
	end
	local oRoom = self.m_tRoomMap[tData.nRoomID]
	return oRoom
end

function CBugHoleMgr:Offline(oPlayer, tData)
	local sCharID = oPlayer:GetCharID()
	local oRoom = self.m_tRoomMap[tData.nRoomID]
	if oRoom then
		oRoom:Offline(oPlayer)
	end
end

function CBugHoleMgr:OnBattleResult(nRoomID, nWinCamp)
	local oRoom = self.m_tRoomMap[nRoomID]
	if not oRoom then
		return
	end
	self.m_tRoomMap[nRoomID] = nil
	print("CBugHoleMgr:BattleResult***", nRoomID, nWinCamp)
	if self.m_tRoomTimerMap[nRoomID] then
		GlobalExport.CancelTimer(self.m_tRoomTimerMap[nRoomID])
		self.m_tRoomTimerMap[nRoomID] = nil
	end
end

function CBugHoleMgr:OnEnterScene(oPlayer, tData)
	local oRoom = self.m_tRoomMap[tData.nRoomID]
	if oRoom then
		oRoom:OnEnterScene(oPlayer)
	end
end	

function CBugHoleMgr:AfterEnterScene(oPlayer, tData)
	local oRoom = self.m_tRoomMap[tData.nRoomID]
	if oRoom then
		oRoom:AfterEnterScene(oPlayer)
	end
end	

function CBugHoleMgr:OnLeaveScene(oPlayer, tData)
	local oRoom = self.m_tRoomMap[tData.nRoomID]
	if oRoom then
		oRoom:OnLeaveScene(oPlayer)
	end
end

function CBugHoleMgr:OnPlayerDead(oPlayer, sAtkerID, nAtkerType, nArmID, nArmType, tData)
	local oRoom = self.m_tRoomMap[tData.nRoomID]	
	if oRoom then
		oRoom:OnPlayerDead(oPlayer, sAtkerID, nAtkerType, nArmID, nArmType)
	end
end

function CBugHoleMgr:OnRobotDead(oSRobot, sAtkerID, nAtkerType, nArmID, nArmType, tData)
	local oRoom = self.m_tRoomMap[tData.nRoomID]	
	if oRoom then
		oRoom:OnRobotDead(oSRobot, sAtkerID, nAtkerType, nArmID, nArmType)
	end
end

function CBugHoleMgr:ClientSceneReady(oPlayer, tData)
	local oRoom = self.m_tRoomMap[tData.nRoomID]	
	if oRoom then
		oRoom:ClientSceneReady(oPlayer)
	end
end

--排序函数
local function _fn_room_sort(tRoom1, tRoom2)
	if tRoom1.nDiffFame == tRoom2.nDiffFame then
		if tRoom1.nDiffCount == tRoom2.nDiffCount then	
			return tRoom1.nCreateTime < tRoom2.nCreateTime
		else
			return tRoom1.nDiffCount > tRoom2.nDiffCount
		end
	else
		return tRoom1.nDiffFame < tRoom2.nDiffFame
	end
end

function CBugHoleMgr:RoomSelect(oPlayer)
	local oGVG = oPlayer:GetModule(CGVGModule:GetType())
	local nFame = oGVG:GetFame()

	local tRoomList = {}
	local nTeamPlayer = ctBugHoleEtc[1].nTeamPlayer
	for nRoomID, oRoom in pairs(self.m_tRoomMap) do
		if oRoom:GetState() ~= CBugHoleRoom.tRoomState.eFinish then
			local nAtkerCount= oRoom:GetAtkerCount()
			local nDeferCount = oRoom:GetDeferCount()
			if nAtkerCount < nTeamPlayer or nDeferCount < nTeamPlayer then
				local nDiffCount = _abs(nAtkerCount - nDeferCount)
				local nDiffFame = _abs(nFame - oRoom:GetAvgFameValue())
				local nCreateTime = oRoom:GetCreateTime()
				_insert(tRoomList, {oRoom=oRoom, nDiffFame=nDiffFame, nDiffCount=nDiffCount
					, nAtkerCount=nAtkerCount, nDeferCount=nDeferCount, nCreateTime=nCreateTime})
			end
		end
	end
	if #tRoomList == 0 then
		return
	end
	_sort(tRoomList, _fn_room_sort)
	local oRoom = tRoomList[1].oRoom
	local nCamp = tRoomList[1].nAtkerCount > tRoomList[1].nDeferCount and gtCampType.eDefender or gtCampType.eAttacker
	return oRoom, nCamp
end

--单人匹配
function CBugHoleMgr:SingleMatchReq(oPlayer)
	self:CancelMatchReq(oPlayer)
	local oBattle = oPlayer:GetModule(CBattle:GetType())
	if oBattle:IsBattling() then
		return
	end
	local oRoom, nCamp = self:RoomSelect(oPlayer)
	if oRoom then
		oRoom:JoinRoom(oPlayer, nCamp)
		local nRoomState = oRoom:GetState()
		if nRoomState == CBugHoleRoom.tRoomState.eInit
			and oRoom:GetAtkerCount() >= ctBugHoleEtc[1].nTeamPlayer
			and oRoom:GetDeferCount() >= ctBugHoleEtc[1].nTeamPlayer then
				local nRoomID = oRoom:GetID()
				if self.m_tRoomTimerMap[nRoomID] then
					GlobalExport.CancelTimer(self.m_tRoomTimerMap[nRoomID])
					self.m_tRoomTimerMap[nRoomID] = nil
				end
				oRoom:StartRun()
		end
	else
		oRoom = self:CreateRoom()
		oRoom:JoinRoom(oPlayer, gtCampType.eAttacker)
		self.m_tRoomTimerMap[oRoom:GetID()] = GlobalExport.RegisterTimer(ctBugHoleEtc[1].nMatchTime*1000, function() oRoom:StartRun() end)
	end
	return oRoom
end

--取消匹配
function CBugHoleMgr:CancelMatchReq(oPlayer)
	local oBattle = oPlayer:GetModule(CBattle:GetType())
	local nType, nCamp, tData = oBattle:GetBattleType()
	if nType ~= gtBattleType.eBugHole then
		return
	end
	local oRoom = self.m_tRoomMap[tData.nRoomID]
	if not oRoom or oRoom:GetState() ~= CBugHoleRoom.tRoomState.eInit then
		return
	end
	oRoom:CancelMatchReq(oPlayer)
end

--玩家自己创建的队伍开始匹配
function CBugHoleMgr:TeamStartMatch(nRoomID, tRoom, sLeaderCharID)
	assert(sLeaderCharID)
	local oRoom = self:CreateRoom(nRoomID)

	local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sLeaderCharID)
	oRoom:JoinRoom(oPlayer, gtCampType.eAttacker, true)

	for sCharID, tMember in pairs(tRoom.tPlayerMap)	do
		if sCharID ~= sLeaderCharID then
			local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
			oRoom:JoinRoom(oPlayer, gtCampType.eAttacker, true)
		end
	end

	self.m_tRoomTimerMap[nRoomID] = GlobalExport.RegisterTimer(ctBugHoleEtc[1].nMatchTime*1000, function() oRoom:StartRun() end)
	return oRoom
end

--GM匹配
function CBugHoleMgr:GmGvg(oPlayer, nAtkNum, nDefNum)
	nAtkNum = _max(1, _min(5, nAtkNum))
	nDefNum = _max(1, _min(5, nDefNum))

	self:CancelMatchReq(oPlayer)
	local oBattle = oPlayer:GetModule(CBattle:GetType())
	if oBattle:IsBattling() then
		return
	end
	local oRoom = self:CreateRoom()
	oRoom:JoinRoom(oPlayer, gtCampType.eAttacker)
	oRoom:StartRun(nAtkNum, nDefNum)
end

function CBugHoleMgr:PrintGVG()
	local nCount = 0
	for k, v in pairs(self.m_tRoomMap) do
		nCount = nCount + 1
	end
	LuaTrace("GVGRoom: ", nCount)
end
