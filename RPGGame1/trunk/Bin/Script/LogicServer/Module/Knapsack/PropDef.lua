--道具类型
gtPropType = 
{
	--eBesto = 1, 	--宝图
	eTreasure = 2,	--珍宝
	eEquipment = 3,	--装备
	eCooking = 4,	--烹饪
	eCurr = 5, 		--货币(虚拟)
	eOther = 6, 	--其他
	eGift = 7,		--礼包
	eAntique = 8, 	--古董
	eGem = 9, 		--宝石
	eFmt = 10, 		--阵法道具
	eFmtChip = 11,	--阵法碎片
	ePraMed = 12, 	--修炼丹药
	eMedicine = 13, --药物
	ePetEqu = 14, 	--宠物装备
	eFlower = 15, 	--鲜花道具
	ePetSkillLower = 16,	--低级技能书
	ePetSkillSenior = 17, 	--高级技能书
	eDoublePoint = 18, 		--双倍点数丹
	eUnionProp = 19, 		--帮派神诏
	ePiXiuZhiBao = 20,		--貔貅之宝
	eShiZhuang = 21,		--时装道具
	eQiLingExpDan = 22,		--器灵经验丹
	eShiZhuangStuff = 23, 	--时装碎片
	eFuMoFu = 25, 			--附魔符
	eArenaTicket = 26,      --竞技令
	eFaBao = 27, 		--法宝(法宝直接进法宝背包)
	eHuiShenDan = 28, 		--回神丹
	eRoleExp = 29, 			--人物经验心得
	eSpiritBottle = 30,     --灵气瓶
	eArtifactChip = 31,		--神器碎片
	eArtifact = 32, 		--神器
	ePrecious = 33,			--宝物类道具
	ePartner = 34,          --仙侣道具
	eWeddingCandy = 35,     --喜糖
	eHouseFurniture = 36,	--家园家具
	eFaBaoChip = 37,		--法宝碎片
	ePetProp = 38,			--宠物道具
	ePartnerDebris = 39, 	--仙侣碎片
	eRarePrecious = 40,     --珍宝
	eFairyReward = 41,		--仙侣赏赐道具
}

--道具类映射
gtPropClass = 
{
	[gtPropType.eOther] = CPropBase,
	[gtPropType.eEquipment] = CPropEqu,
	[gtPropType.eCooking] = CPropCoo,
	[gtPropType.eGift] = CPropGift,
	[gtPropType.eFmt] = CPropFmt,
	[gtPropType.eFmtChip] = CPropGuiGuFragment,
	[gtPropType.eGem] = CPropGem,
	[gtPropType.ePraMed] = CPropPra,
	[gtPropType.eMedicine] = CPropMed,
	[gtPropType.ePetEqu] = CPetEqu,
	[gtPropType.eTreasure] = CPropTre,
	[gtPropType.eFlower] = CPropBase,
	[gtPropType.ePetSkillLower] = CPropBase,
	[gtPropType.ePetSkillSenior] = CPropBase,
	--[gtPropType.eDoublePoint] = CPropDoublePoint,
	[gtPropType.eUnionProp] = CPropUnion,
	[gtPropType.ePiXiuZhiBao] = CPropPiXiuZhiBao,
	[gtPropType.eShiZhuang] = CPropShiZhuang,
	[gtPropType.eQiLingExpDan] = CPropQiLingExpDan,
	[gtPropType.eFuMoFu] = CPropFuMoFu,
	[gtPropType.eArenaTicket] = CPropArenaTicket,
	[gtPropType.eHuiShenDan] = CPropHuiShenDan,
	[gtPropType.eRoleExp] = CPropRoleExp,
	[gtPropType.eSpiritBottle] = CPropSpiritBottle,
	[gtPropType.eArtifactChip] = CPropArtifactChip,
	[gtPropType.eArtifact] = CPropArtifact,
	[gtPropType.ePrecious] = CPrecious,
	[gtPropType.ePartner] = CPropPartner,
	[gtPropType.eWeddingCandy] = CPropWeddingCandy,
	[gtPropType.eHouseFurniture] = CPropHouseFurniture,
	[gtPropType.eShiZhuangStuff] = CPropShiZhuangStuff,
	[gtPropType.eFaBaoChip] = CPropFaBaoChip,
	[gtPropType.ePetProp] = CPropPetChipConvert,
	[gtPropType.ePartnerDebris] = CPropPartnerDebris,
	[gtPropType.eRarePrecious] = CPropBase,
	[gtPropType.eFairyReward] = CFairyReward,
}

--装备位置定义
gtEquPart = 
{
	eWeapon = 1, 	--武器
	eHat = 2, 		--帽子
	eClothes = 3,	--衣服
	eNecklace = 4, 	--项链
	eBelt = 5, 		--腰带
	eShoes = 6, 	--鞋子
}

gtEquPartName = 
{
	[gtEquPart.eWeapon] = "武器",
	[gtEquPart.eHat] = "帽子",
	[gtEquPart.eClothes] = "衣服",
	[gtEquPart.eNecklace] = "项链",
	[gtEquPart.eBelt] = "腰带",
	[gtEquPart.eShoes] = "鞋子",
}

gtPropBoxType = 
{
	eBag = 1,          --背包
	eEquipment = 2,    --装备栏
	eStorage = 3,      --仓库
}

gnEquipmentMaxStrengthenLv = 25  --装备最大强化等级

--装备位置定义
gtPetEquPart = 
{
	eCollar= 1, 	--表示头盔
	eArmor	= 2,	--表示为项圈
	eTalisman = 3,	--表示护符
	eaccies	= 4,	--表示饰品
}

--装备出处
gtEquSourceType = {
	eShop = 1,		--商店装
	eWild = 2,		--野外装
	eManu = 3,		--打造装 
	eTest = 9999,   --测试装备
}

--药品子类
gtMedType = 
{
	eWine = 1, 		--酒类	
	eHerbal = 2, 	--草药
	eSpecial = 3, 	--特效药
}

--烹饪道具子类
gtCookType = 
{
	eJHJ = 1, 	--叫花鸡
	eCWYB = 2, 	--宠物月饼
	eCPRZ = 3,	--脆皮乳猪
	eCSM = 4,	--长寿面
	eNEH = 5, 	--女儿红
	eZLJ = 6, 	--珍露酒
	eSDJ = 7, 	--蛇胆酒
	eZSMS = 8, 	--醉生梦死
}