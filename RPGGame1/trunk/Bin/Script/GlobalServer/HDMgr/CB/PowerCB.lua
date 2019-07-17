--战力冲榜
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPowerCB:Ctor(nID)
	CCBBase.Ctor(self, nID)     --继承基类
end

function CPowerCB:GetRankingConf()
	return ctPowerRankingConf
end

function CPowerCB:GetAwardRanking()
	local tConf = ctMZCBEtcConf[1]
	return 1, tConf.nPowerAwardRanking
end

