--交易系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CMarketActiveTrade:Ctor(nGKey, nRoleID)
	self.m_nGKey = nGKey
	self.m_nRoleID = nRoleID
	self.m_nPKey = nPKey
	self.m_nItemID = 0
	self.m_nExpiryTime = 0
end

function CMarketActiveTrade:GetRoleID() return self.m_nRoleID end
function CMarketActiveTrade:GetGKey() return self.m_nGKey end
function CMarketActiveTrade:GetPKey() return self.m_nPKey end
function CMarketActiveTrade:GetItemID() return self.m_nItemID end
function CMarketActiveTrade:GetExpiryTime() return self.m_nExpiryTime end

function CMarketActiveTrade:SetByMarketItem(oMarketItem)
	self.m_nPKey = oMarketItem:GetPrivateKey()
	self.m_nItemID = oMarketItem:GetItemID()
	self.m_nExpiryTime = oMarketItem:GetExpiryTime()
end


--请注意，如果策划更改了物品ID映射的TradePage(配置表项nTradeMenuId)或者新增删除TradePage类型数据，不能热更，需要重启服务器方可更新
function CMarketMgr:Ctor()
	self.m_tRoleStallMap = {}      --玩家摊位 {nRoleID : MarketStall, ...}
    self.m_tActiveKeyMap = {}      --{GlobalKey : TradePage, ...}  快速确定分类，同时检查GlobalKey是否重复
	self.m_tActiveTradeMap = {}    --当前活跃的交易数据 {TradePage:oRBTree, ...}
	self.m_tActiveItemMap = {}     --{nItemID:oRBTree, ...}
	--读取配置表，添加所有的tradePage，初始化为空
	local tConfTbl = CMarketMgr:GetConfTbl()
	assert(tConfTbl, "配置表不存在")

	local fnTradeItemCmp = function(oTradeL, oTradeR) 
		if oTradeL.m_nExpiryTime ~= oTradeR.m_nExpiryTime then 
			return oTradeL.m_nExpiryTime < oTradeR.m_nExpiryTime and -1 or 1
		end
		if oTradeL.m_nGKey ~= oTradeR.m_nGKey then 
			return oTradeL.m_nGKey < oTradeR.m_nGKey and -1 or 1 
		end
		return 0
	end

	local fnActiveItemMapCmp = function(tDataL, tDataR) --直接比较Key
		if tDataL < tDataR then 
			return -1 
		elseif tDataL > tDataR then 
			return 1
		else
			return 0
		end
	end

	for nItemID, tConf in pairs(tConfTbl) do
		if not self.m_tActiveTradeMap[tConf.nTradeMenuId] then
			self.m_tActiveTradeMap[tConf.nTradeMenuId] = CRBTree:new(fnTradeItemCmp)
		end
		if not self.m_tActiveItemMap[nItemID] then 
			self.m_tActiveItemMap[nItemID] = CRBTree:new(fnActiveItemMapCmp)
		end
	end

	self.m_tRoleViewMap = {}       --玩家刷新数据 {RoleID : MarketView, ...}
	-- self.m_tTradeObserver = {}     --{nGKey : {nRoleID:nRoleID,...}, ...} --直接nRoleID做监听列表键值，加快修改删除速度
	self.m_nKeySerial = gnMarketGKeyBegin          --每次重启，重新生成，用来标识当前活跃交易

	self.m_tDirtyQueue = CUniqCircleQueue:new() --脏数据队列 {nRoleID:oMarketStall, ...}
	---- Save DB Debug Info -----
	self.m_nSavePrintStamp = 0     --SaveDebugLogPrintInterval
	---- Save DB Debug Info -----

	self.m_nTickTimer = nil
	self.m_nActiveTradeTimer = nil
	self.m_nRoleDataTimer = nil

	
	self.m_tMarketPageConf = {}

	self.m_tEquTradePage = {} --{nTradePageID:{nEquID, ...}, ...}，统计，按照TradePage生成临时装备
	--服务器启动时，一分钟后，向本地逻辑服发起请求，创建一批当前拍卖行需要的装备属性并缓存
	--在缓存生成前，如果有玩家登录并发起查询，如果没玩家装备，直接返回空
	self.m_tSysEquipCache = {} --{nPageID:{nEquID:tEquData, ...}, ...} --临时装备缓存

	self:ConfInit()
end

function CMarketMgr:ConfInit()
	self.m_tMarketPageConf = {}
	self.m_tEquTradePage = {} --{nTradePageID:{nEquID, ...}, ...}，统计，按照TradePage生成临时装备
	for nPropID, tConf in pairs(ctBourseItem) do 
		local tPageConf = self.m_tMarketPageConf[tConf.nTradeMenuId] or {}
		tPageConf[nPropID] = tConf
		self.m_tMarketPageConf[tConf.nTradeMenuId] = tPageConf
		
		if ctEquipmentConf[nPropID] then --如果是装备
			local nTradePageID = tConf.nTradeMenuId
			local tPageTbl = self.m_tEquTradePage[nTradePageID] or {}
			tPageTbl[nPropID] = tConf
			self.m_tEquTradePage[nTradePageID] = tPageTbl
		end
	end
end

function CMarketMgr:LoadData()
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	local tKeys = oDB:HKeys(gtDBDef.sRoleMarketDB)
	for _, sRoleID in ipairs(tKeys) do
		local sData = oDB:HGet(gtDBDef.sRoleMarketDB, sRoleID)
		local tData = cjson.decode(sData)
		local nRoleID = tData.nRoleID
		local oRoleStall = CMarketStall:new(self, nRoleID)
		oRoleStall:LoadData(tData)
		oRoleStall.m_bRoleOnline = false
		if oRoleStall:IsKeepActive() then
			self.m_tRoleStallMap[nRoleID] = oRoleStall
			for k, oItem in pairs(oRoleStall.m_tStallItemMap) do
				if oItem:IsActive() then
					self:InsertActiveTrade(oRoleStall:GetRoleID(), oItem)
				else
					--旧的非活跃数据，将nGKey置0，比较安全，防止某个地方意外根据非活跃交易的nGKey去查找活跃交易列表
					oItem.m_nGlobalKey = 0
				end
			end
		end
	end
end

function CMarketMgr:SaveData()
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	--停服时，仍然按照之前的，迭代整个Map
	for nRoleID, oMarketStall in pairs(self.m_tRoleStallMap) do
		if oMarketStall:IsDirty() then
			local tData = oMarketStall:SaveData()
			oDB:HSet(gtDBDef.sRoleMarketDB, oMarketStall:GetRoleID(), cjson.encode(tData))
			oMarketStall:MarkDirty(false)
		end
	end
end

function CMarketMgr:Init()
	self:LoadData()
	self.m_nActiveTradeTimer = goTimerMgr:Interval(60, function () self:OnMinuTimer() end)
	self.m_nRoleDataTimer = goTimerMgr:Interval(70, function () self:TickRoleData() end) --70秒检查一次，和其他时间稍微错开
	self.m_nTickTimer = goTimerMgr:Interval(3, function () self:TickSave() end) --数据保存，间隔1秒
end

function CMarketMgr:OnRelease()
	goTimerMgr:Clear(self.m_nActiveTradeTimer)
	goTimerMgr:Clear(self.m_nRoleDataTimer)
	goTimerMgr:Clear(self.m_nTickTimer)
	self:SaveData()
end

--获取物品交易配置
function CMarketMgr:GetItemConf(nItemID) return ctBourseItem[nItemID] end
function CMarketMgr:GetConfTbl() return ctBourseItem end
function CMarketMgr:GetTradePageConfTbl(nPageID) return self.m_tMarketPageConf[nPageID] end
function CMarketMgr:CheckPageIDValid(nPageID)
	if nPageID <= 0 then
		return false
	end
	if self.m_tActiveTradeMap[nPageID] then
		return true
	end
end

--检查物品是否可交易,true可交易，false不可交易
function CMarketMgr:CheckItemSalePermit(nItemID)
	--不在配置表中，不允许上架出售
	if nItemID <= 0 then
		return false
	end
	local tConf = CMarketMgr:GetItemConf(nItemID)
	if tConf and tConf.bSale then
		return true
	end
	return false
end

function CMarketMgr:GetStall(nRoleID) return self.m_tRoleStallMap[nRoleID] end
function CMarketMgr:GetTradePageIDByKey(nKey) return self.m_tActiveKeyMap[nKey] end
function CMarketMgr:GetTradePage(nPage) return self.m_tActiveTradeMap[nPage] end
function CMarketMgr:GetActiveItemMap(nItemID) return self.m_tActiveItemMap[nItemID] end

function CMarketMgr:GetTradePageIDByItemID(nItemID) 
	local tConf = self:GetItemConf(nItemID)
	if tConf then
		return tConf.nTradeMenuId
	end
end

--GlobalKey是否重复
function CMarketMgr:IsKeyRepeated(nKey)
	if self.m_tActiveKeyMap[nKey] then
		return true
	end
	return false
end

--获取一个新的GlobalKey
function CMarketMgr:GetNewKey()
	if self.m_nKeySerial >= gnMarketGlobalKeyMax then 
		self:ResetKey()
	end
	self.m_nKeySerial = self.m_nKeySerial + 1
	local nKey = self.m_nKeySerial
	if self:IsKeyRepeated(nKey) then
		assert(false, "Market GlobalKey Repeated:"..nKey)
	end
	return nKey
end

function CMarketMgr:ResetKey()
	local nResetSerial = gnMarketGKeyBegin
	self.m_nKeySerial = nResetSerial
end

--将物品插入到活跃交易列表
function CMarketMgr:InsertActiveTrade(nRoleID, oMarketItem)
	print("开始添加玩家出售商品，RoleID:"..nRoleID)
	--调用此函数前，oMarketItem已分配好正确的PrivateKey，所有数据正确的初始化
	local nItemID = oMarketItem:GetItemID()
	--这里不检查，可能策划改动配置，某物品之前可上架，后续不可上架，导致旧数据异常，外层接口做限制
--[[ 	if not CMarketMgr:CheckItemSalePermit(nItemID) then
		return
	end ]]
	local tConf = CMarketMgr:GetItemConf(nItemID) --只检查配置，存在配置中，才可以插入
	if not tConf then 
		return  
	end
	local nPrivateKey = oMarketItem:GetPrivateKey()
	if not nPrivateKey or nPrivateKey <= 0 or nPrivateKey > gnMarketPrivateKeyMax then
		assert(false, "PrivateKey错误")
	end
	local nItemPageID = CMarketMgr:GetTradePageIDByItemID(nItemID)
	local nGlobalKey = self:GetNewKey()
	if not nItemPageID or not nGlobalKey  then
		assert(false, "上架出错")
	end
	oMarketItem.m_nGlobalKey = nGlobalKey
	local oTradePage = self:GetTradePage(nItemPageID)
	if not oTradePage then
		assert(false, "找不到交易页表")
	end
	self.m_tActiveKeyMap[nGlobalKey] = nItemPageID
	local oActiveTrade = CMarketActiveTrade:new(nGlobalKey, nRoleID)
	oActiveTrade:SetByMarketItem(oMarketItem)
	oTradePage:Insert(nGlobalKey, oActiveTrade)

	local oActiveItemMap = self:GetActiveItemMap(nItemID)
	assert(oActiveItemMap)
	oActiveItemMap:Insert(nGlobalKey, nGlobalKey)
	-- self.m_tTradeObserver[nGlobalKey] = {}
	-- self:AddActiveCount(nItemPageID, 1)
	print("插入活跃交易列表成功，RoleID:"..nRoleID)
	return true
end

--获取商品基础价格
function CMarketMgr:GetItemBasePrice(nItemID)
	local tConf = self:GetItemConf(nItemID)
	assert(tConf, "配置不存在")
	local nServerLevel = goServerMgr:GetServerLevel(gnServerID)  --获取服务器等级
	local nBasePrice =  math.floor(tConf.fnBasePrice() * tConf.fnPriceCoefficient(nServerLevel))
	if nBasePrice <= 0 then 
		assert(false, "价格错误")
	end
	return nBasePrice
end

--取多个商品基础价格
function CMarketMgr:GetMultipleItemBasePrice(tItemList)
	local tItemPricr = {}
	for _, nItemID in ipairs(tItemList) do
		table.insert(tItemPricr, {nItemID = nItemID, nBasePrice = self:GetItemBasePrice(nItemID)})
	end
	return tItemPricr
end

--检查商品价格是否合法 --true合法，false不合法
function CMarketMgr:CheckItemPrice(nItemID, nPriceRatio)
	local tConf = self:GetItemConf(nItemID)
	if not tConf then
		return false
	end
	if nPriceRatio < tConf.nMinSaleRatio or nPriceRatio > tConf.nMaxSaleRatio then
		return false
	end
	local nRemain = nPriceRatio % 1000
	if nRemain ~= 0 then
		return false
	end
	return true
end

--计算商品价格
function CMarketMgr:GetItemPrice(nItemID, nPriceRatio)
	return math.floor(self:GetItemBasePrice(nItemID) * (nPriceRatio / 10000))
end

--计算上架手续费
function CMarketMgr:GetTaxCost(nItemID, nNum, nPriceRatio)
	if nItemID <= 0 or nNum <= 0 then
		return
	end
	local tConf = self:GetItemConf(nItemID)
	assert(tConf, "配置不存在")
	local nPrice = self:GetItemPrice(nItemID, nPriceRatio)
	local nSingleTax = math.floor((tConf.nTaxRate / 10000) * nPrice)
	return nSingleTax * nNum
end

--检查货币类型是否合法
function CMarketMgr:CheckCurrTypeValid(nItemID, nCurrType)
	if nCurrType == gtCurrType.eYinBi then -- 当前只有一种货币
		return true
	end
	return false
end

--商品上架销售
function CMarketMgr:SellItem(oRole, nItemID, nGridNum, nNum, nCurrType, nSyncPrice, nPriceRatio, nSaleTime)
	print("CMarketMgr:SellItem:", nItemID, "nGridNum", nGridNum, "nNum:", nNum, 
		"nCurrType:", nCurrType, "nPriceRatio:", nPriceRatio, "nSaleTime", nSaleTime)
	if not oRole or nItemID <= 0 or nNum <= 0 or nSaleTime <= 0 then
		return
	end
	if not ctPropConf[nItemID] then 
		oRole:Tips("物品ID错误")
		return 
	end
	local nRoleID = oRole:GetID()
	local oRoleStall = self:GetStall(nRoleID)
	assert(oRoleStall, "获取玩家摊位失败")
	--检查该玩家当前是否被禁止交易
	local bForbid, nForbidTime, nForbidReason = oRoleStall:GetForbidState()
	if bForbid then
		oRole:Tips("当前被禁止交易")
		return
	end
	--检查物品是否可销售
	if not self:CheckItemSalePermit(nItemID) then
		oRole:Tips("该物品不可交易")
		return
	end
	--检查货币类型是否合法
	if not self:CheckCurrTypeValid(nItemID, nCurrType) then
		return
	end
	--检查价格是否合法
	if not self:CheckItemPrice(nItemID, nPriceRatio) then
		print("商品出售价格不正确")
		oRole:Tips("商品出售价格不正确")
		return
	end
	--检查价格是否已过期
	local nBasePrice = self:GetItemBasePrice(nItemID)
	assert(nBasePrice)
	if nBasePrice ~= nSyncPrice then
		print("价格过期, nBasePrice:"..nBasePrice, "nSyncPrice:"..nSyncPrice)
		oRole:Tips("价格已过期，请重新上架")
		return
	end

	local nPrice = self:GetItemPrice(nItemID, nPriceRatio)
	if not nPrice or nPrice <= 0 then
		print("价格出错")
		return
	end

	--检查当前是否可以上架物品，即摊位格子是否已占满
	if not oRoleStall:CheckCanSaleNewItem() then
		print("摊位已满，无法出售")
		oRole:Tips("摊位已满，无法出售")
		return
	end

	local tSaleItemData  = {}
	tSaleItemData.nItemID = nItemID
	tSaleItemData.nGridNum = nGridNum 
	tSaleItemData.nNum = nNum

	local tCostList = {}
	local nTaxCost = self:GetTaxCost(nItemID, nNum, nPriceRatio)
	if nTaxCost > 0 then
		table.insert(tCostList, {nType = gtItemType.eCurr, nID = gtCurrType.eYinBi, nNum = nTaxCost})
	end

	local fnCheckItemCallback = function (bRet, tPropData)	
		--上架物品
		if not bRet then
			return
		end
		assert(tPropData, "数据错误")
		local oTradeItem = oRoleStall:CreateNewItem(nItemID, tPropData)
		if not oRoleStall:OnSale(oTradeItem, nNum, nCurrType, nPrice, os.time(), gnMarketItemActiveTime) then
			print("Sec3:上架出错")
			return
		end
		if not self:InsertActiveTrade(nRoleID, oTradeItem) then --注意前面不要做深拷贝，这里会设置oTradeItem的nGKey
			print("Sec4:上架出错")
			return
		end
		print("商品上架成功")
		oRole:Tips(string.format("上架%s成功", ctPropConf:GetFormattedName(nItemID)))
		local tRetData = {}
		tRetData.tItemDetail = oTradeItem:GetCSData() --因为上架过程，不做深拷贝，故直接使用原引用对象即可
		oRole:SendMsg("MarketItemOnSaleRet", tRetData)
		self:GetStallData(oRole) -- 重新刷新整个列表数据
	end
	local nServer = oRole:GetStayServer()
	local nService = oRole:GetLogic()
	goRemoteCall:CallWait("MarketSellItemReq", fnCheckItemCallback, nServer, nService, nSession, nRoleID, tSaleItemData, tCostList)
end

function CMarketMgr:CheckItemSale(tItem)
	local nItemID = tItem.nItemID
	if not nItemID then 
		return false
	end
	local nCurrType = gtCurrType.eYinBi
	local nPriceRatio = tItem.nPriceRatio
	local nSyncPrice = tItem.nBasePrice
	--检查物品是否可销售
	if not self:CheckItemSalePermit(nItemID) then
		return false, string.format("%s不可交易", ctPropConf:GetFormattedName(nItemID))
	end
	--检查货币类型是否合法
	if not self:CheckCurrTypeValid(nItemID, nCurrType) then
		return false, string.format("%s出售货币类型不正确", ctPropConf:GetFormattedName(nItemID))
	end
	--检查价格是否合法
	if not self:CheckItemPrice(nItemID, nPriceRatio) then
		print("商品出售价格不正确")
		return false, string.format("%s出售价格不正确", ctPropConf:GetFormattedName(nItemID))
	end
	--检查价格是否已过期
	local nBasePrice = self:GetItemBasePrice(nItemID)
	assert(nBasePrice)
	if nBasePrice ~= nSyncPrice then
		print("价格过期, nBasePrice:"..nBasePrice, "nSyncPrice:"..nSyncPrice)
		return false, string.format("%s价格已过期，请重新上架", ctPropConf:GetFormattedName(nItemID))
	end

	local nPrice = self:GetItemPrice(nItemID, nPriceRatio)
	if not nPrice or nPrice <= 0 then
		print("价格出错")
		return false
	end
	return true
end

--商品上架销售
-- tItemList = {{nItemID=, nGridNum=, nNum=, nBasePrice=, nPriceRatio=,}, ...}
function CMarketMgr:SellItemList(oRole, tItemList)
	print(">>>>>>>>>> SellItemList <<<<<<<<<<")
	print("tItemList", tItemList)
	if not oRole or not tItemList then
		return
	end
	if #tItemList <= 0 then 
		oRole:Tips("请选择需要出售的商品")
		return 
	end

	--检查排重
	local tTempItemMap = {}
	for k, tItem in ipairs(tItemList) do
		if tItem.nItemID <= 0 or tItem.nGridNum <= 0 or not ctPropConf[tItem.nItemID] then 
			return oRole:Tips("非法数据")
		end
		if tTempItemMap[tItem.nGridNum] then 
			return oRole:Tips("非法数据")
		end
		tTempItemMap[tItem.nGridNum] = tItem
	end

	local nRoleID = oRole:GetID()
	local oRoleStall = self:GetStall(nRoleID)
	assert(oRoleStall, "获取玩家摊位失败")
	--检查该玩家当前是否被禁止交易
	local bForbid, nForbidTime, nForbidReason = oRoleStall:GetForbidState()
	if bForbid then
		oRole:Tips("当前被禁止交易")
		return
	end

	local tSaleItemList  = {}
	local nTotalYinBiCost = 0
	for k, tItem in ipairs(tItemList) do 
		local bSucc, sReason = self:CheckItemSale(tItem)
		if not bSucc then 
			if sReason and type(sReason) == "string" then 
				oRole:Tips(sReason)
			end
			return 
		end
		local nTaxCost = self:GetTaxCost(tItem.nItemID, tItem.nNum, tItem.nPriceRatio)
		if nTaxCost > 0 then 
			nTotalYinBiCost = nTotalYinBiCost + nTaxCost
		end

		local tSaleItemData = {}
		tSaleItemData.nItemID = tItem.nItemID
		tSaleItemData.nGridNum = tItem.nGridNum 
		tSaleItemData.nNum = tItem.nNum
		tSaleItemData.nPrice = self:GetItemPrice(tItem.nItemID, tItem.nPriceRatio)
		table.insert(tSaleItemList, tSaleItemData)
	end

	if #tSaleItemList > oRoleStall:GetEmptyGridNum() then 
		oRole:Tips("出售失败，物品数量超过摊位空余格子")
		return 
	end
	if #tSaleItemList <= 0 then 
		return 
	end
	local tCostList = {}
	if nTotalYinBiCost > 0 then 
		table.insert(tCostList, {nType = gtItemType.eCurr, nID = gtCurrType.eYinBi, nNum = nTotalYinBiCost})
	end

	--tSaleDataList，是tSaleItemList原数据，附加上物品属性，返回
	local fnCheckItemCallback = function (bRet, tSaleDataList)	
		--上架物品
		if not bRet then
			return
		end
		assert(tSaleDataList, "数据错误")

		local bIsSuccOnSale = false
		local tRetMsg = {}
		tRetMsg.tItemDetailList = {}
		for k, tSaleItem in ipairs(tSaleDataList) do 
			local nItemID = tSaleItem.nItemID
			local tPropData = tSaleItem.tItemData
			local oTradeItem = oRoleStall:CreateNewItem(tSaleItem.nItemID, tPropData)
			local nCurrType = gtCurrType.eYinBi  --出售的货币类型强制指定为银币，当前只支持银币
			if not oRoleStall:OnSale(oTradeItem, tSaleItem.nNum, nCurrType, tSaleItem.nPrice, os.time(), gnMarketItemActiveTime) then
				oRole:Tips("商品上架出错")
				return
			end
			if not self:InsertActiveTrade(nRoleID, oTradeItem) then --注意前面不要做深拷贝，这里会设置oTradeItem的nGKey
				oRole:Tips("商品上架出错")
				return
			end
			print("商品上架成功")
			bIsSuccOnSale = true
			oRole:Tips(string.format("上架%s成功", ctPropConf:GetFormattedName(nItemID)))
			local tRetData = oTradeItem:GetCSData() --因为上架过程，不做深拷贝，故直接使用原引用对象即可
			table.insert(tRetMsg.tItemDetailList, tRetData)
		end
		oRole:SendMsg("MarketItemOnSaleRet", tRetMsg)
		self:GetStallData(oRole) -- 重新刷新整个列表数据
		if bIsSuccOnSale then
			goRemoteCall:Call("OnMarketItemOnSale", oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), {})
		end
	end
	local nServer = oRole:GetStayServer()
	local nService = oRole:GetLogic()
	goRemoteCall:CallWait("MarketSellItemListReq", fnCheckItemCallback, nServer, nService, nSession, nRoleID, tSaleItemList, tCostList)
end

--移除后, 会将nGKey对应的道具的GKey置0
function CMarketMgr:RemoveActiveSale(nGKey, nState) 
	nState = nState or gtMarketItemState.eRemove

	local nRoleID, nPKey = self:GetRolePKeyByGKey(nGKey)
	local oRoleStall = self:GetStall(nRoleID)
	if oRoleStall then
		oRoleStall:RemoveSale(nPKey, nState)
	end
	-- self:BroadcastTradeState(nGKey) --修改Item状态后再广播
	self:RemoveActiveTradeByGKey(nGKey) --广播后再移除
end

--系统下架过期商品
function CMarketMgr:RemoveExpirySale(nGKey)
	local nRoleID, nPKey = self:GetRolePKeyByGKey(nGKey)
	self:RemoveActiveSale(nGKey, gtMarketItemState.eRemove)
	self:SyncStallInfo(nRoleID)
	return true
end

function CMarketMgr:GetTradePageByGKey(nGKey)
	if nGKey <= 0 then 
		return
	end
	local nTradePageID = self:GetTradePageIDByKey(nGKey)
	local oTradePage = self:GetTradePage(nTradePageID)
	return oTradePage
end

--根据GlobalKey获取活跃交易
function CMarketMgr:GetActiveTradeByGKey(nGKey)
	if nGKey <= 0 then 
		return
	end
	local nTradePageID = self:GetTradePageIDByKey(nGKey)
	local oTradePage = self:GetTradePage(nTradePageID)
	if not oTradePage then
		return
	end
	local tItemData = oTradePage:GetDataByKey(nGKey)
	return tItemData
end

--根据全局Key查找玩家ID和PrivateKey
function CMarketMgr:GetRolePKeyByGKey(nGKey)
	local oItemData = self:GetActiveTradeByGKey(nGKey)
	if not oItemData then
		return
	end
	return oItemData:GetRoleID(), oItemData:GetPKey()
end

--根据全局Key查找玩家摊位物品
function CMarketMgr:GetItemByGKey(nGKey)
	local nRoleID, nPKey = self:GetRolePKeyByGKey(nGKey)
	if not nRoleID or not nPKey then
		return
	end
	local oItem = self:GetItemByRolePKey(nRoleID, nPKey)
	return oItem
end

function CMarketMgr:GetStallByGKey(nGKey)
	local nRoleID, nPKey = self:GetRolePKeyByGKey(nGKey)
	local oRoleStall = self:GetStall(nRoleID)
	return oRoleStall
end

--根据玩家ID和privateKey查找玩家摊位物品
function CMarketMgr:GetItemByRolePKey(nRoleID, nPKey)
	if nRoleID <= 0 or nPKey <= 0 then
		return
	end
	local oRoleStall = self:GetStall(nRoleID)
	if not oRoleStall then
		return
	end
	local oItem = oRoleStall:GetItemByPKey(nPKey)
	return oItem
end

-- --通知所有观察者，当前交易数据发生变化
-- function CMarketMgr:BroadcastTradeState(nGKey)
-- 	local tOb = self.m_tTradeObserver[nGKey]
-- 	if not tOb then 
-- 		return
-- 	end
-- 	local oItem = self:GetItemByGKey(nGKey)
-- 	if not oItem then
-- 		return
-- 	end
-- 	local nPageID = self:GetTradePageIDByKey(nGKey)
-- 	if not nPageID then
-- 		return
-- 	end
-- 	for k, v in pairs(tOb) do
-- 		local oRoleView = self:GetRoleView(v)
-- 		if oRoleView then
-- 			oRoleView:UpdateViewItem(nGKey, nPageID, oItem)
-- 		end
-- 	end
-- end

--移除活跃交易数据
function CMarketMgr:RemoveActiveTradeByGKey(nGKey)
	local nTradePageID = self:GetTradePageIDByKey(nGKey)
	if not nTradePageID then 
		return 
	end
	-- self.m_tTradeObserver[nGKey] = nil  --移除此交易的观察者列表
	local oTradePage = self:GetTradePage(nTradePageID)
	if oTradePage then
		local nItemID = 0
		local oActiveTrade = oTradePage:GetDataByKey(nGKey)
		if oActiveTrade then 
			nItemID = oActiveTrade:GetItemID()
		end
		local oActiveItemMap = self:GetActiveItemMap(nItemID)
		if oActiveItemMap then 
			oActiveItemMap:Remove(nGKey)
		end

		oTradePage:Remove(nGKey)
	end

	self.m_tActiveKeyMap[nGKey] = nil
	-- self:AddActiveCount(nTradePageID, -1)
	return true
end

function CMarketMgr:GetItemByActiveTrade(oActiveTrade)
	local oItem = self:GetItemByRolePKey(oActiveTrade:GetRoleID(), oActiveTrade:GetPKey())
	return oItem
end

--检查更新所有活跃交易数据
function CMarketMgr:UpdateActiveTradeData()
	--检查更新活跃交易数据
	local nTimeStamp = os.time()
	for _, oTradePage in pairs(self.m_tActiveTradeMap) do
		if oTradePage:Count() > 0 then 
			local tRemoveList = {} --下架列表
			local tInvalidList = {} --一些不正确的数据

			local fnTraverse = function(nIndex, nGKey, oActiveTrade) 
				--顺便检查下数据的正确性
				local nRoleID = oActiveTrade:GetRoleID()
				local nPKey = oActiveTrade:GetPKey()
				local oItem = self:GetItemByRolePKey(nRoleID, nPKey)
				if oItem then
					if oItem:CheckExpiry(nTimeStamp) then
						table.insert(tRemoveList, nGKey)
					else  --根据过期时间排序的红黑树，后续的没必要迭代
						return true
					end
				else
					LuaTrace("交易系统数据错误！！！nGkey:"..nGKey)
					table.insert(tInvalidList, nGKey)
				end
				-- if oActiveTrade:GetExpiryTime() <= nTimeStamp then 
				-- 	table.insert(tRemoveList, nGKey)
				-- else
				-- 	return true
				-- end
			end
			oTradePage:Traverse(1, oTradePage:Count(), fnTraverse)

			for k, nGKey in ipairs(tRemoveList) do
				self:RemoveExpirySale(nGKey)
			end
			for k, nGKey in ipairs(tInvalidList) do
				self:RemoveActiveTradeByGKey(nGKey)
			end
		end
	end

	--检查更新摊位相关状态信息
	for nRoleID, oStall in pairs(self.m_tRoleStallMap) do
		oStall:UpdateActiveState()
		oStall:UpdateForbidState()
	end
end

--提取售款
function CMarketMgr:DrawMoney(oRole, nPKey)
	local nRoleID = oRole:GetID()
	local oStall = self:GetStall(nRoleID)
	if not oStall then
		return
	end
	local oItem = oStall:GetItemByPKey(nPKey)
	if not oItem then
		oRole:Tips("商品不存在")
		return
	end
	if oItem.m_nSoldNum <= 0 then
		oRole:Tips("当前商品未售出，无法提现")
		return
	end
	if oItem.m_nSoldNum <= oItem.m_nDrawNum then
		oRole:Tips("该商品已全部提现，不可重复提现")
		return
	end
	local nDrawNum = oItem.m_nSoldNum - oItem.m_nDrawNum
	local nMoney = nDrawNum * oItem:GetPrice()
	local nCurrType = oItem:GetCurrType()

	local tAddList = {}
	table.insert(tAddList, {nType = gtItemType.eCurr, nID = nCurrType, nNum = nMoney})
	oRole:AddItem(tAddList, "交易商品提现")
	oStall:MarkDirty(true)

	oItem.m_nDrawNum = oItem.m_nSoldNum
	--提现不需要广播，如果当前剩余数量为0，说明此时已经被移除出活跃交易列表了
	if oItem:GetRemainNum() <= 0 then --如果已售罄，则删除
		oStall:RemoveFromStallGrid(nPKey)
	end
	--[[
	// 商品提现响应
	message MarketDrawMoneyRet
	{
		required int32 nItemID = 1; // 提现的商品ID
		required int32 nMoney = 2;  //提现的金钱
		required int32 nNum = 3;    // 提现的商品数量
		optional MarketStallItemDetail tItemDetail = 4; // 提现的商品信息
	}
	]]
	local tRetData = {}
	tRetData.nItemID = oItem:GetItemID()
	tRetData.nMoney = nMoney
	tRetData.nNum = nDrawNum
	oRole:SendMsg("MarketDrawMoneyRet", tRetData)
	self:GetStallData(oRole) -- 重新刷新整个列表数据
end

--玩家主动下架商品
function CMarketMgr:RemoveItemByRole(oRole, nPKey)
	local nRoleID = oRole:GetID()
	local oStall = self:GetStall(nRoleID)
	if not oStall then
		return
	end
	local oItem = oStall:GetItemByPKey(nPKey)
	if not oItem then
		oRole:Tips("物品不存在")
		return
	end

	local nSoldNum = oItem:GetSoldNum()
	local nDrawNum = oItem:GetDrawNum()
	local nCurrType = oItem:GetCurrType()
	local nPrice = oItem:GetPrice()
	local nRemainNum = oItem:GetRemainNum()
	local nItemID = oItem:GetItemID()

	--不能根据nGKey查找活跃列表数据，可能此时nGKey已过期，将GKey已经重置过，则会将其他玩家正常销售的物品清理掉
	if oItem:IsActive() then --如果之前还处于活跃交易
		--必须先更改状态，再执行rpc，否则，低几率，玩家商品下架途中，又被其他玩家购买了
		local nGKey = oItem:GetGlobalKey()
		self:RemoveActiveSale(nGKey, gtMarketItemState.eRemove)
	end

	local tAddList = {}  --已出售未提现
	if nSoldNum > 0 and nSoldNum > nDrawNum then
		local nMoney = (nSoldNum - nDrawNum) * nPrice
		if nMoney > 0 then
			table.insert(tAddList, {nType = gtItemType.eCurr, nID = nCurrType, nNum = nMoney})
		end
	end

	if nRemainNum <= 0 then
		if #tAddList > 0 then 
			oRole:AddItem(tAddList, "交易商品下架提现")
		end
		oStall:RemoveFromStallGrid(nPKey)
		oRole:Tips("该商品已全部售出，已自动提现")
		self:GetStallData(oRole) -- 重新刷新整个列表数据
		return
	end

	--必须等待添加物品成功，可能玩家背包满
	local fnAddItemCallback = function (bRet)
		if not bRet then
			--TODO物品状态恢复
			print("下架失败")
			return
		end
		if #tAddList > 0 then 
			oRole:AddItem(tAddList, "交易商品下架提现")
		end
		oStall:RemoveFromStallGrid(nPKey)
		oRole:Tips(string.format("下架%s成功", ctPropConf:GetFormattedName(nItemID)))
		local tRetData = {}
		tRetData.nItemID = nItemID
		oRole:SendMsg("MarketRemoveSaleRet", tRetData)
		self:GetStallData(oRole) -- 重新刷新整个列表数据
	end

	--已排除nRemainNum <= 0 的情况
	local tPropData = oItem:GetPropData()
	if tPropData then  --兼容旧数据
		tPropData.m_nFold = nRemainNum
		oRole:TransferItemList({tPropData}, "交易商品下架", fnAddItemCallback)
	else 
		print("物品<"..nItemID..">没有道具数据")
		oRole:AddItem({{nType = gtItemType.eProp, nID = nItemID, nNum = nRemainNum}}, 
			"交易商品下架", fnAddItemCallBack)
	end
end

--重新上架商品
function CMarketMgr:ReSale(oRole, nPKey, nSyncPrice, nPriceRatio)
	local nRoleID = oRole:GetID()
	local oStall = self:GetStall(nRoleID)
	if not oStall then
		return
	end
	local oItem = oStall:GetItemByPKey(nPKey)
	if not oItem then
		oRole:Tips("物品不存在")
		return
	end

	local nItemID = oItem:GetItemID()
	local nRemainNum = oItem:GetRemainNum()
	local nCurrType = oItem:GetCurrType()
	if nRemainNum <= 0 then
		oRole:Tips("该商品已全部售出")
		return
	end

	if not self:CheckItemPrice(nItemID, nPriceRatio) then
		print("商品出售价格不正确")
		oRole:Tips("商品出售价格不正确")
		return
	end

	local nBasePrice = self:GetItemBasePrice(nItemID)
	if nBasePrice ~= nSyncPrice then
		print("价格过期, nBasePrice:"..nBasePrice, "nSyncPrice:"..nSyncPrice)
		oRole:Tips("商品价格已过期，请重新选择上架")
		return
	end

	local nCurPrice = self:GetItemPrice(nItemID, nPriceRatio)
	if not nCurPrice or nCurPrice <= 0 then
		print("价格出错")
		return
	end

	local nTaxCost = self:GetTaxCost(nItemID, nRemainNum, nPriceRatio)
	local tCostList = {}
	table.insert(tCostList, {nType = gtItemType.eCurr, nID = gtCurrType.eYinBi, nNum = nTaxCost})

	local fnTaxCostCallBack = function (bRet)
		if not bRet then
			oRole:Tips("手续费不足，无法上架")
			return
		end

		local tAddList = {}
		local nSoldNum = oItem.m_nSoldNum
		local nDrawNum = oItem.m_nDrawNum
		if nSoldNum > 0 and nSoldNum > nDrawNum then
			local nMoney = (nSoldNum - nDrawNum) * oItem:GetPrice()
			if nMoney > 0 then --添加未提取的货款
				table.insert(tAddList, {nType = gtItemType.eCurr, nID = nCurrType, nNum = nMoney})
				--直接通知添加即可，没必要等待执行结果了，前面扣除手续费成功，此时服务基本都是正常的，货币类型，不会存在背包满导致无法添加情况
				oRole:AddItem(tAddList, "商品重新上架提现")
				tAddList = {}
			end
			oItem.m_nDrawNum = oItem.m_nSoldNum
			oStall:MarkDirty(true)
		end
		local tPropData = oItem:GetPropData()  --保存下旧的道具信息
		if tPropData then --兼容旧数据
			tPropData.m_nFold = nRemainNum
		end

		--允许玩家将正在出售的物品调整售价后重新上架
		if oItem:IsActive() then --如果还在活跃交易列表，修改状态广播，正常这里都是false
			local nGKey = oItem:GetGlobalKey()
			if nGKey > 0 then 
				self:RemoveActiveSale(nGKey, gtMarketItemState.eRemove)
			end
		end

		oStall:RemoveFromStallGrid(nPKey) --清除旧物品
		local oNewItem = oStall:CreateNewItem(nItemID, tPropData)
		if not oStall:OnSale(oNewItem, nRemainNum, nCurrType, nCurPrice, os.time(), gnMarketItemActiveTime) then
			return
		end
		if not self:InsertActiveTrade(nRoleID, oNewItem) then
			oRole:Tips("上架出错")
			print("商品上架出错")
			return
		end
		oStall:MarkDirty(true)
		self:GetStallData(oRole)  --刷新摊位信息

		--[[
		message MarketItemReSaleRet
		{
			required MarketStallItemDetail tItemDetail = 1; // 售卖信息
		}
		]]
		oRole:Tips(string.format("重新上架%s成功", ctPropConf:GetFormattedName(nItemID)))
		local tRetData = {}
		tRetData.tItemDetail = oNewItem:GetCSData()
		oRole:SendMsg("MarketItemReSaleRet", tRetData)
		goRemoteCall:Call("OnMarketItemOnSale", oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), {})
	end
	--扣除重新上架费用
	oRole:SubItem(tCostList, "交易上架", fnTaxCostCallBack)
	
end

--获取物品基础价格
function CMarketMgr:GetItemPriceData(oRole, nItemID)
	if nItemID <= 0 then
		return
	end
	--[[
	// 商品价格和税率响应
	message MarketGoodsPriceDataRet
	{
		required int32 nItemID = 1;      // 商品ID
		required bool bSale = 2;         // 是否可交易
		optional int32 nBasePrice = 3;   // 基础价格
		optional int32 nMinPriceRatio = 4; // 最低价格比率
		optional int32 nMaxPriceRatio = 5; // 最低价格比率
		optional int32 nTaxRate = 6;     // 税率
	}
	]]

	local tRetData = {}
	tRetData.nItemID = nItemID
	if not self:CheckItemSalePermit(nItemID) then
		tRetData.bSale = false
		oRole:Tips("该物品不可交易")
		--return
	else
		tRetData.bSale = true
		local tConf = self:GetItemConf(nItemID)
		assert(tConf, "配置不存在")
		tRetData.nBasePrice = self:GetItemBasePrice(nItemID)
		tRetData.nMinPriceRatio = tConf.nMinSaleRatio
		tRetData.nMaxPriceRatio = tConf.nMaxSaleRatio
		tRetData.nTaxRate = tConf.nTaxRate
	end
	oRole:SendMsg("MarketGoodsPriceDataRet", tRetData)
	return
end

--解锁摊位格子
function CMarketMgr:UnlockStallGrid(oRole)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local oStall = self:GetStall(nRoleID)
	assert(oStall, "玩家摊位不存在, RoleID"..nRoleID)
	local bUnlock, nUnlockCost = oStall:CheckCanUnlockGrid()
	if not bUnlock then
		oRole:Tips("已达最大，无法继续解锁")
		return
	end

	local tCostList = {}
	table.insert(tCostList, {nType = gtItemType.eCurr, nID = gtCurrType.eAllYuanBao, nNum = nUnlockCost})

	local fnSubCostCallBack = function (bRet)
		if not bRet then
			-- oRole:Tips("元宝不足，解锁失败")
			return
		end
		oStall:UnlockTradeGrid(1) --单次解锁1个

		local tRetData = {}
		tRetData.nCost = nUnlockCost
		oRole:SendMsg("MarketUnlockStallGridRet", tRetData)
		self:GetStallData(oRole)
	end

	oRole:SubItem(tCostList, "解锁交易摊位格子", fnSubCostCallBack)
end

function CMarketMgr:GetRoleView(nRoleID) return self.m_tRoleViewMap[nRoleID] end --获取玩家商品刷新数据

--获取玩家摊位数据
function CMarketMgr:GetStallData(oRole)
	local nRoleID = oRole:GetID()
	local oStall = self:GetStall(nRoleID)
	assert(oStall, "玩家摊位不存在, RoleID"..nRoleID)
	local tData = oStall:GetStallData()
	oRole:SendMsg("MarketStallDataRet", tData)
end

function CMarketMgr:SyncStallInfo(nRoleID)
	if not nRoleID or nRoleID <= 0 then 
		return 
	end
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if oRole and oRole:IsOnline() then 
		self:GetStallData(oRole)
	end
end

--获取交易列表刷新数据
function CMarketMgr:GetViewPageFlushData(oRole)
	local nRoleID = oRole:GetID()
	local oRoleView = self:GetRoleView(nRoleID)
	assert(oRoleView, "交易系统数据错误!")
	local tRetData = {}
	tRetData.tFlushData = oRoleView:GetCSFlushData()
	oRole:SendMsg("MarketViewPageFlushDataRet", tRetData)
end

function CMarketMgr:GetViewPageDataReq(oRole, nPageID) 
	if not oRole:IsOnline() then 
		return 
	end

	local fnQueryCallback = function(tItemList) 
		if not tItemList then 
			return 
		end
		print("必定出售道具列表", tItemList)
		self:GetViewPageData(oRole, nPageID, tItemList) 
	end

	local nServerID = oRole:GetServer()
	local nServiceID = oRole:GetLogic()
	goRemoteCall:CallWait("QueryMarketFlushItemReq", fnQueryCallback, nServerID, 
		nServiceID, 0, oRole:GetID())
end

--获取页表商品
--tItemList {nItemID:nItemNum, ...} 必定刷新的物品列表
function CMarketMgr:GetViewPageData(oRole, nPageID, tItemList)
	local nRoleID = oRole:GetID()
	local oRoleView = self:GetRoleView(nRoleID)
	assert(oRoleView, "交易系统数据错误!")
	if not self:CheckPageIDValid(nPageID) then
		oRole:Tips("不合法的商品页表ID")
		return
	end
	local tRetData = {}
	tRetData.tPageData = oRoleView:GetPageData(nPageID, tItemList)
	oRole:SendMsg("MarketViewPageDataRet", tRetData)
end

function CMarketMgr:FlushViewPageReq(oRole, bMoney) 
	assert(oRole, "参数错误")
	if not oRole:IsOnline() then 
		return 
	end

	local fnQueryCallback = function(tItemList)
		if not tItemList then 
			return --未收到响应，不执行刷新操作，防止消息阻塞，玩家一直花费金币刷新 
		end 
		self:FlushViewPage(oRole, bMoney, tItemList)
	end
	
	local nServerID = oRole:GetServer()
	local nServiceID = oRole:GetLogic()
	goRemoteCall:CallWait("QueryMarketFlushItemReq", fnQueryCallback, nServerID, 
		nServiceID, 0, oRole:GetID())
end

--刷新交易列表数据
--tItemList {nItemID:nItemNum, ...} 必定刷新的物品列表
function CMarketMgr:FlushViewPage(oRole, bMoney, tItemList)
	assert(oRole, "参数错误")
	local nRoleID = oRole:GetID()
	local oRoleView = self:GetRoleView(nRoleID)
	assert(oRoleView, "交易数据错误!")
	print("必定出现商品列表", tItemList)

	local nTimeStamp = os.time()
	local bFree = oRoleView:CheckCanFreeFlush(nTimeStamp)
	if not bMoney and not bFree then
		local nNextStamp = oRoleView:GetNextFreeFlushTime()
		local nWaitTime = nNextStamp - nTimeStamp
		assert(nWaitTime > 0, "逻辑错误")
		local nWaitMinu = math.floor(nWaitTime / 60)
		local nWaitSec = math.floor(nWaitTime % 60)
		if nWaitMinu > 0 then
			oRole:Tips("免费刷新时间未到，还需等待"..nWaitMinu.."分"..nWaitSec.."秒")
		else
			oRole:Tips("免费刷新时间未到，还需等待"..nWaitSec.."秒")
		end
		return
	end

	local fnFlushCostCallBack = function (bRet)
		if not bRet then
			oRole:JinBiTips()
			return
		end
		oRoleView:FlushPage()
		self:GetViewPageData(oRole, oRoleView.m_nLastViewPageID, tItemList)
		--[[
		message MarketFlushViewPageRet  
		{
			required MarketViewPageFlushData tFlushData = 1; // 刷新数据
		}
		]]
		local tRetData = {}
		tRetData.tFlushData = oRoleView:GetCSFlushData()
		oRole:SendMsg("MarketFlushViewPageRet", tRetData)
	end

	if bFree then --优先使用免费刷新
		fnFlushCostCallBack(true)
	else -- bMoney then
		local tCostList = {}
		local nCost = oRoleView:GetFlushCost()
		table.insert(tCostList, {nType = gtItemType.eCurr, nID = gtCurrType.eJinBi, nNum = nCost})
		oRole:SubItem(tCostList, "交易行浏览刷新", fnFlushCostCallBack)
	end
end

--购买系统出售的商品
function CMarketMgr:PurchaseSysSale(oRole, nViewPageID, oViewItem, nNum)
	local nRoleID = oRole:GetID()
	local oRoleView = self:GetRoleView(nRoleID)
	assert(oRoleView, "数据出错") --在线玩家，此数据必然要存在	
	if not oViewItem:IsSysSale() then
		assert(false, "逻辑错误")
	end
	if oViewItem.m_nRemainNum < nNum then
		oRole:Tips("商品数量不足，购买失败")
	end

	local nItemID = oViewItem:GetItemID()
	assert(nItemID)
	local bEquipment = ctEquipmentConf[nItemID] and true or false 
	if bEquipment then 
		nNum = 1 --装备，单次只允许购买1个
	end
	local tPropData = nil
	if bEquipment then 
		local tEquPageData = self.m_tSysEquipCache[nViewPageID]
		if tEquPageData then 
			tPropData = tEquPageData[nItemID]
		end
		if not tPropData then --服务器如果当前尚未生成装备数据，不允许购买
			oRole:Tips("购买失败")
			return 
		end
	end

	local nItemID  = oViewItem.m_nItemID
	local nCurrType = oViewItem.m_nCurrType
	local nPrice = oViewItem.m_nPrice

	local nCost = nPrice * nNum
	local tCostList = {}
	table.insert(tCostList, {nType = gtItemType.eCurr, nID = gtCurrType.eYinBi, nNum = nCost})

	local fnSubCostCallBack = function (bRet)
		if not bRet then
			oRole:Tips(string.format("%s不足，无法购买", gtCurrName[nCurrType]))
			return
		end

		if bEquipment and tPropData then 
			tPropData.m_nFold = nNum --设置为购买的数量
			tPropData.m_bBind = true
			oRole:TransferItemList({tPropData}, "交易购买")
		else
			local tPropExt = nil
			if bEquipment then 
				--缓存信息不存在，直接指定装备品质为白色
				tPropExt = {nQuality = gtQualityColor.eWhite}
				return oRole:Tips("购买失败，装备属性不存在")
			end
			-- 给玩家添加道具
			local tAddList = {}
			table.insert(tAddList, {nType = gtItemType.eProp, nID = nItemID, nNum = nNum, 
				bBind = true, tPropExt = tPropExt})
			oRole:AddItem(tAddList, "交易购买") --背包满会发邮件，否则，则必须尝试在给玩家添加道具的同时扣除玩家货币，即，放在同一个异步请求中
		end

		oViewItem.m_nRemainNum = oViewItem.m_nRemainNum - nNum
		if oViewItem.m_nRemainNum <= 0 then
			oViewItem.m_nState = gtMarketItemState.eSoldOut
		end
		oRole:Tips(string.format("购买%s成功", ctPropConf:GetFormattedName(nItemID)))

		local tRetData = {}
		tRetData.nItemID = nItemID
		tRetData.nNum = nNum
		tRetData.nPrice = nPrice
		oRole:SendMsg("MarketPurchaseRet", tRetData)

		self:GetViewPageData(oRole, nViewPageID) --购买后，当前商品信息界面数据出现了改变
		return true
	end

	oRole:SubItem(tCostList, "交易购买", fnSubCostCallBack)
end

--购买玩家交易的物品
function CMarketMgr:PurchaseRoleItem(oRole, nViewPageID, oViewItem, nNum)
	--外层必须判断请求时，这个物品在oViewItem中的状态是否已经过期
	local nGKey = oViewItem:GetGKey()
	if oViewItem.m_nState == gtMarketItemState.eSoldOut then 
		oRole:Tips("物品已售罄")
		self:GetViewPageData(oRole, nViewPageID)
		return
	elseif oViewItem.m_nState == gtMarketItemState.eRemove then 
		oRole:Tips("物品已下架")
		self:GetViewPageData(oRole, nViewPageID)
		return
	end
	if oViewItem.m_nState ~= gtMarketItemState.eSelling then
		oRole:Tips("当前无法购买")
		return
	end
	--购买数据，根据oItem的来确定，不根据oViewItem
	local oItem = self:GetItemByGKey(nGKey)
	if not oItem then
		oRole:Tips("物品已下架")
		self:GetViewPageData(oRole, nViewPageID)
		return
	end
	--TODO 加多一个判断，物品上架时间。不一致的，不允许购买
	local nTradeState = oItem:GetTradeState()
	if nTradeState == gtMarketItemState.eSoldOut then --理论上不存在此2种情况
		oRole:Tips("物品已售罄")
		return
	elseif nTradeState == gtMarketItemState.eRemove then
		oRole:Tips("物品已下架")
		return
	end
	if nTradeState ~= gtMarketItemState.eSelling then 
		oRole:Tips("购买失败")
		return 
	end

	local nRoleIDSale, nPKey = self:GetRolePKeyByGKey(nGKey)
	if not nRoleIDSale or not nPKey then
		oRole:Tips("购买失败")
		return
	end
	local oSaleStall = self:GetStall(nRoleIDSale)
	if not oSaleStall then 
		oRole:Tips("购买失败")
		return
	end
	if oItem:GetRemainNum() < nNum then
		oRole:Tips("商品数量不足，购买失败")
		return
	end

	--检查并扣除玩家货币
	local nCurrType = oItem:GetCurrType()
	local nPrice = oItem:GetPrice()
	local nCost = nPrice * nNum
	local tCostList = {}
	table.insert(tCostList, {nType = gtItemType.eCurr, nID = gtCurrType.eYinBi, nNum = nCost})

	local fnSubCostCallBack = function (bRet)
		if not bRet then
			oRole:Tips(string.format("%s不足，无法购买", gtCurrName[nCurrType]))
			return
		end
		-- 消耗货币
		-- 可能协程返回前，这个道具，被另一个请求购买了
		-- 需要再次检查当前出售的商品是否存在以及剩余数量
		if oItem:GetRemainNum() < nNum then
			oRole:Tips("物品不足，购买失败")
			oRole:AddItem(tCostList, "交易购买失败回滚")
			return
		end

		-- 给玩家添加道具
		local nItemID = oItem:GetItemID()
		local tPropData = oItem:GetPropData()
		if tPropData then 
			tPropData.m_nFold = nNum --设置为购买的数量
			tPropData.m_bBind = true
			oRole:TransferItemList({tPropData}, "交易购买")
		else  --兼容旧数据
			local tAddList = {}
			table.insert(tAddList, {nType = gtItemType.eProp, nID = nItemID, nNum = nNum, bBind = true})
			oRole:AddItem(tAddList, "交易购买") --同上面系统购买，暂时不走异步
		end 

		oItem:SubSoldNum(nNum)
		if oItem:GetRemainNum() <= 0 then
			self:RemoveActiveSale(nGKey, gtMarketItemState.eSoldOut)
			oViewItem.m_nRemainNum = 0
			oViewItem.m_nState = gtMarketItemState.eSoldOut
		end
		oSaleStall:MarkDirty(true)
		--购买后，当前商品信息界面数据出现了改变
		self:GetViewPageData(oRole, nViewPageID)
		oRole:Tips(string.format("购买%s成功", ctPropConf:GetFormattedName(nItemID)))

		local tRetData = {}
		tRetData.nItemID = nItemID
		tRetData.nNum = nNum
		tRetData.nPrice = nPrice
		oRole:SendMsg("MarketPurchaseRet", tRetData)
		self:SyncStallInfo(nRoleIDSale)
		return true
	end	

	oRole:SubItem(tCostList, "交易购买", fnSubCostCallBack)
end


--购买商品
function CMarketMgr:PurchaseItemReq(oRole, nViewPageID, nGKey) 
	local nNum =  1 --购买数量，单次限定一个
	local nRoleID = oRole:GetID()
	local oRoleView = self:GetRoleView(nRoleID)
	assert(oRoleView, "数据出错") --在线玩家，此数据必然要存在
	-- print("PurchaseItemReq:", "nViewPageID:"..nViewPageID, "nGKey"..nGKey)
	
	local oViewPage = oRoleView:GetViewPage(nViewPageID)
	if not oViewPage then
		oRole:Tips("商品页不存在")
		return
	end
	if oViewPage:IsExpired(oRoleView:GetFlushKey()) then
		oRole:Tips("商品信息已过期，请刷新")
		return
	end
	--不能根据nGKey直接去活跃交易列表中查找，可能是系统提供的，未记录在里面
	--或者是交易已经过期了，这个nGKey已经失效了
	local oViewItem = oViewPage:GetViewItem(nGKey)
	if not oViewItem then
		oRole:Tips("商品不存在，请刷新")
		return
	end

	--必须在此处提前判断
	--如果是非系统出售商品，如果玩家长时间在线，而viewItem中的GKey是没清理的
	--如果系统长时间运行，可能遇到GKey原来所关联的物品已经下架了的情况
	local nItemState = oViewItem.m_nState
	if nItemState == gtMarketItemState.eSoldOut then
		oRole:Tips("物品已售罄")
		return
	elseif nItemState == gtMarketItemState.eRemove then
		oRole:Tips("物品已下架")
		return
	end
	if oViewItem:IsSysSale() then
		self:PurchaseSysSale(oRole, nViewPageID, oViewItem, nNum)
	else
		self:PurchaseRoleItem(oRole, nViewPageID, oViewItem, nNum)
	end
end

--摊位出售的商品详细信息请求
function CMarketMgr:StallItemDetailInfoReq(oRole, nPKey)
	if not oRole or not nPKey or nPKey <= 0 then 
		return 
	end
	local nRoleID = oRole:GetID()
	local oStall = self:GetStall(nRoleID)
	if not oStall then
		return
	end
	local oItem = oStall:GetItemByPKey(nPKey)
	if not oItem then
		oRole:Tips("物品不存在")
		return
	end
	local tPropData = oItem:GetPropData()
	if tPropData then 
		oRole:SendPropDetailInfo(tPropData)
	else  --兼容旧数据
		return --不响应
	end
end

--浏览的商品详细信息请求
function CMarketMgr:ViewItemDetailInfoReq(oRole, nViewPageID, nGKey)
	if not oRole or not nViewPageID or not nGKey then 
		return 
	end
	local nRoleID = oRole:GetID()
	local oRoleView = self:GetRoleView(nRoleID)
	assert(oRoleView, "数据出错") --在线玩家，此数据必然要存在
	-- print("PurchaseItemReq:", "nViewPageID:"..nViewPageID, "nGKey"..nGKey)
	
	local oViewPage = oRoleView:GetViewPage(nViewPageID)
	if not oViewPage then
		oRole:Tips("商品页不存在")
		return
	end
	if oViewPage:IsExpired(oRoleView:GetFlushKey()) then
		oRole:Tips("商品信息已过期，请刷新")
		return
	end
	local oViewItem = oViewPage:GetViewItem(nGKey)
	local nItemState = oViewItem.m_nState
	if nItemState == gtMarketItemState.eSoldOut then
		oRole:Tips("物品已售罄")
		return
	elseif nItemState == gtMarketItemState.eRemove then
		oRole:Tips("物品已下架")
		return
	end
	if oViewItem:IsSysSale() then
		local nItemID = oViewItem:GetItemID()
		if ctEquipmentConf[nItemID] then --如果是装备
			local tEquCachePage = self.m_tSysEquipCache[nViewPageID]
			if not tEquCachePage then 
				print("当前未生成系统出售装备缓存页表数据")
				return 
			end
			local tItemData = tEquCachePage[nItemID]
			if not tItemData then 
				print("当前未生成系统出售装备缓存数据")
				return 
			end
			oRole:SendPropDetailInfo(tItemData)
			return 
		else
			print("系统出售商品，不支持查看")
		end
		return 
	else
		if oViewItem.m_nState ~= gtMarketItemState.eSelling then
			oRole:Tips("商品已下架，无法查看")
			return
		end
		--购买数据，根据oItem的来确定，不根据oViewItem
		local oItem = self:GetItemByGKey(nGKey)
		if not oItem then
			oRole:Tips("物品不存在")
			return
		end
		local tPropData = oItem:GetPropData()
		if tPropData then 
			oRole:SendPropDetailInfo(tPropData)
		else  --兼容旧数据
			return --不响应
		end
	end
end

--玩家上线
function CMarketMgr:OnRoleOnline(oRole)
	local nRoleID = oRole:GetID()	
	local oRoleStall = self:GetStall(nRoleID)
	if oRoleStall then
		oRoleStall.m_bRoleOnline = true
	else
		local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
		local sData = oDB:HGet(gtDBDef.sRoleMarketDB, nRoleID)
		local tData = nil
		if sData ~= "" then
			tData = cjson.decode(sData)
		end
		print("玩家上线，开始创建玩家摊位，RoleID:"..nRoleID)
		oRoleStall = CMarketStall:new(self, nRoleID)
		oRoleStall:LoadData(tData)
		oRoleStall.m_bRoleOnline = true
		self.m_tRoleStallMap[nRoleID] = oRoleStall
		for k, oItem in pairs(oRoleStall.m_tStallItemMap) do
			if oItem:IsActive() then --正常不会发生，服务器启动时就会加载所有玩家活跃交易数据
				self:InsertActiveTrade(oRoleStall:GetRoleID(), oItem)
			else
				--旧的非活跃数据，将nGKey置0，比较安全，防止某个地方意外根据非活跃交易的nGKey去查找活跃交易列表
				oItem.m_nGlobalKey = 0
			end
		end
	end

	local oRoleView = self:GetRoleView(nRoleID)
	if oRoleView then
		oRoleView.m_bOnline = true
	else
		oRoleView = CMarketView:new(self, nRoleID)
		oRoleView.m_bOnline = true
		self.m_tRoleViewMap[nRoleID] = oRoleView
		print("角色上线，插入MarketRoleView")
	end

	self:GetStallData(oRole)
end

--玩家离线
function CMarketMgr:OnRoleOffline(nRoleID)
	local oRoleStall = self:GetStall(nRoleID)
	if oRoleStall then
		oRoleStall.m_bRoleOnline = false
	end

	local oRoleView = self:GetRoleView(nRoleID)
	if oRoleView then
		oRoleView.m_bOnline = false
	end
end

function CMarketMgr:TickSave(nTimeStamp)
	local nDirtyNum = self.m_tDirtyQueue:Count()
	nTimeStamp = nTimeStamp or os.time()
	if math.abs(nTimeStamp - self.m_nSavePrintStamp) >= 180 then --每3分钟打印一次
		self.m_nSavePrintStamp = nTimeStamp
		print("当前等待保存的<交易系统>数据数量:"..nDirtyNum)
	end

	if nDirtyNum <= 0 then
		return
	end

	local nMaxSaveNum = 400                                --单次保存的最大数量
	local nDefaultSaveNum = 40                             --默认单次保存数量
	local nTargetTime = 300                                --全部保存完的目标时间
	local nSaveNum  = nDefaultSaveNum

	local nTargetNum = math.ceil(nDirtyNum / nTargetTime)	
	if nTargetNum > nDefaultSaveNum then --在目标时间无法保存完，需要加快保存速度
		if nMaxSaveNum >= nTargetNum then
			--做一个补偿，在数据较多情况下，比理想情况稍微保存快一点
			local nCompensation = math.ceil(2 * nMaxSaveNum / (math.abs(nMaxSaveNum - nTargetNum) + 1))
			nTargetNum = nTargetNum + nCompensation
		else	
			LuaTrace(string.format("\n请注意，当前<交易系统>待保存数据<%d>,\n目标保存速度<%d>,\n已超过预设最大保存速度<%d>\n", 
				nDirtyNum, nTargetNum, nMaxSaveNum))
		end
		nSaveNum = math.max(math.min(nTargetNum, nMaxSaveNum), nDefaultSaveNum)
	end

	nSaveNum = math.min(nSaveNum, nDirtyNum) --可能当前脏数据的总数量比默认值低

	local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	for i = 1, nSaveNum do
		local oRoleStall = self.m_tDirtyQueue:Head()
		if oRoleStall then
			local tData = oRoleStall:SaveData()
			oDB:HSet(gtDBDef.sRoleMarketDB, oRoleStall:GetRoleID(), cjson.encode(tData))
			oRoleStall:MarkDirty(false)
			--print("保存交易数据成功，nRoleID:"..oRoleStall:GetRoleID())
		end
		self.m_tDirtyQueue:Pop()
	end
end

--定期清理Stall，保存DB
function CMarketMgr:TickRoleStall()
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	local nTimeStamp = os.time()
	local tStallDeleteList = {}
	for k, oStall in pairs(self.m_tRoleStallMap) do
		--必须检查是否是脏数据，脏数据不允许删除
		if not oStall:IsKeepActive() and not oStall:IsDirty() then
			table.insert(tStallDeleteList, k)
		end
	end
	--每一个stall被从内存清理前，都要确保保存DB了，避免丢失数据
	for k, v in ipairs(tStallDeleteList) do
		print("Tick清理玩家MarketStall, RoleID:"..v)
		self.m_tRoleStallMap[v] = nil
	end
end

--定期清理ViewData
function CMarketMgr:TickRoleView()
	local tViewDeleteList = {}
	for k, oRoleView in pairs(self.m_tRoleViewMap) do
		if not oRoleView:IsKeepActive() then
			-- oRoleView:RemoveFromObserver()
			--tViewDeleteList[#tViewDeleteList + 1] = k
			table.insert(tViewDeleteList, k)
		end
	end
	for k, v in ipairs(tViewDeleteList) do
		print("Tick清理玩家MarketView, RoleID:"..v)
		self.m_tRoleViewMap[v] = nil
	end
end

function CMarketMgr:CreateSysEquCache(nPageID)
	assert(nPageID)
	local tPageData = self.m_tEquTradePage[nPageID]
	assert(tPageData)
	local tPageParam = {}
	for nEquID, tConf in pairs(tPageData) do 
		table.insert(tPageParam, nEquID)
	end
	if #tPageParam <= 0 then 
		return 
	end

	local fnCallback = function(tEquTbl)
		if not tEquTbl then 
			return 
		end
		print(string.format("摆摊创建装备缓存信息成功, PageID(%d)", nPageID))
		for nEquID, tEquData in pairs(tEquTbl) do 
			local tBourseConf = ctBourseItem[nEquID]
			local nPageID = tBourseConf.nTradeMenuId
			local tEquCachePage = self.m_tSysEquipCache[nPageID] or {}
			tEquCachePage[nEquID] = tEquData
			self.m_tSysEquipCache[nPageID] = tEquCachePage
		end
	end
	local nMirrorID = 0
	for nRoleID, oRole in pairs(goGPlayerMgr.m_tRoleIDMap) do 
		if not oRole:IsRobot() then 
			nMirrorID = nRoleID
			break 
		end
	end
	if nMirrorID <= 0 then --当前服务器没有角色
		return 
	end
	local nServiceID = 50  --暂时硬编码 TODO
	goRemoteCall:CallWait("CreateSysEquCacheReq", fnCallback, gnServerID, 
		nServiceID, 0, tPageParam, nMirrorID)
end

function CMarketMgr:CheckSysEquCache() 
	local tQueryData = {}
	for nPageID, tPageData in pairs(self.m_tEquTradePage) do 
		if not self.m_tSysEquipCache[nPageID] then 
			self:CreateSysEquCache(nPageID)
		end
	end
end

--定期清理玩家stall和view数据
function CMarketMgr:TickRoleData()
	self:TickRoleStall()
	self:TickRoleView()
end

function CMarketMgr:OnMinuTimer()
	self:UpdateActiveTradeData()
	self:CheckSysEquCache()
end



goMarketMgr = goMarketMgr or CMarketMgr:new()
goMarketMgr:ConfInit()


