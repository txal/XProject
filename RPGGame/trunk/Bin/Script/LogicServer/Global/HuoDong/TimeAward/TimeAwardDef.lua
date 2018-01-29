--限时奖励类型
gtTAType = 
{
	eYL = 1, 	--累计消耗银两
	eWH = 2, 	--累计消耗文化
	eBL = 3, 	--累计消耗兵力
	eXF = 4, 	--累计寻访次数 fix pd
	eZZG = 5, 	--累计消耗资质果
	eGL = 6, 	--势力涨幅
	eXB = 7, 	--累计寻宝次数 fix pd
	eYB = 8, 	--累计消耗元宝
	eLY = 9, 	--累计联姻次数
	eQM = 10, 	--亲密度涨幅
	eHLD = 11, 	--累计消耗活力丹
	eSZD = 12, 	--累计消耗双子丹
	eZS = 13, 	--子嗣数量涨幅
	eWW = 14, 	--心机涨幅
	eTZS = 15, 	--累计消耗挑战书
	eGD = 17, 	--宫斗积分涨幅
	eSX = 19, 	--累计查阅私信数
	eYH = 23, 	--累计赴宴次数
	eTF = 24, 	--讨伐异邦 fix pd
	eJS = 25, 	--击杀异邦 fix pd
	eJYYL = 26,	--经营银两
	eJYWH = 27, --经营文化
	eJYBL = 28, --经营兵力
}

--活动对应类
gtTAClass = 
{
	[gtTAType.eYL] = CTABase,
	[gtTAType.eWH] = CTABase,
	[gtTAType.eBL] = CTABase,
	[gtTAType.eXF] = CTABase,
	[gtTAType.eZZG] = CTABase,
	[gtTAType.eGL] = CTABase,
	[gtTAType.eXB] = CTABase,
	[gtTAType.eYB] = CTABase,
	[gtTAType.eLY] = CTABase,
	[gtTAType.eQM] = CTABase,
	[gtTAType.eHLD] = CTABase,
	[gtTAType.eSZD] = CTABase,
	[gtTAType.eZS] = CTABase,
	[gtTAType.eWW] = CTABase,
	[gtTAType.eTZS] = CTABase,
	[gtTAType.eGD] = CTABase,
	[gtTAType.eSX] = CTABase,
	[gtTAType.eYH] = CTABase,
	[gtTAType.eTF] = CTABase,
	[gtTAType.eJS] = CTABase,
	[gtTAType.eJYYL] = CTABase,
	[gtTAType.eJYWH] = CTABase,
	[gtTAType.eJYBL] = CTABase,
}