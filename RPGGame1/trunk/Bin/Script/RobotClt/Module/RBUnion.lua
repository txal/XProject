
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CRBUnion:Ctor(oRobot)
	self.m_oRobot = oRobot
end

local tRndCmdList = {
	{"UnionDetailReq", {}},
	{"UnionListReq", {sUnionKey="", nPageIndex=1}},
	{"UnionCreateReq", {sName="robot"..math.random(1,1000), sNotice="he he he"}},
	{"UnionExitReq", {}},
	{"UnionSetAutoJoinReq", {nAutoJoin=1}},
	{"UnionSetDeclarationReq", {sDeclaration="dlt dlt dlt"}},
	{"UnionApplyListReq", {}},
	{"UnionAcceptApplyReq", {nRoleID=0}},
	{"UnionRefuseApplyReq", {nRoleID=0}},
	{"UnionMemberListReq", {}},
	{"UnionJoinRandReq", {}},
	{"UnionManagerInfoReq", {}},
	{"UnionSignReq", {}},
	{"UnionModPosNameReq", {nPos=math.random(6), sPos="hehe"}},
	{"UnionGetSalaryReq", {}},
	{"UnionSetPurposeReq", {sCont="abcdefg"}},
	{"UnionDeclarationReadedReq", {}},
	{"UnionPowerRankingReq", {nRankNum=100}},
}

function CRBUnion:Run()
	local tCmd = tRndCmdList[math.random(#tRndCmdList)]
	self.m_oRobot:SendPressMsg(tCmd[1], tCmd[2])
end

function CRBUnion:UnionInfoRet(tData)
	self.m_nUnionID = tData.nID 
end

function CRBUnion:UnionListRet(tData)
	if #tData.tUnionList > 0 then
		if math.random(2) == 1 then
			local tUnion = tData.tUnionList[math.random(#tData.tUnionList)]
			self.m_oRobot:SendPressMsg("UnionApplyReq", {nID=tUnion.nID})
		end
	end
end

function CRBUnion:MemberListRet(tData)
	if #tData.tMemberList > 0 then
		local tMember = tData.tMemberList[math.random(#tData.tMemberList)]
		local tCmdList = {
			{"UnionAppointReq", {nRoleID=tMember.nID, nPos=math.random(6)}},
			{"UnionKickMemberReq", {nRoleID=tMember.nID}},
		} 
		local tCmd = tCmdList[math.random(4)]
		if tCmd then
			self.m_oRobot:SendPressMsg(tCmd[1], tCmd[2])
		end
	end
end
