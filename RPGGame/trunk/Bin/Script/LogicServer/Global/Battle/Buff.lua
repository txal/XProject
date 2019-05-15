--BUFF
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CBuff:Ctor(oUnit, nSkillID, nSkillLv, nBuffID, nRounds, nTarUnit, xExt)
	self.m_oUnit = oUnit
	self.m_nBuffID = nBuffID
	self.m_nSkillID = nSkillID
	self.m_nSkillLv = nSkillLv
	self.m_nTarUnit = nTarUnit
	self.m_xExt = xExt

	self.m_nAddRound = math.max(1, self.m_oUnit.m_oBattle:GetRound()) --当前回合必须>=1,被动技能BUFF一开始就会加,可能会是0
	self.m_nKeepRounds = nRounds
	self.m_tBuffAttr = {}

	self.m_nRoundsRatioAdd = 0 	--回合数加成
	self.m_tRoundsAddCond = nil --回合数加成条件
	self.m_nEscapeRate = 0 		--逃跑几率
	self.m_nDeadRound = 0 		--死亡回合
	self:Exec()
end

function CBuff:GetID()
	return self.m_nBuffID
end

--是否过期
function CBuff:IsExpire() 
	local nCurrRound = self.m_oUnit.m_oBattle:GetRound()
	return (nCurrRound-self.m_nAddRound+1) >= self.m_nKeepRounds
end
function CBuff:RemainRounds()
	local nCurrRound = self.m_oUnit.m_oBattle:GetRound()
	return self.m_nKeepRounds+self.m_nAddRound-nCurrRound
end

function CBuff:GetConf() return ctBuffConf[self.m_nBuffID] end
function CBuff:AddBuffAttr(nType, nVal) self.m_tBuffAttr[nType] = math.min(gnMaxInteger, math.max(-gnMaxInteger, (self.m_tBuffAttr[nType] or 0)+nVal)) end
function CBuff:GetBuffAttr(nType) return (self.m_tBuffAttr[nType] or 0) end
function CBuff:GetTarUnit() return self.m_nTarUnit end
function CBuff:GetRoundsRatioAdd() return self.m_nRoundsRatioAdd end
function CBuff:GetRoundsAddCond() return self.m_tRoundsAddCond end
function CBuff:GetEscapeRate() return self.m_nEscapeRate end
function CBuff:SetDeadRound(nRound) self.m_nDeadRound = nRound end

--执行函数
CBuff.fnExec = {}

--虚弱 降低15%防御和15%灵力, 同时不能进行任何行动
CBuff.fnExec[101] = function(self, oUnit)
	local nFY = math.floor(oUnit:GetAttr(gtBAT.eFY)*0.15)
	local nLL = math.floor(oUnit:GetAttr(gtBAT.eLL)*0.15)
	oUnit:AddAttr(gtBAT.eFY, -nFY, nil, string.format("执行虚弱BUFF%d", self.m_nBuffID))
	oUnit:AddAttr(gtBAT.eLL, -nLL, nil, string.format("执行虚弱BUFF%d", self.m_nBuffID))
	self:AddBuffAttr(gtBAT.eFY, -nFY)
	self:AddBuffAttr(gtBAT.eLL, -nLL)
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eLCK, self:GetID(), {bPermernent=true})
end
--防御 第一回合休息附加防御状态, 并临时提高防御力10%+skill*2和灵力20%;第二回合临时提高攻击力skill*3+50和速度skill*3+80,
--速率120%, 并自动攻击目标, 伤害结果增加30%
CBuff.fnExec[102] = function(self, oUnit)
	local nFY = math.floor(oUnit:GetAttr(gtBAT.eFY)*0.1+self.m_nSkillLv*2)
	local nLL = math.floor(oUnit:GetAttr(gtBAT.eLL)*0.2)
	oUnit:AddAttr(gtBAT.eFY, nFY, nil, string.format("执行防御BUFF%d", self.m_nBuffID))
	oUnit:AddAttr(gtBAT.eLL, nLL, nil, string.format("执行防御BUFF%d", self.m_nBuffID))
	self:AddBuffAttr(gtBAT.eFY, nFY)
	self:AddBuffAttr(gtBAT.eLL, nLL)
end
--物理反击
CBuff.fnExec[103] = function(self, oUnit)
	local tCOTCtx = table.DeepCopy(CUnit.tCOTContext)
	tCOTCtx.sGJTips = "物理反击"
	tCOTCtx.bPermernent = true
	tCOTCtx.nRemoveBuffID = self.m_nBuffID
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eCOT, self:GetID(), tCOTCtx)
end
--休息
CBuff.fnExec[104] = function(self, oUnit)
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eLCK, self:GetID(), {bPermernent=true})
end
--金刚护法 一定(skill-aimlv)/10+skill/80+3回合内增加自己或队友的攻击力skill*1和恢复少量气血skill*2+30；佛光普照技能50级以上作用3个目标，90级以上作用4个目标
CBuff.fnExec[105] = function(self, oUnit)
	local nAtkAdd = math.floor(self.m_nSkillLv*1)
	local sFrom = string.format("执行金刚护法BUFF%d", self.m_nBuffID)
	oUnit:AddAttr(gtBAT.eGJ, nAtkAdd, nil, sFrom)
	self:AddBuffAttr(gtBAT.eGJ, nAtkAdd)

end
--金刚护体 一定(skill-aimlv)/10+skill/80+3回合内增加自己或队友的防御力skill*1和恢复少量气血skill*2+30；佛光普照技能60级以上作用3目标，90级以上作用4个目标
CBuff.fnExec[106] = function(self, oUnit)
	local nDefAdd = math.floor(self.m_nSkillLv*1)
	local sFrom = string.format("执行金刚护体BUFF%d", self.m_nBuffID)
	oUnit:AddAttr(gtBAT.eFY, nDefAdd, nil, sFrom)
	self:AddBuffAttr(gtBAT.eFY, nDefAdd)

end
--变身 物理攻击敌人，伤害结果减少20%。为自己附加变身状态(skill-aimlv)/10+skill/40+4回合，最高7回合，临时提升自己的攻击力skill*0.5+20，是使用烟雨断肠，绵里藏针，移花接木，落花听雨的前提，注意，当对方无可攻击目标时，也可以变身成功
CBuff.fnExec[120] = function(self, oUnit)
	local nAtkAdd = math.floor(self.m_nSkillLv*0.5+20)
	oUnit:AddAttr(gtBAT.eGJ, nAtkAdd, nil, string.format("执行变身BUFF%d", self.m_nBuffID))
	self:AddBuffAttr(gtBAT.eGJ, nAtkAdd)

end
--封法 变身状态下才能使用，临时提升自己的攻击力skill*1，攻击单人并令其2回合内无法使用法术、特技、物理攻击；使用后取消变身状态，自身中一样BUFF
CBuff.fnExec[121] = function(self, oUnit)
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eLCKTJ, self:GetID(), {bPermernent=true})
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eLCKFS, self:GetID(), {bPermernent=true})
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eLCKGJ, self:GetID(), {bPermernent=true})
end
--虚弱 变身状态下才能使用，攻击敌方多人，攻击提高10%，伤害提高30%，使用后次回合只能执行防御、保护、召唤指令或使用药品；大鹏展翅技能25级以上作用2个目标，35级以上作用3个目标，70级以上作用4个目标，105级以上作用5个目标
CBuff.fnExec[122] = function(self, oUnit)
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eLCKTJ, self:GetID(), {bPermernent=true})
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eLCKFS, self:GetID(), {bPermernent=true})
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eLCKGJ, self:GetID(), {bPermernent=true})
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eLCKCT, self:GetID(), {bPermernent=true})
end
--魔法反击 使用水系法术攻击单个目标同时为自己附加魔法反击效果，伤害为50+skill*1.5+skill*skill/170，同时比较灵力，武器攻击/4，受普通物理攻击则以龙腾反击对手，伤害为龙腾正常的一半
CBuff.fnExec[113] = function(self, oUnit)
	local tCOTCtx = table.DeepCopy(CUnit.tCOTContext)
	tCOTCtx.nSKID = 1412
	tCOTCtx.sGJTips = "魔法反击"
	tCOTCtx.bPermernent = true
	tCOTCtx.nRemoveBuffID = self.m_nBuffID
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eCOT, self:GetID(), tCOTCtx) --天灵剑诀反击
end
--盘丝阵 有(skill-aimlv)*2%+60%几率，最低20%，最高70%令对手(skill-aimlv)/10+skill/90+3回合内无法使用物理攻击同时为自己附加防御力skill*1.5效果。如果被封印目标已使用过法术，则封印持续回合+1
CBuff.fnExec[124] = function(self, oUnit)
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eLCKGJ, self:GetID(), {bPermernent=true})
end
--含情脉脉 有(skill-aimlv)*2%+55%几率，最低20%，最高70%令对手(skill-aimlv)/10+skill/90+3回合内无法使用法术、物理攻击。如果被封印目标已使用过法术，则封印持续回合+1
CBuff.fnExec[125] = function(self, oUnit)
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eLCKFS, self:GetID(), {bPermernent=true})
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eLCKGJ, self:GetID(), {bPermernent=true})
end
--夺命蛛丝 临时降低自身一定速度，速率50%，有(skill-aimlv)*2%+50%几率，最低20%，最高70%令对手(skill-aimlv)/10+skill/40+3回合内无法被复活。如果被封印目标已使用过法术，则封印持续回合+1
CBuff.fnExec[126] = function(self, oUnit)
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eLCKRL, self:GetID(), {bPermernent=true})
end
--强化防御
CBuff.fnExec[127] = function(self, oUnit)
	local nDefAdd = math.floor(self.m_nSkillLv*1.5)
	oUnit:AddAttr(gtBAT.eFY, nDefAdd, nil, "执行强化防御127")
	self:AddBuffAttr(gtBAT.eFY, nDefAdd)
end
--睡眠
CBuff.fnExec[401] = function(self, oUnit)
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eLCK, self:GetID(), {bPermernent=true})
end
--混乱
CBuff.fnExec[402] = function(self, oUnit)
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eCONFUSE, self:GetID(), {bPermernent=true})
end

--附加隐身状态；隐身状态下物理攻击能力会降低20%，且无法使用技能。
CBuff.fnExec[303] = function(self, oUnit)
	local nAtkAdd = math.floor(oUnit:GetAttr(gtBAT.eGJ)*0.2)
	oUnit:AddAttr(gtBAT.eGJ, -nAtkAdd, nil, string.format("执行隐身BUFF%d", self.m_nBuffID))
	self:AddBuffAttr(gtBAT.eGJ, -nAtkAdd)
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eHIDE, self:GetID(), {nBuffID=self.m_nBuffID, bPermernent=true})
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eLCKFS, self:GetID(), {bPermernent=true})

end


---------------------------------------------------被动技能类
--鬼魅BUFF
--死亡5回合复活。不受任何状态影响，但也不能使用主动技能恢复气血。
CBuff.fnExec[901] = function(self, oUnit)
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eGM, self:GetID(), {nBuffID=self.m_nBuffID, bPermernent=true})
end
--高级鬼魅BUFF
CBuff.fnExec[1901] = CBuff.fnExec[901]
--冥思BUFF
CBuff.fnExec[902] = function(self, oUnit) end
--高级冥想
CBuff.fnExec[1902] = function(self, oUnit) end
--再生BUFF
CBuff.fnExec[903] = function(self, oUnit) end
--高级再生
CBuff.fnExec[1903] = function(self, oUnit) end
--中毒BUFF
CBuff.fnExec[904] = function(self, oUnit) end
--凝神BUFF
--可以抵挡封印类异常状态
CBuff.fnExec[905] = function(self, oUnit)
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eLCKFYBUFF, self:GetID(), {bPermernent=true})
end
--强迫BUFF
--使目标在行动时只能被迫执行防御
CBuff.fnExec[906] = function(self, oUnit)
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eONLYFY, self:GetID(), {nBuffID=self.m_nBuffID, bPermernent=true})
end
--冰霜BUFF
--攻击目标时，有一定几率使目标4回合内速度降低10%
CBuff.fnExec[907] = function(self, oUnit)
	local tBuffConf = self:GetConf()
	local nAttrID = tBuffConf.eValue[1][1]
	local nAddPer = tBuffConf.eValue[1][2]()
	local nAddSpeed = math.floor(oUnit:GetAttr(nAttrID)*nAddPer*0.01)
	oUnit:AddAttr(nAttrID, nAddSpeed, nil, string.format("BUFF:%d",nAttrID))
	self:AddBuffAttr(nAttrID, nAddSpeed)
end
--高级冰霜BUFF
CBuff.fnExec[1907] = CBuff.fnExec[907]

--气势BUFF
--物理伤害结果增加10%
CBuff.fnExec[908] = function(self, oUnit)
	local tBuffConf = self:GetConf()
	local nAttrID = tBuffConf.eValue[1][1]
	local nAddVal = tBuffConf.eValue[1][2]()
	oUnit:AddAttr(nAttrID, nAddVal, nil, string.format("BUFF:%d",nAttrID))
	self:AddBuffAttr(nAttrID, nAddVal)
end
--高级气势BUFF
CBuff.fnExec[1908] = CBuff.fnExec[908]

--震慑BUFF
--法术伤害结果增加10%
CBuff.fnExec[909] = function(self, oUnit)
	local tBuffConf = self:GetConf()
	local nAttrID = tBuffConf.eValue[1][1]
	local nAddVal = tBuffConf.eValue[1][2]()
	oUnit:AddAttr(nAttrID, nAddVal, nil, string.format("BUFF:%d",nAttrID))
	self:AddBuffAttr(nAttrID, nAddVal)
end
--高级震慑BUFF
CBuff.fnExec[1909] = CBuff.fnExec[909]

--审判BUFF
--将敌人击倒时，其重生类技能或效果无效
CBuff.fnExec[910] = function(self, oUnit)
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eIGNCS, self:GetID(), {nBuffID=self.m_nBuffID, bPermernent=true})
end
--幸运BUFF
--不会受到物理重击、法术暴击
CBuff.fnExec[911] = function(self, oUnit)
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eIGNBJ, self:GetID(), {nBuffID=self.m_nBuffID, bPermernent=true})
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eIGNFSBJ, self:GetID(), {nBuffID=self.m_nBuffID, bPermernent=true})
end
--忠心BUFF
--不会逃跑(主动逃跑)，不受强迫效果影响
CBuff.fnExec[912] = function(self, oUnit)
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eIGNQP, self:GetID(), {nBuffID=self.m_nBuffID, bPermernent=true})
end
--持久
--受到的增益状态持续回合数加倍。
CBuff.fnExec[913] = function(self, oUnit)
	local tBuffConf = self:GetConf()
	self.m_nRoundsRatioAdd = tBuffConf.eValue[1][2]()
	self.m_tRoundsAddCond = {tType={2,3}, tTypeAttr={1,3,4}}
end
--高级持久
CBuff.fnExec[1913] = CBuff.fnExec[913]


------------------------------------------法宝技能BUFF
CBuff.fnExec[2001] = function(self, oUnit)
	local tBuffConf = self:GetConf()
	local nAttrID  = tBuffConf.eValue[1][1]
	local nAddPer = tBuffConf.eValue[1][2]()
	local nAddVal = math.floor(oUnit:GetAttr(nAttrID)*nAddPer*0.01)
	oUnit:AddAttr(nAttrID, nAddVal, nil, string.format("法宝BUFF:%d", self.m_nBuffID))
	self:AddBuffAttr(nAttrID, nAddVal)
end
CBuff.fnExec[2002] = CBuff.fnExec[2001]
CBuff.fnExec[2003] = CBuff.fnExec[2001]
CBuff.fnExec[2004] = CBuff.fnExec[2001]
CBuff.fnExec[2005] = CBuff.fnExec[2001]
CBuff.fnExec[2006] = CBuff.fnExec[2001]
CBuff.fnExec[2007] = CBuff.fnExec[2001]
CBuff.fnExec[2008] = CBuff.fnExec[2001]
CBuff.fnExec[2009] = CBuff.fnExec[2001]
CBuff.fnExec[2010] = CBuff.fnExec[2001]
CBuff.fnExec[2011] = CBuff.fnExec[2001]
CBuff.fnExec[2012] = CBuff.fnExec[2001]
CBuff.fnExec[2013] = function(self, oUnit)
	oUnit:AddRoundFlag(CUnit.tRoundFlag.eIGNHIDE, self:GetID(), {nBuffID=self.m_nBuffID, bPermernent=true})
end
CBuff.fnExec[2014] = function(self, oUnit)
	local tBuffConf = self:GetConf()
	for _, eValue in ipairs(tBuffConf.eValue) do
		local nAttrID = eValue[1]
		local nAddVal = eValue[2]()
		oUnit:AddAttr(nAttrID, nAddVal, nil, string.format("法宝BUFF:%d", self.m_nBuffID))
		self:AddBuffAttr(nAttrID, nAddVal)
	end
end
CBuff.fnExec[2015] = function(self, oUnit)
	CBuff.fnExec[2014](self, oUnit)
	self.m_nEscapeRate = 15
end


--执行BUFF
function CBuff:Exec()
	local fnExec = CBuff.fnExec[self.m_nBuffID]
	if not fnExec then
		return LuaTrace("BUFF:", self.m_nBuffID, "未实现")
	end
	fnExec(self, self.m_oUnit)
end

--恢复属性
CBuff.fnRecover = {}
--虚弱 降低15%防御和15%灵力, 同时不能进行任何行动
CBuff.fnRecover[101] = function(self, oUnit)
	local nFY = self:GetBuffAttr(gtBAT.eFY)
	local nLL = self:GetBuffAttr(gtBAT.eLL)
	oUnit:AddAttr(gtBAT.eFY, -nFY, nil, string.format("恢复虚弱BUFF:%d", self.m_nBuffID))
	oUnit:AddAttr(gtBAT.eLL, -nLL, nil, string.format("恢复虚弱BUFF:%d", self.m_nBuffID))
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eLCK, self:GetID())
end

--防御 第一回合休息附加防御状态, 并临时提高防御力10%+skill*2和灵力20%;第二回合临时提高攻击力skill*3+50和速度skill*3+80,
--速率120%, 并自动攻击目标, 伤害结果增加30%
CBuff.fnRecover[102] = function(self, oUnit)
	local nFY = self:GetBuffAttr(gtBAT.eFY)
	local nLL = self:GetBuffAttr(gtBAT.eLL)
	oUnit:AddAttr(gtBAT.eFY, -nFY, nil, string.format("恢复防御BUFF:%d", self.m_nBuffID))
	oUnit:AddAttr(gtBAT.eLL, -nLL, nil, string.format("恢复防御BUFF:%d", self.m_nBuffID))

	local nGJ = self:GetBuffAttr(gtBAT.eGJ)
	local nSD = self:GetBuffAttr(gtBAT.eSD)
	oUnit:AddAttr(gtBAT.eGJ, -nGJ, nil, string.format("恢复防御BUFF:%d", self.m_nBuffID))
	oUnit:AddAttr(gtBAT.eSD, -nSD, nil, string.format("恢复防御BUFF:%d", self.m_nBuffID))
end
--物理反击
CBuff.fnRecover[103] = function(self, oUnit)
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eCOT, self:GetID())
end
--休息
CBuff.fnRecover[104] = function(self, oUnit)
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eLCK, self:GetID())
end
--金刚护法
CBuff.fnRecover[105] = function(self, oUnit) 
	local nAtkAdd = self:GetBuffAttr(gtBAT.eGJ)
	oUnit:AddAttr(gtBAT.eGJ, -nAtkAdd, nil, string.format("恢复BUFF:%d", self.m_nBuffID))
end
--金刚护体
CBuff.fnRecover[106] = function(self, oUnit)
	local nDefAdd = self:GetBuffAttr(gtBAT.eFY)
	oUnit:AddAttr(gtBAT.eFY, -nDefAdd, nil, string.format("恢复BUFF:%d", self.m_nBuffID))
end
--魔法反击
CBuff.fnRecover[113] = function(self, oUnit)
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eCOT, self:GetID())
end
--变身
CBuff.fnRecover[120] = function(self, oUnit)
	local nAtkAdd = self:GetBuffAttr(gtBAT.eGJ)
	oUnit:AddAttr(gtBAT.eGJ, -nAtkAdd, nil, string.format("恢复BUFF:%d", self.m_nBuffID))
end
--封法
CBuff.fnRecover[121] = function(self, oUnit)
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eLCKTJ, self:GetID())
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eLCKFS, self:GetID())
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eLCKGJ, self:GetID())
end
--虚弱
CBuff.fnRecover[122] = function(self, oUnit)
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eLCKTJ, self:GetID())
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eLCKFS, self:GetID())
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eLCKGJ, self:GetID())
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eLCKCT, self:GetID())
end
--盘丝阵
CBuff.fnRecover[124] = function(self, oUnit)
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eLCKGJ, self:GetID())
end
--含情脉脉
CBuff.fnRecover[125] = function(self, oUnit)
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eLCKFS, self:GetID())
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eLCKGJ, self:GetID())
end
--夺命蛛丝
CBuff.fnRecover[126] = function(self, oUnit)
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eLCKRL, self:GetID())
end
--强化防御
CBuff.fnRecover[127] = function(self, oUnit)
	local nDefAdd = self:GetBuffAttr(gtBAT.eFY)
	oUnit:AddAttr(gtBAT.eFY, -nDefAdd, nil, string.format("恢复BUFF:%d", self.m_nBuffID))
end
--睡眠
CBuff.fnRecover[401] = function(self, oUnit)
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eLCK, self:GetID())
end
--混乱
CBuff.fnRecover[402] = function(self, oUnit)
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eCONFUSE, self:GetID())
end

--附加隐身状态; 隐身状态下物理攻击能力会降低20%，且无法使用技能。
CBuff.fnRecover[303] = function(self, oUnit)
	local nAtkAdd = self:GetBuffAttr(gtBAT.eGJ)
	oUnit:AddAttr(gtBAT.eGJ, -nAtkAdd, nil, string.format("隐身BUFF:%d", self.m_nBuffID))
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eHIDE, self:GetID())
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eLCKFS, self:GetID())

end


---------------------------------------------被动技能类BUFF
--鬼魅BUFF
CBuff.fnRecover[901] = function(self, oUnit)
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eGM, self:GetID())
end
--高级鬼魅BUFF
CBuff.fnRecover[1901] = CBuff.fnRecover[901]
--凝神BUFF, 可以抵挡封印类异常状态
CBuff.fnRecover[905] = function(self, oUnit)
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eLCKBUFF, self:GetID())
end
--强迫BUFF, 使目标在行动时只能被迫执行防御
CBuff.fnRecover[906] = function(self, oUnit)
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eONLYFY, self:GetID())
end
--冰霜BUFF, 攻击目标时，有一定几率使目标4回合内速度降低10%
CBuff.fnRecover[907] = function(self, oUnit)
	local tBuffConf = self:GetConf()
	local nAttrID = tBuffConf.eValue[1][1]
	local nAddVal = self:GetBuffAttr(nAttrID)
	oUnit:AddAttr(nAttrID, -nAddVal, nil, string.format("恢复BUFF:%d", self.m_nBuffID))
end
--高级冰霜
CBuff.fnRecover[1907] = CBuff.fnRecover[907]
--气势BUFF, 物理伤害结果增加10%
CBuff.fnRecover[908] = function(self, oUnit)
	local tBuffConf = self:GetConf()
	local nAttrID = tBuffConf.eValue[1][1]
	local nAddVal = self:GetBuffAttr(nAttrID)
	oUnit:AddAttr(nAttrID, -nAddVal, nil, string.format("恢复BUFF:%d", self.m_nBuffID))
end
--高级气势
CBuff.fnRecover[1908] = CBuff.fnRecover[908]
--震慑BUFF, 法术伤害结果增加10%
CBuff.fnRecover[909] = function(self, oUnit)
	local tBuffConf = self:GetConf()
	local nAttrID = tBuffConf.eValue[1][1]
	local nAddVal = self:GetBuffAttr(nAttrID)
	oUnit:AddAttr(nAttrID, -nAddVal, nil, string.format("恢复BUFF:%d", self.m_nBuffID))
end
--高级震慑
CBuff.fnRecover[1909] = CBuff.fnRecover[909]
--审判BUFF, 其重生类技能或效果无效
CBuff.fnRecover[910] = function(self, oUnit)
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eIGNCS, self:GetID())
end
--幸运BUFF, 其重生类技能或效果无效
CBuff.fnRecover[911] = function(self, oUnit)
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eIGNBJ, self:GetID())
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eIGNFSBJ, self:GetID())
end
--忠心BUFF, 不会逃跑(主动逃跑)，不受强迫效果影响
CBuff.fnRecover[912] = function(self, oUnit)
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eIGNQP, self:GetID())
end


-------------------------------------------法宝技能BUFF
CBuff.fnRecover[2001] = function(self, oUnit)
	local tBuffConf = self:GetConf()
	local nAttrID  = tBuffConf.eValue[1][1]
	local nAddVal = self:GetBuffAttr(nAttrID)
	oUnit:AddAttr(nAttrID, -nAddVal, nil, string.format("法宝BUFF:%d", self.m_nBuffID))
end
CBuff.fnRecover[2002] = CBuff.fnRecover[2001]
CBuff.fnRecover[2003] = CBuff.fnRecover[2001]
CBuff.fnRecover[2004] = CBuff.fnRecover[2001]
CBuff.fnRecover[2005] = CBuff.fnRecover[2001]
CBuff.fnRecover[2006] = CBuff.fnRecover[2001]
CBuff.fnRecover[2007] = CBuff.fnRecover[2001]
CBuff.fnRecover[2008] = CBuff.fnRecover[2001]
CBuff.fnRecover[2009] = CBuff.fnRecover[2001]
CBuff.fnRecover[2010] = CBuff.fnRecover[2001]
CBuff.fnRecover[2011] = CBuff.fnRecover[2001]
CBuff.fnRecover[2012] = CBuff.fnRecover[2001]
CBuff.fnRecover[2013] = function(self, oUnit)
	oUnit:RemoveRoundFlag(CUnit.tRoundFlag.eIGNHIDE, self:GetID())
end
CBuff.fnRecover[2014] = function(self, oUnit)
	local tBuffConf = self:GetConf()
	for _, eValue in ipairs(tBuffConf.eValue) do
		local nAttrID = eValue[1]
		local nAddVal = self:GetBuffAttr(nAttrID)
		oUnit:AddAttr(nAttrID, -nAddVal, nil, string.format("法宝BUFF:%d", self.m_nBuffID))
	end
end
CBuff.fnRecover[2015] = function(self, oUnit)
	CBuff.fnRecover[2014](self, oUnit)
	self.m_nEscapeRate = 0
end


--恢复属性
function CBuff:Recover()
	local fnRecover = CBuff.fnRecover[self.m_nBuffID]
	if not fnRecover then
		return LuaTrace("BUFF:", self.m_nBuffID, "未实现")
	end
	fnRecover(self, self.m_oUnit)
end


--回合前结算
CBuff.fnBeforeRound = {}
--防御 第一回合休息附加防御状态, 并临时提高防御力10%+skill*2和灵力20%;第二回合临时提高攻击力skill*3+50和速度skill*3+80,
--速率120%, 并自动攻击目标, 伤害结果增加30%
CBuff.fnBeforeRound[102] = function(self, oUnit)
	local nCurrRound = oUnit.m_oBattle:GetRound()
	if nCurrRound ~= self.m_nAddRound+1 then --第二回合
		return
	end

	local nGJAdd = self.m_nSkillLv*3+50
	local nSDAdd = math.floor((oUnit:GetAttr(gtBAT.eSD)+self.m_nSkillLv*3+80)*0.2)
	oUnit:AddAttr(gtBAT.eGJ, nGJAdd, nil, string.format("行动前BUFF:%d", self.m_nBuffID))
	oUnit:AddAttr(gtBAT.eSD, nSDAdd, nil, string.format("行动前BUFF:%d", self.m_nBuffID))
	oUnit:AddAttr(gtBAT.eWLSH, 30, nil, string.format("行动前BUFF:%d", self.m_nBuffID))

	self:AddBuffAttr(gtBAT.eGJ, nGJAdd)
	self:AddBuffAttr(gtBAT.eSD, nSDAdd)
	self:AddBuffAttr(gtBAT.eWLSH, 30)

	oUnit:ReplaceInst(CUnit.tINST.eFS, self.m_nTarUnit, self.m_nSkillID, self.m_nBuffID)
end
--中毒BUFF
CBuff.fnBeforeRound[904] = function(self, oUnit)
	local nAddHP = math.floor(oUnit:GetAttr(gtBAT.eQX)*0.05)
	local tEBAct = {
		nAct = gtACT.eEB,
		nSrcUnit = oUnit:GetUnitID(),
		nBuffID = self.m_nBuffID,
		nTime = GetActTime(gtACT.eEB),
		tReact = {},
	}
	local sFrom = string.format("BUFF:%d", self.m_nBuffID)
	oUnit:AddAttr(gtBAT.eQX, -nAddHP, tEBAct, sFrom)
	oUnit.m_oBattle:AddRoundAction(tEBAct, sFrom)
end


----------------------------------------回合后结算
CBuff.fnAfterRound = {}
--冥思
--战斗中，每回合结束时恢复等级*0.5点法力
CBuff.fnAfterRound[902] = function(self, oUnit)
	local tBuffConf = self:GetConf()
	if tBuffConf.nID == 903 or tBuffConf.nID == 1903 then
		if oUnit:IsDeadOrLeave() then --再生对死亡目标无效
			return
		end
	end
	local nAttrID = tBuffConf.eValue[1][1]
	local nAddVal = math.floor(tBuffConf.eValue[1][2](oUnit:GetLevel()))
	local tEBAct = {
		nAct = gtACT.eEB,
		nSrcUnit = oUnit:GetUnitID(),
		nBuffID = self.m_nBuffID,
		nTime = GetActTime(gtACT.eEB),
		tReact = {},
	}
	local sFrom = string.format("BUFF:%d", self.m_nBuffID)
	oUnit:AddAttr(nAttrID, nAddVal, tEBAct, sFrom)
	oUnit.m_oBattle:AddRoundAction(tEBAct, sFrom)
end
--高级冥想
CBuff.fnAfterRound[1902] = CBuff.fnAfterRound[902]
--再生: 战斗中，每回合结束时恢复等级*1点气血
CBuff.fnAfterRound[903] =  CBuff.fnAfterRound[902]
--高级再生
CBuff.fnAfterRound[1903] = CBuff.fnAfterRound[902]
--鬼魅BUFF
CBuff.fnAfterRound[901] = function(self, oUnit)
	if oUnit:IsDead() and not oUnit:IsLeave() then
		local nReliveRounds = self.m_nBuffID == 901 and 5 or 4
		if oUnit.m_oBattle:GetRound()-self.m_nDeadRound+1 >= nReliveRounds then
			self.m_nDeadRound = 0
			local sFrom = string.format("鬼魅BUFF%d复活", self.m_nBuffID)
			oUnit:AddAttr(gtBAT.eQX, oUnit:MaxAttr(gtBAT.eQX), nil, sFrom, oUnit)
			local tFHAct = {
				nAct = gtACT.eFH,
				nSrcUnit = oUnit:GetUnitID(),
				nMP = -1,
				nHurt = oUnit:MaxAttr(gtBAT.eQX),
				nCurrHP = oUnit:GetAttr(gtBAT.eQX),
				nCurrSP = oUnit:GetAttr(gtBAT.eNQ),
				nCurrMP = oUnit:GetAttr(gtBAT.eMF),
				nTime = GetActTime(gtACT.eFH),
				nSKID = self.m_nSkillID,
			}
			oUnit.m_oBattle:AddRoundAction(tFHAct, sFrom)
		end
	end
end
--高级鬼魅BUFF
CBuff.fnAfterRound[1901] = CBuff.fnAfterRound[901]




--行动前结算
function CBuff:BeforeAction()
	if self:GetID() == 128 then
		local oRandUnit = self.m_oUnit.m_oSelectHelper:RandAny(self.m_oUnit)
		if oRandUnit then
			self.m_oUnit:ReplaceInst(CUnit.tINST.eGJ, oRandUnit:GetUnitID())
		end
	end
end

--行动后结算
function CBuff:AfterAction()
end

--回合前计算
function CBuff:BeforeRound()
	local fnBeforeRound = CBuff.fnBeforeRound[self.m_nBuffID]
	if fnBeforeRound then
		fnBeforeRound(self, self.m_oUnit)
	end
end

--回合结束计算
function CBuff:AfterRound()
	if not self:IsExpire() then
		local fnAfterRound = CBuff.fnAfterRound[self.m_nBuffID]
		if fnAfterRound then
			fnAfterRound(self, self.m_oUnit)
		end
		return
	end
	self.m_oUnit:RemoveBuff(self.m_nBuffID, nil, "BUFF过期")
end