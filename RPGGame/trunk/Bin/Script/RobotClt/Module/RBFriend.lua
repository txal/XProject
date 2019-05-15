--好友模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CRBFriend:Ctor(oRobot)
	self.m_oRobot = oRobot
end

function CRBFriend:Run()
	local tCmdList = {
		{"FriendListReq", {}},
		{"FriendHistoryTalkReq", {}},
	}
	local tCmd = tCmdList[math.random(2)]
	self.m_oRobot:SendPressMsg(tCmd[1], tCmd[2])
end

function CRBFriend:FriendListRet(tData)
	if #tData.tList > 0 then
		local tFriend = tData.tList[math.random(#tData.tList)]
		local tCmdList = {
			{"FriendTalkReq", {nTarRoleID=tFriend.nID, sCont="hello hello"}},
			{"DelFriendReq", {nTarRoleID=tFriend.nID, bStranger=false}},
		}
		local tCmd = tCmdList[math.random(4)]
		if tCmd then
			self.m_oRobot:SendPressMsg(tCmd[1], tCmd[2])
		end
	else
		self.m_oRobot:SendPressMsg("FriendApplyListReq", {})
	end
end

function CRBFriend:SearchFriendRet(tData)
	if #tData.tList > 0 then
		local tFriend = tData.tList[math.random(#tData.tList)]
		self.m_oRobot:SendPressMsg("FriendApplyReq", {nTarRoleID=tFriend.nID, sMessage="hello hello hello!!!"})
	end
end

function CRBFriend:FriendApplyListRet(tData)
	if #tData.tList > 0 then
		local tFriend = tData.tList[math.random(#tData.tList)]
		local tCmdList = {
			{"DenyFriendApplyReq", {nTarRoleID=tFriend.nID}},
			{"AddFriendReq", {nTarRoleID=tFriend.nID}},
		}
		local tCmd = tCmdList[math.random(4)]
		if tCmd then
			self.m_oRobot:SendPressMsg(tCmd[1], tCmd[2])
		end

	else
		self.m_oRobot:SendPressMsg("SearchFriendReq", {})

	end
end
