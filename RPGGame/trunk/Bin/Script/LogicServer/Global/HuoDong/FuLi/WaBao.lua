--挖宝福利小活动
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--预处理活动道具表
local function _PreProcessConf()
	for nID, tConf in pairs(ctWBPropConf) do
		local nTotalW, nPreW = 0, 0
		for _, tAward in ipairs(tConf.tAward) do
			tAward.nMinW = nPreW + 1
			tAward.nMaxW = tAward.nMinW + tAward[1] - 1
			nTotalW = nTotalW + tAward[1]
			nPreW = tAward.nMaxW
		end
		tConf.nTotalW = nTotalW
	end
end
_PreProcessConf()

local nMaxRankingNum = 200 			--最大200条记录返回
local nRankingUpdateTime = 3600 	--排行榜1小时更新一次
local nMaxWBRecordNum = 3 			--记录挖宝奖励数量

function CWaBao:Ctor(nID)
	CHDBase.Ctor(self, nID)     	--继承基类
	self:Init()
end

function CWaBao:Init()
	self.m_nServerScore = 0 					--今日全服财宝
	self.m_nSubState = CHDBase.tState.eClose 	--活动子状态
	self.m_tPlayerScoreMap = {}					--个人财宝映射:{[charid]=score, ...}
	self.m_tPlayerUseScoreMap = {}				--个人已使用财宝映射:{[charid]=score, ...}
	self.m_tUnionScoreMap = {} 					--联盟财宝映射:{[unionid]=score, ...}
	self.m_tExchangeMap = {} 					--兑换道具映射:{[charid]={[propid]=num, ...}, ...}

	self.m_tBuyPropMap = {} 					--购买道具映射:{[charid]={[propid]=num, ...}
	self.m_tScoreAwardMap = {} 					--全服财宝奖励映射:{[charid]=1, ...}
	self.m_tPlayerRankAwardMap = {} 			--玩家排行榜领奖状态{[charid]=state, ...}
	self.m_tUnionRankAwardMap = {} 				--联盟排行榜领奖状态{[unionid]={[charid]=state,...},...}
	self.m_tWBRecordList = {} 					--玩家挖宝奖励记录

	--不保存
	self.m_tUnionRanking = {} 		--联盟排行
	self.m_tPlayerRanking = {} 		--个人排行
	self.m_nLastRankTime = 0 		--上次排行时间
	self.m_tTmpUnionScoreMap = {} 	--联盟排行榜临时财宝映射
	self.m_tTmpPlayerScoreMap = {} 	--玩家排行榜临时财宝映射
end

function CWaBao:LoadData()
	print("加载挖宝活动数据")
	local oSSDB = goDBMgr:GetSSDB("Player")  
	local sData = oSSDB:HGet(gtDBDef.sHuoDongDB, self:GetID())
	if sData == "" then return end

	local tData = cjson.decode(sData)
	CHDBase.LoadData(self, tData)
	
	self.m_nSubState = tData.m_nSubState
	self.m_nServerScore = tData.m_nServerScore
	--个人财宝
	self.m_tPlayerScoreMap = tData.m_tPlayerScoreMap
	--个人已使用财宝
	self.m_tPlayerUseScoreMap = tData.m_tPlayerUseScoreMap
	--联盟财宝
	self.m_tUnionScoreMap = tData.m_tUnionScoreMap
	--兑换道具
	self.m_tExchangeMap = tData.m_tExchangeMap
	--购买道具
	self.m_tBuyPropMap = tData.m_tBuyPropMap
	--全服奖励
	self.m_tScoreAwardMap = tData.m_tScoreAwardMap
	--个人排行奖励
	self.m_tPlayerRankAwardMap = tData.m_tPlayerRankAwardMap
	--联盟排行榜领奖状态
	self.m_tUnionRankAwardMap = tData.m_tUnionRankAwardMap
	--玩家挖宝奖励记录
	self.m_tWBRecordList = tData.m_tWBRecordList or {}
end

function CWaBao:SaveData()
	if not self:IsDirty() then return end
	self:MarkDirty(false)

	local tData = CHDBase.SaveData(self)
	tData.m_nSubState = self.m_nSubState 
	tData.m_nServerScore = self.m_nServerScore
	tData.m_tPlayerScoreMap = self.m_tPlayerScoreMap
	tData.m_tPlayerUseScoreMap = self.m_tPlayerUseScoreMap
	tData.m_tUnionScoreMap = self.m_tUnionScoreMap
	tData.m_tExchangeMap = self.m_tExchangeMap

	tData.m_tBuyPropMap = self.m_tBuyPropMap
	tData.m_tScoreAwardMap = self.m_tScoreAwardMap
	tData.m_tPlayerRankAwardMap = self.m_tPlayerRankAwardMap
	tData.m_tUnionRankAwardMap  = self.m_tUnionRankAwardMap
	tData.m_tWBRecordList = self.m_tWBRecordList

	local oSSDB = goDBMgr:GetSSDB("Player")
	oSSDB:HSet(gtDBDef.sHuoDongDB, self:GetID(), cjson.encode(tData))
end

--玩家上线
function CWaBao:Online(oPlayer)
	self:SyncState(oPlayer)
end

--更新状态
function CWaBao:UpdateState()
	CHDBase.UpdateState(self)
	self:UpdateSubState()
end

--进入初始状态
function CWaBao:OnStateInit()
	print("挖宝进入初始状态")
	self:SyncState()
end

--进入活动状态
function CWaBao:OnStateStart()
	print("挖宝进入开始状态")
	--初始化
	self:Init()
	self:SyncState()
	self:MarkDirty(true)
end

--进入领奖状态
function CWaBao:OnStateAward()
	print("挖宝进入领奖状态")
	self:UpdateRanking(true)
	self:SyncState()
end

--进入关闭状态
function CWaBao:OnStateClose()
	print("挖宝进入关闭状态")
	self:SyncState()
end

--子状态开始，结束时间
function CWaBao:GetSubTime()
	local nNow = os.time()
	local tTime = ctWBEtcConf[1].tDayTime[1]
	local tDate = os.date("*t", nNow)
	local nBeginTime = os.MakeTime(tDate.year, tDate.month, tDate.day, tTime[1], 0, 0)
	local nEndTime = os.MakeTime(tDate.year, tDate.month, tDate.day, tTime[2], 0, 0)
	return nBeginTime, nEndTime
end

--更新子状态
function CWaBao:UpdateSubState()
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
	if nNow >= nBeginTime and nNow < nEndTime then
		if self.m_nSubState ~= 	CHDBase.tState.eStart then
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
function CWaBao:OnSubStateInit()
	print("挖宝进入初始子状态")
	self:UpdateRanking(true)
	self.m_nServerScore = 0 --全服财宝重置
	self:MarkDirty(true)
	self:SyncState()
end

--活动子状态开始
function CWaBao:OnSubStateStart()
	print("挖宝进入开始子状态")
	self.m_tBuyPropMap = {}	--限购次数重置
	self.m_nServerScore = 0 --全服财宝重置
	self:MarkDirty(true)
	self:SyncState()
end

--活动子状态结束
function CWaBao:OnSubStateClose()
	print("挖宝进入关闭子状态")
	self:UpdateRanking(true)
	self.m_nServerScore = 0 --全服财宝重置
	self:MarkDirty(true)
	self:SyncState()
end

--取活动子状态(日开放时间状态)
function CWaBao:GetSubState()
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

--同步活动状态
function CWaBao:SyncState(oPlayer)
	local nState = self:GetState()
	local nSubState, nSubStateTime = self:GetSubState()
	local nStateTime = self:GetStateTime()
	local nBeginTime, nEndTime, nAwardTime = self:GetActTime()

	local tMsg = {
		nID = self:GetID(),
		nState = nState,
		nStateTime = nStateTime,
		nBeginTime = nBeginTime,
		nEndTime = nEndTime,
		nAwardTime = nAwardTime,
		nSubState = nSubState,
		nSubStateTime = nSubStateTime,
		nServerScore = self.m_nServerScore,
		tWBRecord = self:GetWBRecord(),
		nOpenTimes = self:GetOpenTimes(),
		bPlayerAward = false,
		bUnionAward = false,
		bActAward = false,
	}

	if oPlayer then
		local bPlayerAward, bUnionAward, bActAward = self:CanGetAward(oPlayer)
		tMsg.bPlayerAward = bPlayerAward
		tMsg.bUnionAward = bUnionAward
		tMsg.bActAward = bActAward
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "WaBaoStateRet", tMsg)
	else
		local tSessionMap = goPlayerMgr:GetSessionMap()
		for nSession, oTmpPlayer in pairs(tSessionMap) do
			local bPlayerAward, bUnionAward, bActAward = self:CanGetAward(oTmpPlayer)
			tMsg.bPlayerAward = bPlayerAward
			tMsg.bUnionAward = bUnionAward
			tMsg.bActAward = bActAward
			CmdNet.PBSrv2Clt(oTmpPlayer:GetSession(), "WaBaoStateRet", tMsg)
		end
	end
end

--取已购买道具次数
function CWaBao:GetPropBuyTimes(nCharID, nPropID)
	local tConf = assert(ctWBPropConf[nPropID])
	local tBuyMap = self.m_tBuyPropMap[nCharID] or {}
	local nBuyTimes = tBuyMap[nPropID] or 0
	return nBuyTimes
end

--增加道具购买次数
function CWaBao:AddPropBuyTimes(nCharID, nPropID)
	local tBuyMap = self.m_tBuyPropMap[nCharID] or {}
	tBuyMap[nPropID] = (tBuyMap[nPropID] or 0) + 1
	self.m_tBuyPropMap[nCharID] = tBuyMap
	self:MarkDirty(true)
end

--道具列表请求
function CWaBao:PropListReq(oPlayer)
	local nStartState = CHDBase.tState.eStart 
	if self.m_nState ~= nStartState or self.m_nSubState ~= nStartState then
		return oPlayer:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	local tList = {}
	local nCharID = oPlayer:GetCharID()
	for nPropID, tConf in pairs(ctWBPropConf) do
		local tItem = {nPropID=nPropID, nBuyTimes=self:GetPropBuyTimes(nCharID, nPropID)}
		table.insert(tList, tItem)
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "WaBaoPropListRet", {tList=tList})
end

--购买道具请求
function CWaBao:BuyPropReq(oPlayer, nPropID)
	local nStartState = CHDBase.tState.eStart 
	if self.m_nState ~= nStartState or self.m_nSubState ~= nStartState then
		return oPlayer:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	local nCharID = oPlayer:GetCharID()

	local tConf = assert(ctWBPropConf[nPropID])
	local nBuyTimes = self:GetPropBuyTimes(nCharID, nPropID)
	if tConf.nLimit > 0 and nBuyTimes >= tConf.nLimit then
		return oPlayer:Tips("已达到购买上限")
	end

	local tPrice = tConf.tPrice[1]
	if tConf.nForward > 0 then
		return oPlayer:Tips("该物品不是可购买类型")
	end

	local nCurrNum = oPlayer:GetItemCount(tPrice[1], tPrice[2])
	if nCurrNum < tPrice[3] then
		return oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(tPrice[2])))
	end

	oPlayer:SubItem(tPrice[1], tPrice[2], tPrice[3], "挖宝活动购买道具")
	oPlayer:AddItem(gtItemType.eProp, tConf.nPropID, 1, "挖宝活动购买道具")
	self:AddPropBuyTimes(nCharID, nPropID)

	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "WaBaoBuyPropRet", {nPropID=nPropID})
	self:PropListReq(oPlayer)
end

--挖宝奖励记录
function CWaBao:AddWBRecord(oPlayer, tAward)
	local sName = oPlayer:GetName()
	local tRecord = {sName, tAward}
	table.insert(self.m_tWBRecordList, 1, tRecord)
	if #self.m_tWBRecordList > nMaxWBRecordNum then
		table.remove(self.m_tWBRecordList)
	end
	self:MarkDirty(true)
end

--取挖宝奖励列表
function CWaBao:GetWBRecord()
	local tList = {}
	for _, tRecord in ipairs(self.m_tWBRecordList) do
		local tInfo = {sName=tRecord[1], tAward=tRecord[2]}
		table.insert(tList, tInfo)
	end
	return tList
end

--使用道具请求
function CWaBao:UsePropReq(oPlayer, nPropID)
	local nStartState = CHDBase.tState.eStart 
	if self.m_nState ~= nStartState or self.m_nSubState ~= nStartState then
		return oPlayer:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	local nCharID = oPlayer:GetCharID()
	local tConf = assert(ctWBPropConf[nPropID], "道具不存在")
	local nCurrNum = oPlayer:GetItemCount(gtItemType.eProp, nPropID)
	if nCurrNum <= 0 then
		return oPlayer:Tips("道具不足")
	end
	oPlayer:SubItem(gtItemType.eProp, nPropID, 1, "挖宝活动使用道具")

	--个人财宝
	self.m_tPlayerScoreMap[nCharID] = (self.m_tPlayerScoreMap[nCharID] or 0) + tConf.nScore

	--联盟财宝
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if oUnion then
		local nUnionID = oUnion:GetID()
		self.m_tUnionScoreMap[nUnionID] = (self.m_tUnionScoreMap[nUnionID] or 0) + tConf.nScore
	end

	--全服财宝
	self.m_nServerScore = self.m_nServerScore + tConf.nScore
	self:MarkDirty(true)

	--奖励
	local tMsg = {nScore=tConf.nScore, nServerScore=self.m_nServerScore, tList={}}
	--伪概率判定
	local tAward = oPlayer.m_oWGL:CheckAward(gtWGLDef.eWB)
	if tAward[1] and tAward[1][1] > 0 then
		for _, tItem in ipairs(tAward) do
			oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "挖宝活动使用道具伪概率")
			local tItem = {nType=tItem[1], nID=tItem[2], nNum=tItem[3]}
			table.insert(tMsg.tList, tItem)
		end
	else
		local nRnd = math.random(1, tConf.nTotalW)
		for _, tAward in pairs(tConf.tAward) do
			if nRnd >= tAward.nMinW and nRnd <= tAward.nMaxW then
				oPlayer:AddItem(tAward[2], tAward[3], tAward[4], "挖宝活动使用道具")
				local tItem = {nType=tAward[2], nID=tAward[3], nNum=tAward[4]}
				table.insert(tMsg.tList, tItem)
				break
			end
		end
	end

	--奖励记录
	local tItem = tMsg.tList[1]
	self:AddWBRecord(oPlayer, {tItem.nType, tItem.nID, tItem.nNum})
	--电视
	local tPropConf = ctPropConf[tItem.nID]
	if tPropConf.nColor >= 5 then
		local sNotice = string.format(ctLang[1], oPlayer:GetName(), tPropConf.nColor, CGuoKu:PropName(tItem.nID))
		goTV:_TVSend(sNotice)
	end

	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "WaBaoUsePropRet", tMsg)
	--小红点
	self:CheckRedPoint(nCharID)
end

--活动奖励信息请求
function CWaBao:AwardInfoReq(oPlayer)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oPlayer:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	local tConf = ctWBEtcConf[1]
	local nCharID = oPlayer:GetCharID()
	local nState = self.m_tScoreAwardMap[nCharID]
	if not nState then
		nState = self.m_nServerScore >= tConf.nScore and 1 or 0
	end
	local tMsg = {nScore=self.m_nServerScore, nState=nState}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "WaBaoAwardInfoRet", tMsg)
end

--领取活动奖励请求
function CWaBao:AwardReq(oPlayer)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oPlayer:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	local tConf = ctWBEtcConf[1]
	local nCharID = oPlayer:GetCharID()
	local nState = self.m_tScoreAwardMap[nCharID]
	if (nState or 0) == 2 then
		return oPlayer:Tips("已领取过奖励")
	end
	if self.m_nServerScore < tConf.nScore then
		return oPlayer:Tips("未达到领取条件")
	end
	local tAward = tConf.tAward[1]
	oPlayer:AddItem(tAward[1], tAward[2], tAward[3], "挖宝活动奖励")
	self.m_tScoreAwardMap[nCharID] = 2
	self:MarkDirty(true)
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "WaBaoAwardRet", {nID=tAward[2], nNum=tAward[3]})
	self:AwardInfoReq(oPlayer)
	--小红点
	self:CheckRedPoint(nCharID)
end

--兑换列表请求
function CWaBao:ExchangeListReq(oPlayer)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oPlayer:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	local nCharID = oPlayer:GetCharID()
	local tExchange = self.m_tExchangeMap[nCharID] or {}
	local nCurrScore = self.m_tPlayerScoreMap[nCharID] or 0
	local nUseScore = self.m_tPlayerUseScoreMap[nCharID] or 0
	local tMsg = {tList={}, nScore=nCurrScore-nUseScore}
	for nPropID, tConf in pairs(ctWBExchangeConf) do
		local tItem = {nPropID=nPropID, nExcNum=tExchange[nPropID] or 0}
		table.insert(tMsg.tList, tItem)
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "WaBaoExchangeListRet", tMsg)
end

--兑换物品请求
function CWaBao:ExchangeReq(oPlayer, nPropID)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oPlayer:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	local nCharID = oPlayer:GetCharID()
	local nCurrScore = self.m_tPlayerScoreMap[nCharID] or 0
	local nUseScore = self.m_tPlayerUseScoreMap[nCharID] or 0
	local tConf = assert(ctWBExchangeConf[nPropID])
	if nUseScore+tConf.nScore > nCurrScore then
		return oPlayer:Tips("财宝不足")
	end
	local tExchange = self.m_tExchangeMap[nCharID] or {}
	if (tExchange[nPropID] or 0) >= tConf.nLimit then
		return oPlayer:Tips("物品已售罄")
	end
	tExchange[nPropID] = (tExchange[nPropID] or 0) + 1
	self.m_tExchangeMap[nCharID] = tExchange

	self.m_tPlayerUseScoreMap[nCharID] = nUseScore + tConf.nScore
	oPlayer:AddItem(gtItemType.eProp, nPropID, 1, "挖宝兑换物品")
	self:MarkDirty(true)

	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "WaBaoExchangeRet", {nID=nPropID, nNum=1})
	self:ExchangeListReq(oPlayer)
end

--排行榜更新
function CWaBao:UpdateRanking(bEnd)
	if os.time() - self.m_nLastRankTime < nRankingUpdateTime and not bEnd then
		return
	end
	self.m_nLastRankTime = os.time()

	self.m_tUnionRanking = {}
	self.m_tPlayerRanking = {}
	self.m_tTmpPlayerScoreMap = {}
	self.m_tTmpUnionScoreMap = {}

	for nCharID, nScore in pairs(self.m_tPlayerScoreMap) do
		table.insert(self.m_tPlayerRanking, {nCharID, nScore})
		self.m_tTmpPlayerScoreMap[nCharID] = nScore
	end
	for nUnionID, nScore in pairs(self.m_tUnionScoreMap) do
		table.insert(self.m_tUnionRanking, {nUnionID, nScore})
		self.m_tTmpUnionScoreMap[nUnionID] = nScore
	end
	
	table.sort(self.m_tPlayerRanking, function(v1, v2)
		if v1[2] == v2[2] then
			return v1[1] < v2[1]
		end
		return v1[2] > v2[2]
	end)
	table.sort(self.m_tUnionRanking, function(v1, v2)
		if v1[2] == v2[2] then
			return v1[1] < v2[1]
		end
		return v1[2] > v2[2]
	end)
end

--取我的排名
function CWaBao:GetPlayerRank(nCharID)
	local nRank, nValue = 0, 0
	if not self.m_tPlayerScoreMap[nCharID] then
		return nRank, nValue
	end

	--财宝降序，角色ID升序
	local function fnCmp(v1, v2)
		if v1[2] == v2[2] then
			if v1[1] == v2[1] then
				return 0
			end
			if v1[1] > v2[1] then --角色ID
				return 1
			else
				return -1
			end
		else
			if v1[2] > v2[2] then --财宝
				return -1
			else
				return 1
			end
		end
	end
	if self.m_tTmpPlayerScoreMap[nCharID] then
		local tTmpVal = {nCharID, self.m_tTmpPlayerScoreMap[nCharID]}
		nRank = CAlg:BinarySearch(self.m_tPlayerRanking, fnCmp, tTmpVal)
		nValue = self.m_tTmpPlayerScoreMap[nCharID]
	end
	return nRank, nValue
end

--取我的联盟排名
function CWaBao:GetUnionRank(nCharID)
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
	--财宝降序，联盟ID升序
	local function fnCmp(v1, v2)
		if v1[2] == v2[2] then
			if v1[1] == v2[1] then
				return 0
			end
			if v1[1] > v2[1] then --联盟ID
				return 1
			else
				return -1
			end
		else
			if v1[2] > v2[2] then --财宝
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
function CWaBao:PlayerRankingReq(oPlayer, nRankNum)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oPlayer:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	self:UpdateRanking()
	local nCharID = oPlayer:GetCharID()
	local nRankNum = math.max(1, math.min(nRankNum, nMaxRankingNum))
	local nMyRank, nMyValue = self:GetPlayerRank(nCharID)
	local tMsg = {nType=1, tList={}, nMyRank=nMyRank, sMyName="", nMyValue=nMyValue}
	for k = 1, nRankNum do
		local tRank = self.m_tPlayerRanking[k]
		if tRank then
			local tItem = {nRank=k, sName=goOfflineDataMgr:GetName(tRank[1]), nValue=tRank[2]}
			table.insert(tMsg.tList, tItem)
		end
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "WaBaoRankingRet", tMsg)
end

--联盟排行榜请求
function CWaBao:UnionRankingReq(oPlayer, nRankNum)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oPlayer:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	self:UpdateRanking()
	local nCharID = oPlayer:GetCharID()
	local nRankNum = math.max(1, math.min(nRankNum, nMaxRankingNum))
	local nMyRank, sMyName, nMyValue = self:GetUnionRank(nCharID)
	local tMsg = {nType=2, tList={}, nMyRank=nMyRank, sMyName=sMyName, nMyValue=nMyValue}
	for k = 1, nRankNum do
		local tRank = self.m_tUnionRanking[k]
		if tRank then
			local oUnion = goUnionMgr:GetUnion(tRank[1])
			if oUnion then
				local tItem = {nRank=k, sName=oUnion:GetName(), nValue=tRank[2]}
				table.insert(tMsg.tList, tItem)
			end
		end
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "WaBaoRankingRet", tMsg)
end

--取玩家领奖状态
function CWaBao:GetPlayerAwardState(nCharID)
	if self.m_nState ~= CHDBase.tState.eAward then
		return 0 --状态不对不可领奖
	end
	local nAwardState = self.m_tPlayerRankAwardMap[nCharID]
	if nAwardState then
		return 2 --已领取过领奖
	end
	local nMyRank, nMyValue = self:GetPlayerRank(nCharID)
	if nMyRank == 0 or nMyRank > ctWBPLRankingConf[#ctWBPLRankingConf].tRank[1][2] then
		return 0 --未上榜不能领取
	end
	return 1 --可领取
end

--取联盟领奖状态
function CWaBao:GetUnionAwardState(nCharID)
	if self.m_nState ~= CHDBase.tState.eAward then
		return 0 --状态不对不可领奖
	end
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	if not oUnion then
		return 0 --没有联盟不能领奖
	end
	local nUnionID = oUnion:GetID()
	local tUnionAwardMap = self.m_tUnionRankAwardMap[nUnionID] or {}
	local nAwardState = tUnionAwardMap[nCharID]
	if nAwardState then
		return 2 --已领取过领奖
	end
	local nMyRank, sMyName, nMyValue = self:GetUnionRank(nCharID)
	if nMyRank == 0 or nMyRank > ctWBUNRankingConf[#ctWBUNRankingConf].tRank[1][2] then
		return 0 --未上榜不能领取
	end
	return 1 --可领取
end

--取个人排行奖励信息
function CWaBao:PlayerRankAwardInfoReq(oPlayer)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oPlayer:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	local nCharID = oPlayer:GetCharID()
	local nMyRank, nMyValue = self:GetPlayerRank(nCharID)
	local nAwardState = self:GetPlayerAwardState(nCharID)
	local tMsg = {nType=1, nState=self:GetState(), nStateTime=self:GetStateTime()
		, nMyRank=nMyRank, sMyName="", nMyValue=nMyValue, nAwardState=nAwardState}	
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "WaBaoRankAwardInfoRet", tMsg)
end

--取联盟排行奖励信息
function CWaBao:UnionRankAwardInfoReq(oPlayer)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oPlayer:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	local nCharID = oPlayer:GetCharID()
	local nMyRank, sMyName, nMyValue = self:GetUnionRank(nCharID)
	local nAwardState = self:GetUnionAwardState(nCharID)
	local tMsg = {nType=2, nState=self:GetState(), nStateTime=self:GetStateTime()
		, nMyRank=nMyRank, sMyName=sMyName, nMyValue=nMyValue, nAwardState=nAwardState}	
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "WaBaoRankAwardInfoRet", tMsg)
end

--领取个人排行奖励
function CWaBao:PlayerRankAwardReq(oPlayer)
	if self.m_nState ~= CHDBase.tState.eAward then
		return oPlayer:Tips("未到领奖时间:"..self.m_nState)
	end
	local nCharID = oPlayer:GetCharID()
	local nAwardState = self:GetPlayerAwardState(nCharID)
	if nAwardState == 2 then
		return oPlayer:Tips("已领取过奖励")
	end
	if nAwardState == 0 then
		return oPlayer:Tips("未达到领取条件")
	end
	local tList = {}
	local nMyRank = self:GetPlayerRank(nCharID)
	for k = #ctWBPLRankingConf, 1, -1 do
		local tConf = ctWBPLRankingConf[k]
		local tRank = tConf.tRank[1]
		if nMyRank >= tRank[1] then
			if self:GetOpenTimes() > 1 then 	--普通开启
				for _, tAward in ipairs(tConf.tAward1) do
					oPlayer:AddItem(tAward[1], tAward[2], tAward[3], "挖宝个人排行奖励")
					table.insert(tList, {nType=tAward[1], nID=tAward[2], nNum=tAward[3]})
				end
			else 								--首次开启
				for _, tAward in ipairs(tConf.tAward) do
					oPlayer:AddItem(tAward[1], tAward[2], tAward[3], "挖宝个人排行奖励")
					table.insert(tList, {nType=tAward[1], nID=tAward[2], nNum=tAward[3]})
				end
			end
			break
		end
	end
	self.m_tPlayerRankAwardMap[nCharID] = 2
	self:MarkDirty(true)
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "WaBaoRankAwardRet", {nType=1, tList=tList})
	self:PlayerRankAwardInfoReq(oPlayer)
	--小红点
	self:CheckRedPoint(nCharID)
end

--领取公会排行奖励
function CWaBao:UnionRankAwardReq(oPlayer)
	if self.m_nState ~= CHDBase.tState.eAward then
		return oPlayer:Tips("未到领奖时间:"..self.m_nState)
	end
	local nCharID = oPlayer:GetCharID()
	local nAwardState = self:GetUnionAwardState(nCharID)
	if nAwardState == 2 then
		return oPlayer:Tips("已领取过奖励")
	end
	if nAwardState == 0 then
		return oPlayer:Tips("未达到领取条件")
	end
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	local nUnionID = oUnion:GetID()
	local nPos = oUnion:GetPos(nCharID) 

	local tList = {}
	local nMyRank = self:GetUnionRank(nCharID)
	for k = #ctWBUNRankingConf, 1, -1 do
		local tConf = ctWBUNRankingConf[k]
		local tRank = tConf.tRank[1]
		if nMyRank >= tRank[1] then
			if self:GetOpenTimes() > 1 then  
				local tAward = tConf["tAward1"..nPos]
				for _, tItem in ipairs(tAward) do
					oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "挖宝联盟排行奖励:"..nPos)
					table.insert(tList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
				end
			else
				local tAward = tConf["tAward"..nPos]
				for _, tItem in ipairs(tAward) do
					oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "挖宝联盟排行奖励:"..nPos)
					table.insert(tList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
				end
			end
			break
		end
	end
	local tUnionAwardMap = self.m_tUnionRankAwardMap[nUnionID] or {}
	tUnionAwardMap[nCharID] = 2
	self.m_tUnionRankAwardMap[nUnionID] = tUnionAwardMap
	self:MarkDirty(true)
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "WaBaoRankAwardRet", {nType=2, tList=tList})
	self:UnionRankAwardInfoReq(oPlayer)
	--小红点
	self:CheckRedPoint(nCharID)
end

--是否可以领取奖励
function CWaBao:CanGetAward(oPlayer)
	local nCharID = oPlayer:GetCharID()
	local nPlayerAward = self:GetPlayerAwardState(nCharID)
	local nUnionAward = self:GetUnionAwardState(nCharID)

	local nAwardState = self.m_tScoreAwardMap[nCharID]
	if not nAwardState then
		nAwardState = self.m_nServerScore >= ctWBEtcConf[1].nScore and 1 or 0
	end
	return (nPlayerAward==1), (nUnionAward==1), (nAwardState==1)
end

--小红点处理
function CWaBao:CheckRedPoint(nCharID)
	local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
	if not oPlayer then
		return
	end
	self:SyncState(oPlayer)
end