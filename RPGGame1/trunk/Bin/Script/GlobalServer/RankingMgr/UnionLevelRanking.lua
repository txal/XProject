--帮派等级排行榜
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CUnionLevelRanking:Ctor(nID)
	CRankingBase.Ctor(self, nID)
end

function CUnionLevelRanking:LoadData()
	local oSSDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())
	local sDBName = self:GetDBName()

	local tKeys = oSSDB:HKeys(sDBName)
	print("加载排行榜:", self:GetID(), #tKeys)

	for _, sUnionID in ipairs(tKeys) do
		local nUnionID = tonumber(sUnionID)
		if goUnionMgr:GetUnion(nUnionID) then
			local sData = oSSDB:HGet(sDBName, sUnionID)
			self.m_oRanking:Insert(nUnionID, cseri.decode(sData))
		end
	end
end

--排行榜请求
function CUnionLevelRanking:RankingReq(oRole, nRankNum)
	local nRoleID = oRole:GetID()
	nRankNum = math.max(1, math.min(CRankingBase.nMaxViewNum, nRankNum))

	local nMyRank, nMyValue = 0, 0
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if oUnion then
		nMyRank = self:GetKeyRank(nRoleID)
		local tMyData = self:GetKeyData(nRoleID)
		nMyValue = tMyData and tMyData[1] or 0
	end

	--前nRankNum名
	local tRanking = {}
	local function _fnTraverse(nRank, nUnionID, tData)
		local oUnion = goUnionMgr:GetUnion(nUnionID)
		if oUnion then
			local nMengZhu = oUnion:GetMengZhu()
			local sMengZhu = oUnion:GetMengZhuName()
			local tRank = {nRank=nRank, nValue=tData[1], nRoleID=nMengZhu, sRoleName=sMengZhu, sUnionName=oUnion:GetName()}
			table.insert(tRanking, tRank)
		end
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
