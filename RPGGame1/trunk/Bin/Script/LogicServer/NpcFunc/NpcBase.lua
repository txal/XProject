--NPC基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CNpcBase:Ctor(nID)
	self.m_nID = nID
	assert(ctNpcConf[nID], "配置不存在")
end

function CNpcBase:Release() end

function CNpcBase:GetID() return self.m_nID end
function CNpcBase:GetConf() return ctNpcConf[self.m_nID] end
function CNpcBase:GetName() return self:GetConf().sName end

--检测NPC和玩家距离是否合法
function CNpcBase:IsPositionValid(oRole)
	return true
end

--触发NPC功能(子类实现)
function CNpcBase:Trigger() end
--角色登陆
function CNpcBase:Online(oRole) end
--角色进入场景
function CNpcBase:OnEnterScene(oRole) end
