--排行榜奖励
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CRankRewardCfg:Ctor(tCfgTbl)
	if not tCfgTbl then
		tCfgTbl = ctAwardPoolConf
	end
	self.m_nCfgTbl = tCfgTbl
	self.m_tRankMap = {}  -- {RankID : {nConfID : tConf, ...}, ...}
	self:Init()
end

function CRankRewardCfg:Init()
	for k, v in pairs(self.m_nCfgTbl) do
		if type(v) == "table" then
			local nRankID = v.nRankID
			local tRankCfg = self:GetRankCfg(nRankID)
			if not tRankCfg then
				tRankCfg = {}
				self.m_tRankMap[nRankID] = tRankCfg
				tRankCfg = self.m_tRankMap[nRankID]
			end
			table.insert(tRankCfg, v)
		end
	end

	--[[
	local fnSortCmp = function (tLeft, tRight)
		if tLeft.nRank < tRight.nRank then --排名靠前的排前面，注意小于0的保底奖励，排在最前面
			return true
		end
		return false
	end
	for k, tConfList in pairs(self.m_tRankMap) do
		table.sort(tConfList, fnSortCmp)
	end
	]]
end

function CRankRewardCfg:GetRankCfg(nRankID) return self.m_tRankMap[nRankID] end

function CRankRewardCfg:GetRankRewardConf(nRankID, nRank)
	if nRankID <= 0 or nRank <= 0 then
		return
	end
	--assert(nRankID > 0 and nRank > 0, "参数错误")
	local tRankCfg = self:GetRankCfg(nRankID)
	assert(tRankCfg, "排行榜奖励配置不存在")
	local tTarCfg = nil   --目标奖励
	for k, tCfg in ipairs(tRankCfg) do --数据少,直接迭代找
		if tCfg.nRank < 0 and not tTarCfg then --保底奖励
			tTarCfg = tCfg
		elseif tCfg.nRank >= nRank then --非保底奖励
			if tTarCfg then  --已设置奖励的情况下
				if tTarCfg.nRank < 0 or tTarCfg.nRank > tCfg.nRank then --如果之前设置的是保底奖励 或者 当前奖励排名比之前排名高(数值低)
					tTarCfg = tCfg
				end
			else
				tTarCfg = tCfg
			end
		end
	end
	return tTarCfg
end

--获取排名奖励  --不包含称谓
--注意，可能排名没有奖励或奖励不存在，请在外层判断返回值
function CRankRewardCfg:GetRankReward(nRankID, nRank)
	if nRankID <= 0 or nRank <= 0 then
		return {}
	end
	--assert(nRankID > 0 and nRank > 0, "参数错误")
	local tRankCfg = self:GetRankCfg(nRankID)
	assert(tRankCfg, "排行榜奖励配置不存在")
	local tTarCfg = self:GetRankRewardConf(nRankID, nRank)
	if tTarCfg then
		local tRewardPoolList = {}
		for k, v in pairs(tTarCfg.tAward) do
			for i, nRewardID in pairs(v) do
				if nRewardID > 0 then
					table.insert(tRewardPoolList, nRewardID)
				end
			end
		end
		return tRewardPoolList
	else
		return {}
	end
end

--获取称谓奖励ID，大于0，才是一个有效的称谓ID值
function CRankRewardCfg:GetRankAppellation(nRankID, nRank)
	assert(nRankID and nRank)
	if not nRank or nRank < 1 then 
		return 0
	end
	local tTarCfg = self:GetRankRewardConf(nRankID, nRank)
	if not tTarCfg then 
		return 0
	end
	return tTarCfg.nAppellation
end

goRankRewardCfg = CRankRewardCfg:new(ctRankAwardConf)


