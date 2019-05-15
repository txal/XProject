--战斗类型
gtBTT = 
{
	ePVE = 1,
	ePVP = 2,
	eArena = 3,
}

--战斗结束类型
gtBTRes = 
{
	eNormal = 1, --正常
	eEscape = 2, --逃避
	eExcept = 3, --异常,强制
	eRounds = 4, --回合限制
}

--百分比属性表
gtRatioAttr = {
	[gtBAT.eWLSH] = true,
	[gtBAT.eWLSS] = true,
	[gtBAT.eFSSH] = true,
	[gtBAT.eFSSS] = true,
	[gtBAT.eFYMZ] = true,
	[gtBAT.eFYKX] = true,
	[gtBAT.eFSBJ] = true,
	[gtBAT.eFSKB] = true,
	[gtBAT.eTPL] = true,
	[gtBAT.eZBL] = true,
	[gtBAT.eFSMZ] = true,
	[gtBAT.eFSSB] = true,
	[gtBAT.eMZL] = true,
	[gtBAT.eSBL] = true,
	[gtBAT.eBJL] = true,
	[gtBAT.eKBL] = true,
	[gtBAT.eSH] = true,
	[gtBAT.eSS] = true,
}

--行动定义
gtACT = 
{
	eGJ = 1, 	--物攻
	eSB = 2, 	--闪避
	eBH = 3, 	--保护
	eSS = 4, 	--受伤
	eSW = 5, 	--死亡
	eCT = 6, 	--撤退
	eFY = 7, 	--防御
	eFS = 8, 	--法术
	eAB = 9, 	--增加BUFF
	eDB = 10, 	--移除BUFF
	eWP = 11, 	--物品
	eFH = 12,	--复活
	eZH = 13, 	--召唤
	eZL = 14, 	--治疗
	eEB = 15, 	--执行BUFF
	eWarSpeak = 16, --喊话
	eSH1 = 17, 	--摄魂扣除
	eSH2 = 18, 	--摄魂奖励
	eHZ = 19, 	--被动技能喊招
}

--取行为时间
function GetActTime(nAct, nSkillID)
	local tConf = ctActionTimeConf[nAct]
	if not tConf then
		return LuaTrace("指令耗时配置不存在", nAct, debug.traceback())
	end
	if nAct == gtACT.eFS then
		local tSKConf = CUnit:GetSkillConf(nSkillID)
		if tSKConf then
			return tSKConf.nSkillTime
		end
	end
	return tConf.nTime
end

--增加属性模块类型
gtAddAttrModType =
{
	eShiLianTask = 1,
	eGuaJi = 2,
}
