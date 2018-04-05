--战斗管理模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CBattleMgr:Ctor()
	self.m_nAutoID = 0
	self.m_tBattleMap = {}
end

--生成战斗ID
function CBattleMgr:GenID()
	self.m_nAutoID = (self.m_nAutoID % 0x7FFFFFFF) + 1
	return self.m_nAutoID
end

--取战斗对象
function CBattleMgr:GetBattle(nID)
	return self.m_tBattleMap[nID]
end

--移除战斗
function CBattleMgr:RemoveBattle(nID)
	self.m_tBattleMap[nID] = nil
end

--PVE战斗
function CBattleMgr:PVEBattle(oRole, oMonster)
	local nID = self:GenID()
	local oBattle = CBattle:new(nID, CBattle.tBTT.ePVE, oRole:GetID(), oMonster:GetID())
	--玩家
	local nUnitID = 101
	local nSpouseID = oRole.m_oSpouse:GetSpouse()
	local nServer = oRole:GetSever()	
	local nSession = oRole:GetSession()
	local nObjID = oRole:GetID()	
	local nObjType = oRole:GetObjType()
	local sObjName = oRole:GetName()
	local nLevel = oRole:GetLevel()
	local nExp = oRole:GetExp()
	local tResAttr = oRole:GetResAttr()
	local tAdvAttr = oRole:GetAdvAttr()
	local tPropMap = oRole:GetBattlePropMap()
	local tSkillMap = {}
	local tPetMap = {}
	local oUnit = CUnit:new(self, nUnitID, nSpouseID, nServer, nSession, nObjID, nObjType, sObjName
		, nLevel, nExp, tResAttr, tAdvAttr, tPropMap, tSkillMap, tPetMap)
	oBattle:AddUnit(nUnitID, oUnit)

	--怪物
	local tMonsterConf = oMonster:GetConf()
	for nGrid, nNpc in ipairs(tMonsterConf.tFmt) do
		local nUnitID = 200 + nGrid
		local tNPCConf = ctNPCConf[nNpc]
		if tNPCConf then
			local oUnit = CUnit:new(self, nUnitID, 0, 0, 0, tNPCConf.nID, gtObjType.eMonster, tNPCConf.sName
				, tNPCConf.nLevel, tNPCConf.nExp, tNPCConf.tResAttr[1], tNPCConf.tAdvAttr[1], {}, {}, {})
			oBattle:AddUnit(nUnitID, oUnit)
		end
	end

	self.m_tBattleMap[nID] = oBattle
	oBattle:StartBattle()
end


goBattle = goBattle or CBattleMgr:new()