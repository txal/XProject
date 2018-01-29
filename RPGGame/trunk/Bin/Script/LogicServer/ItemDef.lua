--游戏对象类型
gtItemType = 
{
	eNone = 0,
    eProp = 1,		--道具
    eCurr = 2,		--货币
    eGongNv = 3, 	--宫女
    eFeiZi = 4, 	--妃子
    eMingChen = 5, 	--名臣
    eFashion = 6, 	--时装
}

--货币类型
gtCurrType = 
{
	eVIP = 1, 			--VIP等级
	eYuanBao = 2,		--元宝
	eYinLiang = 3,		--银两
	eLiangCao = 4,		--粮草
	eBingLi = 5,		--兵力
	eHuoLi = 6,			--活力(皇子单独计算)
	eWenHua = 7,		--文化值
	eTiLi = 8,			--体力(姻缘点)
	eMaxTiLi = 9,		--体力上限(姻缘点上限)
	eJingLi = 10,		--精力
	eMaxJingLi = 11,	--精力上限
	eGuoLi = 12,		--国力
	eShiLi = 13, 		--势力
	eWaiJiao = 14, 		--外交(役事点)
	eGrow = 15, 		--特定知己成长点
	eQinMi = 16, 		--特定知己亲密度
	eRandGrow = 17, 	--随机知己成长点
	eRandQinMi = 18,	--随机知己亲密度
	eRandHaoGan = 19, 	--随机知己好感度
	eZouZhang = 20, 	--奏章
	eQingAnZhe = 21,    --请安折
	eCaiDe = 22, 		--妃子才德
	eSendTimes = 23, 	--军机处出使次数
	eWeiWang = 24, 		--威望
	eZhanJi = 25, 		--随机知己战绩
	eShang = 26, 		--智
	eNong = 27, 		--才
	eZheng = 28, 		--魅
	eJun = 29, 			--武
	eXunFang = 30,      --寻访次数(体力点)
	eUnionContri = 31, 	--联盟贡献
	eUnionActivity = 32, 	--联盟活跃点
	eUnionExp = 33, 		--联盟经验
	eNeiGeTimes = 34,		--内阁征收次数
	eHZExp = 35, 			--皇子经验
	eVIPExp = 36, 			--VIP经验
	ePartyScore = 37, 		--宴会积分
	ePartyActive = 38, 		--宴会活跃
	eCountryExp = 39, 		--国家经验
	eGDScore = 40, 			--宫斗积分
	eCSScore = 41, 			--军机处出使积分
	eSKPoint = 42, 			--技能点
	eHaoGan = 43, 			--好感度
	eActivity = 44, 		--活跃度(每日任务)
	eRandSKP = 45, 			--随机知己成长点
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
	eMCZhenBao = 21, 		--知己赏赐珍宝道具	
	eFZZhenBao = 22, 		--知己送礼珍宝道具
	eHZJiaSu = 24, 			--宠物成长加速道具
	eWaBao = 25,			--挖宝用道具
	eStrength = 26,			--强化材料
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
	[gtCurrType.eWenHua] = 10003, --文化
	[gtCurrType.eBingLi] = 10004, --兵力
}
