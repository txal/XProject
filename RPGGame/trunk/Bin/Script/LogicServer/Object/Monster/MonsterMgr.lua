function CMonsterMgr:Ctor()
	self.m_tMonsterMap = {}
end

function CMonsterMgr:GetMonster(sObjID)
	return self.m_tMonsterMap[sObjID]
end

function CMonsterMgr:GetCount()
	local nCount = 0
	for sObjID, oMonster in pairs(self.m_tMonsterMap) do
		nCount = nCount + 1
	end
	return nCount
end

--刷怪
function CMonsterMgr:CreateMonster(nConfID, nSceneIndex, nPosX, nPosY, tBattle)
	assert(tBattle and tBattle.nType and tBattle.nCamp)
	assert(ctMonsterConf[nConfID], "怪物:"..nConfID.." 不存在")
	local sObjID = GlobalExport.MakeGameObjID()
	local oMonster = CMonster:new(sObjID, nConfID, tBattle)
	self.m_tMonsterMap[sObjID] = oMonster
	oMonster:EnterScene(nSceneIndex, nPosX, nPosY)
	return oMonster
end

--移除
function CMonsterMgr:RemoveMonster(sObjID)
	local oMonster = self:GetMonster(sObjID)
	if oMonster then
		oMonster:OnRelease()
	end
	self.m_tMonsterMap[sObjID] = nil
end

--被清理
function CMonsterMgr:OnMonsterCollected(sObjID)
	self:RemoveMonster(sObjID)
end


goCppMonsterMgr = GlobalExport.GetMonsterMgr()
goLuaMonsterMgr = goLuaMonsterMgr or CMonsterMgr:new()
