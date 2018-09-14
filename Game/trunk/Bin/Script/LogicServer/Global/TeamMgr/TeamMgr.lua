--比赛类型
CTeamMgr.tGameType =
{
	eGVE = 1,
	eGVG = 2,
}

--地图类型
CTeamMgr.tMapType = 
{
	eBugStorm = 1, 	--异虫狂潮
	eBugHole = 2, 	--异虫巢穴
}

function CTeamMgr:Ctor()
	self.m_tTeamMap = {}	 --{[roomid]={nRoomID=0,nGameType=0,nMapType=0,tPlayerMap={},},...}
	self.m_tCharTeamMap = {} --{[charid]=roomid}
end

function CTeamMgr:Offline(oPlayer)
	local sCharID = oPlayer:GetCharID()
	local nRoomID = self.m_tCharTeamMap[sCharID]
	if nRoomID then
		self:LeaveTeam(sCharID, nRoomID)
	end
end

function CTeamMgr:_leave_old_team(sCharID, nNewRoomID)
	local nOldRoomID = self.m_tCharTeamMap[sCharID]
	if not nOldRoomID then
		return
	end
	if nOldRoomID == nNewRoomID then
		return
	end
	self:LeaveTeam(sCharID, nOldRoomID)
end

function CTeamMgr:CreateTeam(oPlayer, nGameType, nMapType)
	print("CTeamMgr:CreateTeam***")
	local sCharID = oPlayer:GetCharID()
	self:_leave_old_team(sCharID)

	local nRoomID = goBattleMgr:MakeRoomID()
	assert(not self.m_tTeamMap[nRoomID])
	local tRoom = {nRoomID=nRoomID, nGameType=nGameType, nMapType=nMapType, tPlayerMap={}}
	self.m_tTeamMap[nRoomID] = tRoom

	local tData = {nRoomID=nRoomID, nGameType=nGameType, nMapType=nMapType}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "CreateTeamRet", tData)

	self:JoinTeam(oPlayer, nRoomID)
	return tRoom
end

function CTeamMgr:GetSessionListByPlayer(oPlayer)
	local sCharID = oPlayer:GetCharID()
	local nRoomID = self.m_tCharTeamMap[sCharID]
	if not nRoomID then
		return {}
	end
	return self:GetSessionList(nRoomID)
end

function CTeamMgr:GetSessionList(nRoomID, sExceptCharID)
	local tSessionList = {}
	local tRoom = self.m_tTeamMap[nRoomID]
	if not tRoom then
		return tSessionList
	end
	for sCharID, tPlayer in pairs(tRoom.tPlayerMap) do
		if sCharID ~= sExceptCharID then
			local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
			table.insert(tSessionList, oPlayer:GetSession())
		end
	end
	return tSessionList
end

function CTeamMgr:_get_player_info(nRoomID, sCharID)
	local tRoom = self.m_tTeamMap[nRoomID]
	if not tRoom then
		return
	end
	local tPlayer = tRoom.tPlayerMap[sCharID]
	if not tPlayer then
		return
	end
	local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
	local sCharID, sCharName, nRoleID, nLevel, nPower = oPlayer:GetCharID(), oPlayer:GetName(), oPlayer:GetRoleID(), oPlayer:GetLevel(), oPlayer:GetPower()
	local tInfo = {sCharID=sCharID, sCharName=sCharName, nRoleID=nRoleID, nLevel=nLevel, nPower=nPower, nTime=tPlayer.nTime, bLeader=tPlayer.bLeader}
	return tInfo
end

function CTeamMgr:JoinTeam(oPlayer, nRoomID)
	print("CTeamMgr:JoinTeam***", nRoomID)
	local sCharID = oPlayer:GetCharID()
	self:_leave_old_team(sCharID, nRoomID)

	local tRoom = self.m_tTeamMap[nRoomID]
	if not tRoom then
		return
	end

	--已经在队伍里面
	if tRoom.tPlayerMap[sCharID] then
		return
	end

	local bLeader = not next(tRoom.tPlayerMap)
	local tPlayer = {nTime=os.time(), bLeader=bLeader}
	tRoom.tPlayerMap[sCharID] = tPlayer
	self.m_tCharTeamMap[sCharID] = nRoomID

	--广播玩家进入(不广播给刚进入的人)
	local tSessionList = self:GetSessionList(nRoomID, sCharID)
	if #tSessionList > 0 then
		local tInfo = self:_get_player_info(nRoomID, sCharID)
		if tInfo then
			CmdNet.PBBroadcastExter(tSessionList, "PlayerEnterTeamSync", {tMember=tInfo})
		end
	end

	--返回玩家列表给刚进入的人
	local tMemberList = {}
	for sCharID, tPlayer in pairs(tRoom.tPlayerMap) do
		local tInfo = self:_get_player_info(nRoomID, sCharID)
		if tInfo then
			table.insert(tMemberList, tInfo)
		end
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "TeamMemberListRet", {tMemberList=tMemberList})
	return true
end

function CTeamMgr:RemoveTeam(nRoomID)
	print("CTeamMgr:RemoveTeam***", nRoomID)
	local tRoom = self.m_tTeamMap[nRoomID]
	if not tRoom then
		return
	end

	--广播房间解散
	local tSessionList = self:GetSessionList(nRoomID)
	if #tSessionList > 0 then
		CmdNet.PBBroadcastExter(tSessionList, "TeamDismissSync", {nRoomID=nRoomID})
	end

	for sCharID, tPlayer in pairs(tRoom.tPlayerMap) do
		self.m_tCharTeamMap[sCharID] = nil
	end
	self.m_tTeamMap[nRoomID] = nil
end

function CTeamMgr:LeaveTeam(sCharID, nRoomID, bKicked)
	print("CTeamMgr:LeaveTeam***", nRoomID)
	local tRoom = self.m_tTeamMap[nRoomID]
	if not tRoom then
		return
	end
	local tPlayer = tRoom.tPlayerMap[sCharID]
	if not tPlayer then
		return
	end
	if tPlayer.bLeader then
		self:RemoveTeam(nRoomID)
	else
		bKicked = bKicked and true or false
		--广播玩家离开(包括离开的人)
		local tSessionList = self:GetSessionList(nRoomID)
		if #tSessionList > 0 then
			CmdNet.PBBroadcastExter(tSessionList, "PlayerLeaveTeamSync", {sCharID=sCharID, bKicked=bKicked})
		end
		tRoom.tPlayerMap[sCharID] = nil
		self.m_tCharTeamMap[sCharID] = nil
	end
end

function CTeamMgr:CreateTeamReq(oPlayer, nGameType, nMapType)
	return self:CreateTeam(oPlayer, nGameType, nMapType)
end

function CTeamMgr:_get_player_count(tRoom)
	local nCount = 0
	for sCharID, tPlayer in pairs(tRoom.tPlayerMap) do
		nCount = nCount + 1
	end
	return nCount
end

function CTeamMgr:_get_battle_mgr(tRoom)
	if tRoom.nGameType == self.tGameType.eGVE then
		if tRoom.nMapType == self.tMapType.eBugStorm then
			return goBattleMgr:GetBattleMgr(gtBattleType.eBugStorm)	
		end
	elseif tRoom.nGameType == self.tGameType.eGVG then
		if tRoom.nMapType == self.tMapType.eBugHole then
			return goBattleMgr:GetBattleMgr(gtBattleType.eBugHole)	
		end
	end
end

function CTeamMgr:EnterTeamReq(oPlayer, nRoomID)
	local tRoom = self.m_tTeamMap[nRoomID]
	if not tRoom then
		return oPlayer:ScrollMsg(ctLang[2])
	end
	if self:_get_player_count(tRoom) >= 5 then
		return oPlayer:ScrollMsg(ctLang[3])
	end
	self:JoinTeam(oPlayer, nRoomID)
end

function CTeamMgr:LeaveTeamReq(oPlayer)
	local sCharID = oPlayer:GetCharID()
	local nRoomID = self.m_tCharTeamMap[sCharID]
	local tRoom = self.m_tTeamMap[nRoomID]
	if not tRoom then
		return
	end
	self:LeaveTeam(sCharID, nRoomID)
end

function CTeamMgr:KickMemberReq(oPlayer, sTarCharID)
	print("CTeamMgr:KickPlayer***", sTarCharID)
	local sCharID = oPlayer:GetCharID()
	local nRoomID = self.m_tCharTeamMap[sCharID]
	local tRoom = self.m_tTeamMap[nRoomID]
	if not tRoom then
		return
	end
	if sCharID == sTarCharID then
		return
	end
	local tPlayer = tRoom.tPlayerMap[sCharID]
	if not tPlayer or not tPlayer.bLeader then
		return
	end
	self:LeaveTeam(sTarCharID, nRoomID, true)	
end

function CTeamMgr:SwitchTeamTypeReq(oPlayer, nGameType, nMapType)
	local nRoomID = self.m_tCharTeamMap[sCharID]
	local tRoom = self.m_tTeamMap[nRoomID]
	if not tRoom then
		return
	end
	local tPlayer = tRoom.tPlayerMap[sCharID]
	if not tPlayer or not tPlayer.bLeader then
		return
	end
	tRoom.nGameType = nGameType
	tRoom.nMapType = nMapType
end

function CTeamMgr:StartMatchReq(oPlayer)
	local sCharID = oPlayer:GetCharID()
	local nRoomID = self.m_tCharTeamMap[sCharID]
	local tRoom = self.m_tTeamMap[nRoomID]
	if not tRoom then
		return
	end
	local tPlayer = tRoom.tPlayerMap[sCharID]
	if not tPlayer or not tPlayer.bLeader then
		return
	end
	local oBattleMgr = self:_get_battle_mgr(tRoom)
	if oBattleMgr then
		if oBattleMgr:GetRoom(nRoomID) then
			return oPlayer:ScrollMsg(ctLang[25])
		end
		oBattleMgr:TeamStartMatch(nRoomID, tRoom, sCharID)
	end
end

--就位请求
function CTeamMgr:ReadyReq(oPlayer)
	local sCharID = oPlayer:GetCharID()
	local nRoomID = self.m_tCharTeamMap[sCharID]
	if not nRoomID then
		return
	end
	local tSessionList = self:GetSessionList(nRoomID, sCharID)
	if #tSessionList > 0 then
		CmdNet.PBBroadcastExter(tSessionList, "TeamReadyAskRet", {})
	end
end

--确认就位
function CTeamMgr:ConfirmReq(oPlayer)
	goTalk:SendTeamMsg(oPlayer, string.format(ctLang[20], oPlayer:GetName()), true)
end


goTeamMgr = goTeamMgr or CTeamMgr:new()