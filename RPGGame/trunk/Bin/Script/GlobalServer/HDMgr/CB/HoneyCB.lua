--仙侣亲密度冲榜
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CHoneyCB:Ctor(nID)
	CCBBase.Ctor(self, nID)     --继承基类
end

function CHoneyCB:GetRankingConf()
	return ctHoneyRankingConf
end

function CHoneyCB:GetAwardRanking()
	local tConf = ctMZCBEtcConf[1]
	return 1, tConf.nHoneyAwardRanking
end

--获取上榜条件值
function CResumeYBCB:GetRankLimitValue()
	return ctMZCBEtcConf[1].nIntimacyRankLimit
end

