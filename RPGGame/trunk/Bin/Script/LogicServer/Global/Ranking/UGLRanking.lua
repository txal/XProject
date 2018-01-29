--联盟国力排行榜
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

function CUGLRanking:Ctor()
	self.m_tDirtyMap = {} 
	self.m_oRanking = CSkipList:new(_fnDescSort) --{nUnionID={sName,nValue}, ...}
end

function CUGLRanking:LoadData()
	local tKeys = goDBMgr:GetSSDB("Player"):HKeys(gtDBDef.sUGLRankingDB)
	print("加载联盟国力排行榜:", #tKeys)
	for _, sUnionID in ipairs(tKeys) do
		local nUnionID = tonumber(sUnionID)
		if goUnionMgr:GetUnion(nUnionID) then
			local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sUGLRankingDB, sUnionID)
			local tData = cjson.decode(sData)
			if tData[1] and tData[2] then
				self.m_oRanking:Insert(nUnionID, tData)
			end
		end
	end
end

function CUGLRanking:SaveData()
	for nUnionID, v in pairs(self.m_tDirtyMap) do
		local tData = self.m_oRanking:GetDataByKey(nUnionID)
		if tData then
			local tRealData = {tData[1], tData[2]} --主意要转成数组
			goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sUGLRankingDB, nUnionID, cjson.encode(tRealData))
		end
	end
	self.m_tDirtyMap = {}
end

function CUGLRanking:OnRelease()
	self:SaveData()
end

--重置清理数据库
function CUGLRanking:ResetRanking()
	goDBMgr:GetSSDB("Player"):HClear(gtDBDef.sUGLRankingDB)
	self.m_oRanking = CSkipList:new(_fnDescSort)
	self.m_tDirtyMap = {}
end

--设置脏数据
function CUGLRanking:MarkDirty(nUnionID, bDirty)
	bDirty = bDirty or nil
	self.m_tDirtyMap[nUnionID] = bDirty
end

--更新数据
function CUGLRanking:Update(nUnionID, nValue, sUnionName)
	local tData = self.m_oRanking:GetDataByKey(nUnionID)
	if tData then
		if tData[2]	== nValue then
			return
		end
		assert(self.m_oRanking:Remove(nUnionID), "删除数据失败:"..nUnionID)
		tData[2] = nValue
	else
		tData = {sUnionName, nValue}
	end
	self.m_oRanking:Insert(nUnionID, tData)
	self:MarkDirty(nUnionID, true)

	-- if self:GetUnionRank(nUnionID) == 1 then 
	--  	goBroadcast:SetBroadcast(59, 2, nUnionID)
	-- end
end

--移除联盟
function CUGLRanking:Remove(nUnionID)
	self.m_oRanking:Remove(nUnionID)
	goDBMgr:GetSSDB("Player"):HDel(gtDBDef.sUGLRankingDB, nUnionID)
end

--取某个联盟排名
function CUGLRanking:GetUnionRank(nUnionID)
	local nRank = self.m_oRanking:GetRankByKey(nUnionID)
	return nRank
end

--取联盟总数
function CUGLRanking:GetUnionCount()
	return self.m_oRanking:GetCount()
end

--取联盟总国力
function CUGLRanking:GetUnionGuoLi(nUnionID)
	local tData = self.m_oRanking:GetDataByKey(nUnionID)
	return (tData and tData[2] or 0)
end

--排行榜请求
function CUGLRanking:UGLRankingReq(oPlayer, nRankNum, nType)
	local nCharID = oPlayer:GetCharID()
	nRankNum = math.max(1, math.min(100, nRankNum))

	--我的排名
	local nMyRank, sMyName, nMyValue = 0, "", 0
	local oMyUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if oMyUnion then
		local nUnionID = oMyUnion:GetID()
		nMyRank = self:GetUnionRank(nUnionID)
		tMyData = self.m_oRanking:GetDataByKey(nUnionID)
		nMyValue = tMyData and tMyData[2] or 0
		sMyName = oMyUnion:GetName()
	end

	--前nRankNum名联盟
	local tRanking = {}
	local function _fnTraverse(nRank, nUnionID, tData)
		local oUnion = goUnionMgr:GetUnion(nUnionID)
		if oUnion then
			local tRank = {nRank=nRank, sName=tData[1], nValue=tData[2], nLevel=0, sMengZhu="", nMember=0, nMaxMember=0}
			tRank.nLevel = oUnion:GetLevel()
			tRank.sMengZhu = oUnion:GetMengZhuName()
			tRank.nMember = oUnion:GetMembers()
			tRank.nMaxMember = oUnion:MaxMembers()
			table.insert(tRanking, tRank)
		end
	end
	self.m_oRanking:Traverse(1, nRankNum, _fnTraverse)
	local tMsg = {
		tRanking = tRanking,
		nMyRank = nMyRank,
		sMyName = sMyName,
		nMyValue = nMyValue,
		nType = nType, 
	}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "UGLRankingRet", tMsg)
	print("CUGLRanking:UGLRankingReq***", tMsg)
end
