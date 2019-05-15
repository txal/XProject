local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CRBTalk:Ctor(oRobot)
	self.m_oRobot = oRobot
end

function CRBTalk:Run()
	local nChannel = math.random(1, 6)
	local sCont = "hello hello hello 喂喂!!!"
	self.m_oRobot:SendPressMsg("TalkReq", {nChannel=nChannel, sCont=sCont})
end
