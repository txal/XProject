--AI辅助类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local gtBTT, gtBAT, gtBTRes, gtRatioAttr, gtACT, GetActTime, gtAddAttrModType, gtBATName
= gtBTT, gtBAT, gtBTRes, gtRatioAttr, gtACT, GetActTime, gtAddAttrModType, gtBATName

--技能触发条件函数
CAIHelper.tCondFunc = {}
CAIHelper.tCondFunc["minHP"]= function(self, oTarUnit, tCond)
	local nCurrHP = oTarUnit:GetAttr(gtBAT.eQX)
	local nMaxHP = oTarUnit:MaxAttr(gtBAT.eQX)
	if nCurrHP >= nMaxHP*tCond.minHP*0.01 then
		return true
	end
end
CAIHelper.tCondFunc["maxHP"] = function(self, oTarUnit, tCond)
	local nCurrHP = oTarUnit:GetAttr(gtBAT.eQX)
	local nMaxHP = oTarUnit:MaxAttr(gtBAT.eQX)
	if nCurrHP <= nMaxHP*tCond.maxHP*0.01 then
		return true
	end
end
CAIHelper.tCondFunc["withoutPasSkillAnd"] = function(self, oTarUnit, tCond)
	for _, nPasSkillID in ipairs(tCond.withoutPasSkillAnd) do
		if oTarUnit:GetPasSkill(nPasSkillID) then
			return false
		end
	end
	return true
end
CAIHelper.tCondFunc["withoutBuffAnd"] = function(self, oTarUnit, tCond)
	for _, nBuffID in ipairs(tCond.withoutBuffAnd) do
		if oTarUnit:GetBuff(nBuffID) then
			return false
		end
	end
	return true
end
CAIHelper.tCondFunc["withBuffOr"] = function(self, oTarUnit, tCond)
	for _, nBuffID in ipairs(tCond.withBuffOr) do
		if oTarUnit:GetBuff(nBuffID) then
			return true
		end
	end
end
CAIHelper.tCondFunc["maxLevel"] = function(self, oTarUnit, tCond)
	return oTarUnit:GetLevel() <= tCond.maxLevel
end
CAIHelper.tCondFunc["objectTypeOr"] = function(self, oTarUnit, tCond)
	local nObjType = oTarUnit:GetObjType()
	return table.InArray(nObjType, tCond.objectTypeOr)
end
CAIHelper.tCondFunc["asSkillTargetOr"] = function(self, oTarUnit, tCond)
	local nTarUnitID = oTarUnit:GetUnitID()
	local tSrcTeamMap = self.m_oBattle:GetEnemyTeam(nTarUnitID)
	for nUnitID, oUnit in pairs(tSrcTeamMap) do
		local tInst = oUnit:GetInst()
		if tInst.nInst == CUnit.tINST.eFS and table.InArray(tInst.nSkill, tCond.asSkillTargetOr or {}) and tInst.nTarUnit == nTarUnitID then
			return true
		end
	end
end
CAIHelper.tCondFunc["freeTarget"] = function(self, oTarUnit)
	local nTarUnitID = oTarUnit:GetUnitID()
	local tSrcTeamMap = self.m_oBattle:GetEnemyTeam(nTarUnitID)
	for nUnitID, oUnit in pairs(tSrcTeamMap) do
		local tInst = oUnit:GetInst()
		if tInst.nTarUnit == nTarUnitID then
			return
		end
	end
	return true
end


--自身条件
local function targetTypeCond0(self, nSKID, oUnit, tCond)
	if not next(tCond) then
		return true
	end
	assert(tCond.targetType == 0, "目标类型错误")

	if tCond.minHP then
		if not CAIHelper.tCondFunc["minHP"](self, oUnit, tCond) then
			return
		end
	end
	if tCond.maxHP then
		if not CAIHelper.tCondFunc["maxHP"](self, oUnit, tCond) then
			return
		end
	end
	if tCond.withoutBuffAnd then
		if not CAIHelper.tCondFunc["withoutBuffAnd"](self, oUnit, tCond) then
			return
		end
	end
	if tCond.withBuffOr then
		if not CAIHelper.tCondFunc["withBuffOr"](self, oUnit, tCond) then
			return
		end
	end
	return true
end

local function condDetailLog(oUnit, nSKID, sCond, bRes, nAllUnitCount, nUnitCount)
	oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), nSKID, sCond, bRes, nAllUnitCount, nUnitCount)
end

--条件(己方/敌方)
local function targetTypeCond1(self, nSKID, oUnit, tCond)
	if not next(tCond) then
		return true
	end

	local nUnitCount = 0
	local nAllUnitCount = 0

	local tTeamMap
	if tCond.targetType == 1 then
		tTeamMap = self.m_oBattle:GetTeam(oUnit:GetUnitID())
	elseif tCond.targetType == 2 then
		tTeamMap = self.m_oBattle:GetEnemyTeam(oUnit:GetUnitID())
	end

	for _, oTmpUnit in pairs(tTeamMap) do
		if not oTmpUnit:IsDeadOrLeave() then
			local bWithoutPasSkill = true 
			if tCond.withoutPasSkillAnd then
				bWithoutPasSkill = CAIHelper.tCondFunc["withoutPasSkillAnd"](self, oTmpUnit, tCond)
				condDetailLog(oUnit, nSKID, "withoutPasSkillAnd", bWithoutPasSkill, nAllUnitCount, nUnitCount)
			end

			if bWithoutPasSkill then
				nAllUnitCount = nAllUnitCount + 1

				local bObjType = true
				if tCond.objectTypeOr then
					bObjType = CAIHelper.tCondFunc["objectTypeOr"](self, oTmpUnit, tCond)
					condDetailLog(oUnit, nSKID, "objectTypeOr", bObjType, nAllUnitCount, nUnitCount)
				end

				if bObjType then
					local bMinHP = true
					if tCond.minHP then
						bMinHP = CAIHelper.tCondFunc["minHP"](self, oTmpUnit, tCond)
						condDetailLog(oUnit, nSKID, "minHP", bMinHP, nAllUnitCount, nUnitCount)
					end

					if bMinHP then
						local bMaxHP = true
						if tCond.maxHP then
							bMaxHP = CAIHelper.tCondFunc["maxHP"](self, oTmpUnit, tCond)
							condDetailLog(oUnit, nSKID, "maxHP", bMaxHP, nAllUnitCount, nUnitCount)
						end

						if bMaxHP then
							if bWithoutPasSkill then
								local bWithoutBuff = true
								if tCond.withoutBuffAnd then
									bWithoutBuff = CAIHelper.tCondFunc["withoutBuffAnd"](self, oTmpUnit, tCond)
									condDetailLog(oUnit, nSKID, "withoutBuffAnd", bWithoutBuff, nAllUnitCount, nUnitCount)
								end

								if bWithoutBuff then
									local bWithBuff = true
									if tCond.withBuffOr then
										bWithBuff = CAIHelper.tCondFunc["withBuffOr"](self, oTmpUnit, tCond)
										condDetailLog(oUnit, nSKID, "withBuffOr", bWithBuff, nAllUnitCount, nUnitCount)
									end

									if bWithBuff then
										local bFreeTarget = true
										if tCond.freeTarget then
											bFreeTarget = CAIHelper.tCondFunc["freeTarget"](self, oTmpUnit, tCond)
											condDetailLog(oUnit, nSKID, "freeTarget", bFreeTarget, nAllUnitCount, nUnitCount)
										end

										if bFreeTarget then
											nUnitCount = nUnitCount + 1
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	if nUnitCount <= 0 then
		return
	end

	if tCond.minUnits then
		condDetailLog(oUnit, nSKID, "minUnits", "check", nAllUnitCount, nUnitCount)
		if tCond.minUnits == 999 then
			if nUnitCount < nAllUnitCount then
				return
			end
		elseif nUnitCount < tCond.minUnits then
			return
		end
	end
	if tCond.maxUnits then
		condDetailLog(oUnit, nSKID, "maxUnits", "check", nAllUnitCount, nUnitCount)
		if nUnitCount > tCond.maxUnits then
			return
		end
	end
	return true
end

--条件判断
local function targetTypeCond(self, nSKID, oUnit, tCond)
	if not tCond or not next(tCond) then
		return true
	end
	if tCond.targetType == 0 then
		return targetTypeCond0(self, nSKID, oUnit, tCond)
	end
	if tCond.targetType == 1 or tCond.targetType == 2 then
		return targetTypeCond1(self, nSKID, oUnit, tCond)
	end
	return false
end

local function targetTypeCondAnd(self, nSKID, oUnit, tCond)
	if not next(tCond) then
		return true
	end

	local bCond1 = targetTypeCond(self, nSKID, oUnit, tCond)
	local bCond2 = targetTypeCond(self, nSKID, oUnit, tCond.andCond)
	return (bCond1 and bCond2)
end

local function targetTypeCondOr(self, nSKID, oUnit, tCond)
	if not next(tCond) then
		return true
	end

	local bCond1 = targetTypeCond(self, nSKID, oUnit, tCond)
	if bCond1 then
		return true
	end
	local bCond2 = targetTypeCond(self, nSKID, oUnit, tCond.orCond)
	return bCond2
end


--技能触发特殊条件函数
CAIHelper.fnSkillCond = {}

------选择目标函数
--@nTargetType 1己方;2敌方
--@eLifeState 1活目标;2死亡目标;3无论死活
function CAIHelper:GetUnitList(oUnit, nTargetType, eLifeState)
	assert(oUnit and nTargetType and eLifeState, "参数错误")
	assert(eLifeState == CSelectHelper.tLifeState.eAlive
		or eLifeState == CSelectHelper.tLifeState.eDead
		or eLifeState == CSelectHelper.tLifeState.eAny, "生命状态错误")

	local tTeamMap = {}
	if nTargetType == 1 then --己方
		tTeamMap = self.m_oBattle:GetTeam(oUnit:GetUnitID())
	elseif nTargetType == 2 then --敌方
		tTeamMap = self.m_oBattle:GetEnemyTeam(oUnit:GetUnitID())
	else
		assert(false)
	end

	local tUnitList = {}
	for _, oTmpUnit in pairs(tTeamMap) do
		if oUnit.m_oSelectHelper:CheckValidUnit(oUnit, oTmpUnit, eLifeState) then
			table.insert(tUnitList, oTmpUnit)
		end
	end
	return tUnitList
end
CAIHelper.fnSelectTargetFunc = {}
CAIHelper.fnSelectTargetFunc["schoolOrder"] = function(self, oUnit, tCond, tUnitList)
	local tResultList = tUnitList or self:GetUnitList(oUnit, tCond.targetType)
	table.sort(tResultList, function(u1, u2)
		local nPrio1 = tCond.schoolOrder[u1:GetSchool()] or 99
		local nPrio2 = tCond.schoolOrder[u2:GetSchool()] or 99
		return nPrio1 < nPrio2
	end)
	local tSameSchoolMap = {}
	for nIndex, oUnit in ipairs(tResultList) do
		tSameSchoolMap[oUnit:GetSchool()] = tSameSchoolMap[oUnit:GetSchool()] or {}
		table.insert(tSameSchoolMap[oUnit:GetSchool()], nIndex)
	end
	for nSchool, tIndexList in pairs(tSameSchoolMap) do
		if #tIndexList > 1 then
			for _, nIndex in ipairs(tIndexList) do
				local nTmpIndex = tIndexList[math.random(#tIndexList)]
				if nTmpIndex ~= nIndex then
					local oTmpUnit = tResultList[nIndex]
					tResultList[nIndex] = tResultList[nTmpIndex]
					tResultList[nTmpIndex] = oTmpUnit
				end
			end
		end
	end

	return tResultList
end
CAIHelper.fnSelectTargetFunc["objectTypeFirstOr"] = function(self, oUnit, tCond, tUnitList)
	local tResultList = tUnitList or self:GetUnitList(oUnit, tCond.targetType)
	table.sort(tResultList, function(u1, u2)
		local bFirst1 = table.InArray(u1:GetObjType(), tCond.objectTypeFirstOr)
		local bFirst2 = table.InArray(u2:GetObjType(), tCond.objectTypeFirstOr)
		if bFirst1 and bFirst2 then return u1:GetUnitID()<u2:GetUnitID() end
		if bFirst1 then return true end
		if bFirst2 then return false end
		return u1:GetUnitID()<u2:GetUnitID()
	end)
	return tResultList
end
CAIHelper.fnSelectTargetFunc["objectTypeFirstOr"] = function(self, oUnit, tCond, tUnitList)
	local tResultList = tUnitList or self:GetUnitList(oUnit, tCond.targetType)
	table.sort(tResultList, function(u1, u2)
		local nFirst1 = table.InArray(u1:GetObjType(), tCond.objectTypeFirstOr) and 1 or 0
		local nFirst2 = table.InArray(u2:GetObjType(), tCond.objectTypeFirstOr) and 1 or 0
		return nFirst1 > nFirst2
	end)
	return tResultList
end
CAIHelper.fnSelectTargetFunc["minHPFirstRatio"] = function(self, oUnit, tCond, tUnitList)
	local tResultList = tUnitList or self:GetUnitList(oUnit, tCond.targetType)
	if math.random(100) <= tCond.minHPFirstRatio then
		table.sort(tResultList, function(u1, u2) return u1:GetAttr(gtBAT.eQX)<u2:GetAttr(gtBAT.eQX) end)
	end
	return tResultList
end
CAIHelper.fnSelectTargetFunc["maxHPFirstRatio"] = function(self, oUnit, tCond, tUnitList)
	local tResultList = tUnitList or self:GetUnitList(oUnit, tCond.targetType)
	if math.random(100) <= tCond.maxHPFirstRatio then
		table.sort(tResultList, function(u1, u2) return u1:GetAttr(gtBAT.eQX)>u2:GetAttr(gtBAT.eQX) end)
	end
	return tResultList
end
CAIHelper.fnSelectTargetFunc["maxMPFirstRatio"] = function(self, oUnit, tCond, tUnitList)
	local tResultList = tUnitList or self:GetUnitList(oUnit, tCond.targetType)
	if math.random(100) <= tCond.maxMPFirstRatio then
		table.sort(tResultList, function(u1, u2) return u1:GetAttr(gtBAT.eMF)>u2:GetAttr(gtBAT.eMF) end)
	end
	return tResultList
end
CAIHelper.fnSelectTargetFunc["maxHP"] = function(self, oUnit, tCond)
	assert(tCond.targetType==1, "目标类型错误")
	local nCurrHP = oUnit:GetAttr(gtBAT.eQX)
	local nMaxHP = oUnit:MaxAttr(gtBAT.eQX)
	if nCurrHP <= nMaxHP*tCond.maxHP*0.01 then
		return true
	end
end
CAIHelper.fnSelectTargetFunc["withoutPasSkillAnd"] = function(self, oUnit, tCond)
	for _, nPasSkillID in ipairs(tCond.withoutPasSkillAnd) do
		if oUnit:GetPasSkill(nPasSkillID) then
			return
		end
	end
	return true
end
CAIHelper.fnSelectTargetFunc["dead"] = function(self, oUnit, tCond)
	return oUnit:IsDead()
end
CAIHelper.fnSelectTargetFunc["withoutBuffAnd"] = function(self, oUnit, tCond)
	for _, nBuffID in ipairs(tCond.withoutBuffAnd) do
		if oUnit:GetBuff(nBuffID) then return end
	end
	return true
end
CAIHelper.fnSelectTargetFunc["withoutBuffFirstAnd"] = function(self, oUnit, tCond, tUnitList)
	local tResultList = {}
	local tTmpList = tUnitList or self:GetUnitList(oUnit, tCond.targetType)

	local function fnWithoutBuff(oTmpUnit)
		for _, nBuffID in ipairs(tCond.withoutBuffFirstAnd) do
			if oTmpUnit:GetBuff(nBuffID) then return end
			return true
		end
	end
	for _, oTmpUnit in pairs(tTmpList) do
		if fnWithoutBuff(oTmpUnit) then
			table.insert(tResultList, 1, oTmpUnit)
		else
			table.insert(tResultList, oTmpUnit)
		end
	end
	return tResultList
end
CAIHelper.fnSelectTargetFunc["withBuffOr"] = function(self, oUnit, tCond)
	for _, nBuffID in ipairs(tCond.withBuffOr) do
		if oUnit:GetBuff(nBuffID) then
			return true
		end
	end
end
CAIHelper.fnSelectTargetFunc["minHPPerFirstRatio"] = function(self, oUnit, tCond, tUnitList)
	local tResultList = tUnitList or self:GetUnitList(oUnit, tCond.targetType)
	if math.random(100) <= tCond.minHPPerFirstRatio then
		table.sort(tResultList, function(u1, u2) return u1:HPRatio() < u2:HPRatio() end)
	end
	return tResultList
end
CAIHelper.fnSelectTargetFunc["withoutSkillTargetAnd"] = function(self, oUnit, tCond)
	local nUnitID = oUnit:GetUnitID()
	local tSrcTeamMap = self.m_oBattle:GetEnemyTeam(nUnitID)
	for nTmpUnitID, oTmpUnit in pairs(tSrcTeamMap) do
		local tInst = oTmpUnit:GetInst()
		if tInst.nInst == CUnit.tINST.eFS and table.InArray(tInst.nSkill, tCond.withoutSkillTargetAnd) and tInst.nTarUnit == nUnitID then
			return
		end
	end
	return true
end





function CAIHelper:Ctor(oBattle)
	self.m_oBattle = oBattle
end

--选择可用技能
function CAIHelper:AISelectSkill(oUnit, bWithoutCond)
	-- assert(not oUnit:IsDeadOrLeave(), "单位状态错误")
	local tAvailableSkillMap = self:SelectAvailableSkill(oUnit)
	if not tAvailableSkillMap or not next(tAvailableSkillMap) then
		return {}
	end
	local tSkillList = self:SkillCondCheck(oUnit, tAvailableSkillMap, bWithoutCond)
	--日志
	self.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), "AISelectSkill", tAvailableSkillMap, tSkillList)
	return tSkillList
end

--有效技能选择
function CAIHelper:SelectAvailableSkill(oUnit)
	local tAIConf = assert(ctAIConf[oUnit:GetAI()], "AI配置不存在:"..oUnit:GetAI())
	local tSkillMap = oUnit:GetActSkillMap()
	local tAvailableSkillMap = {}
	for nSkillID, tSkill in pairs(tSkillMap) do
		if tAIConf.tSkillMap[nSkillID] then
			tAvailableSkillMap[nSkillID] = tSkill
		end
	end
	return tAvailableSkillMap
end


function CAIHelper:CalcSingleCond(oUnit, nSkillID, tCond)
	local fnSkillCond = CAIHelper.fnSkillCond[nSkillID]
	if fnSkillCond then
		return fnSkillCond(self, nSkillID, oUnit)
	end
	if not tCond or not next(tCond) then
		return true
	end
	if tCond.andCond then
		return targetTypeCondAnd(self, nSkillID, oUnit, tCond)
	end
	if tCond.orCond then
		return targetTypeCondOr(self, nSkillID, oUnit, tCond)
	end
	return targetTypeCond(self, nSkillID, oUnit, tCond)
end

--技能条件筛选
function CAIHelper:SkillCondCheck(oUnit, tAvailableSkillMap, bWithoutCond)
	local nUnitID = oUnit:GetUnitID()
	local nUnitLevel = oUnit:GetLevel()

	--可以释放技能列表
	local tCanLuanchSkillList = {}
	for nSkillID, tSkill in pairs(tAvailableSkillMap) do
		local tAISkillConf = ctAISkillConf[nSkillID]
		if not tAISkillConf then

		else
			if not (oUnit:IsPartner() or oUnit:IsMonster()) and  nUnitLevel < tAISkillConf.nLevel then
				self.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), "SkillCondCheck level fail", nSkillID, nUnitLevel, tAISkillConf.nLevel)
			--等级限制
			elseif bWithoutCond or self:CalcSingleCond(oUnit, nSkillID, tAISkillConf.cCond) then
				self.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), "SkillCondCheck cond ok", nSkillID, tAISkillConf.cCond)
				if oUnit.m_oSkillHelper:CanLaunch(oUnit, nSkillID) then
					table.insert(tCanLuanchSkillList, nSkillID)
				end
			end
		end
	end
	return tCanLuanchSkillList
end

--技能目标条件检测
function CAIHelper:AISkillTargetCondCheck(oUnit, tCond, tUnitList, tTarList, nTarNum, oExeptUnit)
	if tCond.schoolOrder then	
		local fnTarget = CAIHelper.fnSelectTargetFunc["schoolOrder"]
		tUnitList = fnTarget(self, oUnit, tCond, tUnitList)
	end
	if tCond.objectTypeFirstOr then
		local fnTarget = CAIHelper.fnSelectTargetFunc["objectTypeFirstOr"]
		tUnitList = fnTarget(self, oUnit, tCond, tUnitList)
	end
	if tCond.minHPFirstRatio then
		local fnTarget = CAIHelper.fnSelectTargetFunc["minHPFirstRatio"]
		tUnitList = fnTarget(self, oUnit, tCond, tUnitList)
	end
	if tCond.minHPFirstRatio then
		local fnTarget = CAIHelper.fnSelectTargetFunc["minHPFirstRatio"]
		tUnitList = fnTarget(self, oUnit, tCond, tUnitList)
	end
	if tCond.withoutBuffFirstAnd then
		local fnTarget = CAIHelper.fnSelectTargetFunc["withoutBuffFirstAnd"]
		tUnitList = fnTarget(self, oUnit, tCond, tUnitList)
	end
	if tCond.minHPPerFirstRatio then
		local fnTarget = CAIHelper.fnSelectTargetFunc["minHPPerFirstRatio"]
		tUnitList = fnTarget(self, oUnit, tCond, tUnitList)
	end
	if tCond.maxHPFirstRatio then
		local fnTarget = CAIHelper.fnSelectTargetFunc["maxHPFirstRatio"]
		tUnitList = fnTarget(self, oUnit, tCond, tUnitList)
	end
	if tCond.maxMPFirstRatio then
		local fnTarget = CAIHelper.fnSelectTargetFunc["maxMPFirstRatio"]
		tUnitList = fnTarget(self, oUnit, tCond, tUnitList)
	end

	for _, oTmpUnit in ipairs(tUnitList) do
		if oTmpUnit ~= oExeptUnit then
			local maxHP = true
			if tCond.maxHP then
				maxHP = CAIHelper.fnSelectTargetFunc["maxHP"](self, oTmpUnit, tCond)
			end
			if maxHP then
				local withoutPasSkillAnd = true
				if tCond.withoutPasSkillAnd then
					withoutPasSkillAnd = CAIHelper.fnSelectTargetFunc["withoutPasSkillAnd"](self, oTmpUnit, tCond)
				end
				if withoutPasSkillAnd then
					local withoutBuffAnd = true
					if tCond.withoutBuffAnd then
						withoutBuffAnd = CAIHelper.fnSelectTargetFunc["withoutBuffAnd"](self, oTmpUnit, tCond)
					end
					if withoutBuffAnd then
						local withBuffOr = true
						if tCond.withBuffOr then
							withBuffOr = CAIHelper.fnSelectTargetFunc["withBuffOr"](self, oTmpUnit, tCond)
						end
						if withBuffOr then
							local withoutSkillTargetAnd = true
							if tCond.withoutSkillTargetAnd then
								withoutSkillTargetAnd = CAIHelper.fnSelectTargetFunc["withoutSkillTargetAnd"](self, oTmpUnit, tCond)
							end
							if withoutSkillTargetAnd then
								table.insert(tTarList, oTmpUnit)
								if #tTarList >= nTarNum then
									return tTarList
								end
							end
						end
					end
				end
			end
		end
	end
	return tTarList
end

--技能目标选择
function CAIHelper:AISkillTarget(oUnit, nSKID, nNum, sFrom, eLifeState)
	local tAISkillConf = assert(ctAISkillConf[nSKID], "AI技能配置不存在:"..nSKID)
	local tCond = tAISkillConf.cTarget

	local eLifeState = tCond.dead and CSelectHelper.tLifeState.eDead or eLifeState
	local nTargetType = tCond.targetType and tCond.targetType or 2

	local tTarList = {}
	local oInstUnit = oUnit.m_oSelectHelper:InstUnit(oUnit, eLifeState)
	if oInstUnit then
		table.insert(tTarList, oInstUnit)
	end
	if #tTarList >= nNum then
		return tTarList
	end

	local tUnitList = self:GetUnitList(oUnit, nTargetType, eLifeState)
	if not next(tCond) then
		while #tUnitList > 0 and #tTarList < nNum do
			local oTmpUnit = table.remove(tUnitList, math.random(#tUnitList))
			if oTmpUnit ~= oInstUnit then
				table.insert(tTarList, oTmpUnit)
			end
		end
		return tTarList
	end

	return self:AISkillTargetCondCheck(oUnit, tCond, tUnitList, tTarList, nNum, oInstUnit)
end

--执行AI
function CAIHelper:DoAI(oUnit)
	local tInst = oUnit:GetInst()

	local nAI = oUnit:GetAI()
	local tAIConf = assert(ctAIConf[nAI], "AI配置不存在:"..nAI)
	if nAI == 310 or nAI == 420 then --怪物/宠物AI
		if (tInst.nInst or 0) > 0 then
			return
		end
		local tAIInfo = self:MonsterAI(oUnit)
		return tAIInfo
	end
	if tAIConf.nBattleType == 1 then --练级AI
		if (tInst.nInst or 0) > 0 then
			return
		end
		return self:PVEAI(oUnit)
	end
	if tAIConf.nBattleType == 2 then --竞技AI
		if self.m_oBattle:GetBattleState() == CBattle.tBTS.eRP then
			return self:PVPAIPrepare(oUnit)
		elseif self.m_oBattle:GetBattleState() == CBattle.tBTS.eRS then
			return self:PVPAIBeforeAction(oUnit)
		else
			assert(false, "执行AI状态错误")
		end
	end
end

--怪物AI
function CAIHelper:MonsterAI(oUnit)
	local tSkillList = self:AISelectSkill(oUnit)
	if #tSkillList == 0 then
		return {nInst=CUnit.tINST.eGJ, nTarUnit=0}
	end
	--1.判断是否可以召唤子怪物
	local nCallSkillID
	local tCallSkillMap = _ctAISkillTypeMap[5]
	if tCallSkillMap then
		for nIndex, nSKID in ipairs(tSkillList) do
			if tCallSkillMap[nSKID] then
				nCallSkillID = nSKID
				table.remove(tSkillList, nIndex)
				break
			end
		end
	end
	if nCallSkillID then
		local bRes, sErr = oUnit:CanCallSubMonster()
		oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), "召唤子怪AI", bRes, sErr, oUnit:GetSubMonsterDeadLeaveRound(), oUnit:GetSubMonsterCalledTimes())
		if bRes then
			return {nInst=CUnit.tINST.eFS, nSkill=nCallSkillID, nTarUnit=0}
		end
	end

	--2.正常AI
	local tResult = CWeightRandom:Random(tSkillList, function(nSKID) return ctAISkillConf[nSKID].nWeight end, 1)
	if not tResult or #tResult == 0 then
		return {nInst=CUnit.tINST.eGJ, nTarUnit=0}
	end
	oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), "怪物AI-1 随机技能", tResult)
	local nSkillID = tResult[1]
	local tAISkillConf = assert(ctAISkillConf[nSkillID], "AI技能配置不存在:"..nSkillID)
	if not next(tAISkillConf.cTarget) then
		return {nInst=CUnit.tINST.eFS, nSkill=nSkillID, nTarUnit=0}
	end
	local tSkillConf = oUnit:GetSkillConf(nSkillID)
	local tTarUnitList = self:AISkillTarget(oUnit, nSkillID, 1, "怪物AI-2", tSkillConf.nLifeState)
	if #tTarUnitList == 0 then
		return {nInst=CUnit.tINST.eGJ, nTarUnit=0}
	end
	return {nInst=CUnit.tINST.eFS, nSkill=nSkillID, nTarUnit=tTarUnitList[1]:GetUnitID()}
end

--取复活类技能
function CAIHelper:GetReliveSkill(tSkillList)
	local tReliveSkillList = {}
	local tReliveSkillMap = _ctAISkillTypeMap[3] or {} --复活类技能
	for _, nSkillID in ipairs(tSkillList) do
		if tReliveSkillMap[nSkillID] then
			table.insert(tReliveSkillList, nSkillID)
		end
	end
	return tReliveSkillList
end

--取治疗类技能
function CAIHelper:GetCureSkill(tSkillList)
	local tCureSkillList = {}
	local tCureSkillMap = _ctAISkillTypeMap[2] or {} --治疗类技能
	for _, nSkillID in ipairs(tSkillList) do
		if tCureSkillMap[nSkillID] then
			table.insert(tCureSkillList, nSkillID)
		end
	end
	return tCureSkillList
end

--取单体类伤害技能
function CAIHelper:GetSingleAtkSkill(tSkillList)
	local tSingleSkillList = {}
	for _, nSkillID in ipairs(tSkillList) do
		local tSkillConf = ctSkillConf[nSkillID] or ctPetSkillConf[nSkillID]
		if (tSkillConf.nAtkType==gtSKAT.eDW or tSkillConf.nAtkType==gtSKAT.eDF) and (tSkillConf.nTarType==gtSKTT.eDFSJ or tSkillConf.nTarType==gtSKTT.eDFQX or tSkillConf.nTarType==gtSKTT.eDFCW) then
			table.insert(tSingleSkillList, nSkillID)
		end
	end
	return tSingleSkillList
end

--取初级群攻技能
function CAIHelper:GetGroupAtkSkill(tSkillList)
	local tGroupAtkSkillMap = _ctAISkillTypeMap[1] or {} --初级群攻
	local tGroupAtkSkillList = {}
	for _, nSkillID in ipairs(tSkillList) do
		if tGroupAtkSkillMap[nSkillID] then
			table.insert(tGroupAtkSkillList, nSkillID)
		end
	end
	return tGroupAtkSkillList
end

--练级AI
function CAIHelper:PVEAI(oUnit)
	local tSkillList = self:AISelectSkill(oUnit, true)
	if #tSkillList == 0 then
		return {nInst=CUnit.tINST.eGJ, nTarUnit=0}
	end

	--有不带鬼魅技能，没有病入膏肓buf的倒地单位, 则判断自身是否有复活类技能
	local tUnitList = self:GetUnitList(oUnit, 1, CSelectHelper.tLifeState.eDead)
	if #tUnitList > 0 then
		local tReliveSkillList = self:GetReliveSkill(tSkillList)
		if #tReliveSkillList > 0 then
			self.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), "PVEAI-1", tSkillList, tReliveSkillList)
			local tResult = CWeightRandom:Random(tReliveSkillList, function(nSKID) return ctAISkillConf[nSKID].nWeight end, 1)
			if tResult and #tResult == 1 then
				local tTarList = {}
				local tConf = ctAISkillConf[tResult[1]]
				tTarList = self:AISkillTargetCondCheck(oUnit, tConf.cTarget, tUnitList, tTarList, 1)
				if #tTarList > 0 then
					return {nInst=CUnit.tINST.eFS, nSkill=tResult[1], nTarUnit=tTarList[1]:GetUnitID()}
				end
			end
		end
	end

	--有我方非鬼魂（即宠物技能里不带不可治疗的鬼魂技能）单位生命值低于50%，则判断自身是否有治疗类技能(见下表)，如有则优先使用
	local tTarList = {}
	local tUnitList = self:GetUnitList(oUnit, 1, CSelectHelper.tLifeState.eAlive)
	for _, oTmpUnit in ipairs(tUnitList) do
		if CAIHelper.fnSelectTargetFunc["withoutPasSkillAnd"](self, oTmpUnit, {withoutPasSkillAnd={5107,5207}}) then
			if oTmpUnit:HPRatio() < 0.5 then
				table.insert(tTarList, oTmpUnit)
			end
		end
	end
	if #tTarList > 0 then
		local tCureSkillList = self:GetCureSkill(tSkillList)
		if #tCureSkillList > 0 then
			self.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), "PVEAI-2", tSkillList, tCureSkillList)
			local tResult = CWeightRandom:Random(tCureSkillList, function(nSKID) return ctAISkillConf[nSKID].nWeight end, 1)
			if tResult and #tResult == 1 then
				return {nInst=CUnit.tINST.eFS, nSkill=tResult[1], nTarUnit=tTarList[1]:GetUnitID()}
			end
		end
	end

	--如当前敌方目标仅存活1个单位，则判断自身是否有单体伤害类技能（见下表），如有该技能并满足释放条件，则优先使用
	local tUnitList = self:GetUnitList(oUnit, 2, CSelectHelper.tLifeState.eAlive)
	if #tUnitList == 1 then
		local tSingleAtkSkillList = self:GetSingleAtkSkill(tSkillList)
		if #tSingleAtkSkillList > 0 then
			self.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), "PVEAI-3", tSkillList, tSingleAtkSkillList)
			local tResult = CWeightRandom:Random(tSingleAtkSkillList, function(nSKID) return ctAISkillConf[nSKID].nWeight end, 1)
			if tResult and #tResult == 1 then
				return {nInst=CUnit.tINST.eFS, nSkill=tResult[1], nTarUnit=tUnitList[1]:GetUnitID()}
			end
		end
	end

	--如当前可使用最初级的群攻技能，则使用；如不能使用，则平砍
	local tGroupAtkSkillList = self:GetGroupAtkSkill(tSkillList)
	if #tGroupAtkSkillList > 0 then
		self.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), "PVEAI-4", tSkillList, tGroupAtkSkillList)
		local tResult = CWeightRandom:Random(tGroupAtkSkillList, function(nSKID) return ctAISkillConf[nSKID].nWeight end, 1)
		if tResult and #tResult == 1 then
			return {nInst=CUnit.tINST.eFS, nSkill=tResult[1], nTarUnit=0}
		end
	end
	return {nInst=CUnit.tINST.eGJ, nTarUnit=0}
end

--竞技AI
function CAIHelper:PVPAIPrepare(oUnit)
	--操纵的为玩家角色，当前无召唤兽存在，则召唤下一个宠物
	if oUnit:IsRole() then
		local oPetUnit = self.m_oBattle:GetSubUnit(oUnit:GetUnitID())
		if not oPetUnit then
			local nCallPetPosID = 0
			local tPetMap = oUnit:GetPetMap()
			for nPetPosID, tPet in pairs(tPetMap) do
				if not tPet.bUsed then
					nCallPetPosID = nPetPosID
					break
				end
			end
			if nCallPetPosID > 0 then
				return {nInst=CUnit.tINST.eZH, nPosID=nCallPetPosID}
			end
		end
	end
	local tSkillList = self:AISelectSkill(oUnit)

	--有单位处于被封印状态且尚未有己方单位对其使用解封技能，80%几率使用解封技能（技能ID：XXX）
	local tUnitList = self:GetUnitList(oUnit, 1, CSelectHelper.tLifeState.eAlive)
	local tTeamMap = self.m_oBattle:GetTeam(oUnit:GetUnitID())

	local tJFAvailableSkillList = {} --可用的解封技能列表
	local tJFSkillMap = _ctAISkillTypeMap[4] or {} --解封类技能
	for _, nSkillID in ipairs(tSkillList) do
		if tJFSkillMap[nSkillID] then
			table.insert(tJFAvailableSkillList, nSkillID)
		end
	end
	if #tJFAvailableSkillList > 0 then
		for _, oTmpUnit in ipairs(tUnitList) do
			if CAIHelper.fnSelectTargetFunc["withBuffOr"](self, oTmpUnit, {withBuffOr={121,124,125,126}}) then
				for _, oTmpUnit1 in pairs(tTeamMap) do
					local tInst = oTmpUnit1:GetInst()
					if tInst.nInst == CUnit.tINST.eFS and tJFSkillMap[tInst.nSkill] and tInst.nTarUnit == oTmpUnit:GetUnitID() then
					else
						local nRnd = math.random(100)
						if nRnd <= 80 then
							local tResult = CWeightRandom:Random(tJFAvailableSkillList, function(nSKID) return ctAISkillConf[nSKID].nWeight end, 1)
							if tResult and #tResult == 1 then
								return {nInst=CUnit.tINST.eFS, nSkill=tResult[1], nTarUnit=oTmpUnit:GetUnitID()}
							end
						end
					end
				end
			end
		end
	end

	--处于法术禁止状态，且门派属于鬼王，合欢，则使用平砍。其他门派使用防御
	if oUnit:IsLockAction(CUnit.tINST.eFS) then
		local nSchool = oUnit:GetSchool()
		if nSchool == gtSchoolType.eGW or nSchool == gtSchoolType.eHH then
			return {nInst=CUnit.tINST.eGJ, nTarUnit=0}
		else
			return {nInst=CUnit.tINST.eFY}
		end
	end

	return {nInst=CUnit.tINST.eGJ, nTarUnit=-1} --表示可以替换的指令(-1)
end

--竞技AI
function CAIHelper:PVPAIBeforeAction(oUnit)
	local tInst = oUnit:GetInst()
	if tInst.nTarUnit ~= -1 then --已经下达过优先级指令
		return 
	end
	
	--非鬼王门派且MP=0，使用平砍
	--HP≤10%（仅鬼王）,平砍
	local nSchool = oUnit:GetSchool()	
	if nSchool ~= gtSchoolType.eGW then
		if oUnit:GetAttr(gtBAT.eMF) == 0 then
			return {nInst=CUnit.tINST.eGJ, nTarUnit=0}
		end
	elseif nSchool == gtSchoolType.eGW then
		if oUnit:HPRatio()*100 <= 10 then
			return {nInst=CUnit.tINST.eGJ, nTarUnit=0}
		end
	end
	local tSkillList = self:AISelectSkill(oUnit)

	--筛选复活非复活技能
	local tNotReliveSkillList, tReliveSkillList = {}, {}
	local tReliveSkillMap = _ctAISkillTypeMap[3] or {} --复活类技能
	for _, nSkillID in ipairs(tSkillList) do
		if tReliveSkillMap[nSkillID] then
			table.insert(tReliveSkillList, nSkillID)
		else
			table.insert(tNotReliveSkillList, nSkillID)
		end
	end
	tSkillList = tNotReliveSkillList

	--存在倒地且不带鬼魂（宠物技能）或高级鬼魂（宠物技能）的己方单位，则80%概率使用复活类技能
	local tUnitList = self:GetUnitList(oUnit, 1, CSelectHelper.tLifeState.eDead)
	if #tUnitList > 0  then
		if #tReliveSkillList > 0 then
			if math.random(100) <= 80 then
				local tConf = ctAISkillConf[tReliveSkillList[1]]
				local tTarList = self:AISkillTargetCondCheck(oUnit, tConf.cTarget, tUnitList, {}, 1)
				if #tTarList > 0 then
					local tResult = CWeightRandom:Random(tReliveSkillList, function(nSKID) return ctAISkillConf[nSKID].nWeight end, 1)
					if tResult and #tResult == 1 then
						return {nInst=CUnit.tINST.eFS, nSkill=tResult[1], nTarUnit=tTarList[1]:GetUnitID()}
					end
				end
			end
		end
	end

	--随机选一个技能
	if #tSkillList > 0 then
		local tCanLaunchSkillList = {}
		for _, nSKID in ipairs(tSkillList) do
			if oUnit.m_oSkillHelper:CanLaunch(oUnit, nSKID) then
				table.insert(tCanLaunchSkillList, nSKID)
			end
		end
		self.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), "PVPAI-24", tCanLaunchSkillList)

		local tResult = CWeightRandom:Random(tCanLaunchSkillList, function(nSKID) return ctAISkillConf[nSKID].nWeight end, 1)
		if not tResult or #tResult == 0 then
			return {nInst=CUnit.tINST.eGJ, nTarUnit=0}
		end
		local nSkillID = tResult[1]
		local tSkillConf = oUnit:GetSkillConf(nSkillID)
		local tTarUnitList = self:AISkillTarget(oUnit, nSkillID, 1, "PVPAI", tSkillConf.nLifeState)
		if #tTarUnitList == 0 then
			return {nInst=CUnit.tINST.eFS, nSkill=nSkillID, nTarUnit=0}
		end
		return {nInst=CUnit.tINST.eFS, nSkill=nSkillID, nTarUnit=tTarUnitList[1]:GetUnitID()}
	end
	return {nInst=CUnit.tINST.eGJ, nTarUnit=0}
end