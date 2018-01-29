--理藩院(赐礼)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nMaxStar = 10 --最大十星(十章)
local nRandItems = assert(ctLiFanYuanEtcConf[1].nLFYRandItems)

function CLiFanYuan:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nStar = 1 --星级(相当于等级)
	self.m_nProg = 0 --进度(相当于经验)
	self.m_nResetTime = 0
	self.m_tSelectItem = {} --物品列表
	self.m_nDayFirstOpen = 0 --每天第一次打开
end

function CLiFanYuan:LoadData(tData)
	if not tData then return end
	self.m_nStar = math.min(tData.m_nStar, nMaxStar)
	self.m_nProg = tData.m_nProg
	self.m_nResetTime = tData.m_nResetTime
	self.m_nDayFirstOpen = tData.m_nDayFirstOpen or 0

	if tData.m_tSelectItem and #tData.m_tSelectItem > 0 then
		self.m_tSelectItem = tData.m_tSelectItem
	else
		self:RandItem()
	end
end

function CLiFanYuan:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nStar = self.m_nStar
	tData.m_nProg = self.m_nProg
	tData.m_nResetTime = self.m_nResetTime
	tData.m_tSelectItem = self.m_tSelectItem
	tData.m_nDayFirstOpen = self.m_nDayFirstOpen
	return tData
end

function CLiFanYuan:GetType()
	return gtModuleDef.tLiFanYuan.nID, gtModuleDef.tLiFanYuan.sName
end

--上线
function CLiFanYuan:Online()
	self:CheckRedPoint()
end

--检测重置
function CLiFanYuan:CheckReset()
	local nNowSec = os.time()
	if not os.IsSameDay(nNowSec, self.m_nResetTime, 0) then
		self.m_nStar = 1
		self.m_nProg = 0
		self:RandItem()
		self.m_nResetTime = nNowSec
		self:MarkDirty(true)
	end
end

--有效物品筛选
function CLiFanYuan:RandItem()
	local tValidItem = {} --有效物品
	local nTotalWeight, nPreWeight = 0, 0
	for _, tConf in pairs(ctLiFanYuanConf) do
		if self.m_nStar == tConf.nRare then
			table.insert(tValidItem, tConf)
			nTotalWeight = nTotalWeight + tConf.nWeight
			tConf.nMinWeight = nPreWeight + 1
			tConf.nMaxWeight = tConf.nMinWeight + tConf.nWeight - 1
			nPreWeight = tConf.nMaxWeight
		end
	end

	self.m_tSelectItem = {}
	--没有满足条件物品
	if #tValidItem > 0 then
		--第1个是奖品
		local rnd = math.random(1, nTotalWeight)
		for k, tConf in pairs(tValidItem) do
			if rnd >= tConf.nMinWeight and rnd <= tConf.nMaxWeight then
				table.insert(self.m_tSelectItem, tConf.nIndex)
				break
			end
		end

		--等概率随机14个
		for k = 1, nRandItems-1 do
			local nRnd = math.random(#tValidItem)
			table.insert(self.m_tSelectItem, tValidItem[nRnd].nIndex)
		end
	end

	self:MarkDirty(true)
end

--贡纳消耗
function CLiFanYuan:UpgradeCost()
	local nStar = math.min(self.m_nStar, #ctLiFanYuanConsumeConf)
	local tConf = ctLiFanYuanConsumeConf[nStar]
	return tConf.tCost[1]
end

--检测开放
function CLiFanYuan:CheckOpen(bTips)
	local nChapter = ctLiFanYuanEtcConf[1].nChapter
	if not self.m_oPlayer.m_oDup:IsChapterPass(nChapter) then
		if bTips then
			self.m_oPlayer:Tips(string.format("通关第%d章：%s开启", nChapter, CDup:ChapterName(nChapter)))
		end
		return
	end
	return true
end

--界面信息
function CLiFanYuan:InfoReq()
	if not self:CheckOpen(true) then
		return
	end
	self:CheckReset()
	self:SyncInfo()
end

--同步界面信息
function CLiFanYuan:SyncInfo()
	local tItemList = {}
	for _, nIndex in pairs(self.m_tSelectItem) do
		local tConf = ctLiFanYuanConf[nIndex]
		table.insert(tItemList, {nType=gtItemType.eProp, nID=tConf.nPropID, nNum=tConf.nPropNum})
	end
	local _, nTimeWaiJiao = self.m_oPlayer.m_oDup:TimeAwardItem()
	local tMsg = {
		nStar = self.m_nStar,
		nProg = self.m_nProg,	
		tItemList = tItemList,
		nTimeWaiJiao = nTimeWaiJiao,
		nCurrWaiJiao = self.m_oPlayer:GetWaiJiao(),
		nMaxWaiJiao = self.m_oPlayer:MaxWaiJiao(),
		nCostWaiJiao = self:UpgradeCost(nStar)[3],
		bDayFirstOpen = false,
	}
	if not os.IsSameDay(os.time(), self.m_nDayFirstOpen, 0) then
		tMsg.bDayFirstOpen = true
		self.m_nDayFirstOpen = os.time()
		self:MarkDirty(true)
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "LFYInfoRet", tMsg)
end

function CLiFanYuan:CheckWaiJiao(bTips)
	local tCost = self:UpgradeCost()
	if tCost[1] > 0 then
		local nCurr = self.m_oPlayer:GetItemCount(tCost[1], tCost[2])
		if nCurr < tCost[3] then
			if bTips then
				self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(tCost[2])))
			end
			return 
		end
	end
	return true
end

--需要先通关1个章节才能点
function CLiFanYuan:CheckConquer()
	if not self.m_oPlayer.m_oDup:IsChapterPass(1) then
		return self.m_oPlayer:Tips(string.format("请先通关第一章%s", CDup:ChapterName(1)))
	end
	return true
end

--纳贡
function CLiFanYuan:Upgrade(bOneKey)
	if not self:CheckOpen(true) then
		return
	end
	if not self:CheckConquer() then
		return
	end
	if #self.m_tSelectItem <= 0 then
		return self.m_oPlayer:Tips("没有有效物品")
	end

	--检测外交点
	if not self:CheckWaiJiao(not bOneKey) then
		return
	end

	--扣除外交点
	local tCost = self:UpgradeCost()
	self.m_oPlayer:SubItem(tCost[1], tCost[2], tCost[3], "赐礼")

	--升级
	local nOrgStar = self.m_nStar
	local nMaxChapter = math.min(nMaxStar, self.m_oPlayer.m_oDup:MaxChapterPass())
	local nMaxRare = math.min(ctLiFanYuanTipsConf[nMaxChapter].nMaxRare, #ctLiFanYuanConf)
	local nMaxNGTimes = ctLiFanYuanTipsConf[self.m_nStar].nNGTimes+1
	self.m_nProg = math.min(nMaxNGTimes, self.m_nProg+1)
	if self.m_nProg == nMaxNGTimes then
		if self.m_nStar < nMaxRare then
			self.m_nProg = 0
			self.m_nStar = self.m_nStar + 1
		end
	end
	self:MarkDirty(true)

	--发奖
	local nIndex = self.m_tSelectItem[1]
	local tItemConf = ctLiFanYuanConf[nIndex]

	--刷出新的物品
	self:RandItem()

	--奖励
	local tItem = {nType=gtItemType.eProp, nID=tItemConf.nPropID, nNum=tItemConf.nPropNum}
	if not bOneKey then
		self.m_oPlayer:AddItem(gtItemType.eProp, tItemConf.nPropID, tItemConf.nPropNum, "赐礼")
	    self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond44, 1)
		self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond15, 1)
		self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond13, 1)

		CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "LFYUpgradeRet", {tItemList={tItem}, nOldStar=nOrgStar, nNewStar=self.m_nStar})
		self:SyncInfo()
	else
		return tItem	
	end
end

--1键纳贡
function CLiFanYuan:OneKeyUpgrade()
	if not self:CheckOpen(true) then
		return
	end
	if not self:CheckConquer() then
		return
	end
	if #self.m_tSelectItem <= 0 then
		return self.m_oPlayer:Tips("没有有效物品")
	end

	--判断外交点
	if not self:CheckWaiJiao(true) then
		return
	end

	--纳贡
	local nCount = 0
	local nOrgStar = self.m_nStar
	local tItemMap = {}
	for k = 1, 10 do
		local tItem = self:Upgrade(true)
		if tItem then
			nCount = nCount + 1
			tItemMap[tItem.nID] = (tItemMap[tItem.nID] or 0) + tItem.nNum
			if nOrgStar ~= self.m_nStar then
				break
			end
		else
			break
		end
	end

	--任务,成就
	if nCount > 0 then
	    self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond44, nCount)
		self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond15, nCount)
		self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond13, nCount)
	end

	local tItemList = {}
	for nID, nNum in pairs(tItemMap) do
		self.m_oPlayer:AddItem(gtItemType.eProp, nID, nNum, "赐礼")
		table.insert(tItemList, {nType=gtItemType.eProp, nID=nID, nNum=nNum})
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "LFYUpgradeRet", {bOneKey=true, tItemList=tItemList, nOldStar=nOrgStar, nNewStar=self.m_nStar})
	self:SyncInfo()
end

--外交点变化
function CLiFanYuan:OnWaiJiaoChange()
	self:CheckRedPoint()
end

--通关章节(激活藩属)
function CLiFanYuan:OnChapterPass(nChapter)
	if nChapter >= 3 and nChapter <= nMaxStar then
		--电视
		local tConf = ctChapterConf[nChapter]
		local sNotice = string.format(ctLang[10], self.m_oPlayer:GetName(), tConf.sName)
		goTV:_TVSend(sNotice)
	end
end

--检测小红点
function CLiFanYuan:CheckRedPoint()
	if not self:CheckOpen() then
		return self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eLiFanYuan, 0)
	end
	local tCost = self:UpgradeCost()
	if tCost[1] > 0 then
		local nCurrNum = self.m_oPlayer:GetItemCount(tCost[1], tCost[2])
		if nCurrNum < tCost[3] then
			return self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eLiFanYuan, 0)
		end
	end
	self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eLiFanYuan, 1)
end

