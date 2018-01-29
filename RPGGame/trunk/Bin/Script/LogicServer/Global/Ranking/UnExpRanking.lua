--联盟经验排行榜
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

function CUnExpRanking:Ctor()
	self.m_tDirtyMap = {} 
	self.m_oRanking = CSkipList:new(_fnDescSort) --{nCharID={sName,nValue}, ...}
end

function CUnExpRanking:LoadData()
	local tKeys = goDBMgr:GetSSDB("Player"):HKeys(gtDBDef.sUnExpRankingDB)
	print("加载联盟经验排行榜:", #tKeys)
	for _, sCharID in ipairs(tKeys) do
		local nCharID = tonumber(sCharID)
		local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sUnExpRankingDB, nCharID)
		local tData = cjson.decode(sData)
		if tData[1] and tData[2] then
			self.m_oRanking:Insert(nCharID, tData)
		end
	end
end

function CUnExpRanking:SaveData()
	for nCharID, v in pairs(self.m_tDirtyMap) do
		local tData = self.m_oRanking:GetDataByKey(nCharID)
		if tData then
			local tRealData = {tData[1], tData[2]} --主意要转成数组
			goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sUnExpRankingDB, nCharID, cjson.encode(tRealData))
		end
	end
	self.m_tDirtyMap = {}
end

function CUnExpRanking:OnRelease()
	self:SaveData()
end

--重置清理数据库
function CUnExpRanking:ResetRanking()
	goDBMgr:GetSSDB("Player"):HClear(gtDBDef.sUnExpRankingDB)
	self.m_oRanking = CSkipList:new(_fnDescSort)
	self.m_tDirtyMap = {}
end

--设置脏数据
function CUnExpRanking:MarkDirty(nCharID, bDirty)
	bDirty = bDirty or nil
	self.m_tDirtyMap[nCharID] = bDirty
end

--更新数据
function CUnExpRanking:Update(nUnionID, nValue, sUnionName)
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
end

--移除联盟
function CUnExpRanking:Remove(nUnionID)
	self.m_oRanking:Remove(nUnionID)
	goDBMgr:GetSSDB("Player"):HDel(gtDBDef.sUnExpRankingDB, nUnionID)
end

--取某个玩家排名
function CUnExpRanking:GetUnionRank(nUnionID)
	local nRank = self.m_oRanking:GetRankByKey(nUnionID)
	return nRank
end

--排行榜请求
function CUnExpRanking:UnExpRankingReq(oPlayer, nRankNum)
end
