--全服消耗元宝冲榜
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CResumeYBCB:Ctor(nID)
	CCBBase.Ctor(self, nID)     --继承基类
end

function CResumeYBCB:GetRankingConf()
	return ctResumeYBRankingKFConf
end

function CResumeYBCB:GetAwardRanking()
	local tConf = ctMZCBEtcConf[1]
	return 1, tConf.nResumeYBAwardRanking
end

--获取上榜条件值
function CResumeYBCB:GetRankLimitValue()
	return ctMZCBEtcConf[1].nConsumeYBRankLimit
end

--冲榜榜单请求
function CResumeYBCB:RankingReq(oRole, nRankNum)
	if self:GetState() == CHDBase.tState.eInit or self:GetState() == CHDBase.tState.eClose then
		return oRole:Tips("活动已结束")
	end

	local nMinRank, nMaxRank = self:GetAwardRanking()
	nRankNum = math.max(1, math.min(nMaxRank, nRankNum))
	local nMyRank, nMyValue = self:MyRank(oRole:GetID())

	local tRanking = {}
	for k=1, nRankNum do 
		local tRank = self.m_tTmpRanking[k]
		if tRank then
			local oRole = goGPlayerMgr:GetRoleByID(tRank[1])
			local sExtName = oRole and goServerMgr:GetServerName(oRole:GetServer()) or ""
			local nValue = tRank[2]
			if #tRanking >= 3 then
				nValue = "***" --运营指定,显示前50名,只有前3显示充值金额.
			end
			table.insert(tRanking, {nRank=k, sName=goGPlayerMgr:GetRoleByID(tRank[1]):GetName(), nValue=nValue, sExtName=sExtName})
		else
			break
		end
	end

	local tMsg = {
		nID = self:GetID(),
		tRanking = tRanking,
		nMyRank = nMyRank,
		nMyValue = nMyValue,
	}
	oRole:SendMsg("CBRankingRet", tMsg)
	print("RankingReq***", self:GetName(), tMsg)
end
