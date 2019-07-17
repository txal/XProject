--竞技场机器人(配置表)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CArenaRobot:Ctor(nID, nLevel)
	assert(nID and nID > 0 and nID < gtGDef.tConst.nArenaConfRobotIDMax and nLevel, "参数错误")
	self.m_nID = nID
	self.m_nLevel = nLevel
	self.m_tPartnerMap = {}
	local tConf = self:GetConf()
	for k, v in pairs(tConf.tPartner) do
		local nPartnerID = v[1]
		if nPartnerID > 0 then
			local oPartner = CPartnerObj:new(self, nPartnerID, nLevel)
			oPartner:UpdateAttr()
			self.m_tPartnerMap[nPartnerID] = oPartner
		end
	end
end

function CArenaRobot:GetConf()
	if self.m_nID >= gtGDef.tConst.nArenaConfRobotIDMax then return end 
	return ctArenaRobotConf[self.m_nID]
end

function CArenaRobot:IsRobot(nID)
	if nID <= gtGDef.tConst.nArenaConfRobotIDMax then
		return true
	end
	return false
end

function CArenaRobot:GetID() return self.m_nID end
function CArenaRobot:GetObjType() return gtGDef.tObjType.eRole end
function CArenaRobot:GetName() return self:GetConf().sName end
function CArenaRobot:GetLevel() return self.m_nLevel end
function CArenaRobot:GetRoleConfID() return self:GetConf().nRoleConfID end
function CArenaRobot:GetRoleConf() return ctRoleInitConf[self:GetRoleConfID()] end
function CArenaRobot:GetSchool() return ctRoleInitConf[self:GetRoleConfID()].nSchool end
function CArenaRobot:GetReviveGrowthID() return 9 end --接口兼容

function CArenaRobot:GetUseFmt()
	local tConf = self:GetConf()
	return tConf.nFmt, tConf.nFmtLv
end

function CArenaRobot:GetPetBattleData(nPetID, nAttrConfID)
	local tPetConf = ctPetInfoConf[nPetID]
	local tSubMonConf = ctSubMonsterConf[nAttrConfID]
	assert(tPetConf and tSubMonConf)

	local tBTData = {}
	tBTData.nObjID = nPetID  --TODO 需要一个宠物配置
	tBTData.nObjType = gtObjType.ePet
	tBTData.sObjName = tPetConf.sName
	tBTData.nRoleID = self:GetID()
	tBTData.sModel = tPetConf.sModelNumber

	local nLevel = self:GetLevel()  --和角色等级一样
	tBTData.nLevel = nLevel
	tBTData.nPos = 1
	tBTData.nExp = 1
	tBTData.nNextExp = ctPetLevelConf[nLevel].nNextExp

	local tBattleAttr = {}
	for _, v in pairs(gtBAT) do tBattleAttr[v] = 0 end
	tBattleAttr[gtBAT.eQX] = tSubMonConf.fnHP(nLevel)
	tBattleAttr[gtBAT.eGJ] = tSubMonConf.fnAtk(nLevel)
	tBattleAttr[gtBAT.eFY] = tSubMonConf.fnDef(nLevel)
	tBattleAttr[gtBAT.eLL] = tSubMonConf.fnMana(nLevel)
	tBattleAttr[gtBAT.eSD] = tSubMonConf.fnSpeed(nLevel)
	tBattleAttr[gtBAT.eMF] = tSubMonConf.fnMag(nLevel)
	tBTData.tBattleAttr = tBattleAttr

	tBTData.nMaxHP = tBTData.tBattleAttr[gtBAT.eQX]
	tBTData.nMaxMP = tBTData.tBattleAttr[gtBAT.eMF]

	tBTData.bAuto = true
	tBTData.nWeaponAtk = 0

	tBTData.tPetMap = {}
	tBTData.tPropList = {}

	local tSkillData = CPet:PetHandleSkills(tPetConf.tMskill, tPetConf.tTskill)
	tBTData.tActSkillMap, tBTData.tPasSkillMap = CPet:GetSKill(tSkillData, nLevel)
	return tBTData
end

function CArenaRobot:GetBattlePartner()
	local tBattlePartner = {}
	for k, oPartner in pairs(self.m_tPartnerMap) do
		table.insert(tBattlePartner, oPartner)
	end
	return tBattlePartner
end

function CArenaRobot:GetRobotBattleData()
	local tConf = self:GetConf()
	local nLevel = self:GetLevel()

	local tBTData = {}
	--基本信息
	tBTData.nSpouseID = 0
	tBTData.nObjID = self.m_nID
	tBTData.nObjType = self:GetObjType()
	tBTData.sObjName = self:GetName()
	tBTData.nLevel = nLevel
	tBTData.nExp = 0
	tBTData.sModel = self:GetRoleConf().sModel
	tBTData.nSchool = self:GetSchool()
	tBTData.bMirror = true

	local tBattleAttr = {}
	for _, v in pairs(gtBAT) do tBattleAttr[v] = 0 end
	local tSubMonConf = ctSubMonsterConf[tConf.nAttrConf]
	tBattleAttr[gtBAT.eQX] = tSubMonConf.fnHP(nLevel)
	tBattleAttr[gtBAT.eGJ] = tSubMonConf.fnAtk(nLevel)
	tBattleAttr[gtBAT.eFY] = tSubMonConf.fnDef(nLevel)
	tBattleAttr[gtBAT.eLL] = tSubMonConf.fnMana(nLevel)
	tBattleAttr[gtBAT.eSD] = tSubMonConf.fnSpeed(nLevel)
	tBattleAttr[gtBAT.eMF] = tSubMonConf.fnMag(nLevel)

	tBTData.tBattleAttr = tBattleAttr
	tBTData.nMaxHP = tBattleAttr[gtBAT.eQX]
	tBTData.nMaxMP = tBattleAttr[gtBAT.eMF]

	--自动战斗
	tBTData.bAuto = true

	--武器攻击
	tBTData.nWeaponAtk = tSubMonConf.fnWeaponAtk(nLevel)

	--宠物
	tBTData.tPetMap = {}
	if tConf.nPetID > 0 and tConf.nPetAttr > 0 then 
		tBTData.tPetMap[1] = self:GetPetBattleData(tConf.nPetID, tConf.nPetAttr)
		tBTData.nCurrPet = 1
	end

	--道具列表
	tBTData.tPropList = {}
	--主动被动技能
	tBTData.tActSkillMap = {}
	for _, tSkill in ipairs(tSubMonConf.tActSkill) do
		if tSkill[1] > 0 then
			local nRnd = math.random(100)
			if nRnd <= tSkill[2] then
				tBTData.tActSkillMap[tSkill[1]] = {nLevel=nLevel, sName=ctSkillConf[tSkill[1]].sName}
			end
		end
	end
	tBTData.tPasSkillMap = {}
	for _, tSkill in ipairs(tSubMonConf.tPasSkill) do
		if tSkill[1] > 0 then
			local nRnd = math.random(100)
			if nRnd <= tSkill[2] then
				tBTData.tPasSkillMap[tSkill[1]] = {nLevel=nLevel, sName=ctPetSkillConf[tSkill[1]].sName}
			end
		end
	end

	--修炼系统
	tBTData.tPracticeMap = {}

	return tBTData
end

function CArenaRobot:GetBattleData()
	local tBattleData = {tUnitMap={}}
	tBattleData.nFmtID, tBattleData.nFmtLv = self:GetUseFmt()
	tBattleData.tFmtAttrAdd = CFormation:GetAttrAddByFmtAndLv(tBattleData.nFmtID, tBattleData.nFmtLv)
	tBattleData.nTeamID = 0
	tBattleData.tUnitMap = {}

	local nUnitID = 201
	local tPartnerList = self:GetBattlePartner()
	local tBTData = self:GetRobotBattleData() 
	tBattleData.tUnitMap[nUnitID] = tBTData
	if #tPartnerList > 0 then
		for k = 1, #tPartnerList do
			nUnitID = nUnitID + 1
			local oPartner = tPartnerList[k]
			local tBTData = oPartner:GetArenaBattleData()
			tBattleData.tUnitMap[nUnitID] = tBTData
			if nUnitID >= 205 then
				break
			end
		end
	end

	return tBattleData
end


