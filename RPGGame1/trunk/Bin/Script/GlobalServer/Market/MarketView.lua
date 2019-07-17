--玩家交易刷新数据
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--浏览的具体商品信息
function CMarketViewItem:Ctor(nItemID)
	self.m_nItemID = 0          --物品ID
	self.m_nGKey = 0            -- 全局Key
	self.m_bSys = false         --是否为系统提供
	self.m_nRemainNum = 0       --剩余可购买数量
	self.m_nCurrType = 0        --货币类型
	self.m_nPrice = 0           --价格
	self.m_nState = 0           --当前状态
end

function CMarketViewItem:GetItemID() return self.m_nItemID end
function CMarketViewItem:GetGKey() return self.m_nGKey end

--是否系统出售
function CMarketViewItem:IsSysSale()
	return self.m_bSys
end

function CMarketViewItem:Update(oTradeItem)
	self.m_nGKey = oTradeItem:GetGlobalKey()
	--self.m_bSys = false
	self.m_nItemID = oTradeItem:GetItemID()
	self.m_nRemainNum = oTradeItem:GetRemainNum()
	self.m_nCurrType = oTradeItem:GetCurrType()
	self.m_nPrice = oTradeItem:GetPrice()
	self.m_nState = oTradeItem:GetTradeState()
end

------------------------------------------------------
--具体商品浏览页表
function CMarketViewPage:Ctor(oModul, nPageID)
	self.m_nModul = oModul
	self.m_nPageID = nPageID
	self.m_nFlushKey = 0       --标识刷新有效的Key值，默认0，不是一个有效key，即默认失效的
	self.m_tViewItemMap = {}  --{Grid : CMarketViewItem, ...}
end

--获取浏览商品
function CMarketViewPage:GetViewItem(nGKey)
	for k, oViewItem in pairs(self.m_tViewItemMap) do
		if oViewItem.m_nGKey == nGKey then
			return oViewItem
		end
	end
end

--检查商品浏览页表是否过期 true过期，false有效
function CMarketViewPage:IsExpired(nFlushKey)
	--[[
	不能根据时间戳判断，存在问题，比如某玩家在 nTimeA时刻刷新了某个物品，此时迅速发起一次刷新页表请求，此时并没有跨秒
	从而出现 nPageFlushStamp == nFlushTime，但是数据已过期
	但二者相等时，也有可能此数据也是有效的，发起页表刷新时，立即请求获取到的数据
	]]
	if self.m_nFlushKey == nFlushKey then
		return false
	end
	return true
end

--生成客户端用的商品数据
function CMarketViewPage:GetCSPageData()
	local tData = {}
	for k, oViewItem in ipairs(self.m_tViewItemMap) do
		if not oViewItem:IsSysSale() then 
			local oSaleItem = goMarketMgr:GetItemByGKey(oViewItem:GetGKey())
			if not oSaleItem or oSaleItem:GetItemID() ~= oViewItem:GetItemID() then 
				oViewItem.m_nRemainNum = 0
				if oViewItem.m_nState ~= gtMarketItemState.eSoldOut then 
					oViewItem.m_nState = gtMarketItemState.eRemove
				end
			else
				oViewItem:Update(oSaleItem)
			end
		end

		local tItemData = {}
		tItemData.nItemID = oViewItem.m_nItemID
		tItemData.nGKey = oViewItem.m_nGKey
		tItemData.nRemainNum = oViewItem.m_nRemainNum
		tItemData.nPrice = oViewItem.m_nPrice
		tItemData.nState = oViewItem.m_nState
		tData[#tData + 1] = tItemData
	end
	return tData
end


------------------------------------------------------
--玩家商品浏览数据
function CMarketView:Ctor(oModul, nRoleID)
	self.m_oModul = oModul
	self.m_nRoleID = nRoleID
	self.m_bOnline = true
	self.m_nLastFlushTime = os.time()  --刷新是全局的
	self.m_nLastViewPageID = 401  --TODO 配置的默认值
	self.m_tViewPageMap = {}     --{PageID : CMarketViewPage, ...} 
	self.m_nKeySerial = 1
	self.m_nFlushKey = 1        --用来标识刷新数据的Key值，每次自增

	self.m_nSysSaleGKeySerial = 1
end

--生成一个新的FlushKey
function CMarketView:GetNewKey()
	local nKey = self.m_nKeySerial
	if self.m_nKeySerial >= 0x7fffffff then
		self.m_nKeySerial = 1
	else
		self.m_nKeySerial = self.m_nKeySerial + 1
	end
	return nKey
end

function CMarketView:GenSysSaleGKey(nGkey) 
	assert(gnMarketGKeyBegin > 10000, "数据错误，逻辑需要改动")
	self.m_nSysSaleGKeySerial = self.m_nSysSaleGKeySerial + 1
	if self.m_nSysSaleGKeySerial >= gnMarketGKeyBegin then 
		self.m_nSysSaleGKeySerial = 1
	end
	return self.m_nSysSaleGKeySerial
end

--获取FlushKey
function CMarketView:GetFlushKey()
	return self.m_nFlushKey
end

--设置一个新的FlushKey
function CMarketView:SetNewFlushKey()
	self.m_nFlushKey = self:GetNewKey()
	self.m_nLastFlushTime = os.time()
end

--更新ViewData
function CMarketView:UpdateViewItem(nGKey, nPageID, oTradeItem)
	local oViewPage = self:GetViewPage(nPageID)
	if not oViewPage then
		print("UpdateViewItem  Sec2")
		return
	end
	local oViewItem = oViewPage:GetViewItem(nGKey)
	if not oViewItem then
		print("UpdateViewItem  Sec3")
		return
	end
	oViewItem:Update(oTradeItem)
end

-- --从活跃交易的观察者列表移除
-- function CMarketView:RemoveFromObserver()
-- 	local oMarketMgr = self.m_oModul
-- 	if not oMarketMgr then
-- 		return
-- 	end
-- 	for _, oViewPage in pairs(self.m_tViewPageMap) do
-- 		for k, oViewItem in pairs(oViewPage.m_tViewItemMap) do
-- 			local tOb = oMarketMgr.m_tTradeObserver[oViewItem.m_nGKey]
-- 			if tOb then
-- 				tOb[self.m_nRoleID] = nil
-- 			end
-- 		end
-- 	end
-- end

--获取刷新金钱消耗
function CMarketView:GetFlushCost()
	return 100  --TODO 读取配置
end

--获取页表下一次免费刷新时间
function CMarketView:GetNextFreeFlushTime()
	return self.m_nLastFlushTime + gnMarketPageFlushTime
end

function CMarketView:CheckCanFreeFlush(nTimeStamp)
	if not nTimeStamp then
		nTimeStamp = os.time()
	end
	if nTimeStamp >= self:GetNextFreeFlushTime() then
		return true
	end
	return false
end

--获取下一次免费刷新倒计时
function CMarketView:GetNextFreeFlushCountdown(nTimeStamp)
	if not nTimeStamp then
		nTimeStamp = os.time()
	end
	local nCountdown = 0
	local nNextFlushTime = self:GetNextFreeFlushTime()
	if nTimeStamp < nNextFlushTime then
		nCountdown = nNextFlushTime - nTimeStamp
	end
	return nCountdown
end

--获取上一次刷新时间
function CMarketView:GetLastFlushTime()
	return self.m_nLastFlushTime
end

--获取一个商品浏览页表
function CMarketView:GetViewPage(nPageID)
	return self.m_tViewPageMap[nPageID]
end

--是否保持活跃，即是否保留在内存
--必须所有页表已过期才可清理，防止玩家通过上下线来刷新数据
function CMarketView:IsKeepActive()
	return self.m_bOnline or not self:CheckCanFreeFlush()
end

function CMarketView:RandomSysItemByPageID(nPageID, nNum, tExceptMap)
	assert(nPageID and nNum > 0, "参数错误")
	if nPageID <= 0 then
		return	{}
	end
	tExceptMap = tExceptMap or {}
	local tConfTbl = goMarketMgr:GetTradePageConfTbl(nPageID)
	assert(tConfTbl, "获取配置表错误")
	local fnGetItemWeight = function (tItemConf) return 10 end
	local tCheckParam = {}
	tCheckParam.nPageID = nPageID
	tCheckParam.tExceptMap = tExceptMap
	tCheckParam.nServerLevel = goServerMgr:GetServerLevel(gnServerID) or 0
	local fnCheckItemValid = function(tItemConf, tCheckParam)
		-- if tItemConf.nTradeMenuId ~= tCheckParam.nPageID then
		-- 	return false 
		-- end
		if not tItemConf.bSysSale then
			return false 
		end
		-- 需求不明确，先注释了，策划表示，
		-- 既需要执行服务器等级控制，又需要刷满物品格子
		-- 之前有做排重，有玩家出售该道具的情况下，不会上架系统出售
		-- 现在加上服务器等级限制，如果做排重，如果存在道具被服务器等级限制而不能系统上架的情况
		-- 明显不可能刷满足够数量的系统出售道具
		-- if tExceptMap[tItemConf.nId] then
		-- 	return false
		-- end
		if tItemConf.nGameServerGrade > tCheckParam.nServerLevel then 
			return false
		end
		return true
	end

	local nRandNum = nNum
	local tRandResult = CWeightRandom:CheckNodeRandom(
							tConfTbl,
							fnGetItemWeight,
							nRandNum,
							false,
							fnCheckItemValid,
							tCheckParam)
	if not tRandResult then --可能该类道具无系统出售
		return {}
	end
	local tRetData = {}
	for k, v in ipairs(tRandResult) do
		table.insert(tRetData, v.nId)
	end
	return tRetData
end

--刷新浏览商品页表信息
function CMarketView:CreatePageData(nPageID, tItemList)
	if not goMarketMgr:CheckPageIDValid(nPageID) then
		print("不合法的nPageID:"..nPageID)
		return
	end	
	tItemList = tItemList or {}
	local tTempList = {}
	for nItemID, nNum in pairs(tItemList) do 
		local tConf = ctBourseItem[nItemID]
		if tConf and tConf.nTradeMenuId == nPageID then 
			tTempList[nItemID] = nNum
		end
	end
	tItemList = tTempList

	local oMarketMgr = self.m_oModul  -- goMarketMgr
	assert(oMarketMgr, "MarketView.m_oModul数据错误")
	local oActiveTradePage = oMarketMgr:GetTradePage(nPageID)
	local nActiveCount = oActiveTradePage:Count()

	local nRoleStallNum = gnMarketStallGridNumUnlockMax
	local oRoleStall = oMarketMgr:GetStall(self.m_nRoleID)
	if oRoleStall then 
		nRoleStallNum = oRoleStall:GetOnSaleGridNum()
	end

	local tData = {}
	local nRoleSaleNum = math.min(nActiveCount, gnMarketPageViewNum)
	local tSysExceptMap = {}  --系统出售屏蔽列表

	--刷新必定出现的商品
	local tGKeyRecord = {}
	for nItemID, nNum in pairs(tItemList) do 
		local oActiveItemMap = goMarketMgr:GetActiveItemMap(nItemID)
		local bSucc = false
		if oActiveItemMap and oActiveItemMap:Count() > 0 then --存在其他玩家出售的商品
			local nItemSaleCount = oActiveItemMap:Count()
			local nRandNum = math.min(nRoleStallNum + 1, nItemSaleCount)
			local tRandList, tRandMap = CUtil:RandDiffNum(1, nItemSaleCount, nRandNum)
			for nIndex, _ in pairs(tRandMap) do 
				local nGKey = oActiveItemMap:GetByDataRank(nIndex)
				local oTrade = oActiveTradePage:GetDataByKey(nGkey)
				if oTrade and oTrade:GetRoleID() ~= self.m_nRoleID then 
					local oItem = oMarketMgr:GetItemByActiveTrade(oTrade)
					if oItem then 
						local oViewItem = CMarketViewItem:new(oItem:GetItemID())
						oViewItem.m_nGKey = oItem:GetGlobalKey()
						oViewItem.m_bSys = false
						oViewItem:Update(oItem)
						table.insert(tData, oViewItem)
						tGKeyRecord[oItem:GetGlobalKey()] = true
						tSysExceptMap[nItemID] = true
						bSucc = true
						break --只随机一个
					else
						LuaTrace("逻辑错误！物品不存在, nGkey:"..nGKey, "oTrade:", oTrade)
						LuaTrace(debug.traceback())
					end
				end
			end
		end
		if not bSucc then --不存在玩家出售的商品，或者前面没有随机到非玩家本人出售的商品
			local oViewItem = CMarketViewItem:new(nItemID)
			local tConf = goMarketMgr:GetItemConf(nItemID)
			assert(tConf, "商品配置不存在")
			local nPriceRatio = math.random(tConf.nSysMinSaleRatio, tConf.nSysMaxSaleRatio)
			nPriceRatio = math.floor(nPriceRatio / 1000)
			nPriceRatio = nPriceRatio * 1000

			--维护一个针对玩家的独立的系统出售商品GKey，防止快速将全局GKey消耗完
			--玩家出售商品全局GKey从 gnMarketGKeyBegin 开始
			--gnMarketGKeyBegin 以下的全部属于系统出售的
			oViewItem.m_nGKey = self:GenSysSaleGKey() 
			oViewItem.m_nItemID = nItemID
			oViewItem.m_bSys = true
			oViewItem.m_nRemainNum = 1
			oViewItem.m_nCurrType = gtCurrType.eYinBi
			oViewItem.m_nPrice = goMarketMgr:GetItemPrice(nItemID, nPriceRatio)
			oViewItem.m_nState = gtMarketItemState.eSelling
			table.insert(tData, oViewItem)
		end

		if #tData >= gnMarketPageViewNum then 
			break 
		end
	end

	--随机刷新剩余需要刷新的道具
	if nRoleSaleNum > 0 then
		--当前可选择数量，可能小于nRoleSaleNum, 比如存在玩家自己出售的道具
		--选出最多gnMarketPageViewNum + nRoleStallNum数量的商品
		local tRandList, tRandMap = CUtil:RandDiffNum(1, nActiveCount, 
			math.min(gnMarketPageViewNum + nRoleStallNum, nActiveCount))

		for nIndex, _ in pairs(tRandMap) do 
			local nGKey, oTrade = oActiveTradePage:GetByDataRank(nIndex)
			--非玩家自己出售的，并且没被刷新到
			if oTrade and oTrade:GetRoleID() ~= self.m_nRoleID and not tGKeyRecord[nGkey] then 
				local oItem = oMarketMgr:GetItemByActiveTrade(oTrade)
				if oItem then 
					local oViewItem = CMarketViewItem:new(oItem:GetItemID())
					oViewItem.m_nGKey = oItem:GetGlobalKey()
					oViewItem.m_bSys = false
					oViewItem:Update(oItem)
					tSysExceptMap[oItem:GetItemID()] = true
					table.insert(tData, oViewItem)
					if #tData >= gnMarketPageViewNum then 
						break 
					end
				else
					LuaTrace("逻辑错误！物品不存在, nGkey:"..nGKey, "oTrade:", oTrade)
					LuaTrace(debug.traceback())
				end
			end
		end
	end

	local nSysSaleNum = gnMarketPageViewNum - #tData
	if nSysSaleNum > 0 then
		local bFlushSysSale = false
		local tConfTbl = goMarketMgr:GetTradePageConfTbl(nPageID)
		for k, tConf in pairs(tConfTbl) do
			if tConf.nTradeMenuId == nPageID and tConf.bSysSale then
				-- if not tSysExceptMap[tConf.nId] then
				-- 	bFlushSysSale = true
				-- 	break
				-- end
				bFlushSysSale = true
				break
			end
		end
		if bFlushSysSale then  --策划要求，全部填充满8个道具
			local tSysItemList = self:RandomSysItemByPageID(nPageID, nSysSaleNum, tSysExceptMap)
			assert(tSysItemList, "系统出售物品生成结果错误")
			for k, nSysItemID in ipairs(tSysItemList) do 
				local oViewItem = CMarketViewItem:new(nSysItemID)
				--系统出售的，不添加到活跃交易列表，但也需要加上GKey,用于在玩家发起购买请求时，确定该玩家是否有浏览刷新到此物品
				--[[
				self.m_nItemID = 0          --物品ID
				self.m_nGKey = 0            -- 全局Key
				self.m_bSys = false         --是否为系统提供
				self.m_nRemainNum = 0       --剩余可购买数量
				self.m_nCurrType = 0        --货币类型
				self.m_nPrice = 0           --价格
				self.m_nState = 0           --当前状态
				]]
				local tConf = goMarketMgr:GetItemConf(nSysItemID)
				assert(tConf, "商品配置不存在")
				local nPriceRatio = math.random(tConf.nSysMinSaleRatio, tConf.nSysMaxSaleRatio)
				nPriceRatio = math.floor(nPriceRatio / 1000)
				nPriceRatio = nPriceRatio * 1000

				--维护一个针对玩家的独立的系统出售商品GKey，防止快速将全局GKey消耗完
				--玩家出售商品全局GKey从 gnMarketGKeyBegin 开始
				--gnMarketGKeyBegin 以下的全部属于系统出售的
				oViewItem.m_nGKey = self:GenSysSaleGKey() 
				oViewItem.m_nItemID = nSysItemID
				oViewItem.m_bSys = true
				oViewItem.m_nRemainNum = 1
				oViewItem.m_nCurrType = gtCurrType.eYinBi
				oViewItem.m_nPrice = goMarketMgr:GetItemPrice(nSysItemID, nPriceRatio)
				oViewItem.m_nState = gtMarketItemState.eSelling
				table.insert(tData, oViewItem)
			end
		end
	end
	--TODO 排序处理
	return tData
end

--获取浏览刷新CS数据
function CMarketView:GetCSFlushData()
	--[[
	// 交易页表刷新数据
	message MarketViewPageFlushData
	{
		required int32 nNextFreeFlushTime = 1; // 下一次免费刷新时间
		required int32 nNextFreeFlushCountdown = 2;     // 免费刷新倒计时
		required int32 nMoneyCost = 3; // 使用金钱刷新需要消耗的数量
	}
	]]
	local tData = {}
	tData.nNextFreeFlushTime = self:GetNextFreeFlushTime()
	tData.nNextFreeFlushCountdown = self:GetNextFreeFlushCountdown()
	tData.nMoneyCost = self:GetFlushCost()
	return tData
end

function CMarketView:CreateViewPage(nPageID)
	if not goMarketMgr:CheckPageIDValid(nPageID) then
		return
	end
	local oViewPage = CMarketViewPage:new(self, nPageID)
	assert(oViewPage, "创建商品浏览页表失败")
	--oViewPage.m_nFlushKey = self:GetFlushKey() --这里不设置，会导致后续逻辑把这个初始Page当成一个未过期的Page，不能正常刷新
	return oViewPage
end

function CMarketView:FlushViewPageData(nPageID, tItemList)
	local oViewPage = self:GetViewPage(nPageID)	
	assert(oViewPage, "创建商品浏览页表失败")
	local tViewData = self:CreatePageData(nPageID, tItemList)
	assert(tViewData, "创建商品页浏览数据出错")
	print("商品页浏览数据", tViewData)
	oViewPage.m_tViewItemMap = tViewData
	oViewPage.m_nFlushKey = self:GetFlushKey()
	return oViewPage
end

--获取商品浏览页表信息
function CMarketView:GetPageData(nPageID, tItemList)
	if not goMarketMgr:CheckPageIDValid(nPageID) then
		return
	end
	local oViewPage = self:GetViewPage(nPageID)	
	if not oViewPage then
		oViewPage = self:CreateViewPage(nPageID)
		assert(oViewPage, "创建商品浏览页表失败")
		self.m_tViewPageMap[nPageID] = oViewPage
	end
	if oViewPage:IsExpired(self:GetFlushKey()) then
		self:FlushViewPageData(nPageID, tItemList)
	end
	self.m_nLastViewPageID = nPageID
	local tData = oViewPage:GetCSPageData()
	if not tData then
		return
	end

	local tRetData = {}
	tRetData.nPageID = nPageID
	tRetData.tFlushData = self:GetCSFlushData()
	tRetData.tItemList = oViewPage:GetCSPageData()
	return tRetData
end

--新刷新整个商品列表
function  CMarketView:FlushPage()
	-- self:RemoveFromObserver() --先从之前的监听商品列表删除
	--self.m_nLastFlushTime = os.time()
	self:SetNewFlushKey()
	self.m_tViewPageMap = {}  --引用空table
end


