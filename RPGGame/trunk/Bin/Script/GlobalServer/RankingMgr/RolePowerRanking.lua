--人物战力排行
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CRolePowerRanking:Ctor(nID)
	CRankingBase.Ctor(self, nID)
end

--更新数据
function CRolePowerRanking:Update(nRoleID, nValue)
	CRankingBase.Update(self, nRoleID, nValue)
end

