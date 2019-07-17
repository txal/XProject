--竞技积分冲榜
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CArenaCB:Ctor(nID)
	CCBBase.Ctor(self, nID)     --继承基类
end

function CArenaCB:GetRankingConf()
	return ctArenaRankingConf
end

function CArenaCB:GetAwardRanking()
	local tConf = ctMZCBEtcConf[1]
	return 1, tConf.nArenaAwardRanking
end
