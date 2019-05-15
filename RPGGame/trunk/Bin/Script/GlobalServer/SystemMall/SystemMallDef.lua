--商店类型定义

gtShopType = 
{
	eChamberCore = 101,  	--商会
	eShop = 102,  			--商城
	eCSpecial = 103,    	--特惠
	eCRecharge = 104,   	--充值
	eCBuy = 105,			--购买金币,银币,金锭
}

gtShopName = 
{
	[gtShopType.eChamberCore] = '商会',
	[gtShopType.eShop] = '商城',
	[gtShopType.eCSpecial] = '特惠',
	[gtShopType.eCRecharge] = '充值',
}

gtShopClass = 
{
	[gtShopType.eChamberCore] = CChamberCore,
	[gtShopType.eShop] = CShop,
	[gtShopType.eCSpecial] = CSpecial,
	[gtShopType.eCRecharge] = CRecharge,
}

gtSubShopType =
{
	eQizhenShop = 201,		--奇珍
	ePowerfulShop = 202,	--变强
	eDailyShop = 203,		--每日限购
	eWeeklyShop = 204,		--每周限购
	eIntegralShop = 205,	--积分兑换
}

gtShopCostName = 
{	[201] = "奇珍异宝消耗",
	[202]= 	"功能玩法消耗",
	[203] =  "商城每日限购消耗",
	[204] =  "商城每周限购消耗",
	[301] =  "侠义积分兑换消耗",
	[302] =  "竞技积分兑换消耗",
	[401] = "特惠购买消耗",
}

gtGoidType = 
{
	[1] = 100,					--金币比例
	[2] = 10000,				--银币比例
}

gtBuyType = 
{
	[1] = 4,		--金币
	[2] = 5,		--银币
	[3] = 21,		--帮贡
	[4] = 24,		--金锭
	[5] = 27,		--灵气
	[6] = 28,		--内丹
}

--获取消耗货币名
gtMoneyName = 
{
	[2] = "元宝不足",
	[3] = "绑定元宝不足",
	[4] = "金币不足",
	[5] = "银币不足",
	[6] = "活力不足",
	[9] = "潜力点不足",
	[10] = "竞技令不足",
	[18] = "侠义值不足",
	[19] = "活跃值不足",
	[20] = "帮贡不足",
	[24] = "金锭不足", 
	[25] = "福缘值不足",
	[26] = "蓝钻不足",
	[27] = "灵气不足",
	[28] = "内丹不足",
	[29] = "妖晶不足",
	[230] = "元宝不足",
}
