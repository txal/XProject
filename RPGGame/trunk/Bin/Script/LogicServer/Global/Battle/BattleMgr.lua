--战斗管理模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CBattleMgr:Ctor()
	self.m_nBattleID = 0
	self.m_tBattleMap = {}
end

--生成战斗ID
function CBattleMgr:GenBattleID()
	self.m_nBattleID = (self.m_nBattleID % 0x7FFFFFFF) + 1
	return self.m_nBattleID
end

--取战斗对象
function CBattleMgr:GetBattle(nID)
	return self.m_tBattleMap[nID]
end

--创建战斗
function CBattleMgr:CreateBattle()
	local nID = self:GenBattleID()
	local oBattle = CBattle:new(nID)
	self.m_tBattleMap[nID] = oBattle
	return oBattle
end

--移除战斗
function CBattleMgr:RemoveBattle(nID)
	self.m_tBattleMap[nID] = nil
end


goBattle = goBattle or CBattleMgr:new()