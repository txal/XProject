--排行榜
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CRBRanking:Ctor(oRobot)
	self.m_oRobot = oRobot
end

function CRBRanking:Run()
	local tRanking = {
		1,		--科举排行
		12, 	--综合战力排行
		13, 	--人物战力榜
		14, 	--人物等级榜
		15, 	--宠物评分榜
		16, 	--帮派等级榜
		17, 	--家园资产榜
		21, 	--鬼王宗
		22, 	--青云门
		23, 	--合欢派
		24, 	--圣巫教
		25, 	--天音寺
		31,		--竞技场积分
		41,		--周人气榜
		42,		--总人气榜
		43,		--总好友度榜
	}
	local nRank = tRanking[math.random(#tRanking)]
	self.m_oRobot:SendPressMsg("RankingListReq", {nRankID=nRank, nRankNum=50})
end
