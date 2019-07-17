--黑水玄蛇
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nMaxRankingNum = 100 			--最大100条记录返回
local nRankingUpdateTime = 3600 	--排行榜1小时更新一次
local nMaxAwardRecordNum = 3 		--记录奖励数量

function CHSXS:Ctor(nID)
	CHDBase.Ctor(self, nID)     	--继承基类
	self:Init()
end

function CHSXS:Init()
	self.m_nServerScore = 0 					--今日全服积分
	self.m_tScoreAwardMap = {} 					--全服积分奖励映射:{[roleid]=1, ...}
	self.m_nSubState = CHDBase.tState.eClose 	--活动子状态

	self.m_tRoleScoreMap = {}					--个人积分映射:{[roleid]=score, ...}
	self.m_tUnionScoreMap = {} 					--联盟积分映射:{[unionid]=score, ...}

	self.m_tExchangeMap = {} 					--兑换道具映射:{[roleid]={[propid]=num, ...}, ...}
	self.m_tRoleUseScoreMap = {}				--个人已使用积分映射:{[roleid]=score, ...}

	self.m_tBuyPropMap = {} 					--购买道具映射:{[roleid]={[propid]=num, ...}
	self.m_tRoleRankAwardMap = {} 				--玩家排行榜领奖状态{[roleid]=state, ...}
	self.m_tUnionRankAwardMap = {} 				--联盟排行榜领奖状态{[unionid]={[roleid]=state,...},...}
	self.m_tAwardRecordList = {} 				--玩家奖励记录

	--日奖励
	self.m_tDayAwardMap = {}

	--不保存
	self.m_tUnionRanking = {} 		--联盟排行
	self.m_tRoleRanking = {} 		--个人排行
	self.m_nLastRankTime = 0 		--上次排行时间
	self.m_tTmpUnionScoreMap = {} 	--联盟排行榜临时积分映射
	self.m_tTmpRoleScoreMap = {} 	--玩家排行榜临时积分映射
end

function CHSXS:LoadData()
	print("加载活动数据", self:GetName())
	local oSSDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
	local sData = oSSDB:HGet(gtDBDef.sHuoDongDB, self:GetID()) 
	if sData == "" then return end

	local tData = cjson.decode(sData)
	CHDBase.LoadData(self, tData)
	
	self.m_nSubState = tData.m_nSubState
	self.m_nServerScore = tData.m_nServerScore
	self.m_tRoleScoreMap = tData.m_tRoleScoreMap
	self.m_tRoleUseScoreMap = tData.m_tRoleUseScoreMap
	self.m_tUnionScoreMap = tData.m_tUnionScoreMap
	self.m_tExchangeMap = tData.m_tExchangeMap
	self.m_tBuyPropMap = tData.m_tBuyPropMap
	self.m_tScoreAwardMap = tData.m_tScoreAwardMap
	self.m_tRoleRankAwardMap = tData.m_tRoleRankAwardMap
	self.m_tUnionRankAwardMap = tData.m_tUnionRankAwardMap
	self.m_tAwardRecordList = tData.m_tAwardRecordList
	self.m_tDayAwardMap = tData.m_tDayAwardMap
end

function CHSXS:SaveData()
	if not self:IsDirty() then
		return
	end

	local tData = CHDBase.SaveData(self)

	tData.m_nSubState = self.m_nSubState 
	tData.m_nServerScore = self.m_nServerScore
	tData.m_tRoleScoreMap = self.m_tRoleScoreMap
	tData.m_tRoleUseScoreMap = self.m_tRoleUseScoreMap
	tData.m_tUnionScoreMap = self.m_tUnionScoreMap
	tData.m_tExchangeMap = self.m_tExchangeMap
	tData.m_tBuyPropMap = self.m_tBuyPropMap
	tData.m_tScoreAwardMap = self.m_tScoreAwardMap
	tData.m_tRoleRankAwardMap = self.m_tRoleRankAwardMap
	tData.m_tUnionRankAwardMap  = self.m_tUnionRankAwardMap
	tData.m_tAwardRecordList = self.m_tAwardRecordList
	tData.m_tDayAwardMap = self.m_tDayAwardMap

	local oSSDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
	oSSDB:HSet(gtDBDef.sHuoDongDB, self:GetID(), cjson.encode(tData))
	self:MarkDirty(false)
end

--玩家上线
function CHSXS:Online(oRole)
	self:SyncState(oRole)
end

--更新状态
function CHSXS:UpdateState()
	CHDBase.UpdateState(self)
	self:UpdateSubState()
end

--进入初始状态
function CHSXS:OnStateInit()
	print("黑水玄蛇进入初始状态")
	self:SyncState()
end

--进入活动状态
function CHSXS:OnStateStart()
	print("黑水玄蛇进入开始状态")
	--初始化
	self:Init()
	self:SyncState()
	self:MarkDirty(true)
end

--进入领奖状态
function CHSXS:OnStateAward()
	print("黑水玄蛇进入领奖状态")
	self:UpdateRanking(true)
	self:SyncState()
end

--进入关闭状态
function CHSXS:OnStateClose()
	print("黑水玄蛇进入关闭状态")
	self:SyncState()
end

--子状态开始，结束时间
function CHSXS:GetSubTime()
	local nNow = os.time()
	local tTime = ctHSXSEtcConf[1].tDayTime[1]
	local tDate = os.date("*t", nNow)
	local nBeginTime = os.MakeTime(tDate.year, tDate.month, tDate.day, tTime[1], 0, 0)
	local nEndTime = os.MakeTime(tDate.year, tDate.month, tDate.day, tTime[2], 0, 0)
	return nBeginTime, nEndTime
end

--更新子状态
function CHSXS:UpdateSubState()
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
function CHSXS:OnSubStateInit()
	print("黑水玄蛇进入初始子状态")
	self:UpdateRanking(true)
	self:MarkDirty(true)
	self:SyncState()
end

--活动子状态开始
function CHSXS:OnSubStateStart()
	print("黑水玄蛇进入开始子状态")
	self.m_tBuyPropMap = {}	--限购次数重置
	self.m_nServerScore = 0 --全服积分重置
	self.m_tScoreAwardMap = {} --全服积分奖励重置
	self.m_tDayAwardMap = {} --每日奖励
	self:MarkDirty(true)
	self:SyncState()
end

--活动子状态结束
function CHSXS:OnSubStateClose()
	print("黑水玄蛇进入关闭子状态")
	self:UpdateRanking(true)
	self:MarkDirty(true)
	self:SyncState()
end

--取活动子状态(日开放时间状态)
function CHSXS:GetSubState()
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
function CHSXS:SyncState(oRole)
	local nState = self:GetState()
	local nSubState, nSubStateTime = self:GetSubState()
	local nBeginTime, nEndTime, nStateTime = self:GetStateTime()
	if nState == CHDBase.tState.eClose then
		nBeginTime, nEndTime = goHDCircle:GetActNextOpenTime(self:GetID())
		if nBeginTime > 0 and nBeginTime > os.time() then
			assert(nEndTime>nBeginTime, "下次开启时间错误")
			nState = CHDBase.tState.eInit
			nStateTime = nEndTime - nBeginTime
		end
	end

	local tMsg = {
		nID = self:GetID(),
		nState = nState,
		nStateTime = nStateTime,
		nBeginTime = nBeginTime,
		nEndTime = nEndTime,
		nSubState = nSubState,
		nSubStateTime = nSubStateTime,
		nServerScore = self.m_nServerScore,
		tAwardRecord = self:GetAwardRecord(),
		nOpenTimes = self:GetOpenTimes(),
		bRoleAward = false,
		bUnionAward = false,
		bActAward = false,
		bDayAward = false, 
	}

	if oRole then
		local bRoleAward, bUnionAward, bActAward = self:CanGetAward(oRole)
		tMsg.bRoleAward = bRoleAward
		tMsg.bUnionAward = bUnionAward
		tMsg.bActAward = bActAward
		tMsg.bDayAward = self:IsDayAward(oRole)
		oRole:SendMsg("XYStateRet", tMsg)
	else
		local tSessionMap = goGPlayerMgr:GetRoleSSMap()
		for nSession, oTmpRole in pairs(tSessionMap) do
			local bRoleAward, bUnionAward, bActAward = self:CanGetAward(oTmpRole)
			tMsg.bRoleAward = bRoleAward
			tMsg.bUnionAward = bUnionAward
			tMsg.bActAward = bActAward
			tMsg.bDayAward = self:IsDayAward(oTmpRole)
			oTmpRole:SendMsg("XYStateRet", tMsg)
		end
	end
end

--取已购买道具次数
function CHSXS:GetPropBuyTimes(nRoleID, nPropID)
	local tConf = assert(ctHSXSPropConf[nPropID])
	local tBuyMap = self.m_tBuyPropMap[nRoleID] or {}
	local nBuyTimes = tBuyMap[nPropID] or 0
	return nBuyTimes
end

--增加道具购买次数
function CHSXS:AddPropBuyTimes(nRoleID, nPropID)
	local tBuyMap = self.m_tBuyPropMap[nRoleID] or {}
	tBuyMap[nPropID] = (tBuyMap[nPropID] or 0) + 1
	self.m_tBuyPropMap[nRoleID] = tBuyMap
	self:MarkDirty(true)
end

--道具列表请求
function CHSXS:PropListReq(oRole)
	if self.m_nState ~= CHDBase.tState.eStart or self.m_nSubState ~= CHDBase.tState.eStart then
		return oRole:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	local tList = {}
	local nRoleID = oRole:GetID()
	for nPropID, tConf in pairs(ctHSXSPropConf) do
		local tItem = {nPropID=nPropID, nBuyTimes=self:GetPropBuyTimes(nRoleID, nPropID)}
		table.insert(tList, tItem)
	end
	oRole:SendMsg("XYPropListRet", {nID=self:GetID(), tList=tList})
end

--购买道具请求
function CHSXS:BuyPropReq(oRole, nPropID)
	if self.m_nState ~= CHDBase.tState.eStart or self.m_nSubState ~= CHDBase.tState.eStart then
		return oRole:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end

	local nRoleID = oRole:GetID()
	local tConf = assert(ctHSXSPropConf[nPropID])
	local nBuyTimes = self:GetPropBuyTimes(nRoleID, nPropID)
	if tConf.nLimit > 0 and nBuyTimes >= tConf.nLimit then
		return oRole:Tips("已达到购买上限")
	end

	local tPrice = tConf.tPrice[1]
	if tConf.nForward > 0 then
		return oRole:Tips("该物品不是可购买类型")
	end

	if tPrice[1] == 0 then --免费
		local tItemList = {{nType=gtItemType.eProp, nID=tConf.nPropID, nNum=1}}
		oRole:AddItem(tItemList, "黑水玄蛇活动购买道具", function(bRet)
			if bRet then
				self:AddPropBuyTimes(nRoleID, nPropID)
				self:PropListReq(oRole)
			end
		end)
		return
	end

	local tItemList = {{nType=tPrice[1], nID=tPrice[2], nNum=tPrice[3]}}
	oRole:SubItem(tItemList, "黑水玄蛇活动购买道具", function(bRet)
		if not bRet then
			return oRole:Tips(string.format("%s不足", ctPropConf:PropName(tPrice[2])))
		end
		local tItemList = {{nType=gtItemType.eProp, nID=tConf.nPropID, nNum=1}}
		oRole:AddItem(tItemList, "黑水玄蛇活动购买道具", function(bRet)
			if bRet then
				self:AddPropBuyTimes(nRoleID, nPropID)
				self:PropListReq(oRole)
			end
		end)
	end)
end

--黑水玄蛇奖励记录
function CHSXS:AddAwardRecord(oRole, tAward)
	if not tAward then return end
	local sName = oRole:GetName()
	local sRecord = string.format(ctLang[1], sName, "黑水玄蛇", ctPropConf:PropName(tAward[2]).."*"..tAward[3])
	table.insert(self.m_tAwardRecordList, 1, sRecord)
	if #self.m_tAwardRecordList > nMaxAwardRecordNum then
		table.remove(self.m_tAwardRecordList)
	end
	self:MarkDirty(true)
end

--取黑水玄蛇奖励列表
function CHSXS:GetAwardRecord()
	return self.m_tAwardRecordList
end

--使用道具请求
function CHSXS:UsePropReq(oRole, nPropID)
	if self.m_nState ~= CHDBase.tState.eStart or self.m_nSubState ~= CHDBase.tState.eStart  then
		return oRole:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	local nRoleID = oRole:GetID()
	local tConf = assert(ctHSXSPropConf[nPropID], "道具不存在")
	oRole:SubItem({{nType=gtItemType.eProp,nID=nPropID,nNum=1}}, "黑水玄蛇活动使用道具", function(bRet)
		if not bRet then
			return oRole:Tips("道具不足")
		end

		--个人积分
		self.m_tRoleScoreMap[nRoleID] = (self.m_tRoleScoreMap[nRoleID] or 0) + tConf.nScore

		--联盟积分
		local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
		if oUnion then
			local nUnionID = oUnion:GetID()
			self.m_tUnionScoreMap[nUnionID] = (self.m_tUnionScoreMap[nUnionID] or 0) + tConf.nScore
		end

		--全服积分
		self.m_nServerScore = self.m_nServerScore + tConf.nScore
		self:MarkDirty(true)

		--奖励
		local tItemList = {}
		local tAwardList = CWeightRandom:Random(tConf.tAward, function(tItem) return tItem[1] end, 1)
		for _,tItem in pairs(tAwardList) do
			table.insert(tItemList, {nType=tItem[2], nID=tItem[3], nNum=tItem[4]})
		end

		oRole:AddItem(tItemList, "黑水玄蛇活动奖励", function(bRet)
			if bRet then
				oRole:SendMsg("XYUsePropRet", {nID=self:GetID(), nScore=tConf.nScore, nServerScore=self.m_nServerScore, tList=tItemList})
				self:AddAwardRecord(oRole, tAwardList[1])
				self:SyncState(oRole)
				
				--日志
				goLogger:ActivityLog(oRole, self:GetID(), self:GetName(), {{1,nPropID,1}}, tAwardList)
			end
		end)

		--限时奖励
		goHDMgr:GetActivity(gtHDDef.eTimeAward):UpdateVal(oRole:GetID(), gtTAType.eXY, 1)

	end)
end

--活动奖励信息请求
function CHSXS:AwardInfoReq(oRole)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oRole:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	local tConf = ctHSXSEtcConf[1]
	local nRoleID = oRole:GetID()
	local nState = self.m_tScoreAwardMap[nRoleID]
	if not nState then
		nState = self.m_nServerScore >= tConf.nScore and 1 or 0
	end
	local tMsg = {nID=self:GetID(), nScore=self.m_nServerScore, nState=nState}
	oRole:SendMsg("XYAwardInfoRet", tMsg)
end

--领取活动奖励请求
function CHSXS:AwardReq(oRole)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oRole:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	local tConf = ctHSXSEtcConf[1]
	local nRoleID = oRole:GetID()
	local nState = self.m_tScoreAwardMap[nRoleID]
	if (nState or 0) == 2 then
		return oRole:Tips("已领取过奖励")
	end
	if self.m_nServerScore < tConf.nScore then
		return oRole:Tips("未达到领取条件")
	end
	self.m_tScoreAwardMap[nRoleID] = 2
	self:MarkDirty(true)

	local tAward = tConf.tAward[1]
	local tItemList = {{nType=tAward[1], nID=tAward[2], nNum=tAward[3]}}
	oRole:AddItem(tItemList, "黑水玄蛇活动奖励", function(bRet)
		if bRet then
			self:AwardInfoReq(oRole)
			self:SyncState(oRole)
		end
	end)
end

--兑换列表请求
function CHSXS:ExchangeListReq(oRole)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oRole:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	local nRoleID = oRole:GetID()
	local tExchange = self.m_tExchangeMap[nRoleID] or {}
	local nCurrScore = self.m_tRoleScoreMap[nRoleID] or 0
	local nUseScore = self.m_tRoleUseScoreMap[nRoleID] or 0

	local tMsg = {nID=self:GetID(), tList={}, nScore=nCurrScore-nUseScore}
	for nPropID, tConf in pairs(ctHSXSExchangeConf) do
		local tItem = {nPropID=nPropID, nExcNum=tExchange[nPropID] or 0}
		table.insert(tMsg.tList, tItem)
	end
	oRole:SendMsg("XYExchangeListRet", tMsg)
end

--兑换物品请求
function CHSXS:ExchangeReq(oRole, nPropID)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oRole:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	local nRoleID = oRole:GetID()
	local nCurrScore = self.m_tRoleScoreMap[nRoleID] or 0
	local nUseScore = self.m_tRoleUseScoreMap[nRoleID] or 0
	local tConf = assert(ctHSXSExchangeConf[nPropID])
	if nUseScore+tConf.nScore > nCurrScore then
		return oRole:Tips("积分不足")
	end
	local tExchange = self.m_tExchangeMap[nRoleID] or {}
	if (tExchange[nPropID] or 0) >= tConf.nLimit then
		return oRole:Tips("物品已售罄")
	end
	tExchange[nPropID] = (tExchange[nPropID] or 0) + 1
	self.m_tExchangeMap[nRoleID] = tExchange
	self.m_tRoleUseScoreMap[nRoleID] = nUseScore + tConf.nScore
	self:MarkDirty(true)

	oRole:AddItem({{nType=gtItemType.eProp, nID=nPropID, nNum=1}}, "黑水玄蛇兑换物品", function(bRet)
		if bRet then
			self:ExchangeListReq(oRole)
		end
	end)
end

--排行榜更新
function CHSXS:UpdateRanking(bEnd)
	if os.time()-self.m_nLastRankTime < nRankingUpdateTime and not bEnd then
		return
	end
	self.m_nLastRankTime = os.time()

	self.m_tUnionRanking = {}
	self.m_tRoleRanking = {}
	self.m_tTmpRoleScoreMap = {}
	self.m_tTmpUnionScoreMap = {}

	for nRoleID, nScore in pairs(self.m_tRoleScoreMap) do
		table.insert(self.m_tRoleRanking, {nRoleID, nScore})
		self.m_tTmpRoleScoreMap[nRoleID] = nScore
	end
	for nUnionID, nScore in pairs(self.m_tUnionScoreMap) do
		table.insert(self.m_tUnionRanking, {nUnionID, nScore})
		self.m_tTmpUnionScoreMap[nUnionID] = nScore
	end
	
	table.sort(self.m_tRoleRanking, function(v1, v2)
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
function CHSXS:GetRoleRank(nRoleID)
	local nRank, nValue = 0, 0
	if not self.m_tRoleScoreMap[nRoleID] then
		return nRank, nValue
	end

	--积分降序，角色ID升序
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
			if v1[2] > v2[2] then --积分
				return -1
			else
				return 1
			end
		end
	end
	if self.m_tTmpRoleScoreMap[nRoleID] then
		local tTmpVal = {nRoleID, self.m_tTmpRoleScoreMap[nRoleID]}
		nRank = CBinarySearch:Search(self.m_tRoleRanking, fnCmp, tTmpVal)
		nValue = self.m_tTmpRoleScoreMap[nRoleID]
	end
	return nRank, nValue
end

--取我的联盟排名
function CHSXS:GetUnionRank(nRoleID)
	local nRank, sName, nValue = 0, "", 0
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then
		return nRank, sName, nValue
	end
	local nUnionID = oUnion:GetID()
	sName = oUnion:GetName()
	if not self.m_tUnionScoreMap[nUnionID] then
		return nRank, sName, nValue
	end
	--积分降序，联盟ID升序
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
			if v1[2] > v2[2] then --积分
				return -1
			else
				return 1
			end
		end
	end
	if self.m_tTmpUnionScoreMap[nUnionID] then
		local tTmpVal = {nUnionID, self.m_tTmpUnionScoreMap[nUnionID]}
		nRank = CBinarySearch:Search(self.m_tUnionRanking, fnCmp, tTmpVal)
		nValue = self.m_tTmpUnionScoreMap[nUnionID]
	end
	return nRank, sName, nValue
end

--个人排行榜请求
function CHSXS:RoleRankingReq(oRole, nRankNum)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oRole:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	self:UpdateRanking()
	local nRoleID = oRole:GetID()
	local nRankNum = math.max(1, math.min(nRankNum, nMaxRankingNum))
	local nMyRank, nMyValue = self:GetRoleRank(nRoleID)
	local tMsg = {nID=self:GetID(), nType=1, tList={}, nMyRank=nMyRank, sMyName="", nMyValue=nMyValue}
	for k = 1, nRankNum do
		local tRank = self.m_tRoleRanking[k]
		if tRank then
			local oTmpRole = goGPlayerMgr:GetRoleByID(tRank[1])
			local tItem = {nRank=k, sName=oTmpRole:GetName(), nValue=tRank[2]}
			table.insert(tMsg.tList, tItem)
		end
	end
	oRole:SendMsg("XYRankingRet", tMsg)
end

--联盟排行榜请求
function CHSXS:UnionRankingReq(oRole, nRankNum)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oRole:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	self:UpdateRanking()
	local nRoleID = oRole:GetID()
	local nRankNum = math.max(1, math.min(nRankNum, nMaxRankingNum))
	local nMyRank, sMyName, nMyValue = self:GetUnionRank(nRoleID)
	local tMsg = {nID=self:GetID(), nType=2, tList={}, nMyRank=nMyRank, sMyName=sMyName, nMyValue=nMyValue}
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
	oRole:SendMsg("XYRankingRet", tMsg)
end

--取玩家领奖状态
function CHSXS:GetRoleAwardState(nRoleID)
	if self.m_nState ~= CHDBase.tState.eAward then
		return 0 --状态不对不可领奖
	end
	local nAwardState = self.m_tRoleRankAwardMap[nRoleID]
	if nAwardState == 2 then
		return 2 --已领取过领奖
	end
	local nMyRank, nMyValue = self:GetRoleRank(nRoleID)
	if nMyRank == 0 or nMyRank > ctHSXSPLRankingConf[#ctHSXSPLRankingConf].tRank[1][2] then
		return 0 --未上榜不能领取
	end
	return 1 --可领取
end

--取联盟领奖状态
function CHSXS:GetUnionAwardState(nRoleID)
	if self.m_nState ~= CHDBase.tState.eAward then
		return 0 --状态不对不可领奖
	end
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oUnion then
		return 0 --没有联盟不能领奖
	end
	local nUnionID = oUnion:GetID()
	local tUnionAwardMap = self.m_tUnionRankAwardMap[nUnionID] or {}
	local nAwardState = tUnionAwardMap[nRoleID]
	if nAwardState then
		return 2 --已领取过领奖
	end
	local nMyRank, sMyName, nMyValue = self:GetUnionRank(nRoleID)
	if nMyRank == 0 or nMyRank > ctHSXSUNRankingConf[#ctHSXSUNRankingConf].tRank[1][2] then
		return 0 --未上榜不能领取
	end
	return 1 --可领取
end

--取个人排行奖励信息
function CHSXS:RoleRankAwardInfoReq(oRole)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oRole:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	local nRoleID = oRole:GetID()
	local nMyRank, nMyValue = self:GetRoleRank(nRoleID)
	local nAwardState = self:GetRoleAwardState(nRoleID)
	local tMsg = {nID=self:GetID(), nType=1, nState=self:GetState(), nStateTime=self:GetStateTime()
		, nMyRank=nMyRank, sMyName="", nMyValue=nMyValue, nAwardState=nAwardState}	
	oRole:SendMsg("XYRankAwardInfoRet", tMsg)
end

--取联盟排行奖励信息
function CHSXS:UnionRankAwardInfoReq(oRole)
	if self.m_nState ~= CHDBase.tState.eStart and self.m_nState ~= CHDBase.tState.eAward then
		return oRole:Tips("活动已结束:"..self.m_nState..":"..self.m_nSubState)
	end
	local nRoleID = oRole:GetID()
	local nMyRank, sMyName, nMyValue = self:GetUnionRank(nRoleID)
	local nAwardState = self:GetUnionAwardState(nRoleID)
	local tMsg = {nID=self:GetID(), nType=2, nState=self:GetState(), nStateTime=self:GetStateTime()
		, nMyRank=nMyRank, sMyName=sMyName, nMyValue=nMyValue, nAwardState=nAwardState}	
	oRole:SendMsg("XYRankAwardInfoRet", tMsg)
end

--领取个人排行奖励
function CHSXS:RoleRankAwardReq(oRole)
	if self.m_nState ~= CHDBase.tState.eAward then
		return oRole:Tips("未到领奖时间:"..self.m_nState)
	end
	local nRoleID = oRole:GetID()
	local nAwardState = self:GetRoleAwardState(nRoleID)
	if nAwardState == 2 then
		return oRole:Tips("已领取过奖励")
	end
	if nAwardState == 0 then
		return oRole:Tips("未达到领取条件")
	end
	local tItemList = {}
	local nMyRank = self:GetRoleRank(nRoleID)
	for k = #ctHSXSPLRankingConf, 1, -1 do
		local tConf = ctHSXSPLRankingConf[k]
		local tRank = tConf.tRank[1]
		if nMyRank >= tRank[1] then
			local tItemList = {}
			if self:GetOpenTimes() == 1 then --首次
				for _, tAward in ipairs(tConf.tAward1) do
					table.insert(tItemList, {nType=tAward[1], nID=tAward[2], nNum=tAward[3]})
				end
			else --非首次开启
				for _, tAward in ipairs(tConf.tAward2) do
					table.insert(tItemList, {nType=tAward[1], nID=tAward[2], nNum=tAward[3]})
				end
			end
			break
		end
	end
	self.m_tRoleRankAwardMap[nRoleID] = 2
	self:MarkDirty(true)

	oRole:AddItem(tItemList, "黑水玄蛇个人排行奖励", function(bRet)
		if bRet then
			self:RoleRankAwardInfoReq(oRole)
			self:SyncState(oRole)
		end
	end)
end

--领取公会排行奖励
function CHSXS:UnionRankAwardReq(oRole)
	if self.m_nState ~= CHDBase.tState.eAward then
		return oRole:Tips("未到领奖时间:"..self.m_nState)
	end
	local nRoleID = oRole:GetID()
	local nAwardState = self:GetUnionAwardState(nRoleID)
	if nAwardState == 2 then
		return oRole:Tips("已领取过奖励")
	end
	if nAwardState == 0 then
		return oRole:Tips("未达到领取条件")
	end
	local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	local nUnionID = oUnion:GetID()
	local nPos = oUnion:GetPos(nRoleID) 

	local tItemList = {}
	local nMyRank = self:GetUnionRank(nRoleID)
	for k = #ctHSXSUNRankingConf, 1, -1 do
		local tConf = ctHSXSUNRankingConf[k]
		local tRank = tConf.tRank[1]
		if nMyRank >= tRank[1] then
			if self:GetOpenTimes() == 1 then  
				local tAward = tConf["tAward1"..nPos]
				for _, tItem in ipairs(tAward) do
					table.insert(tItemList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
				end
			else
				local tAward = tConf["tAward2"..nPos]
				for _, tItem in ipairs(tAward) do
					table.insert(tItemList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
				end
			end
			break
		end
	end
	local tUnionAwardMap = self.m_tUnionRankAwardMap[nUnionID] or {}
	tUnionAwardMap[nRoleID] = 2
	self.m_tUnionRankAwardMap[nUnionID] = tUnionAwardMap
	self:MarkDirty(true)

	oRole:AddItem(tItemList, "黑水玄蛇联盟排行奖励", function(bRet)
		if bRet then
			self:UnionRankAwardInfoReq(oRole)
			self:SyncState(oRole)
		end
	end)
end

--是否可以领取奖励
function CHSXS:CanGetAward(oRole)
	local nRoleID = oRole:GetID()
	local nPlayerAward = self:GetRoleAwardState(nRoleID)
	local nUnionAward = self:GetUnionAwardState(nRoleID)
	local nAwardState = self.m_tScoreAwardMap[nRoleID]
	if not nAwardState then
		nAwardState = self.m_nServerScore >= ctHSXSEtcConf[1].nScore and 1 or 0
	end
	return (nPlayerAward==1), (nUnionAward==1), (nAwardState==1)
end

--每日奖励是否可领
function CHSXS:IsDayAward(oRole)
	if not self:IsOpen() or not self:IsSubOpen()then
		return false
	end
	local nRoleID = oRole:GetID()
	return (not self.m_tDayAwardMap[nRoleID])
end

function CHSXS:IsSubOpen()
	return self.m_nSubState == CHDBase.tState.eStart
end

--领取每日奖励请求
function CHSXS:DayAwardReq(oRole)
	if not self:IsOpen() or not self:IsSubOpen() then
		return oRole:Tips("活动已结束或未开始")
	end

	local nRoleID = oRole:GetID()
	if self.m_tDayAwardMap[nRoleID] then
		return oRole:Tips("你已领取过奖励，请明日再来")
	end
	self.m_tDayAwardMap[nRoleID] = true
	self:MarkDirty(true)

	local nGoldAward = 200
	oRole:AddItem({{nType=gtItemType.eCurr,nID=gtCurrType.eJinBi,nNum=nGoldAward}}, "黑水玄蛇每日奖励", function(bRet)
		if bRet then
			self:SyncState(oRole)
		end
	end)
end