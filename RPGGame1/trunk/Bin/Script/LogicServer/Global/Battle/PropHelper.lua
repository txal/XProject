--物品辅助类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local function _fnExecPropEffect(self, oProp, oUnit, oTarUnit, tParentAct)
	local tAttrList = self:CalcEffect(oUnit, oProp)
	for _, tAttr in ipairs(tAttrList) do
		oTarUnit:AddAttr(tAttr[1], tAttr[2], tParentAct, "使用药品"..oProp:GetID())
	end

	local tPropConf = oProp:GetPropConf()
	local tLogicConf = assert(ctLogicFuncConf[tPropConf.nLogicID])
	oTarUnit:ClearBuffTypeAttr(tLogicConf.nClearBuffStateAttr, tParentAct)
	if tLogicConf.nBuffID > 0 then
		oTarUnit:AddBuff(0, 0, tLogicConf.nBuffID, tLogicConf.eRounds(), tParentAct)
	end
end

CPropHelper.fnPropFunc = {}
CPropHelper.fnPropFunc[101] = function(self, oProp, oUnit, oTarUnit, tParentAct)
	if oTarUnit:IsDeadOrLeave() then
		return false, "目标已死亡或离开，使用药品失败"
	end
	_fnExecPropEffect(self, oProp, oUnit, oTarUnit, tParentAct)
	return true
end
CPropHelper.fnPropFunc[102] = CPropHelper.fnPropFunc[101]
CPropHelper.fnPropFunc[103] = CPropHelper.fnPropFunc[101]
CPropHelper.fnPropFunc[104] = CPropHelper.fnPropFunc[101]
CPropHelper.fnPropFunc[105] = CPropHelper.fnPropFunc[101]
CPropHelper.fnPropFunc[106] = CPropHelper.fnPropFunc[101]
CPropHelper.fnPropFunc[107] = CPropHelper.fnPropFunc[101]
CPropHelper.fnPropFunc[108] = CPropHelper.fnPropFunc[101]

CPropHelper.fnPropFunc[109] = function(self, oProp, oUnit, oTarUnit, tParentAct)
	if not oTarUnit:IsDead() or oTarUnit:IsLeave() then
		return false, "目标不需要复活"
	end
	if oTarUnit:GetRoundFlag(CUnit.tRoundFlag.eLCKRL) then
		return false, "目标被禁止复活"
	end
	_fnExecPropEffect(self, oProp, oUnit, oTarUnit, tParentAct)
	return true
end

CPropHelper.fnPropFunc[110] = function(self, oProp, oUnit, oTarUnit, tParentAct)
	if not oTarUnit:IsDead() or oTarUnit:IsLeave() then
		return false, "目标不需要复活"
	end
	if oTarUnit:GetRoundFlag(CUnit.tRoundFlag.eLCKRL) then
		return false, "目标被禁止复活"
	end
	_fnExecPropEffect(self, oProp, oUnit, oTarUnit, tParentAct)
	return true
end

CPropHelper.fnPropFunc[111] = CPropHelper.fnPropFunc[101]
CPropHelper.fnPropFunc[201] = CPropHelper.fnPropFunc[101]
CPropHelper.fnPropFunc[202] = CPropHelper.fnPropFunc[101]
CPropHelper.fnPropFunc[203] = CPropHelper.fnPropFunc[101]
CPropHelper.fnPropFunc[204] = CPropHelper.fnPropFunc[101]
CPropHelper.fnPropFunc[205] = CPropHelper.fnPropFunc[101]
CPropHelper.fnPropFunc[301] = CPropHelper.fnPropFunc[101]
CPropHelper.fnPropFunc[302] = CPropHelper.fnPropFunc[101]
CPropHelper.fnPropFunc[303] = CPropHelper.fnPropFunc[101]
CPropHelper.fnPropFunc[304] = CPropHelper.fnPropFunc[101]

--构造函数
function CPropHelper:Ctor()
end

--计算效果数值
function CPropHelper:CalcEffect(oUnit, oProp)
	local oRoleUnit = oUnit
	if oUnit:IsPet() then
		oRoleUnit = oUnit.m_oBattle:GetMainUnit(oUnit:GetUnitID())
	end

	local tAttrList, tAttrValList = {}, {}
	local tPropConf = oProp:GetPropConf()
	local tLogicConf = assert(ctLogicFuncConf[tPropConf.nLogicID])
	for _, tAttr in ipairs(tLogicConf.tAttrAdd) do
		if tAttr[1] > 0 then
			local nAddVal = math.floor(tAttr[2](oProp:GetStar(), oRoleUnit:GetLevel()))
			table.insert(tAttrList, {tAttr[1], nAddVal})
			table.insert(tAttrValList, nAddVal)
		end
	end

	local sEffect = ""
	if tLogicConf.sEffect then
		sEffect = string.format(tLogicConf.sEffect, table.unpack(tAttrValList))
	end
	return tAttrList, sEffect
end

--使用物品
function CPropHelper:UseProp(oProp, oUnit, oTarUnit)
	local tPropConf = oProp:GetPropConf()
	local tLogicConf = assert(ctLogicFuncConf[tPropConf.nLogicID])

	local tWPAct = {
		nAct = gtACT.eWP,
		nSrcUnit = oUnit:GetUnitID(),
		tTarUnit = {oTarUnit:GetUnitID()},
		nPropID = 0,
		sTips = "",
		nTime = GetActTime(gtACT.eWP),
		tReact = {},
	}	

	if oUnit:IsLockAction() then
		tWPAct.sTips = "被禁止行动，使用药品失败"

	elseif oProp:GetNum() <= 0 then
		tWPAct.sTips = "药品不存在，使用失败"

	else
		local fnProp = CPropHelper.fnPropFunc[tPropConf.nLogicID]
		if fnProp then
			local bRes, sErr = fnProp(self, oProp, oUnit, oTarUnit, tWPAct)
			if not bRes then
				tWPAct.sTips = sErr
			else
				tWPAct.nPropID = oProp:GetID()
				local oRoleUnit = oUnit:IsRole() and oUnit or oUnit.m_oBattle:GetMainUnit(oUnit:GetUnitID())
				local oRole = goPlayerMgr:GetRoleByID(oRoleUnit:GetObjID())
				oRole.m_oKnapsack:SubGridItem(oProp:GetGrid(), oProp:GetID(), 1, "战斗使用")
				oRoleUnit:AddPropUsed()
			end
		else
			tWPAct.sTips = "药品逻辑未实现:"..oProp:GetID()
		end

	end
	oUnit.m_oBattle:AddRoundAction(tWPAct, "药品:"..oProp:GetID())
end

--检测物品目标是否正确
function CPropHelper:CheckTarget(oProp, oUnit, oTarUnit)
	if oProp:GetNum() <= 0 then
		return LuaTrace("药品数量不足", oProp:GetID())
	end
	local tPropConf = oProp:GetPropConf()
	local tLogicConf = ctLogicFuncConf[tPropConf.nLogicID]
	if not tLogicConf then
		return LuaTrace("药品逻辑ID配置不存在", oProp:GetID())
	end
	if tPropConf.nType == gtPropType.eMedicine and tPropConf.nSubType == gtMedType.eWine 
		or tPropConf.nType == gtPropType.eCooking then
			if oUnit ~= oTarUnit or not oUnit:IsRole() then
				local oRoleUnit = oUnit
				if oUnit:IsPet() then oRoleUnit = oUnit.m_oBattle:GetMainUnit(oUnit:GetUnitID()) end
				return oUnit.m_oBattle:Tips(oRoleUnit, "酒类只能对角色自身使用")
			end
	end
	if not oUnit:IsSameTeam(oTarUnit:GetUnitID()) then
		local oRoleUnit = oUnit
		if oUnit:IsPet() then oRoleUnit = oUnit.m_oBattle:GetMainUnit(oUnit:GetUnitID()) end
		return oUnit.m_oBattle:Tips(oRoleUnit, "只能对自己和队友使用药品")
	end
	return true
end