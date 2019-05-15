--交易摊位
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CMarketStall:Ctor(oModul, nRoleID)
	self.m_oModul = oModul
	self.m_nRoleID = nRoleID
	self.m_tStallItemMap = {} --{Grid:MarketItem, ...}
	                          --使用PrivateKey标识每一笔交易，RoleID + PrivateKey即可确定交易唯一，不使用GlobalKey
	                          --避免在服务器长时间不重启，玩家长时间在线情况下，玩家过期物品长时间不取，导致key冲突
	self.m_bTradeActive = true   --交易状态是否活跃，即是否存在上架的商品
	self.m_bRoleOnline = false   --玩家是否在线
	self.m_bDirty = false
	self.m_nKeySerial = 1     --玩家私有PrivateKey序列号，不同于MarketMgr中的活跃交易用的GlobalKey

	self.m_bForbid = false        --是否被禁止交易
	self.m_nForbidTime = 0    --玩家被禁止交易时间戳
	self.m_nForbidReason = 0  --被禁止交易原因

	self.m_nStallGrid = gnMarketStallGridNumDefalut  --总的格子数量(默认+花钱开启的)
	self.m_nStallUnlockGrid = 0   --花钱开启的格子数量

	self.m_nLastSaveTime = 0
end

function CMarketStall:LoadData(tData)
	if not tData then
		return
	end
	self.m_tStallItemMap = {}
	for k, tItemData in ipairs(tData.tStallItemMap) do
		local oItem = self:CreateNewItem(tItemData.nItemID)
		oItem:LoadData(tItemData)
		oItem.m_nPrivateKey = self:GetNewKey() --重新设置好PrivateKey
		oItem.m_nGlobalKey = 0   --Load时将所有GKey置0，需要插入到活跃交易列表的，插入过程，会生成新的GKey
		self.m_tStallItemMap[#self.m_tStallItemMap + 1] = oItem
	end
	self.m_bForbid = tData.bForbid
	self.m_nForbidTime = tData.nForbidTime
	self.m_nForbidReason = tData.nForbidReason

	self.m_nStallUnlockGrid = tData.nStallUnlockGrid
	self.m_nStallGrid = gnMarketStallGridNumDefalut + self.m_nStallUnlockGrid

	self:UpdateActiveState()
	self:UpdateForbidState()
end

function  CMarketStall:SaveData()
	local tData = {}
	tData.nRoleID = self.m_nRoleID
	tData.tStallItemMap = {}
	for k, oItem in ipairs(self.m_tStallItemMap) do
		tData.tStallItemMap[#tData.tStallItemMap + 1] = oItem:SaveData()
	end
	tData.bForbid = self.m_bForbid
	tData.nForbidTime = self.m_nForbidTime
	tData.nForbidReason = self.m_nForbidReason

	tData.nStallUnlockGrid = self.m_nStallUnlockGrid
	return tData
end

function CMarketStall:GetLastSaveTime()
	return self.m_nLastSaveTime
end

function CMarketStall:SetLastSaveTime(nTimeStamp)
	self.m_nLastSaveTime = nTimeStamp
end

function CMarketStall:GetNewKey()
	local nKey = self.m_nKeySerial
	if nKey >= gnMarketPrivateKeyMax then
		--不做重置和重复性检查，正常情况不可能达到最大，除非玩家行为异常
		assert(false, "RoleID:"..self.m_nRoleID.." 数据异常, Market PrivateKey值已达最大")
	end
	self.m_nKeySerial = self.m_nKeySerial + 1
	return nKey
end

--更新交易活跃状态
function CMarketStall:UpdateActiveState()
	for nGrid, oItem in pairs(self.m_tStallItemMap) do
		if oItem:IsActive() then
			self.m_bTradeActive = true
			return
		end
	end
	self.m_bTradeActive = false
end

--是否活跃保留在内存中
function CMarketStall:IsKeepActive() 
	return self.m_bTradeActive or self.m_bRoleOnline
end
function CMarketStall:IsTradeActive() return self.m_bTradeActive end
function CMarketStall:IsOnline() return self.m_bRoleOnline end
function CMarketStall:MarkDirty(bDirty) 
	self.m_bDirty = bDirty 
	if self.m_bDirty then
		goMarketMgr.m_tDirtyQueue:Push(self.m_nRoleID, self)
	end
end
function CMarketStall:IsDirty() return self.m_bDirty end
function CMarketStall:GetRoleID() return self.m_nRoleID end
function CMarketStall:GetGridNum() return self.m_nStallGrid end
function CMarketStall:GetUnlockGridNum() return self.m_nStallUnlockGrid end
function CMarketStall:GetOnSaleGridNum() return #self.m_tStallItemMap end

function CMarketStall:GetForbidState()
	return self.m_bForbid, self.m_nForbidTime, self.m_nForbidReason
end

function CMarketStall:SetForbidState(bForbid, nForbidTime, nForbidReason)
	self.m_bForbid = bForbid
	self.m_nForbidTime = nForbidTime
	self.m_nForbidReason = nForbidReason
end

--更新禁止交易数据，检查是否有到期
function CMarketStall:UpdateForbidState(nTimeStamp)
	if not self.m_bForbid then
		return
	end
	if not nTimeStamp then
		nTimeStamp = os.time()
	end
	if self.m_nForbidTime < nTimeStamp then
		self.m_bForbid = false
		self.m_nForbidTime = 0
		self.m_nForbidReason = 0
	end
end

function CMarketStall:CreateNewItem(nItemID, tPropData)
	local oItem = CMarketItem:new(self, nItemID, tPropData)
	-- oItem.m_nItemID = nItemID
	return oItem
end

--将交易物品插入到玩家摊位
function CMarketStall:InsertItem(oMarketItem)
	self.m_tStallItemMap[#self.m_tStallItemMap + 1] = oMarketItem
end

--上架销售
function CMarketStall:OnSale(oMarketItem, nItemNum, nCurrType, nPrice, nAddTime, nSaleTime)
	if oMarketItem:GetItemID() <= 0 then
		return false
	end
	oMarketItem.m_nRemainNum = nItemNum	
	oMarketItem.m_nCurrType = nCurrType
	oMarketItem.m_nPrice = nPrice
	--local nTimeStamp = os.time()
	oMarketItem.m_nAddTime = nAddTime
	oMarketItem.m_nExpiryTime = nAddTime + nSaleTime
	oMarketItem.m_nState = gtMarketItemState.eSelling
	oMarketItem.m_nPrivateKey = self:GetNewKey()
	self:InsertItem(oMarketItem)
	self.m_bTradeActive = true
	self:MarkDirty(true)
	return true
end

--下架商品，只是设置状态为下架
function CMarketStall:RemoveSale(nPKey, nState)
	if not nState then
		nState = gtMarketItemState.eRemove
	end
	local oItem = self:GetItemByPKey(nPKey)
	if not oItem then
		return
	end
	oItem:SetTradeState(nState)
	oItem:SetGlobalKey(0)
	self:UpdateActiveState()
	self:MarkDirty(true)
	return true
end

--从交易摊位移除
function CMarketStall:RemoveFromStallGrid(nPKey)
	local oItem = self:GetItemByPKey(nPKey)
	if not oItem then
		return
	end
	local nGridID = self:GetStallGridByPKey(nPKey)
	if not nGridID then 
		return
	end
	table.remove(self.m_tStallItemMap, nGridID)
	self:UpdateActiveState()
	self:MarkDirty(true)
end

--查找当前Pkey对应物品所在的摊位格子
function CMarketStall:GetStallGridByPKey(nPKey)
	for nGrid, oItem in ipairs(self.m_tStallItemMap) do
		if oItem:GetPrivateKey() == nPKey then 
			return nGrid
		end
	end
end

--根据privateKey获取交易物品
function CMarketStall:GetItemByPKey(nPKey)
	for nGrid, oItem in ipairs(self.m_tStallItemMap) do
		if oItem:GetPrivateKey() == nPKey then 
			return oItem
		end
	end
end

--检查是否可以上架新的物品
function CMarketStall:CheckCanSaleNewItem()
	-- local nOnSale = self:GetOnSaleGridNum()
	-- local nGridNum = self:GetGridNum()
	-- return nOnSale < nGridNum
	return self:GetEmptyGridNum() > 0 
end

function CMarketStall:GetEmptyGridNum()
	local nOnSale = self:GetOnSaleGridNum()
	local nGridNum = self:GetGridNum()
	return math.max(nGridNum - nOnSale, 0)
end


--检查是否可继续解锁，并且返回解锁价格
function CMarketStall:CheckCanUnlockGrid()
	local nUnlockNum = self:GetUnlockGridNum()
	if nUnlockNum < gnMarketStallGridNumUnlockMax then
		return true, (40 + 4*nUnlockNum)
	end
	return false, 0
end

--解锁格子
function CMarketStall:UnlockTradeGrid(nNum)
	if not nNum or nNum <= 0 then
		return
	end
	if self.m_nStallUnlockGrid + nNum > gnMarketStallGridNumUnlockMax then
		return
	end
	self.m_nStallGrid = self.m_nStallGrid + nNum
	self.m_nStallUnlockGrid = self.m_nStallUnlockGrid + nNum
	self:MarkDirty(true)
end

--获取当前摊位商品数据，返回的是protobuf协议数据
function CMarketStall:GetStallData()
	--[[
	// 玩家摊位数据响应
	message MarketStallDataRet
	{

		repeated MarketStallItemDetail tItemList = 1; // 当前摊位售卖物品列表
		required int32 nGridNum = 2; // 当前总的交易格子
		required int32 nGridUnlockNum = 3; // 当前花钱开启的交易格子数量
		required int32 nRemainUnlockGrid = 4;    // 剩余可解锁交易格子
		optional int32 nUnlockGridCost = 5; // 解锁花费
	}
	]]
	local tData = {}
	tData.nGridNum = self:GetGridNum()
	tData.nGridUnlockNum = self:GetUnlockGridNum()
	tData.nRemainUnlockGrid = 0
	if gnMarketStallGridNumUnlockMax > self.m_nStallUnlockGrid then
		tData.nRemainUnlockGrid = gnMarketStallGridNumUnlockMax - self.m_nStallUnlockGrid
		local bUnlock, nUnlockCost = self:CheckCanUnlockGrid()
		assert(bUnlock, "数据出错") --正常都应为true
		tData.nUnlockGridCost = nUnlockCost
	end
	tData.tItemList = {}
	for k, oItem in ipairs(self.m_tStallItemMap) do
		tData.tItemList[#tData.tItemList + 1] = oItem:GetCSData()
	end
	return tData
end



