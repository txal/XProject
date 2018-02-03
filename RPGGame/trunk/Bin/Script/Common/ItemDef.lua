--游戏对象类型
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
	eYinLiang = 3,	--银两
	eShang = 4, 	--商
	eNong = 5,		--农
	eZheng = 6,		--政
	eJun = 7, 		--军
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

--道具详细类型
gtDetType = 
{
}

--资质类型
gtQuaType = 
{
	eShang = 1, 		--商
	eNong = 2, 			--农
	eZheng = 3, 		--政
	eJun = 4, 			--军
}

--资质名
gtQuaNameMap = 
{
	[1] = "智力",
	[2] = "才力",
	[3] = "魅力",
	[4] = "武力",
}

--属性值
gtAttrMap = 
{
	[1]	= gtCurrType.eShang, 	--商
	[2] = gtCurrType.eNong,		--农
	[3] = gtCurrType.eZheng,	--政
	[4] = gtCurrType.eJun, 		--军
}

--货币道具映射
gtCurrProp = 
{
	[gtCurrType.eYuanBao] = 10001, 	--元宝
	[gtCurrType.eYinLiang] = 10002, --银两
}
