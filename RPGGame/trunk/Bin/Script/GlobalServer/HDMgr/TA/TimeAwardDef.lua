--限时奖励类型
gtTAType = 
{
	eYB = 1, 	--累计消耗银币
	eJB = 2, 	--累计消耗金币
	eXY = 3, 	--累计仙缘次数
	eZZD = 4, 	--累计消耗宠物资质丹
	eDZ = 5, 	--累计被点赞次数 fix pd
	eHYD = 6, 	--友好度度涨幅
	eHL = 7, 	--累计消耗活力
	eJJC = 8, 	--竞技积分涨幅
	eTZZ = 9, 	--累计消耗挑战书
	eTB = 10, 	--累计探宝次数（个人空间） fix pd
	eXYX = 11, 	--累计小游戏私人房对战次数 （房卡模式下进行次数） fix pd
	eXD = 12, 	--累计消耗 仙豆（小游戏筹码） fix pd
}

--活动对应类
gtTAClass = 
{
	[gtTAType.eYB] = CTABase, 	--累计消耗银币
	[gtTAType.eJB] = CTABase, 	--累计消耗金币
	[gtTAType.eXY] = CTABase, 	--累计仙缘次数
	[gtTAType.eZZD] = CTABase, 	--累计消耗宠物资质丹
	[gtTAType.eDZ] = CTABase, 	--累计被点赞次数
	[gtTAType.eHYD] = CTABase, 	--友好度度涨幅
	[gtTAType.eHL] = CTABase, 	--累计消耗活力
	[gtTAType.eJJC] = CTABase, 	--竞技积分涨幅
	[gtTAType.eTZZ] = CTABase, 	--累计消耗挑战书
	[gtTAType.eTB] = CTABase, 	--累计探宝次数（个人空间）
	[gtTAType.eXYX] = CTABase, 	--累计小游戏私人房对战次数 （房卡模式下进行次数）
	[gtTAType.eXD] = CTABase, 	--累计消耗 仙豆（小游戏筹码）
}