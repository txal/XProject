--伙伴对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPartnerObj:Ctor(oModule, nID, nLevel)
	local tConf = assert(ctPartnerConf[nID], "找不到配置，伙伴ID<"..nID..">的配置不存在")
	self.m_oModule = oModule
	self.m_nID = nID
	self.m_sName = tConf.sName
	self.m_nType = tConf.nType
	self.m_nGradeID = tConf.nGradeID --评级ID
	self.m_nSpiritGrade = nil        --灵气升级评级ID 暂时置空，防止后续再次功能更改
	self.m_nStarLevel = tConf.nStar --星级
	self.m_nStarCount = gtPartnerStarLevel.eMinStarCount --当前星级已点亮星星数量
	self.m_sModel = tConf.sModel --模型
	self.m_nLevel = nLevel or 0
	self.m_nIntimacy = 0              --亲密度
	self.m_nSpirit = 0                --灵气
	-- self.m_nAddSpiritStamp = 0        --灵气操作时间戳
	self.m_tGiftPropAttr = {} --{AttrType:AttrValue}通过礼物道具获得的属性值加成，可考虑直接根据record中数据计算
	self.m_tGiftPropRecord = {}  --{nPropID:nNum} 记录每种礼物道具当前已经使用的数量
	for k, v in pairs(ctPartnerGiftConf) do 
		if k > 0 then
			self.m_tGiftPropRecord[k] = 0
		end
	end

	self.m_tReviveData = {}              --觉醒数据
	self.m_tReviveData.nLevel = 0
	self.m_tReviveData.nExp = 0

	--self.m_nGiftPropLimit = 5   --可送礼物数量上限
	self.m_tBaseAttr = {}       --伙伴基础属性
	self.m_tAttr = {}           --伙伴最终属性
	for k, v in pairs(gtBAT) do
		self.m_tBaseAttr[v] = 0
		self.m_tAttr[v] = 0
	end
	self.m_nWeaponAtk = 0  --武器攻击
	self.m_tActSkillMap = {}
	self.m_tPasSkillMap = {}
	self.m_nFightAbility = self:CalcFightAbility()
end

function CPartnerObj:LoadData(tData)
	if not tData then return end 
	self.m_nSpiritGrade = tData.m_nSpiritGrade or self.m_nSpiritGrade
	if self.m_nSpiritGrade and self.m_nSpiritGrade > self.m_nGradeID then 
		self.m_nGradeID = self.m_nSpiritGrade
	end
	self.m_nStarLevel = tData.m_nStarLevel
	self.m_nStarCount = tData.m_nStarCount
	self.m_nIntimacy = tData.m_nIntimacy
	self.m_nSpirit = tData.m_nSpirit or self.m_nSpirit
	-- self.m_nAddSpiritStamp = tData.m_nAddSpiritStamp or self.m_nAddSpiritStamp
	--不直接引用，可能策划配置新增类型，这里引用旧table，会丢失了构造函数中的预处理数据，导致后续逻辑处理，取新增类型的值，为nil
	for k, v in pairs(tData.m_tGiftPropRecord) do
		if ctPartnerGiftConf[k] then 
			self.m_tGiftPropRecord[k] = v
		else  --被删除了的
			self.m_oModule:MarkDirty(true)
		end
	end
	self:UpdateGiftAttr()

	self.m_tReviveData = tData.m_tReviveData or self.m_tReviveData

	self.m_nFightAbility = tData.m_nFightAbility or self.m_nFightAbility

	self:UpdateGrade()
	self:UpdateAttr()  --这里不更新战力，会触发角色战力变化导致同步数据，但是角色数据此时可能没初始化完成
end

function CPartnerObj:SaveData()
	local tData = {}
	tData.m_nID = self.m_nID
	tData.m_nStarLevel = self.m_nStarLevel
	tData.m_nStarCount = self.m_nStarCount
	tData.m_nIntimacy = self.m_nIntimacy
	tData.m_nSpirit = self.m_nSpirit
	-- tData.m_nAddSpiritStamp = self.m_nAddSpiritStamp
	-- tData.m_tGiftPropAttr = self.m_tGiftPropAttr
	tData.m_tGiftPropRecord = self.m_tGiftPropRecord
	-- tData.m_nGradeID = self.m_nGradeID
	tData.m_nSpiritGrade = self.m_nSpiritGrade
	tData.m_nFightAbility = self.m_nFightAbility
	tData.m_tReviveData = self.m_tReviveData
	--战斗属性以及策划配置属性，每次load时，重新计算，无需保存
	return tData
end

function CPartnerObj:Online()
	self:UpdateFightAbility()
end

--更新伙伴技能  --升级和升星都会触发
function CPartnerObj:UpdateSkill()
	local nLevel = self:GetLevel()
	local nGrade = self:GetGrade()
	local nStarLevel = self:GetStarLevel()

	local tActSkillConf = self:GetConf().tActSkill
	local tActSkill = {}
	for k, v in ipairs(tActSkillConf) do
		if v[1] > 0 and nLevel >= v[2] then
			table.insert(tActSkill, {v[1], v[3]})
		end
	end
	self.m_tActSkillMap = tActSkill

	local tPasSkill = {}
	local tPasSkillConf = self:GetConf().tPasSkill
	for k, tSkillConf in ipairs(tPasSkillConf) do
		if tSkillConf[4] and tSkillConf[4] > 0 and nStarLevel >= tSkillConf[2] and nGrade >= tSkillConf[5] then 
			table.insert(tPasSkill, tSkillConf[4])
		elseif tSkillConf[1] > 0 and nStarLevel >= tSkillConf[2] and nGrade >= tSkillConf[3] then
			table.insert(tPasSkill, tSkillConf[1])
		end
	end
	self.m_tPasSkillMap = tPasSkill
end

--获取战斗力
function CPartnerObj:GetFightAbility()
	return self.m_nFightAbility
end

function CPartnerObj:CalcFightAbility() 
	local nBaseScore = 0
	local tGradeConf = self:GetGradeConf()
	if tGradeConf then
		nBaseScore = tGradeConf.fnFightAbility(self:GetLevel())
	end
	local nAttrScore = 0
	for nAttrID, nAttrVal in pairs(self.m_tAttr) do 
		nAttrScore = nAttrScore + CUtil:CalcAttrScore(nAttrID, nAttrVal)
	end
	local nSkillScore = self:CalcSkillScore()*100
	return nAttrScore + nBaseScore + nSkillScore
end

function CPartnerObj:CalcSkillScore()
	local nSkillScore = 0
	for _, nSkillID in pairs(self.m_tPasSkillMap) do
		local tConf = ctPetSkillConf[nSkillID]
		if tConf then
			if tConf.nSkType == getPetSkillsClassify.eLowlevel then
				nSkillScore = nSkillScore + 300
			else
				nSkillScore = nSkillScore + 600
			end
		end
	end
	return nSkillScore
end

--更新战斗力
function CPartnerObj:UpdateFightAbility()
	local nOldVal = self:GetFightAbility()
	self.m_nFightAbility = self:CalcFightAbility() 
	if nOldVal ~= self.m_nFightAbility then 
		self:OnFightAbilityChange(nOldVal)
		self.m_oModule:MarkDirty(true)
	end
	return
end

function CPartnerObj:OnFightAbilityChange(nOldVal)
	self.m_oModule:OnPartnerPowerChange()
end

--获取武器攻击
function CPartnerObj:GetWeaponAtk()
	return self.m_nWeaponAtk
end

function CPartnerObj:GetAttrStarLevel(nAttrType)
	local bExist = false
	for k, v in pairs(gtPartnerStarAttr) do
		if v == nAttrType then
			bExist = true
			break
		end
	end
	assert(bExist, "错误的属性类型")

	local nLevel, nCount = self:GetStarLevel()
	local nAttrStarLevel = nLevel
	for i = 1, nCount do
		if gtPartnerStarAttr[i] == nAttrType then
			nAttrStarLevel = nAttrStarLevel + 1
			break
		end
	end
	return nAttrStarLevel
end

function CPartnerObj:UpdateGiftAttr() 
	self.m_tGiftPropAttr = {}
	for nPropID, nPropNum in pairs(self.m_tGiftPropRecord) do 
		local tConf = ctPartnerGiftConf[nPropID]
		self.m_tGiftPropAttr[tConf.nAttrType] = (self.m_tGiftPropAttr[tConf.nAttrType] or 0) + tConf.nAttrValue * nPropNum
	end
	for nAttrType, nAttrVal in pairs(self.m_tGiftPropAttr) do 
		self.m_tGiftPropAttr[nAttrType] = math.floor(nAttrVal)
	end
end


--更新属性
--请注意，CArenaRobot会调用这个，不要在这个函数中，增加self.m_oModule相关联的调用
function CPartnerObj:UpdateAttr() 
	self:UpdateSkill() --更新下技能
	self:UpdateGiftAttr()
	
	self.m_tAttr = {}
	for k, v in pairs(gtBAT) do
		self.m_tAttr[v] = 0
	end
	local tBaseAttr = {} --缓存计算过程中间数据
	for k, v in pairs(gtBAT) do
		tBaseAttr[v] = 0
	end
	local tEquipAttr = {} --缓存计算过程中间数据
	for k, v in pairs(gtBAT) do
		tEquipAttr[v] = 0
	end

	local tConf = self:GetConf()
	local nPartnerLv = self:GetLevel()
	local nPartnerStarLevel = self:GetStarLevel()
	local nStarEffect = tConf.fnStarEffect(nPartnerStarLevel)
	tBaseAttr[gtBAT.eQX] = tConf.fnBaseHp(nPartnerLv)
	tBaseAttr[gtBAT.eMF] = tConf.fnBaseMp(nPartnerLv)
	tBaseAttr[gtBAT.eGJ] = tConf.fnBaseAttack(nPartnerLv)
	tBaseAttr[gtBAT.eFY] = tConf.fnBaseDefense(nPartnerLv)
	tBaseAttr[gtBAT.eLL] = tConf.fnBaseMagic(nPartnerLv)
	tBaseAttr[gtBAT.eSD] = tConf.fnBaseSpeed(nPartnerLv)

	tEquipAttr[gtBAT.eQX] = tConf.fnEquipHp(nPartnerLv, nStarEffect)
	tEquipAttr[gtBAT.eMF] = tConf.fnEquipMp(nPartnerLv, nStarEffect)
	tEquipAttr[gtBAT.eGJ] = tConf.fnEquipAttack(nPartnerLv, nStarEffect)
	tEquipAttr[gtBAT.eFY] = tConf.fnEquipDefense(nPartnerLv, nStarEffect)
	tEquipAttr[gtBAT.eLL] = tConf.fnEquipMagic(nPartnerLv, nStarEffect)
	tEquipAttr[gtBAT.eSD] = tConf.fnEquipSpeed(nPartnerLv, nStarEffect)

	--基础属性计算完成，统一math.floor处理下所有基础属性
	for k, v in pairs(gtBAT) do
		tBaseAttr[v] = math.floor(tBaseAttr[v])
	end	
	self.m_tBaseAttr = tBaseAttr

	--属性计算公式
	local nGrade = self:GetGrade()
	local nGrowthID = CPartner:GetReviveGrowthID()
	local nReviveRatio = ctRoleGrowthConf[nGrowthID].nParam
	local nReviveLevel = self:GetReviveLevel()
	local nReviveAdd = nReviveRatio * nReviveLevel

	for nAttrID, tAttrConf in pairs(ctPartnerAttrCalcConf) do 
		local nBaseAttr = self.m_tBaseAttr[nAttrID] or 0
		local nEquAttr = tEquipAttr[nAttrID] or 0
		local nAttrStarLevel = self:GetAttrStarLevel(nAttrID) or 0
		self.m_tAttr[nAttrID] = 
			(tAttrConf.fnAttr(nBaseAttr, nEquAttr, nAttrStarLevel, nGrade)) * (1 + nReviveAdd)
	end

	--礼物属性加成
	for k, v in pairs(self.m_tGiftPropAttr) do
		self.m_tAttr[k] = self.m_tAttr[k] + v
	end

	--所有计算完成后，在最后统一math.floor处理下所有属性
	for k, v in pairs(gtBAT) do
		self.m_tAttr[v] = math.floor(self.m_tAttr[v])
	end	
	self.m_nWeaponAtk = math.floor(tConf.fnWeaponAttack(nPartnerLv)) --武器攻击
end

--更新综合属性
function CPartnerObj:UpdateProperty()
	self:UpdateAttr()
	self:UpdateFightAbility()
end

--获取属性列表
function CPartnerObj:GetAttrList()
	return self.m_tAttr
end

--获取战斗相关数据
function CPartnerObj:GetBattleData(bMirror)
	local tBTData = {}
	tBTData.nObjID = self:GetID()
	tBTData.nObjType = self:GetObjType()
	tBTData.sObjName = self:GetName()
	tBTData.nRoleID = self.m_oModule.m_oRole:GetID()
	tBTData.nLevel = self:GetLevel()
	tBTData.nExp = 0
	tBTData.sModel = self:GetModel()
	tBTData.nSchool = self:GetSchool()
	tBTData.bMirror = bMirror
	tBTData.sGrade = self:GetGradeConf().sGrade

	tBTData.nMaxHP = self:GetAttr(gtBAT.eQX)
	tBTData.nMaxMP = self:GetAttr(gtBAT.eMF)
	tBTData.tBattleAttr = table.DeepCopy(self:GetAttrList())

	tBTData.bAuto = true
	tBTData.nWeaponAtk = self:GetWeaponAtk()
	tBTData.tPetMap = {}

	--技能数据
	local tActSkillMap = {}
	for _, tSkill in pairs(self.m_tActSkillMap) do
		local tSkillConf = ctSkillConf[tSkill[1]] or ctPetSkillConf[tSkill[1]]
		tActSkillMap[tSkill[1]] = {nLevel=self:GetLevel(), sName=tSkillConf.sName}
	end
	tBTData.tActSkillMap = tActSkillMap

	local tPasSkillMap = {}
	for _, nSkill in pairs(self.m_tPasSkillMap) do
		local tSkillConf = ctPetSkillConf[nSkill]
		tPasSkillMap[nSkill] = {nLevel=self:GetLevel(), sName=tSkillConf.sName}
	end
	tBTData.tPasSkillMap = tPasSkillMap

	--修炼系统
	tBTData.tPracticeMap = self.m_oModule.m_oRole.m_oPractice:GetPracticeMap()
	
	return tBTData
end

--竞技场机器人获取战斗属性用
function CPartnerObj:GetArenaBattleData(nRobotID)
	local tBTData = {}
	tBTData.nObjID = self:GetID()
	tBTData.nObjType = self:GetObjType()
	tBTData.sObjName = self:GetName()
	tBTData.nRoleID = nRobotID
	tBTData.nLevel = self:GetLevel()
	tBTData.nExp = 0
	tBTData.sModel = self:GetModel()
	tBTData.nSchool = self:GetSchool()
	tBTData.bMirror = true

	tBTData.nMaxHP = self:GetAttr(gtBAT.eQX)
	tBTData.nMaxMP = self:GetAttr(gtBAT.eMF)
	tBTData.tBattleAttr = table.DeepCopy(self:GetAttrList())

	tBTData.bAuto = true
	tBTData.nWeaponAtk = self:GetWeaponAtk()
	tBTData.tPetMap = {}

	--技能数据
	local tActSkillMap = {}
	for _, tSkill in pairs(self.m_tActSkillMap) do
		local tSkillConf = ctSkillConf[tSkill[1]] or ctPetSkillConf[tSkill[1]]
		tActSkillMap[tSkill[1]] = {nLevel=self:GetLevel(), sName=tSkillConf.sName}
	end
	tBTData.tActSkillMap = tActSkillMap

	local tPasSkillMap = {}
	for _, nSkill in pairs(self.m_tPasSkillMap) do
		local tSkillConf = ctPetSkillConf[nSkill]
		tPasSkillMap[nSkill] = {nLevel=self:GetLevel(), sName=tSkillConf.sName}
	end
	tBTData.tPasSkillMap = tPasSkillMap

	--修炼系统
	tBTData.tPracticeMap = {}
	
	return tBTData
end

--获取属性值
function CPartnerObj:GetAttr(nAttrType)
	local nValue = self.m_tAttr[nAttrType]
	if not nValue then --nil
		assert(false, "属性类型不存在")
	end
	return nValue
end

function CPartnerObj:SetAttr(nAttrType, nAttrValue)
	if not self.m_tAttr[nAttrType] then
		assert(false, "属性类型错误")
	end
	self.m_tAttr[nAttrType] = nAttrValue
end

--获取伙伴亲密度
function CPartnerObj:GetIntimacy()
	return self.m_nIntimacy
end

function CPartnerObj:IsIntimacyMax()
	return self.m_nIntimacy >= gnPartnerIntimacyMaxValue
end

-- function CPartnerObj:SetIntimacy(nValue)
-- 	if nValue < 0 then
-- 		return
-- 	end
-- 	if nValue > gnPartnerIntimacyMaxValue then
-- 		nValue = gnPartnerIntimacyMaxValue
-- 	end
-- 	self.m_nIntimacy = nValue
-- end

function CPartnerObj:AddIntimacy(nValue)
	local nOldValue = self:GetIntimacy()
	self.m_nIntimacy = math.min(math.max(self:GetIntimacy() + nValue, 0), gnPartnerIntimacyMaxValue)

	local nChangeVal = self:GetIntimacy() - nOldValue
	if nChangeVal ~= 0 then
		self:OnIntimacyChanged(nOldVal, nChangeVal)
	end
end

function CPartnerObj:OnIntimacyChanged(nOldVal, nChangeVal) 
	--仙侣亲密度涨幅统计
	if nChangeVal ~= 0 then
		local oRole = self.m_oModule.m_oRole
	    Network.oRemoteCall:Call("OnCBQMDReq", oRole:GetServer(), goServerMgr:GetGlobalService(oRole:GetServer(), 20), 0, oRole:GetID(), nChangeVal) 
	end
end

function CPartnerObj:OnAddStarCount() 
	CEventHandler:OnPartnerLearn(self.m_oModule.m_oRole, {})
end

function CPartnerObj:OnStarLevelUp()
	CEventHandler:OnPartnerUpStar(self.m_oModule.m_oRole, {})
	self:UpdateProperty()
end

--星级升级
function CPartnerObj:StarLevelUp()
	if self:IsMaxStarLevel() then 
		return 
	end
	local tTmpPasSkill = self.m_tPasSkillMap

	if self.m_nStarLevel < gtPartnerStarLevel.eMaxStarLevel then
		self.m_nStarLevel = self.m_nStarLevel + 1
		self.m_nStarCount = gtPartnerStarLevel.eMinStarCount
		self.m_oModule:MarkDirty(true)
		self:OnStarLevelUp()
	end

	--新开启的被动技能
	for k=#tTmpPasSkill+1, #self.m_tPasSkillMap do
		local sName = ctPetSkillConf[self.m_tPasSkillMap[k]].sName
		return self.m_nStarLevel, sName
	end
end

--点亮星级星星
function CPartnerObj:AddStarCount()
	if self.m_nStarCount < gtPartnerStarLevel.eMaxStarCount then
		self.m_nStarCount = self.m_nStarCount + 1
		self.m_oModule:MarkDirty(true)
		self:OnAddStarCount()
	end
end

function CPartnerObj:IsMaxStarLevel()
	if self.m_nStarLevel >= gtPartnerStarLevel.eMaxStarLevel then
		return true
	end
	return false
end

function CPartnerObj:IsMaxStarCount()
	if self.m_nStarCount >= gtPartnerStarLevel.eMaxStarCount then 
		return true  
	end
	return false
end

--点亮下一颗星星需要的材料ID及数量
function CPartnerObj:GetStarLevelMaterial()
	if self:IsMaxStarLevel() then
		return
	end
	local tConf = self:GetConf()
	local tStarConf = ctPartnerStarLevelConf[self.m_nStarLevel+1]
	if tConf and tStarConf then
		return tConf.nStarLeveCost, tStarConf.nMaterialNum
	end
end

function CPartnerObj:GetID() return self.m_nID end
function CPartnerObj:GetConf() return ctPartnerConf[self.m_nID] end		--伙伴配置
function CPartnerObj:GetGradeConf() return ctPartnerGradeConf[self.m_nGradeID] end --伙伴评级配置
function CPartnerObj:GetName() return self.m_sName end		--名字
function CPartnerObj:GetHeader() return self:GetConf().sHeader end	--头像
function CPartnerObj:GetGender() return self:GetConf().nGender end	--性别
function CPartnerObj:GetType() return self.m_nType end 		--类型   --是哪种类型的伙伴，非哪种类型对象(角色、宠物还是伙伴)
function CPartnerObj:GetObjType() return gtObjType.ePartner end
function CPartnerObj:GetModel() return self:GetConf().sModel end
function CPartnerObj:GetGrade() return self.m_nGradeID end
function CPartnerObj:GetSchool() return self:GetConf().nSchool end
function CPartnerObj:IsHighestGrade() return self.m_nGradeID >= gtPartnerGrade.eSSS end 
function CPartnerObj:GetSpirit() return self.m_nSpirit end 

function CPartnerObj:GetLevel() --等级
	return self.m_nLevel
end

function CPartnerObj:SetLevel(nLevel)
	self.m_nLevel = nLevel
	self:OnLevelChange()
end

function CPartnerObj:OnLevelChange()
	self:UpdateProperty()
end

function CPartnerObj:GetStarLevel() return self.m_nStarLevel, self.m_nStarCount end  --星级及数量

--获取礼物道具已使用次数
function CPartnerObj:GetPartnerGiftPropRecordNum(nPropID)
	local nCurPropNum = self.m_tGiftPropRecord[nPropID]
	if not nCurPropNum then --没有记录，即原来数量为0
		nCurPropNum = 0
	end
	return nCurPropNum
end

--获取当前宠物可送礼物道具数量上限
function CPartnerObj:GetGiftPropLimitNum(nPropID)
	local tConf = ctPartnerGiftConf[nPropID]
	assert(tConf)
	return math.floor(tConf.fnLimitNum(self:GetLevel()))
end

--检查当前礼物道具是否可继续添加并返回可添加数量
function CPartnerObj:CheckCanSendGiftProp(nPropID)
	if not CPartner:CheckIsPartnerGiftProp(nPropID) then
		return false, 0
	end
	local nCurPropNum = self:GetPartnerGiftPropRecordNum(nPropID)
	local nLimitNum = self:GetGiftPropLimitNum(nPropID)
	if nCurPropNum >= nLimitNum then
		return false, 0
	end
	return true, nLimitNum - nCurPropNum
end

--给伙伴送礼物道具 --请在外层检查当前是否超过礼物数量限制
function CPartnerObj:SendGift(tProp)  -- tProp {PropID : PropNum, ...}
	local bAddFlag = false
	print("送礼道具", tProp)
	for nPropID, nAddNum in pairs(tProp) do
		local tConf = ctPartnerGiftConf[nPropID]
		if not tConf then
			return
		end

		if not self.m_tAttr[tConf.nAttrType] then --属性类型必须是合法存在的
			assert(false, "属性类型错误")
		end

		--添加亲密度
		local nIntimacyAdd = math.floor(tConf.nIntimacy * nAddNum)
		self:AddIntimacy(nIntimacyAdd)
		--添加送礼记录
		local nRecordNum = self:GetPartnerGiftPropRecordNum(nPropID)
		self.m_tGiftPropRecord[nPropID] = nRecordNum + nAddNum
		bAddFlag = true
		self.m_oModule:MarkDirty(true)
		self:UpdateProperty()
	end
	return bAddFlag
end

-- function CPartnerObj:CheckAddSpiritStamp(nTimeStamp)
-- 	nTimeStamp = nTimeStamp or os.time()
-- 	if os.IsSameDay(self.m_nAddSpiritStamp, nTimeStamp, 0) then 
-- 		return false 
-- 	end
-- 	return true 
-- end

-- function CPartnerObj:SetSpiritOpStamp(nTimeStamp)
-- 	nTimeStamp = nTimeStamp or os.time()
-- 	self.m_nAddSpiritStamp = nTimeStamp
-- 	self.m_oModule:MarkDirty(true)
-- end

function CPartnerObj:CheckCanAddSpirit()
	if self:IsHighestGrade() then 
		return false, "已达最高品质"
	end
	local nIntimacyLimit = 10
	if self:GetIntimacy() <= nIntimacyLimit then 
		return false, string.format("亲密度不足%d", nIntimacyLimit)
	end
	if self:GetStarLevel() < 5 then 
		return false, string.format("仙侣星级需达到5星")
	end
	-- if not self:CheckAddSpiritStamp() then 
	-- 	return false, "今日已服用"
	-- end
	return true
end

function CPartnerObj:OnGradeChange(nOld, nCur)
	nCur = nCur or self.m_nGradeID
	self:UpdateProperty()
end

function CPartnerObj:UpdateGrade()
	if self:IsHighestGrade() then 
		return 
	end
	local tConf = assert(self:GetGradeConf(), "配置不存在")
	if tConf.nGradeLevelUpSpirit > 0 then --防止配置错误
		if self:GetSpirit() >= tConf.nGradeLevelUpSpirit then
			local nOldGrade = self.m_nGradeID
			self.m_nGradeID = gtPartnerGrade.eSSS
			self.m_nSpiritGrade = self.m_nGradeID
			self:OnGradeChange(nOldGrade)
			self.m_oModule:MarkDirty(true)
		end
	end
end

function CPartnerObj:AddSpirit(nVal)
	self.m_nSpirit = self.m_nSpirit + nVal
	self:UpdateGrade()
	self.m_oModule:MarkDirty(true)
end

--获取伙伴简要数据
function CPartnerObj:GetBriefData()
	local tData = {}
	tData.nID = self.m_nID
	tData.nGrade = self:GetGrade()
	tData.nStarLevel = self.m_nStarLevel
	tData.nStarCount = self.m_nStarCount
	tData.nLevel = self:GetLevel()
	tData.nFightAbility = self:GetFightAbility()
	tData.nIntimacy = self:GetIntimacy()
	return tData
end

--获取伙伴详细数据，客户端协议用数据
function CPartnerObj:GetDetailData()
	local tData = {}
	tData.nID = self.m_nID
	tData.nGrade = self:GetGrade()
	tData.nStarLevel = self.m_nStarLevel
	tData.nStarCount = self.m_nStarCount
	tData.nLevel = self:GetLevel()
	tData.nFightAbility = self:GetFightAbility()
	tData.nIntimacy = self:GetIntimacy()
	tData.tGiftPropRecord = {}
	for k, v in pairs(self.m_tGiftPropRecord) do
		table.insert(tData.tGiftPropRecord, {nKey = k, nValue = v})
	end
	tData.nGiftPropLimitNum = 0 --self:GetGiftPropLimitNum()
	tData.tGiftPropAttrList = {}
	for k, v in pairs(self.m_tGiftPropAttr) do
		table.insert(tData.tGiftPropAttrList, {nAttrID = k, nAttrVal = v})
	end
	tData.tBaseAttrList = {}
	for k, v in pairs(self.m_tBaseAttr) do
		table.insert(tData.tBaseAttrList, {nAttrID = k, nAttrVal = v})
	end
	tData.tAttrList = {}
	for k, v in pairs(self.m_tAttr) do
		table.insert(tData.tAttrList, {nAttrID = k, nAttrVal = v})
	end
	tData.nWeaponAtk = self:GetWeaponAtk()
	-- tData.bDailyAddSpiritOp = (not self:CheckAddSpiritStamp())
	tData.nSpirit = self:GetSpirit()
	tData.nLevelUpSpirit = self:GetGradeConf().nGradeLevelUpSpirit

	local tReviveData = {}
	tReviveData.nLevel = self:GetReviveLevel()
	tReviveData.nExp = self:GetReviveExp()
	tData.tReviveData = tReviveData

	return tData
end

function CPartnerObj:OnBattleEnd(tBTRes, tExtData)
	--吴凡策划说了，伙伴去掉饱食度恢复血量魔法，默认恢复
	print("伙伴战斗结束", self:GetName(), tBTRes)
end

function CPartnerObj:OnBattleBegin(nBattleID)
end

--仙侣觉醒功能
function CPartnerObj:GetReviveLevel()
	return self.m_tReviveData.nLevel or 0
end

function CPartnerObj:SetReviveLevel(nTarLevel) 
	self.m_tReviveData.nLevel = nTarLevel
	self.m_oModule:MarkDirty(true)
end

function CPartnerObj:GetReviveExp() 
	return self.m_tReviveData.nExp or 0
end

function CPartnerObj:SetReviveExp(nTarExp)
	self.m_tReviveData.nExp = nTarExp
	self.m_oModule:MarkDirty(true)
end

function CPartnerObj:OnReviveLevelUp(nOldLevel)
	self:UpdateProperty()
end

function CPartnerObj:AddReviveExp(nAddExp)
	local nGrowthID = self.m_oModule:GetReviveGrowthID()
	local nCurLevel = self:GetReviveLevel()
	local nLimitLevel = self.m_oModule:GetReviveLimitLevel()
	local nCurExp = self:GetReviveExp()
	local nTarLevel, nTarExp = ctRoleGrowthConf.AddExp(nGrowthID, nCurLevel, nLimitLevel, nCurExp, nAddExp)
	self:SetReviveLevel(nTarLevel)
	self:SetReviveExp(nTarExp)
	self:OnReviveLevelUp(nCurLevel)
end
