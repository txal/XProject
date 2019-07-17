--跑动模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CRBWalk:Ctor(oRobot)
	self.m_oRobot = oRobot
end

function CRBWalk:Run()
    local oNativeRobot = goNativeRobotMgr:GetRobot(self.m_oRobot:GetSession())
	if not oNativeRobot:IsRunning() and not self.m_oRobot.m_tModuleMap["battle"]:IsInBattle() then
		oNativeRobot:StartRun(self.m_oRobot:RndMoveTarget())
	end
end

