--排行榜
gtRankingDef = 
{
	eKejuRanking = 1,			--科举排行
	eColligatePowerRanking = 12, --综合战力排行
	eRolePowerRanking = 13, 	--人物战力榜
	eRoleLevelRanking = 14, 	--人物等级榜
	ePetScoreRanking = 15, 		--宠物评分榜
	eUnionLevelRanking = 16, 	--帮派等级榜
	eHouseAssetsRanking = 17, 	--家园资产榜

	eGWPowerRanking = 21, 	--鬼王宗
	eQYPowerRanking = 22, 	--青云门
	eHHPowerRanking = 23, 	--合欢派
	eSWPowerRanking = 24, 	--圣巫教
	eTYPowerRanking = 25, 	--天音寺

	eArenaScoreRanking = 31,	--竞技场积分

	eWeekPopularityRanking = 41,--周人气榜
	ePopularityRanking = 42,	--总人气榜
	eFriendDegreeRanking = 43,	--总好友度榜
}

--排行榜对应类
gtRankingClassDef = 
{
	[gtRankingDef.eKejuRanking] = CKejuRanking,		
	[gtRankingDef.eColligatePowerRanking] = CColligatePowerRanking,
	[gtRankingDef.eRolePowerRanking] = CRolePowerRanking,
	[gtRankingDef.eRoleLevelRanking] = CRankingBase,
	[gtRankingDef.ePetScoreRanking] = CPetScoreRanking,
	[gtRankingDef.eUnionLevelRanking] = CUnionLevelRanking,
	[gtRankingDef.eHouseAssetsRanking] = CRankingBase,
	[gtRankingDef.eGWPowerRanking] = CRankingBase,
	[gtRankingDef.eQYPowerRanking] = CRankingBase,
	[gtRankingDef.eHHPowerRanking] = CRankingBase,
	[gtRankingDef.eSWPowerRanking] = CRankingBase,
	[gtRankingDef.eTYPowerRanking] = CRankingBase,
	[gtRankingDef.eArenaScoreRanking] = CRankingBase,
	[gtRankingDef.eWeekPopularityRanking] = CWeekPopularityRanking,
	[gtRankingDef.ePopularityRanking] = CRankingBase,
	[gtRankingDef.eFriendDegreeRanking] = CRankingBase,
}

--门派对应排行榜
gtSchoolRankingDef = 
{
	[gtSchoolType.eGW] = gtRankingDef.eGWPowerRanking,
	[gtSchoolType.eQY] = gtRankingDef.eQYPowerRanking,
	[gtSchoolType.eHH] = gtRankingDef.eHHPowerRanking,
	[gtSchoolType.eSW] = gtRankingDef.eSWPowerRanking,
	[gtSchoolType.eTY] = gtRankingDef.eTYPowerRanking,
}