--祈福活动
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--预处理活动使用道具奖励表
local function PreProcessConf()
	for nID, tConf in pairs(ctQFPropConf) do 
		local nTotalW, nPreW = 0, 0
		for _, tAward in ipairs(tConf.tAward) do 
			tAward.nMinW = nPreW + 1
			tAward.nMaxW = tAward.nMinW + tAward[1] - 1
			nPreW = tAward.nMaxW
			nTotalW = nTotalW + tAward[1]
		end
		tConf.nTotalW = nTotalW
	end
end
PreProcessConf()

local nRankingUpdataTime = 3600 		--排行榜1小时更新一次
local nMaxRankingNum = 200 				--最大查看目录200条
local nMaxRecord = 3 					--奖励记录最多3条

function CQiFu:Ctor(nID)
	CHDBase.Ctor(self, nID)
	self:Init()
end

function CQiFu:Init()
	self.m_nServerScore = 0				--全服吉运
	self.m_nSubState = CHDBase.tState.eClose --活动子状态

	self.m_tExChangeMap = {} 			--兑换物品{[charid]={[propid]=num,...}
	self.m_tBuyPropMap = {} 			--购买道具{[charid]={[propid]=num,...}

	self.m_tPlayerScoreMap = {}			--个人吉运{[charid]=score,...}
	self.m_tPlayerUseScoreMap = {}		--个人兑换奖励的吉运{[charid]=score,...}
	self.m_tUnionScoreMap = {}			--所有联盟吉运{[unionid]=score,...}

	self.m_tScoreAwardMap = {} 			--今日吉运全服奖励{[charid]=state,...}
	self.m_tPlayerRankAwardMap = {} 	--个人排名奖励状态{[charid]=state}
	self.m_tUnionRankAwardMap = {}	 	--联盟排名奖励状态{[unionid]={[charid]=state,...}}
	self.m_tQFRecordList = {} 			--玩家祈福奖励记录

	--不保存
	self.m_tPlayerRanking = {}			--个人排行榜
	self.m_tUnionRanking = {}			--联盟排行榜
	self.m_nLastRankingTime = 0			--上次排行时间
	self.m_tTmpUnionScoreMap = {} 	--联盟排行榜临时吉运映射
	self.m_tTmpPlayerScoreMap = {} 	--玩家排行榜临时吉运映射
end

function CQiFu:LoadData()
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sHuoDongDB, self:GetID())
	if sData == "" then return end

	local tData = cjson.decode(sData)
	CHDBase.LoadData(self, tData) 

	self.m_nSubState = tData.m_nSubState
	self.m_nServerScore = tData.m_nServerScore

	--个人吉运
	self.m_tPlayerScoreMap = tData.m_tPlayerScoreMap
	--个人使用吉运
	self.m_tPlayerUseScoreMap = tData.m_tPlayerUseScoreMap
	--联盟吉运
	self.m_tUnionScoreMap = tData.m_tUnionScoreMap

	--购买物品
	self.m_tBuyPropMap = tData.m_tBuyPropMap
	self.m_tExChangeMap = tData.m_tExChangeMap
	--全服吉运奖励状态
	self.m_tScoreAwardMap = tData.m_tScoreAwardMap
	--个人排名吉运奖励状态
	self.m_tPlayerRankAwardMap = tData.m_tPlayerRankAwardMap
	--联盟排名吉运奖励状态
	self.m_tUnionRankAwardMap = tData.m_tUnionRankAwardMap
	--祈福奖励记录
	self.m_tQFRecordList = tData.m_tQFRecordList
end

function CQiFu:SaveData()
	if not self:IsDirty() then return end
	self:MarkDirty(false)

	local tData = CHDBase.SaveData(self)
	tData.m_tQFRecordList = self.m_tQFRecordList
	tData.m_nSubState = self.m_nSubState
	tData.m_nServerScore = self.m_nServerScore
	tData.m_tPlayerScoreMap = self.m_tPlayerScoreMap
	tData.m_tPlayerUseScoreMap = self.m_tPlayerUseScoreMap
	tData.m_tUnionScoreMap = self.m_tUnionScoreMap
	tData.m_tBuyPropMap = self.m_tBuyPropMap
	tData.m_tExChangeMap = self.m_tExChangeMap
	tData.m_tScoreAwardMap = self.m_tScoreAwardMap
	tData.m_tPlayerRankAwardMap = self.m_tPlayerRankAwardMap
	tData.m_tUnionRankAwardMap = self.m_tUnionRankAwardMap
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sHuoDongDB, self:GetID(), cjson.encode(tData))
end

--玩家上线
function CQiFu:Online(oPlayer)
	self:SyncState(oPlayer)
end

--活动状态更新
function CQiFu:UpdateState()
	CHDBase.UpdateState(self)
	self:UpdateSubState()
end

--进入初始状态
function CQiFu:OnStateInit()
	print("祈福进入初始状态")
	self:SyncState()
end

--进入开始状态
function CQiFu:OnStateStart()
	print("祈福进入开始状态")
	self:Init()
	self:SyncState()
	self:MarkDirty(true)
end

--进入领奖状态
function CQiFu:OnStateAward()
	print("祈福进入领奖状态")
	self:UpdateRanking(true)
	self:SyncState()
end

--进入关闭状态
function CQiFu:OnStateClose()
	print("祈福进入关闭状态")
	self:SyncState()
end

--子状态开始、结束时间
function CQiFu:GetSubTime()
	local nNow = os.time()
	local tTime = ctQFEtcConf[1].tDayTime[1]
	local tDate = os.date("*t", os.time())
	local nBeginTime = os.MakeTime(tDate.year, tDate.month, tDate.day, tTime[1], 0, 0)
	local nEndTime = os.MakeTime(tDate.year, tDate.month, tDate.day, tTime[2], 0, 0)
	return nBeginTime, nEndTime
end

--更新子状态
function CQiFu:UpdateSubState()
	if not self:IsOpen() then 
		if self.m_nSubState ~= CHDBase.tState.eClose then 
			self.m_nSubState = CHDBase.tState.eClose
			self:MarkDirty(true)
			self:OnSubStateClose()
		end
		return 
	end 

	local nNow = os.time()
	local nBeginTime, nEndTime = self:GetSubTime()
	if nBeginTime <= nNow and nNow < nEndTime then 
		if self.m_nSubState ~= CHDBase.tState.eStart then 
			self.m_nSubState = CHDBase.tState.eStart
			self:MarkDirty(true)
			self:OnSubStateStart()
		end

	elseif self.m_nSubState ~= CHDBase.tState.eInit then 
		self.m_nSubState = CHDBase.tState.eInit
		self:MarkDirty(true)
		self:OnSubStateInit()
	end
end

--活动子状态即将开始
function CQiFu:OnSubStateInit()
	print("祈福进入初始子状态")
	self:UpdateRanking(true)
	self.m_nServerScore = 0 --全服财宝重置
	self:MarkDirty(true)
	self:SyncState()
end

--活动子状态开始
function CQiFu:OnSubStateStart()
	print("祈福进入开始子状态")
	self.m_tBuyPropMap = {}
	self.m_nServerScore = 0 
	self:MarkDirty(true)
	self:SyncState()
end

--活动子状态关闭
function CQiFu:OnSubStateClose()
	print("活动进入关闭子状态")
	self:UpdateRanking(true)
	self.m_nServerScore = 0 --全服财宝重置
	self:MarkDirty(true)
	self:SyncState()
end

--取活动子状态(日开放时间状态)
function CQiFu:GetSubState()
	local nNowSec = os.time()
	local nBeginTime, nEndTime = self:GetSubTime()
	if self.m_nSubState == CHDBase.tState.eInit then 
		local nNextTime = nNowSec < nBeginTime and (nBeginTime - nNowSec) or (nBeginTime + 24*3600 - nNowSec)
		assert(nNextTime > 0)
		return self.m_nSubState, nNextTime

	elseif self.m_nSubState == CHDBase.tState.eStart then
		return self.m_nSubState, nEndTime-nNowSec

	elseif self.m_nSubState == CHDBase.tState.eClose then 
		return self.m_nSubState, 0
	
	else 
		assert(false, "状态非法")
	end
end

--活动信息状态
function CQiFu:SyncState(oPlayer)
	local nState = self:GetState()
	local nStateTime = self:GetStateTime()
	local nBeginTime, nEndTime, nAwardTime = self:GetActTime()
	local nSubState, nSubStateTime = self:GetSubState()
	local bPlayerAward, bUnionAward, bActAward = false, false, false
	local nID = self:GetID()
	if oPlayer then
		bPlayerAward, bUnionAward, bActAward = self:CanGetAward(oPlayer)
	end 
	local tMsg ={
		nID = nID,
		nState = nState,
		nStateTime = nStateTime,
		nBeginTime = nBeginTime,
		nEndTime = nEndTime,
		nAwardTime = nAwardTime,
		nSubState = nSubState,
		nSubStateTime = nSubStateTime,
		nServerScore = self.m_nServerScore,
		bPlayerAward = bPlayerAward,
		bUnionAward = bUnionAward,
		bActAward = bActAward,
		nOpenTimes = self:GetOpenTimes(),
		tRecord = self.m_tQFRecordList,
	}
	--同步给指定玩家
	if oPlayer then
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "QiFuStateRet", tMsg)

	--全服广播
	else
		CmdNet.PBSrv2All("QiFuStateRet", tMsg) 
	end
end

--取购买道具次数
function CQiFu:GetBuyPropTimes(nCharID, nPropID)
	local tBuyMap = self.m_tBuyPropMap[nCharID] or {}
	local nTimes = tBuyMap[nPropID] or 0
	return nTimes  
end

--增加购买道具次数
function CQiFu:AddBuyPropTimes(nCharID, nPropID)
	local tBuyMap = self.m_tBuyPropMap[nCharID] or {}
	tBuyMap[nPropID] = (tBuyMap[nPropID] or 0) + 1
	self.m_tBuyPropMap[nCharID] = tBuyMap
	self:MarkDirty(true)
end

--道具列表请求
function CQiFu:PropListReq(oPlayer)
	local nStartState = CHDBase.tState.eStart
	if self.m_nState ~= nStartState or self.m_nSubState ~= nStartState then
		return oPlayer:Tips("活动已结束") 
	end

	local tList ={}
	local nCharID = oPlayer:GetCharID()
	for nPropID, tConf in pairs(ctQFPropConf) do 
		local tTemp = {nPropID=nPropID, nBuyTimes=self:GetBuyPropTimes(nCharID, nPropID)}
		table.insert(tList, tTemp)
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "QiFuPropListRet", {tList=tList})
end

--购买道具请求
function CQiFu:BuyPropReq(oPlayer, nPropID)
	local nStartState = CHDBase.tState.eStart
	if self.m_nState ~= nStartState or self.m_nSubState ~= nStartState then
		return oPlayer:Tips("活动已结束") 
	end

	local tConf = assert(ctQFPropConf[nPropID])
	local nCharID = oPlayer:GetCharID()
	local nTimes = self:GetBuyPropTimes(nCharID, nPropID)
	if nTimes >= tConf.nLimit then 
		return oPlayer:Tips("已达到购买上限")
	end 

	if tConf.nForward > 0 then 
		return oPlayer:Tips("该物品不是可购买类型")
	end
	
	local tPrice = tConf.tPrice[1]
	local nCurrNum = oPlayer:GetItemCount(tPrice[1], tPrice[2])
	if nCurrNum < tPrice[3] then 
		return oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(tPrice[2])))
	end
	oPlayer:SubItem(tPrice[1], tPrice[2], tPrice[3], "祈福活动购买道具")
	oPlayer:AddItem(gtItemType.eProp, tConf.nPropID, 1, "祈福活动购买道具")
	self:AddBuyPropTimes(nCharID, nPropID)

	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "QiFuBuyPropRet", {nPropID=nPropID})
	self:PropListReq(oPlayer)
end

--添加奖励记录
function CQiFu:AddRecord(sRecord)
	table.insert(self.m_tQFRecordList, 1, sRecord)
	if #self.m_tQFRecordList > nMaxRecord then 
		table.remove(self.m_tQFRecordList)
	end 
	self:MarkDirty(true)
end

--使用道具请求
function CQiFu:UsePropReq(oPlayer, nPropID)
	local nStartState = CHDBase.tState.eStart
	if self.m_nState ~= nStartState or self.m_nSubState ~= nStartState then
		return oPlayer:Tips("活动已结束")
	end

	local tConf = assert(ctQFPropConf[nPropID], "道具不存在")
	local nCurrNum = oPlayer:GetItemCount(gtItemType.eProp, nPropID)
	if nCurrNum <= 0 then 
		return oPlayer:Tips("道具不足")
	end
	oPlayer:SubItem(gtItemType.eProp, nPropID, 1, "祈福活动使用道具")
	local nCharID = oPlayer:GetCharID()

	--全服吉运
	self.m_nServerScore = self.m_nServerScore + tConf.nScore 			

	--个人吉运
	self.m_tPlayerScoreMap[nCharID] = (self.m_tPlayerScoreMap[nCharID] or 0) + tConf.nScore 

	--联盟吉运
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if oUnion then 
		local nUnionID = oUnion:GetID()
		self.m_tUnionScoreMap[nUnionID] = (self.m_tUnionScoreMap[nUnionID] or 0) + tConf.nScore  
	end
	self:MarkDirty(true)

	local tMsg = {nScore=tConf.nScore, nServerScore=self.m_nServerScore, tList={}}
	local nRnd = math.random(1, tConf.nTotalW)
	for _, tAward in pairs(tConf.tAward) do 
		if nRnd >= tAward.nMinW and nRnd <= tAward.nMaxW then 
			oPlayer:AddItem(tAward[2], tAward[3], tAward[4], "祈福活动使用道具")
			table.insert(tMsg.tList, {nType=tAward[2], nID=tAward[3], nNum=tAward[4]})
		end
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "QiFuUsePropRet", tMsg)

	--添加奖励记录
	local tItem = tMsg.tList[1]
	local sCont = CGuoKu:PropName(tItem.nID).."x"..tItem.nNum
	local sRecord = string.format(ctLang[32], oPlayer:GetName(), sCont)
	self:AddRecord(sRecord)

	--小红点
	self:CheckRedPoint(nCharID)
end

--全服吉运奖励信息请求
function CQiFu:ServerAwardReq(oPlayer)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oPlayer:Tips("活动已结束")
	end
	
	local nCharID = oPlayer:GetCharID()
	local nState = self.m_tScoreAwardMap[nCharID]		
	if not nState then
		nState = self.m_nServerScore >= ctQFEtcConf[1].nScore and 1 or 0
	end 
	local tMsg = {nScore=self.m_nServerScore, nState=nState}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "QiFuServerAwardRet", tMsg)
end

--领取全服吉运奖励请求
function CQiFu:GetServerAwardReq(oPlayer)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oPlayer:Tips("活动已结束")
	end

	local tConf = ctQFEtcConf[1]
	local nCharID = oPlayer:GetCharID()
	local nState = self.m_tScoreAwardMap[nCharID]
	if (nState or 0) == 2 then 
		return oPlayer:Tips("已领取过奖励")
	end
	if self.m_nServerScore < tConf.nScore then 
		return oPlayer:Tips("未达到领奖条件")
	end

	self.m_tScoreAwardMap[nCharID] = 2
	local tAward = tConf.tAward[1]
	oPlayer:AddItem(tAward[1], tAward[2], tAward[3], "祈福活动奖励")
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "QiFuGetServerAwardRet", {nID=tAward[2], nNum=tAward[3]})
	self:MarkDirty(true)
	self:ServerAwardReq(oPlayer)
	--小红点
	self:CheckRedPoint(nCharID)
end

--兑换列表请求
function CQiFu:ExChangeListReq(oPlayer)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oPlayer:Tips("活动已结束")
	end

	local nCharID = oPlayer:GetCharID()
	local tExChangeList = self.m_tExChangeMap[nCharID] or {}
	local nCurrScore = self.m_tPlayerScoreMap[nCharID] or 0
	local nUseScore = self.m_tPlayerUseScoreMap[nCharID] or 0 
	local tMsg = {tList={}, nScore=nCurrScore-nUseScore}
	for nPropID, tConf in pairs(ctQFExchangeConf) do 
		local tTemp = {nPropID=nPropID, nExcNum=tExChangeList[nPropID] or 0}
		table.insert(tMsg.tList, tTemp)
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "QiFuExChangeListRet", tMsg)
end

--兑换物品
function CQiFu:ExChangeItemReq(oPlayer, nPropID)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oPlayer:Tips("活动已结束")
	end

	local tConf = assert(ctWBExchangeConf[nPropID], "道具不存在")
	local nCharID = oPlayer:GetCharID()
	local tExChangeList = self.m_tExChangeMap[nCharID] or {}
	local nCurrScore = self.m_tPlayerScoreMap[nCharID] or 0
	local nUseScore = self.m_tPlayerUseScoreMap[nCharID] or 0 
	if nUseScore+tConf.nScore > nCurrScore then 
		return oPlayer:Tips("吉运不足")
	end

	if (tExChangeList[nPropID] or 0) >= tConf.nLimit then 
		return oPlayer:Tips("物品已售罄")
	end

	--个人兑换次数
	tExChangeList[nPropID] = (tExChangeList[nPropID] or 0) + 1
	self.m_tExChangeMap[nCharID] = tExChangeList

	--个人使用吉运
	self.m_tPlayerUseScoreMap[nCharID] = nUseScore + tConf.nScore
	oPlayer:AddItem(gtItemType.eProp, nPropID, 1, "祈福兑换物品")
	self:MarkDirty(true)

	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "QiFuExChangeItemRet", {nID=nPropID, nNum=1})
	self:ExChangeListReq(oPlayer)
end

--更新排行榜
function CQiFu:UpdateRanking(bEnd)
	if os.time() - self.m_nLastRankingTime < nRankingUpdataTime and not bEnd then 
		return 
	end
	self.m_nLastRankingTime = os.time()
	self.m_tPlayerRanking = {}
	self.m_tUnionRanking = {}
	self.m_tTmpPlayerScoreMap = {}
	self.m_tTmpUnionScoreMap = {}

	--个人排名更新
	for nCharID, nScore in pairs(self.m_tPlayerScoreMap) do 
		table.insert(self.m_tPlayerRanking, {nCharID, nScore})
		self.m_tTmpPlayerScoreMap[nCharID] = nScore
	end
	table.sort(self.m_tPlayerRanking, function(t1, t2) 
		if t1[2] == t2[2] then 
			return t1[1] < t2[1]
		end
		return t1[2] > t2[2]
	end)

	--联盟排名更新
	for nUnionID, nScore in pairs(self.m_tUnionScoreMap) do 
		table.insert(self.m_tUnionRanking, {nUnionID, nScore})
		self.m_tTmpUnionScoreMap[nUnionID] = nScore
	end
	table.sort(self.m_tUnionRanking, function(t1, t2) 
		if t1[2] == t2[2] then 
			return t1[1] < t2[1]
		end
		return t1[2] > t2[2]
	end)
end

--取个人排名
function CQiFu:GetPlayerRank(nCharID)
	local nRank, nValue = 0, 0
	if not self.m_tPlayerScoreMap[nCharID] then 
		return nRank, nValue
	end
	local function fnCmp(t1, t2)
		if t1[2] == t2[2] then
			if t1[1] == t2[1] then 
				return 0
			end
			if t1[1] > t2[1] then 
				return 1
			else
				return -1
			end

		else
			if t1[2] > t2[2] then 
				return -1
			else
				return 1
			end
		end
	end
	if self.m_tTmpPlayerScoreMap[nCharID] then 
		local tTmpVal = {nCharID, self.m_tTmpPlayerScoreMap[nCharID]}
		nRank = CAlg:BinarySearch(self.m_tPlayerRanking, fnCmp, tTmpVal)
	end
	return nRank, self.m_tPlayerScoreMap[nCharID]
end

--取联盟排名
function CQiFu:GetUnionRank(nCharID)
	local nRank, sName, nValue = 0, "", 0
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then
		return nRank, sName, nValue
	end
	local nUnionID = oUnion:GetID()
	sName = oUnion:GetName()
	if not self.m_tUnionScoreMap[nUnionID] then
		return nRank, sName, nValue
	end
	local function fnCmp(t1, t2)
		if t1[2] == t2[2] then
			if t1[1] == t2[1] then 
				return 0
			end
			if t1[1] > t2[1] then 
				return 1
			else
				return -1
			end

		else
			if t1[2] > t2[2] then 
				return -1
			else
				return 1
			end
		end
	end
	if self.m_tTmpUnionScoreMap[nUnionID] then 
		local tTmpVal = {nUnionID, self.m_tTmpUnionScoreMap[nUnionID]}
		nRank = CAlg:BinarySearch(self.m_tUnionRanking, fnCmp, tTmpVal)
		nValue = self.m_tTmpUnionScoreMap[nUnionID]
	end
	return nRank, sName, nValue
end

--个人排行榜请求
function CQiFu:PlayerRankingReq(oPlayer, nRankNum) 
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oPlayer:Tips("活动已结束")
	end

	self:UpdateRanking()
	local nCharID = oPlayer:GetCharID()
	local nRankNum = math.max(1, math.min(nRankNum, nMaxRankingNum))
	local nMyRank, nMyValue = self:GetPlayerRank(nCharID)
	local tMsg = {nType=1, nMyRank=nMyRank, sMyName="", nMyValue=nMyValue, tList={}}
	for k=1, nRankNum do 
		local tRank = self.m_tPlayerRanking[k]
		if tRank then 
			local tInfo = {nRank=k, sName=goOfflineDataMgr:GetName(tRank[1]), nValue=tRank[2]}
			table.insert(tMsg.tList, tInfo)
		end
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "QiFuRankingRet", tMsg)
end

--联盟排行榜请求
function CQiFu:UnionRankingReq(oPlayer, nRankNum) 
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oPlayer:Tips("活动已结束")
	end

	self:UpdateRanking()
	local nCharID = oPlayer:GetCharID()
	local nRankNum = math.max(1, math.min(nRankNum, nMaxRankingNum))
	local nMyRank, sMyName, nMyValue = self:GetUnionRank(nCharID)
	local tMsg = {nType=2, nMyRank=nMyRank, sMyName=sMyName, nMyValue=nMyValue, tList={}}
	for k=1, nRankNum do 
		local tRank = self.m_tUnionRanking[k]
		if tRank then
			local oUnion = goUnionMgr:GetUnion(tRank[1])
			if oUnion then  
				local tInfo = {nRank=k, sName=oUnion:GetName(), nValue=tRank[2]}
				table.insert(tMsg.tList, tInfo)
			end
		end
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "QiFuRankingRet", tMsg)
end

--取玩家奖励状态
function CQiFu:GetPlayerAwardState(nCharID)
	if self.m_nState ~= CHDBase.tState.eAward then
		return 0 --状态不对不可领奖
	end
	local nAwardState = self.m_tPlayerRankAwardMap[nCharID]
	if nAwardState then
		return 2 --已领取过领奖
	end
	local nMyRank, nMyValue = self:GetPlayerRank(nCharID)
	if nMyRank == 0 or nMyRank > ctQFPLRankingConf[#ctQFPLRankingConf].tRank[1][2] then
		return 0 --未上榜不能领取
	end
	return 1 --可领取
end

--取联盟奖励状态
function CQiFu:GetUnionAwardState(nCharID)
	if self.m_nState ~= CHDBase.tState.eAward then
		return 0 --状态不对不可领奖
	end
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then
		return 0 --没有联盟不可领奖
	end
	local nUnionID = oUnion:GetID()
	local tUnionAward = self.m_tUnionRankAwardMap[nUnionID] or {}
	local nAwardState = tUnionAward[nCharID]
	if nAwardState then 
		return 2 --已领取过领奖
	end
	local nMyRank, sMyName, nMyValue = self:GetUnionRank(nCharID)
	if nMyRank == 0 or nMyRank > ctQFUNRankingConf[#ctQFUNRankingConf].tRank[1][2] then 
		return 0 --未上榜不能领取
	end
	return 1 --可领取
end

--个人排行榜奖励状态请求
function CQiFu:PlayerRankingAwardStateReq(oPlayer)
	if self.m_nState == CHDBase.tState.eInit or self.m_nState == CHDBase.tState.eClose then 
		return oPlayer:Tips("活动已结束")
	end 

	local nCharID = oPlayer:GetCharID()
	local nMyRank, nMyValue = self:GetPlayerRank(nCharID)
	local nAwardState = self:GetPlayerAwardState(nCharID)
	local tMsg = {nType=1, nState=self:GetState(), nStateTime=self:GetStateTime()
		, nMyRank=nMyRank, sMyName="", nMyValue=nMyValue, nAwardState=nAwardState}	
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "QiFuRankingAwardStateRet", tMsg)
end
 
--联盟排行榜奖励状态请求
function CQiFu:UnionRankingAwardStateReq(oPlayer)
	if self.m_nState == CHDBase.tState.eInit or self.m_nState == CHDBase.tState.eClose then 
		return oPlayer:Tips("活动已结束")
	end

	local nCharID = oPlayer:GetCharID()
	local nMyRank, sMyName, nMyValue = self:GetUnionRank(nCharID)
	local nAwardState = self:GetUnionAwardState(nCharID)
	local tMsg = {nType=2, nState=self:GetState(), nStateTime=self:GetStateTime()
		, nMyRank=nMyRank, sMyName=sMyName, nMyValue=nMyValue, nAwardState=nAwardState}	
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "QiFuRankingAwardStateRet", tMsg)
end

--个人排行榜奖励领取
function CQiFu:GetPlayerRankAwardReq(oPlayer)
	if self.m_nState ~= CHDBase.tState.eAward then
		return oPlayer:Tips("未到领奖时间") 
	end
	
	local nCharID = oPlayer:GetCharID()
	local nAwardState = self:GetPlayerAwardState(nCharID)
	if nAwardState == 2 then 
		return oPlayer:Tips("已领过奖励")
	end
	if nAwardState == 0 then 
		return oPlayer:Tips("未达到领奖条件")
	end

	local tList = {}
	local nMyRank = self:GetPlayerRank(nCharID)
	for k = #ctQFPLRankingConf, 1, -1 do 	
		local tConf = ctQFPLRankingConf[k]
		local tRank = tConf.tRank[1]
		if nMyRank >= tRank[1] then 
			if self:GetOpenTimes() > 1 then  --普通开启
				for _, tAward in pairs(tConf.tAward1) do 
					oPlayer:AddItem(tAward[1], tAward[2], tAward[3], "个人祈福吉运排名奖励")
					table.insert(tList, {nType=tAward[1], nID=tAward[2], nNum=tAward[3]})
				end
			else 							--首次开启
				for _, tAward in pairs(tConf.tAward) do 
					oPlayer:AddItem(tAward[1], tAward[2], tAward[3], "个人祈福吉运排名奖励")
					table.insert(tList, {nType=tAward[1], nID=tAward[2], nNum=tAward[3]})
				end
			end
			break
		end
	end

	self.m_tPlayerRankAwardMap[nCharID] = 2
	self:MarkDirty(true)
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "QiFuGetRankAwardRet", {nType=1, tList=tList})
	self:PlayerRankingAwardStateReq(oPlayer)
	--小红点
	self:CheckRedPoint(nCharID)
end

--联盟排行榜奖励领取
function CQiFu:GetUnionRankAwardReq(oPlayer)
	if self.m_nState ~= CHDBase.tState.eAward then
		return oPlayer:Tips("未到领奖时间") 
	end
	
	local nCharID = oPlayer:GetCharID()
	local nAwardState = self:GetUnionAwardState(nCharID)
	if nAwardState == 2 then 
		return oPlayer:Tips("已领过奖励")
	end
	if nAwardState == 0 then 
		return oPlayer:Tips("未达到领奖条件")
	end

	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	local nUnionID = oUnion:GetID()
	local nPos = oUnion:GetPos(nCharID) 

	local tList = {}
	local nMyRank = self:GetUnionRank(nCharID)
	for k = #ctQFUNRankingConf, 1, -1 do 	
		local tConf = ctQFUNRankingConf[k]
		local tRank = tConf.tRank[1]
		if nMyRank >= tRank[1] then 
			if self:GetOpenTimes() > 1 then --普通开启
				local tAward = tConf["tAward1"..nPos]
				for _, tItem in pairs(tAward) do 
					oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "个人祈福吉运排名奖励")
					table.insert(tList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
				end
			else 							--首次开启
				local tAward = tConf["tAward"..nPos]
				for _, tItem in pairs(tAward) do 
					oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "个人祈福吉运排名奖励")
					table.insert(tList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
				end
			end
			break
		end
	end

	local tUnionAward = self.m_tUnionRankAwardMap[nUnionID] or {}
	tUnionAward[nCharID] = 2
	self.m_tUnionRankAwardMap[nUnionID] = tUnionAward
	self:MarkDirty(true)
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "QiFuGetRankAwardRet", {nType=2, tList=tList})
	self:UnionRankingAwardStateReq(oPlayer)
	--小红点
	self:CheckRedPoint(nCharID)
end

--是否可以领取奖励
function CQiFu:CanGetAward(oPlayer)
	local nCharID = oPlayer:GetCharID()
	local nPlayerAward = self:GetPlayerAwardState(nCharID)
	local nUnionAward = self:GetUnionAwardState(nCharID)

	local nAwardState = self.m_tScoreAwardMap[nCharID]
	if not nAwardState then
		nAwardState = self.m_nServerScore >= ctQFEtcConf[1].nScore and 1 or 0
	end
	return (nPlayerAward==1), (nUnionAward==1), (nAwardState==1)
end

--小红点
function CQiFu:CheckRedPoint(nCharID)
	local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
	if not oPlayer then
		return
	end
	self:SyncState(oPlayer)
end