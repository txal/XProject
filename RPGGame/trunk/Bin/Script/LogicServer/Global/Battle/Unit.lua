--战斗单位
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--结果属性类型(值)
CUnit.tRAT = 
{
	eQX = 1, 	--气血
	eMF = 2, 	--魔法
	eNQ = 3, 	--怒气
	eGJ = 4, 	--攻击
	eFY = 5, 	--防御
	eLL = 6, 	--灵力
	eSD = 7, 	--速度
}

--高级属性类型
CUnit.tAAT = 
{
	eFSGJ = 1,	--法术攻击(值)
	eFSFY = 2, 	--法术防御(值)
	eZLQD = 3, 	--治疗强度(值)
	eFYMZ = 4,	--封印命中(百分比)
	eFYKX = 5, 	--封印抗性(百分比)
}

--隐藏属性类型(百分比[放大100倍])
CUnit.tHAT = 
{
	eMZL = 1, 	--命中率
	eSBL = 2, 	--闪避率
	eBJL = 3, 	--暴击率
	eKBL = 4, 	--抗暴率
}

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
	[CUnit.tINST.eFS] = {"FSInst", "FSExec"}
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
	ePTD = 1, 	--被保护(每回合只保护一次)
	eSPC = 2, 	--速度被改变
	eLCK = 3, 	--禁止本轮行动
}


function CUnit:Ctor(oBattle , nUnitID, nParentUnit, nSpouseID, nServer, nSession
	, nObjID, nObjType, sObjName, nExp, tResAttr, tAdvAttr, tPropMap, tSkillMap, tPetMap)

	self.m_oBattle = oBattle
	self.m_nUnitID = nUnitID 			--单位ID
	self.m_nParentUnit = nParentUnit 	--父单位ID(宠物,伙伴)
	self.m_nSpouseID = nSpouseID 		--夫妻ID

	self.m_nServer = nServer 	--服务器(角色)
	self.m_nSession = nSession 	--会话ID(角色)
	self.m_nObjID = nObjID		--对象ID
	self.m_nObjType = nObjType 	--对象类型
	self.m_sObjName = sObjName 	--对象名字
	self.m_nExp = nExp 			--经验

    self.m_tResAttr = tResAttr 	--结果属性
    self.m_tAdvAttr = tAdvAttr 	--高级属性
    self.m_tHideAttr = self:GenHideAttr() 	--隐藏属性
    self.m_nCTSuccRate = 70 	--撤退成功率

    self.m_bAuto = false 		--是否自动战斗
    self.m_bDead = false 		--是否死亡
    self.m_bLeave = false 		--是否已离开(撤退/PNC死亡)

    self.m_tInst = {}			--指令{inst=0,...}
    self.m_tBuffMap = {} 		--BUFF映射
    self.m_tRoundFlag = {}		--回合中一些状态记录(被保护,速度改变等){[flag]={...}, ...}

    self.m_tPropMap = tPropMap  	--物品列表(角色){[id]=num, ...}
    self.m_nPropUsed = 0 			--物品使用数量(角色)
    self.m_tPetMap = tPetMap 		--宠物列表(角色){[id]={name="",level=0,skill={[id]={name="",},...},attr={...},used=false}, ...}
    self.m_tSkillMap = tSkillMap 	--法术列表{[id]={name="",},...}

    self.m_nManuSkill = 0	--手动技能(法术)
    self.m_nAuotoSkill = 0 	--自动技能(法术,攻击,防御)

    self.m_nAutoTimer = nil --自动时缓冲计时器
end

function CUnit:GenHideAttr()
	local tHideAttr = {}
	tHideAttr[CUnit.tHAT.eMZL] = 100
	tHideAttr[CUnit.tHAT.eSBL] = self:IsRole() and 10 or 5
	tHideAttr[CUnit.tHAT.eBJL] = 3
	tHideAttr[CUnit.tHAT.eKBL] = 0
	return tHideAttr
end

function CUnit:OnRelease()
	goTimerMgr:Clear(self.m_nAutoTimer)
	self.m_nAutoTimer = nil
end

function CUnit:IsAuto() return self.m_bAuto end
function CUnit:IsDead() return self.m_bDead end
function CUnit:IsReady() return (self.m_tInst.nInst or 0) > 0 end
function CUnit:IsLeave() return self.m_bLeave end
function CUnit:SetLeave() return self.m_bLeave = true end

function CUnit:GetUnitID() return self.m_nUnitID end
function CUnit:GetObjID() return self.m_nObjID end
function CUnit:GetObjName() return self.m_nObjName end
function CUnit:GetObjType() return self.m_nObjType end
function CUnit:GetSpouseID() return self.m_nSpouseID end
function CUnit:GetParentUnit() return self.m_nParentUnit end
function CUnit:GetExp() return self.m_nExp end

function CUnit:IsPet() return (self.m_nObjType == gtObjType.ePet) end
function CUnit:IsRole() return (self.m_nObjType == gtObjType.eRole) end
function CUnit:IsPartner() return (self.m_nObjType == gtObjType.ePartner) end
function CUnit:IsMonster() return (self.m_nObjType == gtObjType.eMonster) end
function CUnit:SetSession(nSession) self.m_nSession = nSession end
function CUnit:GetSession() return self.m_nSession end
function CUnit:GetServer() return self.m_nServer end
function CUnit:GetPropMap() return self.m_tPropMap end
function CUnit:GetPropUsed() return self.m_nPropUsed end
function CUnit:IsSameTeam(nTarUnit) return (nTarUnit%10 == self.m_nUnitID%10) end

function CUnit:GetResAttr(nType) return self.m_tResAttr[nType] end
function CUnit:AddResAttr(nType, nVal)
	self.m_tResAttr[nType] = math.max(0, self.m_tResAttr[nType]+nVal)
	--标记速度改变	
	if nType == CUnit.tRAT.eSD then
		self:SetRoundFlag(CUnit.tRoundFlag.eSPC, true)

	--死亡判断
	elseif nType == CUnit.tRAT.eQX then
		if self.m_tResAttr[nType] <= 0 then
			self:OnDead()
		end

	end
end
function CUnit:GetAdvAttr(nType) return self.m_tAdvAttr[nType] end
function CUnit:AddAdvAttr(nType, nVal) self.m_tAdvAttr[nType] = math.max(0, self.m_tAdvAttr[nType]+nVal) end
function CUnit:GetHideAttr(nType) return self.m_tAdvAttr[nType] end
function CUnit:AddHideAttr(nType, nVal) self.m_tHideAttr[nType] = math.max(0, self.m_tHideAttr[nType]+nVal) end

function CUnit:SetRoundFlag(nFlag, xVal) self.m_tRoundFlag[nFlag] = Val end
function CUnit:GetRoundFlag(nFlag) return self.m_tRoundFlag[nFlag] end
function CUnit:IsProtected() return self.m_tRoundFlag[CUnit.tRoundFlag.ePTD] end
function CUnit:IsSpeedChange() return self.m_tRoundFlag[CUnit.tRoundFlag.eSPC] end
function CUnit:IsLockAction() return self.m_tRoundFlag[CUnit.tRoundFlag.eLCK] end
function CUnit:IsInstMiss() return self.m_tInst.bMiss end

--回合开始事件
function CUnit:OnRoundBegin(nRound)
    assert(not self:IsLeave())
    --重置
    self.m_tInst = {}
    self.m_tRoundFlag = {}

    --自动缓冲
    if self:IsAuto() then
    	goTimerMgr:Clear(self.m_nAutoTimer)
    	self.m_nAutoTimer = goTimerMgr:Interval(3, function() self:OnAutoTimer() end)
    end
end

--自动缓冲到时
function CUnit:OnAutoTimer()
	goTimerMgr:Clear(self.m_nAutoTimer)
	self.m_nAutoTimer = nil
	assert(self:IsAuto())
	self:EnterAuto()
end

--回合结束事件
function CUnit:OnRoundEnd(nRound)
end

--死亡
function CUnit:OnDead()
	--添加消息 fix pd

	self.m_bDead = true
	self.m_oBattle:OnUnitDead(self)

	if self:IsMonster() or self:IsPet() then
		self:SetLeave()
	end
end

--进入自动
function CUnit:EnterAuto()
	self.m_bAuto = true
	if not self:IsReady() then
		local nRndEnemy = self.m_oBattle:RandAliveEnemy(self.m_nUnitID)
		assert(nRndEnemy > 0)
		self:SetInst(CUnit.tINST.eGJ, nRndEnemy)
	end
end

--------------------下达指令------------------
--下达指令
function CUnit:SetInst(nInst, ...)
	assert(self.m_tInst.nInst == 0, "已经下达指令")
	local fnSet = CUnit.tInstFunc[nInst][1]
	if not fnSet(...) then
		return
	end
	self.m_oBattle:OnUnitReady(self.m_nUnitID)
end

--下达法术指令
function CUnit:FSInst(nTarUnit, nSKill)
	assert(self:IsRole() or self:IsPet())
	self.m_tInst = {nInst=CUnit.tINST.eFS, nSKill=nSKill, nTarUnit=nTarUnit}
	return true
end

--下达攻击指令
function CUnit:GJInst(nTarUnit)
	assert(self:IsRole() or self:IsPet())
	self.m_tInst = {nInst=CUnit.tINST.eGJ, nTarUnit=nTarUnit}
	return true
end

--下达物品指令
function CUnit:WPInst(nTarUnit, nPropID)
	assert(self:IsRole() or self:IsPet())
	local nMaxProp = 10
	local nPropUsed = 0
	local tPropMap = nil
	local nServer = 0
	local nSession = 0

	if self:IsRole() then
		nPropUsed = self:GetPropUsed()
		tPropMap = self:GetPropMap()
		nServer = self:GetServer()
		nSession = self:GetSession()
	else
		local oRoleUnit = self.m_oBattle:GetUnit(self.m_nParentUnit)
		nPropUsed = oRoleUnit:GetPropUsed()
		tPropMap = oRoleUnit:GetPropMap()
		nServer = oRoleUnit:GetServer()
		nSession = oRoleUnit:GetSession()
	end
	if (tPropMap[nPropID] or 0) <= 0 then
		return CBattle:Tips(nServer, nSession, "物品不足")
	end
	if nPropUsed >= nMaxProp then
		return CBattle:Tips(nServer, nSession, "你已使用了10个物品")
	end
	tPropMap[nPropID] = tPropMap[nPropID] - 1
	self.m_tInst = {nInst=CUnit.tINST.eWP, nTarUnit=nTarUnit, nPropID=nPropID}
	return true
end

--取剩下可已出战宠物数
function CUnit:GetRemainPet()
	local nMaxPet = 5
	local nUsedPet = 0
	for nID, tPet in pairs(self.m_tPetMap) do
		if tPet.bUsed then
			nUsedPet = nUsedPet + 1
		end
	end
	return (nMaxPet-nUsedPet)
end

--下达召唤令
function CUnit:ZHInst(nPetID)
	assert(self:IsRole())
	local nRemainPet = self:GetRemainPet()
	if nRemainPet <= 0 then
		return CBattle:Tips(nServer, nSession, "没有可召唤宠物")
	end
	local tPet = self.m_tPetMap[nPetID]
	if not tPet or tPet.bUsed then
		return CBattle:Tips(nServer, nSession, "宠物不存在或者已出战")
	end
	self.m_tInst = {nInst=CUnit.tINST.eZH, nPetID=nPetID}
	return true
end

--下达自动指令
function CUnit:ZDInst()
end

--下达防御指令
function CUnit:FYInst()
	assert(self:IsRole() or self:IsPet())
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
	assert(self:IsRole() or self:IsPet())
	self.m_tInst = {nInst=CUnit.tINST.eCT}
	return self.m_tInst
end

--计算速度
function CUnit:CalcSpeed()
	local nSpeed = self:GetResAttr(CUnit.tRAT.eSD)
	if not self:IsMonster() then --NPC不随机
		nSpeed = nSpeed * math.random(90, 110) * 0.01
	end
	local nInst = self.m_tInst.nInst
	if nInst == CUnit.tINST.eFY then
		nSpeed = nSpeed * 10
	elseif nInst == CUnit.tINST.eBH then
		nSpeed = nSpeed * 10
	elseif nInst == CUnit.tINST.eZH then
		nSpeed = nSpeed * 1.2
	elseif nInst == CUnit.tINST.eWP then
		nSpeed = nSpeed * 1.2
	elseif nInst == CUnit.tINST.eBZ then
		nSpeed = nSpeed * math.random(100, 500) * 0.01
	end
	return nSpeed
end


--------------------执行指令------------------
--某指令是否已执行
function CUnit:IsInstExec(nInst)
	if self.m_tInst.nInst and self.m_tInst.bExed then
		return true
	end
end

--执行指令
function CUnit:ExecInst()
	assert(self.m_tInst.nInst > 0, "没有下达指令")
	if self:IsLockAction() then
		return
	end
	--不会错误的指令表
	local tNotMissInst = {CUnit.tINST.eZD}

	--执行指令
	if self:IsDead() and not table.InArray(self.m_tInst.nInst, tNotMissInst) then
		self.m_tInst.bMiss = true
	else
		local fnExec = CUnit.tInstFunc[self.m_tInst.nInst][2]
		return fnExec()
	end
end

--执行法术指令
function CUnit:FSExec()
	return true
end

--执行攻击指令(物理)
function CUnit:GJExec()
	local nTarUnit = self.m_tInst.nTarUnit
	local oTarUnit = self.m_oBattle:GetUnit(nTarUnit)
	if not oTarUnit or oTarUnit:IsDead() then
		nTarUnit = self.m_oBattle:RandAliveEnemy(self.m_nUnitID)
		self.m_tInst.nTarUnit = nTarUnit
	end
	self.m_tInst.bExed = true	
	local oTarUnit = self.m_oBattle:GetUnit(nTarUnit)
	oTarUnit:OnGJ(self)
	return true
end

--被攻击事件(物理)
function CUnit:OnGJ(oSrcUnit)
	local nSrcGJ = oSrcUnit:GetResAttr(CUnit.tRAT.eGJ) + 40 --攻击
	local nTarFY = self:GetResAttr(CUnit.tRAT.eFY) --防御

	local nSrcMZL = oSrcUnit:GetResAttr(CUnit.tHAT.eMZL) --命中率
	local nTarSBL = self:GetResAttr(CUnit.tHAT.eSBL) --闪避率
	local nSrcBJL = oSrcUnit:GetResAttr(CUnit.tHAT.eBJL) --暴击率
	local nTarKBL = self:GetResAttr(CUnit.tHAT.eKBL) --抗暴率

	--fix pd 命中算法对不对
	local bHit = math.random(1,100) <= math.min(20, math.max(100, (nSrcMZL-nTarSBL)))
	local bCrit = math.random(1,100) <= (nSrcBJL-nTarKBL)

	--计算伤害
	local nHurt = 0
	if bHit then
		nHurt = nSrcGJ*math.random(90,110)*0.01 - nTarFY
		if bCrit then nHurt = nHurt*2 end
	end

	--是否防御
	if self:IsInstExec(CUnit.tINST.eFY) then
		nHurt = nHurt * 0.5
	end

	--是否保护
	--被保护者只受到本次伤害的35%，自身受到本次伤害的65%。如果双方是夫妻，则伤害比调整为70%:30%
	local nProUnit = self:IsProtected()
	if nProUnit then
		local oProUnit = self.m_oBattle:GetUnit(nProUnit)
		if oProUnit and not oProUnit:IsDead() then
			local nTmpHurt = nHurt
			local nProHurt = 0
			if oProUnit:IsRole() and self:IsRole() and oProUnit:GetSpouseID() == self:GetObjID() then
				nHurt = nTmpHurt * 0.7
				nProHurt = nTmpHurt - nHurt

			else
				nHurt = nTmpHurt * 0.35
				nProHurt = nTmpHurt - nHurt
			end

		end
	end

end

--执行物品指令
function CUnit:WPExec()
	return true
end

--执行召唤令
function CUnit:ZHExec()
	--fix 召回
	self.m_tInst.bExed = true
	return true
end

--执行自动指令
function CUnit:ZDExec()
	return true
end

--执行防御指令
function CUnit:FYExec()
	print("执行防御指令")
	self.m_tInst.bExed = true
	local tMsg = {nBattleID=self.m_oBattle:GetID(), nUnitID=self:GetUnitID()}
	self.m_oBattle:Broadcast("ExecInstRet", tMsg)
	return true
end

--执行保护指令
function CUnit:BHExec()
	print(self.m_sObjName, "执行保护指令")
	local oTarUnit = self.m_oBattle:GetUnit(self.m_tInst.nTarUnit)
	if oTarUnit then
		oTarUnit:SetRoundFlag(CUnit.tRoundFlag.eBH, self:GetUnitID())
	end
	self.m_tInst.bExed = true
	return true
end

--执行捕捉指令
function CUnit:BZExec()
end

--执行撤退指令
function CUnit:CTExec()
	local nRnd = math.random(1, 100)
	if nRnd >= self.m_nCTSuccRate then
		self.m_oBattle:OnUnitCT(self)
	end
	return true
end

--撤退成功事件
function CUnit:OnCTSuccess()
	print("逃避成功:", self.m_sObjName)
	--添加消息 fix pd
	self:SetLeave()
end

--回合前结算BUFF
function CUnit:BeforeRoundBuff(nRound)
end

--回合后结算BUFF
function CUnit:AfterRoundBuff(nRound)
end

--行动前结算BUFF
function CUnit:BeforeActionBuff()
end

--行动后结算BUFF
function CUnit:AfterActionBuff()
end
