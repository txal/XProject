--商店类型定义

gtShopType = 
{
	eDrugStore = 101,   --药店 101
	eDressStore = 102,  --服饰店
	eArmStore = 103,    --武器店
	eGoldStore = 104,   --元宝商城
	eArenaScore =105,    --积分商城
}

gtShopName = 
{
	[gtShopType.eDrugStore] = '药店',
	[gtShopType.eDressStore] = '服装店',
	[gtShopType.eArmStore] = '武器店',
	[gtShopType.eGoldStore] = '元宝商城',
	[gtShopType.eArenaScore] = '积分商城',
}

gtShopClass = 
{
	[gtShopType.eDrugStore] = CDrugStore,
	[gtShopType.eDressStore] = CDressStore,
	[gtShopType.eArmStore] = CArmStore,
	[gtShopType.eGoldStore] = CGoldStore,
	[gtShopType.eArenaScore] = CArenaScoreStore,
}

