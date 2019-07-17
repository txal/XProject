CRankingMgr = CRankingMgr or class()

CRankingBase = CRankingBase or class()
CKejuRanking = CKejuRanking or class(CRankingBase)
CPetScoreRanking = CPetScoreRanking or class(CRankingBase)
CUnionLevelRanking = CUnionLevelRanking or class(CRankingBase)
CRolePowerRanking = CRolePowerRanking or class(CRankingBase)
CColligatePowerRanking = CColligatePowerRanking or class(CRankingBase)
CWeekPopularityRanking = CWeekPopularityRanking or class(CRankingBase)


require("RankingMgr/RankingBase")
require("RankingMgr/KejuRanking")
require("RankingMgr/PetScoreRanking")
require("RankingMgr/UnionLevelRanking")
require("RankingMgr/RolePowerRanking")
require("RankingMgr/ColligatePowerRanking")
require("RankingMgr/WeekPopularityRanking")


--放到最后
require("RankingMgr/RankingDef")
require("RankingMgr/RankingMgr")
require("RankingMgr/RankingRpc")
