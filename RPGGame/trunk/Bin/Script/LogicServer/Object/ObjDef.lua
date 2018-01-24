--游戏对象类型
gtObjType = 
{
	eNone = 0,
    ePlayer = 1,	--玩家
    eMonster = 2,	--怪物
    eArm = 3,		--装备
    eProp = 4,		--背包道具
    eWSProp = 5, 	--工坊道具
    eCurr = 6,		--货币
    eRobot = 10,	--机器人 
    eSceneDrop = 11,--场景掉落
    eDetetor = 12,	--探测器
}

--货币类型
gtCurrType = 
{
	eGold = 1,			--金币
	eMoney = 2,			--钻石
	eExp = 3,			--经验
	eVIP = 4,			--VIP
	eGVEFame = 5, 		--GVE声望
	eGVGFame = 6, 		--GVG声望

	--[7,12]工坊技能熟练度占坑
	eSQMaster = 7,		--手枪熟练度
	eBQMaster = 8,		--步枪熟练度
	eJQMaster = 9,		--机枪熟练度
	eTZQMaster = 10,	--特种枪熟练度
	eSLMaster = 11,		--手雷熟练度
	eSPXMaster = 12,	--饰品箱熟练度
}
