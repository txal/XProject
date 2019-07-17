--技能
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local gtBTT, gtBAT, gtBTRes, gtRatioAttr, gtACT, GetActTime, gtAddAttrModType, gtBATName
= gtBTT, gtBAT, gtBTRes, gtRatioAttr, gtACT, GetActTime, gtAddAttrModType, gtBATName

--技能属性加成相关字段
CSkillHelper.tSkillAttrAdd =
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
	tSkillMap = {}, 			--释放的技能记录
}

--技能额外信息
CSkillHelper.tSkillExtCtx = 
{
	sFrom = "", 			--来源
	sGJTips = "", 			--喊招
	oTarget = nil,  		--指定目标
	tParentAct = nil, 		--父动作
	nSkillHurtRatioAdd = 0, --伤害加成
}

--取群攻伤害比例
CSkillHelper.tGroupAtkHurtRatio =
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
function CSkillHelper:Ctor()
	self.m_tSkillAttrMap = {} 	--技能临时属性
	self.m_tSkillDoubleHit = nil --法术连击标记
	self.m_tSkillForbidMap = {} --技能无法使用标识(痴情咒)
end

--取技能属性加成
function CSkillHelper:GetSkillAttr(nSKID, nType)
	self.m_tSkillAttrMap[nSKID] = self.m_tSkillAttrMap[nSKID] or {}
	return (self.m_tSkillAttrMap[nSKID][nType] or 0)
end
--设置技能属性加成
function CSkillHelper:AddSkillAttr(nSKID, nType, nVal)
	self.m_tSkillAttrMap[nSKID] = self.m_tSkillAttrMap[nSKID] or {}
	self.m_tSkillAttrMap[nSKID][nType] = (self.m_tSkillAttrMap[nSKID][nType] or 0) + nVal
end
--清空技能属性加成
function CSkillHelper:ClearSkillAttr(nSKID)
	self.m_tSkillAttrMap[nSKID] = {}
end

--设置法术连击
function CSkillHelper:SetSkillDoubleHit(tSkillExtCtx)
	self.m_tSkillDoubleHit = tSkillExtCtx
end
--清空法术连击
function CSkillHelper:ClearSkillDoubleHit()
	self.m_tSkillDoubleHit = nil 
end

--技能是否无法使用
function CSkillHelper:IsSkillForbid(nSKID, nRounds)
	local nExpireRounds = self.m_tSkillForbidMap[nSKID] or 0
	if nRounds <= nExpireRounds then
		return true
	end
	return false
end
--设置技能无法使用
function CSkillHelper:SetSkillForbid(nSKID, nExpireRounds)
	self.m_tSkillForbidMap[nSKID] = nExpireRounds
end

--是否可以发动
--@返回 true/false, reason, consume
CSkillHelper.fnCanLaunch = {}
----------------------鬼王-----------------------
--鬼乱斩
CSkillHelper.fnCanLaunch[1111] = function(self, nSKID, oUnit, bSub)
	local tConf = ctSkillConf[nSKID]
	for _, tCond in ipairs(tConf.tCond) do
		if tCond[1] > 0 then
			local nCurVal = oUnit:GetAttr(tCond[1])
			local nMaxVal = oUnit:MaxAttr(tCond[1])
			if not tCond[2](nCurVal, nMaxVal) then
				return false, string.format("%s值不足", gtBATName[tCond[1]]), tConf.sCons
			end
		end
	end

	if bSub then
		local tConsumeList = tConf.tConsume
		for _, tConsume in ipairs(tConsumeList) do
			if tConsume[1] > 0 then
				local nCurVal = oUnit:GetAttr(tConsume[1])
				local nMaxVal = oUnit:MaxAttr(tConsume[1])
				local nConsume = math.floor(tConsume[2](nCurVal, nMaxVal))
				oUnit:AddAttr(tConsume[1], -nConsume, nil, string.format("技能%d消耗", nSKID))
			end
		end
	end
	return true, "", tConf.sCons
end
CSkillHelper.fnCanLaunch[1112] = CSkillHelper.fnCanLaunch[1111]
CSkillHelper.fnCanLaunch[1113] = CSkillHelper.fnCanLaunch[1111]
CSkillHelper.fnCanLaunch[1114] = CSkillHelper.fnCanLaunch[1111]
CSkillHelper.fnCanLaunch[1115] = CSkillHelper.fnCanLaunch[1111]
CSkillHelper.fnCanLaunch[1116] = CSkillHelper.fnCanLaunch[1111]
CSkillHelper.fnCanLaunch[1118] = CSkillHelper.fnCanLaunch[1111]

--------------------天音------------------------
--无量净世咒
CSkillHelper.fnCanLaunch[1211] = function(self, nSKID, oUnit, bSub)
	local tConf = ctSkillConf[nSKID]
	local tCondList = tConf.tCond
	local nLevel = oUnit:GetLevel()

	local tPasSkillContext = oUnit.m_oPasSkillHelper:OnUseSkill(oUnit, bSub)
	local nAddRatio = (100 + (tPasSkillContext.tAttrAdd[gtBAT.eMF] or 0)) * 0.01

	local sConsumeTips = ""
	for k, tCond in ipairs(tCondList) do
		if tCond[1] > 0 then
			local tConsume = tConf.tConsume[k]
			local nConsume = math.floor(tConsume[2](nLevel, nAddRatio))
			local sAttrName = gtBATName[tCond[1]]
			sConsumeTips = string.format("消耗%d点%s", nConsume, sAttrName)

			local nCurVal = oUnit:GetAttr(tCond[1])
			if not tCond[2](nCurVal, nLevel, nAddRatio) then
				return false, string.format("%s值不足", sAttrName), sConsumeTips
			end
		end
	end

	if bSub then
		local tConsumeList = tConf.tConsume
		for _, tConsume in ipairs(tConsumeList) do
			if tConsume[1] > 0 then
				local nConsume = math.floor(tConsume[2](nLevel, nAddRatio))
				oUnit:AddAttr(tConsume[1], -nConsume, nil, string.format("技能%d消耗", nSKID))
			end
		end
	end
	return true, "", sConsumeTips
end
CSkillHelper.fnCanLaunch[1212] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1213] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1214] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1215] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1216] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1218] = CSkillHelper.fnCanLaunch[1211]

--------------------合欢------------------------
CSkillHelper.fnCanLaunch[1311] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1312] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1313] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1314] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1315] = CSkillHelper.fnCanLaunch[1211]
--痴情咒
--@bDisplay 取技能列表为true
CSkillHelper.fnCanLaunch[1316] = function(self, nSKID, oUnit, bSub, bDisplay)
	if not bDisplay then
		local tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, 1, string.format("技能%d", nSKID))
		if #tTarList <= 0 then
			return false, "目标无效", "剩1气血"
		end
	end
	if self:IsSkillForbid(nSKID, oUnit.m_oBattle:GetRound()) then
		return false, "技能冷却中", "剩1气血"
	end
	if oUnit:IsDeadOrLeave() then	
		return false, "单位已死亡", "剩1气血"
	end
	if bSub then
		local tConf = ctSkillConf[nSKID]
		local tConsume = tConf.tConsume[1]
		if tConsume[1] > 0 then
			local nCurVal = oUnit:GetAttr(tConsume[1])
			local nConsume = math.floor(tConsume[2](nCurVal))
			oUnit:AddAttr(tConsume[1], -nConsume, nil, string.format("技能%d消耗", nSKID))
		end
	end
	return true, "", "剩1气血"
end
--狂风点柳
CSkillHelper.fnCanLaunch[1318] = CSkillHelper.fnCanLaunch[1211]

--------------------青云------------------------
CSkillHelper.fnCanLaunch[1411] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1412] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1413] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1414] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1415] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1416] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1418] = CSkillHelper.fnCanLaunch[1211]

--------------------圣巫------------------------
CSkillHelper.fnCanLaunch[1511] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1512] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1513] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1514] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1515] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1516] = CSkillHelper.fnCanLaunch[1211]
CSkillHelper.fnCanLaunch[1518] = CSkillHelper.fnCanLaunch[1211]


-------------------------------------------------------宠物主动技能
--惊雷
CSkillHelper.fnCanLaunch[5301] = function(self, nSKID, oUnit, bSub)
	local tConf = ctPetSkillConf[nSKID]
	local nCurMP = oUnit:GetAttr(gtBAT.eMF)
	local nNeedMP = tConf.eConsume(oUnit:GetLevel())
	local tPasSkillContext = oUnit.m_oPasSkillHelper:OnUseSkill(oUnit, bSub)
	nNeedMP = math.floor(nNeedMP * (1+(tPasSkillContext.tAttrAdd[gtBAT.eMF] or 0)*0.01))

	local sConsumeTips = ""
	local sAttrName = gtBATName[gtBAT.eMF]
	if not bSub then
		sConsumeTips = string.format("消耗%d点%s", nNeedMP, sAttrName)
	end

	if nCurMP < nNeedMP then
		return false, string.format("%s值不足", sAttrName), sConsumeTips
	end

	if bSub then
		oUnit:AddAttr(gtBAT.eMF, -nNeedMP, nil, string.format("技能%d消耗", nSKID))
	end
	return true, "", sConsumeTips
end
CSkillHelper.fnCanLaunch[5302] = CSkillHelper.fnCanLaunch[5301] 
CSkillHelper.fnCanLaunch[5303] = CSkillHelper.fnCanLaunch[5301] 
CSkillHelper.fnCanLaunch[5304] = CSkillHelper.fnCanLaunch[5301] 
CSkillHelper.fnCanLaunch[5305] = CSkillHelper.fnCanLaunch[5301] 
CSkillHelper.fnCanLaunch[5306] = CSkillHelper.fnCanLaunch[5301] 
CSkillHelper.fnCanLaunch[5307] = CSkillHelper.fnCanLaunch[5301] 
CSkillHelper.fnCanLaunch[5308] = CSkillHelper.fnCanLaunch[5301] 
CSkillHelper.fnCanLaunch[5309] = CSkillHelper.fnCanLaunch[5301] 
--召唤子怪
CSkillHelper.fnCanLaunch[5310] = function(self, nSKID, oUnit, bSub)
	return true, "", ""
end

--群攻伤害比例
function CSkillHelper:GetGroupAtkHurtRatio(nTarNum)
	nTarNum = math.max(1, math.min(#CSkillHelper.tGroupAtkHurtRatio, nTarNum))
	return CSkillHelper.tGroupAtkHurtRatio[nTarNum]
end

------回合开始前结算函数
CSkillHelper.fnBeforeRound = {}
----------------------鬼王-----------------------
--先发制人 临时提高自身速度skill*0.5+50，速率150%，攻击后速度恢复正常，攻击敌方单个目标，伤害结果减少40%
CSkillHelper.fnBeforeRound[1114] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tSkill = oUnit:GetActSkill(nSKID)
	local nSD = oUnit:GetAttr(gtBAT.eSD)
	local nSDAdd = math.floor((nSD+tSkill.nLevel*0.5+50)*0.5)
	oUnit:AddAttr(gtBAT.eSD, nSDAdd, nil, "技能预处理1114")
	self:AddSkillAttr(nSKID, gtBAT.eSD, nSDAdd)
end
--魔入膏肓 临时降低自身一定速度，速率50%，有(skill-aimlv)*2%+50%几率，最低20%，最高70%令对手(skill-aimlv)/10+skill/40+3回合内无法被复活。如果被封印目标已使用过法术，则封印持续回合+1
CSkillHelper.fnBeforeRound[1516] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tSkill = oUnit:GetActSkill(nSKID)
	local nSD = oUnit:GetAttr(gtBAT.eSD)
	local nSDAdd = math.floor(nSD*0.5)
	oUnit:AddAttr(gtBAT.eSD, -nSDAdd, nil, "技能预处理1516")
	self:AddSkillAttr(nSKID, gtBAT.eSD, -nSDAdd)
end

------执行技能后处理函数
CSkillHelper.fnAfterLaunch = {}
----------------------鬼王-----------------------
--先发制人 临时提高自身速度skill*0.5+50，速率150%，攻击后速度恢复正常，攻击敌方单个目标，伤害结果减少40%
CSkillHelper.fnAfterLaunch[1114] = function(self, nSKID, oUnit, tSkillExtCtx)
	local nSDAdd = self:GetSkillAttr(nSKID, gtBAT.eSD)
	oUnit:AddAttr(gtBAT.eSD, -nSDAdd, nil, "执行技能后1114")
end
--魔入膏盲 临时降低自身一定速度，速率50%，有(skill-aimlv)*2%+50%几率，最低20%，最高70%令对手(skill-aimlv)/10+skill/40+3回合内无法被复活。如果被封印目标已使用过法术，则封印持续回合+1
CSkillHelper.fnAfterLaunch[1516] = function(self, nSKID, oUnit, tSkillExtCtx)
	local nSDAdd = self:GetSkillAttr(nSKID, gtBAT.eSD)
	oUnit:AddAttr(gtBAT.eSD, -nSDAdd, nil, "执行技能后1516")
end	

--生成技能行动数据
--nAtkTimes 多段攻击
function CSkillHelper:MakeSkillAct(oUnit, nSKID, nAtkTimes, tSkillExtCtx)
	nAtkTimes = nAtkTimes or 1
	local tConf = oUnit:GetSkillConf(nSKID)
	local tSkillAct = {
		nAct = gtACT.eFS,
		nSKID = nSKID,
		sSKName = tConf.sName,
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
function CSkillHelper:CalcTargetNum(oUnit, nSKID)
	local tConf = oUnit:GetSkillConf(nSKID)
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = 1
	for _, tTarget in ipairs(tConf.tTargets) do
		if tSkill.nLevel >= tTarget[1] then
			nNum = tTarget[2]
			break
		end
	end
	return nNum
end

--发动法术
CSkillHelper.fnLaunch = {}
----------------------鬼王-----------------------
--鬼乱斩
CSkillHelper.fnLaunch[1111] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHurtRatioAdd = -5 		
	tAttrAdd.nSkillHitRate = tConf.nHitRate

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		oUnit:PhyAtk(oTarUnit, tSkillAct, tAttrAdd)
	end

end
--狂鬼击
CSkillHelper.fnLaunch[1112] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHitRate = tConf.nHitRate

	local nAtkTimes = 3
	local oTarUnit = tTarList[1]
	local tAtkRatio = {-10, 0, 10}
	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, nAtkTimes, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	
	table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
	for k = 1, nAtkTimes do
		tAttrAdd.nSkillAtkRatioAdd = tAtkRatio[k] 
		oUnit:PhyAtk(oTarUnit, tSkillAct, tAttrAdd)
		if oTarUnit:IsDeadOrLeave() then break end
	end

	--BUFF
	oUnit:AddBuff(nSKID, tSkill.nLevel, 101, 2, tSkillAct)

end
--后发先至
CSkillHelper.fnLaunch[1113] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)
	local tInst = oUnit:GetInst()

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end

	if (tInst.nBuffID or 0) > 0 then --第二回合自动攻击
		local oTarUnit = oUnit.m_oBattle:GetUnit(tInst.nTarUnit)
		if not oTarUnit or oTarUnit:IsDeadOrLeave() then
			local nNum = self:CalcTargetNum(oUnit, nSKID)
			oTarUnit = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID,  1, string.format("技能%d", nSKID))[1]
			if not oTarUnit then return end
		end
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())

		--属性附加
		local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
		tAttrAdd.tSkillMap[nSKID] = 1
		tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
		tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(1)
		tAttrAdd.nSkillHitRate = tConf.nHitRate
		oUnit:PhyAtk(oTarUnit, tSkillAct, tAttrAdd)

	else --第一回合附加BUFF
		oUnit:AddBuff(nSKID, tSkill.nLevel, 102, 2, tSkillAct)

	end


end
--先发制人
CSkillHelper.fnLaunch[1114] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	local oTarUnit = tTarList[1]
	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHurtRatioAdd = -40
	tAttrAdd.nSkillHitRate = tConf.nHitRate

	oUnit:PhyAtk(oTarUnit, tSkillAct, tAttrAdd)


	--恢复速度
	oUnit:AddAttr(gtBAT.eSD, -self:GetSkillAttr(nSKID, gtBAT.eSD), nil, "技能后恢复"..nSKID)
end
--幽冥盾击
CSkillHelper.fnLaunch[1115] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)
	local nNum = self:CalcTargetNum(oUnit, nSKID)

	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	local oTarUnit = tTarList[1]
	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHitRate = tConf.nHitRate

	oUnit:PhyAtk(oTarUnit, tSkillAct, tAttrAdd)

	--BUFF	
	oUnit:AddBuff(nSKID, tSkill.nLevel, 103, 1, tSkillAct)

end
--鬼影重重
CSkillHelper.fnLaunch[1116] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHurtRatioAdd = 50
	tAttrAdd.nSkillAtkRatioAdd = 10
	tAttrAdd.nSkillHitRate = tConf.nHitRate

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		oUnit:PhyAtk(oTarUnit, tSkillAct, tAttrAdd)
	end

	--BUFF
	oUnit:AddBuff(nSKID, tSkill.nLevel, 104, 2, tSkillAct)

end
--虎啸裂天碎
CSkillHelper.fnLaunch[1118] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	local oTarUnit = tTarList[1]
	local nXRatio= oTarUnit:GetAttr(gtBAT.eQX)/oTarUnit:MaxAttr(gtBAT.eQX)

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHurtRatioAdd = (nXRatio*100-100)
	tAttrAdd.nSkillHitRate = tConf.nHitRate
	tAttrAdd.nEfficiency = 4 --策划特意说了

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
	oUnit:PhyAtk(oTarUnit, tSkillAct, tAttrAdd)

	--BUFF
	oUnit:AddBuff(nSKID, tSkill.nLevel, 104, 2, tSkillAct)

end

--------------------天音------------------------
--无量净世咒 使用水系法术固定伤害skill*1.5+30敌方多个目标，对普通怪物伤害增加200%；小乘佛法技能5级以上作用2个目标，40级以上作用3个目标，80级以上作用4个目标
CSkillHelper.fnLaunch[1211] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHitRate = tConf.nHitRate
	local nBaseStaticHurt = math.floor(tSkill.nLevel*1.5+30)

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		if oTarUnit:IsMonster() then
			tAttrAdd.nSkillStaticHurt = nBaseStaticHurt*2
		else
			tAttrAdd.nSkillStaticHurt = nBaseStaticHurt
		end
		oUnit:MagAtk(nSKID, oTarUnit, tSkillAct, tAttrAdd)
	end


end
--醐醍灌顶 使用后可以恢复自己或队友的气血skill*6.5+50，使用群伤递减规则，除选择目标外优先选择气血较少的目标，歧黄之术技能15级以上作用2个目标，40级以上作用3个目标，65级以上作用4个目标，90级以上作用5个目标
CSkillHelper.fnLaunch[1212] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	--恢复气血
	local nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	local nQXAdd = math.floor((tSkill.nLevel*6.5+50)*nGroupAtkHurtRatio*0.01)
	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		oTarUnit:AddAttr(gtBAT.eQX, nQXAdd, tSkillAct, string.format("技能%d", nSKID))
	end

end
--佛光普 可恢复自己skill*7+30+skill*skill/200或队员skill*6+20+skill*skill/200的气血 
CSkillHelper.fnLaunch[1213] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	local oTarUnit = tTarList[1]
	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end

	local nQXAdd = 0
	if oTarUnit == oUnit then --自己
		nQXAdd = math.floor(tSkill.nLevel*7+30+tSkill.nLevel*tSkill.nLevel/200)
	else --队友
		nQXAdd = math.floor(tSkill.nLevel*6+20+tSkill.nLevel*tSkill.nLevel/200)
	end
	table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
	oTarUnit:AddAttr(gtBAT.eQX, nQXAdd, tSkillAct, string.format("技能%d", nSKID))

end
--往生咒 复活已经死亡的队友，并恢复一定气血skill*4+(skill/12)^2
CSkillHelper.fnLaunch[1214] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	local oTarUnit = tTarList[1]
	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end

	table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
	if not oTarUnit:GetRoundFlag(CUnit.tRoundFlag.eLCKRL) then --被禁止复活
		local nQXAdd = math.max(1, math.floor(tSkill.nLevel*4+(tSkill.nLevel/12)^2)) --临时加个最小恢复血量值1
		oTarUnit:AddAttr(gtBAT.eQX, nQXAdd, tSkillAct, string.format("技能%d", nSKID))
	else
		oTarUnit.m_oBattle:WriteLog(oTarUnit:GetUnitID(), oTarUnit:GetObjName(), "技能1214复活失败(被禁止复活)")
	end


end
--无相咒 一定(skill-aimlv)/10+skill/80+3回合内增加自己或队友的攻击力skill*1和恢复少量气血skill*2+30；佛光普照技能50级以上作用3个目标，90级以上作用4个目标
CSkillHelper.fnLaunch[1215] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end

	local nHPAdd = math.floor(tSkill.nLevel*2+30)
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		oTarUnit:AddAttr(gtBAT.eQX, nHPAdd, tSkillAct, sFrom)

		local nRounds = math.floor((tSkill.nLevel-oTarUnit:GetLevel())*0.1+tSkill.nLevel/80+3)
		if nRounds > 0 then
			oTarUnit:AddBuff(nSKID, tSkill.nLevel, 105, nRounds, tSkillAct)
		else
			oTarUnit.m_oBattle:WriteLog(oTarUnit:GetUnitID(), oTarUnit:GetObjName(), "105BUFF回合计算<=0:", tSkill.nLevel, oTarUnit:GetLevel())
		end
	end


end
--水晶之境 一定(skill-aimlv)/10+skill/80+3回合内增加自己或队友的防御力skill*1和恢复少量气血skill*2+30；佛光普照技能60级以上作用3目标，90级以上作用4个目标
CSkillHelper.fnLaunch[1216] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	local nHPAdd = math.floor(tSkill.nLevel*2+30)
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		oTarUnit:AddAttr(gtBAT.eQX, nHPAdd, tSkillAct, sFrom)

		local nRounds = math.floor((tSkill.nLevel-oTarUnit:GetLevel())*0.1+tSkill.nLevel/80+3)
		if nRounds > 0 then
			oTarUnit:AddBuff(nSKID, tSkill.nLevel, 106, nRounds, tSkillAct)
		else
			oTarUnit.m_oBattle:WriteLog(oTarUnit:GetUnitID(), oTarUnit:GetObjName(), "106BUFF回合计算<=0:", tSkill.nLevel, oTarUnit:GetLevel())
		end
	end


end
--涅槃咒
--涅槃咒：终极奥义，治疗全体所有单位,恢复一定蓝量，使用后休息一回合。
CSkillHelper.fnLaunch[1218] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = oUnit:GetSkillConf(nSKID)
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		local nRecoverHP = math.floor(math.min(3000, oTarUnit:MaxAttr(gtBAT.eQX)*(0.2+tSkill.nLevel/500)+tSkill.nLevel*6+(tSkill.nLevel/12)^2))
		local nRecoverMP = math.floor(math.min(3000, oTarUnit:MaxAttr(gtBAT.eMF)*(0.2+tSkill.nLevel/500)+tSkill.nLevel*6+(tSkill.nLevel/12)^2)*0.6)
		oTarUnit:AddAttr(gtBAT.eMF, nRecoverMP, tSkillAct, string.format("技能%d恢复MP", nSKID))
		oTarUnit:AddAttr(gtBAT.eQX, nRecoverHP, tSkillAct, string.format("技能%d恢复HP", nSKID))
	end

	oUnit:AddBuff(nSKID, tSkill.nLevel, 104, 2, tSkillAct)
end

--------------------合欢------------------------
--百花缭乱 物理攻击多个目标，伤害结果减少5%；狂兽诀技能5级以上作用2个目标，40级以上作用3个目标
CSkillHelper.fnLaunch[1311] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHurtRatioAdd = -5
	tAttrAdd.nSkillHitRate = tConf.nHitRate

	--群伤比例
	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		oUnit:PhyAtk(oTarUnit, tSkillAct, tAttrAdd)
	end
end
--移花接木 变身状态下才能使用，攻击敌方多人，攻击提高10%，伤害提高30%，使用后次回合只能执行防御、保护、召唤指令或使用药品；大鹏展翅技能25级以上作用2个目标，35级以上作用3个目标，70级以上作用4个目标，105级以上作用5个目标
CSkillHelper.fnLaunch[1312] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHurtRatioAdd = 30
	tAttrAdd.nSkillAtkRatioAdd = 10
	tAttrAdd.nSkillHitRate = tConf.nHitRate

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		oUnit:PhyAtk(oTarUnit, tSkillAct, tAttrAdd)
	end

	oUnit:AddBuff(nSKID, tSkill.nLevel, 122, 2, tSkillAct)


end
--烟雨断肠 变身状态下才能使用，攻击敌人单个目标，临时提升自己的攻击力skill*1.5+20
CSkillHelper.fnLaunch[1313] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillAtkValAdd = math.floor(tSkill.nLevel*1.5+20)
	tAttrAdd.nSkillHitRate = tConf.nHitRate

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		oUnit:PhyAtk(oTarUnit, tSkillAct, tAttrAdd)
	end
end
--绵里藏针，临时提升自己的攻击力skill*1，攻击单人并令其2回合内无法使用法术、特技、物理攻击；使用后自身也附加此BUFF
CSkillHelper.fnLaunch[1314] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillAtkValAdd = tSkill.nLevel*1
	tAttrAdd.nSkillHitRate = tConf.nHitRate

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		oUnit:PhyAtk(oTarUnit, tSkillAct, tAttrAdd)
		oTarUnit:AddBuff(nSKID, tSkill.nLevel, 121, 2, tSkillAct)
	end

	--从变身恢复
	oUnit:RemoveBuff(120, nil, "从变身恢复")
	--自身BUFF
	oUnit:AddBuff(nSKID, tSkill.nLevel, 121, 2, tSkillAct)

end
--落花听雨 变身状态下才能使用，疯狂地连续攻击敌人，每次伤害减少10%，最小30%伤害，使用后取消变身状态，并休息1回合；极度疯狂技能60级以上连续攻击3次，90级以上连续攻击4次
CSkillHelper.fnLaunch[1315] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	local nAtkTimes =  2
	if tSkill.nLevel >= 90 then
		nAtkTimes = 4
	elseif tSkill.nLevel >= 60 then
		nAtkTimes = 3
	end

	local oTarUnit = tTarList[1]
	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, nAtkTimes, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHurtRatioAdd = 0
	tAttrAdd.nSkillAtkRatioAdd = 10
	tAttrAdd.nSkillHitRate = tConf.nHitRate

	local nHurtRatio = 0
	for k = 1, nAtkTimes do
		tAttrAdd.nSkillHurtRatioAdd = nHurtRatio
		oUnit:PhyAtk(oTarUnit, tSkillAct, tAttrAdd)
		nHurtRatio = math.max(-30, nHurtRatio-10)
		if oTarUnit:IsDeadOrLeave() then break end
	end
	--移除变身状态 
	oUnit:RemoveBuff(120, nil, "从变身恢复")

	--BUFF
	oUnit:AddBuff(nSKID, tSkill.nLevel, 104, 2, tSkillAct)
end
--痴情咒 【效果】复活一个友方目标，自身保留一点气血，3回合之内无法再次使用。
CSkillHelper.fnLaunch[1316] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	local oTarUnit = tTarList[1]
	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end

	table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
	if not oTarUnit:GetRoundFlag(CUnit.tRoundFlag.eLCKRL) then --被禁止复活
		local nMaxHP = oTarUnit:MaxAttr(gtBAT.eQX)
		oTarUnit:AddAttr(gtBAT.eQX, nMaxHP, tSkillAct, string.format("技能%d", nSKID))
	else
		oTarUnit.m_oBattle:WriteLog(oTarUnit:GetUnitID(), oTarUnit:GetObjName(), "技能1316复活失败(被禁止复活)")
	end
	self:SetSkillForbid(nSKID, oUnit.m_oBattle:GetRound()+2)
end
-- --觉醒 物理攻击敌人，伤害结果减少20%。为自己附加变身状态(skill-aimlv)/10+skill/40+4回合，最高7回合，临时提升自己的攻击力skill*0.5+20，是使用烟雨断肠，绵里藏针，移花接木，落花听雨的前提，注意，当对方无可攻击目标时，也可以变身成功
-- CSkillHelper.fnLaunch[1312] = function(self, nSKID, oUnit, tSkillExtCtx)
-- 	local tConf = ctSkillConf[nSKID]
-- 	local tSkill = oUnit:GetActSkill(nSKID)

-- 	local nNum = self:CalcTargetNum(oUnit, nSKID)

-- 	--目标列表(没有目标也可以变身)
-- 	local tTarList
-- 	if tSkillExtCtx.oTarget then
-- 		tTarList = { tSkillExtCtx.oTarget }
-- 	else
-- 		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
-- 	end
-- 	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
-- 	if tSkillExtCtx.tParentAct then
-- 		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
-- 	else
-- 		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
-- 	end

-- 	--先加BUFF
-- 	local nRounds = math.min(7, math.floor((tSkill.nLevel-oUnit:GetLevel())*0.1+tSkill.nLevel/40+4))
-- 	if nRounds > 0 then
-- 		oUnit:AddBuff(nSKID, tSkill.nLevel, 120, nRounds, tSkillAct)
-- 	else
-- 		oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), "120BUFF回合计算<=0:", tSkill.nLevel, oUnit:GetLevel())
-- 	end

-- 	--属性附加
-- 	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
-- 	tAttrAdd.tSkillMap[nSKID] = 1
-- 	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
-- 	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
-- 	tAttrAdd.nSkillHurtRatioAdd = -20
-- 	tAttrAdd.nSkillHitRate = tConf.nHitRate

-- 	for _, oTarUnit in ipairs(tTarList) do
-- 		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
-- 		oUnit:PhyAtk(oTarUnit, tSkillAct, tAttrAdd)
-- 	end
-- end
--狂风点柳
CSkillHelper.fnLaunch[1318] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = 100 
	tAttrAdd.nSkillHitRate = tConf.nHitRate
	tAttrAdd.nSkillStaticDef = 0

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		tAttrAdd.nSkillStaticDef = math.min(oTarUnit:GetAttr(gtBAT.eFY), oTarUnit:GetAttr(gtBAT.eLL))
		oUnit:PhyAtk(oTarUnit, tSkillAct, tAttrAdd)
	end


end

--------------------青云------------------------
--神剑御累真诀 使用水系法术攻击敌方多个目标50+skill*1+skill*skill/144，使用群伤递减规则，比较各目标灵力，武器攻击/4；呼风唤雨技能5级以上可以作用2个目标，35级以上作用3个目标，70级以上作用4个目标，105级以上作用5个目标
CSkillHelper.fnLaunch[1411] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHitRate = tConf.nHitRate
	tAttrAdd.nSkillHurtValAdd = 0

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	local nSkillHurtAdd = 50+tSkill.nLevel+tSkill.nLevel*tSkill.nLevel/144
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		tAttrAdd.nSkillHurtValAdd = nSkillHurtAdd
		oUnit:MagAtk(nSKID, oTarUnit, tSkillAct, tAttrAdd)
	end


end
--天灵剑诀 使用水系法术攻击单个目标，伤害为75+skill*1.7+skill*skill/105，同时比较灵力，武器攻击/4
CSkillHelper.fnLaunch[1412] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end

	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHitRate = tConf.nHitRate
	tAttrAdd.nSkillHurtValAdd = 0

	local nSkillHurtAdd = 70+tSkill.nLevel*1.7+tSkill.nLevel*tSkill.nLevel/105
	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		tAttrAdd.nSkillHurtValAdd = nSkillHurtAdd
		oUnit:MagAtk(nSKID, oTarUnit, tSkillAct, tAttrAdd)
	end
	

end
--碎玉剑诀 减少敌方全体队员一定的气血skill+10和魔法值skill*2
CSkillHelper.fnLaunch[1413] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	local nMFSub = tSkill.nLevel * 2
	local nQXSub = tSkill.nLevel + 10

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		oTarUnit:AddAttr(gtBAT.eMF, -nMFSub, tSkillAct, string.format("技能%d", nSKID))
		oTarUnit:AddAttr(gtBAT.eQX, -nQXSub, tSkillAct, string.format("技能%d", nSKID), oUnit)
	end


end
--唤雷剑诀 使用雷系法术攻击敌人50+skill*1.5+skill*skill/170，同时比较灵力，武器攻击/4，可攻击隐身的怪物和宠物，同时20%概率将其隐身状态清除
CSkillHelper.fnLaunch[1414] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--可攻击隐身
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eIGNHIDE, nSKID, {})

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eIGNHIDE, nSKID)
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHitRate = tConf.nHitRate
	tAttrAdd.nSkillHurtValAdd = 0

	local nSkillHurtAdd = 75+tSkill.nLevel*1.7+tSkill.nLevel*tSkill.nLevel/105
	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end

	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		tAttrAdd.nSkillHurtValAdd = nSkillHurtAdd
		oUnit:MagAtk(nSKID, oTarUnit, tSkillAct, tAttrAdd)

		--概率移除隐身
		if oTarUnit:IsHide() then
			local nRnd = math.random(100)
			if nRnd <= 20 then
				oTarUnit:RemoveBuff(303, tSkillAct, "概率移除隐身")
			end
		end
	end

	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eIGNHIDE, nSKID)
end
--醉风望月 使用水系法术攻击单个目标同时为自己附加魔法反击效果，伤害为50+skill*1.5+skill*skill/170，同时比较灵力，武器攻击/4，受普通物理攻击则以龙腾反击对手，伤害为龙腾正常的一半
CSkillHelper.fnLaunch[1415] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHitRate = tConf.nHitRate
	tAttrAdd.nSkillHurtValAdd = 0

	local nSkillHurtAdd = 50+tSkill.nLevel*1.2+tSkill.nLevel*tSkill.nLevel/140
	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		tAttrAdd.nSkillHurtValAdd = nSkillHurtAdd
		oUnit:MagAtk(nSKID, oTarUnit, tSkillAct, tAttrAdd)
	end

	--BUFF
	oUnit:AddBuff(nSKID, tSkill.nLevel, 113, 1, tSkillAct)

end
--挑月剑诀 使用火系法术攻击两个目标，伤害为50+skill*1.2+skill*skill/140，使用群伤递减规则，同时比较灵力，武器攻击/4
CSkillHelper.fnLaunch[1416] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHitRate = tConf.nHitRate
	tAttrAdd.nSkillHurtValAdd = 0

	local nSkillHurtAdd = 50+tSkill.nLevel*1.2+tSkill.nLevel*tSkill.nLevel/140
	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		tAttrAdd.nSkillHurtValAdd = nSkillHurtAdd
		oUnit:MagAtk(nSKID, oTarUnit, tSkillAct, tAttrAdd)
	end

end
--万剑归宗
CSkillHelper.fnLaunch[1418] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败",nSKID))
	end

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHitRate = tConf.nHitRate
	local nBaseHurt = 50+tSkill.nLevel+tSkill.nLevel*tSkill.nLevel/144
	tAttrAdd.nSkillHurtValAdd = 0
	tAttrAdd.nSkillHurtRatioAdd = 0

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		local nCurMP = oTarUnit:GetAttr(gtBAT.eMF)
		local nMaxMP = oTarUnit:MaxAttr(gtBAT.eMF)
		tAttrAdd.nSkillHurtValAdd = nBaseHurt*(1+(1-nCurMP/nMaxMP)/4)
		oUnit:MagAtk(nSKID, oTarUnit, tSkillAct, tAttrAdd)
	end

	--BUFF
	oUnit:AddBuff(nSKID, tSkill.nLevel, 104, 2, tSkillAct)

end

--------------------圣巫------------------------
--痴心裂 使用土系法术攻击多个目标，造成(75+skill*1.5)的固定伤害或(50+skill*1+skill*skill/144+灵力差+武器伤害/4），其中固定伤害对普通怪物的伤害提高100%，而灵力算法的则受群攻规则和法攻修炼影响，优先取最终数值较高的那个；技能5级以上作用2个目标，40级以上作用3个目标,80级以上4个目标
CSkillHelper.fnLaunch[1511] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	--属性附加
	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHitRate = tConf.nHitRate
	tAttrAdd.nSkillStaticHurt = 0

	local nStaticHurtTmp1 = 75+tSkill.nLevel*1.5
	local nStaticHurtTmp2 = 50+tSkill.nLevel+tSkill.nLevel*tSkill.nLevel/144
	local nSrcLL = oUnit:GetAttr(gtBAT.eLL)

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		local nLL = oTarUnit:GetAttr(gtBAT.eLL)
		local nWA = oTarUnit:GetWeaponAtk() 
		local nStaticHurt1 = oTarUnit:IsMonster() and nStaticHurtTmp1*2 or nStaticHurtTmp1
		local nStaticHurt2 = math.floor(nStaticHurtTmp1+nSrcLL-nLL-nWA/4) --修炼加成? fix pd

		tAttrAdd.nSkillStaticHurt = nStaticHurt1
		tAttrAdd.bIgnoreGroupAtkHurt = true
		if nStaticHurt1	< nStaticHurt2 then
			tAttrAdd.nSkillStaticHurt = nStaticHurt2
			tAttrAdd.bIgnoreGroupAtkHurt = false
		end

		oUnit:MagAtk(nSKID, oTarUnit, tSkillAct, tAttrAdd)
	end

end
--禁灵锁 有(skill-aimlv)*2%+60%几率，最低20%，最高70%令对手(skill-aimlv)/10+skill/90+3回合内无法使用物理攻击同时为自己附加防御力skill*1.5效果。如果被封印目标已使用过法术，则封印持续回合+1
CSkillHelper.fnLaunch[1512] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		local nRate = math.min(70, math.max(20, math.floor((tSkill.nLevel-oTarUnit:GetLevel())*2+60)))
		local bTrigger = math.random(100) <= nRate
		if bTrigger then
			local nRounds = math.floor((tSkill.nLevel-oTarUnit:GetLevel())*0.1+tSkill.nLevel/90+3)
			if nRounds > 0 then
				oUnit:AddBuff(nSKID, tSkill.nLevel, 127, nRounds, tSkillAct)
				local tInst = oTarUnit:GetInst()
				if tInst.bExed and tInst.nInst == CUnit.tINST.eFS then
					nRounds = nRounds + 1
				end
				oTarUnit:AddBuff(nSKID, tSkill.nLevel, 124, nRounds, tSkillAct)
			else
				oTarUnit.m_oBattle:WriteLog(oTarUnit:GetUnitID(), oTarUnit:GetObjName(), "127BUFF回合计算<=0", tSkill.nLevel, oTarUnit:GetLevel())
			end
		end
	end

end
--绵骨咒 有(skill-aimlv)*2%+55%几率，最低20%，最高70%令对手(skill-aimlv)/10+skill/90+3回合内无法使用法术、物理攻击。如果被封印目标已使用过法术，则封印持续回合+1
CSkillHelper.fnLaunch[1513] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		local nRate = math.min(70, math.max(20, math.floor((tSkill.nLevel-oTarUnit:GetLevel())*2+55)))
		local bTrigger = math.random(100) <= nRate
		if bTrigger then
			local nRounds = math.floor((tSkill.nLevel-oTarUnit:GetLevel())*0.1+tSkill.nLevel/90+3)
			if nRounds > 0 then
				local tInst = oTarUnit:GetInst()
				if tInst.bExed and tInst.nInst == CUnit.tINST.eFS then
					nRounds = nRounds + 1
				end
				oTarUnit:AddBuff(nSKID, tSkill.nLevel, 125, nRounds, tSkillAct)
			else
				oTarUnit.m_oBattle:WriteLog(oTarUnit:GetUnitID(), oTarUnit:GetObjName(), "125BUFF回合计算<=0", tSkill.nLevel, oTarUnit:GetLevel())
			end
		end
	end

end
--焚魄炎 吸取对方的气血skill*3+对方当前气血的10%（最高不超过技能等级*30）来补充自己的气血（补充量为对方损失量的一半）；失败则只减少敌人5%的当前气血(最高不超过技能等级*10)，(skill-aimlv)*2%+60%几率，最低30%，最高90%
CSkillHelper.fnLaunch[1514] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		local nRate = math.min(90, math.max(30, math.floor((tSkill.nLevel-oTarUnit:GetLevel())*2+60)))
		local bTrigger = math.random(100)
		if bTrigger then
			local nQXSub = math.min(tSkill.nLevel*30, math.floor(tSkill.nLevel*3+oTarUnit:GetAttr(gtBAT.eQX)*0.1))
			oTarUnit:AddAttr(gtBAT.eQX, -nQXSub, tSkillAct, string.format("技能%d", nSKID), oUnit)

			local nQXAdd = math.floor(nQXSub*0.5)
			oUnit:AddAttr(gtBAT.eQX, nQXAdd, tSkillAct, string.format("技能%d", nSKID))
		else
			local nQXSub = math.min(tSkill.nLevel*10, math.floor(oTarUnit:GetAttr(gtBAT.eQX)*0.05))
			oTarUnit:AddAttr(gtBAT.eQX, -nQXSub, tSkillAct, string.format("技能%d", nSKID), oUnit)

			local nQXAdd = math.floor(nQXSub*0.5)
			oUnit:AddAttr(gtBAT.eQX, nQXAdd, tSkillAct, string.format("技能%d", nSKID))
		end
	end

end
--碎灵诀 有(skill-aimlv)*2%+60%几率，最低30%，最高90%吸取skill*5对方的魔法值来补充自己的魔法值
CSkillHelper.fnLaunch[1515] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		local nRate = math.min(90, math.max(30, math.floor((tSkill.nLevel-oTarUnit:GetLevel())*2+60)))
		local bTrigger = math.random(100) <= nRate
		if bTrigger then
			local nMP = tSkill.nLevel*5
			oTarUnit:AddAttr(gtBAT.eMF, -nMP, tSkillAct, string.format("技能%d", nSKID))
			oUnit:AddAttr(gtBAT.eMF, nMP, tSkillAct, string.format("技能%d", nSKID))
		end
	end


end
--魔入膏盲 临时降低自身一定速度，速率50%，有(skill-aimlv)*2%+50%几率，最低20%，最高70%令对手(skill-aimlv)/10+skill/40+3回合内无法被复活。如果被封印目标已使用过法术，则封印持续回合+1
CSkillHelper.fnLaunch[1516] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end

	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		local nRate = math.min(70, math.max(20, math.floor((tSkill.nLevel-oTarUnit:GetLevel())*2+50)))
		local bTrigger = math.random(100) <= nRate
		if bTrigger then
			local nRounds = math.floor((tSkill.nLevel-oTarUnit:GetLevel())*0.1+tSkill.nLevel/40+3)
			if nRounds > 0 then
				local tInst = oTarUnit:GetInst()
				if tInst.bExed and tInst.nInst == CUnit.tINST.eFS then
					nRounds = nRounds + 1
				end
				oTarUnit:AddBuff(nSKID, tSkill.nLevel, 126, nRounds, tSkillAct)
			else
				oTarUnit.m_oBattle:WriteLog(oTarUnit:GetUnitID(), oTarUnit:GetObjName(), "126BUFF回合计算<=0", tSkill.nLevel, oTarUnit:GetLevel())
			end
		end
	end


	--恢复速度
	local nSDAdd = self:GetSkillAttr(nSKID, gtBAT.eSD)
	oUnit:AddAttr(gtBAT.eSD, -nSDAdd, nil, string.format("技能%d", nSKID))
end
--凝石咒
CSkillHelper.fnLaunch[1518] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("技能%d 选择目标失败", nSKID))
	end

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("技能%d", nSKID))
	end
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		local nRate = math.min(70, math.max(20, math.floor((tSkill.nLevel-oTarUnit:GetLevel())*2+55)))
		local bTrigger = math.random(100) <= nRate
		if bTrigger then
			local nRounds = math.floor((tSkill.nLevel-oTarUnit:GetLevel())*0.1+tSkill.nLevel/90+3)
			if nRounds > 0 then
				local tInst = oTarUnit:GetInst()
				if tInst.bExed and tInst.nInst == CUnit.tINST.eFS then
					nRounds = nRounds + 1
				end
				oTarUnit:AddBuff(nSKID, tSkill.nLevel, 125, nRounds, tSkillAct)
			else
				oTarUnit.m_oBattle:WriteLog(oTarUnit:GetUnitID(), oTarUnit:GetObjName(), "125BUFF回合计算<=0", tSkill.nLevel, oTarUnit:GetLevel())
			end
		end
	end
	oUnit:AddBuff(nSKID, tSkill.nLevel, 104, 2, tSkillAct)

end

------------宠物主动技能---------------------
-- 单体雷系攻击法术，消耗的MP=自身等级×2，附加法术伤害=等级*2+15
-- 单体火系攻击法术，消耗的MP=自身等级×2，附加法术伤害=等级*2+15
-- 单体水系攻击法术，消耗的MP=自身等级×2，附加法术伤害=等级*2+15
-- 单体土系攻击法术，消耗的MP=自身等级×2，附加法术伤害=等级*2+15
-- 群体雷系攻击法术（初始作用2个目标、50级以上作用3个目标）消耗MP：自身等级*2，附加法术伤害=等级*1.5+30，受群攻规则影响
-- 群体火系攻击法术（初始作用2个目标、50级以上作用3个目标）消耗MP：自身等级*2，附加法术伤害=等级*1.5+30，受群攻规则影响
-- 群体水系攻击法术（初始作用2个目标、50级以上作用3个目标）消耗MP：自身等级*2，附加法术伤害=等级*1.5+30，受群攻规则影响
-- 群体土系攻击法术（初始作用2个目标、50级以上作用3个目标）消耗MP：自身等级*2，附加法术伤害=等级*1.5+30，受群攻规则影响
-- 群体物理攻击法术（初始作用2个目标、50级以上作用3个目标）消耗MP：自身等级*2，1人100%，2人75%，3人60%。（冲击、高级冲击、恐怖、高级恐怖有效）

--惊雷
CSkillHelper.fnLaunch[5301] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctPetSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("宠物技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("宠物技能%d 选择目标失败", nSKID))
	end

	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHurtValAdd = oUnit:GetLevel()*2+15
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nSkillHitRate = tConf.nHitRate

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("宠物技能%d", nSKID))
	end
	
	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		oUnit:MagAtk(nSKID, oTarUnit, tSkillAct, tAttrAdd)
	end

end
CSkillHelper.fnLaunch[5302] = CSkillHelper.fnLaunch[5301] 
CSkillHelper.fnLaunch[5303] = CSkillHelper.fnLaunch[5301] 
CSkillHelper.fnLaunch[5304] = CSkillHelper.fnLaunch[5301] 

CSkillHelper.fnLaunch[5305] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctPetSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)

	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	local tTarList
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("宠物技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("宠物技能%d 选择目标失败", nSKID))
	end

	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	tAttrAdd.nGroupAtkHurtRatio = self:GetGroupAtkHurtRatio(#tTarList)
	tAttrAdd.nSkillHurtValAdd = math.floor(oUnit:GetLevel()*1.5+30)
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nSkillHitRate = tConf.nHitRate

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("宠物技能%d", nSKID))
	end

	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		oUnit:MagAtk(nSKID, oTarUnit, tSkillAct, tAttrAdd)
	end
end
CSkillHelper.fnLaunch[5306] = CSkillHelper.fnLaunch[5305] 
CSkillHelper.fnLaunch[5307] = CSkillHelper.fnLaunch[5305] 
CSkillHelper.fnLaunch[5308] = CSkillHelper.fnLaunch[5305] 
CSkillHelper.fnLaunch[5309] = function(self, nSKID, oUnit, tSkillExtCtx)
	local tConf = ctPetSkillConf[nSKID]
	local tSkill = oUnit:GetActSkill(nSKID)
	local nNum = self:CalcTargetNum(oUnit, nSKID)

	--目标列表
	if tSkillExtCtx.oTarget then
		tTarList = { tSkillExtCtx.oTarget }
	else
		tTarList = oUnit.m_oSelectHelper:SkillTarget(oUnit, nSKID, nNum, string.format("宠物技能%d", nSKID))
	end
	if #tTarList <= 0 then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), string.format("宠物技能%d 选择目标失败", nSKID))
	end

	local tAttrAdd = table.DeepCopy(CSkillHelper.tSkillAttrAdd) 
	tAttrAdd.tSkillMap[nSKID] = 1
	local tTmpGroupAtkHurtRatio = {100, 75, 60}
	local nTmpTargets = math.max(1, math.min(3, #tTarList))
	tAttrAdd.nGroupAtkHurtRatio = tTmpGroupAtkHurtRatio[nTmpTargets]
	tAttrAdd.nSkillHurtRatioAdd1 = tSkillExtCtx.nSkillHurtRatioAdd
	tAttrAdd.nSkillHitRate = tConf.nHitRate

	local tSkillAct = self:MakeSkillAct(oUnit, nSKID, 1, tSkillExtCtx)
	if tSkillExtCtx.tParentAct then
		oUnit:AddReactAct(tSkillExtCtx.tParentAct, tSkillAct, tSkillExtCtx.sFrom)
	else
		oUnit.m_oBattle:AddRoundAction(tSkillAct, string.format("宠物技能%d", nSKID))
	end

	for _, oTarUnit in ipairs(tTarList) do
		table.insert(tSkillAct.tTarUnit, oTarUnit:GetUnitID())
		oUnit:PhyAtk(oTarUnit, tSkillAct, tAttrAdd)
	end
end
--召唤子怪技能
CSkillHelper.fnLaunch[5310] = function(self, nSKID, oUnit, tSkillExtCtx)
	local bRes, sErr = oUnit:CanCallSubMonster()
	oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), "召唤子怪"
		, bRes, sErr, oUnit:GetSubMonsterDeadLeaveRound(), oUnit:GetSubMonsterCalledTimes())
	if not bRes then
		return
	end
	oUnit:ZHSubMonster()
end


--是否可以执行
function CSkillHelper:CanLaunch(oUnit, nSKID, bDisplay)
	local fnCanLaunch = self.fnCanLaunch[nSKID]
	if not fnCanLaunch then
		LuaTrace("技能未实现:", nSKID)
		return false, "技能未实现:"..nSKID, ""
	end
	local bRes, sErr, sConsumeTips = fnCanLaunch(self, nSKID, oUnit, false, bDisplay)
	return bRes, sErr, sConsumeTips
end

--执行技能消耗
function CSkillHelper:CostLaunch(oUnit, nSKID)
	local fnCanLaunch = self.fnCanLaunch[nSKID]
	if not fnCanLaunch then
		return LuaTrace("技能未实现:", nSKID)
	end
	fnCanLaunch(self, nSKID, oUnit, true)
end

--回合开始前结算
function CSkillHelper:BeforeRound(oUnit, nSKID)
	oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), "预处理技能", nSKID)
	local fnBeforeRound = self.fnBeforeRound[nSKID]	
	if fnBeforeRound then
		fnBeforeRound(self, nSKID, oUnit)
	end
end

--执行后事件
function CSkillHelper:AfterLaunch(oUnit, nSKID)
	local fnAfterLaunch = self.fnAfterLaunch[nSKID]
	if not fnAfterLaunch then
		return 
	end
	fnAfterLaunch(self, nSKID, oUnit)
end

--发动技能
function CSkillHelper:Launch(oUnit, nSKID, tSkillExtCtx)
	local fnLaunch = self.fnLaunch[nSKID]
	tSkillExtCtx = tSkillExtCtx or table.DeepCopy(CSkillHelper.tSkillExtCtx)
	fnLaunch(self, nSKID, oUnit, tSkillExtCtx)
end

--执行技能
function CSkillHelper:ExecSkill(oUnit, nSKID)
	oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), "执行技能", nSKID)
	local tSkill = oUnit:GetActSkill(nSKID)

	local bRes, sErr = true, ""	
	local tInst = oUnit:GetInst()
	if (tInst.nBuffID or 0) == 0 then --BUFF触发自动攻击不消耗资源
		bRes, sErr = self:CanLaunch(oUnit, nSKID)
	end

	if not bRes then
		local tInst = oUnit:GetInst()
		if tInst.nTarUnit == 0 
			or (tInst.nTarUnit > 0 and not oUnit.m_oSelectHelper:CheckSkillTarget(oUnit, 1, tInst.nTarUnit))
			or (tInst.nTarUnit > 0 and oUnit:IsSameTeam(tInst.nTarUnit)) then
				tInst.nTarUnit = 0
				local oTarUnit = oUnit.m_oSelectHelper:SkillTarget(oUnit, 1, 1, "技能发动失败普攻代替")[1]
				tInst.nTarUnit = oTarUnit and oTarUnit:GetUnitID() or 0
		end
		if tInst.nTarUnit > 0 then
			if oUnit:ReplaceInst(CUnit.tINST.eGJ, tInst.nTarUnit, string.format("%s发动%s失败", sErr, tSkill.sName)) then
				oUnit:ExecInst()
			end
		end
	else
		if (tInst.nBuffID or 0) == 0 then
			self:CostLaunch(oUnit, nSKID)
		end
		self:Launch(oUnit, nSKID)
		--法术连击
		if self.m_tSkillDoubleHit and not oUnit:IsDeadOrLeave() then
			self:Launch(oUnit, nSKID, self.m_tSkillDoubleHit)
		end
	end
	self:AfterLaunch(oUnit, nSKID)
	self:ClearSkillAttr(nSKID)
	self:ClearSkillDoubleHit()
end