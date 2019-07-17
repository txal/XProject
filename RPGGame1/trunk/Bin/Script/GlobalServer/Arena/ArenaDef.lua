



--竞技场模块的一些系统参数定义，集中写在此处，方便后续修改，注意行尾的逗号
gtArenaSysConf = 
{
bSwitchExceptionStart = false,   --结算异常情况下，是否正常开启服务器
bRankDebug = false,              --排行榜测试
-------- DB相关 ---------
nMaxSecSaveNum = 500,            --每秒最大保存数量
nDefaultSecSaveNum = 50,         --每秒默认保存数量
nTargetSaveTime = 300,           --全部保存完的目标时间(单位秒)
-------------------------

nDefaultDailyChallenge = 10,      --每日默认挑战次数
nChallengeYuanbaoExchCount = 2,  --每日可用元宝兑换的挑战次数
-- nChallengeYunbaoExchCost = 50,   --使用元宝兑换挑战次数的花费
nChallengeYunbaoExchCost = ctArenaSysConf["nPurchChallCost"].nVal,

nChallengeYuanbaoExchCount1 = 999, 	--每日可用元宝兑换的挑战次数
nChallengeYunbaoExchCost1 = 60, 	--使用元宝兑换挑战次数首次花费

--nChallengeArenaCoinCost = 1,     --使用竞技令兑换的花费
nDailyFirstWinReward = 0,        --每日首胜奖励
nDailyJoinBattleRewardCount = 5, --每日挑战奖励达成需要的次数
nDailyJoinBattleReward = 0,      --每日挑战奖励
nFlushMatchDataInterval = 60,    --匹配刷新间隔时间(单位秒)
nDefaultScore = 1000,            --初始积分
nMinScore = 1000,                --最低积分
nMaxScore = 3000,                --最高积分

--胜利获得人物经验
fnWinRoleExp = function (nLv) return (nLv * 250 + 1250) end, 
--战败获得人物经验
fnFailRoleExp = function (nLv) return math.floor(gtArenaSysConf.fnWinRoleExp(nLv) * 0.6) end,
--胜利获得宠物经验
fnWinPetExp = function (nLv) return (nLv * 75 + 375) end,
--战败获得宠物经验
fnFailPetExp = function (nLv) return math.floor(gtArenaSysConf.fnWinPetExp(nLv) * 0.6) end,
--胜利获得银币
fnWinSilverCoin = function (nLv) return math.floor((nLv * 25 + 4000) * 10 * 0.2) end,
--失败获得银币
fnFailSilverCoin = function (nLv) return math.floor(gtArenaSysConf.fnWinSilverCoin(nLv) * 0.6) end,
--胜利获得的竞技币
nWinArenaCoinNum = 10,
nFailArenaCoinNum = 5,


--主动挑战获胜获得积分
fnActiveWinScore = function (nSelfScore, nTarScore) return math.ceil(((3000 - nSelfScore) / 100 + 5) * math.max(nTarScore / nSelfScore, 0.8)) end,
--被动挑战失败扣除积分,这里nTarScore指的挑战者的积分，nSelfScore指的是被挑战者的积分
fnPassiveFailScore = function (nTarScore, nSelfScore) return math.ceil(gtArenaSysConf.fnActiveWinScore(nTarScore, nSelfScore) * 0.2) end,

--每日竞技币奖励
fnDailyArenaCoin = function (nRank, nLevel, nScore) 
	if nLevel <= 0 then --防止除0错误
		return 0
	end
	return math.floor(math.max(0, (3000 - nRank*30)/100*(nLevel/20)) + 10 + nScore/50) 
end,
--每日竞技币排名额外奖励
fnDailyExtraArenaCoin = function (nRank) assert(nRank and nRank > 0, "参数错误") return nRank <= 10 and math.floor(50/nRank) or 0 end,

nDailyWinKeepAnnounce = 5,  --每日连胜触发公告的次数

}


gtArenaRewardType = 
{
	eDailyFirstWin = 1,      --每日首胜
	eDailyJoinBattle = 2,    --每日参与
	eArenaLevelBox = 3,      --赛季宝箱
}

gtArenaRewardState = 
{
	eNotAchieve = 0,    --未达成 --客户端会显示为null
	eAchieved = 1,      --可领取
	eRecieved = 2,      --已领取
}

gtArenaSeasonState = 
{
	ePrepare = 1,     --未开放
	eOpen = 2,        --开放
	eSwitchSeason = 3, --赛季结算
}

