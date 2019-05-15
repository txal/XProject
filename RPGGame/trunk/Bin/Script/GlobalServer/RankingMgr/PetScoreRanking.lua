--宠物评分排行榜
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPetScoreRanking:Ctor(nID)
	CRankingBase.Ctor(self, nID)
end

--更新数据
function CPetScoreRanking:Update(nRoleID, nPetPos, sPetName, nValue)
	assert(nPetPos and sPetName and nValue, "参数错误")
	if nPetPos == 0 or nValue == 0 then
		return
	end

	local tData = self.m_oRanking:GetDataByKey(nRoleID)
	if tData then
		if tData[1]	== nValue and tData[2] == nPetPos then
			return
		end
		self.m_oRanking:Remove(nRoleID)
	end
	tData = {nValue, nPetPos, sPetName}

	self.m_oRanking:Insert(nRoleID, tData)
	self:MarkDirty(nRoleID, true)
end

--排行榜请求
function CPetScoreRanking:RankingReq(oRole, nRankNum)
	local nRoleID = oRole:GetID()
	nRankNum = math.max(1, math.min(CRankingBase.nMaxViewNum, nRankNum))

	--我的排名
	local nMyRank = self:GetKeyRank(nRoleID)
	local tMyData = self:GetKeyData(nRoleID)
	local nMyValue, nPetPos, sPetName = 0, 0, ""
	if tMyData then
		nMyValue, nMyPetPos, sMyPetName = table.unpack(tMyData)
	end

	--前nRankNum名
	local tRanking = {}
	local function _fnTraverse(nRank, nRoleID, tData)
		local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
		local tRank = {nRank=nRank, nValue=tData[1], nRoleID=nRoleID, sRoleName=oRole:GetName(), nPetPos=tData[2], sPetName=tData[3]}
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
