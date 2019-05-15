--被动技能
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local gtBTT, gtBAT, gtBTRes, gtRatioAttr, gtACT, GetActTime, gtAddAttrModType, gtBATName
= gtBTT, gtBAT, gtBTRes, gtRatioAttr, gtACT, GetActTime, gtAddAttrModType, gtBATName

--被动技能属性加成相关字段
CPasSkillHelper.tPasSkillContext =
{
	tSkillMap = {}, 		--触发的被动技能表
	tAttrAdd = {}, 			--通用属性加成
	bPursuit = false, 		--追击
	nPursuitHurt = 0, 		--追击伤害加成
	bDoubleHit = false, 	--连击
	nDoubleHitHurt = 0, 	--连击伤害加成
	bSuck = false,  		--吸血
	nSuckRatio = 0, 		--吸血比例
	bSkillDoubleHit = false,--技能连击
	nSkillDoubleHitHurt = 0,--技能连击伤害加成
	bIgnSkillDoubleHit = false,--忽略技能连击
	bSingleAtk = true,		--是否单体攻击
}

--触发类型
CPasSkillHelper.tTriggerType = 
{
	eEnter = 1, 		--进入战斗时
	eNorPhyAtk = 2, 	--普通物理攻击时
	eBePhyAtk = 3, 		--受到物理攻击时
	eDead = 4, 			--死亡时
	eMagAtk = 5, 		--法术攻击
	eExecSkill = 6, 	--使用技能时
	eSelectTarget = 7, 	--选择目标时
	eBeCure = 8, 		--受到治疗时
	eTargetDead = 9, 	--敌人死亡时	
	ePreDead = 10, 		--将要死亡时	
	ePhyAtk = 11, 		--物理攻击时(普通+物理系技能)
}

--构造函数
function CPasSkillHelper:Ctor(oBattle)
	self.m_tSkillAttrMap = {}
	self.m_oBattle = oBattle
end

--取技能属性加成
function CPasSkillHelper:GetSkillAttr(nSKID, nType)
	self.m_tSkillAttrMap[nSKID] = self.m_tSkillAttrMap[nSKID] or {}
	return (self.m_tSkillAttrMap[nSKID][nType] or 0)
end

--设置技能属性加成
function CPasSkillHelper:AddSkillAttr(nSKID, nType, nVal)
	self.m_tSkillAttrMap[nSKID] = self.m_tSkillAttrMap[nSKID] or {}
	self.m_tSkillAttrMap[nSKID][nType] = (self.m_tSkillAttrMap[nSKID][nType] or 0) + nVal
end

--清空技能属性加成
function CPasSkillHelper:ClearSkillAttr(nSKID)
	self.m_tSkillAttrMap[nSKID] = {}
end

--执行
CPasSkillHelper.fnExecute = {}

--连击
CPasSkillHelper.fnExecute[5102] = function(self, nSKID, nTriggerType, oSrcUnit, oTarUnit, tParentAct, tCtx)
	assert(tCtx, "环境不存在")
	local nTarUnitLevel = oTarUnit:GetLevel()
	local tSkillConf = ctPetSkillConf[nSKID]
	tCtx.bDoubleHit = true
	tCtx.tSkillMap[nSKID] = 1

	for _, tAttr in ipairs(tSkillConf.tAttr) do
		if tAttr[1] == 0 or tAttr[1] == nTriggerType then
			local nAddVal = math.floor(tAttr[4](nTarUnitLevel))
			tCtx.nDoubleHitHurt = tCtx.nDoubleHitHurt + nAddVal
		end
	end
	return oSrcUnit --作用目标
end
CPasSkillHelper.fnExecute[5202] = CPasSkillHelper.fnExecute[5102]

--追击
CPasSkillHelper.fnExecute[5104] = function(self, nSKID, nTriggerType, oSrcUnit, oTarUnit, tParentAct, tCtx)
	assert(tCtx, "环境不存在")
	if not oTarUnit:IsDead() then
		return
	end

	local nTarUnitLevel = oTarUnit:GetLevel()
	local tSkillConf = ctPetSkillConf[nSKID]
	tCtx.tSkillMap[nSKID] = 1
	tCtx.bPursuit = true

	for _, tAttr in ipairs(tSkillConf.tAttr) do
		if tAttr[1] == 0 or tAttr[1] == nTriggerType then
			local nAddVal = math.floor(tAttr[4](nTarUnitLevel))
			tCtx.nPursuitHurt = tCtx.nPursuitHurt  + nAddVal
		end
	end
	return oSrcUnit --作用目标
end
CPasSkillHelper.fnExecute[5204] = CPasSkillHelper.fnExecute[5104]

--驱鬼
CPasSkillHelper.fnExecute[5108] = function(self, nSKID, nTriggerType, oSrcUnit, oTarUnit, tParentAct, tCtx)
	assert(tCtx, "环境不存在")
	local nTarUnitLevel = oTarUnit:GetLevel()
	local tSkillConf = ctPetSkillConf[nSKID]
	tCtx.tSkillMap[nSKID] = 1

	for _, tAttr in ipairs(tSkillConf.tAttr) do
		if tAttr[1] == 0 or tAttr[1] == nTriggerType then
			local nAddVal = math.floor(tAttr[4](nTarUnitLevel))
			tCtx.tAttrAdd[tAttr[2]] = (tCtx.tAttrAdd[tAttr[2]] or 0) + nAddVal
		end
	end
	oSrcUnit:AddRoundFlag(CUnit.tRoundFlag.eIGNGM, nSKID, {nSkillID=nSKID})
	return oSrcUnit --作用目标
end
CPasSkillHelper.fnExecute[5208] = CPasSkillHelper.fnExecute[5108]

--吸血
CPasSkillHelper.fnExecute[5109] = function(self, nSKID, nTriggerType, oSrcUnit, oTarUnit, tParentAct, tCtx)
	assert(tCtx, "环境不存在")
	local nTarUnitLevel = oTarUnit:GetLevel()
	local tSkillConf = ctPetSkillConf[nSKID]
	tCtx.bSuck = true
	tCtx.tSkillMap[nSKID] = 1

	for _, tAttr in ipairs(tSkillConf.tAttr) do
		if tAttr[1] == 0 or tAttr[1] == nTriggerType then
			local nAddVal = math.floor(tAttr[4](nTarUnitLevel))
			tCtx.nSuckRatio =  nAddVal --吸血效果不叠加 单#4604
		end
	end
	return oSrcUnit --作用目标
end
CPasSkillHelper.fnExecute[5209] = CPasSkillHelper.fnExecute[5109]

--报复
CPasSkillHelper.fnExecute[5133] = function(self, nSKID, nTriggerType, oSrcUnit, oTarUnit, tParentAct, tCtx)
	assert(tCtx, "环境不存在")
	local tSkillConf = ctPetSkillConf[nSKID]
	tCtx.tSkillMap[nSKID] = 1

	for _, tAttr in ipairs(tSkillConf.tAttr) do
		if tAttr[1] == 0 or tAttr[1] == nTriggerType then
			local nAddVal = math.floor(tAttr[4](oSrcUnit:GetAttr(gtBAT.eQX), oSrcUnit:MaxAttr(gtBAT.eQX)))
			tCtx.tAttrAdd[tAttr[2]] = (tCtx.tAttrAdd[tAttr[2]] or 0) + nAddVal
		end
	end
	return oSrcUnit --作用目标
end
CPasSkillHelper.fnExecute[5233] = CPasSkillHelper.fnExecute[5133]

--复仇
CPasSkillHelper.fnExecute[5105] = function(self, nSKID, nTriggerType, oSrcUnit, oTarUnit, tParentAct, tCtx)
	assert(tCtx, "环境不存在")
	local nTarUnitLevel = oTarUnit:GetLevel()
	local tSkillConf = ctPetSkillConf[nSKID]
	tCtx.tSkillMap[nSKID] = 1

	for _, tAttr in ipairs(tSkillConf.tAttr) do
		if tAttr[1] == 0 or tAttr[1] == nTriggerType then
			tCtx.tAttrAdd[tAttr[2]] = (tCtx.tAttrAdd[tAttr[2]] or 0) + tAttr[4](nTarUnitLevel)
		end
	end
	oTarUnit:AddRoundFlag(CUnit.tRoundFlag.eCOT, nSKID, {nSKID=0, sGJTips="物理反击", bPasSkill=true})

	return oTarUnit --作用目标
end
CPasSkillHelper.fnExecute[5205] = CPasSkillHelper.fnExecute[5105]

--魔法反击
CPasSkillHelper.fnExecute[5106] = function(self, nSKID, nTriggerType, oSrcUnit, oTarUnit, tParentAct, tCtx)
	assert(tCtx, "环境不存在")
	local nTarUnitLevel = oTarUnit:GetLevel()
	local tSkillConf = ctPetSkillConf[nSKID]
	tCtx.tSkillMap[nSKID] = 1

	for _, tAttr in ipairs(tSkillConf.tAttr) do
		if tAttr[1] == 0 or tAttr[1] == nTriggerType then
			tCtx.tAttrAdd[tAttr[2]] = (tCtx.tAttrAdd[tAttr[2]] or 0) + tAttr[4](nTarUnitLevel)
		end
	end
	oTarUnit:AddRoundFlag(CUnit.tRoundFlag.eCOT, nSKID, {nSKID=tSkillConf.nCOTSkill, sGJTips="魔法反击", bPasSkill=true})

	return oTarUnit --作用目标
end
CPasSkillHelper.fnExecute[5206] = CPasSkillHelper.fnExecute[5106]

--金睛
CPasSkillHelper.fnExecute[5112] = function(self, nSKID, nTriggerType, oSrcUnit, oTarUnit, tParentAct, tCtx)
	assert(tCtx, "环境不存在")
	local nTarUnitLevel = oTarUnit:GetLevel()
	local tSkillConf = ctPetSkillConf[nSKID]
	tCtx.tSkillMap[nSKID] = 1

	for _, tAttr in ipairs(tSkillConf.tAttr) do
		if tAttr[1] == 0 or tAttr[1] == nTriggerType then
			tCtx.tAttrAdd[tAttr[2]] = (tCtx.tAttrAdd[tAttr[2]] or 0) + tAttr[4](nTarUnitLevel)
		end
	end
	oSrcUnit:AddRoundFlag(CUnit.tRoundFlag.eIGNHIDE, nSKID, {})

	return oSrcUnit --作用目标
end
CPasSkillHelper.fnExecute[5212] = CPasSkillHelper.fnExecute[5112]

--法术连击
CPasSkillHelper.fnExecute[5118] = function(self, nSKID, nTriggerType, oSrcUnit, oTarUnit, tParentAct, tCtx)
	assert(tCtx, "环境不存在")
	if tCtx.bIgnSkillDoubleHit then
		return
	end
	
	local nTarUnitLevel = oTarUnit:GetLevel()
	local tSkillConf = ctPetSkillConf[nSKID]
	tCtx.bSkillDoubleHit = true
	tCtx.tSkillMap[nSKID] = 1

	for _, tAttr in ipairs(tSkillConf.tAttr) do
		if tAttr[1] == 0 or tAttr[1] == nTriggerType then
			local nAddVal = math.floor(tAttr[4](nTarUnitLevel))
			tCtx.nSkillDoubleHitHurt = tCtx.nSkillDoubleHitHurt + nAddVal
		end
	end
	return oSrcUnit --作用目标
end
CPasSkillHelper.fnExecute[5218] = CPasSkillHelper.fnExecute[5118]

--重生
CPasSkillHelper.fnExecute[5115] = function(self, nSKID, nTriggerType, oSrcUnit, oTarUnit, tParentAct, tCtx)
	assert(not tCtx)
	local tAttr = ctPetSkillConf[nSKID].tAttr[1]
	assert(tAttr[1] == 0 or tAttr[1] == nTriggerType)
	assert(gtBAT.eQX == tAttr[2] and tAttr[3] == 2) --气血 & 百分比

	local nAddVal = math.floor(oTarUnit:MaxAttr(gtBAT.eQX)*tAttr[4](0)*0.01)
	oTarUnit:AddAttr(gtBAT.eQX, nAddVal, tParentAct, "重生技能增加:"..nSKID)

	return oTarUnit --作用目标
end
CPasSkillHelper.fnExecute[5215] = CPasSkillHelper.fnExecute[5115]

--触发条件,忽略条件检测
function CPasSkillHelper:CondCheck(tSkillConf, tTarPasSkillMap)
	local bSkillCond = false
	for _, tSkillCond in ipairs(tSkillConf.tTriggerSkillCond) do
		if tSkillCond[1]==0 or tTarPasSkillMap[tSkillCond[1]] then
			bSkillCond = true
			break
		end
	end
	if not bSkillCond then
		return
	end
	for _, tSkillCond in ipairs(tSkillConf.tIgnoreSkillCond) do
		if tSkillCond[1]>0 and tTarPasSkillMap[tSkillCond[1]] then
			return
		end
	end
	return true
end

--某个技能是否触发
function CPasSkillHelper:SingleSkillCheck(nSKID, nTriggerType, oSrcUnit, oTarUnit, tCtx)
	local tCtx = tCtx or table.DeepCopy(CPasSkillHelper.tPasSkillContext)
	local tTarPasSkillMap = oTarUnit:GetPasSkillMap()

	local tSkillConf = ctPetSkillConf[nSKID]
	for _, tTrigger in ipairs(tSkillConf.tTrigger) do
		local bTrigger = true
		if math.random(100) > tSkillConf.nRate then
			bTrigger = false
		else
			bTrigger = self:CondCheck(tSkillConf, tTarPasSkillMap)
		end
		if bTrigger then
			if self:TriggerSkill(oSrcUnit, oTarUnit, tSkillConf, nTriggerType, nil, tCtx, oSrcUnit) then
				self.m_oBattle:WriteLog("被动技能 特殊处理", tCtx)
			end
		end
	end
	return tCtx
end

function CPasSkillHelper:AddTriggerTips(nSKID, tParentAct, oOwnerUnit, tCtx)
	--怪物不触发喊招
	if oOwnerUnit:IsMonster() then
		return
	end

	local tSkillConf = ctPetSkillConf[nSKID]
	--法术群攻，物理群攻，只会喊招一次
	if tCtx and not tCtx.bSingleAtk and tParentAct then
		for _, tReact in ipairs(tParentAct.tReact) do
			if tReact.nAct == gtACT.eHZ and tReact.nSKID == nSKID then
				return
			end
		end
	end

	local tTTAct = {
		nAct = gtACT.eHZ,
		nSKID = nSKID,
		nSrcUnit = oOwnerUnit:GetUnitID(),
		nTime = GetActTime(gtACT.eHZ),
	}

	if tParentAct then
		self.m_oBattle:AddReactActTime(tParentAct, tTTAct, string.format("%s-喊招-%s", oOwnerUnit:GetObjName(), tSkillConf.sName))
	else
		self.m_oBattle:AddRoundAction(tTTAct, string.format("%s-喊招-%s", oOwnerUnit:GetObjName(), tSkillConf.sName))
	end
end

function CPasSkillHelper:TriggerSkill(oSrcUnit, oTarUnit, tSkillConf, nTriggerType, tParentAct, tCtx, oOwnerUnit)
	local nSKID = tSkillConf.nSKILId
	local nTarUnitLevel = oTarUnit:GetLevel()
	local oEffUnit = oTarUnit

	local fnExecute = CPasSkillHelper.fnExecute[nSKID] 
	if fnExecute then --要特殊处理的
		oEffUnit = fnExecute(self, nSKID, nTriggerType, oSrcUnit, oTarUnit, tParentAct, tCtx)
		if oEffUnit then
			self.m_oBattle:WriteLog(oOwnerUnit:GetUnitID(), oOwnerUnit:GetObjName(), "触发了被动技能", tSkillConf.sName)
			if tSkillConf.nBuffNumber > 0 then
				oEffUnit:AddBuff(nSKID, 0, tSkillConf.nBuffNumber, tSkillConf.nBuffRounds)
			end
		end

	else
		self.m_oBattle:WriteLog(oOwnerUnit:GetUnitID(), oOwnerUnit:GetObjName(), "触发被动技能", tSkillConf.sName)
		--属性加成
		for _, tAttr in ipairs(tSkillConf.tAttr) do
			if tAttr[1] == 0 or tAttr[1] == nTriggerType then
				local nAddVal = math.floor(tAttr[4](nTarUnitLevel))
				if tAttr[3] == 1 then --加值
					if tCtx then
						tCtx.tAttrAdd[tAttr[2]] = (tCtx.tAttrAdd[tAttr[2]] or 0) + nAddVal
					else
						oTarUnit:AddAttr(tAttr[2], nAddVal, tParentAct, "被动技能属性加成(值)")		
					end

				elseif tAttr[3] == 2 then --加百分比
					nAddVal = math.floor(oTarUnit:GetAttr(tAttr[2])*nAddVal*0.01)
					if tCtx then
						tCtx.tAttrAdd[tAttr[2]] = (tCtx.tAttrAdd[tAttr[2]] or 0) + nAddVal
					else
						oTarUnit:AddAttr(tAttr[2], nAddVal, tParentAct, "被动技能属性加成(百分比)")
					end

				end
			end
		end
		--BUFF
		if tSkillConf.nBuffNumber > 0 then
			oTarUnit:AddBuff(nSKID, 0, tSkillConf.nBuffNumber, tSkillConf.nBuffRounds)
		end
	end
	if oEffUnit then
		if tCtx then
			tCtx.tSkillMap[nSKID] = 1
		end
		if tSkillConf.bTriggerTips then
			--使用技能在入口处理
			if nTriggerType ~= CPasSkillHelper.tTriggerType.eExecSkill then
				self:AddTriggerTips(nSKID, tParentAct, oOwnerUnit, tCtx)
			end
		end
	end
	return oEffUnit
end

--普通物理攻击
function CPasSkillHelper:OnNormalPhyAtk(oSrcUnit, oTarUnit, tCtx)
	local tCtx = tCtx or table.DeepCopy(CPasSkillHelper.tPasSkillContext)
	local tSrcPasSkillMap = oSrcUnit:GetPasSkillMap()
	local tTarPasSkillMap = oTarUnit:GetPasSkillMap()

	for nSKID, tSkill in pairs(tSrcPasSkillMap) do
		local tSkillConf = ctPetSkillConf[nSKID]
		for _, tTrigger in ipairs(tSkillConf.tTrigger) do
			if tTrigger[1] == CPasSkillHelper.tTriggerType.eNorPhyAtk then
				local bTrigger = true
				if math.random(100) > tSkillConf.nRate then
					bTrigger = false
				else
					bTrigger = self:CondCheck(tSkillConf, tTarPasSkillMap)
				end
				if bTrigger then
					self.m_oBattle:WriteLog("被动技能 普通物理攻击事件", tCtx)
					self:TriggerSkill(oSrcUnit, oTarUnit, tSkillConf, CPasSkillHelper.tTriggerType.eNorPhyAtk, nil, tCtx, oSrcUnit)
				end
			end
		end
	end
	return tCtx
end

--物理攻击时(普通+物理系技能)
function CPasSkillHelper:OnPhyAtk(oSrcUnit, oTarUnit, tCtx, tParentAct)
	local tCtx = tCtx or table.DeepCopy(CPasSkillHelper.tPasSkillContext)
	local tSrcPasSkillMap = oSrcUnit:GetPasSkillMap()
	local tTarPasSkillMap = oTarUnit:GetPasSkillMap()

	for nSKID, tSkill in pairs(tSrcPasSkillMap) do
		local tSkillConf = ctPetSkillConf[nSKID]
		for _, tTrigger in ipairs(tSkillConf.tTrigger) do
			if tTrigger[1] == CPasSkillHelper.tTriggerType.ePhyAtk then
				local bTrigger = true
				if math.random(100) > tSkillConf.nRate then
					bTrigger = false
				else
					bTrigger = self:CondCheck(tSkillConf, tTarPasSkillMap)
				end
				if bTrigger then
					self.m_oBattle:WriteLog("被动技能 物理攻击事件", tCtx)
					self:TriggerSkill(oSrcUnit, oTarUnit, tSkillConf, CPasSkillHelper.tTriggerType.ePhyAtk, tParentAct, tCtx, oSrcUnit)
				end
			end
		end
	end
	return tCtx
end

--法术攻击时
function CPasSkillHelper:OnMagAtk(oSrcUnit, oTarUnit, tCtx, tParentAct)
	local tCtx = tCtx or table.DeepCopy(CPasSkillHelper.tPasSkillContext)
	local tSrcPasSkillMap = oSrcUnit:GetPasSkillMap()
	local tTarPasSkillMap = oTarUnit:GetPasSkillMap()

	for nSKID, tSkill in pairs(tSrcPasSkillMap) do
		local tSkillConf = ctPetSkillConf[nSKID]
		for _, tTrigger in ipairs(tSkillConf.tTrigger) do
			if tTrigger[1] == CPasSkillHelper.tTriggerType.eMagAtk then
				local bTrigger = true
				if math.random(100) > tSkillConf.nRate then
					bTrigger = false
				else
					bTrigger = self:CondCheck(tSkillConf, tTarPasSkillMap)
				end
				if bTrigger then
					self.m_oBattle:WriteLog("被动技能 法术攻击事件", tCtx)
					self:TriggerSkill(oSrcUnit, oTarUnit, tSkillConf, CPasSkillHelper.tTriggerType.eMagAtk, tParentAct, tCtx, oSrcUnit)
				end
			end
		end
	end
	return tCtx
end

--受到物理攻击时(普通+物理系技能)
function CPasSkillHelper:OnBePhyAtk(oSrcUnit, oTarUnit, tCtx)
	local tCtx = tCtx or table.DeepCopy(CPasSkillHelper.tPasSkillContext)
	local tSrcPasSkillMap = oSrcUnit:GetPasSkillMap()
	local tTarPasSkillMap = oTarUnit:GetPasSkillMap()

	for nSKID, tSkill in pairs(tTarPasSkillMap) do
		local tSkillConf = ctPetSkillConf[nSKID]
		for _, tTrigger in ipairs(tSkillConf.tTrigger) do
			if tTrigger[1] == CPasSkillHelper.tTriggerType.eBePhyAtk then
				local bTrigger = true
				if math.random(100) > tSkillConf.nRate then
					bTrigger = false
				else
					bTrigger = self:CondCheck(tSkillConf, tSrcPasSkillMap)
				end
				if bTrigger then
					self.m_oBattle:WriteLog("被动技能 被物理攻击事件", tCtx)
					self:TriggerSkill(oSrcUnit, oTarUnit, tSkillConf, CPasSkillHelper.tTriggerType.eBePhyAtk, nil, tCtx, oTarUnit)
				end
			end
		end
	end
	return tCtx
end

--进入战斗
function CPasSkillHelper:OnEnterBattle(oTarUnit, tCtx)
	local tPasSkillMap = oTarUnit:GetPasSkillMap()
	local tCtx = tCtx or table.DeepCopy(CPasSkillHelper.tPasSkillContext)

	for nSKID, tSkill in pairs(tPasSkillMap) do
		local tSkillConf = ctPetSkillConf[nSKID]
		for _, tTrigger in ipairs(tSkillConf.tTrigger) do
			if tTrigger[1] == CPasSkillHelper.tTriggerType.eEnter then
				if math.random(100) <= tSkillConf.nRate then
					self.m_oBattle:WriteLog("被动技能 进入战斗事件", tCtx)
					self:TriggerSkill(nil, oTarUnit, tSkillConf, CPasSkillHelper.tTriggerType.eEnter, nil, tCtx, oTarUnit)
				end
			end
		end
	end
	return tCtx
end

--攻击会死亡事件
function CPasSkillHelper:OnPreDeadEvent(oSrcUnit, oTarUnit)
	assert(oTarUnit:IsDead(), "状态错误")

	local tPasSkillMap = oTarUnit:GetPasSkillMap()
	for nSKID, tSkill in pairs(tPasSkillMap) do
		local tSkillConf = ctPetSkillConf[nSKID]
		for _, tTrigger in ipairs(tSkillConf.tTrigger) do
			if tTrigger[1] == CPasSkillHelper.tTriggerType.ePreDead  then
				if math.random(100) <= tSkillConf.nRate then
					self.m_oBattle:WriteLog("被动技能准备死亡事件")
					self:TriggerSkill(oSrcUnit, oTarUnit, tSkillConf, CPasSkillHelper.tTriggerType.ePreDead, nil, nil, oTarUnit)
				end
			end
		end
	end
end

--死亡事件
function CPasSkillHelper:OnDeadEvent(oSrcUnit, oTarUnit, tParentAct)
	assert(oTarUnit:IsDead(), "状态错误")

	local tPasSkillMap = oTarUnit:GetPasSkillMap()
	for nSKID, tSkill in pairs(tPasSkillMap) do
		local tSkillConf = ctPetSkillConf[nSKID]
		for _, tTrigger in ipairs(tSkillConf.tTrigger) do
			if tTrigger[1] == CPasSkillHelper.tTriggerType.eDead then 
				if math.random(100) <= tSkillConf.nRate then
					self.m_oBattle:WriteLog("被动技能死亡事件")
					self:TriggerSkill(oSrcUnit, oTarUnit, tSkillConf, CPasSkillHelper.tTriggerType.eDead, tParentAct, nil, oTarUnit)
				end
			end
		end
	end
end

--使用技能事件
function CPasSkillHelper:OnUseSkill(oTarUnit, bConsume)
	local tCtx = tCtx or table.DeepCopy(CPasSkillHelper.tPasSkillContext)
	local tPasSkillMap = oTarUnit:GetPasSkillMap()
	for nSKID, tSkill in pairs(tPasSkillMap) do
		local tSkillConf = ctPetSkillConf[nSKID]
		for _, tTrigger in ipairs(tSkillConf.tTrigger) do
			if tTrigger[1] == CPasSkillHelper.tTriggerType.eExecSkill then 
				if math.random(100) <= tSkillConf.nRate then
					self.m_oBattle:WriteLog("被动技能 使用技能事件", tCtx)
					self:TriggerSkill(nil, oTarUnit, tSkillConf, CPasSkillHelper.tTriggerType.eExecSkill, nil, tCtx, oTarUnit)
					if bConsume then
						self:AddTriggerTips(nSKID, nil, oTarUnit)
					end
				end
			end
		end
	end
	return tCtx
end

--宠物受到治疗时
function CPasSkillHelper:OnBeCure(oTarUnit)
	local tCtx = tCtx or table.DeepCopy(CPasSkillHelper.tPasSkillContext)
	if not oTarUnit:IsPet() then
		return tCtx
	end

	local tPasSkillMap = oTarUnit:GetPasSkillMap()
	for nSKID, tSkill in pairs(tPasSkillMap) do
		local tSkillConf = ctPetSkillConf[nSKID]
		for _, tTrigger in ipairs(tSkillConf.tTrigger) do
			if tTrigger[1] == CPasSkillHelper.tTriggerType.eBeCure then 
				if math.random(100) <= tSkillConf.nRate then
					self.m_oBattle:WriteLog("被动技能 宠物受到治疗事件", tCtx)
					self:TriggerSkill(nil, oTarUnit, tSkillConf, CPasSkillHelper.tTriggerType.eBeCure, nil, tCtx, oTarUnit)
				end
			end
		end
	end
	return tCtx
end
