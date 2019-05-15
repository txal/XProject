--人气冲榜
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPopularityCB:Ctor(nID)
	CCBBase.Ctor(self, nID)     --继承基类
end

function CPopularityCB:GetRankingConf()
	return ctPopularityRankingConf
end

function CPopularityCB:GetAwardRanking()
	local tConf = ctMZCBEtcConf[1]
	return 1, tConf.nPopularityAwardRanking
end
