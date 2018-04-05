--怪物管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CMonsterMgr:Ctor()
	self.m_tMonsterMap = {}
	self.m_nAutoID = 0
end

function CMonsterMgr:GenID()
	self.m_nAutoID = self.m_nAutoID % 0x7FFFFFFF + 1
	return self.m_nAutoID
end

function CMonsterMgr:GetMonster(nObjID)
	return self.m_tMonsterMap[nObjID]
end

function CMonsterMgr:GetCount()
	local nCount = 0
	for nObjID, oMonster in pairs(self.m_tMonsterMap) do
		nCount = nCount + 1
	end
	return nCount
end

--刷怪
function CMonsterMgr:CreateMonster(nConfID, nDupMixID, nPosX, nPosY)
	print("CMonsterMgr:CreateMonster***", nConfID)
	assert(ctMonsterConf[nConfID], "怪物:"..nConfID.." 不存在")
	local oDup = goDupMgr:GetDup(nDupMixID)
	if not oDup then
		return LuaTrace("副本不存在", nDupMixID)
	end
	local nID = self:GenID()
	local oMonster = CMonster:new(nID, nConfID)
	self.m_tMonsterMap[nID] = oMonster
	oMonster:EnterScene(nDupMixID, nPosX, nPosY, -1)
	return oMonster
end

--移除
function CMonsterMgr:RemoveMonster(nObjID)
	local oMonster = self:GetMonster(nObjID)
	if oMonster then
		oMonster:OnRelease()
	end
	self.m_tMonsterMap[nObjID] = nil
end

--清理
function CMonsterMgr:OnMonsterCollected(nObjID)
	self:RemoveMonster(nObjID)
end


goMonsterMgr = goMonsterMgr or CMonsterMgr:new()
goCppMonsterMgr = GlobalExport.GetMonsterMgr()
