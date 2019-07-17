--战斗单位
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--加快速度
local gtBTT, gtBTRes, gtRatioAttr, gtACT, GetActTime, gtAddAttrModType = 
	gtBTT, gtBTRes, gtRatioAttr, gtACT, GetActTime, gtAddAttrModType


--指令
CUnit.tINST = 
{
	eFS = 1, 	--法术
	eGJ = 2,	--攻击
	eWP = 3, 	--物品
	eZH = 4, 	--召唤
	eZD = 5, 	--自动
	eFY = 6, 	--防御
	eBH = 7, 	--保护
	eBZ = 8,	--捕捉
	eCT = 9, 	--撤退
}

--指令函数映射
CUnit.tInstFunc = 
{
	[CUnit.tINST.eFS] = {"FSInst", "FSExec"},
	[CUnit.tINST.eGJ] = {"GJInst", "GJExec"},
	[CUnit.tINST.eWP] = {"WPInst", "WPExec"},
	[CUnit.tINST.eZH] = {"ZHInst", "ZHExec"},
	[CUnit.tINST.eZD] = {"ZDInst", "ZDExec"},
	[CUnit.tINST.eFY] = {"FYInst", "FYExec"},
	[CUnit.tINST.eBH] = {"BHInst", "BHExec"},
	[CUnit.tINST.eBZ] = {"BZInst", "BZExec"},
	[CUnit.tINST.eCT] = {"CTInst", "CTExec"},
}

--回合辅助标记
CUnit.tRoundFlag = 
{
	ePTD = 1, 			--被保护(每回合只保护一次)
	eSPC = 2, 			--速度被改变
	eLCK = 3, 			--禁止所有行动
	eCOT = 4, 			--反击
	eSHA = 5, 			--变身(废弃)
	eLCKFS = 6,			--禁止法术
	eLCKGJ = 7, 		--禁止物理
	eLCKCT = 8, 		--禁止撤退
	eLCKRL = 9, 		--禁止复活
	eLCKFYBUFF = 12, 	--禁止封印BUFF
	eONLYFY = 13, 		--只能防御
	eIGNBJ = 14, 		--忽略物理暴击
	eIGNFSBJ = 15, 		--忽略法术暴击
	eHIDE = 16, 		--隐身标记
	eGM = 17, 			--触发鬼魅
	eIGNGM = 18, 		--忽略鬼魅效果
	eIGNCS = 19, 		--忽略重生效果
	eIGNQP = 20, 		--忽略强迫效果
	eIGNHIDE = 21, 		--忽略隐身
	eLCKTJ = 22, 		--禁止特技
	eCONFUSE = 23, 		--混乱
}

--反击环境
CUnit.tCOTContext = 
{
	nSKID = 0,			--反击技能ID
	sGJTips = "", 		--反击喊招
	bPasSkill = false,  --是否被动技能触发的反击
	nRemoveBuffID = 0, 	--要移除的BUFF(主动技能反击)
}

--自动的指令
CUnit.tAutoInst = 
{
	CUnit.tINST.eGJ,
	CUnit.tINST.eFS,
	CUnit.tINST.eFY,
}

--不会错过的治疗
CUnit.tNoMissInst = 
{
	CUnit.tINST.eZD,
}

--@nUnitID 单位ID
function CUnit:Ctor(oBattle, nUnitID, tBTData)
	self.m_tBTData = tBTData
	self.m_oBattle = oBattle
	self.m_nUnitID = nUnitID 					--单位ID
	self.m_nSpouseID = tBTData.nSpouseID or 0 	--夫妻ID
	self.m_nRoleID = tBTData.nRoleID or 0 		--所属角色ID
	self.m_sGrade = tBTData.sGrade or "" 		--评级(仙侣,角色,宠物)
	self.m_nAI = 0
	self.m_nCmdID = 0 				--战斗指挥ID
	self.m_sCmdName = 0 			--战斗指挥名字

	self.m_nObjID = tBTData.nObjID		--对象ID
	self.m_nObjType = tBTData.nObjType 	--对象类型
	self.m_sObjName = tBTData.sObjName 	--对象名字
	self.m_nLevel = tBTData.nLevel 		--等级
	self.m_nExp = tBTData.nExp 			--经验
	self.m_sModel = tBTData.sModel 		--模型ID
	self.m_nPetPos = tBTData.nPos or 0 	--格子编号(宠物)
	self.m_nSchool = tBTData.nSchool or 0	--门派(角色)
	self.m_bMirror = tBTData.bMirror or false --是否镜像
	self.m_bRobot = tBTData.bRobot or false   --是否为机器人
	self.m_nWeaponID = tBTData.nWeaponID or 0 		--武器ID
	self.m_nArtifactID = tBTData.nArtifactID or 0 	--神器ID
	self.m_nArtifactLevel = tBTData.nArtifactLevel or 0  --神器等级

	self.m_tBattleAttr = tBTData.tBattleAttr
    self.m_nWeaponAtk = tBTData.nWeaponAtk 	--武器攻击
    self.m_nMaxHP = tBTData.nMaxHP 			--血量上限
    self.m_nMaxMP = tBTData.nMaxMP 			--魔法上限

    self.m_tPetMap = tBTData.tPetMap or {} 			 --宠物列表(角色){[posid]=tPetMData,...}
    self.m_tActSkillMap = tBTData.tActSkillMap or {} --主动法术列表{[id]={name="",level=0,},...}
    self.m_tPasSkillMap = tBTData.tPasSkillMap or {} --被动技能
    self.m_tPracticeMap = tBTData.tPracticeMap or {} --修炼{[id]=level,...}
    self.m_tFBSkillMap = tBTData.tFBSkillMap or {} 	--法宝技能{[id]={name="",level=0,},...}

    self.m_nMaxSP = 150 			--怒气上限
    self.m_nPropUsed = 0 			--物品使用数量(角色)
    self.m_nPetCalled = 0 			--召唤宠物次数
    self.m_nRetreatBaseRate = 70 	--撤退基础成功率

    self.m_nSubMonsterCalled = 0 	 	--已召唤子怪物次数
    self.m_nSubMonsterDeadLeaveRound = 0 --子怪物死亡离开回合

    self.m_bLeave = false 			--是否已离开(撤退/PNC死亡)
    self.m_bAuto = tBTData.bAuto 	--是否自动战斗

    self.m_tInst = {}			--指令{inst=0,...}
    self.m_tBuffMap = {} 		--BUFF映射{[type]={...},...}
    self.m_tRoundFlag = {}		--回合中一些状态标记{[flag]={...}, ...}

    self.m_oSkillHelper = CSkillHelper:new()
    self.m_oFBSkillHelper = CFBSkillHelper:new()
    self.m_oSelectHelper = CSelectHelper:new()
    self.m_oPropHelper = CPropHelper:new()
    self.m_oPracticeHelper = CPracticeHelper:new()
    self.m_oPasSkillHelper = CPasSkillHelper:new(oBattle)
    self.m_oAIHelper = CAIHelper:new(oBattle)

    self.m_nAttackCount = 0 	--攻击次数
    self.m_nBeAttackedCount = 0 --被攻击次数

    self.m_nManualInst = 0 --上次手动指令
    self.m_nManualSkill = tBTData.nManualSkill or 0	 --上次手动技能(法术)
    --过滤不存在技能(宠物的技能学习时会被替换)
    if self.m_nManualSkill>0 and not self.m_tActSkillMap[self.m_nManualSkill] then
    	self.m_nManualInst = 0
    	self.m_nManualSkill = 0
    end

    self.m_nAutoInst = (tBTData.nAutoInst or 0)==0 and CUnit.tINST.eGJ or tBTData.nAutoInst	 --自动战斗指令
    self.m_nAutoSkill = tBTData.nAutoSkill or 0  --自动战斗技能(法术,攻击,防御)
    --过滤不存在技能(宠物的技能学习时会被替换)
	if self.m_nAutoSkill>0 and not self.m_tActSkillMap[self.m_nAutoSkill] then
		self.m_nAutoInst = CUnit.tINST.eGJ
    	self.m_nAutoSkill  = 0
    end
    
    self.m_nAutoTimer = nil 	--自动时缓冲计时器
    self.m_nLeaveTimer = nil 	--离开战斗计时器
    self.m_nRoundsEscape = 0 		--某1回合逃跑
    self.m_bReconnectRound = false 	--当前回合是否重连回合
end

function CUnit:InitUnit()
	--设置基础逃跑成功率
	local nBattleType = self.m_oBattle:GetType()
	if nBattleType == gtBTT.ePVP or nBattleType == gtBTT.eArena then
	    self.m_nRetreatBaseRate = 50
	else
	    self.m_nRetreatBaseRate = 70
	end

	--愤怒值固定80点
	if self:IsRole() then
		self:AddAttr(gtBAT.eNQ, 80, nil, "初始化愤怒值固定80点")
	end

	--竞技场默认手动
	if self.m_oBattle:IsArena() then 
		if self.m_oBattle:TeamFlag(self:GetUnitID()) == 1 then
			self.m_bAuto = false
		else
			self.m_bAuto = true
		end
	end

	--PVP
	if self.m_oBattle:IsPVP() and not self:IsRobot() then 
		self.m_bAuto = false
	end

	--机器人
	if self:IsRobot() then
		self.m_bAuto = true
	end

	--选择AI
	self:SelectAI()

	--被动技能
	local tPasSkillContext = self.m_oPasSkillHelper:OnEnterBattle(self)
	for nAttrID, nAttrVal in pairs(tPasSkillContext.tAttrAdd) do
		if nAttrID == gtBAT.eQXSX then --气血上限
			self.m_nMaxHP = self.m_nMaxHP + nAttrVal
			self.m_tBTData.nMaxHP = self.m_nMaxHP
			self:AddAttr(gtBAT.eQX, nAttrVal, nil, "进入战斗被动技能加成")
		else
			assert(self.m_tBattleAttr[nAttrID], "属性不存在:"..nAttrID)
			self:AddAttr(nAttrID, nAttrVal, nil, "进入战斗被动技能加成")
		end
	end

	--PVE机器人默认使用第1个获得的技能
	local tExtData = self.m_oBattle:GetExtData()
	if self:IsRobot() and self.m_oBattle:IsPVE() then
		local tSchoolSkillMap = {[1]=1111,[2]=1211,[3]=1311,[4]=1411,[5]=1511}
		local nSkillID = tSchoolSkillMap[self.m_nSchool]
		if nSkillID then
			if self.m_tActSkillMap[nSkillID] then
				self.m_nAutoInst = CUnit.tINST.eFS
		    	self.m_nAutoSkill = nSkillID
		    end
		end
	end
end

function CUnit:SelectAI()
	if self.m_oBattle:IsPVE() then
		local nBattleGroup = self.m_oBattle.m_nBattleGroup
		local nAIBattleType = ctBattleGroupConf[nBattleGroup].nAIBattleType
		if self.m_nObjType == gtObjType.ePartner then	
			assert(self.m_nSchool > 0, "伙伴没有配置门派:"..self.m_sObjName)
			local tAIConf = ctAIConf:GetAIByBattleTypeAndSchool(nAIBattleType, self.m_nSchool)
			self.m_nAI = tAIConf and tAIConf.nID or 0

		elseif self.m_nObjType == gtObjType.eMonster then
			self.m_nAI = 310 --怪物固定AI

		end
	end
	if self.m_oBattle:IsPVP() or self.m_oBattle:IsArena() then
		if self.m_nObjType == gtObjType.ePartner then	
			assert(self.m_nSchool > 0, "伙伴门派错误:"..self.m_sObjName)
			local tAIConf = ctAIConf:GetAIByBattleTypeAndSchool(gtBTT.ePVP, self.m_nSchool)
			self.m_nAI = tAIConf and tAIConf.nID or 0

		elseif self.m_nObjType == gtGDef.tObjType.eRole then
			if self:IsRobot() or (self.m_oBattle:IsArena() and self.m_nUnitID>200) then
				local tAIConf = ctAIConf:GetAIByBattleTypeAndSchool(gtBTT.ePVP, self.m_nSchool)
				self.m_nAI = tAIConf and tAIConf.nID or 0
			end

		elseif self.m_nObjType == gtObjType.ePet then
			local oMainUnit = self.m_oBattle:GetMainUnit(self.m_nUnitID)
			if (oMainUnit and oMainUnit:IsRobot()) or (self.m_oBattle:IsArena() and self.m_nUnitID>200) then
				self.m_nAI = 420 --竞技场/机器人宠物AI固定
			end

		elseif self.m_nObjType == gtObjType.eMonster then
			self.m_nAI = 310 --怪物固定AI

		end

	end

	if self.m_nAI > 0 then
		self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "选择了AI", self.m_nAI)
	end
end


function CUnit:Release()
	GetGModule("TimerMgr"):Clear(self.m_nAutoTimer)
	self.m_nAutoTimer = nil
	GetGModule("TimerMgr"):Clear(self.m_nLeaveTimer)
	self.m_nLeaveTimer = nil
end

function CUnit:IsAuto() return self.m_bAuto end
function CUnit:SetAuto(bAuto)  self.m_bAuto = bAuto end
function CUnit:IsReady() return (self.m_tInst.nInst or 0) > 0 end
function CUnit:IsDead() return self:GetAttr(gtBAT.eQX)<=0 end
function CUnit:IsLeave() return self.m_bLeave end
function CUnit:IsDeadOrLeave() return (self:IsDead() or self.m_bLeave) end
function CUnit:IsReconnectRound() return self.m_bReconnectRound end
function CUnit:SetReconnectRound(bReconnectRound) self.m_bReconnectRound = bReconnectRound end

--是否魅怪
function CUnit:IsGhost()
	if not self:IsMonster() then
		return
	end
	local tSubMonsterConf = ctSubMonsterConf[self:GetObjID()]
	return tSubMonsterConf.bGhost
end

--设置离开战斗
--@nExtTime 避免角色撤退时,仙侣宠物同时撤退,引起的顺序问题,正确的顺序应该是[宠物/仙侣->角色],因为角色撤退可能会引起对象释放
function CUnit:SetLeave(nExtTime) 
	nExtTime = nExtTime or 0
	self.m_bLeave = true
	GetGModule("TimerMgr"):Clear(self.m_nLeaveTimer)

	local nLeaveTime = self.m_oBattle:GetRoundActTime() + nExtTime
	if nLeaveTime <= 0 then
		self:OnLeave()
	else
		self.m_nLeaveTimer = GetGModule("TimerMgr"):Interval(nLeaveTime, function() self:OnLeave() end)
	end
end

function CUnit:GetUnitID() return self.m_nUnitID end
function CUnit:GetObjID() return self.m_nObjID end
function CUnit:GetObjType() return self.m_nObjType end
function CUnit:GetObjName() return self.m_sObjName end
function CUnit:GetSpouseID() return self.m_nSpouseID end --配偶ID
function CUnit:GetExp() return self.m_nExp end
function CUnit:GetModel() return self.m_sModel end
function CUnit:GetLevel() return self.m_nLevel end
function CUnit:GetRoleID() return self.m_nRoleID end

function CUnit:GetActSkillMap() return self.m_tActSkillMap end --角色主动技能或宠物主动技能表(不包括法宝技能)
function CUnit:GetFBSkillMap() return self.m_tFBSkillMap end --法宝技能表

function CUnit:GetActSkill(nSKID) return (self.m_tActSkillMap[nSKID] or self.m_tFBSkillMap[nSKID]) end
function CUnit:GetSkillConf(nSKID) return (ctSkillConf[nSKID] or ctPetSkillConf[nSKID] or ctFaBaoSkillConf[nSKID]) end
function CUnit:IsFBSkill(nSKID) return ctFaBaoSkillConf[nSKID] end

function CUnit:GetPasSkill(nSKID) return self.m_tPasSkillMap[nSKID] end
function CUnit:GetPasSkillMap() return self.m_tPasSkillMap end

function CUnit:GetBasePhyHitRate() return 100 end --物理基础命中
function CUnit:GetBasePhyDodgeRate() return (self:IsRole() and 10 or 5) end --物理基础闪避
function CUnit:GetBasePhyCritRate() return 3 end --物理基础暴击
function CUnit:GetBaseMagHitRate() return 100 end --法术基础命中
function CUnit:GetBaseMagDodgeRate() return 0 end --法术基础闪避
function CUnit:GetSchool() return self.m_nSchool end
function CUnit:GetAI() return self.m_nAI end

function CUnit:IsPet() return (self.m_nObjType == gtObjType.ePet) end
function CUnit:IsRole() return (self.m_nObjType == gtGDef.tObjType.eRole) end
function CUnit:IsMirror() return self.m_bMirror end
function CUnit:IsRealRole() return self.m_oBattle:IsRealRole(self) end
function CUnit:IsPartner() return (self.m_nObjType == gtObjType.ePartner) end
function CUnit:IsMonster() return (self.m_nObjType == gtObjType.eMonster) end
function CUnit:IsRobot() return self.m_bRobot end
function CUnit:IsSameTeam(nTarUnit) return self.m_oBattle:IsSameTeam(self:GetUnitID(), nTarUnit) end
function CUnit:GetPropUsed() return self.m_nPropUsed end
function CUnit:AddPropUsed() self.m_nPropUsed=self.m_nPropUsed+1 end
function CUnit:GetWeaponAtk() return self.m_nWeaponAtk end
function CUnit:GetPracticeMap() return self.m_tPracticeMap end
function CUnit:GetBuffMap() return self.m_tBuffMap end
function CUnit:GetAtkCount() return self.m_nAttackCount end
function CUnit:GetBeAtkCount() return self.m_nBeAttackedCount end
function CUnit:GetPetPos() return self.m_nPetPos end --宠物格子
function CUnit:GetPetMap() return self.m_tPetMap end
function CUnit:GetUnitPos()  --取单位位置
	local nTeamFlag = math.floor(self.m_nUnitID/100)
	local nPos = self.m_nUnitID-nTeamFlag*100
	return nPos
end

function CUnit:GetResAttrList() 
	local tResAttr = {}
	for k = gtBAD.eMinRAT, gtBAD.eMaxRAT do
		table.insert(tResAttr, self.m_tBattleAttr[k])
	end
	return tResAttr
end

function CUnit:GetAdvAttrList ()
	local tAdvAttr = {}
	for k = gtBAD.eMinAAT, gtBAD.eMaxAAT do
		table.insert(tAdvAttr, self.m_tBattleAttr[k])
	end
	return tAdvAttr
end

function CUnit:GetHideAttrList()
	local tHideAttr = {}
	for k = gtBAD.eMinHAT, gtBAD.eMaxHAT do
		table.insert(tHideAttr, self.m_tBattleAttr[k])
	end
	return tHidAttr
end

function CUnit:GetAttr(nType)
	return self.m_tBattleAttr[nType] or 0
end 

function CUnit:SetMaxHP(nMaxHP)
	self.m_nMaxHP = nMaxHP
end

function CUnit:MaxAttr(nType)
	if nType == gtBAT.eQX then --气血
		return self.m_nMaxHP
	end
	if nType == gtBAT.eMF then --魔法
		return self.m_nMaxMP
	end
	if nType == gtBAT.eNQ then --怒气
		return self.m_nMaxSP
	end
	return gtGDef.tConst.nMaxInteger
end

--气血比例
function CUnit:HPRatio()
	return self:GetAttr(gtBAT.eQX)/self:MaxAttr(gtBAT.eQX)
end

--魔法变化
function CUnit:OnMPChange(nVal, tParentAct)
	if not tParentAct then
		return
	end
	local tAct = {
		nAct = gtACT.eSS,
		nSrcUnit = self:GetUnitID(),
		nMP = nVal==0 and -1 or nVal, --MP飘字
		nHurt = -1, --HP飘字
		nCurrHP = self:GetAttr(gtBAT.eQX)==0 and -1 or self:GetAttr(gtBAT.eQX),
		nCurrSP = self:GetAttr(gtBAT.eNQ)==0 and -1 or self:GetAttr(gtBAT.eNQ),
		nCurrMP = self:GetAttr(gtBAT.eMF)==0 and -1 or self:GetAttr(gtBAT.eMF),
		nTime = GetActTime(gtACT.eSS),
		tReact = {}
	}
	self:AddReactAct(tParentAct, tAct, "MP变更")
end

--怒气变化
function CUnit:OnSPChange(nVal, tParentAct)
	if not tParentAct then
		return
	end
	local tAct = {
		nAct = gtACT.eSS, 
		nSrcUnit = self:GetUnitID(),
		nMP = -1, 	--MP飘字
		nHurt = -1, --HP飘字
		nCurrHP = self:GetAttr(gtBAT.eQX)==0 and -1 or self:GetAttr(gtBAT.eQX),
		nCurrSP = self:GetAttr(gtBAT.eNQ)==0 and -1 or self:GetAttr(gtBAT.eNQ),
		nCurrMP = self:GetAttr(gtBAT.eMF)==0 and -1 or self:GetAttr(gtBAT.eMF),
		nTime = GetActTime(gtACT.eSS),
		tReact = {},
	}
	self:AddReactAct(tParentAct, tAct, "SP变更")
end

--气血变化
function CUnit:OnHPChange(nVal, nOldAttr, tParentAct, oSrcUnit, bCrit, bDefense)
	if not tParentAct then
		return
	end
	local nHurt = math.abs(self:GetAttr(gtBAT.eQX)-nOldAttr)
	if nVal < 0 then
		--受伤增加SP(技能消耗不算)
		if self:IsRole() then
			local nSP = self:CalcNQ(nHurt)
			self:AddAttr(gtBAT.eNQ, nSP, nil, "受伤增加SP")
		end
		--记录总伤害
		local nTeamFlag = self.m_oBattle:EnemyFlag(self:GetUnitID())
		self.m_oBattle:AddTeamHurt(nTeamFlag, nHurt)
		--将死亡被动技能
		if self:IsDead() then
			self.m_oPasSkillHelper:OnPreDeadEvent(oSrcUnit, self)
		end
		--移除睡眠BUFF
		self:RemoveBuff(401, nil, "受伤移除BUFF")

	elseif nVal > 0 then
		if nOldAttr <= 0 then --复活
			local tAct = {
				nAct = gtACT.eFH,
				nSrcUnit = self:GetUnitID(),
				nMP = -1, --MP飘字
				nHurt = nVal == 0 and -1 or nVal, --HP飘字
				nCurrHP = self:GetAttr(gtBAT.eQX)==0 and -1 or self:GetAttr(gtBAT.eQX),
				nCurrSP = self:GetAttr(gtBAT.eNQ)==0 and -1 or self:GetAttr(gtBAT.eNQ),
				nCurrMP = self:GetAttr(gtBAT.eMF)==0 and -1 or self:GetAttr(gtBAT.eMF),
				nTime = GetActTime(gtACT.eFH),
				tReact = {},
			}
			self:AddReactAct(tParentAct, tAct, "复活")
			return

		else --治疗
			local tPasSkillContext = self.m_oPasSkillHelper:OnBeCure(self)
			local nExtVal = math.floor(nVal*(tPasSkillContext.tAttrAdd[gtBAT.eZLXG] or 0)*0.01)
			if nExtVal > 0 then
				self:AddAttr(gtBAT.eQX, nExtVal, nil, "光明被动技能")
				nHurt = nHurt + nExtVal
				nVal = nVal + nExtVal
			end

		end

	end

	--受伤/治疗动作
	local nAct = nVal>0 and gtACT.eZL or gtACT.eSS
	local tAct = {
		nAct = nAct,
		nSrcUnit = self:GetUnitID(),
		nMP = -1, --MP飘字
		nHurt = nVal == 0 and -1 or nVal, --HP飘字
		nCurrHP = self:GetAttr(gtBAT.eQX)==0 and -1 or self:GetAttr(gtBAT.eQX),
		nCurrSP = self:GetAttr(gtBAT.eNQ)==0 and -1 or self:GetAttr(gtBAT.eNQ),
		nCurrMP = self:GetAttr(gtBAT.eMF)==0 and -1 or self:GetAttr(gtBAT.eMF),
		bCrit = bCrit,
		bDefense = bDefense,
		nTime = GetActTime(nAct),
		tReact = {},
	}
	self:AddReactAct(tParentAct, tAct, "受伤/治疗")
	return tAct
end

function CUnit:AddAttr(nType, nVal, tParentAct, sFrom, oSrcUnit, bCrit, bDefense)
	if nType == gtBAT.eQX and nVal > 0 then
		if self:GetRoundFlag(CUnit.tRoundFlag.eGM) and self ~= oSrcUnit then --self==oSrcUnit 鬼魅复活允许加气血
			return self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "鬼魅禁止恢复气血操作")
		end
		if self:GetRoundFlag(CUnit.tRoundFlag.eIGNCS) then
			return self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "重生被禁止")
		end
	end

	local nMinVal = gtRatioAttr[nType] and -gtGDef.tConst.nMaxInteger or 0
	local nOldAttr = self.m_tBattleAttr[nType]

	self.m_tBattleAttr[nType] = math.min(self:MaxAttr(nType), math.max(nMinVal, self.m_tBattleAttr[nType]+nVal))

	self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName()
		, "增加属性", nType, nVal, self.m_tBattleAttr[nType]
		, (sFrom or ""), (bCrit and "暴击" or ""), (bDefense and "防御" or ""))

	--标记速度改变	
	if nType == gtBAT.eSD then
		self:AddRoundFlag(CUnit.tRoundFlag.eSPC, 0, {})

	--魔法相关处理
	elseif nType == gtBAT.eMF then
		self:OnMPChange(nVal, tParentAct)

	--怒气相关处理
	elseif nType == gtBAT.eNQ then
		self:OnSPChange(nVal, tParentAct)

	--气血相关处理
	elseif nType == gtBAT.eQX then
		local tAct = self:OnHPChange(nVal, nOldAttr, tParentAct, oSrcUnit, bCrit, bDefense)
		--死亡判断
		if nVal < 0 and self:IsDead() then
			self:OnDead(tAct, oSrcUnit)
		end
		return tAct 

	end
end

function CUnit:IsInstMiss() return self.m_tInst.bMiss end
function CUnit:IsChangeShape() return self:HasBuff(120) end

function CUnit:IsProtected()
	local tDataMap = self:GetRoundFlag(CUnit.tRoundFlag.ePTD)
	if tDataMap then
		local _, tData = next(tDataMap)
		return tData.nUnitID
	end
	return 0
end

function CUnit:IsCounterAttack()
	local tDataMap = self:GetRoundFlag(CUnit.tRoundFlag.eCOT)
	if tDataMap then
		local _, tData = next(tDataMap)
		return tData
	end
end


function CUnit:GetRoundFlag(nFlag)
	return self.m_tRoundFlag[nFlag]
end
function CUnit:AddRoundFlag(nFlag, nSrcID, tData)
	nSrcID = nSrcID or 0
	local tRoundFlag = self:GetRoundFlag(nFlag) or {}
	tRoundFlag[nSrcID] = tData
	self.m_tRoundFlag[nFlag] = tRoundFlag
end
function CUnit:RemoveRoundFlag(nFlag, nSrcID)
	nSrcID = nSrcID or 0
	if nSrcID == 0 then --移除所有
		self.m_tRoundFlag[nFlag] = nil
	else --移除指定
		local tRoundFlag = self:GetRoundFlag(nFlag)
		if tRoundFlag and tRoundFlag[nSrcID] then
			tRoundFlag[nSrcID] = nil
			if not next(tRoundFlag) then
				self.m_tRoundFlag[nFlag] = nil
			end
		end
	end
end

function CUnit:IsLockAction(nInst, nSkillID)
	--禁止所有行动
	if self:GetRoundFlag(CUnit.tRoundFlag.eLCK) then
		return true
	end
	--禁止法术
	if nInst == CUnit.tINST.eFS then
		if self:IsFBSkill(nSkillID) then
			return self:GetRoundFlag(CUnit.tRoundFlag.eLCKTJ)
		end
		return self:GetRoundFlag(CUnit.tRoundFlag.eLCKFS)
	end
	--禁止物攻
	if nInst == CUnit.tINST.eGJ and self:GetRoundFlag(CUnit.tRoundFlag.eLCKGJ) then
		return true
	end
	--禁止撤退
	if nInst == CUnit.tINST.eCT and self:GetRoundFlag(CUnit.tRoundFlag.eLCKCT) then
		return true
	end
end

--单位信息
function CUnit:GetInfo()
	local tInfo = {
		nUnitID = self:GetUnitID()
		, nObjID = self:GetObjID()
		, nObjType = self:GetObjType()
		, sObjName = self:GetObjName()
		, nLevel = self:GetLevel()
		, tResAttr = self:GetResAttrList()
		, tAdvAttr = self:GetAdvAttrList()
		, tHidAttr = self:GetHideAttrList()
		, sModel = self:GetModel()
		, nMaxHP = self:MaxAttr(gtBAT.eQX)
		, nMaxMP = self:MaxAttr(gtBAT.eMF)
		, nMaxSP = self:MaxAttr(gtBAT.eNQ)
		, bAuto = self:IsAuto()
		, tBuffList = self:GetBuffList()
		, nAutoInst = self.m_nAutoInst
		, nAutoSkill = self.m_nAutoSkill
		, nWeaponID = self.m_nWeaponID
		, nSchool = self.m_nSchool
		, nArtifactID = self.m_nArtifactID
		, sGrade = self.m_sGrade
		, nCmdID = self.m_nCmdID
		, sCmdName = self.m_sCmdName
		, nArtifactLevel = self.m_nArtifactLevel
		, nParentID = self:GetRoleID()
	}
	if self:IsPet() and not self:IsMirror() then	
		tInfo.nPetExp = self.m_tBTData.nExp
		tInfo.nPetNextExp = self.m_tBTData.nNextExp
	end
	return tInfo
end

--战斗指挥界面BUFF列表
function CUnit:GetCommandBuffList()
	local tBuffList = {}
	for nType, tBuffMap in pairs(self.m_tBuffMap) do
		for nBuffID, oBuff in pairs(tBuffMap) do
			local tConf = oBuff:GetConf()
			if tConf.bCommand then
				local tInfo = {
					nID = nBuffID,	
					sName = tConf.sName,
					nType = tConf.nType,
					sDesc =  tConf.sDesc,
					nRounds = oBuff:RemainRounds(),
				}
				table.insert(tBuffList, tInfo)
			end
		end
	end
	return tBuffList
end

--战斗指挥界面信息
function CUnit:GetCommandInfo(oReqUnit)
	local nReqUnitID = oReqUnit:GetUnitID()
	local bSameTeam = self:IsSameTeam(nReqUnitID)

	local tInfo = {
		nUnitID = self:GetUnitID(),
		nLevel = self:GetLevel(),
		sName = self:GetObjName(),
		nSchool = self:GetSchool(),
		nCurrHP = bSameTeam and self:GetAttr(gtBAT.eQX) or 0,
		nMaxHP = bSameTeam and self:MaxAttr(gtBAT.eQX) or 0,
		nCurrMP = bSameTeam and self:GetAttr(gtBAT.eMF) or 0,
		nMaxMP = bSameTeam and self:GetAttr(gtBAT.eMF) or 0,
		tBuffList = self:GetCommandBuffList(),
		tFmtInfo = self.m_oBattle:GetCommandFmtInfo(self),
	}
	return tInfo
end

--设置战斗指挥
function CUnit:SetCommand(nID, sName)
	if self.m_nCmdID == nID and self.m_sCmdName == sName then	
		return
	end
	self.m_nCmdID = nID
	self.m_sCmdName = sName
	return true
end

--取战斗指挥
function CUnit:GetCommand()
	return self.m_nCmdID, self.m_sCmdName
end

--取技能信息
function CUnit:GetSkillInfo(nSkill)
	local tSkill = self:GetActSkill(nSkill)
	if not tSkill then
		return LuaTrace("技能不存在:", nSkill)
	end

	local nLevel = tSkill.nLevel
	local tSkillConf = self:GetSkillConf(nSkill)
	local nLearnLevel = tSkillConf.nLearn or 999

	local bValid, sTips, sConsumeTips = true, "", ""
	if not self:IsFBSkill(nSkill) then
		bValid, sTips, sConsumeTips = self.m_oSkillHelper:CanLaunch(self, nSkill, true)
	else
		bValid, sTips, sConsumeTips = self.m_oFBSkillHelper:CanLaunch(self, nSkill)
	end
	sTips = sTips or ""
	sConsumeTips = sConsumeTips or ""

	local tInfo = {nID=nSkill, nLevel=nLevel, sName=tSkill.sName, bValid=bValid, sTips=sTips, nLevel=nLevel, nLearnLevel=nLearnLevel, sConsumeTips=sConsumeTips}
	return tInfo
end

--取预加载的技能ID列表
function CUnit:GetPreloadSkillList()
	local tSkillList = {}
	for nSkill, tSkill in pairs(self.m_tActSkillMap) do
		table.insert(tSkillList, nSkill)
	end
	for nSkill, tSkill in pairs(self.m_tFBSkillMap) do
		table.insert(tSkillList, nSkill)
	end
	return tSkillList
end


--取上次使用技能
function CUnit:GetManualSkill()
	local nRoleManualSkill = self.m_nManualSkill
	local oPetUnit = self.m_oBattle:GetSubUnit(self:GetUnitID())
	local nPetManualSkill = oPetUnit and oPetUnit.m_nManualSkill or 0

	local tRoleManualSkill = {nID=0}
	if nRoleManualSkill > 0 then
		tRoleManualSkill = self:GetSkillInfo(nRoleManualSkill)
	end
	local tPetManualSkill = {nID=0}
	if nPetManualSkill > 0 then
		tPetManualSkill = oPetUnit:GetSkillInfo(nPetManualSkill)
	end
	return tRoleManualSkill, tPetManualSkill
end

--清理非永久的辅助标记
function CUnit:ClearTmpRoundFlag()
	for k, v in pairs(self.m_tRoundFlag) do
		for nKey, tVal in pairs(v) do
			if not tVal.bPermernent then
				self:RemoveRoundFlag(k, nKey)
			end
		end
	end
end

--回合准备事件
function CUnit:OnRoundPrepare(nRound, nMainTime, bReconnect)
    assert(not self:IsLeave(), "单位已离开")

    if not bReconnect then
	    self.m_tInst = {nInst=0, nTarUnit=0}
	    self:ClearTmpRoundFlag()

	    self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), string.format("第%d回合准备时数据:", nRound)
	    	, self.m_tBTData, self.m_tInst, self:GetBuffList())
	end

    --自动缓冲(3s)
    if self:IsAuto() then
    	if self:IsRole() then
	    	GetGModule("TimerMgr"):Clear(self.m_nAutoTimer)
	    	local nAutoTime = math.max(1, math.min(3, nMainTime))
	    	self.m_nAutoTimer = GetGModule("TimerMgr"):Interval(nAutoTime, function() self:OnAutoTimer() end)

	    	if self:IsRealRole() then
		    	local tRoleManualSkill, tPetManualSkill = self:GetManualSkill()
	    		local tMsg = {
		    		nRound=self.m_oBattle:GetRound(),
		    		nMainTime=nMainTime,
		    		nAutoTime=nAutoTime,
		    		bAuto=true,
		    		tRoleManualSkill=tRoleManualSkill,
		    		tPetManualSkill=tPetManualSkill,
		    	}
				self.m_oBattle:SendMsg("RoundBeginRet", tMsg, self)
			end

		elseif not self:IsPet() then
    		self:OnAutoTimer()

    	end

    --非自动
    else
    	if self:IsRole() then
    		if self:IsRealRole() then
		    	local tRoleManualSkill, tPetManualSkill = self:GetManualSkill()
	    		local tMsg = {
	    			nRound=self.m_oBattle:GetRound(),
	    			nMainTime=nMainTime,
	    			nAutoTime=0,
	    			bAuto=false,
	    			tRoleManualSkill=tRoleManualSkill,
	    			tPetManualSkill=tPetManualSkill,
	    		}
				self.m_oBattle:SendMsg("RoundBeginRet", tMsg, self)
			end

		elseif not self:IsPet() then
			self:OnAutoTimer()

		end

    end
end

--自动缓冲到时
function CUnit:OnAutoTimer()
	GetGModule("TimerMgr"):Clear(self.m_nAutoTimer)
	self.m_nAutoTimer = nil
	self:EnterAuto()
end

--回合结束事件
function CUnit:OnRoundEnd(nRound)
end

--计算怒气
function CUnit:CalcNQ(nHurt)
	nHurt = math.abs(nHurt)
	local nPercent = (nHurt/self.m_nMaxHP)*100
	if nPercent >= 80 then
		return 60
	elseif nPercent >= 50 then
		return 50
	elseif nPercent >= 30 then
		return 40
	elseif nPercent >= 20 then
		return 30
	elseif nPercent >= 10 then
		return 20
	elseif nPercent >= 3 then
		return 10
	else
		return 2
	end
end

--死亡
function CUnit:OnDead(tParentAct, oSrcUnit)
	self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "死亡")

	--清空怒气值
	self:AddAttr(gtBAT.eNQ, -gtGDef.tConst.nMaxInteger, nil, "死亡清空SP")

	local tDeadAct
	--添加死亡动作
	if tParentAct then
		tDeadAct = {
			nAct = gtACT.eSW,
			nSrcUnit = self:GetUnitID(),
			nCurrHP = self:GetAttr(gtBAT.eQX),
			nCurrMP = self:GetAttr(gtBAT.eMF),
			nCurrSP = self:GetAttr(gtBAT.eNQ),
			bLeave = false,
			nTime = GetActTime(gtACT.eSW),
			tReact = {},
		}
		self:AddReactAct(tParentAct, tDeadAct, "死亡动作")
		self.m_oPasSkillHelper:OnDeadEvent(oSrcUnit, self, tDeadAct)
	end

	--是否离开
	local bLeave = false
	if (self:IsMonster() or self:IsPet()) and self:IsDead() then
		if not self:GetRoundFlag(CUnit.tRoundFlag.eGM) or oSrcUnit:GetRoundFlag(CUnit.tRoundFlag.eIGNGM) then
		--鬼魅禁止离开
			bLeave = true
		elseif self:GetRoundFlag(CUnit.tRoundFlag.eGM) then
		--鬼魅死亡回合记录
			local oBuff = self:GetBuff(1901) or self:GetBuff(901)
			if oBuff then
				oBuff:SetDeadRound(self.m_oBattle:GetRound())
			end
		end
		--只触发一次
		self:RemoveRoundFlag(CUnit.tRoundFlag.eIGNGM, 0)
	end
	if tDeadAct then
		tDeadAct.bLeave = bLeave
	end

	--设置离开
	if bLeave then
		self:SetLeave()

		--设置子怪死亡回合(召唤子怪技能可能用到)
		if self:IsMonster() and self:GetUnitPos()>=6 then
			local oMainUnit = self.m_oBattle:GetMainUnit(self:GetUnitID())
			if oMainUnit and oMainUnit:IsMonster() then
				oMainUnit:OnSubMonsterDeadLeave(oMainUnit:GetObjID(), self.m_oBattle:GetRound())
			end
		end
	else
		self:DeadClearBuff(tDeadAct)
	end

	--镇妖摄魂判断
	if self.m_oBattle:GetExtData().nBattleDupType == gtBattleDupType.eZhenYao and tDeadAct then
		if oSrcUnit and self:IsMonster() then
			local tTeamMap = self.m_oBattle:GetTeam(oSrcUnit:GetUnitID())
			for _, oUnit in pairs(tTeamMap) do
				if oUnit:IsRealRole() and not oUnit:IsLeave() then
					local oRole = goPlayerMgr:GetRoleByID(oUnit:GetObjID())
					local bActive, tSubItem, tCurItem, tAward, tCurItem1 = oRole.m_oDrawSpirit:BattleTrigger()
					if bActive then
						local tSHAct1 = {
							nAct = gtACT.eSH1,
							nSrcUnit = oUnit:GetUnitID(),
							tTarUnit = { self:GetUnitID() },
							tSubItem = tSubItem, --扣除物品
							tCurItem = tCurItem, --扣除后当前物品
							nTime = GetActTime(gtACT.eSH1),
						}
						self:AddReactAct(tDeadAct, tSHAct1, "摄魂扣除")

						local tSHAct2 = {
							nAct = gtACT.eSH2,
							nSrcUnit = oUnit:GetUnitID(),
							tTarUnit = { self:GetUnitID() },
							tAward = tAward, 		--奖励物品
							tCurItem = tCurItem1,	--奖励后当前物品
							nTime = GetActTime(gtACT.eSH2),
						}
						self:AddReactAct(tDeadAct, tSHAct2, "摄魂奖励")
					end
				end
			end
		end
	end

	--死亡事件
	self.m_oBattle:OnUnitDead(self)
end

--进入自动
function CUnit:EnterAuto()
	self:SetAuto(true)

	--处理自己
	if not self:IsReady() then
		if self:GetAI() > 0 then --AI
			local tAIInfo = self.m_oAIHelper:DoAI(self)
			self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "AI决策", self.m_tInst, tAIInfo)
			if tAIInfo.nInst == CUnit.tINST.eGJ then
				self:SetInst(CUnit.tINST.eGJ, tAIInfo.nTarUnit)
			elseif tAIInfo.nInst == CUnit.tINST.eFS then
				self:SetInst(tAIInfo.nInst, tAIInfo.nTarUnit, tAIInfo.nSkill)
			elseif tAIInfo.nInst == CUnit.tINST.eFY then
				self:SetInst(tAIInfo.nInst)
			elseif tAIInfo.nInst == CUnit.tINST.eZH then
				self:SetInst(tAIInfo.nInst, tAIInfo.nPosID)
			else
				assert(false, "AI错误")
			end
		else
			if self.m_nAutoInst == 0 then
				local oTarUnit = self.m_oSelectHelper:RandEnemys(self, 1)[1]
				local nTarUnitID = oTarUnit and oTarUnit:GetUnitID() or 0
				self:SetInst(CUnit.tINST.eGJ, nTarUnitID)

			elseif self.m_nAutoInst == CUnit.tINST.eGJ then
				self:SetInst(self.m_nAutoInst, 0)

			elseif self.m_nAutoInst == CUnit.tINST.eFY then
				self:SetInst(self.m_nAutoInst)

			elseif self.m_nAutoInst == CUnit.tINST.eFS then
				if self.m_nAutoSkill <= 0 then
					LuaTrace("自动技能错误", self:GetUnitID(), self:GetObjName(), self.m_nManualInst, self.m_nManualSkill)
					self:SetInst(CUnit.tINST.eGJ, 0)
				else
					self:SetInst(self.m_nAutoInst, 0, self.m_nAutoSkill)
				end

			end
		end
	end

	--处理玩家宠物
	if self:IsRole() then
		local oPetUnit = self.m_oBattle:GetSubUnit(self:GetUnitID())
		if oPetUnit and not oPetUnit:IsReady() then
			oPetUnit:OnAutoTimer()
		end
		local tMsg = {nInst=CUnit.tINST.eZD, nUnitID=self:GetUnitID(), bAuto=true}
		self.m_oBattle:SendMsg("UnitInstRet", tMsg, self)
		self.m_oBattle:SyncCurrAutoInst(self)
	end
end

--------------------下达指令------------------
--下达指令
function CUnit:SetInst(nInst, ...)
	self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "下达指令", nInst, ...)

	if nInst ~= CUnit.tINST.eZD then
		if self.m_tInst.nInst ~= 0 then
			self.m_oBattle:Tips(self, "已经下达过指令")
			self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "已经下达过指令了")
			return
		end
	end

	local sFunc = CUnit.tInstFunc[nInst][1]
	local fnSet = CUnit[sFunc]
	if not fnSet(self, ...) then
		return self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "下达指令失败", nInst, ...)
	end

	if nInst ~= CUnit.tINST.eZD and self.m_tInst.nInst ~= 0 then
		self.m_nManualInst = nInst
		self.m_oBattle:Broadcast("UnitInstRet", {nUnitID=self:GetUnitID(), nInst=nInst})
		self.m_oBattle:OnUnitReady(self.m_nUnitID)
	end
end

--取指令
function CUnit:GetInst()
	return self.m_tInst
end

--替换指令
function CUnit:ReplaceInst(nInst, ...)
	self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "替换指令", self.m_tInst.nInst.."->"..nInst)
	local sFunc = CUnit.tInstFunc[nInst][1]
	local fnSet = CUnit[sFunc]
	if not fnSet(self, ...) then
		return self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "替换指令失败", nInst)
	end
	self.m_nManualInst = nInst
	return true
end

--下达法术指令
function CUnit:FSInst(nTarUnit, nSkill, nBuffID)
	local tSkill = self:GetActSkill(nSkill)
	if not tSkill then
		return self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "技能不存在", nSkill)
	end
	if nTarUnit > 0 and not self.m_oSelectHelper:CheckSkillTarget(self, nSkill, nTarUnit) then
		return self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "技能目标错误", nSkill)
	end
	self.m_tInst = {nInst=CUnit.tINST.eFS, nSkill=nSkill, nTarUnit=nTarUnit, nBuffID=nBuffID}
	return true
end

--下达攻击指令
function CUnit:GJInst(nTarUnit, sTips)
	if nTarUnit > 0 then
		local oTarUnit = self.m_oBattle:GetUnit(nTarUnit)
		if not oTarUnit or oTarUnit:IsDeadOrLeave() then
			self.m_oBattle:Tips(self, "目标不存在或已死亡")
			self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "普通攻击目标不存在或已死亡:", nTarUnit)
			return 
		end
	end
	self.m_tInst = {nInst=CUnit.tINST.eGJ, nTarUnit=nTarUnit, sTips=sTips}
	return true
end

--取剩余可使用物品次数
function CUnit:RemainPropTimes()
	local nMaxProps = 10
	local oRoleUnit = self
	if self:IsPet() then
		oRoleUnit = self.m_oBattle:GetMainUnit(self:GetUnitID())
	end
	if not oRoleUnit:IsRealRole() then
		return 0, oRoleUnit
	end
	local nPropUsed = oRoleUnit:GetPropUsed()
	return (nMaxProps-nPropUsed), oRoleUnit
end

--下达物品指令
function CUnit:WPInst(nTarUnit, nGridID)
	assert(self:IsRole() or self:IsPet(), "指令请求单元错误")
	local nRemainProps, oRoleUnit = self:RemainPropTimes()
	if nRemainProps <= 0 then
		return self.m_oBattle:Tips(oRoleUnit, "每场战斗只能使用10个药品")
	end

	local oRole = goPlayerMgr:GetRoleByID(oRoleUnit:GetObjID())
	if not oRole then
		return
	end

	local oProp = oRole.m_oKnapsack:GetItem(nGridID)
	if not oProp or oProp:GetNum() <= 0 then
		return self.m_oBattle:Tips(oRoleUnit, "药品不存在")
	end

	local oTarUnit = self.m_oBattle:GetUnit(nTarUnit)
	if not self.m_oPropHelper:CheckTarget(oProp, self, oTarUnit) then
		return
	end
	self.m_tInst = {nInst=CUnit.tINST.eWP, nTarUnit=nTarUnit, nPropKey=oProp:GetKey()}
	return true
end

--取剩下可已出战宠物数
function CUnit:GetRemainPet()
	local nMaxPet = 5
    return (nMaxPet-self.m_nPetCalled)
end

--下达召唤令
function CUnit:ZHInst(nPosID)
	assert(self:IsRole())
	local nRemainPet = self:GetRemainPet()
	if nRemainPet <= 0 then
		return self.m_oBattle:Tips(self, "没有可召唤宠物")
	end
	local tPetData = self.m_tPetMap[nPosID]
	if not tPetData or tPetData.bUsed then
		return self.m_oBattle:Tips(self, "宠物不存在或者已出战")
	end
	self.m_tInst = {nInst=CUnit.tINST.eZH, nPetID=tPetData.nObjID, nPosID=nPosID}
	return true
end

--下达/取消自动指令
function CUnit:ZDInst(bAuto)
	assert(self:IsRole(), "单位类型错误")
	local oPetUnit = self.m_oBattle:GetSubUnit(self:GetUnitID())

	if bAuto then --自动
		self.m_oBattle:WriteLog("进入自动****")
		if self:IsAuto() then
			assert(not oPetUnit or oPetUnit:IsAuto(), "人物宠物自动不同步")
			return true
		end

		if oPetUnit then	
			--进入自动默认用上次的指令: 攻击,法术,防御
			if table.InArray(oPetUnit.m_nManualInst, CUnit.tAutoInst) then
				oPetUnit.m_nAutoInst = oPetUnit.m_nManualInst
				oPetUnit.m_nAutoSkill = oPetUnit.m_nManualSkill
			end
			oPetUnit:OnAutoTimer()
		end
		--进入自动默认用上次的指令: 攻击,法术,防御
		if table.InArray(self.m_nManualInst, CUnit.tAutoInst) then
			self.m_nAutoInst = self.m_nManualInst
			self.m_nAutoSkill = self.m_nManualSkill
		end
		self:OnAutoTimer()	
		self.m_oBattle:SyncCurrAutoInst(self)

	else --取消
		self.m_oBattle:WriteLog("取消自动****")
		if not self:IsAuto() then
			assert(not oPetUnit or not oPetUnit:IsAuto(), "人物宠物自动不同步")
			return true
		end

		self:SetAuto(false)
		if oPetUnit then
			oPetUnit:SetAuto(false)
		end

		if self:IsReady() then
			self.m_oBattle:Tips(self, "下回合开始时显示操作菜单")
		else
			GetGModule("TimerMgr"):Clear(self.m_nAutoTimer)
			self.m_nAutoTimer = nil
		end
		self.m_oBattle:SendMsg("UnitInstRet", {nInst=CUnit.tINST.eZD, nUnitID=self:GetUnitID(), bAuto=bAuto}, self)
	end
	return true
end

--下达防御指令
function CUnit:FYInst()
	self.m_tInst = {nInst=CUnit.tINST.eFY}
	return true
end

--下达保护指令
function CUnit:BHInst(nTarUnit)
	assert(self:IsSameTeam(nTarUnit) and nTarUnit ~= self.m_nUnitID, "目标错误")
	self.m_tInst = {nInst=CUnit.tINST.eBH, nTarUnit=nTarUnit}
	return true
end

--下达捕捉指令
function CUnit:BZInst()
end

--下达撤退指令
function CUnit:CTInst()
	self.m_tInst = {nInst=CUnit.tINST.eCT}
	return self.m_tInst
end

--计算速度
function CUnit:CalcSpeed()
	local nSpeed = self:GetAttr(gtBAT.eSD)
	if not self:IsMonster() then --NPC不随机
		nSpeed = nSpeed * math.random(90, 110) * 0.01
	end
	local nInst = self.m_tInst.nInst
	if nInst == CUnit.tINST.eFY then --防御
		nSpeed = nSpeed * 10
	elseif nInst == CUnit.tINST.eBH then --保护
		nSpeed = nSpeed * 10
	elseif nInst == CUnit.tINST.eZH then --召唤
		nSpeed = nSpeed * 1.2
	elseif nInst == CUnit.tINST.eWP then --物品
		nSpeed = nSpeed * 1.2
	elseif nInst == CUnit.tINST.eBZ then --捕捉
		nSpeed = nSpeed * math.random(100, 500) * 0.01
	end
	return nSpeed
end

--添加反馈指令
function CUnit:AddReactAct(tParentAct, tReactAct, sFrom, bFront)
	self.m_oBattle:AddReactActTime(tParentAct, tReactAct, sFrom, bFront)
end

--------------------执行指令------------------
--某指令是否已执行
function CUnit:IsInstExed(nInst)
	if self.m_tInst.nInst == nInst and self.m_tInst.bExed then
		return true
	end
end

--执行指令
function CUnit:ExecInst()
	self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "执行指令", self.m_tInst)
	assert(self.m_tInst.nInst > 0, "没有下达指令")

	if self:IsLeave() then
		return self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "已离开战场", self.m_tInst)
	end

	if self:IsLockAction(self.m_tInst.nInst, self.m_tInst.nSkill) then
		return self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "BUFF禁止行动", self.m_tInst)
	end

	--不会错过的指令表
	if self:IsDead() and not table.InArray(self.m_tInst.nInst, CUnit.tNoMissInst) then
		self.m_tInst.bMiss = true
		self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "死亡错过指令", self.m_tInst)

	else
		--强迫防御
		if self:GetRoundFlag(CUnit.tRoundFlag.eONLYFY) and not self:GetRoundFlag(CUnit.tRoundFlag.eIGNQP)then
			self:ReplaceInst(CUnit.tINST.eFY)
		--混乱
		elseif self:GetRoundFlag(CUnit.tRoundFlag.eCONFUSE) then
			local oTarUnit = self.m_oSelectHelper:RandAny(self)
			if oTarUnit then
				self:ReplaceInst(CUnit.tINST.eGJ, oTarUnit:GetUnitID())
			end
		end
		local sFunc = CUnit.tInstFunc[self.m_tInst.nInst][2]
		local fnExec = CUnit[sFunc]
		self.m_tInst.bMiss = false
		return fnExec(self)

	end
end

--执行法术指令
function CUnit:FSExec()
	self.m_tInst.bExed = true
	if self:IsFBSkill(self.m_tInst.nSkill) then
		self.m_oFBSkillHelper:ExecSkill(self, self.m_tInst.nSkill)
	else
	    self.m_nManualSkill = self.m_tInst.nSkill
		self.m_oSkillHelper:ExecSkill(self, self.m_tInst.nSkill)
	end
	return true
end

--执行攻击指令(物理)
function CUnit:GJExec()
	local nTarUnit = self.m_tInst.nTarUnit
	local oTarUnit = self.m_oBattle:GetUnit(nTarUnit)
	if not oTarUnit or oTarUnit:IsDeadOrLeave() or not self:HideAtkCheck(oTarUnit) then
		oTarUnit = self.m_oSelectHelper:RandEnemys(self, 1)[1] 
		if not oTarUnit then
			return
		end
		nTarUnit = oTarUnit:GetUnitID()
		self.m_tInst.nTarUnit = nTarUnit
	end
	self.m_tInst.bExed = true	

	local tGJAct = {
		nAct = gtACT.eGJ,
		nSrcUnit = self:GetUnitID(),
		tTarUnit = {nTarUnit},
		sTips = self.m_tInst.sTips,
		nTime = GetActTime(gtACT.eGJ),
		tReact = {},
	}

	local tPasSkillContext = self.m_oPasSkillHelper:OnNormalPhyAtk(self, oTarUnit)
	if tPasSkillContext then
		local nAtkTimes = 1
		if tPasSkillContext.bDoubleHit then
			nAtkTimes = 2
			tGJAct.sGJTips = "物理连击"
		end
		for k = 1, nAtkTimes do --连击被动技能
			if not oTarUnit:IsDeadOrLeave() and not self:IsDeadOrLeave() then --对方死亡/离开
				if k == 2 then
					tPasSkillContext.tAttrAdd[gtBAT.eWLSH] = (tPasSkillContext.tAttrAdd[gtBAT.eWLSH] or 0) + tPasSkillContext.nDoubleHitHurt
				end
				self:PhyAtk(oTarUnit, tGJAct, nil, tPasSkillContext)
			end
		end

		--追击判定
		local nPursuitSkill = 0
		if self.m_tPasSkillMap[5204] then
			nPursuitSkill = 5204
		elseif self.m_tPasSkillMap[5104] then
			nPursuitSkill = 5104
		end
		if nPursuitSkill > 0 then
			tPasSkillContext = self.m_oPasSkillHelper:SingleSkillCheck(nPursuitSkill, CPasSkillHelper.tTriggerType.eNorPhyAtk, self, oTarUnit, tPasSkillContext)

			if tPasSkillContext.bPursuit then
				tPasSkillContext.tAttrAdd[gtBAT.eWLSH] = (tPasSkillContext.tAttrAdd[gtBAT.eWLSH] or 0) - tPasSkillContext.nDoubleHitHurt + tPasSkillContext.nPursuitHurt
				local oNewTarUnit = self.m_oSelectHelper:RandEnemys(self, 1)[1] 
				if oNewTarUnit then
					local tZJAct = {
						nAct = gtACT.eGJ,
						nSrcUnit = self:GetUnitID(),
						tTarUnit = {oNewTarUnit:GetUnitID()},
						sTips = self.m_tInst.sTips,
						nTime = GetActTime(gtACT.eGJ),
						sGJTips = "物理追击",
						tReact = {},
					}
					self:PhyAtk(oNewTarUnit, tZJAct, nil, tPasSkillContext)
					self:AddReactAct(tGJAct, tZJAct, "追击")
				end
			end
			self.m_oBattle:AddRoundAction(tGJAct, "物攻")
		else
			self.m_oBattle:AddRoundAction(tGJAct, "物攻")
		end
	else
		self:PhyAtk(oTarUnit, tGJAct)
		self.m_oBattle:AddRoundAction(tGJAct, "物攻")
	end
	return true
end

--计算物攻B类系数
function CUnit:CalcPhyBRatio(oTarUnit, tPasSkillContext)
	tPasSkillContext = tPasSkillContext or table.DeepCopy(CPasSkillHelper.tPasSkillContext)

	--阵法
	local nFmtSrcSH = self:GetAttr(gtBAT.eWLSH)
	local nFmtTarSS = oTarUnit:GetAttr(gtBAT.eWLSS)

	--被动技能
	local nPasSkillSH = tPasSkillContext.tAttrAdd[gtBAT.eWLSH] or 0

	--BUFF
	local nBuffSrcSH = 0
	local nBuffTarSS = 0
	for nType, tBuffMap in pairs(self.m_tBuffMap) do
		for nID, oBuff in pairs(tBuffMap) do
			nBuffSrcSH = nBuffSrcSH + oBuff:GetBuffAttr(gtBAT.eWLSH)
		end
	end
	
	local tTarBuffMap = oTarUnit:GetBuffMap()
	for nType, tBuffMap in pairs(tTarBuffMap) do
		for nID, oBuff in pairs(tBuffMap) do
			nBuffTarSS = nBuffTarSS + oBuff:GetBuffAttr(gtBAT.eWLSS)
		end
	end
	return (nFmtSrcSH+nFmtTarSS+nBuffSrcSH+nBuffTarSS+nPasSkillSH)
end

--计算法攻B类系数
function CUnit:CalcMagBRatio(oTarUnit, tPasSkillContext)
	tPasSkillContext = tPasSkillContext or table.DeepCopy(CPasSkillHelper.tPasSkillContext)

	--阵法
	local nFmtSrcSH = self:GetAttr(gtBAT.eFSSH)
	local nFmtTarSS = oTarUnit:GetAttr(gtBAT.eFSSS)

	--被动技能
	local nPasSkillSH = tPasSkillContext.tAttrAdd[gtBAT.eFSSH] or 0

	--BUFF
	local nBuffSrcSH = 0
	local nBuffTarSS = 0
	for nType, tBuffMap in pairs(self.m_tBuffMap) do
		for nID, oBuff in pairs(tBuffMap) do
			nBuffSrcSH = nBuffSrcSH + oBuff:GetBuffAttr(gtBAT.eFSSH)
		end
	end

	local tTarBuffMap = oTarUnit:GetBuffMap()
	for nType, tBuffMap in pairs(tTarBuffMap) do
		for nID, oBuff in pairs(tBuffMap) do
			nBuffTarSS = nBuffTarSS + oBuff:GetBuffAttr(gtBAT.eFSSS)
		end
	end

	return (nFmtSrcSH+nFmtTarSS+nBuffSrcSH+nBuffTarSS+nPasSkillSH)
end

--计算物理命中
function CUnit:CalcPhyHit(oTarUnit, tSkillAttrAdd, tPasSkillContext)
	local nSkillHitRate =  tSkillAttrAdd.nSkillHitRate or 0
	local nBaseHitRate = nSkillHitRate>0 and nSkillHitRate or self:GetBasePhyHitRate()
	local nSrcMZL = nBaseHitRate + self:GetAttr(gtBAT.eMZL) --命中率
	local nTarSBL = oTarUnit:GetBasePhyDodgeRate()+oTarUnit:GetAttr(gtBAT.eSBL) --闪避率
	local bHit = math.random(1,100) <= math.max(20, math.min(100, (nSrcMZL-nTarSBL)))
	return bHit
end

--计算物理暴击
function CUnit:CalcPhyCrit(oTarUnit)
	if oTarUnit:GetRoundFlag(CUnit.tRoundFlag.eIGNBJ) then
		return self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "BUFF禁止物理暴击")
	end
	local nSrcBJL = self:GetBasePhyCritRate()+self:GetAttr(gtBAT.eBJL) --暴击率
	local nTarKBL = oTarUnit:GetAttr(gtBAT.eKBL) --抗暴率
	local bCrit = math.random(1,100) <= (nSrcBJL-nTarKBL)
	return bCrit
end

--计算物理伤害
function CUnit:CalcPhyHurt(oTarUnit, tSkillAttrAdd, tPasSkillContext)
	tSkillAttrAdd = tSkillAttrAdd or table.DeepCopy(CSkillHelper.tSkillAttrAdd)
	tPasSkillContext = tPasSkillContext or table.DeepCopy(CPasSkillHelper.tPasSkillContext)

	--主动技能
	local nGroupAtkHurtRatio = tSkillAttrAdd.nGroupAtkHurtRatio or 100
	local nSkillHurtRatioAdd = tSkillAttrAdd.nSkillHurtRatioAdd or 0
	local nSkillHurtValAdd = tSkillAttrAdd.nSkillHurtValAdd or 0
	local nSkillAtkRatioAdd = tSkillAttrAdd.nSkillAtkRatioAdd or 0
	local nSkillAtkValAdd = tSkillAttrAdd.nSkillAtkValAdd or 0
	local nEfficiency = tSkillAttrAdd.nEfficiency or 1
	local nSkillStaticHurt = tSkillAttrAdd.nSkillStaticHurt  or 0
	local nSkillStaticDef = tSkillAttrAdd.nSkillStaticDef or 0

	local sLog
	local bBattleLog = goBattleMgr:IsBattleLog()
	if bBattleLog then
		sLog = ">>>>>>>>>>>>>>>>>>>>>>>>物理伤害计算开始\n"
		sLog = sLog .. string.format("主动技能参数: %s\n", tostring(tSkillAttrAdd))
		sLog = sLog .. string.format("被动技能参数: %s\n", tostring(tPasSkillContext))
	end

	local nHurt = 0
	local nBaseAtk = 0 
	if nSkillStaticHurt > 0 then
		nHurt = nSkillStaticHurt
		if not tSkillAttrAdd.bIgnoreGroupAtkHurt then
			nHurt = nHurt * (nGroupAtkHurtRatio*0.01)
		end

		if bBattleLog then
			sLog = sLog .. string.format("技能固定伤害: 结果:%f\n", nHurt)
		end

	else
		nBaseAtk = self:GetAttr(gtBAT.eGJ) 	--基础攻击
		local nSrcAtk = (nBaseAtk+nSkillAtkValAdd) * (1+nSkillAtkRatioAdd*0.01)--攻击加成
		local nTarDef = nSkillStaticDef>0 and nSkillStaticDef or oTarUnit:GetAttr(gtBAT.eFY) --防御(固定,基础)
		local nBaseHurt = (nSrcAtk*math.random(90,110)*0.01-nTarDef)*(1+nSkillHurtRatioAdd*0.01)+nSkillHurtValAdd --基础伤害
		nBaseHurt = nBaseHurt * nEfficiency --效率
		nBaseHurt = nBaseHurt * nGroupAtkHurtRatio*0.01 --群攻修正

		if bBattleLog then
			sLog = sLog .. string.format("物理基础伤害: 攻击:%f 防御:%f 结果:%f\n", nSrcAtk, nTarDef, nBaseHurt)
		end

		local nSHAdd = self:CalcPhyBRatio(oTarUnit, tPasSkillContext)
		nBaseHurt = nBaseHurt * (1+nSHAdd*0.01) --B类系数
		nHurt = nBaseHurt

		if bBattleLog then
			sLog = sLog .. string.format("B类系数加成: %f 结果%f\n", nSHAdd, nHurt)
		end

	end

	--修炼加成
	local nPerAdd, nValAdd = self.m_oPracticeHelper:PhyAtkPraAdd(self, oTarUnit)
	nHurt = nHurt * (1+nPerAdd) + nValAdd

	if bBattleLog then
		sLog = sLog .. string.format("修炼加成: 百分比:%f 值:%f 结果:%f\n", nPerAdd, nValAdd, nHurt)
	end

	--保底
	nHurt = math.max(2, math.max(nHurt, nBaseAtk*0.05))

	if bBattleLog then
		sLog = sLog .. string.format("保底: max(1, max(基础攻击[%f]*0.05, 结果)) 结果:%f\n", nBaseAtk, nHurt)
		sLog = sLog .. string.format(">>>>>>>>>>>>>>>>>>>>>>>>>物理伤害计算结束 结果:%f", nHurt)
		self.m_oBattle:WriteLog(sLog)
	end
	return nHurt
end

--被动反击类技能,是否已经反击过(一个回合内，一个单位只能被同一个单位最多反击一次)
function CUnit:IsPasSkillCounterAttacked(oTarUnit)
	local tCOTMap = self.m_tInst.tCOTMap
	return (tCOTMap and tCOTMap[oTarUnit:GetUnitID()])
end

--被动反击类技能,设置反击过标记
function CUnit:SetPasSkillCounterAttacked(tCOTCtx, oTarUnit)
	if not tCOTCtx.bPasSkill then
		return
	end
	self.m_tInst.tCOTMap = self.m_tInst.tCOTMap or {}
	self.m_tInst.tCOTMap[oTarUnit:GetUnitID()] = 1
end

--物理攻击
--@tParentAct 父动作
--@tSkillAttrAdd 主动技能属性加成
--@tPasSkillContext 被动技能属性加成
function CUnit:PhyAtk(oTarUnit, tParentAct, tSkillAttrAdd, tPasSkillContext)
	tSkillAttrAdd = tSkillAttrAdd or table.DeepCopy(CSkillHelper.tSkillAttrAdd)
	tPasSkillContext = tPasSkillContext or table.DeepCopy(CPasSkillHelper.tPasSkillContext)

	--记录攻击和被攻击次数
	self.m_nAttackCount = self.m_nAttackCount + 1
	oTarUnit.m_nBeAttackedCount = oTarUnit.m_nBeAttackedCount + 1

	--是否单体物攻
	local bSingle = false 
	local tSkillConf = self:GetSkillConf(tParentAct.nSKID)
	if tParentAct.nAct==gtACT.eGJ or (tParentAct.nAct==gtACT.eFS and tSkillConf.nAtkType==gtSKAT.eDW) then
		bSingle = true
	end

	--被动技能
	tPasSkillContext.bSingleAtk = bSingle
	tPasSkillContext = self.m_oPasSkillHelper:OnPhyAtk(self, oTarUnit, tPasSkillContext, tParentAct)

	--命中/暴击
	local bHit = self:CalcPhyHit(oTarUnit, tSkillAttrAdd, tPasSkillContext)
	if not bHit then --闪避
		local tSBAct = {nAct=gtACT.eSB, nSrcUnit=oTarUnit:GetUnitID(), nTime=GetActTime(gtACT.eSB)}
		self:AddReactAct(tParentAct, tSBAct, "闪避")
		return
	end

	--伤害
	local nHurt = self:CalcPhyHurt(oTarUnit, tSkillAttrAdd, tPasSkillContext)
	local bCrit = self:CalcPhyCrit(oTarUnit)
	if bCrit then
		nHurt = nHurt*2
	end

	--是否有防御
	local bDefense = false
	if oTarUnit:IsInstExed(CUnit.tINST.eFY) then 
		bDefense = true
		nHurt = nHurt*0.5
	end

	--非单体物理不触发保护
	if not bSingle then
		nHurt = math.floor(nHurt)
		oTarUnit:AddAttr(gtBAT.eQX, -nHurt, tParentAct, "物理攻击扣HP", self, bCrit, bDefense)

		--吸血
		if tPasSkillContext.bSuck then
			local nAddHP = math.floor(nHurt*tPasSkillContext.nSuckRatio*0.01)
			self:AddAttr(gtBAT.eQX, nAddHP, tParentAct, "被动技能吸血")
		end
		return
	end

	--是否有保护
	local tBHAct
	local nProUnit = oTarUnit:IsProtected()
	if nProUnit then
		local oProUnit = self.m_oBattle:GetUnit(nProUnit)
		if oProUnit and not oProUnit:IsDeadOrLeave() then
			local nProHurt = 0
			local nTmpHurt = nHurt
			--夫妻
			if oProUnit:IsRole() and oTarUnit:IsRole() and oProUnit:GetSpouseID() == oTarUnit:GetObjID() then
				nHurt = nTmpHurt * 0.7
				nProHurt = nTmpHurt - nHurt

			--普通	
			else
				nHurt = nTmpHurt * 0.35
				nProHurt = nTmpHurt - nHurt

			end

			--保护动作
			tBHAct = {nAct=gtACT.eBH, nSrcUnit=nProUnit, tTarUnit={oTarUnit:GetUnitID()}, nTime=GetActTime(gtACT.eBH), tReact={}}
			--保护者扣血
			oProUnit:AddAttr(gtBAT.eQX, -math.floor(nProHurt), tBHAct, "保护者扣HP", self)
		end
	end
	--目标扣血
	nHurt = math.floor(nHurt)
	local tSSAct =  oTarUnit:AddAttr(gtBAT.eQX, -nHurt, tParentAct, "物理攻击扣HP", self, bCrit, bDefense)
	if tSSAct and tBHAct then
		self:AddReactAct(tSSAct, tBHAct, "保护动作", true)
	end
	
	--吸血
	if tPasSkillContext.bSuck then
		local nAddHP = math.floor(nHurt*tPasSkillContext.nSuckRatio*0.01)
		self:AddAttr(gtBAT.eQX, nAddHP, tParentAct, "被动技能吸血")
	end

	--反击检测
	local tTarPasSkillContext
	local bCountered = oTarUnit:IsPasSkillCounterAttacked(self) --被动反击类技能,一个回合内,一个单位只能被同一个单位最多反击一次
	local bDoubleCounter = tParentAct.sGJTips=="物理反击" or tParentAct.sGJTips=="魔法反击" --反击不会触发反击
	if not bCountered and not bDoubleCounter and not self:IsDeadOrLeave() and not oTarUnit:IsDeadOrLeave() then
		tTarPasSkillContext = self.m_oPasSkillHelper:OnBePhyAtk(self, oTarUnit)
	end

	--反击
	local tCOTCtx = oTarUnit:IsCounterAttack()
	if tCOTCtx then
		--避免下次被攻击时残留反击状态
		oTarUnit:RemoveRoundFlag(CUnit.tRoundFlag.eCOT, 0)
		if (tCOTCtx.nSKID or 0) == 0 then
			oTarUnit:CounterPhyAttack(self, tCOTCtx, tParentAct, tTarPasSkillContext)
		else
			oTarUnit:CounterMagAttack(self, tCOTCtx, tParentAct, tTarPasSkillContext)
		end
	end
end

--计算法术命中
--@nSkillHitRate 技能有自己的命中率(封印类特殊)
function CUnit:CalcMagHit(nSKID, oTarUnit, tSkillAttrAdd, tPasSkillContext)
	nSkillHitRate = tSkillAttrAdd.nSkillHitRate or 0

	local tConf = ctSkillConf[nSKID]
	if tConf and tConf.nType == gtSKT.eFY then --封印
		local nSrcFYMZ = self:GetAttr(gtBAT.eFYMZ) + self.m_oPracticeHelper:MagSealPraAdd(oUnit)
		local nTarFYKX = self:GetAttr(gtBAT.eFYKX) + self.m_oPracticeHelper:MagAntiSealPraAdd(oTarUnit) 
		local bHit = math.random(1,100) <= math.max(20, math.min(100, (nSrcFYMZ-nTarFYKX)))
		return bHit
	end
	local nBaseHitRate = nSkillHitRate>0 and nSkillHitRate or self:GetBaseMagHitRate()
	local nSrcFSMZ = nBaseHitRate + self:GetAttr(gtBAT.eFSMZ) --装备等加成
	local nTarFSSB = self:GetBaseMagDodgeRate() + oTarUnit:GetAttr(gtBAT.eFSSB) --装备等加成
	local bHit = math.random(1,100) <= math.max(20, math.min(100, (nSrcFSMZ-nTarFSSB)))
	return bHit
end

--计算法术暴击
function CUnit:CalcMagCrit(oTarUnit, tPasSkillContext)
	if oTarUnit:GetRoundFlag(CUnit.tRoundFlag.eIGNFSBJ) then
		self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "BUFF禁止暴法术击")
		return false
	end
	local nFSBJ = self:GetAttr(gtBAT.eFSBJ)+(tPasSkillContext.tAttrAdd[gtBAT.eFSBJ] or 0)
	local nFSKB = oTarUnit:GetAttr(gtBAT.eFSKB)
	local nBJ = nFSBJ - nFSKB
	if math.random(100) <= nBJ then
		return true
	end
	return false
end

--计算法术伤害
function CUnit:CalcMagHurt(oTarUnit, tSkillAttrAdd, tPasSkillContext)
	local nGroupAtkHurtRatio = tSkillAttrAdd.nGroupAtkHurtRatio
	local nSkillHurtRatioAdd = tSkillAttrAdd.nSkillHurtRatioAdd + tSkillAttrAdd.nSkillHurtRatioAdd1
	local nSkillHurtValAdd = tSkillAttrAdd.nSkillHurtValAdd
	local nSkillAtkRatioAdd = tSkillAttrAdd.nSkillAtkRatioAdd
	local nSkillAtkValAdd = tSkillAttrAdd.nSkillAtkValAdd
	local nEfficiency = tSkillAttrAdd.nEfficiency
	local nSkillStaticHurt = tSkillAttrAdd.nSkillStaticHurt
	local nSkillStaticDef = tSkillAttrAdd.nSkillStaticDef

	local sLog
	local bBattleLog = goBattleMgr:IsBattleLog()
	if bBattleLog then
		sLog = ">>>>>>>>>>>>>>>>>>>>>>>>法术伤害计算开始\n"
		sLog = sLog .. string.format("主动技能参数: %s\n", tostring(tSkillAttrAdd))
		sLog = sLog .. string.format("被动技能参数: %s\n", tostring(tPasSkillContext))
	end

	local nHurt = 0
	local nSrcLL = self:GetAttr(gtBAT.eLL) --可能有BUFF加成
	if nSkillStaticHurt > 0 then
		nHurt = nSkillStaticHurt
		if not tSkillAttrAdd.bIgnoreGroupAtkHurt then
			nHurt = nHurt * (nGroupAtkHurtRatio*0.01)
		end
		if bBattleLog then
			sLog = sLog .. string.format("技能固定伤害: 结果:%f\n", nHurt)
		end

	else
		local nWeaponAtk = self:GetWeaponAtk()
		local nSrcLL = (nSrcLL+nSkillAtkValAdd)*(1+nSkillAtkRatioAdd*0.01) --可能有BUFF加成
		local nTarLL = nSkillStaticDef > 0 and nSkillStaticDef or oTarUnit:GetAttr(gtBAT.eLL) --可能有BUFF加成

		local nSrcFG = self:GetAttr(gtBAT.eFSGJ)     --策划说没有法攻
		local nTarFF = oTarUnit:GetAttr(gtBAT.eFSFY) --策划说没有法防

		local nBaseHurt = ((nSrcLL-nTarLL+nWeaponAtk/2)+nSkillHurtValAdd)*(1+nSkillHurtRatioAdd*0.01) --基础伤害

		nBaseHurt = nBaseHurt * nEfficiency --效率
		nBaseHurt = nBaseHurt * nGroupAtkHurtRatio*0.01 --群攻修正

		if bBattleLog then
			sLog = sLog .. string.format("法术基础伤害: 灵力:%f 攻击(法攻+武器/2+技能攻击加成):%f 武器攻击:%f -> 灵力:%f 防御:%f 结果:%f\n", nSrcLL, nSrcFG, nWeaponAtk, nTarLL, nTarFF, nBaseHurt)
		end

		local nSHAdd = self:CalcMagBRatio(oTarUnit, tPasSkillContext)
		nBaseHurt = nBaseHurt * (1+nSHAdd*0.01) --B类系数
		nHurt = nBaseHurt

		if bBattleLog then
			sLog = sLog .. string.format("B类系数加成: %f 结果%f\n", nSHAdd, nHurt)
		end

	end

	--修炼加成
	local nPerAdd, nValAdd = self.m_oPracticeHelper:MagAtkPraAdd(self, oTarUnit)
	nHurt = nHurt * (1+nPerAdd) + nValAdd

	if bBattleLog then
		sLog = sLog .. string.format("修炼加成: 百分比:%f 值:%f 结果:%f\n", nPerAdd, nValAdd, nHurt)
	end

	--保底
	nHurt = math.max(2, math.max(nHurt, nSrcLL*0.05))

	if bBattleLog then
		sLog = sLog .. string.format("保底: max(1, max(攻方灵力[%f]*0.05, 结果)) 结果:%f\n", nSrcLL, nHurt)
		sLog = sLog .. string.format(">>>>>>>>>>>>>>>>>>>>>>>>法术伤害计算结束 结果:%f", nHurt)
		self.m_oBattle:WriteLog(sLog)
	end
	return nHurt
end

--法术攻击
--@tParentAct 父动作
--@tSkillAttrAdd 技能属性加成
function CUnit:MagAtk(nSKID, oTarUnit, tParentAct, tSkillAttrAdd)
	--主动技能
	local tSkillAttrAdd = tSkillAttrAdd or table.DeepCopy(CSkillHelper.tSkillAttrAdd)

	--被动技能
	local tPasSkillContext = table.DeepCopy(CPasSkillHelper.tPasSkillContext)
	tPasSkillContext.bSingleAtk = self:GetSkillConf(nSKID).nAtkType==gtSKAT.eDF
	--法术连击不会再触发法术连击,否则会打到死; 法宝技能不触发连击; 魔法反击不触发连击
	tPasSkillContext.bIgnSkillDoubleHit = tParentAct.sGJTips=="魔法反击" or tParentAct.sGJTips=="法术连击" or self:IsFBSkill(nSKID)
	tPasSkillContext = self.m_oPasSkillHelper:OnMagAtk(self, oTarUnit, tPasSkillContext, tParentAct)

	--记录攻击和被攻击次数
	self.m_nAttackCount = self.m_nAttackCount + 1
	oTarUnit.m_nBeAttackedCount = oTarUnit.m_nBeAttackedCount + 1

	--命中
	local bHit = self:CalcMagHit(nSKID, oTarUnit, tSkillAttrAdd, tPasSkillContext)
	if not bHit then --闪避
		local tSBAct = {nAct=gtACT.eSB, nSrcUnit=oTarUnit:GetUnitID(), nTime=GetActTime(gtACT.eSB)}
		self:AddReactAct(tParentAct, tSBAct, "法术闪避")
		return --没命中不会有暴击
	end

	--伤害
	local nHurt = self:CalcMagHurt(oTarUnit, tSkillAttrAdd, tPasSkillContext)
	local bCrit = self:CalcMagCrit(oTarUnit, tPasSkillContext)
	if bCrit then
		nHurt = nHurt*2
	end

	--目标扣血
	nHurt = math.floor(nHurt)
	oTarUnit:AddAttr(gtBAT.eQX, -nHurt, tParentAct, "法术攻击扣HP", self, bCrit)

	--检测法术连击
	self:CheckSkillDoubleHit(nSKID, oTarUnit, tPasSkillContext)
end

--检测法术连击
function CUnit:CheckSkillDoubleHit(nSKID, oTarUnit, tPasSkillContext)
	if not tPasSkillContext.bSkillDoubleHit then
		return
	end

	--法宝技能不连击
	if self:IsFBSkill(nSKID) then
		return
	end

	--附加参数环境
	local tSkill = self:GetActSkill(nSKID)
	local tSkillExtCtx = table.DeepCopy(CSkillHelper.tSkillExtCtx)
	tSkillExtCtx.oTarget = nil --有可能是群攻技能，所以不能固定目标
	tSkillExtCtx.nSkillHurtRatioAdd	= tPasSkillContext.nSkillDoubleHitHurt 
	tSkillExtCtx.sFrom = string.format("法术连击:%d", nSKID)
	tSkillExtCtx.sGJTips = "法术连击"
	self.m_oSkillHelper:SetSkillDoubleHit(tSkillExtCtx)
end

--执行物理反击
function CUnit:CounterPhyAttack(oSrcUnit, tCOTCtx, tParentAct, tPasSkillContext)
	if self:IsDeadOrLeave() or oSrcUnit:IsDeadOrLeave() then
		return
	end
	self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "物理反击", oSrcUnit:GetUnitID(), oSrcUnit:GetObjName(), tPasSkillContext)

	local tGJAct = {
		nAct = gtACT.eGJ,
		nSrcUnit = self:GetUnitID(),
		tTarUnit = {oSrcUnit:GetUnitID()},
		nTime = GetActTime(gtACT.eGJ),
		sGJTips = tCOTCtx.sGJTips,
		tReact = {},
	}
	self:PhyAtk(oSrcUnit, tGJAct, nil, tPasSkillContext)
	self:AddReactAct(tParentAct, tGJAct, "物理反击")

	--角色反击类主动技能执行后马上移除BUFF
	if (tCOTCtx.nRemoveBuffID or 0) > 0 then
		--self:RemoveBuff(tCOTCtx.nRemoveBuffID, tParentAct, "移除角色反击类技能BUFF")  客户端没处理，先屏蔽
	--被动反击处理
	elseif tCOTCtx.bPasSkill then
		self:SetPasSkillCounterAttacked(tCOTCtx, oSrcUnit)
		
	end
end

--执行魔法反击
function CUnit:CounterMagAttack(oSrcUnit, tCOTCtx, tParentAct, tPasSkillContext)
	if self:IsDeadOrLeave() or oSrcUnit:IsDeadOrLeave() then
		return
	end
	self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "魔法反击", oSrcUnit:GetObjName(), tPasSkillContext)

	local nSKID = tCOTCtx.nSKID
	if self:IsFBSkill(nSKID) then --法宝技能不能作为反击用
		return
	end

	local tSkill = self:GetActSkill(nSKID) --策划说没有也可以反击，取角色自己的等级
	if not tSkill then
		local tSkillConf = self:GetSkillConf(nSKID)
		self.m_tActSkillMap[nSKID] = {nLevel=self:GetLevel(), sName=tSkillConf.sName}
		self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "魔法反击没有技能加个临时的", nSKID)
	end

	local tSkillExtCtx = table.DeepCopy(CSkillHelper.tSkillExtCtx)
	tSkillExtCtx.oTarget = oSrcUnit
	tSkillExtCtx.tParentAct = tParentAct
	tSkillExtCtx.nSkillHurtRatioAdd	= tPasSkillContext.tAttrAdd[gtBAT.eFSSH] or 0
	tSkillExtCtx.sGJTips = tCOTCtx.sGJTips
	tSkillExtCtx.sFrom = string.format("魔法反击%d", nSKID)
	self.m_oSkillHelper:Launch(self, nSKID, tSkillExtCtx)

	if not tSkill then	
		self.m_tActSkillMap[nSKID] = nil 
	end

	--角色反击类主动技能执行后马上移除BUFF
	if (tCOTCtx.nRemoveBuffID or 0) > 0 then
		-- self:RemoveBuff(tCOTCtx.nRemoveBuffID, tParentAct, "移除角色反击类技能BUFF") 客户端没处理,屏蔽
	--被动反击处理
	elseif tCOTCtx.bPasSkill then
		self:SetPasSkillCounterAttacked(tCOTCtx, oSrcUnit)
	end
end

--执行物品指令
function CUnit:WPExec()
	self.m_tInst.bExed = true
	local oTarUnit = self.m_oBattle:GetUnit(self.m_tInst.nTarUnit)
	if not oTarUnit or oTarUnit:IsLeave() then
		return self.m_oBattle:WriteLog("药品目标不存在", self.m_tInst)
	end
	local oRoleUnit = self
	if self:IsPet() then
		oRoleUnit = self.m_oBattle:GetMainUnit(self:GetUnitID())
	end
	local oRole = goPlayerMgr:GetRoleByID(oRoleUnit:GetObjID())
	local oProp = oRole.m_oKnapsack:GetPropByKey(self.m_tInst.nPropKey)
	if not oProp then
		return self.m_oBattle:Tips(oRoleUnit, "物品不存在")
	end
	return self.m_oPropHelper:UseProp(oProp, self, oTarUnit)
end

--执行召唤令
function CUnit:ZHExec()
	self.m_tInst.bExed = true
	local nPosID = self.m_tInst.nPosID
	local tPetData = self.m_tPetMap[nPosID]
	assert(not tPetData.bUsed, "宠物已出战过")
	tPetData.bUsed = true

	local nPetUnitID = self.m_oBattle:GetSubUnitID(self:GetUnitID())
	local oPetUnit = self.m_oBattle:GetUnit(nPetUnitID)
	if oPetUnit then
		oPetUnit.m_bLeave = true
		oPetUnit:OnLeave()
	end

	local tZHAct = {
		nAct = gtACT.eZH,
		nSrcUnit = self:GetUnitID(),
		tTarUnit = {nPetUnitID},
		tUnit = nil,
		nTime = GetActTime(gtACT.eZH),
		sTips = string.format("该场战斗还能召唤%d个宠物", self:GetRemainPet()),
	}
	self.m_oBattle:AddRoundAction(tZHAct, "宠物召唤") --需要先占位,否则会出现战斗前喊招找不到单位

	local oPetUnit = CUnit:new(self.m_oBattle, nPetUnitID, tPetData)
	self.m_oBattle:AddUnit(nPetUnitID, oPetUnit)
	tZHAct.tUnit = oPetUnit:GetInfo() --AddUnit过程中可能改变属性,所以信息延后到这里取
	self.m_nPetCalled = self.m_nPetCalled + 1
	self.m_oBattle:SyncPreloadSkillRet(nPetUnitID)
	return true
end

--设置子怪死亡离开回合,和主怪ID
function CUnit:OnSubMonsterDeadLeave(nMainMonsterID, nDeadLeaveRound)
	self.m_nSubMonsterDeadLeaveRound = nDeadLeaveRound
end

function CUnit:GetSubMonsterDeadLeaveRound()
	return self.m_nSubMonsterDeadLeaveRound
end

function CUnit:GetSubMonsterCalledTimes()
	return self.m_nSubMonsterCalled
end

--是否可召唤子怪
function CUnit:CanCallSubMonster()
	if self.m_nSubMonsterCalled >= 1 then --只能召唤一次
		return false,  "只能召唤1次,召唤失败"
	end
	if self:GetUnitPos() > 5 then --非主怪不触发
		return false, "非主怪不能召唤"
	end
	if not self:IsMonster() or self:IsDeadOrLeave() then --主怪非怪物或死亡离开不触发
		return false, "主怪非怪物或已死亡"
	end
	if self.m_nSubMonsterDeadLeaveRound <= 0 then
		return false, "子怪未死亡"
	end
	if self:IsLockAction(CUnit.tINST.eZH, 0) then --被禁止行动不触发
		self.m_nSubMonsterDeadLeaveRound = self.m_oBattle:GetRound()
		return false, "被禁止行动,召唤失败"
	end
	local nSubUnitID = self.m_oBattle:GetSubUnitID(self:GetUnitID())
	if self.m_oBattle:GetUnit(nSubUnitID) then --子怪物没离开战斗不触发
		return false, "子怪未离开战斗"
	end
	if self.m_oBattle:GetRound() ~= self.m_nSubMonsterDeadLeaveRound+1 then --子怪死亡第二回合触发
		return false, "非子怪死亡第二回合"
	end
	return true, "成功"
end

--执行怪物召唤指令
function CUnit:ZHSubMonster()
	local tMonsterConf = ctSubMonsterConf[self:GetObjID()]
	if not tMonsterConf then
		return
	end
	local tResult = CWeightRandom:Random(tMonsterConf.tCallMonster, function(conf) return conf[2] end, 1)
	if not tResult or #tResult <= 0 then
		return
	end
	local tUnitData = CMonsterBase:GetSubMonsterBattleData(tResult[1][1], self:GetLevel())
	local nSubUnitID = self.m_oBattle:GetSubUnitID(self:GetUnitID())
	goBattleMgr:CalcUnitFmtAttr(self.m_oBattle, nSubUnitID, tUnitData)
	goBattleMgr:CalcUnitOtherAttrAdd(self.m_oBattle, nSubUnitID, tUnitData)

	self.m_oBattle:WriteLog("召唤子怪物单位数据", nSubUnitID, tUnitData)
	local oSubUnit = CUnit:new(self.m_oBattle, nSubUnitID, tUnitData)
	self.m_oBattle:AddUnit(nSubUnitID, oSubUnit)

	local tZHAct = {
		nAct = gtACT.eZH,
		nSrcUnit = self:GetUnitID(),
		tTarUnit = {nSubUnitID},
		tUnit = oSubUnit:GetInfo(),
		nTime = GetActTime(gtACT.eZH),
	}
	self.m_oBattle:AddRoundAction(tZHAct, "召唤子怪物")
	self.m_oBattle:SyncPreloadSkillRet(nSubUnitID)

	self.m_nSubMonsterDeadLeaveRound = 0
	self.m_nSubMonsterCalled = self.m_nSubMonsterCalled + 1
end

--执行自动指令
function CUnit:ZDExec()
	return true
end

--执行防御指令
function CUnit:FYExec()
	self.m_tInst.bExed = true
	return true
end

--执行保护指令
function CUnit:BHExec()
	local oTarUnit = self.m_oBattle:GetUnit(self.m_tInst.nTarUnit)
	if oTarUnit then
		oTarUnit:AddRoundFlag(CUnit.tRoundFlag.ePTD, 0, {nUnitID=self:GetUnitID()})
	end
	self.m_tInst.bExed = true
	return true
end

--执行捕捉指令
function CUnit:BZExec()
	return true
end

--执行撤退指令
function CUnit:CTExec()
	local nRnd = math.random(1, 100)

	--逃跑率
	local oBattle = self.m_oBattle
	local nTPL = self:GetAttr(gtBAT.eTPL) or 0

	--抓捕率
	local nZBL = 0
	local nTeamFlag = oBattle:EnemyFlag(self:GetUnitID())
	local oLeaderUnit = oBattle:GetLeaderUnit(nTeamFlag)
	if oLeaderUnit then
		nZBL = oLeaderUnit:GetAttr(gtBAT.eZBL) or 0
	else
		local tLeaderData = oBattle:GetLeaderData(nTeamFlag)
		nZBL = tLeaderData.tBattleAttr[gtBAT.eZBL] or 0
	end

	local nRate = math.max(0, math.min(90, self.m_nRetreatBaseRate+nTPL-nZBL))
	local bLeave = nRnd <= nRate

	local tCTAct = {nAct=gtACT.eCT, nSrcUnit=self:GetUnitID(), bLeave=bLeave, nTime=GetActTime(gtACT.eCT), tReact={}}
	self.m_oBattle:AddRoundAction(tCTAct, "撤退")
	
	if bLeave then
		self.m_oBattle:OnUnitCT(self, tCTAct)
	end
	return true
end

--单位离开战斗事件
function CUnit:OnLeave()
	GetGModule("TimerMgr"):Clear(self.m_nLeaveTimer)
	self.m_nLeaveTimer = nil
	self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "离开战斗")
	self.m_oBattle:OnUnitLeave(self:GetUnitID())
end

--魅怪检测喊话
function CUnit:GhostBeforeRound(nRound)
	if not self:IsGhost() or nRound > 1 then	
		return
	end
	local tSubMonsterConf = ctSubMonsterConf[self:GetObjID()]

	local bExist = false
	local tRoleSchoolList = self.m_oBattle:GetTeamSchoolList(self.m_oBattle:EnemyFlag(self:GetUnitID()))
	for _, tSchool in ipairs(tSubMonsterConf.tTalkSchool) do
		if table.InArray(tSchool[1], tRoleSchoolList) then
			bExist = true
			break
		end
	end

	local sTalk = bExist and tSubMonsterConf.sExistTalk or tSubMonsterConf.sNotExistTalk
	if bExist then
		local tCTAct = {nAct=gtACT.eCT, nSrcUnit=self:GetUnitID(), bLeave=true, nTime=GetActTime(gtACT.eCT), tReact={}}
		self.m_oBattle:AddRoundAction(tCTAct, "魅怪逃跑")

		local tWSAct = {nAct=gtACT.eWarSpeak, nSrcUnit=self:GetUnitID(), sTips=sTalk, nTime=GetActTime(gtACT.eWarSpeak), tReact={}}
		self:AddReactAct(tCTAct, tWSAct, "魅怪喊话")
		self.m_oBattle:OnUnitCT(self, tCTAct)
	else
		assert(tSubMonsterConf.nEscapeRounds > 0)
		local tWSAct = {nAct=gtACT.eWarSpeak, nSrcUnit=self:GetUnitID(), sTips=sTalk, nTime=GetActTime(gtACT.eWarSpeak), tReact={}}
		self.m_oBattle:AddRoundAction(tWSAct, "魅怪喊话")
		self.m_nRoundsEscape = tSubMonsterConf.nEscapeRounds
	end
end

--回合前结算(BUFF/技能)
function CUnit:BeforeRound(nRound)
	for nType, tBuffMap in pairs(self.m_tBuffMap) do
		for nBuffID, oBuff in pairs(tBuffMap) do
			oBuff:BeforeRound()
		end
	end

	if self.m_tInst.nInst == CUnit.tINST.eFS then
		if self:IsLockAction(self.m_tInst.nInst, self.m_tInst.nSkill) then  --BUFF禁止行动
			self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "BUFF禁止技能预处理", self.m_tInst)

		else --执行技能
			if self:IsFBSkill(self.m_tInst.nSkill) then
				self.m_oFBSkillHelper:BeforeRound(self, self.m_tInst.nSkill)	
			else
				self.m_oSkillHelper:BeforeRound(self, self.m_tInst.nSkill)	
			end
		end
	end

	--魅怪处理
	self:GhostBeforeRound(nRound)
end

--检测魅怪逃跑
function CUnit:GhostAfterRound(nRound)
	if not self:IsGhost() then
		return
	end
	if self.m_nRoundsEscape ~= nRound then
		return
	end
	self.m_nRoundsEscape = 0

	local tCTAct = {nAct=gtACT.eCT, nSrcUnit=self:GetUnitID(), bLeave=true, nTime=GetActTime(gtACT.eCT), tReact={}}
	self.m_oBattle:AddRoundAction(tCTAct, "魅怪逃跑")
	self.m_oBattle:OnUnitCT(self, tCTAct)
end

--回合后结算(BUFF/技能)
function CUnit:AfterRound(nRound)
	for nType, tBuffMap in pairs(self.m_tBuffMap) do
		for nBuffID, oBuff in pairs(tBuffMap) do
			oBuff:AfterRound()
		end
	end

	--魅怪逃跑检测
	self:GhostAfterRound(nRound)
end

--行动前结算(BUFF/技能)
function CUnit:BeforeAction()
	for nType, tBuffMap in pairs(self.m_tBuffMap) do
		for nBuffID, oBuff in pairs(tBuffMap) do
			oBuff:BeforeAction()
		end
	end

	if self:GetAI() > 0 and not self:IsDeadOrLeave() then
		local tInst = self.m_oAIHelper:DoAI(self)
		if tInst then
			if tInst.nInst == CUnit.tINST.eGJ then
				self:ReplaceInst(tInst.nInst, tInst.nTarUnit)
			elseif tInst.nInst == CUnit.tINST.eFS then
				self:ReplaceInst(tInst.nInst, tInst.nTarUnit, tInst.nSkill)
			elseif tInst.nInst == CUnit.tINST.eFY then
				self:ReplaceInst(tInst.nInst)
			else
				assert(false, "AI指令错误")
			end
		end
	end

	--宠物概率触发逃跑
	if self:IsPet() and not self:IsDeadOrLeave() then 
		local oBuff = self:GetBuff(2015)
		local nEscapeRate = oBuff and oBuff:GetEscapeRate() or 0
		if nEscapeRate > 0 then
			if math.random(100) <= nEscapeRate then
				self:ReplaceInst(CUnit.tINST.eCT)
			end
		end
	end
end

--行动后结算(BUFF/技能)
function CUnit:AfterAction()
	for nType, tBuffMap in pairs(self.m_tBuffMap) do
		for nBuffID, oBuff in pairs(tBuffMap) do
			oBuff:AfterAction()
		end
	end
end

--取BUFF
function CUnit:GetBuff(nBuffID)
	local nType = ctBuffConf[nBuffID].nType
	local tBuffMap = self.m_tBuffMap[nType] or {}
	return tBuffMap[nBuffID]
end

--取BUFF回合加成
function CUnit:CalcRoundsAdd(nBuffID, nBuffRounds)
	local tConf = ctBuffConf[nBuffID]
	local oBuff = self:GetBuff(913) or self:GetBuff(1913)
	if oBuff then
		local tRoundsAddCond = oBuff:GetRoundsAddCond()
		if table.InArray(tConf.nType, tRoundsAddCond.tType) or table.InArray(tConf.nType, tRoundsAddCond.tTypeAttr) then
			local nRoundsRatioAdd = oBuff:GetRoundsRatioAdd()
			local nOldBuffRounds = nBuffRounds
			nBuffRounds = math.floor(nBuffRounds*(1+nRoundsRatioAdd*0.01))
			self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), string.format("BUFF回合加成[%d]->[%d]", nOldBuffRounds, nBuffRounds))
		end
	end
	return nBuffRounds
end

--添加BUFF
--@xExt 额外参数
function CUnit:AddBuff(nSkillID, nSkillLv, nBuffID, nRounds, tParentAct, xExt)
	self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "添加BUFF", nSkillID, nBuffID, nRounds)
	assert(nRounds>0, "BUFF回合数错误")

	--鬼魅
	if self:GetRoundFlag(CUnit.tRoundFlag.eGM) then
		return self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "鬼魅禁止添加任何BUFF")
	end
	--抗封印BUFF
	if self:GetRoundFlag(CUnit.tRoundFlag.eLCKFYBUFF) then
		local tBuffConf = ctBuffConf[nBuffID]
		if tBuffConf.nTypeAttr == gtSTA.eFY then
			return self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "BUFF禁止添加封印类BUFF")
		end
	end

	--回合加成
	nRounds = self:CalcRoundsAdd(nBuffID, nRounds)
	if nRounds <= 0 then
		return self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "BUFF回合加成后<=0", nBuffID)
	end

	local tInst = self:GetInst()
	local nType = ctBuffConf[nBuffID].nType
	self.m_tBuffMap[nType] = self.m_tBuffMap[nType] or {}

	local tBuffMap = self.m_tBuffMap[nType]
	if tBuffMap[nBuffID] then --BUFF已存在则替换
		self:ReplaceBuff(nBuffID)
		tBuffMap[nBuffID] = CBuff:new(self, nSkillID, nSkillLv, nBuffID, nRounds, tInst.nTarUnit, xExt)

	else --添加新BUFF
		if nType == gtSTT.eYC or nType == gtSTT.eFZ or nType == gtSTT.eLS then --异常,辅助,临时
			local tBuffList = {}
			for nBuffID, oBuff in pairs(tBuffMap) do
				table.insert(tBuffList, nBuffID)
			end
			if #tBuffList > 3 then
				local nRelpaceBuffID = tBuffList[math.random(#tBuffList)]
				self:RemoveBuff(nRelpaceBuffID, tParentAct, "BUFF类型达到上限随机替换:"..nType)
			end
		end

		tBuffMap[nBuffID] = CBuff:new(self, nSkillID, nSkillLv, nBuffID, nRounds, tInst.nTarUnit, xExt)
		if tParentAct then
			local tABAct = {
				nAct = gtACT.eAB,
				nSrcUnit = self:GetUnitID(),
				nBuffID = nBuffID,
				nTime = GetActTime(gtACT.eAB)
			}
			self:AddReactAct(tParentAct, tABAct, "添加BUFF")
		end
	end
end

--恢复并移除要替换的BUFF
function CUnit:ReplaceBuff(nBuffID)
	self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "替换BUFF:", nBuffID)

	local nType = ctBuffConf[nBuffID].nType
	local tBuffMap = self.m_tBuffMap[nType]
	tBuffMap[nBuffID]:Recover()
	tBuffMap[nBuffID] = nil
end

--清理特定类型的BUFF
function CUnit:ClearBuffType(nType, tParentAct)
	for nTmpType, tBuffMap in pairs(self.m_tBuffMap) do
		if nTmpType == nType then
			for nBuffID, oBuff in pairs(tBuffMap) do
				self:RemoveBuff(nBuffID, tParentAct, "清理特定类型的BUFF:"..nType)
			end
		end
	end
end

--清理特定类型属性的BUFF
function CUnit:ClearBuffTypeAttr(nTypeAttr, tParentAct)
	if nTypeAttr == 0 then
		return
	end
	for nType, tBuffMap in pairs(self.m_tBuffMap) do
		for nBuffID, oBuff in pairs(tBuffMap) do
			local tConf = ctBuffConf[nBuffID]
			if tConf.nTypeAttr == nTypeAttr then
				self:RemoveBuff(nBuffID, tParentAct, "清理特定类型属性的BUFF:"..nTypeAttr)
			end
		end
	end
end

--移除BUFF
function CUnit:RemoveBuff(nBuffID, tParentAct, sReason)
	self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "移除BUFF:", nBuffID, sReason)
	local tBuffConf = ctBuffConf[nBuffID]
	if not tBuffConf then
		return
	end

	local nType = tBuffConf.nType
	local tBuffMap = self.m_tBuffMap[nType] or {}
	if not tBuffMap[nBuffID] then
		return self.m_oBattle:WriteLog(self:GetUnitID(), self:GetObjName(), "BUFF不存在", nBuffID)
	end
	tBuffMap[nBuffID]:Recover()
	tBuffMap[nBuffID] = nil


	--0是为了实现功能加的BUFF
	if nType ~= 0 then
		local tDBAct = {
			nAct = gtACT.eDB,
			nSrcUnit = self:GetUnitID(),
			nBuffID = nBuffID,
			nCurrHP = self:GetAttr(gtBAT.eQX),
			nCurrMP = self:GetAttr(gtBAT.eMF),
			nCurrSP = self:GetAttr(gtBAT.eNQ),
			nTime = GetActTime(gtACT.eAB),
		}
		if tParentAct then
			self:AddReactAct(tParentAct, tDBAct, "移除BUFF")
		else
			self.m_oBattle:AddRoundAction(tDBAct, "移除BUFF")
		end
	end
end

--死亡清楚类BUFF
function CUnit:DeadClearBuff(tParentAct)
	for nType, tBuffMap in pairs(self.m_tBuffMap) do
		for nBuffID, oBuff in pairs(tBuffMap) do
			local tConf = ctBuffConf[nBuffID]
			if tConf.bDeadClear then
				self:RemoveBuff(nBuffID, tParentAct, "死亡清除BUFF")
			end
		end
	end
end

--是否隐身
function CUnit:IsHide()
	return self:GetRoundFlag(CUnit.tRoundFlag.eHIDE)
end

--是否可以攻击隐身目标
function CUnit:HideAtkCheck(oTarUnit)
	if not oTarUnit:IsHide() then
		return true
	end
	if self:IsSameTeam(oTarUnit:GetUnitID()) then
		return true
	end
	if self:GetRoundFlag(CUnit.tRoundFlag.eIGNHIDE) then
		return true
	end
	--金睛
	if self:GetPasSkill(5112) or self:GetPasSkill(5212) then
		return true
	end
	return false
end

--是否有某个BUFF
function CUnit:HasBuff(nBuffID)
	for nType, tBuffMap in pairs(self.m_tBuffMap) do
		if tBuffMap[nBuffID] then
			return true
		end
	end
end

--取BUFF列表
function CUnit:GetBuffList()
	local tBuffList = {}
	for nType, tBuffMap in pairs(self.m_tBuffMap) do
		for nBuffID, oBuff in pairs(tBuffMap) do
			table.insert(tBuffList, nBuffID)
		end
	end
	return tBuffList
end

--取自动战斗指令列表
function CUnit:GetAutoInstList()
	local tInstList = {{nInst=CUnit.tINST.eGJ}, {nInst=CUnit.tINST.eFY}}	

	local tTmpList = {}
	local tSkillMap = self:GetActSkillMap()
	for nSkill, tSkill in pairs(tSkillMap) do
		table.insert(tTmpList, {nInst=CUnit.tINST.eFS, tSkill=self:GetSkillInfo(nSkill)})
	end
	table.sort(tTmpList, function(t1, t2) return t1.tSkill.nLearnLevel<t2.tSkill.nLearnLevel end)
	
	for _, tInst in ipairs(tTmpList) do
		table.insert(tInstList, tInst)
	end
	return tInstList
end