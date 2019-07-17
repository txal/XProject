--玩家竞技场数据
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local ctArenaLevelConf = ctArenaLevelConf

function CRoleArenaInfo:Ctor(nRoleID)
	--玩家头像、职业、等级、角色配置ID等可从全局GRoleMgr中获取到
	assert(nRoleID > 0, "参数错误")
	self.m_nRoleID = nRoleID
	--self.m_nArenaSeason = goArenaMgr:GetArenaSeason() --数据所属的赛季
	self.m_nScore = gtArenaSysConf.nDefaultScore --竞技场积分
	self.m_nScoreChangeStamp = os.time()                 --积分变化时间戳 --用来做排名比较
	self.m_nChallenge = gtArenaSysConf.nDefaultDailyChallenge   --挑战次数，每日重置
	self.m_nDailyChallPurchCount = 0             --挑战次数，每日购买数量
	--可通过元宝或竞技令购买，竞技令数据挂在在LogicSvr玩家身上，元宝购买存在次数限制，元宝次数消耗完才可用竞技令购买

	self.m_nAppellation = 0             --上赛季获得的称号
	----------------------------
	self.m_nMaxScore = self.m_nScore    --整个赛季最高积分
	self.m_nTotalBattleCount = 0        --整个赛季的战斗场次	
	self.m_nTotalWinCount = 0           --整个赛季的胜利场次
	self.m_nMaxDailyWinKeep = 0         --整个赛季的最高每日连胜次数
	self.m_nMaxWinKeep = 0              --整个赛季的最高连胜次数

	self.m_nDailyBattleCount = 0        --每日战斗次数
	self.m_nDailyWinCount = 0           --每日胜利次数
	self.m_nDailyWinKeep = 0            --每日连胜次数
	self.m_nWinKeep = 0                 --当前连胜次数，不每天清零

	self.m_nTotalDefenceCount = 0       --被挑战次数
	self.m_nTotalDefSuccCount = 0       --被挑战防御成功次数

	self.m_tMatchRole = {}  --{index:nRoleID, ...},匹配的可挑战目标玩家
	--如果有玩家角色数据被删除了，需要处理下，这里会找不到具体玩家对象
	self.m_nMatchStamp = 0              --匹配时间戳
	self.m_nFreeFlushMatchCount = ctArenaSysConf.nFreeFlushMatchCount.nVal   --免费刷新次数
	---------------------
	--self.m_nArenaBoxReward = 0      --竞技场赛季奖励宝箱
	self.m_nArenaBoxRewardLevel = 0  --竞技场赛季奖励宝箱等级
	self.m_nArenaBoxRewardState = gtArenaRewardState.eNotAchieve --赛季奖励状态 已领取/未领取

	---------------------
	self.m_nDailyFirstWinRewardState = gtArenaRewardState.eNotAchieve     --每日首胜奖励领取状态 不可领取/可领取/已领取
	self.m_nDailyJoinBattleRewardState = gtArenaRewardState.eNotAchieve   --每日挑战次数礼包领取状态

	------- No Save DB -------
	self.m_nArenaLevel = 1       --竞技场段位，根据配置，自动计算
	self.m_sArenaLevelName = ""
	self:UpdateArenaLevel()

	self.m_bDirty = false
end

function CRoleArenaInfo:IsDirty() return self.m_bDirty end
function CRoleArenaInfo:MarkDirty(bDirty) 
	self.m_bDirty = bDirty 
	if self.m_bDirty then
		goArenaMgr.m_tDirtyQueue:Push(self.m_nRoleID, self)
	end
end

function CRoleArenaInfo:GetID() return self.m_nRoleID end --接口兼容
function CRoleArenaInfo:GetRoleID() return self.m_nRoleID end
function CRoleArenaInfo:GetScore() return self.m_nScore end
function CRoleArenaInfo:GetArenaLevel() return self.m_nArenaLevel end
function CRoleArenaInfo:GetArenaLevelConf() return ctArenaLevelConf[self.m_nArenaLevel] end
function CRoleArenaInfo:GetArenaLevelByScore(nScore)
	local tArenaLevelConfTbl = ctArenaLevelConf
	local tTargetConf = nil
	for k, tConf in pairs(tArenaLevelConfTbl) do
		if tConf.nScore <= nScore then
			if not tTargetLevel then
				tTargetConf = tConf
			elseif tTargetConf.nScore < tConf.nScore then
				tTargetConf = tConf
			end
		end
	end
	if tTargetConf then
		return tTargetConf.nArenaLevelID
	end
	return 0
end
function CRoleArenaInfo:ChallengeCount() return self.m_nChallenge end
function CRoleArenaInfo:AddChallenge(nNum) 
	self.m_nChallenge = math.max(self.m_nChallenge + nNum, 0)
	self:MarkDirty(true)
end
function CRoleArenaInfo:GetFreeFlushMatchCount() return self.m_nFreeFlushMatchCount end
function CRoleArenaInfo:AddFreeFlushMatchCount(nNum) 
	self.m_nFreeFlushMatchCount = math.max(self.m_nFreeFlushMatchCount + nNum, 0)
	self:MarkDirty(true)
end 

function CRoleArenaInfo:GetDailyFirstWinRewardState()
	return self.m_nDailyFirstWinRewardState
end
function CRoleArenaInfo:SetDailyFirstWinRewardState(nState)
	self.m_nDailyFirstWinRewardState = nState
end
function CRoleArenaInfo:GetDailyJoinRewardState()
	return self.m_nDailyJoinBattleRewardState
end
function CRoleArenaInfo:SetDailyJoinRewardState(nState)
	self.m_nDailyJoinBattleRewardState = nState
end
function CRoleArenaInfo:GetArenaBoxRewardState()
	return self.m_nArenaBoxRewardState, self.m_nArenaBoxRewardLevel
end
function CRoleArenaInfo:SetArenaBoxRewardState(nState, nBoxLevel)
	assert(nState, "参数错误") --领取奖励，只需要设置nState
	self.m_nArenaBoxRewardState = nState
	if nBoxLevel then
		self.m_nArenaBoxRewardLevel = nBoxLevel
	end
end

function CRoleArenaInfo:GetArenaRewardState(nType)
	if nType == gtArenaRewardType.eDailyFirstWin then
		return self:GetDailyFirstWinRewardState()
	elseif nType == gtArenaRewardType.eDailyJoinBattle then
		return self:GetDailyJoinRewardState()
	elseif nType == gtArenaRewardType.eArenaLevelBox then
		return self:GetArenaBoxRewardState()
	else
		assert(false, "不合法的奖励类型")
	end	
end

function CRoleArenaInfo:SetArenaRewardState(nType, nState, ...)
	if nType == gtArenaRewardType.eDailyFirstWin then
		self:SetDailyFirstWinRewardState(nState)
	elseif nType == gtArenaRewardType.eDailyJoinBattle then
		self:SetDailyJoinRewardState(nState)
	elseif nType == gtArenaRewardType.eArenaLevelBox then
		self:SetArenaBoxRewardState(nState, ...)
	else
		assert(false, "不合法的奖励类型")
	end	
	self:MarkDirty(true)
end

function CRoleArenaInfo:GetDailyBattleCount() return self.m_nDailyBattleCount end
function CRoleArenaInfo:GetDailyWinKeep() return self.m_nDailyWinKeep end

function CRoleArenaInfo:CheckEnemyIDValid(nEnemyID)
	if nEnemyID <= 0 then
		return false
	end
	for k, v in ipairs(self.m_tMatchRole) do
		if v == nEnemyID then
			return true
		end
	end
	return false
end

function CRoleArenaInfo:SaveData()
	local tData = {}
	tData.nRoleID = self.m_nRoleID
	--tData.nArenaSeason = self.m_nArenaSeason
	tData.nScore = self.m_nScore
	tData.nScoreChangeStamp = self.m_nScoreChangeStamp
	tData.nChallenge = self.m_nChallenge
	tData.nDailyChallPurchCount = self.m_nDailyChallPurchCount

	tData.nAppellation = self.m_nAppellation

	tData.tMatchRole = self.m_tMatchRole
	tData.nMatchStamp = self.m_nMatchStamp
	tData.nFreeFlushMatchCount = self.m_nFreeFlushMatchCount

	tData.nArenaBoxRewardLevel = self.m_nArenaBoxRewardLevel
	tData.nArenaBoxRewardState = self.m_nArenaBoxRewardState

	tData.nDailyFirstWinRewardState = self.m_nDailyFirstWinRewardState
	tData.nDailyJoinBattleRewardState = self.m_nDailyJoinBattleRewardState

	------ 统计数据 --------
	tData.nMaxScore = self.m_nMaxScore
	tData.nTotalBattleCount = self.m_nTotalBattleCount
	tData.nTotalWinCount = self.m_nTotalWinCount
	tData.nMaxDailyWinKeep = self.m_nMaxDailyWinKeep
	tData.nMaxWinKeep = self.m_nMaxWinKeep

	tData.nDailyBattleCount = self.m_nDailyBattleCount
	tData.nDailyWinCount = self.m_nDailyWinCount
	tData.nDailyWinKeep = self.m_nDailyWinKeep
	tData.nWinKeep = self.m_nWinKeep

	tData.nTotalDefenceCount = self.m_nTotalDefenceCount
	tData.nTotalDefSuccCount = self.m_nTotalDefSuccCount
	tData.nMaxScore = self.m_nMaxScore

	return tData
end

function CRoleArenaInfo:LoadData(tData)
	if not tData then return end
	self.m_nRoleID = tData.nRoleID
	--self.m_nArenaSeason = tData.nArenaSeason or self.m_nArenaSeason
	self.m_nScore = math.max(tData.nScore, gtArenaSysConf.nMinScore)
	self.m_nScoreChangeStamp = tData.nScoreChangeStamp
	self.m_nChallenge = tData.nChallenge or gtArenaSysConf.nDefaultDailyChallenge
	self.m_nDailyChallPurchCount = tData.nDailyChallPurchCount
	self.m_nAppellation = tData.nAppellation or self.m_nAppellation

	self.m_tMatchRole = tData.tMatchRole
	self.m_nMatchStamp = tData.nMatchStamp
	self.m_nFreeFlushMatchCount = tData.nFreeFlushMatchCount or self.m_nFreeFlushMatchCount

	self.m_nArenaBoxRewardLevel = tData.nArenaBoxRewardLevel or 0

	local fnFixRewardState = function (nCurState)
		if nCurState < gtArenaRewardState.eNotAchieve or nCurState > gtArenaRewardState.eRecieved then
			return gtArenaRewardState.eNotAchieve --不对的状态，默认返回不可领取
		end
		return nCurState
	end
	--修复下旧数据
	self.m_nArenaBoxRewardState = tData.nArenaBoxRewardState or gtArenaRewardState.eNotAchieve
	self.m_nArenaBoxRewardState = fnFixRewardState(self.m_nArenaBoxRewardState)

	self.m_nDailyFirstWinRewardState = tData.nDailyFirstWinRewardState or gtArenaRewardState.eNotAchieve
	self.m_nDailyFirstWinRewardState = fnFixRewardState(self.m_nDailyFirstWinRewardState)

	self.m_nDailyJoinBattleRewardState = tData.nDailyJoinBattleRewardState or gtArenaRewardState.eNotAchieve
	self.m_nDailyJoinBattleRewardState = fnFixRewardState(self.m_nDailyJoinBattleRewardState)

	------ 统计数据 --------
	self.m_nMaxScore = tData.nMaxScore
	self.m_nTotalBattleCount = tData.nTotalBattleCount
	self.m_nTotalWinCount = tData.nTotalWinCount
	self.m_nMaxDailyWinKeep = tData.nMaxDailyWinKeep
	self.m_nMaxWinKeep = tData.nMaxWinKeep

	self.m_nDailyBattleCount = tData.nDailyBattleCount
	self.m_nDailyWinCount = tData.nDailyWinCount
	self.m_nDailyWinKeep = tData.nDailyWinKeep
	self.m_nWinKeep = tData.nWinKeep

	self.m_nTotalDefenceCount = tData.nTotalDefenceCount
	self.m_nTotalDefSuccCount = tData.nTotalDefSuccCount     
	self.m_nMaxScore = tData.nMaxScore
	self:UpdateArenaLevel()
end

function CRoleArenaInfo:CountBattle(bWin)  --战斗统计
	if bWin then
		self.m_nDailyWinCount = self.m_nDailyWinCount + 1
		self.m_nDailyWinKeep = self.m_nDailyWinKeep + 1
		self.m_nWinKeep = self.m_nWinKeep + 1
		self.m_nTotalWinCount = self.m_nTotalWinCount + 1
		if self.m_nMaxDailyWinKeep < self.m_nDailyWinKeep then
			self.m_nMaxDailyWinKeep = self.m_nDailyWinKeep
		end
		if self.m_nMaxWinKeep < self.m_nWinKeep then
			self.m_nMaxWinKeep = self.m_nWinKeep
		end
	else
		self.m_nDailyWinKeep = 0
		self.m_nWinKeep = 0
	end
	self.m_nDailyBattleCount = self.m_nDailyBattleCount + 1
	self.m_nTotalBattleCount = self.m_nTotalBattleCount + 1

	self:MarkDirty(true)
end

function CRoleArenaInfo:CountDefence(bWin)  --防御统计
	self.m_nTotalDefenceCount = self.m_nTotalDefenceCount + 1
	if bWin then
		self.m_nTotalDefSuccCount = self.m_nTotalDefSuccCount + 1
	end
	self:MarkDirty(true)
end

--获取玩家当前排名
function CRoleArenaInfo:GetRank()
	local oRankInst = goArenaMgr:GetRankInst()
	local nRank = oRankInst:GetRankByKey(self.m_nRoleID)
	if not nRank then
		print("排名不存在", self.m_nRoleID)
		return 10000
	end
	return nRank
end

function CRoleArenaInfo:AddScore(nNum)
	local nOld = self.m_nScore
	self.m_nScore = math.min(math.max(self.m_nScore + nNum, gtArenaSysConf.nMinScore), gtArenaSysConf.nMaxScore)
	self:OnScoreChange(nOld, self.m_nScore)
	self:MarkDirty(true)
	local oRole = goGPlayerMgr:GetRoleByID(self:GetID())
	oRole:UpdateActGTArenaScore()
end

function CRoleArenaInfo:UpdateArenaLevel()
	self.m_nArenaLevel = self:GetArenaLevelByScore(self.m_nScore)
	self.m_sArenaLevelName = self:GetArenaLevelConf(self.m_nArenaLevel).sLevelName
	--print("更新玩家<"..self.m_nRoleID..">当前竞技场等级为:"..self.m_nArenaLevel)
end

function CRoleArenaInfo:OnScoreChange(nOld, nNew)
	self:UpdateArenaLevel()
	if nNew > self.m_nMaxScore then
		self.m_nMaxScore = nNew
	end
	--更新下时间戳，需要依据时间戳算排名，玩家可能连败，积分掉到1000分，
	--注意，如果玩家分数前后没变化，不需要更新，比如一直变化前后都是3000分，如果连败，一直1000分，也暂时不改
	if nOld ~= nNew then --or nNew ~= gtArenaSysConf.nMaxScore then
		self.m_nScoreChangeStamp = os.time()
	end

    --竞技场积分涨幅统计(冲榜+限时奖励)
    local nDiffVal = nNew - nOld
    if nDiffVal ~= 0 then
	    local oRole = goGPlayerMgr:GetRoleByID(self.m_nRoleID)
    	goHDMgr:GetActivity(gtHDDef.eArenaCB):UpdateValue(self.m_nRoleID, nDiffVal)
    	goHDMgr:GetActivity(gtHDDef.eTimeAward):UpdateVal(self.m_nRoleID, gtTAType.eJJC, nDiffVal)
		goRankingMgr:GetRanking(gtRankingDef.eArenaScoreRanking):Update(self.m_nRoleID, nNew)
	    -- Network.oRemoteCall:Call("OnTAJJCReq", oRole:GetServer(), goServerMgr:GetGlobalService(oRole:GetServer(),20), 0, self.m_nRoleID, nDiffVal)
	    -- Network.oRemoteCall:Call("OnCBJJCReq", oRole:GetServer(), goServerMgr:GetGlobalService(oRole:GetServer(),20), 0, self.m_nRoleID, nDiffVal)
	    -- Network.oRemoteCall:Call("ArenaScoreChangeReq", oRole:GetServer(), goServerMgr:GetGlobalService(oRole:GetServer(),20), 0, self.m_nRoleID, nNew)
	end
end

--返回一个排行榜用的数据
function CRoleArenaInfo:GetRankData()
	local tRankData = {}
	tRankData.nRoleID = self.m_nRoleID
	tRankData.nScore = self.m_nScore
	tRankData.nScoreChangeStamp = self.m_nScoreChangeStamp
	local oRole = goGPlayerMgr:GetRoleByID(self.m_nRoleID)
	assert(oRole, "数据错误")
	--tRankData.nRoleConfID = oRole:GetConfID()
	tRankData.nGender = oRole:GetGender()
	tRankData.nSchool = oRole:GetSchool()
	tRankData.sHeader = oRole:GetHeader()
	return tRankData
end

function CRoleArenaInfo:DailyReset() --重置每日相关数据
	--可能很多玩家当天并没有参与竞技场相关活动，判断下，减少每日清理的数据保存量
	local bDirty = false
	if self.m_nChallenge ~= gtArenaSysConf.nDefaultDailyChallenge then --挑战次数，每日购买数量
		self.m_nChallenge = gtArenaSysConf.nDefaultDailyChallenge
		bDirty = true
	end
	if self.m_nDailyChallPurchCount ~= 0 then
		self.m_nDailyChallPurchCount = 0
		bDirty = true
	end
	if self.m_nDailyBattleCount ~= 0 then       --每日战斗次数
		self.m_nDailyBattleCount = 0
		bDirty = true
	end
	if self.m_nDailyWinCount ~= 0 then         --每日胜利次数
		self.m_nDailyWinCount = 0
		bDirty = true
	end
	if self.m_nDailyWinKeep ~= 0 then           --每日连胜次数
		self.m_nDailyWinKeep = 0
		bDirty = true
	end

	if self.m_nFreeFlushMatchCount ~= ctArenaSysConf.nFreeFlushMatchCount.nVal then 
		self.m_nFreeFlushMatchCount = ctArenaSysConf.nFreeFlushMatchCount.nVal
		bDirty = true
	end

	if self.m_nDailyFirstWinRewardState ~= gtArenaRewardState.eNotAchieve then     --每日首胜奖励领取状态 不可领取/可领取/已领取
		self.m_nDailyFirstWinRewardState = gtArenaRewardState.eNotAchieve
		bDirty = true
	end
	if self.m_nDailyJoinBattleRewardState ~= gtArenaRewardState.eNotAchieve then  --每日挑战次数礼包领取状态
		self.m_nDailyJoinBattleRewardState = gtArenaRewardState.eNotAchieve
		bDirty = true
	end

	if bDirty then
		self:MarkDirty(true)
	end
end

function CRoleArenaInfo:SeasonReset() --赛季重置
	--self.m_nArenaSeason = goArenaMgr:GetArenaSeason() --数据所属的赛季
	self.m_nScore = gtArenaSysConf.nDefaultScore --竞技场积分
	self.m_nScoreChangeStamp = os.time()                 --积分变化时间戳 --用来做排名比较
	self.m_nChallenge = gtArenaSysConf.nDefaultDailyChallenge   --挑战次数，每日重置
	self.m_nDailyChallPurchCount = 0             --挑战次数，每日购买数量
	----------------------------
	self.m_nMaxScore = self.m_nScore    --整个赛季最高积分
	self.m_nTotalBattleCount = 0        --整个赛季的战斗场次	
	self.m_nTotalWinCount = 0           --整个赛季的胜利场次
	self.m_nMaxDailyWinKeep = 0         --整个赛季的最高每日连胜次数
	self.m_nMaxWinKeep = 0              --整个赛季的最高连胜次数

	self.m_nDailyBattleCount = 0        --每日战斗次数
	self.m_nDailyWinCount = 0           --每日胜利次数
	self.m_nDailyWinKeep = 0            --每日连胜次数
	self.m_nWinKeep = 0                 --当前连胜次数，不每天清零

	self.m_nTotalDefenceCount = 0       --被挑战次数
	self.m_nTotalDefSuccCount = 0       --被挑战防御成功次数

	--初始不刷新此数据，玩家主动获取时，才刷新此数据，并且将玩家添加到排行榜
	self.m_tMatchRole = {}  --{index:nRoleID, ...},匹配的可挑战目标玩家
	--如果有玩家角色数据被删除了，需要处理下，这里会找不到具体玩家对象
	self.m_nMatchStamp = 0  --匹配时间戳


	self.m_nDailyFirstWinRewardState = gtArenaRewardState.eNotAchieve     --每日首胜奖励领取状态 不可领取/可领取/已领取
	self.m_nDailyJoinBattleRewardState = gtArenaRewardState.eNotAchieve   --每日挑战次数礼包领取状态

	self:UpdateArenaLevel()

	self:MarkDirty(true)
end

function CRoleArenaInfo:GetMatchFlushCountdown(nTimeStamp)
	nTimeStamp = nTimeStamp or os.time()
	local nCountdown = 0
	local nExpiryTime = self.m_nMatchStamp + gtArenaSysConf.nFlushMatchDataInterval
	if nExpiryTime > nTimeStamp then
		nCountdown = nExpiryTime - nTimeStamp
	end
	return nCountdown
end

function CRoleArenaInfo:GetPBMatchData()
	local tRetData = {}
	--[[
	message ArenaMatchRoleData
	{
		required int32 nRoleID = 1;          // 玩家ID
		required int32 nGender = 2;          // 性别
		required int32 nSchool = 3;          // 门派
		required string sHeader = 4;         // 头像
		required int32 nLevel = 5;           // 玩家等级
		required int32 nScore = 6;           // 竞技场积分
		required int32 nArenaLevel = 7;      // 竞技场段位
		required string sArenaLevelName = 8; // 段位名称
	}
	]]
	local oRole = goGPlayerMgr:GetRoleByID(self.m_nRoleID)
	assert(oRole, "数据错误")
	tRetData.nRoleID = self.m_nRoleID
	--tRetData.nRoleConfID = oRole:GetConfID()
	tRetData.nGender = oRole:GetGender()
	tRetData.nSchool = oRole:GetSchool()
	tRetData.sHeader = oRole:GetHeader()
	tRetData.nLevel= oRole:GetLevel()
	tRetData.nScore = self:GetScore()
	tRetData.nArenaLevel = self.m_nArenaLevel
	tRetData.sArenaLevelName = self.m_sArenaLevelName
	return tRetData
end

-- 检查是否可继续使用元宝购买挑战次数，返回状态及价格及次数
function CRoleArenaInfo:CheckCanPurchChallenge()
	if self.m_nDailyChallPurchCount >= gtArenaSysConf.nChallengeYuanbaoExchCount then
		return false, 0, gtArenaSysConf.nChallengeYunbaoExchCost
	end
	return true, (gtArenaSysConf.nChallengeYuanbaoExchCount - self.m_nDailyChallPurchCount), gtArenaSysConf.nChallengeYunbaoExchCost
end

-- --检查是否可继续使用元宝购买挑战次数，返回状态及价格及次数
-- function CRoleArenaInfo:CheckCanPurchChallenge()
-- 	local function _fnCalcPurchCost()
-- 		return math.min(200, (self.m_nDailyChallPurchCount*10)+gtArenaSysConf.nChallengeYunbaoExchCost1)
-- 	end

-- 	if self.m_nDailyChallPurchCount >= gtArenaSysConf.nChallengeYuanbaoExchCount1 then
-- 		return false, 0, _fnCalcPurchCost()
-- 	end
-- 	return true, (gtArenaSysConf.nChallengeYuanbaoExchCount1-self.m_nDailyChallPurchCount) , _fnCalcPurchCost()
-- end

function CRoleArenaInfo:GetPBData()
	local tRetData = {}

	--基础分数相关
	local nArenaSeason = goArenaMgr:GetArenaSeason()
	tRetData.nArenaSeason = nArenaSeason  --self.m_nArenaSeason

	local tSeasonConf = goArenaMgr:GetSeasonConf(nArenaSeason)
	assert(tSeasonConf, "赛季配置不存在")
	tRetData.nArenaSeasonEndTime = goArenaMgr:GetSeasonEndTimeByConf(tSeasonConf)
	tRetData.nArenaSeasonEndCountdown = goArenaMgr:GetSeasonEndCountdownByConf(tSeasonConf)

	tRetData.nScore = self:GetScore()
	tRetData.nArenaLevel = self.m_nArenaLevel
	tRetData.sArenaLevelName = self.m_sArenaLevelName
	--挑战次数相关
	tRetData.nChallenge = self.m_nChallenge
	tRetData.nDailyChallPurchCount = self.m_nDailyChallPurchCount
	local bPurch, nRemainCount, nCost = self:CheckCanPurchChallenge()
	tRetData.nCanPurchChallCount, tRetData.nPurchChallCost = nRemainCount, nCost
	--每日奖励
	tRetData.nDailyFirstWinRewardState = self.m_nDailyFirstWinRewardState
	tRetData.nDailyJoinBattleRewardState = self.m_nDailyJoinBattleRewardState
	--赛季宝箱
	tRetData.nArenaBoxRewardLevel = self.m_nArenaBoxRewardLevel
	tRetData.nArenaBoxRewardState = self.m_nArenaBoxRewardState
	--匹配对手相关
	tRetData.tMatchRoleList = {}
	for k, nRoleID in pairs(self.m_tMatchRole) do
		local tMatchData = nil
		if goArenaMgr:IsRobot(nRoleID) then
			tMatchData = goArenaMgr:GetRobotMatchData(nRoleID)
		else
			local oRoleArena = goArenaMgr:GetRoleArenaInfo(nRoleID)
			assert(oRoleArena, "数据错误")
			tMatchData = oRoleArena:GetPBMatchData()
		end
		if tMatchData then
			table.insert(tRetData.tMatchRoleList, tMatchData)
		else
			LuaTrace("生成匹配数据错误", nRoleID)
		end
	end
	tRetData.nMatchFlushCountdown = self:GetMatchFlushCountdown()
	tRetData.nFreeFlushMatchCount = self:GetFreeFlushMatchCount()
	--统计数据
	tRetData.nDailyBattleCount = self.m_nDailyBattleCount
	tRetData.nDailyWinKeep = self.m_nDailyWinKeep
	tRetData.nRank = goArenaMgr:GetRankInst():GetRankByKey(self:GetRoleID())
	return tRetData
end


