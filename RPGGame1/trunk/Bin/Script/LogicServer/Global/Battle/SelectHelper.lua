--技能辅助类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--生命状态
CSelectHelper.tLifeState = 
{
	eAlive = 1, --活的
	eDead = 2, 	--死的
	eAny = 3, 	--任何
}

--构造函数
function CSelectHelper:Ctor()
end

--生命状态是否符合
function CSelectHelper:CheckLifeState(oUnit, eLifeState)
	if oUnit:IsLeave() then
		return
	end
	if eLifeState == CSelectHelper.tLifeState.eAlive then
		return (not oUnit:IsDead())
	end

	if eLifeState == CSelectHelper.tLifeState.eDead then
		return oUnit:IsDead()
	end

	if eLifeState == CSelectHelper.tLifeState.eAny then
		return true
	end
	assert(false, "生命状态参数错误:"..eLifeState)
end

--目标是否有效
function CSelectHelper:CheckValidUnit(oSrcUnit, oTarUnit, eLifeState)
	if not oTarUnit then
		return false, "目标不存在"
	end
	if oTarUnit:IsLeave() then
		return false, "目标已离开"
	end
	if not oSrcUnit:HideAtkCheck(oTarUnit) then
		return false, "目标已隐身"
	end
	if not self:CheckLifeState(oTarUnit, eLifeState) then
		return false, "目标生命状态错误"
	end
	return true
end

--取指令指定目标
function CSelectHelper:InstUnit(oUnit, eLifeState)
	local oBattle = oUnit.m_oBattle
	local nInstUnit = oUnit:GetInst().nTarUnit or 0
	local oInstUnit = oBattle:GetUnit(nInstUnit)
	if not oInstUnit then
		return
	end
	local bRes, sErr = self:CheckValidUnit(oUnit, oInstUnit, eLifeState)
	if not bRes then
		return oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), sErr, oUnit:GetInst())
	end
	return oInstUnit
end

--随机任何人
function CSelectHelper:RandAny(oUnit)
	local tAtkMap = oUnit.m_oBattle:GetAtkTeam()
	local tDefMap = oUnit.m_oBattle:GetDefTeam()

	local tUnitList = {}
	for _, oTmpUnit in pairs(tAtkMap) do
		if oTmpUnit ~= oUnit and self:CheckValidUnit(oUnit, oTmpUnit, CSelectHelper.tLifeState.eAlive) then
			table.insert(tUnitList, oTmpUnit)
		end
	end
	for _, oTmpUnit in pairs(tDefMap) do
		if oTmpUnit ~= oUnit and self:CheckValidUnit(oUnit, oTmpUnit, CSelectHelper.tLifeState.eAlive) then
			table.insert(tUnitList, oTmpUnit)
		end
	end
	if #tUnitList <= 0 then
		return
	end
	return tUnitList[math.random(#tUnitList)]
end

--敌方随机(活的)
function CSelectHelper:RandEnemys(oUnit, nNum, sFrom)
	local tTarList = {}

	--指令指定的目标
	local nInstUnit = 0
	local oInstUnit = self:InstUnit(oUnit, CSelectHelper.tLifeState.eAlive)
	if oInstUnit and not oInstUnit:IsSameTeam(oUnit:GetUnitID()) then
		nInstUnit = oInstUnit:GetUnitID()
		table.insert(tTarList, oInstUnit)
	end
	if #tTarList == nNum then
		return tTarList
	end

	--随机剩下的目标
	local tUnitList = {}
	local oBattle = oUnit.m_oBattle
	local tUnitMap = oBattle:GetEnemyTeam(oUnit:GetUnitID())	
	for nTmpUnit, oTmpUnit in pairs(tUnitMap) do
		if nInstUnit ~= nTmpUnit and self:CheckValidUnit(oUnit, oTmpUnit, CSelectHelper.tLifeState.eAlive) then
			table.insert(tUnitList, oTmpUnit)
		end
	end

	while #tUnitList > 0 and #tTarList < nNum do
		local nIndex = math.random(#tUnitList)
		table.insert(tTarList, table.remove(tUnitList, nIndex))
	end

	if #tTarList == 0 then
		oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), sFrom or "", "选择目标失败")
	end
	return tTarList
end

--己方随机
function CSelectHelper:RandFriends(oUnit, nNum, sFrom, eLifeState)
	local tTarList = {}

	--指令指定的目标
	local nInstUnit = 0
	local oInstUnit = self:InstUnit(oUnit, eLifeState)
	if oInstUnit and oInstUnit:IsSameTeam(oUnit:GetUnitID()) then
		nInstUnit = oInstUnit:GetUnitID()
		table.insert(tTarList, oInstUnit)
	end
	if #tTarList == nNum then
		return tTarList
	end

	--随机剩下的目标
	local tUnitList = {}
	local oBattle = oUnit.m_oBattle
	local tUnitMap = oBattle:GetTeam(oUnit:GetUnitID())	
	for nTmpUnit, oTmpUnit in pairs(tUnitMap) do
		if nInstUnit ~= nTmpUnit and self:CheckValidUnit(oUnit, oTmpUnit, eLifeState) then
			table.insert(tUnitList, oTmpUnit)
		end
	end

	while #tUnitList > 0 and #tTarList < nNum do
		local nIndex = math.random(#tUnitList)
		table.insert(tTarList, table.remove(tUnitList, nIndex))
	end

	if #tTarList == 0 then
		oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), sFrom or "", "选择目标失败")
	end
	return tTarList
end

--己方血量最少
function CSelectHelper:MinHPFriends(oUnit, nNum, sFrom, eLifeState)
	local tTarList = {}

	--指令指定的目标
	local nInstUnit = 0
	local oInstUnit = self:InstUnit(oUnit, eLifeState)
	if oInstUnit and oInstUnit:IsSameTeam(oUnit:GetUnitID()) then
		nInstUnit = oInstUnit:GetUnitID()
		table.insert(tTarList, oInstUnit)
	end
	if #tTarList == nNum then
		return tTarList
	end

	--按血量大小取剩下的
	local tUnitList = {}
	local oBattle = oUnit.m_oBattle
	local tUnitMap = oBattle:GetTeam(oUnit:GetUnitID())	
	for nTmpUnit, oTmpUnit in pairs(tUnitMap) do
		if nInstUnit ~= nTmpUnit and self:CheckValidUnit(oUnit, oTmpUnit, eLifeState) then
			table.insert(tUnitList, oTmpUnit)
		end
	end

	table.sort(tUnitList, function(u1, u2) return u1:GetAttr(gtBAT.eQX) > u2:GetAttr(gtBAT.eQX) end)
	while #tUnitList > 0 and #tTarList < nNum do
		table.insert(tTarList, table.remove(tUnitList))
	end

	if #tTarList == 0 then
		oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), sFrom or "", "选择目标失败")
	end

	return tTarList
end

--敌方血量最少(活的)
function CSelectHelper:MinHPEnemys(oUnit, nNum, sFrom)
	local tTarList = {}

	--指令指定的目标
	local nInstUnit = 0
	local oInstUnit = self:InstUnit(oUnit, CSelectHelper.tLifeState.eAlive)
	if oInstUnit and not oInstUnit:IsSameTeam(oUnit:GetUnitID()) then
		nInstUnit = oInstUnit:GetUnitID()
		table.insert(tTarList, oInstUnit)
	end
	if #tTarList == nNum then
		return tTarList
	end

	--按血量大小取剩下的
	local tUnitList = {}
	local oBattle = oUnit.m_oBattle
	local tUnitMap = oBattle:GetEnemyTeam(oUnit:GetUnitID())	
	for nTmpUnit, oTmpUnit in pairs(tUnitMap) do
		if nInstUnit ~= nTmpUnit and self:CheckValidUnit(oUnit, oTmpUnit, CSelectHelper.tLifeState.eAlive) then
			table.insert(tUnitList, oTmpUnit)
		end
	end

	table.sort(tUnitList, function(u1, u2) return u1:GetAttr(gtBAT.eQX) > u2:GetAttr(gtBAT.eQX) end)
	while #tUnitList > 0 and #tTarList < nNum do
		table.insert(tTarList, table.remove(tUnitList))
	end

	if #tTarList == 0 then
		oUnit:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), (sFrom or ""), "选择目标失败")
	end

	return tTarList
end

--选择死亡的队友
function CSelectHelper:DeadFriends(oUnit, nNum, sFrom)
	local tTarList = {}

	--指令指定的目标
	local nInstUnit = 0
	local oInstUnit = self:InstUnit(oUnit, CSelectHelper.tLifeState.eDead)
	if oInstUnit and oInstUnit:IsSameTeam(oUnit:GetUnitID()) then
		nInstUnit = oInstUnit:GetUnitID()
		table.insert(tTarList, oInstUnit)
	end
	if #tTarList == nNum then
		return tTarList
	end

	--取剩下的
	local tUnitList = {}
	local oBattle = oUnit.m_oBattle
	local tUnitMap = oBattle:GetTeam(oUnit:GetUnitID())	
	for nTmpUnit, oTmpUnit in pairs(tUnitMap) do
		if nInstUnit ~= nTmpUnit and self:CheckValidUnit(oUnit, oTmpUnit, CSelectHelper.tLifeState.eDead) then
			table.insert(tUnitList, oTmpUnit)
		end
	end

	while #tUnitList > 0 and #tTarList < nNum do
		table.insert(tTarList, table.remove(tUnitList))
	end

	if #tTarList == 0 then
		oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), sFrom or "", "选择目标失败")
	end
	return tTarList
end

--全部敌方目标
function CSelectHelper:AllEnemeys(oUnit, sFrom, eLifeState)
	local tTarList = {}
	local oBattle = oUnit.m_oBattle
	local tUnitMap = oBattle:GetEnemyTeam(oUnit:GetUnitID())	
	for _, oTmpUnit in pairs(tUnitMap) do
		if self:CheckValidUnit(oUnit, oTmpUnit, eLifeState) then
			table.insert(tTarList, oTmpUnit)
		end
	end
	
	if #tTarList == 0 then
		oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), sFrom or "", "选择目标失败")
	end
	return tTarList
end

--全部己方目标
function CSelectHelper:AllFriends(oUnit, sFrom, eLifeState)
	local tTarList = {}
	local oBattle = oUnit.m_oBattle
	local tUnitMap = oBattle:GetTeam(oUnit:GetUnitID())	
	for _, oTmpUnit in pairs(tUnitMap) do
		if self:CheckValidUnit(oUnit, oTmpUnit, eLifeState) then
			table.insert(tTarList, oTmpUnit)
		end
	end
	
	if #tTarList == 0 then
		oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), sFrom or "", "选择目标失败")
	end
	return tTarList
end

--己方宠物
function CSelectHelper:FriendPets(oUnit, nNum, sFrom, eLifeState)
	local tTarList = {}

	--指令指定的目标
	local nInstUnit = 0
	local oInstUnit = self:InstUnit(oUnit, eLifeState)
	if oInstUnit and oInstUnit:IsPet() and oInstUnit:IsSameTeam(oUnit:GetUnitID()) then
		nInstUnit = oInstUnit:GetUnitID()
		table.insert(tTarList, oInstUnit)
	end
	if #tTarList == nNum then
		return tTarList
	end

	--取剩下的
	local tUnitList = {}
	local oBattle = oUnit.m_oBattle
	local tUnitMap = oBattle:GetTeam(oUnit:GetUnitID())	
	for nTmpUnit, oTmpUnit in pairs(tUnitMap) do
		if nTmpUnit ~= nInstUnit and oTmpUnit:IsPet() and self:CheckValidUnit(oUnit, oTmpUnit, eLifeState) then
			table.insert(tUnitList, oTmpUnit)
		end
	end

	while #tUnitList > 0 and #tTarList < nNum do
		table.insert(tTarList, table.remove(tUnitList))
	end

	if #tTarList == 0 then
		oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), sFrom or "", "选择目标失败")
	end
	return tTarList
end

--敌方宠物
function CSelectHelper:EnemyPets(oUnit, nNum, sFrom, eLifeState)
	local tTarList = {}

	--指令指定的目标
	local nInstUnit = 0
	local oInstUnit = self:InstUnit(oUnit, eLifeState)
	if oInstUnit and oInstUnit:IsPet() and not oInstUnit:IsSameTeam(oUnit:GetUnitID()) then
		nInstUnit = oInstUnit:GetUnitID()
		table.insert(tTarList, oInstUnit)
	end
	if #tTarList == nNum then
		return tTarList
	end

	--取剩下的
	local tUnitList = {}
	local oBattle = oUnit.m_oBattle
	local tUnitMap = oBattle:GetEnemyTeam(oUnit:GetUnitID())	
	for nTmpUnit, oTmpUnit in pairs(tUnitMap) do
		if nTmpUnit ~= nInstUnit and oTmpUnit:IsPet() and self:CheckValidUnit(oUnit, oTmpUnit, eLifeState) then
			table.insert(tUnitList, oTmpUnit)
		end
	end

	while #tUnitList > 0 and #tTarList < nNum do
		table.insert(tTarList, table.remove(tUnitList))
	end

	if #tTarList == 0 then
		oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), sFrom or "", "选择目标失败")
	end
	return tTarList
end

--根据技能合适目标(包括普攻1,防御2)
function CSelectHelper:SkillTarget(oUnit, nSKID, nNum, sFrom)
	if nSKID == 1 then --普攻
		return self:RandEnemys(oUnit, nNum, sFrom, CSelectHelper.tLifeState.eAlive)
	end
	if nSKID == 2 then --防御
		return {oUnit}
	end

	local tConf = oUnit:GetSkillConf(nSKID)
	local eLifeState = tConf.nLifeState and tConf.nLifeState or CSelectHelper.tLifeState.eAlive

	------通过AI选着目标
	if oUnit:GetAI() > 0 then
		local tAISkillConf = ctAISkillConf[nSKID]
		if tAISkillConf and next(tAISkillConf.cTarget) then
			return oUnit.m_oAIHelper:AISkillTarget(oUnit, nSKID, nNum, "AI技能选择目标", eLifeState)
		end
	end

	------正常目标选择
	--自己
	if tConf.nTarType == gtSKTT.eZJ then
		if eLifeState == CSelectHelper.tLifeState.eAlive then
			if not oUnit:IsDeadOrLeave() then
				return {oUnit}
			end
			oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), "自己已死亡,选择失败", oUnit:GetInst())
			return
		end
		if eLifeState == CSelectHelper.tLifeState.eDead then
			if oUnit:IsDead() and not oUnit:IsLeave() then
				return {oUnit}
			end
			oUnit.m_oBattle:WriteLog(oUnit:GetUnitID(), oUnit:GetObjName(), "自己未死亡,选择失败", oUnit:GetInst())
			return
		end
		return {oUnit}
	end

	--己方随机
	if tConf.nTarType == gtSKTT.eJFSJ then
		return self:RandFriends(oUnit, nNum, sFrom, eLifeState)
	end
	--敌方随机
	if tConf.nTarType == gtSKTT.eDFSJ then
		return self:RandEnemys(oUnit, nNum, sFrom, eLifeState)
	end
	--己方死亡
	if tConf.nTarType == gtSKTT.eJFSW then
		assert(eLifeState == CSelectHelper.tLifeState.eDead, "生命状态错误")
		return self:DeadFriends(oUnit, nNum, sFrom, eLifeState)
	end
	--敌方气血升序
	if tConf.nTarType == gtSKTT.eDFQX then
		return self:MinHPEnemys(oUnit, nNum, sFrom, eLifeState)
	end
	--己方气血升序
	if tConf.nTarType == gtSKTT.eJFQX then
		return self:MinHPFriends(oUnit, nNum, sFrom, eLifeState)
	end
	--己方宠物
	if tConf.nTarType == gtSKTT.eJFCW then
		return self:FriendPets(oUnit, nNum, sFrom, eLifeState)
	end
	--敌方宠物
	if tConf.nTarType == gtSKTT.eDFCW then
		return self:EnemyPets(oUnit, nNum, sFrom, eLifeState)
	end
	assert(false, "目标类型未定义")
end

--检测技能目标是否正确(包括普攻1,防御2)
function CSelectHelper:CheckSkillTarget(oUnit, nSKID, nTarUnit)
	if nTarUnit == 0 then --自动时没有设置目标
		return true
	end

	if nSKID == 1 then --普攻(策划说己方和敌方都可以打)
		return true
	end

	local tConf = oUnit:GetSkillConf(nSKID)
	
	local nTarType = 0
	if nSKID == 2 then --防御
		nTarType = gtSKTT.eZJ
	else --技能
		nTarType = tConf.nTarType
	end

	local tJF = {gtSKTT.eJFSJ, gtSKTT.eJFSW, gtSKTT.eJFQX, gtSKTT.eJFCW} --己方
	local tDF = {gtSKTT.eDFSJ, gtSKTT.eDFQX, gtSKTT.eDFCW} --敌方

	--自己
	if nTarType == gtSKTT.eZJ then
		return (oUnit:GetUnitID() == nTarUnit)
	end

	--己方
	if table.InArray(nTarType, tJF) then
		return oUnit:IsSameTeam(nTarUnit)
	end

	--敌方
	if table.InArray(nTarType, tDF) then
		return (not oUnit:IsSameTeam(nTarUnit))
	end
	
	assert(false, "目标类型未定义:"..nTarType)
end
