--功能NPC
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CNpcFunc:Ctor(nID)
	CNpcBase.Ctor(self, nID)
end

--触发NPC
--@nFuncID 功能编号
function CNpcFunc:Trigger(oRole, nFuncID)
	if not self:IsPositionValid(oRole) then
		return oRole:Tips("坐标非法")
	end
end
