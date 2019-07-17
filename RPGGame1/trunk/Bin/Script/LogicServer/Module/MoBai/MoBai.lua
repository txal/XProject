local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CMoBai:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_tMoBaiMap = {} --{[rankingid]=0/1,...}
	self.m_nResetTime = os.time()
end

function CMoBai:LoadData(tData)
	if tData then
		self.m_tMoBaiMap = tData.m_tMoBaiMap
		self.m_nResetTime = tData.m_nResetTime
	end
end

function CMoBai:SaveData()
	if not self:IsDirty() then return end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tMoBaiMap = self.m_tMoBaiMap
	tData.m_nResetTime = self.m_nResetTime
	return tData
end

function CMoBai:GetType()
	return gtModuleDef.tMoBai.nID, gtModuleDef.tMoBai.sName
end

function CMoBai:Online()
	self:CheckRedPoint()
end

function CMoBai:CheckReset()
	if not os.IsSameDay(os.time(), self.m_nResetTime, 5*3600) then
		self.m_nResetTime = os.time()
		self.m_tMoBaiMap = {}
		self:MarkDirty(true)
	end
end

function CMoBai:MoBaiReq(nRankID)
	print("CMoBai:MoBaiReq***", nRankID)
	self:CheckReset()
	local oRanking = goRankingMgr:GetRanking(nRankID)
	if not oRanking then
		return self.m_oPlayer:Tips("排行榜不存在:"..nRankID)
	end

	if self.m_tMoBaiMap[nRankID] then
		return self.m_oPlayer:Tips("您今天已经膜拜过")
	end

	local nRankNum = 11
	local tRanking = {}
	local function _fnTraverse(nRank, nTmpCharID, tData)
		if nTmpCharID == nCharID or #tRanking >= nRankNum then
			return
		end
		local sName = goOfflineDataMgr:GetName(nTmpCharID)
		table.insert(tRanking, sName)
	end
	oRanking.m_oRanking:Traverse(1, nRankNum, _fnTraverse)
	if #tRanking <= 0 then
		return self.m_oPlayer:Tips("没有可膜拜的玩家")
	end
	local sTarName = tRanking[math.random(#tRanking)]

	--50%概率获得1元宝，50%概率获得2元宝
	local nRnd = math.random(1, 100)
	local nYuanBao = 0
	local nZhuFu = self.m_oPlayer.m_oShenJiZhuFu:ShenJiZhuFu(gtSJZFDef.eTCYB)  --神迹祝福
	if nRnd <= 50 then
		nYuanBao = 10+nZhuFu
	else
		nYuanBao = 20+nZhuFu
	end
	self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eYuanBao, nYuanBao, "膜拜排行榜:"..nRankID)
	self.m_tMoBaiMap[nRankID] = 1
	self:MarkDirty(true)

	Network.PBSrv2Clt(self.m_oPlayer:GetSession(), "MoBaiRet", {nRankID=nRankID, sTarName=sTarName, nType=gtItemType.eCurr, nID=gtCurrType.eYuanBao, nNum=nYuanBao})
	--小红点
	self:CheckRedPoint()

	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond11, 1)
	self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond9, 1)
end

function CMoBai:IsMoBai(nRankID)
	self:CheckReset()
	print("CMoBai:IsMoBai***", nRankID, self.m_tMoBaiMap)
	return (self.m_tMoBaiMap[nRankID] or 0) > 0
end

function CMoBai:CheckRedPoint()
	self:CheckReset()
	local tList = {}

	local tRank = {gtRankingDef.eGLRanking, gtRankingDef.eDupRanking, gtRankingDef.eQMRanking}	
	for _, nRankID in ipairs(tRank) do
		local oRanking = goRankingMgr:GetRanking(nRankID)
		if oRanking and not self.m_tMoBaiMap[nRankID] and oRanking.m_oRanking:GetCount() >= 2 then
			table.insert(tList, nRankID)
		end
	end
	print("CMoBai:CheckRedPoint***", tList)
	Network.PBSrv2Clt(self.m_oPlayer:GetSession(), "MoBaiRedPointRet", {tList=tList})
end