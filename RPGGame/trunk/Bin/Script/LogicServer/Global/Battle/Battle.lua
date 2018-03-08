--战斗模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CBattle:Ctor(nID)
	self.m_nID = nID
	self.m_nRound = 0
	self.m_tUnitAtkMap = {}	--攻方单元(1x)	{[1x]=battle, ...}
	self.m_tUnitDefMap = {}	--守方单元(2x)	{[2x]=battle, ...}
end

--释放战斗对象
function CBattle:OnRelease()
	for nID, oUnit in pairs(self.m_tUnitAtkMap) do
		oUnit:OnRelease()
	end
	for nID, oUnit in pairs(self.m_tUnitDefMap) do
		oUnit:OnRelease()
	end
end

--回合开始
function CBattle:RoundBegin()
	self.m_nRound = self.m_nRound + 1
	for nID, oUnit in pairs(self.m_tUnitAtkMap) do
		oUnit:OnRoundBegin(self.m_nRound)
	end
	for nID, oUnit in pairs(self.m_tUnitDefMap) do
		oUnit:OnRoundBegin(self.m_nRound)
	end
end

--回合结束
function CBattle:RoundEnd()
end

--取回合数
function CBattle:GetRound()
	return self.m_nRound
end

--取战斗单位
function CBattle:GetUnit(nID)
	if nID%10 == 1 then
		return self.m_tUnitAtkMap[nID]
	end
	if nID%10 == 2 then
		return self.m_tUnitDefMap[nID]
	end
end

--是否同一阵营
function CBattle:IsSameTeam(nUnitID1, nUnitID2)
	return (nUnitID1%10 == nUnitID2%10)
end

--单元下达指令完毕
function CBattle:OnUnitReady(nUnitID)
end

--单元死亡事件
function CBattle:OnUnitDead(nUnitID)
end








--使用物品请求
function CBattle:UsePropReq(oRole, nSrcUnitID, nTarUnitID, nPropID)
	--战斗可使用物品判断 fix pd
	local oUnit = self:GetUnit(nUnitID)
	if not oUnit then
		return
	end
end