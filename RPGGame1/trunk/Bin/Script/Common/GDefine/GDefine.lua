--全局变量,服务器是否正在关闭
gbServerClosing = false

--全局常量定义
gtGDef.tConst = 
{
	nMaxInteger = 0x4000000000000,	--最大整数(100兆g)
	nServiceShift = 24,				--会话ID中的服务ID移位
	nBaseRoleID = 10000, 			--角色ID起始值
	nMaxRoleID = 9999999, 			--角色ID上限
	nAutoSaveTime = 300, 			--自动保存间隔
	nMaxOnlineNum = 5000,        	--最大同时在线人数
	nMaxRoleNameLen = 10*3, 		--角色名字最大长度

	nRobotIDMax = 9999,            	--玩家机器人ID最大值，这个和竞技场机器人不冲突
	nRobotMoveSpeed = 200,         	--机器人移动速度
	nArenaConfRobotIDMax = 100,    	--竞技场配置的机器人ID(非玩家镜像，不进入场景, ctArenaRobotConf中配置)

	nMaxMailItemLength = 15, 		--邮件物品附件最大长度
	nMaxKnapsackAddOnce = 999, 		--背包一次最多加道具数量
}

--游戏对象类型
gtGDef.tObjType = 
{
	eRole = 1,	
	ePet = 2,	
	eMonster = 3,	
	eRobot = 4,
}

--物品类型
gtGDef.tItemType = 
{
	eCurr = 1, 		--货币
	eOther = 2, 	--其他道具
	eEquipment = 3,	--装备
}

--物品子类
gtGDef.tSubItemType = 
{
	[gtGDef.tItemType.eCurr] = 
	{
		eYuanBao = 1, 		--元宝
	}
}

--物品类定义
gtGDef.tItemClass = 
{
	[gtGDef.tItemType.eOther] = CPropBase,
	[gtGDef.tItemType.eEquipment] = CPropEqu,
}

--副本类型
gtGDef.tDupType = 
{
    eCity = 100,  --城镇(整个游戏生存期)
    eDup = 200,   --副本(动态生存期)
}

--副本类映射
gtGDef.tDupClass = 
{
	[gtGDef.tDupType.eCity]	= CDupBase,
	[gtGDef.tDupType.eDup]	= CDupBase,
}
