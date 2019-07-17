--NPC类型
gtNpcType = 
{
	eFuncNpc = 1, 	--功能NPC
	eTalkNpc = 2, 	--对话NPC
	eTaskNpc = 5, 	--任务NPC
	eCollectNpc = 6, --采集NPC
	eGoldBoxNpc = 7, --金宝箱NPC
}

--NPC类映射
gtNpcClass = 
{
	[gtNpcType.eFuncNpc] = CNpcFunc,
	[gtNpcType.eTalkNpc] = CNpcTalk,
	[gtNpcType.eTaskNpc] = CNpcTalk,
	[gtNpcType.eCollectNpc] = CNpcTalk,
	[gtNpcType.eGoldBoxNpc] = CNpcGoldBox,
}