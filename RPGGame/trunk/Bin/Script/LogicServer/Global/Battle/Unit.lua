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

--隐藏属性类型(百分比)
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

function CUnit:Ctor(oBattle, nUnitID, nObjID, nObjType, sObjName, tResAttr, tAdvAttr, tHideAttr)
	self.m_oBttle = oBattle
	self.m_nUnitID = nUnitID 	--单位ID

	self.m_nObjID = nObjID		--对象ID
	self.m_nObjType = nObjType 	--对象类型
	self.m_sObjName = sObjName 	--对象名字

    self.m_tResAttr = tResAttr 	--结果属性
    self.m_tAdvAttr = tAdvAttr 	--高级属性
    self.m_tHideAttr = tHideAttr--隐藏属性

    self.m_bAuto = false 	--是否自动战斗
    self.m_bDead = false 	--是否死亡

    self.m_tInst = {}		--指令	
    self.m_tBuffMap = {} 	--BUFF映射

    self.m_nManuSkill = 0	--手动技能(主动技能)
    self.m_nAuotoSkill = 0 	--自动技能(主动技能,攻击,防御)

    self.m_tPropMap = {}  	--物品列表{[id]=num, ...}
    self.m_nTotalUse = 0 	--物品使用数量

    self.m_nReadyTimer = nil --回合准备计时器
end

function CUnit:OnRelease()
	goTimerMgr:Clear(self.m_nReadyTimer)
	self.m_nReadyTimer = nil
end

function CUnit:IsAuto() return self.m_bAuto end
function CUnit:IsDead() return self.m_bDead end
function CUnit:IsReady() return self.m_nInst > 0 end
function CUnit:GetUnitID() return self.m_nUnitID end
function CUnit:GetObjID() return self.m_nObjID end
function CUnit:GetObjType() return self.m_nObjType end

function CUnit:GetResAttr(nType) return self.m_tResAttr[nType] end
function CUnit:AddResAttr(nType, nVal) self.m_tResAttr[nType] = math.max(0, self.m_tResAttr[nType]+nVal) end
function CUnit:GetAdvAttr(nType) return self.m_tAdvAttr[nType] end
function CUnit:AddAdvAttr(nType, nVal) self.m_tAdvAttr[nType] = math.max(0, self.m_tAdvAttr[nType]+nVal) end
function CUnit:GetHideAttr(nType) return self.m_tAdvAttr[nType] end
function CUnit:AddHideAttr(nType, nVal) self.m_tHideAttr[nType] = math.max(0, self.m_tHideAttr[nType]+nVal) end

--回合开始事件
function CUnit:OnRoundBegin(nRound)
	goTimerMgr:Clear(self.m_nReadyTimer)
	self.m_nInst = 0 --置空指令

	local nReadyTime = 30
	if self:IsAuto() then
		nReadyTime = 3
	end
	self.m_nReadyTimer = goTimerMgr:Interval(nReadyTime, function() self:OnReadyTimer() end)
end

--准备时间结束
function CUnit:OnReadyTimer()
	if self:IsAuto() then
	else
	end
end

--死亡
function CUnit:OnDead()
	self.m_bDead = true
	self.m_oBttle:OnUnitDead(self.m_nUnitID)
end

--下达指令
function CUnit:SetInst(nInst, nSkill, nTarUnit)
	self.m_nInst = nInst
	self.m_nSkill = nSkill
	self.m_nTarUnit = nTarUnit
	self.m_oBttle:OnUnitReady(self.m_nUnitID)
end
