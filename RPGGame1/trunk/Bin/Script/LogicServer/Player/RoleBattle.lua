--角色对象中与战斗相关函数
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

CRole.tBattleFromModule = 
{
	eTaskSystem = 1,
	eShiMenTask = 2,
}

--取战斗数据
--@bMirror 是否竞技场
function CRole:GetBattleData(bMirror)
	--恢复气血和蓝
	if self.m_oRoleState:GetBaoShiTimes() > 0 then
		self:RecoverMPHP()
	end

	local tBTData = {}
	--基本信息
	tBTData.nSpouseID = self:GetSpouse() --配偶ID
	tBTData.nObjID = self:GetID()	
	tBTData.nObjType = self:GetObjType()
	tBTData.sObjName = self:GetName()
	tBTData.nLevel = self:GetLevel()
	tBTData.nExp = self:GetExp()
	tBTData.sModel = self:GetConf().sModel
	tBTData.nSchool = self:GetSchool()
	tBTData.bMirror = bMirror
	tBTData.sGrade = self:GetGrade()
	--自动战斗
	tBTData.bAuto = self:IsAutoBattle()
	--先取武器攻击,可能会触发附魔失效,会重新计算战斗属性
	tBTData.nWeaponAtk = self.m_oKnapsack:GetWeaponAtk()
	--取武器ID
	tBTData.nWeaponID = self:GetWeaponID()
	--取神器ID
	tBTData.nArtifactID = self:GetArtifactID()

	local tBattleAttr = self:GetBattleAttr()
	tBTData.nMaxHP = tBattleAttr[gtBAT.eQX]
	tBTData.nMaxMP = tBattleAttr[gtBAT.eMF]
	tBTData.tBattleAttr = table.DeepCopy(tBattleAttr)
	tBTData.tBattleAttr[gtBAT.eQX] = self:GetCurrHP()
	tBTData.tBattleAttr[gtBAT.eMF] = self:GetCurrMP()

	--宠物
	tBTData.tPetMap = {}
	local tPetList = self.m_oPet:GetPetList()
	for _, nPos in ipairs(tPetList) do
		local tPetMData = self.m_oPet:GetBattleData(nPos)
		if tPetMData then
			tPetMData.bMirror = bMirror
			tBTData.tPetMap[nPos] = tPetMData
		end
	end
	tBTData.nCurrPet = self.m_oPet:PetCombat()

	if not bMirror then --镜像没有法宝技能
		tBTData.tFBSkillMap = self.m_oFaBao:GetFaBaoSkill()
	end

	--主动被动技能
	tBTData.tActSkillMap = self.m_oSkill:GetBattleSkillMap()
	tBTData.tPasSkillMap = {}

	--修炼系统
	tBTData.tPracticeMap = self.m_oPractice:GetPracticeMap()

	--自动战斗
	tBTData.nAutoInst = self.m_nAutoInst
	tBTData.nAutoSkill = self.m_nAutoSkill
	tBTData.nManualSkill = self.m_nManualSkill

	return tBTData
end

--生成队伍战斗信息
function CRole:MakeTeamBattleData(nTeamID, tTeam, bAtk, bWithoutPartner)
	assert(tTeam, "队伍战斗数据生成参数错误")

	local nFmtID, nFmtLv = self.m_oFormation:GetUseFmt()
	local tFmtAttrAdd = self.m_oFormation:GetAttrAdd()

	local tBattleData = {
		nTeamID = nTeamID,
		nFmtID = nFmtID,
		nFmtLv = nFmtLv,
		tFmtAttrAdd = tFmtAttrAdd,
		tUnitMap={},
	}

	local nUnitID = bAtk and 100 or 200
	local tPartnerList = bWithoutPartner and {} or self.m_oPartner:GetBattlePartner()

	for k = 1, 5 do 
		nUnitID = nUnitID + 1

		local tRole = tTeam[k]
		if tRole and not tRole.bLeave then
			local oRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
			if not oRole then
				if k == 1 then
					return LuaTrace("队长角色已释放,战斗失败", tRole)
				else
					LuaTrace("非队长角色已释放", tRole)
				end
			else
				local tBTData = oRole:GetBattleData() 
				tBattleData.tUnitMap[nUnitID] = tBTData

				--0耐久装备
				local tEquList = oRole.m_oKnapsack:GetDurableWearEqu(0)
				for _, oEqu in ipairs(tEquList) do
					oRole:Tips(string.format("%s已损坏，请点击装备修复耐久度", oEqu:GetName()))
				end
			end

		--伙伴
		elseif #tPartnerList > 0 then
			local oPartner = tPartnerList[1]
			local tBTData = oPartner:GetBattleData()
			tBattleData.tUnitMap[nUnitID] = tBTData
			table.remove(tPartnerList, 1)

		end
	end

	if not next(tBattleData.tUnitMap) then
		return LuaTrace(self:GetID(), self:GetName(), "没有单位参加战斗!")
	end
	return tBattleData
end

--生成用于竞技场镜像的战斗信息
function CRole:MakeArenaNpcBattleData()
	local nFmtID, nFmtLv = self.m_oFormation:GetUseFmt()
	local tFmtAttrAdd = self.m_oFormation:GetAttrAdd()

	local tBattleData = {
		nTeamID = 0,
		nFmtID = nFmtID,
		nFmtLv = nFmtLv,
		tFmtAttrAdd = tFmtAttrAdd,
		tUnitMap={},
	}

	local nUnitID = 201
	local tBTData = self:GetBattleData(true) 
	tBTData.bAuto = true
	tBattleData.tUnitMap[nUnitID] = tBTData

	local tPartnerList = self.m_oPartner:GetBattlePartner()
	for k = 1, #tPartnerList do
		nUnitID = nUnitID + 1
		local oPartner = tPartnerList[k]
		local tBTData = oPartner:GetBattleData(true)
		tBattleData.tUnitMap[nUnitID] = tBTData
		if nUnitID >= 205 then
			break
		end
	end

	return tBattleData
end

--开始PVE战斗
--@tExtData 战斗额外参数，战斗结束原样返回
function CRole:PVE(oMonster, tExtData)
	print("CRole:PVE***", self:GetName(), oMonster:GetName())
	tExtData = tExtData or {}
	
	if self:IsInBattle() then		
		LuaTrace(self:GetName(), "正在战斗中", self:GetBattleID())
		return self:Tips("正在战斗中")
	end
	if not oMonster then
		return LuaTrace("怪物不存在")
	end

	local nRoleID = self:GetID()
	local oDup = self:GetCurrDupObj()
	local tConf = oDup:GetConf()

	--单人副本
	if tConf.bSingle then
		local tBattleData = self:MakeTeamBattleData(0, {{nRoleID=nRoleID}}, true)
		if not tBattleData then return end
		goBattleMgr:PVEBattle(self, tBattleData, oMonster, tExtData, tExtData.nLimitRounds)

	else
		self:GetTeam(function(nTeamID, tTeam)
			--无队伍
			if not nTeamID or nTeamID == 0 then
				local tBattleData = self:MakeTeamBattleData(0, {{nRoleID=nRoleID}}, true)
				if not tBattleData then return end
				goBattleMgr:PVEBattle(self, tBattleData, oMonster, tExtData, tExtData.nLimitRounds)
				return
			end

			--非队长,但是已归队
			if tTeam[1].nRoleID ~= nRoleID then
				for _, tRole in pairs(tTeam) do
					if tRole.nRoleID == nRoleID and not tRole.bLeave then
						return self:Tips("请先暂离队伍")
					end
				end
				local tBattleData = self:MakeTeamBattleData(0, {{nRoleID=nRoleID}}, true)
				if not tBattleData then return end
				goBattleMgr:PVEBattle(self, tBattleData, oMonster, tExtData, tExtData.nLimitRounds)

			else
				local tBattleData = self:MakeTeamBattleData(nTeamID, tTeam, true)
				if not tBattleData then return end
				goBattleMgr:PVEBattle(self, tBattleData, oMonster, tExtData, tExtData.nLimitRounds)

			end
		end)
	end
end

--开始PVP战斗
--@tExtData 战斗额外参数，战斗结束原样返回
--@bWithoutPartner 是否禁止仙侣上阵(可选)
--@nLimitRounds 限制回合数(可选)
function CRole:PVP(oTarRole, tExtData, bWithoutPartner, nLimitRounds)
	print("CRole:PVP***", self:GetName(), oTarRole:GetName())
	assert(not nLimitRounds or nLimitRounds>0, "回合数据错误")
	assert(self:GetID() ~= oTarRole:GetID(), "不能打自己")

	if self:IsInBattle() then
		return self:Tips("正在战斗中")
	end
	if oTarRole:IsInBattle() then
		return self:Tips("对方正在战斗中")
	end

	local nRoleID = self:GetID()
	local nTarRoleID = oTarRole:GetID()
	local oDup = self:GetCurrDupObj()
	local tConf = oDup:GetConf()

	self:GetTeam(function(nTeamID, tTeam)
		local tBattleData
		--无队伍
		if not nTeamID or nTeamID == 0 then
			tBattleData = self:MakeTeamBattleData(0, {{nRoleID=nRoleID}}, true, bWithoutPartner)

		--非队长,但是已归队
		elseif tTeam[1].nRoleID ~= nRoleID then
			for _, tRole in pairs(tTeam) do
				if tRole.nRoleID == nRoleID and not tRole.bLeave then
					return self:Tips("请先暂离队伍")
				end
			end
			tBattleData = self:MakeTeamBattleData(0, {{nRoleID=nRoleID}}, true, bWithoutPartner)

		else
			tBattleData = self:MakeTeamBattleData(nTeamID, tTeam, true, bWithoutPartner)

		end

		if not tBattleData then
			return
		end

		--对手
		oTarRole:GetTeam(function(nTarTeamID, tTarTeam)
			local tTarBattleData
			if not nTarTeamID or nTarTeamID == 0 then
				tTarBattleData = oTarRole:MakeTeamBattleData(0, {{nRoleID=nTarRoleID}}, false, bWithoutPartner)

			elseif tTarTeam[1].nRoleID ~= nTarRoleID then
				for _, tRole in pairs(tTarTeam) do
					if tRole.nRoleID == nTarRoleID and not tRole.bLeave then
						return self:Tips("对方在归队状态")
					end
				end
				tTarBattleData = oTarRole:MakeTeamBattleData(0, {{nRoleID=nTarRoleID}}, false, bWithoutPartner)

			else
				tTarBattleData = oTarRole:MakeTeamBattleData(nTarTeamID, tTarTeam, false, bWithoutPartner)
			end	

			if not tTarBattleData then
				return
			end

			goBattleMgr:PVP(self, tBattleData, oTarRole, tTarBattleData, tExtData, nLimitRounds)
		end)
	end)
end

--开始竞技场战斗
--@tTarBTData 镜像战斗数据
--@tExtData 战斗额外参数，战斗结束原样返回
--@nLimitRounds 限制回合数(可选)
function CRole:PVPArena(tTarBTData, tExtData, nLimitRounds)
	print("CRole:PVPArena***", self:GetName(), tTarBTData.sObjName)
	assert(not nLimitRounds or nLimitRounds>0, "回合数据错误")

	if self:IsInBattle() then
		return self:Tips("正在战斗中")
	end

	local nRoleID = self:GetID()
	local tBattleData = self:MakeTeamBattleData(0, {{nRoleID=nRoleID}}, true)
	if not tBattleData then
		return
	end
	goBattleMgr:PVPArena(self, tBattleData, tTarBTData, tExtData, nLimitRounds)
end

--进入战斗事件
function CRole:OnBattleBegin(nBattleID)
	self.m_nBattleID = nBattleID
	if self:GetNativeObj() and self:GetAOIID() > 0 then 
		self:StopRun()
	end
	local oDup = self:GetCurrDupObj()
	if oDup then 
		oDup:OnObjBattleBegin(self)
	end

    --同步到GLOBAL/WGLOBAL
    self:GlobalRoleUpdate({m_nBattleID=nBattleID})
end

function CRole:GetPVPActivityArgs(nActivityID)
	if nActivityID == 1004 then
		return self:GetUnionID()
	else
		return self:GetSchool()
	end
end

--战斗结束事件
--@tBTRes 战斗结束数据:
--{
--@nBattleID 战斗ID
--@nBattleType 战斗类型
--@nEndType 结束类型: 1正常; 2逃跑; 3异常
--@bWin 是否胜利
--@bAuto 是否自动
--@nLeaderID1 攻方队长ID
--@nLeaderID2 守方队长ID
--@nHP 剩余血量
--@nMP 剩余魔法
--@nAtkCount 攻击次数
--@nBeAtkCount 被攻击次数
--@nTeamID 队伍ID
--@tTeamRoleList 队伍角色ID表(里面不包括中途逃跑的)
--@bLastCallback 是否队伍里面最后1个角色的回调(正常结束有效)
--@nAutoInst 自动战斗默认指令
--@nAutoSkill 自动战斗默认技能
--@nEndTime 战斗结束时间戳
--}
--@tExtData 额外数据，原样返回
function CRole:OnBattleEnd(tBTRes, tExtData)
	LuaTrace("角色战斗结束", self:GetID(), self:GetName(), tBTRes)
	tExtData = tExtData or {}
    self.m_nBattleID = 0
    self.m_bAutoBattle = tBTRes.bAuto
    self.m_nBattleCount = (self.m_nBattleCount or 0)+1
    self.m_nCurrMP = tBTRes.nMP
    self.m_nCurrHP = math.max(1, tBTRes.nHP) --最少留1点血
    self.m_nManualSkill = tBTRes.nManualSkill
    self.m_nAutoInst = tBTRes.nAutoInst
    self.m_nAutoSkill = tBTRes.nAutoSkill
    self:MarkDirty(true)
    
    --饱食度相关
    if self.m_oRoleState:CheckSubBaoShi(tBTRes.nBattleID, tExtData.nBattleDupType) then
	    self:RecoverMPHP()
    end

	--装备耐久相关
	self.m_oKnapsack:OnBattleResult(tBTRes)
	self.m_oRoleState:CheckEquDurable()

    --同步到GLOBAL/WGLOBAL
    self:GlobalRoleUpdate({m_nBattleID=0, m_tBTRes=tBTRes})
    -- Network.oRemoteCall:Call("OnBattleEndReq", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), self:GetSession(), self:GetID(), tBTRes)

    --场景调用
    local oDup = self:GetCurrDupObj()
    if oDup then
    	oDup:OnBattleEnd(self, tBTRes, tExtData)
    end

	--挂机调用
	if tExtData and  tExtData.bGuaJi then
		self.m_oGuaJi:OnBattleEnd(tBTRes.bWin)
	end
	-- if tExtData and tExtData.bPVPActivityBattle then
	-- 	local nPVPActivityID = tExtData.tPVPActivityData.nActivityID
	-- 	local nArgs = self:GetPVPActivityArgs(nPVPActivityID)
	-- 	local oActInst = goPVPActivityMgr:GetActivityByID(nPVPActivityID,nArgs)
	-- 	if oActInst then --可能被释放了
	-- 		oActInst:OnRoleBattleEnd(self, tBTRes, tExtData)
	-- 	end
	-- end
	if tExtData and tExtData.bArenaBattle then
		local tArenaResult = {nEnemyID = tExtData.tArenaData.nEnemyID, nArenaSeason = tExtData.tArenaData.nArenaSeason, bWin = tBTRes.bWin}
		local nServerID = self:GetServer() --竞技场在本地全局服
		Network.oRemoteCall:Call("ArenaBattleEndReq", nServerID, goServerMgr:GetGlobalService(nServerID, 20), 
			self:GetSession(), self:GetID(), tArenaResult)
	end
	if tExtData and tExtData.bMentorshipTaskBattle then
		local nTaskID = tExtData.tAsyncData.nTaskID
		local nTimeStamp = tExtData.tAsyncData.nTimeStamp
		local nSrcService = tExtData.tAsyncData.nSrcService
		Network.oRemoteCall:Call("MentorshipTaskBattleEndReq", gnWorldServerID, nSrcService, 
			self:GetSession(), self:GetID(), {nTaskID = nTaskID, bWin = tBTRes.bWin, nTimeStamp = nTimeStamp})
	end

	if tExtData and tExtData.bShangJinTask then
		self.m_oShangJinTask:OnBattleEnd(tBTRes.bWin)
	end

	if tExtData and tExtData.bYaoShouTuXiTask then
		self.m_oYaoShouTuXi:OnBattleEnd(tBTRes.bWin)
	end

	if tExtData and tExtData.bShiLian then
		self.m_oShiLianTask:OnBattleEnd(tBTRes.bWin)
	end

	if tExtData and tExtData.bJiangHuLiLian then
		local oExperience = self.m_oHolidayActMgr:GetActByHolidayActType(gtHolidayActType.eExperience)
		if oExperience then
			oExperience:OnBattleEnd(tBTRes.bWin)
		end
	end	

	if tExtData and tExtData.bTargetTask then
		self.m_oTargetTask:OnBattleEnd(tBTRes.bWin)
	end
	if tExtData and tExtData.bShenShouLeYuan then
		self.m_oShenShouLeYuanModule:OnBattleEnd(tBTRes, tExtData)
	end

    --如果战斗中角色下线了,战斗结束后释放对象
    if self:IsBattleOffline() then
        goPlayerMgr:RoleOfflineReq(self:GetID())
    end
end

--取队伍角色列表封装
function CRole:GetTeam(fnCallback)
	Network.oRemoteCall:CallWait("TeamBattleInfoReq", function(nTeamID, tTeam)
		if not nTeamID then
			return LuaTrace("队伍信息请求超时了")
		end
		fnCallback(nTeamID, tTeam)
	end, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), self:GetSession(), self:GetID())
end

--创建队伍
function CRole:CreateTeam(fnCallback)
	Network.oRemoteCall:CallWait("WCreateTeamReq", function(nTeamID, tTeam)
		fnCallback(nTeamID, tTeam)
	end, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), self:GetSession(), self:GetID())
end

--离开队伍
function CRole:QuitTeam(fnCallback)
	if fnCallback then 
		Network.oRemoteCall:CallWait("WQuitTeamReq", fnCallback, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), self:GetSession(), self:GetID())
	else
		Network.oRemoteCall:Call("WQuitTeamReq", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), self:GetSession(), self:GetID())
	end
end

--进行组队匹配
--@nGameType 玩法类型
--@bSys 是否是系统服务调用，系统服务调用，不受组队匹配冷却时间限制
function CRole:MatchTeam(nGameType, sGameName, bSys)
	Network.oRemoteCall:Call("WMatchTeamReq", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), self:GetSession(), self:GetID(), nGameType, sGameName, bSys)
end

--取消组队匹配
function CRole:CancelMatchTeam(nGameType, sGameName)
	Network.oRemoteCall:Call("WCancelMatchTeamReq", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), self:GetSession(), self:GetID(), nGameType, sGameName)
end

--战斗副本ID
function CRole:SetBattleDupID(nBattleDupID)
	self.m_nBattleDupID = nBattleDupID
end
function CRole:GetBattleDupID()
	return self.m_nBattleDupID
end

--设置目标副本类型(在副本中通过日常请求进入其他副本时设置此，在中转场景根据此类型回调)
function CRole:SetTarBattleDupType(nType)
	self.m_oDailyActivity:SetTarBattleDupType(nType)
end

function CRole:GetTarBattleDupType(nType)
	return self.m_oDailyActivity:GetTarBattleDupType()
end