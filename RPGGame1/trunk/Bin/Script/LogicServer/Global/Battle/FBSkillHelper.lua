--法宝技能
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--技能属性加成相关字段
CFBSkillHelper.tSkillAttrAdd =
{
	nGroupAtkHurtRatio = 100,	--群攻伤害比例
	nSkillHurtRatioAdd = 0, 	--技能伤害附加(百分比100倍)
	nSkillHurtValAdd = 0, 		--技能伤害附加(值)
	nSkillAtkRatioAdd = 0, 		--技能攻击附加(百分比100倍)
	nSkillAtkValAdd = 0, 		--技能攻击附加(值)
	nSkillHitRate = 0, 			--技能命中
	nEfficiency = 1, 			--伤害比例效率
	nSkillStaticHurt = 0, 		--技能固定伤害
	nSkillStaticDef = 0, 		--技能固定防御
	bIgnoreGroupAtkHurt = false,--是否忽略群伤规则
	nSkillHurtRatioAdd1 = 0, 	--技能伤害附加1(百分比100倍)
	tSkillMap = {},
}

--技能额外信息
CFBSkillHelper.tSkillExtCtx = 
{
	oTarget = nil,  		--指定目标
	tParentAct = nil, 		--父动作
	nSkillHurtRatioAdd = 0, --伤害加成
	sFrom = "", 			--源
	sGJTips = "", 			--喊招
}

--取群攻伤害比例
CFBSkillHelper.tGroupAtkHurtRatio =
{
	[1] = 100,
	[2] = 90,
	[3] = 75,
	[4] = 65,
	[5] = 55,
	[6] = 50,
	[7] = 45,
	[8] = 40,
	[9] = 40,
	[10] = 40,
	[11] = 40,
	[12] = 40,
}

--构造函数
function CFBSkillHelper:Ctor()
	self.m_tSkillAttrMap = {}
end

--取技能属性加成
function CFBSkillHelper:GetSkillAttr(nSKID, nType)
	self.m_tSkillAttrMap[nSKID] = self.m_tSkillAttrMap[nSKID] or {}
	return (self.m_tSkillAttrMap[nSKID][nType] or 0)
end

--设置技能属性加成
function CFBSkillHelper:AddSkillAttr(nSKID, nType, nVal)
	self.m_tSkillAttrMap[nSKID] = self.m_tSkillAttrMap[nSKID] or {}
	self.m_tSkillAttrMap[nSKID][nType] = (self.m_tSkillAttrMap[nSKID][nType] or 0) + nVal
end

--清空技能属性加成
function CFBSkillHelper:ClearSkillAttr(nSKID)
	self.m_tSkillAttrMap[nSKID] = {}
end

--群攻伤害比例
function CFBSkillHelper:GetGroupAtkHurtRatio(nTarNum)
	nTarNum = math.max(1, math.min(#CFBSkillHelper.tGroupAtkHurtRatio, nTarNum))
	return CFBSkillHelper.tGroupAtkHurtRatio[nTarNum]
end

--是否可以执行
function CFBSkillHelper:CanLaunch(oUnit, nSKID)
	local tConf = ctFaBaoSkillConf[nSKID]
	local nCostSP = tConf.nCostSP

	local sAttrName = gtBATName[gtBAT.eNQ]
	local sConsumeTips = string.format("消耗%d点%s", nCostSP, sAttrName)

	if oUnit:GetAttr(gtBAT.eNQ) < nCostSP then
		return false, string.format("%s值不足", sAttrName), sConsumeTips
	end
	return true, "", sConsumeTips
end

--执行技能消耗
function CFBSkillHelper:CostLaunch(oUnit, nSKID)
	local tConf = ctFaBaoSkillConf[nSKID]
	local nCostSP = tConf.nCostSP
	if oUnit:GetAttr(gtBAT.eNQ) < nCostSP then
		return false, "怒气值不足"
	end
	oUnit:AddAttr(gtBAT.eNQ, -nCostSP, nil, string.format("法宝技能:%d消耗", nSKID))
	return true
end

--生成技能行动数据
--nAtkTimes 多段攻击
function CFBSkillHelper:MakeSkillAct(oUnit, nSKID, nAtkTimes, tSkillExtCtx)
	nAtkTimes = nAtkTimes or 1
	local tConf = oUnit:GetSkillConf(nSKID)
	local tSkill = oUnit:GetActSkill(nSKID)

	local tSkillAct = {
		nAct = gtACT.eFS,
		nSKID = nSKID,
		sSKName = tSkill.sName,
		nSKType = tConf.nAtkType,
		nSrcUnit = oUnit:GetUnitID(),
		tTarUnit = {},
		nCurrHP = oUnit:GetAttr(gtBAT.eQX),
		nCurrSP = oUnit:GetAttr(gtBAT.eNQ),
		nCurrMP = oUnit:GetAttr(gtBAT.eMF),
		nTime = GetActTime(gtACT.eFS, nSKID)+nAtkTimes*0.5,
		sGJTips = tSkillExtCtx.sGJTips,
		tReact = {},
	}

	return tSkillAct
end

--计算目标数量
function CFBSkillHelper:CalcTargetNum(oUnit, nSKID)
	local tConf = oUnit:GetSkillConf(nSKID)
	local tSkill = oUnit:GetActSkill(nSKID)
	return tConf.nTargets
end

--发动法术
CFBSkillHelper.fnLaunch = {}
CFBSkillHelper.fnLaunch[32305] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = oUnit:GetSkillConf(nSKID)
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)
	local tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("法宝技能%d", nSKID))
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("法宝技能%d 选择目标失败", nSKID))
	end

	--属性附加
	local tAttrAdd = table.DeepCopy(CFBSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("法宝技能%d", nSKID))

	local oTarUnit =  tTarList[1]
	table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
	local nOldHP = oTarUnit:GetAttr(gtBAT.eQX)
	oUnit:PhyAtk(oTarUnit, tSkillAct, tAttrAdd)
	local nCurHP = oTarUnit:GetAttr(gtBAT.eQX)
	local nLostHP = math.abs(nOldHP-nCurHP)
	local nLostMP = math.floor(tConf.cEff.subMP(nLostHP))
	oTarUnit:AddAttr(gtBAT.eMF, -nLostMP, tSkillAct, string.format("法宝技能%d", nSKID))
end

CFBSkillHelper.fnLaunch[32502] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = oUnit:GetSkillConf(nSKID)
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)
	local tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("法宝技能%d", nSKID))
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("法宝技能%d 选择目标失败", nSKID))
	end

	local oInstUnit = table.remove(tTarList, 1) --指令指定的单位
	table.sort(tTarList, function(u1, u2) return u1:GetObjType()<u2:GetObjType() end)
	table.insert(tTarList, 1, oInstUnit)

	local function _fnWithoutPassSkill(oTarUnit)
		if not (oTarUnit:GetPasSkill(5107) or oTarUnit:GetPasSkill(5207)) then
			return true 
		end
	end

	local nCount = 0
	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	for _, oTarUnit in ipairs(tTarList) do
		if _fnWithoutPassSkill(oTarUnit) then
			oTarUnit:AddAttr(gtBAT.eQX, oTarUnit:MaxAttr(gtBAT.eQX), tSkillAct, string.format("法宝技能:%d",nSKID))
			nCount = nCount + 1
			if nCount >= 5 then break end
		end
	end
	if nCount > 0 then
		local nCurMP = oUnit:GetAttr(gtBAT.eMF)
		local nCurHP = oUnit:GetAttr(gtBAT.eHP)
		oUnit:AddAttr(gtBAT.eMF, -nCurMP, nil, string.format("法宝技能%d", nSKID))
		oUnit:AddAttr(gtBAT.eQX, -nCurHP+1, tSkillAct, string.format("法宝技能%d", nSKID))
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("法宝技能%d", nSKID))
	end
end

CFBSkillHelper.fnLaunch[32510] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = oUnit:GetSkillConf(nSKID)
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)
	local tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("法宝技能%d", nSKID))
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("法宝技能%d 选择目标失败", nSKID))
	end

	--属性附加
	local tAttrAdd = table.DeepCopy(CFBSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHurtRatioAdd = -20

	local nAtkTimes = 2
	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, nAtkTimes, tSkillExtCtx)
	oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("法宝技能%d", nSKID))

	local oTarUnit =  tTarList[1]
	for k = 1, nAtkTimes do
		if oTarUnit:IsDeadOrLeave() then
			break
		end
		oUnit:PhyAtk(oTarUnit, tSkillAct, tAttrAdd)
	end
end

CFBSkillHelper.fnLaunch[32511] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = oUnit:GetSkillConf(nSKID)
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)
	local tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("法宝技能%d", nSKID))
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("法宝技能%d 选择目标失败", nSKID))
	end

	--属性附加
	local tAttrAdd = table.DeepCopy(CFBSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHurtRatioAdd = -20
	tAttrAdd.nSkillStaticHurt = 0

	local nAtkTimes = 2
	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, nAtkTimes, tSkillExtCtx)
	oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("法宝技能%d", nSKID))

	local nSrcLv = oUnit:GetLevel()
	local nSrcLL = oUnit:GetAttr(gtBAT.eLL)
	local nWeaponAtk = oUnit:GetWeaponAtk()

	local oTarUnit =  tTarList[1]
	local nTarLL = oTarUnit:GetAttr(gtBAT.eLL)

	tAttrAdd.nSkillStaticHurt = (80+nSrcLv*1.8+nSrcLv*nSrcLv/100+nSrcLv-nTarLL+nWeaponAtk)*0.8
	
	for k = 1, nAtkTimes do
		if oTarUnit:IsDeadOrLeave() then
			break
		end
		oUnit:MagAtk(nSKID, oTarUnit, tSkillAct, tAttrAdd)
	end
end

--回合开始前结算
function CFBSkillHelper:BeforeRound(oUnit, nSKID)
end

--执行后事件
function CFBSkillHelper:AfterLaunch(oUnit, nSKID)
end

--发动技能
function CFBSkillHelper:Launch(oUnit, nSKID, tSkillExtCtx)
	local fnLaunch = self.fnLaunch[nSKID]
	tSkillExtCtx = tSkillExtCtx or table.DeepCopy(CFBSkillHelper.tSkillExtCtx)
	if fnLaunch then
		return fnLaunch(self, nSKID, oUnit, tSkillExtCtx)
	end
	local tConf = oUnit:GetSkillConf(nSKID)
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("法宝技能%d", nSKID))
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("法宝技能%d 选择目标失败", nSKID))
	end

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("法宝技能%d", nSKID))

	local cEff = tConf.cEff
	for _, oTmpUnit in ipairs(tTarList) do
		local bWithoutPasSkill = true
		if cEff.withoutPasSkillAnd then
			for _, nPasSkill in ipairs(cEff.withoutPasSkillAnd) do
				if oTmpUnit:GetPasSkill(nPasSkill) then
					bWithoutPasSkill = false
					break
				end
			end
		end
		if bWithoutPasSkill then
			table.insert(tSkillAct.tTarUnit, oTmpUnit:GetUnitID())
			if cEff.addHP then
				local nAddHP = math.floor(cEff.addHP(oTmpUnit:MaxAttr(gtBAT.eQX), oTmpUnit:GetLevel()))
				oTmpUnit:AddAttr(gtBAT.eQX, nAddHP, tSkillAct, string.format("法宝技能:%d", nSKID))
			elseif cEff.subHP then
				local nSubHP = math.floor(cEff.subHP(oTmpUnit:GetLevel()))
				oTmpUnit:AddAttr(gtBAT.eQX, -nSubHP, tSkillAct, string.format("法宝技能:%d", nSKID), oUnit)
			elseif cEff.addMP then
				local nAddMP = math.floor(cEff.addMP(oTmpUnit:GetLevel(), oTmpUnit:MaxAttr(gtBAT.eMF)))
				oTmpUnit:AddAttr(gtBAT.eMF, nAddMP, tSkillAct, string.format("法宝技能:%d", nSKID))
			end
			if cEff.clearBuffType then
				oTmpUnit:ClearBuffType(cEff.clearBuffType, tSkillAct)
			end
			if cEff.buffID then
				oTmpUnit:AddBuff(nSKID, tSkill.nLevel, cEff.buffID, cEff.rounds, tSkillAct)
			end
		end
	end
end

--执行技能
function CFBSkillHelper:ExecSkill(oUnit, nSKID)
	oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), "执行法宝技能", nSKID)
	local tSkill = oUnit:GetActSkill(nSKID)

	local bRes, sErr = self:CanLaunch(oUnit, nSKID)
	if not bRes then
		local tInst = oUnit:GetInst()
		if tInst.nTarUnit == 0 
			or (tInst.nTarUnit > 0 and not oUnit.m_oSelectHelper:CheckSkillTarget(oUnit, 1, tInst.nTarUnit))
			or (tInst.nTarUnit > 0 and oUnit:IsSameTeam(tInst.nTarUnit)) then
				local oTarUnit = oUnit.m_oSelectHelper:SkillTarget(oUnit, 1, 1, "法宝技能发动失败普攻代替")[1]
				tInst.nTarUnit = oTarUnit and oTarUnit:GetUnitID() or 0
		end
		if tInst.nTarUnit > 0 then
			if oUnit:ReplaceInst(CUnit.tINST.eGJ, tInst.nTarUnit, string.format("%s发动%s失败", sErr, tSkill.sName)) then
				oUnit:ExecInst()
			end
		end
	else
		self:CostLaunch(oUnit, nSKID)
		self:Launch(oUnit, nSKID)
	end
	self:AfterLaunch(oUnit, nSKID)
	self:ClearSkillAttr(nSKID)
end