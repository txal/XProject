


gnPVPActivityQuickTeamInterval = 60   --快捷组队广播间隔时间
gnPVPActivityAutoMatchInterval = 60   --自动匹配战斗，间隔时间

--PVP活动类型, 不同于pvp活动ID, 用于区分活动类型(可以支持不同ID的多个同类型活动)
gtPVPActivityType =
{
	eSchoolArena = 1,     --首席争霸
	eQimaiArena = 2,      --七脉会武
	eQingyunBattle = 3,   --青云之战
	eUnionArena = 4,	  --帮战
}

--PVP活动管理器
gtPVPActivityMgrMap = 
{
	[gtPVPActivityType.eSchoolArena] = CSchoolArenaMgr,        --首席争霸
	[gtPVPActivityType.eQimaiArena] = CQimaiArenaMgr,          --七脉会武
	[gtPVPActivityType.eQingyunBattle] = CQingyunBattleMgr,    --青云之战
	[gtPVPActivityType.eUnionArena] = CUnionArenaMgr,		   --帮战
}


gtPVPActivityState = 
{
	ePrepare = 1,        --准备
	eStarted = 2,        --已开始
	eEnd = 3,            --已结束
}

gtPVPActivityRoleState = 
{
	ePrepare = 1,            --准备
	eNormal = 2,             --正常
	eBattle = 3,             --战斗
	eBattleProtected = 4,    --进战保护 
	eEnd = 5,                --已结束
}


