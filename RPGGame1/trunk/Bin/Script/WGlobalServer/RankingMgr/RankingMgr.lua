--排行榜管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nAutoSaveTick = 5*60
function CRankingMgr:Ctor()
	self.m_nSaveTick = nil
	self.m_tRankingMap = {}
	self:Init()
end

function CRankingMgr:Init()
	--self.m_tRankingMap[gtRankingDef.eXXX] = oObj --例子

end

--加载数据
function CRankingMgr:LoadData()
	for _, oRanking in pairs(self.m_tRankingMap) do
		oRanking:LoadData()
	end
	self:AutoSave()
end

function CRankingMgr:AutoSave()
	self.m_nSaveTick = GetGModule("TimerMgr"):Interval(nAutoSaveTick, function() self:SaveData() end)
end

--保存数据
function CRankingMgr:SaveData()
	for _, oRanking in pairs(self.m_tRankingMap) do
		oRanking:SaveData()
	end

end

--释放
function CRankingMgr:Release()
	GetGModule("TimerMgr"):Clear(self.m_nSaveTick)
	self.m_nSaveTick = nil

	for _, oRanking in pairs(self.m_tRankingMap) do
		oRanking:Release()
	end
	
end

--取排行榜
function CRankingMgr:GetRanking(nID)
	return self.m_tRankingMap[nID]
end

