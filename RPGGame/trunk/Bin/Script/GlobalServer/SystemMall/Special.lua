--特惠
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
function CSpecial:Ctor(model)
	self.m_oModule = model
	self.m_tPlayerShop = {} --  self.m_tPlayerShop[RoleId] = {self.m_tShopList}
	self.m_tUpdateNum = {}
	self.m_nResetTime = 0
	self.m_nRebate = 10
end

function CSpecial:LoadData(tData)
	self.m_tPlayerShop = tData.m_tPlayerShop
	self.m_tUpdateNum =  tData.m_tUpdateNum
	self.m_nResetTime = tData.m_nResetTime
end

function CSpecial:SaveData()
	local tData = {}
	tData.m_tPlayerShop = self.m_tPlayerShop
	tData.m_tUpdateNum = self.m_tUpdateNum
	tData.m_nResetTime =  self.m_nResetTime
	return tData
end

function CSpecial:MarkDirty(bMark)
	self.m_oModule:MarkDirty(bMark)
end

function CSpecial:ZeroUpdate()
	if not os.IsSameDay(self.m_nResetTime, os.time(), 0) then
		self.m_tPlayerShop = {}
		self.m_tUpdateNum = {}
		self.m_nResetTime = os.time()
		self:MarkDirty(true)
	end
end

function CSpecial:FindShop(tList, nID)
	for i =1, #tList, 1 do
		if tList[i].nID == nID then
			return tList[i]
		end
	end
end

--检查购买的商品件数
function CSpecial:CheckBuyNum(tShopList)
	local nCount = 0
	for i = 1, #tShopList, 1 do
		if tShopList[i].nRemainNum == self:GetShopInfo(tShopList[i].nID).nLimNum then
			nCount = nCount + 1
			if nCount == 4 then
				return nCount 
			end
		end
	end
end

function CSpecial:UpdateReq(nShopType, oRole)
	--初始化
	local nTem 
	local nFlag = false
	local tList = {}
	--检测免费刷
	if not self.m_tUpdateNum[oRole:GetID()] or self:CheckBuyNum(self.m_tPlayerShop[oRole:GetID()]) == 4 then
		nFlag = true
		nTem = true
	else
		if self.m_tUpdateNum[oRole:GetID()].nNum == 10 then
			return oRole:Tips("今日刷新次数已达上限")
		end
		local tCost = ctShopConf[401].tRefreshPrice[1][2](self.m_tUpdateNum[oRole:GetID()].nNum)
	    tList[#tList+1] = {nType = gtItemType.eCurr, nID = gtCurrType.eJinBi, nNum = tCost}
	end

	local fnFlushCostCallBack = function (bRet)
		if not bRet then
			oRole:Tips("金币不足,无法刷新")
			return
		end
		if not self.m_tUpdateNum[oRole:GetID()] then
		 	self.m_tUpdateNum[oRole:GetID()] = {nNum = 0}
		end

		self.m_tUpdateNum[oRole:GetID()].nNum = self.m_tUpdateNum[oRole:GetID()].nNum + 1

		local nUpdatePrice = ctShopConf[401].tRefreshPrice[1][2](self.m_tUpdateNum[oRole:GetID()].nNum)
		local nUpdateCount = ctShopConf[401].nRefreshLim - self.m_tUpdateNum[oRole:GetID()].nNum
		local tItemList = self:RandomShop(oRole)
		 local tMsg = {tList =tItemList, nShopType = nShopType, nUpdatePrice = nUpdatePrice, nUpdateCount = nUpdateCount, }
		oRole:SendMsg("SystemMallShopListRet", tMsg)
	end

	--优先使用免费刷新
	if nFlag then
		if not self.m_tUpdateNum[oRole:GetID()] then
			 self.m_tUpdateNum[oRole:GetID()] = {nNum = 0}
		end
		if self:CheckBuyNum(self.m_tPlayerShop[oRole:GetID()]) ~= 4 then
			self.m_tUpdateNum[oRole:GetID()].nNum = self.m_tUpdateNum[oRole:GetID()].nNum + 1
		end

		local nUpdatePrice = ctShopConf[401].tRefreshPrice[1][2](self.m_tUpdateNum[oRole:GetID()].nNum)
		local nUpdateCount = ctShopConf[401].nRefreshLim - self.m_tUpdateNum[oRole:GetID()].nNum
		local tItemList = self:RandomShop(oRole)
		local tMsg = {tList =tItemList, nShopType = nShopType, nUpdatePrice = nUpdatePrice, nUpdateCount = nUpdateCount, }
		oRole:SendMsg("SystemMallShopListRet", tMsg)
	else
		oRole:SubItem(tList, "特惠消耗", fnFlushCostCallBack)
	end
end

--购买请求
function CSpecial:BuyReq(nShopType, nID, nNum, oRole)
	if not oRole:IsSysOpen(18, true) then
		return
	end
	if nNum < 1 then
		oRole:Tips("请选择商品数量")
	end
	if not ctPropConf[nID] then
		return oRole:Tips("商品不存在")
	end
	if not self.m_tPlayerShop[oRole:GetID()] then
		self:RandomShop(oRole)
	end
	local tShopCfg = self:GetShopInfo(nID)
	if not tShopCfg then return end
	local fnGetOverFoldNumCallBack = function (nOverNum)
		if not nOverNum then return end
		if nOverNum < nNum then return oRole:Tips("背包空间不足,清理后再买") end
		--限购商品
		if self:GetShopInfo(nID).nLimNum ~= -1 then
			local nRemainNum = -1
			if self.m_tPlayerShop[oRole:GetID()] and self:FindShop(self.m_tPlayerShop[oRole:GetID()], nID) then
				nRemainNum = self:GetShopInfo(nID).nLimNum - self:FindShop(self.m_tPlayerShop[oRole:GetID()], nID).nRemainNum
			else
				nRemainNum = self:GetShopInfo(nID).nLimNum
			end
			if nRemainNum < nNum then
				return oRole:Tips("剩余商品不足")
			end
		end

		if self:GetShopInfo(nID).bUpFrame == 0 then
			oRole:Tips("商品未上架")
		end 

		local tItemList = {}
		tItemList[#tItemList+1] = {nType = gtItemType.eCurr, nID = self:GetShopInfo(nID).nMoneyType,
		nNum = nNum*self:GetShopInfo(nID).nNeedNum * (self:GetShop(self.m_tPlayerShop[oRole:GetID()],nID).nRebate/10)}

		local fnFlushCostCallBack = function (bRet)
			if not bRet then
				oRole:Tips("货币不足")
				return
			end

			---@tItemList {{nType=0,nID=0,nNum=0,bBind=false,tPropExt={}},...}
			local tList = {}
			tList[#tList+1] = {nType =gtItemType.eProp, nID = nID, nNum = nNum, bBind = false,tPropExt= {} }
			oRole:AddItem(tList, "特惠商城购买获得")
			--记录购买次数
			local tShop
			if self:GetShopInfo(nID).nLimNum ~= -1 then
				print("限购商品，记录个数---")
				tShop = self:FindShop(self.m_tPlayerShop[oRole:GetID()], nID)
				tShop.nRemainNum = tShop.nRemainNum + nNum
				self.m_nResetTime = os.time()
			end

			--购买完大于四件商品时,免费刷新商品
			local nFlag = false
			if self:CheckBuyNum(self.m_tPlayerShop[oRole:GetID()]) == 4 then
				nFlag = true
			end

			local nRemainNum = 0
			if tShop then
				nRemainNum = math.max(0, self:GetShopInfo(nID).nLimNum - tShop.nRemainNum) 
			end
			self:MarkDirty(true)
			local tMsg = {}
			tMsg.nID = nID
			tMsg.bFreeUpdate = nFlag
			tMsg.nNum = nNum
			tMsg.nRemainNum = nRemainNum
			oRole:SendMsg("SystemMalluyRet", tMsg)
		end
		oRole:SubItem(tItemList, "商城购买消耗", fnFlushCostCallBack)
	end
	oRole:KnapsackRemainCapacity(nID, false, fnGetOverFoldNumCallBack, tShopCfg.nBagType)
end

function CSpecial:GetShopInfo(nID)
	for _, tShop in pairs(ctShopItem) do
		if tShop.nID == nID then
			return tShop
		end
	end
end

function CSpecial:GetShop(tShopList, nID)
	if not tShopList then return end
	for i =1, #tShopList, 1 do
		if tShopList[i].nID == nID then
			return tShopList[i]
		end
	end
end
function CSpecial:RandomShop(oRole)
	nRebate = math.random(1,9)
	local nWeights = 0
	local tItemListS = {}
	local tItemList = {}
	local tShopList = {}
	local tmpMap = {}
	for _, tShop in pairs(ctShopItem) do
		if tShop.nShopType == 401 then
			tItemListS[#tItemListS+1] = tShop
		end
	end

	 for i = 1, 6, 1 do
        local ttlValue = 0
        for _, v in pairs(tItemListS) do
            if not tmpMap[v.nID] then
                ttlValue = ttlValue + v.nWeight
            end
        end
        local rdValue = math.random(1, ttlValue)
        local curValue = 0
        for _, v in pairs(tItemListS) do
            if not tmpMap[v.nID] then
                curValue = curValue + v.nWeight
                if curValue >= rdValue then
                    tItemList[#tItemList+1] = {nID = v.nID, nRemainNum =0, nRebate = nRebate}
       				tShopList[#tShopList+1] = {nID = v.nID, nRemainNum =v.nLimNum, nRebate = nRebate, nIndex = v.nIndex}
                    tmpMap[v.nID] = true
                    break
                end
            end
        end
    end
	self.m_tPlayerShop[oRole:GetID()] = tItemList
	self:MarkDirty(true)
	return tShopList
end
 

--物品列表请求
function CSpecial:ItemListReq(nShopType, oRole)
	if not oRole:IsSysOpen(18, true) then
		return
	end
	local tItemList
	local nUpdateCount = 0
	local nUpdatePrice = 0
	if not self.m_tPlayerShop[oRole:GetID()] then
	 	tItemList = self:RandomShop(oRole)
	 	nUpdateCount = ctShopConf[401].nRefreshLim
	 	nUpdatePrice = 0
	else
		local tList = self.m_tPlayerShop[oRole:GetID()]
		if not tList then
			return		end
		tItemList = {}
		for i=1, #tList, 1 do
			local nRemainNum = 0
			nRemainNum = self:GetShopInfo(tList[i].nID).nLimNum - tList[i].nRemainNum
			tItemList[#tItemList+1] = {nID = tList[i].nID, nRemainNum = nRemainNum, nRebate = tList[i].nRebate, nIndex = self:GetShopInfo(tList[i].nID).nIndex}
			if not self.m_tUpdateNum[oRole:GetID()] then
				nUpdateCount =  ctShopConf[401].nRefreshLim
				nUpdatePrice = 0
			else
				nUpdateCount =  ctShopConf[401].nRefreshLim - self.m_tUpdateNum[oRole:GetID()].nNum
				nUpdatePrice = ctShopConf[401].tRefreshPrice[1][2](self.m_tUpdateNum[oRole:GetID()].nNum)
			end
		end
	end
	if self:CheckBuyNum(self.m_tPlayerShop[oRole:GetID()]) == 4 then
		nUpdatePrice = 0
	end
	local tMsg = {tList = tItemList, nShopType = nShopType, nUpdateCount= nUpdateCount, nUpdatePrice = nUpdatePrice, nTradeMenuId = 0,}
	oRole:SendMsg("SystemMallShopListRet", tMsg)
end
