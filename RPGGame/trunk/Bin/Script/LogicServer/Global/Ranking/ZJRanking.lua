--战绩排行榜
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

function CZJRanking:Ctor()
	self.m_tDirtyMap = {} 
	self.m_oRanking = CSkipList:new(_fnDescSort) --{nCharID={sName,nValue}, ...}
end

function CZJRanking:LoadData()
	local tKeys = goDBMgr:GetSSDB("Player"):HKeys(gtDBDef.sZJRankingDB)
	print("加载战绩排行榜:", #tKeys)
	for _, sCharID in ipairs(tKeys) do
		local nCharID = tonumber(sCharID)
		local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sZJRankingDB, nCharID)
		local tData = cjson.decode(sData)
		if tData[1] and tData[2] then
			self.m_oRanking:Insert(nCharID, tData)
		end
	end
end

function CZJRanking:SaveData()
	for nCharID, v in pairs(self.m_tDirtyMap) do
		local tData = self.m_oRanking:GetDataByKey(nCharID)
		if tData then
			local tRealData = {tData[1], tData[2]} --主意要转成数组
			goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sZJRankingDB, nCharID, cjson.encode(tRealData))
		end
	end
	self.m_tDirtyMap = {}
end

function CZJRanking:OnRelease()
	self:SaveData()
end

--重置清理数据库
function CZJRanking:ResetRanking()
	goDBMgr:GetSSDB("Player"):HClear(gtDBDef.sZJRankingDB)
	self.m_oRanking = CSkipList:new(_fnDescSort)
	self.m_tDirtyMap = {}
end

--设置脏数据
function CZJRanking:MarkDirty(nCharID, bDirty)
	bDirty = bDirty or nil
	self.m_tDirtyMap[nCharID] = bDirty
end

--更新数据
function CZJRanking:Update(oPlayer, nValue)
	local nCharID = oPlayer:GetCharID()
	local tData = self.m_oRanking:GetDataByKey(nCharID)
	if tData then
		if tData[2]	== nValue then
			return
		end
		assert(self.m_oRanking:Remove(nCharID), "删除数据失败:"..nCharID)
		tData[2] = nValue
	else
		tData = {"", nValue}
	end
	self.m_oRanking:Insert(nCharID, tData)
	self:MarkDirty(nCharID, true)
end

--取某个玩家排名
function CZJRanking:GetPlayerRank(nCharID)
	local nRank = self.m_oRanking:GetRankByKey(nCharID)
	return nRank
end

--排行榜请求
function CZJRanking:ZJRankingReq(oPlayer, nRankNum)
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
	}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "ZJRankingRet", tMsg)
	print("CZJRanking:ZJRankingReq***", tMsg)
end
