--对象类型
gtItemType = 
{
	eNone = 0,
    eProp = 1,		--道具
    eCurr = 2,		--货币
}

--货币类型
gtCurrType = 
{
	eVIP = 1, 		--VIP等级
	eYuanBao = 2,	--元宝
	eYinBi = 3,		--银币
	eTongBi = 4,	--铜币
	eVitality = 5, 	--活力
	nExp = 6, 		--经验
	eStoreExp = 7, 	--储备经验
	ePotential = 8, --潜力点
}

--道具类型
gtPropType = 
{
	eCurr = 1, 			--货币道具(在道具界面可以直接使用)
	eTeShu = 2, 		--特殊道具(没有使用或出售按钮,在特定地方使用和消耗,但在国库界面中无法使用)
	eCaiLiao = 3, 		--材料道具(在道具界面只能出现出售按钮)
	eBaoXiang = 4,		--宝箱道具(在道具界面可以直接使用)
	eXiaoHao = 5, 		--消耗品(在道具界面可以直接使用)
}

--道具具体类型
gtDetType = 
{
}

--货币类型->货币道具映射
gtCurrProp = 
{
	[gtCurrType.eYuanBao] = 10001, 	--元宝
	[gtCurrType.eYinBi] = 10002, 	--银币
}

--场景对象类型
gtObjType = 
{
	eRole = 1,	 	--角色对象
	eMonster = 2, 	--怪物对象
}

--门派类型
gtSchoolType = 
{
	eGW = 1, 	--鬼王
	eQY = 2, 	--青云
	eTY = 3,	--天音
	eHH = 4, 	--合欢
	eSW = 5, 	--圣巫
}