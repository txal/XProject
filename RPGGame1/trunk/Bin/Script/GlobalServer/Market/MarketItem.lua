--交易物品对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CMarketItem:Ctor(oModul, nItemID, tPropData)
	assert(nItemID, "参数错误")
	self.m_oModul = oModul
	self.m_nItemID = nItemID         --道具ID
	self.m_tPropData = tPropData
	self.m_nPrivateKey = 0           --玩家私有交易Key
	self.m_nGlobalKey = 0            --Market全局Key，状态变化时，用来快速查找更新全局数据
	self.m_nState = 0                --道具交易状态
	self.m_nCurrType = 0             --货币类型
	self.m_nPrice = 0                --单价
	self.m_nAddTime = 0              --上架时间
	self.m_nExpiryTime = 0           --过期时间
	self.m_nRemainNum = 0            --剩余数量
	self.m_nSoldNum = 0              --已售出数量
	self.m_nDrawNum = 0              --已提取售款的商品数量
	--self.m_nDisplayCount = 0         --当前被展示给其他玩家的计数
	--self.m_nTotalDisplayCount = 0    --上架期间，当前被展示总计数
	--self.m_nDisplayWeight = 0        --展示权重
end

function CMarketItem:LoadData(tData)
	if not tData then
		return
	end
	self.m_nItemID = tData.nItemID
	self.m_tPropData = tData.tPropData
	self.m_nCurrType = tData.nCurrType
	self.m_nPrice = tData.nPrice
	self.m_nAddTime = tData.nAddTime
	self.m_nExpiryTime = tData.nExpiryTime
	self.m_nRemainNum = tData.nRemainNum
	self.m_nSoldNum = tData.nSoldNum
	self.m_nDrawNum = tData.nDrawNum
	self.m_nState = tData.nState
	--self.m_nTotalDisplayCount = tData.nTotalDisplayCount

	if self.m_nRemainNum <= 0 then
		self.m_nState = gtMarketItemState.eSoldOut
	else
		local nTimeStamp = os.time()
		if self.m_nExpiryTime <= nTimeStamp or self.m_nAddTime > nTimeStamp then
			self.m_nState = gtMarketItemState.eRemove
		else
			self.m_nState = gtMarketItemState.eSelling
		end
	end	

end

function CMarketItem:SaveData()
	local tData = {}
	tData.nItemID = self.m_nItemID
	tData.tPropData = self.m_tPropData
	tData.nCurrType = self.m_nCurrType
	tData.nPrice =  self.m_nPrice
	tData.nAddTime = self.m_nAddTime
	tData.nExpiryTime = self.m_nExpiryTime
	tData.nRemainNum = self.m_nRemainNum
	tData.nSoldNum = self.m_nSoldNum
	tData.nDrawNum = self.m_nDrawNum
	tData.nState = self.m_nState
	--tData.nTotalDisplayCount = self.m_nTotalDisplayCount
	return tData
end

function CMarketItem:GetItemID() return self.m_nItemID end
function CMarketItem:GetPrivateKey() return self.m_nPrivateKey end
function CMarketItem:GetGlobalKey() return self.m_nGlobalKey end
function CMarketItem:SetGlobalKey(nGKey) self.m_nGlobalKey = nGKey end
function CMarketItem:GetExpiryTime() return self.m_nExpiryTime end
function CMarketItem:GetExpiryCountdown(nTimeStamp)
	if not nTimeStamp then
		nTimeStamp = os.time()
	end
	local nCountdown = 0
	local nExpiry = self:GetExpiryTime()
	if nTimeStamp < nExpiry then
		nCountdown = nExpiry - nTimeStamp
	end
	return nCountdown
end

--function CMarketItem:GetDisplayWeight() return self.m_nDisplayWeight end
function CMarketItem:GetTradeState() return self.m_nState end
function CMarketItem:SetTradeState(nState) self.m_nState = nState end
function CMarketItem:CheckExpiry(nTimeStamp) return nTimeStamp >= self.m_nExpiryTime end
function CMarketItem:IsActive() return self.m_nState == gtMarketItemState.eSelling end
function CMarketItem:GetRemainNum() return self.m_nRemainNum end
function CMarketItem:GetCurrType() return self.m_nCurrType end
function CMarketItem:GetPrice() return self.m_nPrice end
function CMarketItem:GetSoldNum() return self.m_nSoldNum end
function CMarketItem:GetDrawNum() return self.m_nDrawNum end
--返回深拷贝数据，外部会使用修改此数据
function CMarketItem:GetPropData() 
	if self.m_tPropData then --兼容旧数据
		local tPropData = table.DeepCopy(self.m_tPropData)
		return tPropData
	end 
end 
function CMarketItem:SubSoldNum(nNum) 
	assert(nNum > 0 or nNum > self.m_nRemainNum, "参数错误")
	self.m_nRemainNum = self.m_nRemainNum - nNum
	self.m_nSoldNum = self.m_nSoldNum + nNum
	if self.m_tPropData then 
		self.m_tPropData.m_nFold = self.m_tPropData.m_nFold - nNum
	end
end

--function CMarketItem:UpdateDisplayWeight() end
function CMarketItem:GetCSData()
	--[[
	// 玩家摊位售卖商品详细数据
	message MarketStallItemDetail
	{
		required int32 nItemID = 1;  // 商品ID
		required int32 nPKey = 2;    // 商品私有Key
		required int32 nState = 3;   // 商品交易状态
		required int32 nPrice = 4;   // 商品出售价格
		required int32 nExpiryTime = 5; // 商品下架时间
		required int32 nExpiryCountdown = 6; // 商品下架倒计时
		required int32 nRemainNum = 7;  // 商品剩余未售出数量
		required int32 nSoldNum = 8;    // 已售出数量
		required int32 nDrawNum = 9;    // 已提现数量
	}
	]]
	local tData = {}
	tData.nItemID = self:GetItemID()
	tData.nPKey = self:GetPrivateKey()
	tData.nState = self:GetTradeState()
	tData.nPrice = self:GetPrice()
	tData.nExpiryTime = self:GetExpiryTime()
	tData.nExpiryCountdown = self:GetExpiryCountdown()
	tData.nRemainNum = self:GetRemainNum()
	tData.nSoldNum = self:GetSoldNum()
	tData.nDrawNum = self:GetDrawNum()
	return tData
end


