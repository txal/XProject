--商城系统
local nMaxAddOnce = 5000 	--一次最多加道具数
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
function CShop:Ctor(model)
	self.m_oModule = model
	self.m_tAllreadyBuy = {} -- self.m_tAllreadyBuy[RoleId] = {[Id] = {Id = Id, nNum = nNum}}
	self.m_tFirstBuyTime = {}

	-- 1 日限购 ，2 周限购 ，3 月限购 , 4一生只能买一次
	for nLimBuyType=1, 4 do
		self.m_tAllreadyBuy[nLimBuyType] = {} --[nID] = nNum 日(周/月)限购物品 已购买的
		self.m_tFirstBuyTime[nLimBuyType] = 0 --日(周/月)限购 第一次购买时间
	end
end

function CShop:LoadData(tData)
	self.m_tAllreadyBuy = tData.m_tAllreadyBuy or {}
	self.m_tFirstBuyTime = tData.m_tFirstBuyTime or {}
	self:InitPurchseLimitType()
end

function CShop:SaveData()
	print("保存商城数据")
	local tData = {}
	tData.m_tAllreadyBuy = self.m_tAllreadyBuy
	tData.m_tFirstBuyTime = self.m_tFirstBuyTime
	return tData
end

--初始化限购类型
function CShop:InitPurchseLimitType()
	local bMarkDirty = false
	for _, tShop in pairs(ctShopItem) do
		if tShop.nLimBuyType > 0 then
			if not self.m_tAllreadyBuy[tShop.nLimBuyType] then
				self.m_tAllreadyBuy[tShop.nLimBuyType] = {}
				bMarkDirty = true
			end
		end
	end
	if bMarkDirty then
		self:MarkDirty(bMarkDirty)
	end
end

function CShop:MarkDirty(bMark)
	self.m_oModule:MarkDirty(bMark)
end

function CShop:GetShopInfo(nID, nShopSubType)
	for _, tShop in pairs(ctShopItem) do
		if tShop.nID == nID and tShop.nShopType == nShopSubType then
			return tShop
		end
	end
end

--重置限购
function CShop:ZeroUpdate()
	if self.m_tFirstBuyTime[1]~=0 and not os.IsSameDay( os.time() , self.m_tFirstBuyTime[1] , 0 )  then --每天限购 不是同一天且已经购买过
		self.m_tAllreadyBuy[1] = {}
		self.m_tFirstBuyTime[1] = 0
		self:MarkDirty(true)
	end

	if self.m_tFirstBuyTime[2]~=0 and not os.IsSameWeek( os.time() , self.m_tFirstBuyTime[2] , 0 )  then --每周限购
		self.m_tAllreadyBuy[2] = {}
		self.m_tFirstBuyTime[2] = 0
		self:MarkDirty(true)
	end

	if self.m_tFirstBuyTime[3]~=0 and not os.IsSameMonth( os.time() , self.m_tFirstBuyTime[3] , 0 ) then --每月限购
		self.m_tAllreadyBuy[3] = {}
		self.m_tFirstBuyTime[3] = 0
		self:MarkDirty(true)
	end
end

--物品列表请求
function CShop:ItemListReq(nShopType, oRole, nTradeMenuId)
	if not oRole:IsSysOpen(18, true) then
		return
	end
	local tMsg = {}
	tMsg.tList = {}
	tMsg.nTradeMenuId = nTradeMenuId
	tMsg.nShopType = nShopType
	local tList = {}
	for nKey, tConf in pairs(ctShopItem) do
		if tConf.nShopType == nTradeMenuId then
			local nLimNum = -1
			if tConf.nLimNum ~= -1 then
				--限购商品
				if self.m_tAllreadyBuy[tConf.nLimBuyType] and self.m_tAllreadyBuy[tConf.nLimBuyType][oRole:GetID()] and self.m_tAllreadyBuy[tConf.nLimBuyType][oRole:GetID()][tConf.nID] then
					nLimNum = tConf.nLimNum - self.m_tAllreadyBuy[tConf.nLimBuyType][oRole:GetID()][tConf.nID].nNum
				else
					nLimNum = tConf.nLimNum
				end
			end
			tMsg.tList[#tMsg.tList+1] = {nID = tConf.nID,nRemainNum = nLimNum, nRebate = tConf.nDiscountStr, nIndex =tConf.nIndex }
		end
	end
	oRole:SendMsg("SystemMallShopListRet", tMsg)
end

--购买请求
function CShop:BuyReq(nShopType, nID, nNum, oRole, nShopSubType)
	print("BuyReq***", nShopType, nID, nNum, nShopSubType)
	if not oRole:IsSysOpen(18, true) then
		return
	end

	local nBuyNum = nNum
	if nNum == 0 then
	 return oRole:Tips("购买数量数不能小于1")
	end
	local tProp = self:GetShopInfo(nID, nShopSubType) 
	if not tProp then
		return oRole:Tips("商店没有此商品")
	end
	
	if not self:GetShopInfo(nID, nShopSubType).bUpFrame then
		return oRole:Tips("商品未上架")
	end
	if nMaxAddOnce < nNum then return oRole:Tips("单次最多买" .. nMaxAddOnce .. "份") end
	local fnGetOverFoldNumCallBack = function (nOverNum)
		if not nOverNum then return  end
		if nOverNum < nNum then
			return oRole:Tips("背包空间不足,清理再买")
		end
		local nPlayerID = oRole:GetID()
		if self:GetShopInfo(nID, nShopSubType).nLimNum ~= -1 then
			local nLimNum = 0
			if self.m_tAllreadyBuy[self:GetShopInfo(nID,nShopSubType).nLimBuyType][nPlayerID] 
				and  self.m_tAllreadyBuy[self:GetShopInfo(nID, nShopSubType).nLimBuyType][nPlayerID][nID] then
				nLimNum = self:GetShopInfo(nID, nShopSubType).nLimNum - self.m_tAllreadyBuy[self:GetShopInfo(nID, nShopSubType).nLimBuyType][nPlayerID][nID].nNum
			else
				nLimNum = self:GetShopInfo(nID, nShopSubType).nLimNum
			end
			if nLimNum < nNum then
				return oRole:Tips("商品剩余购买数量不足")
			end
		end

		local nCost = 0
		if self:GetShopInfo(nID, nShopSubType).nShopType == 204 then
			if self:GetShopInfo(nID, nShopSubType).nDiscountStr > 0 then
				nCost  = self:GetShopInfo(nID, nShopSubType).nNeedNum * (self:GetShopInfo(nID, nShopSubType).nDiscountStr/10)
			else
				nCost = self:GetShopInfo(nID, nShopSubType).nNeedNum
			end
			nCost = nCost * nNum 
		else
			nCost = self:GetShopInfo(nID, nShopSubType).nNeedNum *nNum
		end

		local tItemList = {}
		tItemList[#tItemList+1] = {nType = gtItemType.eCurr, nID = self:GetShopInfo(nID, nShopSubType).nMoneyType,nNum = nCost}
		local fnFlushCostCallBack = function (bRet)
			if not bRet then
				return 
				
			end	
			--限购商品记录
			if self:GetShopInfo(nID, nShopSubType).nLimNum ~= -1 then
				if not self.m_tAllreadyBuy[self:GetShopInfo(nID, nShopSubType).nLimBuyType][nPlayerID] then
					self.m_tAllreadyBuy[self:GetShopInfo(nID, nShopSubType).nLimBuyType][nPlayerID] = {}
				end

				if not self.m_tAllreadyBuy[self:GetShopInfo(nID, nShopSubType).nLimBuyType][nPlayerID][nID] then
					 self.m_tAllreadyBuy[self:GetShopInfo(nID, nShopSubType).nLimBuyType][nPlayerID][nID] = {nID = nID, nNum = nNum}
				else
					 self.m_tAllreadyBuy[self:GetShopInfo(nID, nShopSubType).nLimBuyType][nPlayerID][nID].nNum = 
					 self.m_tAllreadyBuy[self:GetShopInfo(nID, nShopSubType).nLimBuyType][nPlayerID][nID].nNum + nNum
				end

				if self.m_tFirstBuyTime[self:GetShopInfo(nID, nShopSubType).nLimBuyType] == 0 then
					self.m_tFirstBuyTime[self:GetShopInfo(nID, nShopSubType).nLimBuyType] = os.ZeroTime(os.time())
				end
				self:MarkDirty(true)
			end
			local nBagType = self:GetShopInfo(nID, nShopSubType).nBagType
			tItemList = {}
			tItemList[#tItemList+1] = {nType = nBagType , nID = nID,  nNum = nBuyNum, bBind = false, tPropExt = {}}
			oRole:AddItem(tItemList,"商城购买获得")
			local tMsg = {nID = nID, nNum = nNum}
			oRole:SendMsg("SystemMalluyRet", tMsg)
		end
		oRole:SubItem(tItemList, "商城购买消耗", fnFlushCostCallBack)
	end

	oRole:KnapsackRemainCapacity(nID, false, fnGetOverFoldNumCallBack, tProp.nBagType)
end
