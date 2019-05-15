--宝箱NPC管理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CNpcGoldBox:Ctor(nID)
	CNpcBase.Ctor(self, nID)
	self.m_tBoxList = {}
	self.m_nHourTimer = nil      	--分钟计时器
	self.m_nLastResetTime = os.time()
	self.m_nSeq = 1					--配置序号()

	--self:RegHourTimer()
end

function CNpcGoldBox:OnRelease()
	goNpcMgr:MarkDirty(self:GetID(), true)
	goTimerMgr:Clear(self.m_nHourTimer)
	self.m_nHourTimer = nil
end

function CNpcGoldBox:LoadData(tData)
	if tData then
		self.m_nSeq = ctTianDiBaoWuConf[tData.m_nSeq] and tData.m_nSeq or 1
		self.m_nLastResetTime = tData.m_nLastResetTime or 0
	end
	if self.m_nLastResetTime == 0 then
		self.m_nSeq = 1
		self.m_nLastResetTime = os.time()
		goNpcMgr:MarkDirty(self:GetID(), true)
	end
	self:CheckAndSetGoldBox()
end

function CNpcGoldBox:SaveData()
	local tData = {}
	tData.m_nSeq = self.m_nSeq
	tData.m_nLastResetTime = self.m_nLastResetTime
	return tData
end

--开启宝箱
function CNpcGoldBox:OpenGoldBox(oRole, nOpenTimes, bUseGold)
	if nOpenTimes ~= 1 and nOpenTimes ~= 10 then
		return oRole:Tips("天帝宝物打开次数有误")
	end

	assert(ctTianDiBaoWuConf[self.m_nSeq], "天帝宝物数据错误,序号"..self.m_nSeq)
	if bUseGold then  --使用元宝打开
		local nCostGold = 0
		if nOpenTimes == 1 then
			nCostGold = ctTianDiBaoWuConf[self.m_nSeq].nCostOnce
		else
			nCostGold = ctTianDiBaoWuConf[self.m_nSeq].nCostTen
		end
		if oRole:ItemCount(gtItemType.eCurr, gtCurrType.eAllYuanBao) < nCostGold then
			return oRole:Tips("消耗物品不足")
		end
		oRole:AddItem(gtItemType.eCurr, gtCurrType.eAllYuanBao, - nCostGold, "打开天帝宝物消耗")
	else
		local nNeedItemID = ctTianDiBaoWuConf[self.m_nSeq].nItemID
		local nNeedNum = 0
		if nOpenTimes == 1 then
			nNeedNum = ctTianDiBaoWuConf[self.m_nSeq].nOnceNum
		else
			nNeedNum = ctTianDiBaoWuConf[self.m_nSeq].nTemNum
		end
		if oRole:ItemCount(gtItemType.eProp, nNeedItemID) < nNeedNum then
			return oRole:Tips("消耗物品不足")
		end
		oRole:AddItem(gtItemType.eProp, nNeedItemID, - nNeedNum, "打开天帝宝物消耗")
	end

	--将有可能抽到的时装和奖励池放在一起再抽
	local tSet = {}
	for nIndex, tRand in pairs(ctTianDiBaoWuConf[self.m_nSeq].tShiZhuangIDList) do
		table.insert(tSet, tRand)
	end
	for nIndex, tRand in pairs(ctTianDiBaoWuConf[self.m_nSeq].tAwardPoolID) do
		table.insert(tSet, tRand)
	end

	--抽奖池
	local function GetAwardPoolWeight(tNode)
		return tNode[4]
	end
	local tAwardPoolList = CWeightRandom:Random(tSet, GetAwardPoolWeight, nOpenTimes, false)

	--抽物品
	local function GetItemWeight(tNode)
		return tNode.nWeight
	end
	local tItemIDList = {}
	local nRewardCount = 0
	for key, tReward in ipairs(tAwardPoolList) do	--有是抽1次的结果，有可能抽10次的结果
		--拿最后一次结果展示
		if nRewardCount + 1 >= nOpenTimes then
			local nViewIndex = 0
			local tForeachList
			if tReward[1] == 1 then
				tForeachList = ctTianDiBaoWuConf[self.m_nSeq].tShiZhuangIDList
			else
				tForeachList = ctTianDiBaoWuConf[self.m_nSeq].tAwardPoolID
			end
			for nIndex, tItem in pairs(tForeachList) do
				if tReward[2] == tItem[2] then
					nViewIndex = nIndex
					if tReward[1] == 2 then				--如果是奖励池
						nViewIndex = nViewIndex + 3		--索引加2，1,2分别是时装，3开始才是奖励池展示物的索引
					end
					break
				end
			end
			oRole:SendMsg("OpenGoldBoxViewRet", {nViewIndex = nViewIndex})
		end

		--抽取物品加入背包
		if tReward[1] == 1 then		--1类型为固定物品 2类型为奖励库需要再一次随机抽
			oRole:AddItem(gtItemType.eProp, tReward[2], tReward[3], "打开天帝宝物")
			local tItem = {}
			tItem.nItemID = tReward[2]
			tItem.nItemNum = tReward[3]
			table.insert(tItemIDList, tItem)
		else
			local tItemList = ctAwardPoolConf.GetPool(tReward[2], oRole:GetLevel(), oRole:GetConfID())
			local tItem = CWeightRandom:Random(tItemList, GetItemWeight, tReward[3], false)
			for _, tConf in pairs(tItem) do
				oRole:AddItem(tConf.nItemType, tConf.nItemID, tConf.nItemNum, "打开天帝宝物")
				local tItem = {}
				tItem.nItemID = tConf.nItemID
				tItem.nItemNum = tConf.nItemNum
				table.insert(tItemIDList, tItem)
			end
		end
		nRewardCount = nRewardCount + 1
	end
	local nRewardFuYuan = ctTianDiBaoWuConf[self.m_nSeq].nGetFuYuan * nOpenTimes
	oRole:AddItem(gtItemType.eCurr, gtCurrType.eFuYuan, nRewardFuYuan, "开启宝箱奖励福缘值")
	local tMsg = { tItemList = {}}
	tMsg.tItemList = table.DeepCopy(tItemIDList)
	oRole:SendMsg("ShowOpenGoldBoxRet", tMsg)
	local tData = {}
	tData.bIsHearsay = true
	tData.tItemIDList = tItemIDList
	CEventHandler:OnOpenGoldBox(oRole, tData)
end

--福缘兑换
function CNpcGoldBox:FuYuanExchangeReq(oRole, nExchangeID)
	assert(ctFuYuanExchangeConf[nExchangeID], "福缘兑换ID错误")
	local bCanExchange = false
	for _, tSeq in pairs(ctFuYuanExchangeConf[nExchangeID].tSeqList) do
		if self.m_nSeq == tSeq[1] then
			bCanExchange = true
			break
		end
	end
	if not bCanExchange then
		return oRole:Tips("本周不能兑换此物品")
	end
	local nCurrType = ctFuYuanExchangeConf[nExchangeID].nCostType
	local nNumCost = ctFuYuanExchangeConf[nExchangeID].nNumCost
	if oRole:ItemCount(gtItemType.eCurr, nCurrType) < nNumCost then
		return oRole:Tips("福缘值不足")
	end
	oRole:AddItem(gtItemType.eCurr, nCurrType, - nNumCost, "天帝宝物福缘兑换")
	local tItem = ctFuYuanExchangeConf[nExchangeID].tItem
	oRole:AddItem(gtItemType.eProp, tItem[1] [1], tItem[1] [2], "天帝宝物福缘兑换")

	--广播公告
	local sBroad = ctFuYuanExchangeConf[nExchangeID].sBroad
	if sBroad then
		GF.SendNotice(oRole:GetServer(), sBroad)
	end
end

--宝箱出现事件
function CNpcGoldBox:OnCreateBox()
	--广播场景
	for nDupID, tPosList in pairs(self.m_tBoxList) do
		local oDup = goDupMgr:GetDup(nDupID)
		if oDup then
			local tMsg = {tGoldBoxInfoList = {}}
			for _, tPos in pairs(tPosList) do
				local tPosTmp = {}
				tPosTmp.nDupID = tPos[1]
				tPosTmp.nPosX = tPos[2]
				tPosTmp.nPosY = tPos[3]
				table.insert(tMsg.tGoldBoxInfoList, tPosTmp)
			end
			oDup:BroadcastScene(- 1, "GoldBoxInfoListRet", tMsg)
		end
	end
end

--宝箱移除事件
function CNpcGoldBox:OnRemoveBox()
	--广播场景
	for nDupID, tPosList in pairs(self.m_tBoxList) do
		local oDup = goDupMgr:GetDup(nDupID)
		if oDup then
			oDup:BroadcastScene(- 1, "GoleBoxReMoveRet", {})
		end
	end
end

--角色进入场景事件
function CNpcGoldBox:OnEnterScene(oRole)
	--发送宝箱列表
	local nDupID = oRole:GetDupID()
	local tMsg = {tGoldBoxInfoList = {}}
	if self.m_tBoxList[nDupID] then
		for _, tPosInfo in pairs(self.m_tBoxList[nDupID]) do
			local tPos = {}
			tPos.nDupID = tPosInfo[1]
			tPos.nPosX = tPosInfo[2]
			tPos.nPosY = tPosInfo[3]
			table.insert(tMsg.tGoldBoxInfoList, tPos)
		end
		oRole:SendMsg("GoldBoxInfoListRet", tMsg)
	end
end

function CNpcGoldBox:CheckAndSetGoldBox()
	if next(self.m_tBoxList) then
		for key, _ in ipairs(self.m_tBoxList) do
			self.m_tBoxList[key] = nil
		end
		self:OnRemoveBox()
	end

	--防止重复地点
	function GetPosWeight(tNode)
		return 100
	end
	local nConfID = self:CalTianDiBaoWuID()
	assert(ctTianDiBaoWuConf[nConfID], "配置不存在:"..nConfID)
	local tPosList = CWeightRandom:Random(ctTianDiBaoWuConf[nConfID].tPosList, GetPosWeight,
	ctTianDiBaoWuConf[self.m_nSeq].nNumTotal, true)

	for key, tPos in ipairs(tPosList) do
		if not self.m_tBoxList[tPos[1]] then
			self.m_tBoxList[tPos[1]] = {}
		end
		table.insert(self.m_tBoxList[tPos[1]], tPos)	--根据场景ID分类保存坐标
	end
	self:OnCreateBox()
	--重新注册一下计时器
	self:RegHourTimer()
end

function CNpcGoldBox:CalTianDiBaoWuID()
	if (self.m_nLastResetTime > 0) and (not os.IsSameWeek(self.m_nLastResetTime, os.time())) then
		--跟周数没有绑定(切换一周，切换一组抽奖内容)
		if self.m_nSeq + 1 <= #ctTianDiBaoWuConf then
			self.m_nSeq = self.m_nSeq + 1
		else
			self.m_nSeq = 1
		end
		self.m_nLastResetTime = os.time()
		goNpcMgr:MarkDirty(self:GetID(), true)
	end
	--第一次没数据不执行LoadData
	if self.m_nSeq == 0 and self.m_nLastResetTime == 0 then
		self.m_nSeq = 1
		self.m_nLastResetTime = os.time()
		goNpcMgr:MarkDirty(self:GetID(), true)
	end
	return self.m_nSeq
end

function CNpcGoldBox:GoldBoxReq(oRole)
	oRole:SendMsg("GoldBoxRet", {nSeq=self.m_nSeq})
end

--定时器定时刷新
function CNpcGoldBox:OnHourTimer()
	self:CheckAndSetGoldBox()
end

function CNpcGoldBox:RegHourTimer()
	goTimerMgr:Clear(self.m_nHourTimer)
	local nNextHourTime = os.NextHourTime(os.time())		--距离下个整点还有多少秒
	local nDefRefreshTime = 30 * 60
	local nRefreshInterval = 0
	if nNextHourTime > nDefRefreshTime then
		--距离半点还有多少秒	
		nRefreshInterval = nNextHourTime - nDefRefreshTime
	else
		nRefreshInterval = nNextHourTime
	end
	self.m_nHourTimer = goTimerMgr:Interval(nRefreshInterval, function() self:OnHourTimer() end)
end