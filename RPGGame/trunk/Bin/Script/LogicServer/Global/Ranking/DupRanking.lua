--副本排行榜
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

function CDupRanking:Ctor(nID)
	self.m_nID = nID
	self.m_tDirtyMap = {} 
	self.m_oRanking = CSkipList:new(_fnDescSort) --{nCharID={sName,nValue}, ...}
end

function CDupRanking:LoadData()
	local tKeys = goDBMgr:GetSSDB("Player"):HKeys(gtDBDef.sDupRankingDB)
	print("加载副本排行榜:", #tKeys)
	for _, sCharID in ipairs(tKeys) do
		local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sDupRankingDB, sCharID)
		local tData = cjson.decode(sData)
		if ctCheckPointConf[tData[3]] then
			self.m_oRanking:Insert(tonumber(sCharID), tData)
		end
	end
end

function CDupRanking:SaveData()
	for nCharID, v in pairs(self.m_tDirtyMap) do
		local tData = self.m_oRanking:GetDataByKey(nCharID)
		if tData then
			local tRealData = {tData[1], tData[2], tData[3] or 1} --主意要转成数组
			goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sDupRankingDB, nCharID, cjson.encode(tRealData))
		end
	end
	self.m_tDirtyMap = {}
end

function CDupRanking:OnRelease()
	self:SaveData()
end

--重置清理数据库
function CDupRanking:ResetRanking()
	goDBMgr:GetSSDB("Player"):HClear(gtDBDef.sDupRankingDB)
	self.m_oRanking = CSkipList:new(_fnDescSort)
	self.m_tDirtyMap = {}
end

--设置脏数据
function CDupRanking:MarkDirty(nCharID, bDirty)
	bDirty = bDirty or nil
	self.m_tDirtyMap[nCharID] = bDirty
end

--更新数据
function CDupRanking:Update(oPlayer, nValue, nDupID)
	print("CDupRanking:Update***", oPlayer:GetName(), nValue)
	local nCharID = oPlayer:GetCharID()
	local tData = self.m_oRanking:GetDataByKey(nCharID)
	if tData then
		if tData[2]	== nValue then return end
		self.m_oRanking:Remove(nCharID)
		tData[2], tData[3] = nValue, nDupID
	else
		tData = {"", nValue, nDupID}
	end
	self.m_oRanking:Insert(nCharID, tData)
	self:MarkDirty(nCharID, true)

	local nNowRank = self:GetPlayerRank(nCharID)
	if nNowRank == 1 then 
		goBroadcast:SetBroadcast(34, 1, nCharID)
	end
end

--取某个玩家排名
function CDupRanking:GetPlayerRank(nCharID)
	local nRank = self.m_oRanking:GetRankByKey(nCharID)
	return nRank
end

--排行榜请求
function CDupRanking:DupRankingReq(oPlayer, nRankNum)
	local nCharID = oPlayer:GetCharID()
	nRankNum = math.max(1, math.min(100, nRankNum))

	--我的排名
	local nMyRank = self:GetPlayerRank(nCharID)
	local tMyData = self.m_oRanking:GetDataByKey(nCharID)
	local nMyValue, nMyDupID = 0, 1
	if tMyData then
		nMyValue, nMyDupID = tMyData[2], tMyData[3] or 1
	end

	--前nRankNum名玩家
	local tRanking = {}
	local function _fnTraverse(nRank, nCharID, tData)
		local tRank = {nRank=nRank, sName=goOfflineDataMgr:GetName(nCharID), nValue=tData[2], nDupID=tData[3] or 1}
		table.insert(tRanking, tRank)
	end
	self.m_oRanking:Traverse(1, nRankNum, _fnTraverse)

	local tMsg = {
		tRanking = tRanking,
		nMyRank = nMyRank,
		sMyName = oPlayer:GetName(),
		nMyValue = nMyValue,
		nMyDupID = nMyDupID,
		bMoBai = oPlayer.m_oMoBai:IsMoBai(self.m_nID)
	}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "DupRankingRet", tMsg)
	oPlayer.m_oMoBai:CheckRedPoint()
	print("CDupRanking:DupRankingReq***", tMsg.bMoBai)
end
