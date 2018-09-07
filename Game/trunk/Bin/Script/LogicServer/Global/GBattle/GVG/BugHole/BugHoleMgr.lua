--异虫巢穴管理类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CBugHoleMgr:Ctor()
	self.m_tRoomMap = {}
	self.m_tRoomTimerMap = {}
end

function CBugHoleMgr:CreateRoom(nRoomStage, nRoomID)
	local nRoomID = nRoomID or goBattleCnt:MakeRoomID()
	assert(nRoomID and nRoomStage)
	local tStageRoomMap = self.m_tRoomMap[nRoomStage]
	if not tStageRoomMap then
		tStageRoomMap = {}
		self.m_tRoomMap[nRoomStage] = tStageRoomMap
	end
	assert(not tStageRoomMap[nRoomID])
	local oRoom = CBugHoleRoom:new(self, nRoomID, nRoomStage)
	tStageRoomMap[nRoomID] = oRoom
	return oRoom
end

function CBugHoleMgr:GetRoom(tBattleData)
	local nRoomID, nRoomStage = tBattleData.nRoomID, tBattleData.nRoomStage
	local tStageRoomMap = self.m_tRoomMap[nRoomStage]
	return tStageRoomMap and tStageRoomMap[nRoomID]
end

function CBugHoleMgr:OnBattleResult(oRoom, nWinCamp)
	if not oRoom then
		return
	end
	local nRoomID = oRoom:GetID()
	local nRoomStage = oRoom:GetStage()
	self.m_tRoomMap[nRoomStage][nRoomID] = nil

	if self.m_tRoomTimerMap[nRoomID] then
		GlobalExport.CancelTimer(self.m_tRoomTimerMap[nRoomID])
		self.m_tRoomTimerMap[nRoomID] = nil
	end
	print("CBugHoleMgr:BattleResult***", nRoomStage, nRoomID, nWinCamp)
end

function CBugHoleMgr:CalcRoomStage(oPlayer)
	local nFameLevel = oPlayer.m_oGVGModule:GetFameLevel()
	local nRndLevel = math.random(1, nFameLevel)
	local nMaxFame = nMAX_INTEGER
	if ctGVGFameLevelConf[nRndLevel+1] then
		nMaxFame = ctGVGFameLevelConf[nRndLevel+1].nFame - 1
	end
	return nRndLevel, nMaxFame
end

--排序函数
local function _fn_room_sort_(tRoom1, tRoom2)
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
	local nFame = oPlayer.m_oGVGModule:GetFame()
	local nWins, nLoses = oPlayer.m_oGVGModule:GetWinsInfo()
	nFame = nFame + GetGVGMatchFameAdd(nWins, nLoses)

	local tRoomList = {}
	local nRoomStage, nMaxFame = self:CalcRoomStage(oPlayer)
	nFame = math.min(nFame, nMaxFame)
	local tStageRoomMap = self.m_tRoomMap[nRoomStage] or {}
	local nTeamPlayer = ctBugHoleEtc[1].nTeamPlayer
	for nRoomID, oRoom in pairs(tStageRoomMap) do
		if not oRoom:IsNewbie() and oRoom:GetState() ~= CBugHoleRoom.tRoomState.eFinish then
			local nAtkerCount= oRoom:GetAtkerCount()
			local nDeferCount = oRoom:GetDeferCount()
			if nAtkerCount < nTeamPlayer or nDeferCount < nTeamPlayer then
				local nDiffCount = math.abs(nAtkerCount - nDeferCount)
				local nDiffFame = math.abs(nFame - oRoom:GetAvgFameValue())
				local nCreateTime = oRoom:GetCreateTime()
				table.insert(tRoomList, {oRoom=oRoom, nDiffFame=nDiffFame, nDiffCount=nDiffCount
					, nAtkerCount=nAtkerCount, nDeferCount=nDeferCount, nCreateTime=nCreateTime})
			end
		end
	end
	if #tRoomList == 0 then
		return
	end
	table.sort(tRoomList, _fn_room_sort_)
	local tRoom = tRoomList[1]
	local oRoom = tRoom.oRoom
	local nCamp = tRoom.nAtkerCount > tRoom.nDeferCount and gtCampType.eDefender or gtCampType.eAttacker
	return oRoom, nCamp
end

--单人匹配
function CBugHoleMgr:SingleMatchReq(oPlayer)
	self:CancelMatchReq(oPlayer)
	if oPlayer:IsBattling() then
		LuaTrace(oPlayer:GetName(), "匹配失败,已经在战斗中")
		return
	end
	local tEtcConf = ctBugHoleEtc[1]
	local bNewbie, oRoom, nCamp = true, nil, nil
	local nTotalFights = oPlayer.m_oGVGModule:GetTotalFights()
	--新手判定
	if oPlayer:GetLevel() > tEtcConf.nNewbieLevel or nTotalFights >= tEtcConf.nNewbieFights then
		oRoom, nCamp = self:RoomSelect(oPlayer)
		bNewbie = false
	end
	if oRoom then
		oRoom:JoinRoom(oPlayer, nCamp)
		local nRoomState = oRoom:GetState()
		if nRoomState == CBugHoleRoom.tRoomState.eInit
			and oRoom:GetAtkerCount() >= tEtcConf.nTeamPlayer
			and oRoom:GetDeferCount() >= tEtcConf.nTeamPlayer then
				local nRoomID = oRoom:GetID()
				if self.m_tRoomTimerMap[nRoomID] then
					GlobalExport.CancelTimer(self.m_tRoomTimerMap[nRoomID])
					self.m_tRoomTimerMap[nRoomID] = nil
				end
				oRoom:StartRun()
		end
	else
		local nRoomStage = self:CalcRoomStage(oPlayer)
		oRoom = self:CreateRoom(nRoomStage)
		if bNewbie then
			oRoom:SetNewbie(nTotalFights+1) --第几场
		end
		oRoom:JoinRoom(oPlayer, gtCampType.eAttacker)
		self.m_tRoomTimerMap[oRoom:GetID()] = GlobalExport.RegisterTimer(tEtcConf.nMatchTime*1000, function() oRoom:StartRun() end)
	end
	return oRoom
end

function CBugHoleMgr:GetRoomByPlayer(oPlayer)
	local tBattle = oPlayer:GetBattle()
	if tBattle.nType ~= gtBattleType.eBugHole then
		return
	end
	return self:GetRoom(tBattle.tData)
end

--取消匹配
function CBugHoleMgr:CancelMatchReq(oPlayer)
	local oRoom = self:GetRoomByPlayer(oPlayer)
	if not oRoom or oRoom:GetState() ~= CBugHoleRoom.tRoomState.eInit then
		return
	end
	oRoom:CancelMatchReq(oPlayer)
end

--玩家自己创建的队伍开始匹配
function CBugHoleMgr:TeamStartMatch(nRoomID, tRoom, sLeaderCharID)
	local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sLeaderCharID)
	if not oPlayer then
		return
	end
	local nRoomStage = self:CalcRoomStage(oPlayer)
	local oRoom = self:CreateRoom(nRoomStage, nRoomID)
	oRoom:JoinRoom(oPlayer, gtCampType.eAttacker, true)

	for sCharID, tMember in pairs(tRoom.tPlayerMap)	do
		if sCharID ~= sLeaderCharID then
			local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
			if oPlayer then oRoom:JoinRoom(oPlayer, gtCampType.eAttacker, true) end
		end
	end

	self.m_tRoomTimerMap[nRoomID] = GlobalExport.RegisterTimer(ctBugHoleEtc[1].nMatchTime*1000, function() oRoom:StartRun() end)
	return oRoom
end

--GM匹配
function CBugHoleMgr:GmGvg(oPlayer, nAtkNum, nDefNum)
	local tEtcConf = ctBugHoleEtc[1]
	nAtkNum = math.max(1, math.min(tEtcConf.nTeamPlayer, nAtkNum))
	nDefNum = math.max(1, math.min(tEtcConf.nTeamPlayer, nDefNum))

	self:CancelMatchReq(oPlayer)
	if oPlayer:IsBattling() then
		return
	end
	local nRoomStage = self:CalcRoomStage(oPlayer)
	local oRoom = self:CreateRoom(nRoomStage)
	local nTotalFights = oPlayer.m_oGVGModule:GetTotalFights()
	if oPlayer:GetLevel() <= ctBugHoleEtc[1].nNewbieLevel and nTotalFights < ctBugHoleEtc[1].nNewbieFights then
		oRoom:SetNewbie(nTotalFights+1)
	end
	oRoom:JoinRoom(oPlayer, gtCampType.eAttacker)
	oRoom:StartRun(nAtkNum, nDefNum)
end

function CBugHoleMgr:PrintGVG()
	local nCount = 0
	for k, tStageRoomMap in pairs(self.m_tRoomMap) do
		for _, v in pairs(tStageRoomMap) do
			nCount = nCount + 1
		end
	end
	LuaTrace("GVGRoom: ", nCount)
end
