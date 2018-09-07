--战斗属性定义(C++同步)
gtAttrDef = 
{
	eAtk = 1,		--攻击(值)
	eDef = 2,		--防御(值)
	eHP = 3,		--血量(值)
	eCrit = 4,		--暴击率(百分数10000倍)
	eCritDmg = 5, 	--暴击伤害(百分数10000倍)
	eCritRes = 6, 	--暴击抗性(百分数10000倍)
	eAtkAdj = 7, 	--攻击修正(百分数10000倍)
	eDefAdj = 8,	--防御修正(百分数10000倍)
	eHPAdj = 9,		--血量修正(百分数10000倍)
	ePhyDmg = 10,	--动能伤害(百分数10000倍)
	eLonDmg = 11,	--离子伤害(百分数10000倍)
	eRadDmg = 12,	--射线伤害(百分数10000倍)
	ePlaDmg	= 13,	--电浆伤害(百分数10000倍)
	eFireDmg = 14,	--火焰伤害(百分数10000倍)
	eMisDmg = 15,	--飞弹伤害(百分数10000倍)
	eNorDmg = 16,	--普通伤害(百分数10000倍)
	eSpeed = 17,	--速度(值)
}

--战斗类型(C++同步)
gtBattleType =
{
	eTest = 1, 		--测试
	eSingleDup = 2,	--单人
	eBugStorm = 3,	--异虫风暴
	eBugHole = 4, 	--异虫巢穴
}

--阵营类型(C++同步)
gtCampType = 
{
	eAttacker = 1,	--攻方
	eDefender = 2,	--守方
	eFreeLand = 3,	--自由阵营(除了中立都可以打/被打)
	eNeutral = 4,	--中立阵营(谁都不可以打/被打)
}