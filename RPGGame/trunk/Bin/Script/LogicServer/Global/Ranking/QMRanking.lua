--妃子总亲密度排行榜
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--比较函数
local function _fnDescSort(t1, t2)
	if t1[2] == t2[2] then
		return 0
	end
	if t1[2] > t2[2] then
		return -1
	end
	return 1
end

function CQMRanking:Ctor(nID)
	self.m_nID = nID
	self.m_tDirtyMap = {} 
	self.m_oRanking = CSkipList:new(_fnDescSort) --{nCharID={sName,nValue}, ...}
end

function CQMRanking:LoadData()
	local tKeys = goDBMgr:GetSSDB("Player"):HKeys(gtDBDef.sQMRankingDB)
	print("加载妃子总亲密度排行榜:", #tKeys)
	for _, sCharID in ipairs(tKeys) do
		local nCharID = tonumber(sCharID)
		local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sQMRankingDB, nCharID)
		local tData = cjson.decode(sData)
		if tData[1] and tData[2] then
			self.m_oRanking:Insert(nCharID, tData)
		end
	end
end

function CQMRanking:SaveData()
	for nCharID, v in pairs(self.m_tDirtyMap) do
		local tData = self.m_oRanking:GetDataByKey(nCharID)
		if tData then
			local tRealData = {tData[1], tData[2]} --主意要转成数组
			goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sQMRankingDB, nCharID, cjson.encode(tRealData))
		end
	end
	self.m_tDirtyMap = {}
end

function CQMRanking:OnRelease()
	self:SaveData()
end

--重置清理数据库
function CQMRanking:ResetRanking()
	goDBMgr:GetSSDB("Player"):HClear(gtDBDef.sQMRankingDB)
	self.m_oRanking = CSkipList:new(_fnDescSort)
	self.m_tDirtyMap = {}
end

--设置脏数据
function CQMRanking:MarkDirty(nCharID, bDirty)
	bDirty = bDirty or nil
	self.m_tDirtyMap[nCharID] = bDirty
end

--更新数据
function CQMRanking:Update(oPlayer, nValue)
	if nValue == 0 then return end
	local nCharID = oPlayer:GetCharID()
	local nDiffVal = nValue
	local tData = self.m_oRanking:GetDataByKey(nCharID)
	if tData then
		if tData[2]	== nValue then return end
		self.m_oRanking:Remove(nCharID)
		nDiffVal = nValue - tData[2]
		tData[2] = nValue
	else
		tData = {"", nValue}
	end
	self.m_oRanking:Insert(nCharID, tData)
	self:MarkDirty(nCharID, true)

	if self:GetPlayerRank(nCharID) == 1 then 
	 	goBroadcast:SetBroadcast(35, 1, nCharID)
	end

	--活动
    goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(nCharID, gtTAType.eQM, nDiffVal)
    --日志
    goLogger:RankingLog(oPlayer, self.m_nID, nValue, oPlayer.m_oVIP:GetTotalRecharge())
end

--取某个玩家亲密
function CQMRanking:GetPlayerQinMi(nCharID)
	local tData = self.m_oRanking:GetDataByKey(nCharID)
	return (tData and tData[2] or 0)
end

--取某个玩家排名
function CQMRanking:GetPlayerRank(nCharID)
	local nRank = self.m_oRanking:GetRankByKey(nCharID)
	return nRank
end

--排行榜请求
function CQMRanking:QMRankingReq(oPlayer, nRankNum)
	local nCharID = oPlayer:GetCharID()
	nRankNum = math.max(1, math.min(100, nRankNum))

	--我的排名
	local nMyRank = self:GetPlayerRank(nCharID)
	local tMyData = self.m_oRanking:GetDataByKey(nCharID)
	local nMyValue = tMyData and tMyData[2] or 0

	--前nRankNum名玩家
	local tRanking = {}
	local function _fnTraverse(nRank, nCharID, tData)
		local tRank = {nRank=nRank, sName=goOfflineDataMgr:GetName(nCharID), nValue=tData[2]}
		table.insert(tRanking, tRank)
	end
	self.m_oRanking:Traverse(1, nRankNum, _fnTraverse)
	local tMsg = {
		tRanking = tRanking,
		nMyRank = nMyRank,
		sMyName = oPlayer:GetName(),
		nMyValue = nMyValue,
		bMoBai = oPlayer.m_oMoBai:IsMoBai(self.m_nID)
	}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "QMRankingRet", tMsg)
	oPlayer.m_oMoBai:CheckRedPoint()
end
