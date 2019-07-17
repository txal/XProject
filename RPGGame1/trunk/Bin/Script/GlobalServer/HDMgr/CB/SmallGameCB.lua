--小游戏积分冲榜
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CSmallGameCB:Ctor(nID)
	CCBBase.Ctor(self, nID)     --继承基类
end

function CSmallGameCB:GetRankingConf()
	return ctSmallGameRankingConf
end

function CSmallGameCB:GetAwardRanking()
	local tConf = ctMZCBEtcConf[1]
	return 1, tConf.nSmallGameAwardRanking
end
