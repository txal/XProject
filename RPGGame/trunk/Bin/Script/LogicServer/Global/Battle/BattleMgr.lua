--战斗管理模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--定时清理无效战斗
local nClearInterval = 5*60

function CBattleMgr:Ctor()
	self.m_nAutoID = 0
	self.m_tBattleMap = {}
	self.m_nClearTimer = goTimerMgr:Interval(nClearInterval, function() self:ClearBattle() end)

	self.m_fnAddAttr = {}
	self:RegisterAddAttrFun()

	self.m_bBattleLog = io.FileExist("../linux.txt") or io.FileExist("debug.txt")
end

function CBattleMgr:IsBattleLog()
	return self.m_bBattleLog
end

--释放
function CBattleMgr:OnRelease()
	goTimerMgr:Clear(self.m_nClearTimer)
	self.m_nClearTimer = nil
end

--清理无效战斗
function CBattleMgr:ClearBattle()
	local nCount = 0
	for nID, oBattle in pairs(self.m_tBattleMap) do
		if not (oBattle.m_nReadyTimer or oBattle.m_nRoundTimer) then
			oBattle:OnRelease(true)
			self.m_tBattleMap[nID] = nil
		else
			nCount = nCount + 1
		end
	end
	LuaTrace("有效战斗数:", nCount)
end

--生成战斗ID
function CBattleMgr:GenID()
	local nServiceID = GF.GetServiceID()
	local nUnixMSTime = GF.GetUnixMSTime()
	local nBattleID = tonumber(nServiceID..nUnixMSTime)
	for k = 0, 1000 do
		nBattleID = nBattleID + k
		if not self.m_tBattleMap[nBattleID] then
			break
		end
	end
	assert(not self.m_tBattleMap[nBattleID], "战斗ID冲突")
	return nBattleID
end

--取战斗对象
function CBattleMgr:GetBattle(nID)
	return self.m_tBattleMap[nID]
end

--移除战斗
function CBattleMgr:RemoveBattle(nID, bForce)
	local oBattle = self.m_tBattleMap[nID]
	if oBattle then
		oBattle:OnRelease(bForce)
		self.m_tBattleMap[nID] = nil
	end
end

function CBattleMgr:GMRemoveBattle(nID, nRoleID) 
	local oBattle = self.m_tBattleMap[nID]
	if oBattle then
		oBattle:GMRemove(nRoleID)
	end
end

--PVE取队伍类型等级
function CBattleMgr:GetPVETeamLv(nType, tRoleBTData)
	print("CBattleMgr:GetPVETeamLv***", nType)
	-- 1：玩家队伍所有成员的平均等级
	-- 2：玩家队伍所有成员的最高等级
	-- 3：玩家队伍所有成员的最低等级
	-- 4：玩家队伍中队长的等级
	-- 5：玩家队伍中等级最高的前三名的平均等级
	if nType == 1 then
		local nTotalLevel, nCount = 0, 0
		for nUnit, tBTData in pairs(tRoleBTData.tUnitMap) do
			if tBTData.nObjType == gtObjType.eRole then
				nTotalLevel = nTotalLevel + tBTData.nLevel
				nCount = nCount + 1
			end
		end
		return math.floor(nTotalLevel/nCount)
	end
	if nType == 2 then
		local nMaxLevel = 0
		for nUnit, tBTData in pairs(tRoleBTData.tUnitMap) do
			if tBTData.nObjType == gtObjType.eRole then
				if tBTData.nLevel > nMaxLevel then
					nMaxLevel = tBTData.nLevel
				end
			end
		end
		return nMaxLevel
	end
	if nType == 3 then
		local nMinLevel = 0
		for nUnit, tBTData in pairs(tRoleBTData.tUnitMap) do
			if tBTData.nObjType == gtObjType.eRole then
				if nMinLevel == 0 or tBTData.nLevel < nMinLevel then
					nMinLevel = tBTData.nLevel
				end
			end
		end
		return nMinLevel
	end
	if nType == 4 then
		return tRoleBTData.tUnitMap[101].nLevel
	end
	if nType == 5 then
		local tLvList = {}
		for nUnit, tBTData in pairs(tRoleBTData.tUnitMap) do
			if tBTData.nObjType == gtObjType.eRole then
				table.insert(tLvList, tBTData.nLevel)
			end
		end
		table.sort(tLvList, function(v1, v2) return v1>v2 end)
		local nTotalLevel = 0
		for k = 1, 3 do
			nTotalLevel = nTotalLevel + (tLvList[k] or 0)
		end
		return math.floor(nTotalLevel/math.min(3,#tLvList))
	end
	assert(false)
end

--取队伍人数
function CBattleMgr:GetTeamMembers(tRoleBTData)
	local nTeamMembers = 0
	for nUnit, tBTData in pairs(tRoleBTData.tUnitMap) do
		if tBTData.nObjType == gtObjType.eRole then
			nTeamMembers = nTeamMembers + 1
		end
	end
	return nTeamMembers
end

--计算阵法加成
function CBattleMgr:CalcUnitFmtAttr(oBattle, nUnitID, tUnitData)
	local tFmtData = oBattle:GetFmtData()
	
	local nAtkFmtID = tFmtData.nAtkFmtID
	local nAtkFmtLv = tFmtData.nAtkFmtLv
	local tAtkFmtAttr = tFmtData.tAtkFmtAttr
	local nDefFmtID = tFmtData.nDefFmtID
	local nDefFmtLv = tFmtData.nDefFmtLv
	local tDefFmtAttr = tFmtData.tDefFmtAttr
	local nTeamFlag = oBattle:TeamFlag(nUnitID) 
	local nUnitPos = nUnitID-nTeamFlag*100

	local tFmtAttr
	local tResFmtConf
	local nResFmtID
	if nTeamFlag == 1 then --攻方
		tFmtAttr = tAtkFmtAttr 
		nResFmtID = nAtkFmtID --被克制阵法
		tResFmtConf = ctFormationConf[nDefFmtID] --克制方配置
	else --守方
		tFmtAttr = tDefFmtAttr
		nResFmtID = nDefFmtID --被克制阵法
		tResFmtConf = ctFormationConf[nAtkFmtID] --克制方配置
	end
	--阵法加成
	if tFmtAttr[nUnitPos] then
		for nAttrID, nAttrVal in pairs(tFmtAttr[nUnitPos]) do
			local nOldVal = tUnitData.tBattleAttr[nAttrID] 
			--百分比类属性直接加法
			if gtRatioAttr[nAttrID] then
				if nAttrID == gtBAT.eSH then
					tUnitData.tBattleAttr[gtBAT.eWLSH] = tUnitData.tBattleAttr[gtBAT.eWLSH] + nAttrVal
					tUnitData.tBattleAttr[gtBAT.eFSSH] = tUnitData.tBattleAttr[gtBAT.eFSSH] + nAttrVal

				elseif nAttrID == gtBAT.eSS then
					tUnitData.tBattleAttr[gtBAT.eWLSS] = tUnitData.tBattleAttr[gtBAT.eWLSS] + nAttrVal
					tUnitData.tBattleAttr[gtBAT.eFSSS] = tUnitData.tBattleAttr[gtBAT.eFSSS] + nAttrVal

				else
					tUnitData.tBattleAttr[nAttrID] = tUnitData.tBattleAttr[nAttrID] + nAttrVal
				end
			--其他属性计算值
			else
				tUnitData.tBattleAttr[nAttrID] =  math.floor(tUnitData.tBattleAttr[nAttrID]*(100+nAttrVal)*0.01)
			end
			oBattle:WriteLog("阵法加成", nUnitID, tUnitData.sObjName, tFmtAttr[nUnitPos], nOldVal, tUnitData.tBattleAttr[nAttrID])
		end
	end
	--阵法克制
	for _, tRes in ipairs(tResFmtConf.tRestrain) do
		if tRes[1] >= 0 and tRes[1] == nResFmtID then
			local nOldSS = tUnitData.tBattleAttr[gtBAT.eWLSS]
			local nOldFSSS = tUnitData.tBattleAttr[gtBAT.eFSSS]
			--降低是负数,增加是正数
			tUnitData.tBattleAttr[gtBAT.eWLSS] = tUnitData.tBattleAttr[gtBAT.eWLSS] + tRes[2]
			tUnitData.tBattleAttr[gtBAT.eFSSS] = tUnitData.tBattleAttr[gtBAT.eFSSS] + tRes[2]
			oBattle:WriteLog("阵法被克制", nUnitID, tUnitData.sObjName, tRes, nOldSS, nOldFSSS, tUnitData.tBattleAttr[gtBAT.eWLSS], tUnitData.tBattleAttr[gtBAT.eFSSS])
		end
	end
end

--计算队伍阵法属性加成和相克
function CBattleMgr:CalcFormationAttr(oBattle, tAtkBTData, tDefBTData)
	local tFmtData = oBattle:GetFmtData()
	oBattle:WriteLog("阵法信息", tFmtData)
	for nUnitID, tBTData in pairs(tAtkBTData.tUnitMap) do
		self:CalcUnitFmtAttr(oBattle, nUnitID, tBTData)
	end
	for nUnitID, tBTData in pairs(tDefBTData.tUnitMap) do
		self:CalcUnitFmtAttr(oBattle, nUnitID, tBTData)
	end
end

--PVE战斗
--@tExtData 额外数据,原样返回
function CBattleMgr:PVEBattle(oRole, tRoleBTData, oMonster, tExtData)
	if oRole:IsInBattle() then
		return
	end
	local nID = self:GenID()

	--怪物战斗数据
	local nLevel = 0
	local tBTGConf = oMonster:GetBattleGroupConf()
	if tBTGConf.nMonLvType == 0 then
		nLevel = tBTGConf.nMonLvVal
	else
		nLevel = self:GetPVETeamLv(tBTGConf.nMonLvType, tRoleBTData)
	end
	local nTeamMembers = self:GetTeamMembers(tRoleBTData)
	local tMonBTData = oMonster:GetBattleData(nLevel, nTeamMembers)

	--其他模块属性加成百分比
	local tOtherAttrAddRatio = self:CalcOtherAttrAddRatio(oRole, tExtData)

	--战斗信息
	local tBattleInfo = {
		sMusic = tBTGConf.sMusic,	
		nTeamID1 = tRoleBTData.nTeamID,
		nTeamID2 = 0,
		nLeaderID1 = oRole:GetID(),
		nLeaderID2 = oMonster:GetID(),
		sLeaderName1 = oRole:GetName(),
		sLeaderName2 = oMonster:GetName(),
		nFmtID1 = tRoleBTData.nFmtID,
		nFmtLv1 = tRoleBTData.nFmtLv,
		tFmtAttr1 = tRoleBTData.tFmtAttrAdd,
		nFmtID2 = tMonBTData.nFmtID,
		nFmtLv2 = tMonBTData.nFmtLv,
		tFmtAttr2 = tMonBTData.tFmtAttrAdd,
		tExtData = tExtData,
		nBattleGroup = tBTGConf.nID,
		tLeaderData1 = tRoleBTData.tUnitMap[101],
		tLeaderData2 = tMonBTData.tUnitMap[201],
		tOtherAttrAddRatio = tOtherAttrAddRatio,
	}

	--战斗对象
	local oBattle = CBattle:new(nID, gtBTT.ePVE, tBattleInfo)
	--其他模块加成怪物属性(基础属性上加)
	self:CalcOtherAttrAdd(oBattle, tMonBTData)
	--处理阵法加成
	self:CalcFormationAttr(oBattle, tRoleBTData, tMonBTData)

	--玩家
	local tRoleList = {}
	for nUnitID, tBTData in pairs(tRoleBTData.tUnitMap) do
		oBattle:WriteLog("角色单位数据", nUnitID, tBTData)
		local oUnit = CUnit:new(oBattle, nUnitID, tBTData)
		oBattle:AddUnit(nUnitID, oUnit)

		if oUnit:IsRole() and not oUnit:IsMirror() then
			local oTmpRole = goPlayerMgr:GetRoleByID(oUnit:GetObjID())
			if oTmpRole then
				if oBattle:IsLeader(oUnit:GetObjID()) then
					table.insert(tRoleList, 1, oTmpRole)
				else
					table.insert(tRoleList, oTmpRole)
				end
			end
		end

		local tPetBTData = tBTData.tPetMap[tBTData.nCurrPet]
		if tPetBTData then
			tPetBTData.bUsed = true
			local nPetUnitID = nUnitID+5
			oBattle:WriteLog("宠物单位数据", nPetUnitID, tPetBTData)
			local oUnit = CUnit:new(oBattle, nPetUnitID, tPetBTData)
			oBattle:AddUnit(nPetUnitID, oUnit)
		end

	end

	--怪物
	for nUnitID, tBTData in pairs(tMonBTData.tUnitMap) do
		oBattle:WriteLog("怪物单位数据", nUnitID, tBTData)
		local oUnit = CUnit:new(oBattle, nUnitID, tBTData)
		oBattle:AddUnit(nUnitID, oUnit)
	end

	self.m_tBattleMap[nID] = oBattle
	oBattle:BattleBegin()

	for _, oTmpRole in pairs(tRoleList) do
		oTmpRole:OnBattleBegin(nID, oBattle:GetExtData())
	end
	oMonster:OnBattleBegin(nID, oBattle:GetExtData())

end

--PVP战斗
--@tExtData 额外数据,原样返回
function CBattleMgr:PVP(oRole, tRoleBTData, oTarRole, tTarRoleBTData, tExtData, nLimitRounds)
	if oRole:IsInBattle() or oTarRole:IsInBattle() then
		return
	end
	local nID = self:GenID()

	--战斗信息
	local tBattleInfo = {
		sMusic = "battle_02.mp3",
		nTeamID1 = tRoleBTData.nTeamID,
		nTeamID2 = tTarRoleBTData.nTeamID,
		nLeaderID1 = oRole:GetID(),
		nLeaderID2 = oTarRole:GetID(),
		sLeaderName1 = oRole:GetName(),
		sLeaderName2 = oTarRole:GetName(),
		nFmtID1 = tRoleBTData.nFmtID,
		nFmtLv1 = tRoleBTData.nFmtLv,
		tFmtAttr1 = tRoleBTData.tFmtAttrAdd,
		nFmtID2 = tTarRoleBTData.nFmtID,
		nFmtLv2 = tTarRoleBTData.nFmtLv,
		tFmtAttr2 = tTarRoleBTData.tFmtAttrAdd,
		nLimitRounds = nLimitRounds,
		tExtData = tExtData,
		tLeaderData1 = tRoleBTData.tUnitMap[101],
		tLeaderData2 = tTarRoleBTData.tUnitMap[201],
	}

	--战斗对象
	local oBattle = CBattle:new(nID, gtBTT.ePVP, tBattleInfo)
	--处理阵法加成
	self:CalcFormationAttr(oBattle, tRoleBTData, tTarRoleBTData)

	--攻方玩家
	local tRoleList = {}
	for nUnitID, tBTData in pairs(tRoleBTData.tUnitMap) do
		oBattle:WriteLog("角色单位数据", nUnitID, tBTData)
		local oUnit = CUnit:new(oBattle, nUnitID, tBTData)
		oBattle:AddUnit(nUnitID, oUnit)

		if oUnit:IsRole() and not oUnit:IsMirror() then
			local oTmpRole = goPlayerMgr:GetRoleByID(oUnit:GetObjID())
			if oTmpRole then
				if oBattle:IsLeader(oUnit:GetObjID()) then
					table.insert(tRoleList, 1, oTmpRole)
				else
					table.insert(tRoleList, oTmpRole)
				end
			end
		end

		local tPetBTData = tBTData.tPetMap[tBTData.nCurrPet]
		if tPetBTData then
			tPetBTData.bUsed = true
			local nPetUnitID = nUnitID+5
			oBattle:WriteLog("宠物单位数据", nPetUnitID, tPetBTData)
			local oUnit = CUnit:new(oBattle, nPetUnitID, tPetBTData)
			oBattle:AddUnit(nPetUnitID, oUnit)
		end

	end

	--守方玩家
	local tTarRoleList = {}
	for nUnitID, tBTData in pairs(tTarRoleBTData.tUnitMap) do
		oBattle:WriteLog("角色单位数据", nUnitID, tBTData)
		local oUnit = CUnit:new(oBattle, nUnitID, tBTData)
		oBattle:AddUnit(nUnitID, oUnit)
		
		if oUnit:IsRole() and not oUnit:IsMirror() then
			local oTmpRole = goPlayerMgr:GetRoleByID(oUnit:GetObjID())
			if oTmpRole then
				if oBattle:IsLeader(oUnit:GetObjID()) then
					table.insert(tTarRoleList, 1, oTmpRole)
				else
					table.insert(tTarRoleList, oTmpRole)
				end
			end
		end

		local tPetBTData = tBTData.tPetMap[tBTData.nCurrPet]
		if tPetBTData then
			tPetBTData.bUsed = true
			local nPetUnitID = nUnitID+5
			oBattle:WriteLog("宠物单位数据", nPetUnitID, tPetBTData)
			local oUnit = CUnit:new(oBattle, nPetUnitID, tPetBTData)
			oBattle:AddUnit(nPetUnitID, oUnit)
		end

	end

	self.m_tBattleMap[nID] = oBattle
	oBattle:BattleBegin()

	for _, oTmpRole in pairs(tRoleList) do
		oTmpRole:OnBattleBegin(nID, oBattle:GetExtData())
	end
	for _, oTmpRole in pairs(tTarRoleList) do
		oTmpRole:OnBattleBegin(nID, oBattle:GetExtData())
	end

end

--默认tTeamList和tTarTeamList第一个成员是队长
--只要在列表，不论是否暂离，都会进入战斗
function CBattleMgr:PVPBySpecify(tTeamList, tTarTeamList, tExtData, bWithoutPartner, nLimitRounds)
	print("CRole:PVPBySpecify***", tTeamList, tTarTeamList)
	assert(not nLimitRounds or nLimitRounds>0, "回合数据错误")
	assert(tTeamList and #tTeamList > 0, "玩家数据错误")
	assert(tTarTeamList and #tTarTeamList > 0, "目标玩家数据错误")
	for k, v in ipairs(tTeamList) do 
		for x, tTar in ipairs(tTarTeamList) do 
			if v.nRoleID == tTar.nRoleID then 
				LuaTrace("数据错误，出现自己挑战自己")
				LuaTrace("tTeamList", tTeamList)
				LuaTrace("tTarTeamList", tTarTeamList)
				if gbInnerServer then 
					assert(false, "数据错误")
				else
					LuaTrace(debug.traceback())
					return
				end
			end
		end
	end

	local nTeamID = nil
	local nTarTeamID = nil
	for k, v in ipairs(tTeamList) do 
		local oTempRole = goPlayerMgr:GetRoleByID(v.nRoleID)
		assert(oTempRole, "玩家不存在当前逻辑服")
		if oTempRole:IsInBattle() then 
			LuaTrace("数据错误，玩家正在战斗中")
			return 
		end
		v.bLeave = false --否则，如果玩家暂离，然后发起战斗，无法正常生成战斗数据
		if not nTeamID then 
			nTeamID = oTempRole:GetTeamID()
		else
			if nTeamID ~= oTempRole:GetTeamID() then --如果存在多人，目前只允许同一队伍玩家一起进战
				LuaTrace("存在其他队伍玩家")
				return 
			end
		end
	end
	for k, v in ipairs(tTarTeamList) do 
		local oTempRole = goPlayerMgr:GetRoleByID(v.nRoleID)
		assert(oTempRole, "玩家不存在当前逻辑服")
		if oTempRole:IsInBattle() then 
			LuaTrace("数据错误，玩家正在战斗中")
			return 
		end
		v.bLeave = false
		if not nTarTeamID then 
			nTarTeamID = oTempRole:GetTeamID()
		else
			if nTarTeamID ~= oTempRole:GetTeamID() then --如果存在多人，目前只允许同一队伍玩家一起进战
				LuaTrace("存在其他队伍玩家")
				return 
			end
		end
	end
	local oRoleLeader = goPlayerMgr:GetRoleByID(tTeamList[1].nRoleID)
	local oTarRoleLeader = goPlayerMgr:GetRoleByID(tTarTeamList[1].nRoleID)
	assert(oRoleLeader and oTarRoleLeader)
	local tBattleData = oRoleLeader:MakeTeamBattleData(nTeamID, tTeamList, true, bWithoutPartner)
	local tTarBattleData = oTarRoleLeader:MakeTeamBattleData(nTarTeamID, tTarTeamList, false, bWithoutPartner)
	if not tBattleData or not tTarBattleData then 
		return
	end
	goBattleMgr:PVP(oRoleLeader, tBattleData, oTarRoleLeader, tTarBattleData, tExtData, nLimitRounds)
end

--检测宠物数据是否正常
function CBattleMgr:CheckPetData(oBattle, tPetMap)
	for nPos, tPetData in pairs(tPetMap) do
	    if not ctPetInfoConf[tPetData.nObjID] then
	    	tPetMap[nPos] = nil
	    	oBattle:WriteLog("战斗数据中宠物配置不存在", tPetData.nObjID)
	    	print("战斗数据中宠物配置不存在", tPetData.nObjID)
	    end
	end
end

--竞技场P战斗
--@tExtData 额外数据,原样返回
function CBattleMgr:PVPArena(oRole, tRoleBTData, tTarRoleBTData, tExtData, nLimitRounds)
	if oRole:IsInBattle() then
		return
	end
	local nID = self:GenID()

	--战斗信息
	local tBattleInfo = {
		sMusic = "battle_02.mp3",
		nTeamID1 = tRoleBTData.nTeamID,
		nTeamID2 = tTarRoleBTData.nTeamID,
		nLeaderID1 = oRole:GetID(),
		nLeaderID2 = tTarRoleBTData.tUnitMap[201].nObjID,
		sLeaderName1 = oRole:GetName(),
		sLeaderName2 = tTarRoleBTData.tUnitMap[201].sObjName,
		nFmtID1 = tRoleBTData.nFmtID,
		nFmtLv1 = tRoleBTData.nFmtLv,
		tFmtAttr1 = tRoleBTData.tFmtAttrAdd,
		nFmtID2 = tTarRoleBTData.nFmtID,
		nFmtLv2 = tTarRoleBTData.nFmtLv,
		tFmtAttr2 = tTarRoleBTData.tFmtAttrAdd,
		nLimitRounds = nLimitRounds,
		tExtData = tExtData,
		tLeaderData1 = tRoleBTData.tUnitMap[101],
		tLeaderData2 = tTarRoleBTData.tUnitMap[201],
	}

	--战斗对象
	local oBattle = CBattle:new(nID, gtBTT.eArena, tBattleInfo) 
	--处理阵法加成
	self:CalcFormationAttr(oBattle, tRoleBTData, tTarRoleBTData)

	--攻方玩家
	local tRoleList = {}
	for nUnitID, tBTData in pairs(tRoleBTData.tUnitMap) do
		assert(nUnitID < 200, "单位编号错误")
		oBattle:WriteLog("角色单位数据", nUnitID, tBTData)
		local oUnit = CUnit:new(oBattle, nUnitID, tBTData)
		oBattle:AddUnit(nUnitID, oUnit)

		if oUnit:IsRole() and not oUnit:IsMirror() then
			local oTmpRole = goPlayerMgr:GetRoleByID(oUnit:GetObjID())
			if oTmpRole then
				if oBattle:IsLeader(oUnit:GetObjID()) then
					table.insert(tRoleList, 1, oTmpRole)
				else
					table.insert(tRoleList, oTmpRole)
				end
			end
		end

		self:CheckPetData(oBattle, tBTData.tPetMap)
		local tPetBTData = tBTData.tPetMap[tBTData.nCurrPet]
		if tPetBTData then
			tPetBTData.bUsed = true
			local nPetUnitID = nUnitID+5
			oBattle:WriteLog("宠物单位数据", nPetUnitID, tPetBTData)
			local oUnit = CUnit:new(oBattle, nPetUnitID, tPetBTData)
			oBattle:AddUnit(nPetUnitID, oUnit)
		end

	end

	--守方玩家
	for nUnitID, tBTData in pairs(tTarRoleBTData.tUnitMap) do
		assert(nUnitID > 200, "单位编号错误")
		oBattle:WriteLog("角色单位数据", nUnitID, tBTData)
		local oUnit = CUnit:new(oBattle, nUnitID, tBTData)
		oBattle:AddUnit(nUnitID, oUnit)

		self:CheckPetData(oBattle, tBTData.tPetMap)
		local tPetBTData = tBTData.tPetMap[tBTData.nCurrPet]
		if tPetBTData then
			tPetBTData.bUsed = true
			local nPetUnitID = nUnitID+5
			oBattle:WriteLog("宠物单位数据", nPetUnitID, tPetBTData)
			local oUnit = CUnit:new(oBattle, nPetUnitID, tPetBTData)
			oBattle:AddUnit(nPetUnitID, oUnit)
		end

	end

	self.m_tBattleMap[nID] = oBattle
	oBattle:BattleBegin()

	for _, oTmpRole in pairs(tRoleList) do
		oTmpRole:OnBattleBegin(nID, oBattle:GetExtData())
	end

end

--注册其他模块属性加成函数
function CBattleMgr:RegisterAddAttrFun()
	self.m_fnAddAttr[gtAddAttrModType.eShiLianTask] = function(oRole) return self:ShiLianTaskAddAttr(oRole) end
	self.m_fnAddAttr[gtAddAttrModType.eGuaJi] = function(oRole) return self:GuaJiAddAttrPre(oRole)end
end

--返回试炼属性加成百分比
function CBattleMgr:ShiLianTaskAddAttr(oRole)
	local nHuanShu = oRole.m_oShiLianTask.m_nCompTimes + 1 --(环数：1~200)
	local nAttrAddRatio = 1 + nHuanShu/100
	return nAttrAddRatio
end
--返回挂机模块属性加成百分比
function CBattleMgr:GuaJiAddAttrPre(oRole)
	local nGuanQia, nBattleTimes = oRole.m_oGuaJi:GetGuanQiaAndBattleTimes()
	local tGuanQiaConf = ctGuaJiConf:GetGuanQiaConf(nGuanQia)
	return (1+tGuanQiaConf.fnAddBossAttrPre(nGuanQia))
end

--其他模块加成怪物属性百分比[基础属性[气血,攻击,防御,速度,魔法]上加],会存在Battle对象中
function CBattleMgr:CalcOtherAttrAddRatio(oRole, tExtData)
	local tOtherAttrAddRatio = {}
	if tExtData and tExtData.nAddAttrModType then
		assert(self.m_fnAddAttr[tExtData.nAddAttrModType],"其他模块加成怪物属性函数未定义:"..tExtData.nAddAttrModType)
		tOtherAttrAddRatio[tExtData.nAddAttrModType] = self.m_fnAddAttr[tExtData.nAddAttrModType](oRole)
	end
	return tOtherAttrAddRatio
end

--计算全部单位怪物的其他模块属性加成(进入战斗前计算)
function CBattleMgr:CalcOtherAttrAdd(oBattle, tMonBTData)
	for nUnitID, tBTData in pairs(tMonBTData.tUnitMap) do
		self:CalcUnitOtherAttrAdd(oBattle, nUnitID, tBTData)
	end
end

--计算某个单位怪物的其他模块属性加成(中途召唤也会计算)
function CBattleMgr:CalcUnitOtherAttrAdd(oBattle, nUnitID, tUnitData)
	local tAttrAddRatio = oBattle:GetOtherAttrAddRatio()
	for nType, nRatio in pairs(tAttrAddRatio) do
		tUnitData.tBattleAttr[gtBAT.eQX] = math.floor(tUnitData.tBattleAttr[gtBAT.eQX]*nRatio)
		tUnitData.tBattleAttr[gtBAT.eGJ] = math.floor(tUnitData.tBattleAttr[gtBAT.eGJ]*nRatio)
		tUnitData.tBattleAttr[gtBAT.eFY] = math.floor(tUnitData.tBattleAttr[gtBAT.eFY]*nRatio)
		tUnitData.tBattleAttr[gtBAT.eSD] = math.floor(tUnitData.tBattleAttr[gtBAT.eSD]*nRatio)
		tUnitData.tBattleAttr[gtBAT.eMF] = math.floor(tUnitData.tBattleAttr[gtBAT.eMF]*nRatio)
		tUnitData.tBattleAttr[gtBAT.eLL] = math.floor(tUnitData.tBattleAttr[gtBAT.eLL]*nRatio)
	end
	if next(tAttrAddRatio) then
		tUnitData.nMaxHP = math.max(tUnitData.nMaxHP, tUnitData.tBattleAttr[gtBAT.eQX])
		tUnitData.nMaxMP = math.max(tUnitData.nMaxMP, tUnitData.tBattleAttr[gtBAT.eMF])
		oBattle:WriteLog("怪物其他模块属性加成", tAttrAddRatio, nUnitID, tUnitData.sObjName, tUnitData.tBattleAttr)
	end
end

goBattleMgr = goBattleMgr or CBattleMgr:new()