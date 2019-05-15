
--PetDefine.lua

--玩家宠物携带个数
getCarryCap = 
{
	eDefaultCcarry 		= 7,	--宠物携带列表默认个数
	eMaxCarry 			= 20,	--宠物列表最大携带个数
	eExpansionTimes 	= 1,	--宠物单次扩充个数
}

gtPetAutoPointState = 
{
	eAutoState = 1,		--自动状态
	eNoAutoState = 2,	--非自动状态
}

--属性生产方式分类
getPetType = 
{
	eYS					= 1,	--野生
	eBB 				= 2,	--宝宝
	EBY 				= 3,	--变异
	eTherion 			= 4,	--圣兽
	eMythicalAanimals 	= 5, 	--神兽
}

--攻击偏向类型
getAttackType = 
{
	eQuilibrium 		= 1,	  --均衡
	ePhysics 			= 2,	  --物理
	eSpell 				= 3,	  --法术
}

--装备位置定义
gtPetEquPart = 
{
	eCollar= 1, 	--表示头盔
	eArmor	= 2,	--表示为项圈
	eTalisman = 3,	--表示护符
	eaccies	= 4,	--表示饰品
}

--宠物寿命分类
getPetLifiType = 
{
	eLifi 				= 0, 	--永生，非0为不是永生，策划自行配置。
}

--宠物状态获取
gtSTT = 
{
	eXZ					= 1,	--休战
	eCZ					= 2,	--参战
}
--技能分类
getPetSkillsClassify =
{
	
	eLowlevel 			= 1,	--低级技能
	eAdvanced 			= 2,	--高级技能		
	eSpecial	 		= 3,	--特殊技能
}

getSkillsClassify = 
{

	eInitiative			= 1,	--主动技能
	ePassive			= 2,	--被动技能
}

gtEquitPos = 
{
	eCollar 			= 1,	--表示项圈
	hmtkm
}

gtEquitType = 
{
	eCollar 			= 1, 	--表示为项圈
	eArmor				= 2,	--表示头盔
	eTalisman			= 3,	--表示护符
	eaccies				= 4,	--表示饰品
}
getQualiName =
{
	[1] 				= "攻击",
	[2] 				= "防御",
	[3] 				= "体力",
	[4] 				= "法力",
	[5] 				= "速度",
}

--被动技能分类
gtPasSkillType = 
{
	eEffAttr = 1, 	--影响属性
	eEffRatio = 2, 	--影响效率
	ePhyAtk = 3, 	--物理攻击
	eSpecial = 4, 	--特殊
	eBePhyAtk = 5, 	--物理受击
	eDead = 6, 		--死亡
	eRestraint = 7, --克制
	eRecover = 8, 	--回复
	eDiscount = 9, 	--降低消耗
	eMagAtk = 10, 	--法攻触发
	eResSeal = 11, 	--抗封印
	eAttrAbsorb = 12, 	--属性吸收
	eAttrInjury = 13, 	--属性增伤
	eInBattle = 14, 	--入战触发
}
