--战斗模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CRBBattle:Ctor(oRobot)
	self.m_oRobot = oRobot
	self.m_bBattle = false
	self.m_nNextBattleTime = os.time()+math.random(300, 600)
end

function CRBBattle:Run()
	if os.time() < (self.m_nNextBattleTime or 0) then
		return
	end
	if not self.m_bBattle then
		self.m_oRobot:SendPressMsg("GMCmdReq", {sCmd="lgm tbt"})
	end
end

function CRBBattle:OnBattleStartRet()
	self.m_bBattle = true
	--LuaTrace("onbattlestart***")
end

function CRBBattle:OnBattleEndRet()
	self.m_bBattle = false
	self.m_nNextBattleTime = os.time() + math.random(300, 600)
	--LuaTrace("onbattleend***")
end

function CRBBattle:IsInBattle()
	return self.m_bBattle
end
