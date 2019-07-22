--全局变量,服务器是否正在关闭
gbServerClosing = false

--全局常量定义
gtGDef.tConst = 
{
	nServiceShift = 24,				--会话ID中的服务ID移位
	nMaxInteger = 0x4000000000000,	--最大整数(100兆g)
	nBasePlayerID = 10000, 			--玩家ID起始值
	nMaxPlayerID = 9999999, 		--玩家ID上限
	nAutoSaveTime = 300, 			--自动保存间隔
	nMaxOnlineNum = 5000,        	--最大同时在线人数
	nMaxRoleNameLen = 10*3, 		--角色名字最大长度

	nArenaConfRobotIDMax = 100,    	--竞技场配置的机器人ID(非玩家镜像，不进入场景, ctArenaRobotConf中配置)
	nRobotIDMax = 9999,            	--玩家机器人ID最大值，这个和竞技场机器人不冲突
	nRobotMoveSpeed = 120,         	--机器人移动速度

	nMaxMailItemLength = 15, 		--邮件物品附件最大长度
}

--游戏对象类型
gtGDef.tObjType = 
{
	eRole = 1,	
	eMonster = 2,	
}

--物品类型
gtGDef.tItemType = 
{
	eCurr = 1, 		--货币
	eOther = 2, 	--其他(道具)
	eEquipment = 3,	--装备
}

--物品类定义
gtGDef.tItemClass = 
{
	[gtGDef.tItemType.eOther] = CPropBase,
	[gtGDef.tItemType.eEquipment] = CPropEqu,
}

--物品子类
gtGDef.tSubItemType = 
{
	[gtGDef.tItemType.eCurr] = 
	{
		eYuanBao = 1, 		--元宝
	}
}

--副本类型
gtGDef.tDupType = 
{
    eCity = 100,  --城镇
    eDup = 200,   --副本
}