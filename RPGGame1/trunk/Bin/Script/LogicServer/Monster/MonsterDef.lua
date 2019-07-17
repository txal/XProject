--怪物类型
gtMonType =
{
	eNormal = 1, 	--普通怪,进入场景
	eTaskNpc = 2, 	--任务战斗Npc(战斗时创建),不进入场景
	eInvisible = 3, --仅仅战斗，不进入场景被人所看到 
	ePublicNpc = 4, --场景NPC
	ePickPublicNpc = 5, --拾取NPC
	ePalanquin = 6, --花轿
	eCreateByGroup = 7,	--根据战斗组产生的怪
	eOldManNpc = 8,	--月老刷新道具
	eWeddingCandy = 9, --婚礼糖果
}


--怪物类
gtMonClass =
{
	[gtMonType.eNormal] = CMonsterNormal,
	[gtMonType.eTaskNpc] = CMonsterTaskNpc,
	[gtMonType.eInvisible] = CMonsterInvisible,
	[gtMonType.ePublicNpc] = CPublicNpc,	
	[gtMonType.eWeddingCandy] = CWeddingCandyNpc,
	[gtMonType.ePalanquin] = CPalanquinNpc,
	[gtMonType.eCreateByGroup] = CMonsterByGroup,
	[gtMonType.eOldManNpc] = COldManNpc,
}






