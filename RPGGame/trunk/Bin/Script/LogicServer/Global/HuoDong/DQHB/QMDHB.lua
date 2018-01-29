--亲密皇榜
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

CQMDHB.tAwardState = 
{
	eInit = 0, 	--初始状态	
	eFeed = 1, 	--满足未领取
	eClose = 2, --已领取
}

function CQMDHB:Ctor(nID)
	CHDBase.Ctor(self, nID)
	self:Init()
end

function CQMDHB:Init()
	self.m_tInitQM = {}               --保存初始表
	self.m_tDiffQM = {}               --增值变化表
	self.m_tRanking = {}              --更新排行榜表
	self.m_tAwardState = {}           --奖励状态表
	self.m_nLastRankTime = 0          --保持上次排序时间
end

function CQMDHB:LoadData()
	local nID = self:GetID()
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sHuoDongDB, self:GetID())
	if sData ~= "" then
		local tData = cjson.decode(sData)
		
		self.m_tRanking = tData.m_tRanking
		self.m_tInitQM = tData.m_tInitQM
		self.m_tDiffQM = tData.m_tDiffQM
		self.m_tAwardState = tData.m_tAwardState

		CHDBase.LoadData(self, tData)
	end
end

function CQMDHB:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)     --非脏有数据变化就保存

	local tData = CHDBase.SaveData(self)
	tData.m_tRanking = self.m_tRanking
	tData.m_tInitQM = self.m_tInitQM
	tData.m_tDiffQM = self.m_tDiffQM
	tData.m_tAwardState = self.m_tAwardState
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sHuoDongDB, self:GetID(), cjson.encode(tData))
end

function CQMDHB:CheckAwardState(oPlayer)
	local nCharID = oPlayer:GetCharID()
	local nMyRank = self:MyRank(oPlayer)
	local tCong = ctDQHBEtcConf[1]
	if self:GetState() == CGLHB.tState.eAward
		and not self.m_tAwardState[nCharID]
		and nMyRank > 0 and nMyRank <= tCong.nQMDAwardRanking then
			self.m_tAwardState[nCharID] = CQMDHB.tAwardState.eFeed
			self:MarkDirty(true)
	end
	return self.m_tAwardState[nCharID]
end

--进入活动  
function CQMDHB:InActivityReq(oPlayer)
	if self:GetState() == CQMDHB.tState.eInit or self:GetState() == CQMDHB.tState.eClose then
		return oPlayer:Tips("活动已结束")
	end

	self:QMDRankingDeal()
	self:CheckAwardState(oPlayer)

	local nCharID = oPlayer:GetCharID()
	local nMyRank = self:MyRank(oPlayer)

	local sFirstName = ""
	local nFirstValue = 0
	local nID = self.m_tRanking[1]
	if nID then
		local tConf = self.m_tDiffQM[nID]
		sFirstName = tConf.sName
		nFirstValue = tConf.nValue
	end

	local nRemainTime = self:GetStateTime()
	local nState = self.m_tAwardState[nCharID] or CQMDHB.tAwardState.eInit  
	local tMsg = {nRemainTime=nRemainTime, nAwardState=nState, nID=self:GetID(), sFirstName=sFirstName, nFirstValue=nFirstValue, nMyRank=nMyRank}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "HBInActivityRet", tMsg)
	self:MarkDirty(true)
end

--冲榜榜单处理
function CQMDHB:QMDRankingDeal(bEnd)
	if self:GetState() == self.tState.eStart or bEnd then
		local tConf = ctDQHBEtcConf[1]    
		if os.time() - self.m_nLastRankTime >= tConf.nRankingUpdateTime or bEnd then 
			self.m_nLastRankTime = os.time()

			local tTempRanking = self.m_tRanking or {}
			self.m_tRanking = {}
			local function _fnTraverse(nRank, nCharID, tData)
				local nInitVal = self.m_tInitQM[nCharID] and self.m_tInitQM[nCharID].nValue or 0
				local nDiff = tData[2]- nInitVal
				if nDiff > 0 then
					self.m_tDiffQM[nCharID] = {nCharID=nCharID, sName=goOfflineDataMgr:GetName(nCharID), nValue=nDiff}
					table.insert(self.m_tRanking, nCharID)
				end
			end
			local nRankNum = goRankingMgr.m_oQMRanking.m_oRanking:GetCount()      
			goRankingMgr.m_oQMRanking.m_oRanking:Traverse(1, nRankNum, _fnTraverse)

			table.sort(self.m_tRanking, function(v1, v2)
				local nVal1 = self.m_tDiffQM[v1].nValue 
				local nVal2 = self.m_tDiffQM[v2].nValue
				if nVal1 == nVal2 then
					return v1 < v2
				end
				return nVal1 > nVal2
			end)
			self:MarkDirty(true)
			
			--播报
			for nRank, nCharID in pairs(tTempRanking) do 
				local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
				if oPlayer then 
					local nNowRank = self:MyRank(oPlayer) 
					goBroadcast:UpdateRanking(43, oPlayer, nRank, nNowRank)
				end
			end
			goBroadcast:SetBroadcast(43, 1, self.m_tRanking[1])
		end
	end
end

--我的排名
function CQMDHB:MyRank(oPlayer)
	local nCharID = oPlayer:GetCharID()

	local nMyRank = 0
	local nMyValue = 0
	local sMyName = ""
	if self.m_tDiffQM[nCharID] then
		local function fnCmp(v1, v2)
			local nVal1 = self.m_tDiffQM[v1].nValue    --增值1
			local nVal2 = self.m_tDiffQM[v2].nValue    --增值2
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
		nMyRank = CAlg:BinarySearch(self.m_tRanking, fnCmp, nCharID)
		nMyValue = self.m_tDiffQM[nCharID].nValue 
		sMyName = oPlayer:GetName()
	end
	return nMyRank, nMyValue, sMyName
end

--冲榜榜单
function CQMDHB:RankingReq(oPlayer, nRankNum)
	if self:GetState() == CQMDHB.tState.eInit or self:GetState() == CQMDHB.tState.eClose then
		return oPlayer:Tips("活动已结束")
	end

	local nCharID = oPlayer:GetCharID()
	local tConf = ctDQHBEtcConf[1]
	nRankNum = math.max(1, math.min(tConf.nQMDAwardRanking, nRankNum))
	local nMyRank, nMyValue, sMyName = self:MyRank(oPlayer)
	local tRanking = {}
	for i=1, nRankNum do
		local nID = self.m_tRanking[i]
		if nID then
			local tRank = {nRank=i, sName=self.m_tDiffQM[nID].sName, nValue=self.m_tDiffQM[nID].nValue}
			table.insert(tRanking, tRank)
		else
			break
		end
	end

	local tMsg = {
		tRanking = tRanking,
		nMyRank = nMyRank,
		sMyName = sMyName,
		nMyValue = nMyValue,
		nID = self:GetID()
	}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "HBRankingRet", tMsg)
	self:MarkDirty(true)
end

--奖励列表
function CQMDHB:GetRankAward(nRank)
	local tList = {}
	for k=#ctQMDRankingConf, 1, -1 do 
		local tConf = ctQMDRankingConf[k]
		local tRank = tConf.tRanking[1]
		if nRank >= tRank[1] and nRank <= tRank[2] then 
			local tAward
			if self:GetOpenTimes() > 1 then 
				tAward = tConf.tAward1
			else
				tAward = tConf.tAward
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
function CQMDHB:GetAwardReq(oPlayer)
	if self:GetState() ~= CQMDHB.tState.eAward then
		return oPlayer:Tips("未到领奖时间")
	end

	local nCharID = oPlayer:GetCharID()
	local nMyRank = self:MyRank(oPlayer)

	local tConf = ctDQHBEtcConf[1]
	if nMyRank > tConf.nQMDAwardRanking or nMyRank == 0 then 
		return oPlayer:Tips("未上榜")                                 --不在领奖排名中 
	end
	if self.m_tAwardState[nCharID] == CQMDHB.tAwardState.eClose then
		return oPlayer:Tips("已领取过")
	end

	self.m_tAwardState[nCharID] = CQMDHB.tAwardState.eClose                --已领取
	self:MarkDirty(true)

	local tList = {}
	local tAward = self:GetRankAward(nMyRank)
	for _, tItem in ipairs(tAward) do 
		oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "亲密度冲榜奖励")
		table.insert(tList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
	end
	self:MarkDirty(true)
	
	local tMsg = {tList=tList, nAwardState=self.m_tAwardState[nCharID]}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "HBGetAwardRet", tMsg)
	self:CheckRedPoint(nCharID)
end

--是否能领奖
function CQMDHB:CanGetAward(oPlayer)
	if self:GetState() ~= CGLHB.tState.eAward then
		return false
	end
	if self:CheckAwardState(oPlayer) == CQMDHB.tAwardState.eFeed then
		return true 
	end
	return false
end

--玩家上线
function CQMDHB:Online(oPlayer)
	goHBMgr:Online(oPlayer)
end

--进入初始状态
function CQMDHB:OnStateInit()
	print("活动:", self.m_nID, "进入初始状态")
	goHBMgr:OnStateInit()
end

--进入活动状态
function CQMDHB:OnStateStart()
	print("活动:", self.m_nID, "进入开始状态")
	self:Init()
	goOfflineDataMgr.m_oGSGData:SetFirst(self.m_nID)
	goBroadcast:SetBroadcast(43, 1, self.m_tRanking[1], true)

	local function _fnTraverse(nRank, nCharID, tData)                     
		local tRank = {nCharID=nCharID,sName=goOfflineDataMgr:GetName(nCharID), nValue=tData[2]}
		self.m_tInitQM[nCharID] = tRank                                   --保存初始表
	end
	local nRankNum = goRankingMgr.m_oQMRanking.m_oRanking:GetCount()      --获取所有排名
	goRankingMgr.m_oQMRanking.m_oRanking:Traverse(1, nRankNum, _fnTraverse)
	self:MarkDirty(true)
	goHBMgr:OnStateStart()
end

--进入领奖状态
function CQMDHB:OnStateAward()
	print("活动:", self.m_nID, "进入奖励状态")
	self:QMDRankingDeal(true)    
	goHBMgr:OnStateAward()
	goOfflineDataMgr.m_oGSGData:SetFirst(self.m_nID, self.m_tRanking[1], os.time())
end

--进入关闭状态
function CQMDHB:OnStateClose()
	print("活动:", self.m_nID, "进入关闭状态")
	goHBMgr:OnStateClose()
	self:CheckAward()
end

--检测未领奖的玩家,然后发奖
function CQMDHB:CheckAward()
	local tConf = ctDQHBEtcConf[1]
	for k = 1, tConf.nQMDAwardRanking do
		local nCharID = self.m_tRanking[k]
		if nCharID then
			if self.m_tAwardState[nCharID] ~= CQMDHB.tAwardState.eClose then
				local tList = self:GetRankAward(k)
				goMailMgr:SendMail("系统邮件", "亲密度冲榜奖励", "您在亲密度冲榜活动中获得第"..k.."名，获得了以下奖励，请查收。", tList, nCharID)
			end
		end
	end
end

--检测小红点
function CQMDHB:CheckRedPoint(nCharID)
	local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
	if not oPlayer then
		return
	end
	goHBMgr:SyncState(oPlayer)
end