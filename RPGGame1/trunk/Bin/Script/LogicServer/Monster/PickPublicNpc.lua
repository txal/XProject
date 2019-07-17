--拾取公共NPC
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
function CPickPublicNpc:Ctor(nObjID, nConfID)
	CPublicNpc.Ctor(self, nObjID, nConfID)
	self.m_nMonType = gtMonType.ePickPublicNpc
end

function CPickPublicNpc:IsPickPublicNpc()
	if self:GetObjType() ~= gtObjType.eMonster then
		return false
	end
	if self:GetMonType() ~= gtMonType.ePickPublicNpc then
		return false
	end
	return true
end

--拾取接口需要子类实现
function CPickPublicNpc:PickReq() end