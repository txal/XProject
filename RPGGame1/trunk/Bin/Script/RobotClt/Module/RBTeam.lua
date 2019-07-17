local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CRBTeam:Ctor(oRobot)
	self.m_oRobot = oRobot
	self.m_nTeamID = 0
end

local tTeamCmdReq = {
	{"TeamQuitReq", {}},
	{"TeamReturnReq", {}},
	{"TeamLeaveReq", {}},
	{"TeamFriendReq", {}},
	{"TeamUnionMemberReq", {}},
	{"TeamInviteReq", {nRoleID=math.random(10000, 100000)}},
	{"TeamApplyJoinReq", {nTeamID=math.random(1, 50000)}},
	{"TeamApplyListReq", {}},
	{"TeamAgreeJoinReq", {nRoleID=math.random(10000, 100000)}},
	{"TeamExchangePosReq", {nIndex1=2, nIndex2=3}},
	{"TeamCallReturnReq", {}},
	{"TeamKickMemberReq", {nRoleID=math.random(10000, 100000)}},
	{"TeamTransferLeaderReq",{nRoleID=math.random(10000, 100000)}},
	{"TeamApplyLeaderReq", {}},
	{"TeamClearApplyListReq", {}},
}

function CRBTeam:Run()
	if self.m_nTeamID == 0 then
		self.m_oRobot:SendPressMsg("TeamReq", {})
	else
		local tCmdReq = tTeamCmdReq[math.random(#tTeamCmdReq)]
		self.m_oRobot:SendPressMsg(tCmdReq[1], tCmdReq[2])
	end
end

function CRBTeam:OnTeamRet(tData)
	if tData.nTeamID == 0 then

		local tGameType = {101, 102, 103, 105, 109, 200, 201, 202, 203, 301, 302, 303, 304}
		local nGameType = tGameType[math.random(#tGameType)]

		local tTeamGenReq = {
			{"CreateTeamReq", {}},
			{"TeamMatchReq", {nGameType=nGameType, sGameName="副本"..nGameType}},
		}

		local tGenReq = tTeamGenReq[math.random(4)]
		if tGenReq then
			self.m_oRobot:SendPressMsg(tGenReq[1], tGenReq[2])
		end

	else
		self.m_nTeamID = tData.nTeamID
	end
end
