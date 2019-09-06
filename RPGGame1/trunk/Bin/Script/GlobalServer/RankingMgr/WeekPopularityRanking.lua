--人气周排行
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CWeekPopularityRanking:Ctor(nID)
	CRankingBase.Ctor(self, nID)
	self.m_nLastWeekTime = os.time()
	self.m_bDirty = false
end

function CWeekPopularityRanking:LoadData()
	CRankingBase.LoadData(self)
	--杂项
	local oSSDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())
	local sEtcData = oSSDB:HGet(gtDBDef.sRankingEtcDB, self:GetID())
	if sEtcData ~= "" then
		local tEtcData = cseri.decode(sEtcData)
		self.m_nLastWeekTime = tEtcData.m_nLastWeekTime
	end
end

function CWeekPopularityRanking:SaveData()
	CRankingBase.SaveData(self)
	
	--杂项
	local oSSDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())
	if self:IsEtcDirty() then
		local tData = {m_nLastWeekTime = self.m_nLastWeekTime}
		oSSDB:HSet(gtDBDef.sRankingEtcDB, self:GetID(), cseri.encode(tData))
		self:MarkEtcDirty(false)
	end
end

function CWeekPopularityRanking:MarkEtcDirty(bDirty) self.m_bDirty = true end
function CWeekPopularityRanking:IsEtcDirty() return self.m_bDirty end

--检测重置
function CWeekPopularityRanking:CheckReset()
	if not os.IsSameWeek(os.time(), self.m_nLastWeekTime, 0) then
		self.m_nLastWeekTime = os.time()
		self:MarkEtcDirty(true)
		self:ResetRanking()
	end
end

--更新数据
function CWeekPopularityRanking:Update(nRoleID, nValue)
	self:CheckReset()
	CRankingBase.Update(self, nRoleID, nValue)

	if nValue == 0 then
		return
	end

	--更新总榜
	local oRanking = goRankingMgr:GetRanking(gtRankingDef.ePopularityRanking)
	oRanking:Update(nRoleID, nValue)
end

--排行榜请求
function CWeekPopularityRanking:RankingReq(oRole, nRankNum)
	self:CheckReset()

	local nRoleID = oRole:GetID()
	nRankNum = math.max(1, math.min(CRankingBase.nMaxViewNum, nRankNum))

	--我的排名
	local nMyRank = self:GetKeyRank(nRoleID)
	local tMyData = self:GetKeyData(nRoleID)
	local nMyValue = tMyData and tMyData[1] or 0

	--前nRankNum名
	local tRanking = {}
	local function _fnTraverse(nRank, nRoleID, tData)
		local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
		local tRank = {nRank=nRank, nValue=tData[1], nRoleID=nRoleID, sRoleName=oRole:GetName(), nSchool=oRole:GetSchool()}
		table.insert(tRanking, tRank)
	end
	self.m_oRanking:Traverse(1, nRankNum, _fnTraverse)
	local tMsg = {
		nRankID = self:GetID(),
		tRanking = tRanking,
		nMyRank = nMyRank,
		nMyValue = nMyValue,
	}
	oRole:SendMsg("RankingListRet", tMsg)
end

