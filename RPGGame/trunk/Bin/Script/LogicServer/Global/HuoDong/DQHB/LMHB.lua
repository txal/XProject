--联盟经验皇榜
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

CLMHB.tAwardState = 
{
	eInit = 0, 	--初始状态	
	eFeed = 1, 	--满足未领取
	eClose = 2, --已领取
}

function CLMHB:Ctor(nID)
	CHDBase.Ctor(self, nID)
	self:Init()
end

function CLMHB:Init()
	self.m_tInitLM = {}               --保存初始表
	self.m_tDiffLM = {}               --增值变化表
	self.m_tRanking = {}              --更新排行榜表
	self.m_tAwardState = {}           --奖励状态表
	self.m_nLastRankTime = 0          --保持上次排序时间
end

function CLMHB:LoadData()
	local nID = self:GetID()
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sHuoDongDB, self:GetID())
	if sData == "" then
		return
	end
	local tData = cjson.decode(sData)
	
	self.m_tRanking = tData.m_tRanking
	self.m_tInitLM = tData.m_tInitLM
	self.m_tDiffLM = tData.m_tDiffLM
	self.m_tAwardState = tData.m_tAwardState
	CHDBase.LoadData(self, tData)
end

function CLMHB:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)     --非脏有数据变化就保存

	local tData = CHDBase.SaveData(self)
	tData.m_tRanking = self.m_tRanking
	tData.m_tInitLM = self.m_tInitLM
	tData.m_tDiffLM = self.m_tDiffLM
	tData.m_tAwardState = self.m_tAwardState
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sHuoDongDB, self:GetID(), cjson.encode(tData))
end

function CLMHB:CheckAwardState(oPlayer)
	local nCharID = oPlayer:GetCharID()
	local nMyRank = self:MyUnionRank(oPlayer)
	local tCong = ctDQHBEtcConf[1]
	if self:GetState() == CLMHB.tState.eAward
		and not self.m_tAwardState[nCharID]
		and nMyRank > 0 and nMyRank <= tCong.nLMExpAwardRanking then
			self.m_tAwardState[nCharID] = CLMHB.tAwardState.eFeed
			self:MarkDirty(true)
	end
	return self.m_tAwardState[nCharID]
end

--进入活动  
function CLMHB:InActivityReq(oPlayer)
	if self:GetState() == CLMHB.tState.eInit or self:GetState() == CLMHB.tState.eClose then
		return oPlayer:Tips("活动已结束")
	end

	self:LMRankingDeal()
	self:CheckAwardState(oPlayer)

	local nCharID = oPlayer:GetCharID()
	local nUnionRank = self:MyUnionRank(oPlayer) or 0

	local sFirstName = ""
	local nFirstValue = 0
	local nID = self.m_tRanking[1]
	if nID then
		local tConf = self.m_tDiffLM[nID]
		sFirstName = tConf.sName
		nFirstValue = tConf.nValue
	end

	local nRemainTime = self:GetStateTime()
	local nState = self.m_tAwardState[nCharID] or CLMHB.tAwardState.eInit  
	local tMsg = {nRemainTime=nRemainTime, nAwardState=nState, nID=self:GetID(), nMyRank=nUnionRank, sFirstName=sFirstName, nFirstValue=nFirstValue}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "HBInActivityRet", tMsg)
	self:MarkDirty(true)
end

--冲榜榜单处理
function CLMHB:LMRankingDeal(bEnd)
	if self:GetState() == self.tState.eStart or bEnd then 
		local tConf = ctDQHBEtcConf[1]   
		if os.time() - self.m_nLastRankTime >= tConf.nRankingUpdateTime or bEnd then 
			self.m_nLastRankTime = os.time()

			self.m_tRanking = {}
			local function _fnTraverse(nRank, nCharID, tData)
				local nInitVal = self.m_tInitLM[nCharID] and self.m_tInitLM[nCharID].nValue or 0
				local nDiff = tData[2]-nInitVal
				if nDiff > 0 then
					self.m_tDiffLM[nCharID] = {nCharID=nCharID, sName=goUnionMgr:GetUnion(nCharID).m_sName, nValue=nDiff}
					table.insert(self.m_tRanking, nCharID)
				end
			end
			local nRankNum = goRankingMgr.m_oUnExpRanking.m_oRanking:GetCount()      
			goRankingMgr.m_oUnExpRanking.m_oRanking:Traverse(1, nRankNum, _fnTraverse)

			table.sort(self.m_tRanking, function(v1, v2)
				local nVal1 = self.m_tDiffLM[v1].nValue 
				local nVal2 = self.m_tDiffLM[v2].nValue
				if nVal1 == nVal2 then
					return v1 < v2
				end
				return nVal1 > nVal2
			end)
			self:MarkDirty(true)

			goBroadcast:SetBroadcast(46, 2, self.m_tRanking[1])
		end
	end
end

--我联盟的排名
function CLMHB:MyUnionRank(oPlayer)
	local nUnionRank = 0				--联盟排名
	local nUnionValue = 0				--联盟增幅
	local sUnionName = ""				--联盟名字
	local nCharID = oPlayer:GetCharID()
	local oMyUnion = goUnionMgr:GetUnionByCharID(nCharID)       --我的联盟
	if not oMyUnion  then
		if self.m_tAwardState[nCharID] == CLMHB.tAwardState.eFeed then 
			self.m_tAwardState[nCharID] = nil
		end
		return nUnionRank, nUnionValue, sUnionName 
	end
	
	local nUnionID = oMyUnion.m_nID		--联盟ID              
	if self.m_tDiffLM[nUnionID] then
		local function fnCmp(v1, v2)
			local nVal1 = self.m_tDiffLM[v1].nValue    --增值1
			local nVal2 = self.m_tDiffLM[v2].nValue    --增值2
			if nVal1 == nVal2 then
				if v1 == v2 then
					return 0
				end
				if v1 > v2 then
					return 1
				else
					return -1
				end
			else
				if nVal1 > nVal2 then
					return -1
				else
					return 1
				end
			end
		end
		nUnionRank = CAlg:BinarySearch(self.m_tRanking, fnCmp, nUnionID)
		nUnionValue = self.m_tDiffLM[nUnionID].nValue 
		sUnionName = oMyUnion.m_sName
	end
	return nUnionRank, nUnionValue, sUnionName
end

--冲榜榜单
function CLMHB:RankingReq(oPlayer, nRankNum)
	if self:GetState() == CLMHB.tState.eInit or self:GetState() == CLMHB.tState.eClose then
		return oPlayer:Tips("活动已结束")
	end

	if not self.m_tRanking then
		return
	end

	local tConf = ctDQHBEtcConf[1]
	nRankNum = math.max(1, math.min(tConf.nLMExpAwardRanking, nRankNum))
	local nUnionRank, nUnionValue, sUnionName = self:MyUnionRank(oPlayer)
	local tRanking = {}
	for i=1, nRankNum do
		local nID = self.m_tRanking[i]
		if nID then
			local tRank = {nRank=i, sName=self.m_tDiffLM[nID].sName, nValue=self.m_tDiffLM[nID].nValue}
			table.insert(tRanking, tRank)
		else
			break
		end
	end

	local tMsg = {
		tRanking = tRanking,
		nMyRank = nUnionRank,
		nMyValue = nUnionValue,
		sMyName = sUnionName,
		nID = self:GetID()
	}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "HBRankingRet", tMsg)
	self:MarkDirty(true)
end

--奖励列表
function CLMHB:GetRankAward(nRank, nPos)
	local tList = {}
	for k=#ctLMExpRankingConf, 1, -1 do 
		local tConf = ctLMExpRankingConf[k]
		local tRank = tConf.tRanking[1]
		if nRank >= tRank[1] and nRank <= tRank[2] then 
			local tAward
			if self:GetOpenTimes() > 1 then
				tAward = tConf["tAward2"..nPos]
			else
				tAward = tConf["tAward1"..nPos]
			end
			for _, tItem in ipairs(tAward) do 
				table.insert(tList, {tItem[1], tItem[2], tItem[3]})
			end
			break
		end
	end
	return tList
end

--领取奖励
function CLMHB:GetAwardReq(oPlayer)
	if self:GetState() ~= CLMHB.tState.eAward then
		return oPlayer:Tips("未到领奖时间")
	end
	local nCharID = oPlayer:GetCharID()
	local nUnionRank = self:MyUnionRank(oPlayer)
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)

	if not oUnion then
		return oPlayer:Tips("请加入联盟")
	end

	local tConf = ctDQHBEtcConf[1]
	if nUnionRank > tConf.nLMExpAwardRanking or nUnionRank == 0 then 
		return oPlayer:Tips("未上榜")                                 --不在领奖排名中 
	end
	if self.m_tAwardState[nCharID] == CLMHB.tAwardState.eClose then
		return oPlayer:Tips("已领取过")
	end

	self.m_tAwardState[nCharID] = CLMHB.tAwardState.eClose            --已领取
	self:MarkDirty(true)
	
	local tList = {}
	local nMyPos = oUnion:GetPos(nCharID)
	local tAward = self:GetRankAward(nUnionRank, nMyPos)
	for _, tItem in ipairs(tAward) do 
		oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "联盟排名奖励")
		table.insert(tList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
	end

	local tMsg = {tList=tList, nAwardState=self.m_tAwardState[nCharID], nMyPos=nMyPos}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "HBGetAwardRet", tMsg)
	self:CheckRedPoint(nCharID)
end

--是否能领奖
function CLMHB:CanGetAward(oPlayer)
	if self:GetState() ~= CLMHB.tState.eAward then
		return false
	end
	if self:CheckAwardState(oPlayer) == CLMHB.tAwardState.eFeed then
		return true 
	end
	return false
end

--玩家上线
function CLMHB:Online(oPlayer)
	goHBMgr:Online(oPlayer)
end

--进入初始状态
function CLMHB:OnStateInit()
	print("活动:", self.m_nID, "进入初始状态")
	goHBMgr:OnStateInit()
end

--进入活动状态
function CLMHB:OnStateStart()
	print("活动:", self.m_nID, "进入开始状态")
	self:Init()
	goOfflineDataMgr.m_oGSGData:SetFirst(self.m_nID)
	goBroadcast:SetBroadcast(46, 2, self.m_tRanking[1], true)

	local function _fnTraverse(nRank, nCharID, tData)                     
		local tRank = {nCharID=nCharID,sName=goOfflineDataMgr:GetName(nCharID), nValue=tData[2]}
		self.m_tInitLM[nCharID] = tRank                                   --保存初始表
	end
	local nRankNum = goRankingMgr.m_oUnExpRanking.m_oRanking:GetCount()      --获取所有排名
	goRankingMgr.m_oUnExpRanking.m_oRanking:Traverse(1, nRankNum, _fnTraverse)
	self:MarkDirty(true)
	goHBMgr:OnStateStart()
end

--进入领奖状态
function CLMHB:OnStateAward()
	print("活动:", self.m_nID, "进入奖励状态")
	self:LMRankingDeal(true)    
	goHBMgr:OnStateAward()

	local nUnionID = self.m_tRanking[1]
	if nUnionID then 	
		local oUnion = goUnionMgr:GetUnion(nUnionID)
		goOfflineDataMgr.m_oGSGData:SetFirst(self.m_nID, oUnion.m_nMengZhu, os.time())
	end
end

--进入关闭状态
function CLMHB:OnStateClose()
	print("活动:", self.m_nID, "进入关闭状态")
	goHBMgr:OnStateClose()
	self:CheckAward()
end

--检测未领奖的玩家,然后发奖
function CLMHB:CheckAward()
	local tConf = ctDQHBEtcConf[1]
	for k = 1, tConf.nLMExpAwardRanking do
		local nUnionID = self.m_tRanking[k]
		local oUnion = goUnionMgr:GetUnion(nUnionID)
		if oUnion then
			local tMemberMap = oUnion:GetMemberMap()
			for nCharID, v in pairs(tMemberMap) do
				local nPos = oUnion:GetPos(nCharID)
				local tList = self:GetRankAward(k, nPos)
				goMailMgr:SendMail("系统邮件", "联盟冲榜奖励", "您的联盟在联盟冲榜活动中获得第"..k.."名，获得了以下奖励，请查收。", tList, nCharID)
			end
		end
	end
end

--检测小红点
function CLMHB:CheckRedPoint(nCharID)
	local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
	if not oPlayer then
		return
	end
	goHBMgr:SyncState(oPlayer)
end