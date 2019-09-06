---背包基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
--物品类定义
local tItemClass = gtGDef.tItemClass
--本地化
local gtGDef = gtGDef

function CKanpsackBase:Ctor(oRole, nKnapType)
	assert(oRole and nKnapType, "参数错误")
	self.m_oRole = oRole
	self.m_nKnapType = nKnapType
	self.m_nGridNum = ctKnapsackEtcConf[1].nInitGrids 	--背包开放格子数
	self.m_tGridMap = {} 								--背包道具 {[grid]=obj,...}
	self.m_tItemGridMap = {} 							--物品ID->格子列表映射 {[itemid]={[grid]=1,...}}

	self.m_tItemSyncCached = {} 	--背包同步缓存
	self.m_bDirty = false

end

function CKanpsackBase:IsDirty() return self.m_bDirty end
function CKanpsackBase:MarkDirty(bDirty) self.m_bDirty = bDiry end

function CKanpsackBase:GetItemClass(nItemID)
	local tItemConf = assert(ctItemConf[nItemID], "物品配置不存在:"..nItemID)
	local cClass = assert(tItemClass[tItemConf.nType], "物品类定义不存在:"..tItemConf.nType)
	return cClass
end

function CKanpsackBase:LoadData(tData)
	self.m_nGridNum = tData.m_nGridNum
	for nGrid, tItem in pairs(tData.m_tGridMap) do
		local cClass = self:GetItemClass(tItem.m_nItemID)
		local oItem = cClass:new()
		oItem:LoadData(tItem)
		self.m_tGridMap[nGrid] = oItem
	end
end

function CKanpsackBase:SaveData()
	local tData = {}
	tData.m_nGridNum = self.m_nGridNum
	tData.m_tGridMap = {}
	for nGrid, oItem in pairs(self.m_tGridMap) do
		tData.m_tGridMap[nGrid] = oItem:SaveData()
	end
	return tData
end

function CKanpsackBase:Online() end

function CKanpsackBase:GetItemByGrid(nGrid)
	return self.m_tGridMap[nGrid]
end

--是否同类物品
function CKanpsackBase:IsSameItem(oItem, nItemID, bBind)
	local nBind1 = oItem:IsBind() and 1 or 0
	local nBind2 = bBind and 1 or 0
	if oItem:GetID() == nItemID and nBind1 == nBind2 then
		return true
	end
	return false
end

--通过物品ID取对象列表
--@nBind 0非绑; 1绑定; 2全部. 默认全部
function CKanpsackBase:GetItemList(nItemID, nBind)
	nBind = nBind or 2
	assert(nBind == 0 or nBind == 1 or nBind == 2, "参数错误")

	local tItemList = {}
	local tItemGridMap = self.m_tItemGridMap[nItemID]
	if tItemGridMap then
		for nGrid, v in pairs(tItemGridMap) do
			local oItem = self.m_tGridMap[nGrid]
			if nBind == 2 or (oItem:IsBind() and 1 or 0) == nBind then
				table.insert(tItemList, oItem)
			end
		end
	end
	return tItemList
end

--通过物品ID取物品数量
--@nBind 0非绑; 1绑定; 2先绑定后非绑(全部). 默认2
function CKanpsackBase:GetItemCount(nItemID, nBind)
	local nItemCount = 0
	local tItemList = self:GetItemList(nItemID, nBind)
	for _, oItem in ipairs(tItemList) do
		nItemCount = nItemCount + oItem:GetNum()
	end
	return nItemCount
end

--根据道具类型创建道具对象
function CKanpsackBase:CreateItem(nItemID, nGrid, bBind, tItemExt)
	tITemExt = tItemExt or {}
	local tConf = assert(ctItemConf[nItemID], "物品配置不存在:"..nItemID)
	local cItem = gtItemClass[tConf.nType]
	if not cItem then
		return LuaTrace("道具未实现", tConf)
	end
	local oItem = cItem:new(self, nItemID, nGrid, bBind, tItemExt)
	return oItem
end

--取空闲格子
function CKanpsackBase:GetFreeGrid()
	local nFreeGrid = 0
	for k = 1, self.m_nGridNum do
		if not self.m_tGridMap[k] then
			nFreeGrid = k
			break
		end
	end
	return nFreeGrid
end

--取背包空闲格子数
function CKanpsackBase:GetFreeGridCount()
	local nCount = 0
	for k = 1, self.m_nGridNum do
		if not self.m_tGridMap[k] then
			nCount = nCount + 1
		end
	end
	return nCount
end

--取背包剩余可放道具数量
--@bBind true绑定, false非绑定
function CKanpsackBase:GetRemainCapacity(nItemID, bBind)
	bBind = bBind and true or false
	local tConf = ctItemConf[nItemID]
	if not tConf or tConf.nType == gtItemType.eCurr then
		return gtGDef.tConst.nMaxInteger
	end
	local nFreeGridCount = self:GetFreeGridCount()
	local nRemainCapacity = nFreeGridCount * tConf.nFold

	local tItemGridMap = self.m_tItemGridMap[nItemID]
	if tItemGridMap then
		for nGrid, v in pairs(tItemGridMap) do
			local oItem = self.m_tGridMap[nGrid]
			if self:IsSameItem(oItem, nItemID, bBind) then
				nRemainCapacity = nRemainCapacity + oItem:EmptyNum()
			end
		end
	end
	return nRemainCapacity
end

--取新增物品占用新格子数量
function CKanpsackBase:GetNewGridOccupy(nItemID, nNum, bBind)
	assert(nItemID and nNum, "参数错误")
	bBind = bBind and true or false
	if nNum <= 0 then 
		return 0
	end
	local tConf = assert(ctItemConf[nItemID], "物品配置不存在:"..nItemID)
	if tConf.nType == gtGDef.tItemType.eCurr then
		return 0
	end
	assert(tConf.nFold > 0, "配置错误或者不是道具")
	local nRemainCapacity = 0
	local tItemGridMap = self.m_tItemGridMap[nItemID]
	if tItemGridMap then
		for nGrid, v in pairs(tItemGridMap) do
			local oItem = self.m_tGridMap[nGrid]
			if self:IsSameItem(oItem, bBind) then
				nRemainCapacity = nRemainCapacity + oItem:EmptyNum()
			end
		end
	end
	if nRemainCapacity >= nNum then 
		return 0
	end
	return math.ceil((nNum - nRemainCapacity) / tConf.nFold)
end

--@tItem {nID=0,nNum=0,bBind=0,tItemExp={}}
function CKanpsackBase:AddItem(tItem)
	if tItem.nNum == 0 then
		return
	end
	local nItemID = tItem.nID
	local nItemNum = tItem.nNum
	local tItemExt = tItem.tItemExt
	local bBind = tItem.bBind and true or false

	if nItemNum > gtGDef.tConst.nMaxKnapsackAddOnce then
		return self.m_oRole:Tips("每次最多能加物品:"..tConst.nMaxKnapsackAddOnce)
	end
	local tConf = ctItemConf[nItemID]
	if not tConf then
		return self.m_oRole:Tips("物品配置不存在:"..nItemID)
	end
	if tConf.nType == gtGDef.tItemType.eCurr then
		return self.m_oRole:Tips("货币物品不能加入背包:"..nItemID)
	end
	local cClass = gtItemClass[tConf.nType]
	if not cClass then
		return self.m_oRole:Tips("物品未实现:"..nItemID)
	end

	--先加满未满道具
	local tItemGridMap = self.m_tItemGridMap[nItemID]
	if tItemGridMap then
		for nGrid, v in pairs(tItemGridMap) do
			local oItem = self.m_tGridMap[nGrid]
			local nAddNum = math.min(oItem:GetFreeNum(), nItemNum)
			if nAddNum > 0 then
				oItem:AddNum(nAddNum)
				nItemNum = nItemNum - nAddNum
				self:OnItemModified(oItem)
			end
			if nItemNum <= 0 then
				break
			end
		end
	end
	--有剩余加到空闲格子
	if nItemNum > 0 then
		for nGrid = 1, self.m_nGridNum do
			if not self.m_tGridMap[nGrid] then
				local oItem = self:CreateItem(nItemID, nGrid, bBind, tItemExt)
				local nAddNum = math.min(nItemNum, oItem:GetFreeNum())
				oItem:AddNum(nAddNum)
				self.m_tGridMap[nGrid] = oItem
				nItemNum = nItemNum - nAddNum
				self:OnItemAdded(oItem, true)
				if nItemNum <= 0 then
					break
				end
			end
		end
	end
	self:MarkDirty(true)

	--背包已满
	if nItemNum > 0 then
		local tItemList = {{nItemID,nItemNum,bBind,tItemExt}} 
		CUtil:SendMail(self.m_oRole:GetServerID(), "背包已满", "请及时领取邮件中物品", tItemList, self.m_oRole:GetID())
		self.m_oRole:Tips("背包空间不足，请及时清理背包")
	end
	return self:GetItemCount(nItemID)
end

--扣除物品: 优先扣除绑定道具,优先扣除格子道具数量少的格子
--@tItem {nID=0,nNum=0,bBind=0,tItemExp={}} bBind会被忽略
function CKanpsackBase:SubItemByID(tItem)
	local nItemID = tItem.nID
	local nItemNum = tItem.nNum
	local tItemExt = tItem.tItemExt

	assert(nItemNum >= 0, "数量错误:"..nItemNum)
	if nItemNum == 0 then
		return
	end

	local fnCmp = function(oItem1, oItem2) 
		return oItem1:GetNum() < oItem2:GetNum()
	end

	local tBindItemList = {}
	local tNormalItemList = {}

	local tItemGridMap = self.m_tItemGridMap[nItemID]
	if not tItemGridMap then
		return
	end
	for nGrid, v in pairs(tItemGridMap) do
		local oItem = self.m_tItemGridMap[nGrid]
		if oItem:IsBind() then
			table.insert(tBindItemList, oItem)
		else
			table.insert(tNormalItemList, oItem)
		end
	end

	local function fnSubItem(tItemList)
		for _, oItem in ipairs(tItemList) do
			local nSubNum = math.min(oItem:GetNum(), nItemNum)
			oItem:SubNum(nSubNum)
			nItemNum = nItemNum - nSubNum
			if oItem:GetNum() == 0 then
				self.m_tGridMap[oItem:GetGrid()] = nil
				self:OnItemRemoved(oItem) 
			else
				self:OnItemModified(oItem)
			end
			if nItemNum <= 0 then 
				break 
			end
		end
	end
	if #tBindItemList then
		table.sort(tBindItemList, fnCmp)
		fnSubItem(tBindItemList)
	end

	if nItemNum > 0 and #tNormalItemList > 0 then
		table.sort(tNormalItemList, fnCmp)
		fnSubItem(tNormalItemList)
	end
	self:MarkDirty(true)
	return self:GetItemCount(nID)
end

--@tItemList {{nGrid=0, nID=0, nNum=0}, ...}
function CKanpsackBase:SubGridItemList(tItemList, sReason) 
	--先检查是否足够
	local tGridMap = {}
	for _, tItem in ipairs(tItemList) do 
		local nGrid = tItem.nGrid
		local nID = tItem.nID
		local nNum = tItem.nNum
		local oItem = self.m_tGridMap[nGrid]
		if not oItem then
			return false, "物品不存在"
		end
		if oItem:GetID() ~= nID then
			return false, "物品ID错误"
		end
	
		if oItem:GetNum() < nNum then
			return false, "物品数量不足"
		end
		if tGridMap[nGrid] then 
			return false, "物品重复"
		end
		tGridMap[nGrid] = tItem
	end

	for nGrid, tItem in pairs(tGridMap) do
		local nID = tItem.nID
		local nNum = tItem.nNum
		local oItem = self.m_tGridMap[nGrid]
		oItem:SubNum(nNum)
		if oItem:GetNum() <= 0 then
			self.m_tGridMap[nGrid] = nil
			self:OnItemRemoved(oItem)
		else
			self:OnItemModified(oItem)
		end
		self:MarkDirty(true)
		GetGModule("Logger"):AwardLog(gtEvent.eSubItem, sReason, self.m_oRole, nID, nNum, self:GetItemCount(nID)) 
	end
	self:SyncItemCache()
	return true
end


--物品添加成功
function CKanpsackBase:OnItemAdded(oItem, bNewItem)
	local tInfo = oItem:GetInfo()
	tInfo.nOpera = 1
	table.insert(self.m_tItemSyncCached, tInfo)
end

--物品修改成功
function CKanpsackBase:OnItemModified(oItem)
	local tInfo = oItem:GetInfo()
	tInfo.nOpera = 2
	table.insert(self.m_tItemSyncCached, tInfo)
end

--物品删除成功
function CKanpsackBase:OnItemRemoved(oItem)
	local tInfo = oItem:GetInfo()
	tInfo.nOpera = 3
	table.insert(self.m_tItemSyncCached, tInfo)
end

--清除消息缓存
function CKanpsackBase:ClearItemSyncCached()
	self.m_tItemSyncCached = {}
end

--同步消息缓存
function CKanpsackBase:SyncItemCache()
	self.m_oRole:SendMsg("KnapsackItemOperaRet", {tList=self.m_tItemSyncCached})
	self:ClearItemSyncCached()
end

--同步背包道具列表
function CKanpsackBase:SynCKanpsackItemList()
	local tItemList = {}
	for nGrid, oItem in pairs(self.m_tGridMap) do
		table.insert(tItemList, oItem:GetInfo())
	end
	local tMsg = {tItemList=tItemList, nGridNum=self.m_nGridNum}
	self.m_oRole:SendMsg("KnapsackItemListRet", tMsg)
end

--GM清空背包
function CKanpsackBase:GMClrKnapsack()
	self.m_tGridMap = {}
	self.m_tItemGridMap = {}
	self:MarkDirty(true)

	self:ClearItemSyncCached()
	self:SynCKanpsackItemList()
	self.m_oRole:Tips("清空背包成功")
	
end

--使用道具请求
function CKanpsackBase:ItemUseReq(tData)
	local nGrid = tData.nGrid
	local nUseNum = tData.nUseNum
	local oItem = self:GetItem(nGrid)
	if not oItem then
		return self.m_oRole:Tips("物品不存在")
	end
	local tItemConf = ctItemConf[oItem:GetID()]
	if nUserNum > 1 and (not tItemConf.bBatchUseable) then
		return self.m_oRole:Tips("该物品不能批量使用")
	end
	if not oItem.Use then
		return self.m_oRole:Tips(string.format("%s不能使用", tItemConf.sName))
	end
	oItem:Use(nUseNum)
end

--出售道具请求
--@tData.tList {{nGrid=0,nNum=0}, ...}
function CKanpsackBase:ItemSellReq(tData)
	local oItem = self:GetItem(nGrid)
	if not oItem then
		return self.m_oRole:Tips("道具不存在")
	end
	-- if oItem:GetNum() < nNum then
	-- 	return self.m_oRole:Tips("道具数量不足")
	-- end
	-- --只要配了价格，不管绑不绑定都可以出售	
	-- local nSellCopperPrice = oItem:GetItemConf().nSellCopperPrice
	-- local nSellGoldPrice = oItem:GetItemConf().nSellGoldPrice
	-- if nSellCopperPrice <= 0 and nSellGoldPrice <= 0 then
	-- 	return self.m_oRole:Tips("道具不可出售(出售价格配置错误?)")
	-- end

	-- oItem:Sell(nNum, nType)

	if nNum < 0 then 
		self.m_oRole:Tips("参数错误")
		return 
	end
	if oItem:GetNum() < nNum then 
		self.m_oRole:Tips("道具数量不足")
		return 
	end

	if nType == 1 then 
		if not oItem:CheckSaleGold() then 
			self.m_oRole:Tips("该道具不可出售")
			return
		end
	elseif nType == 2 then 
		if not oItem:CheckSaleSilver() then 
			self.m_oRole:Tips("该道具不可回收")
			return
		end
	else
		self.m_oRole:Tips("参数错误")
		return
	end
	local tSaleList = {{nID = oItem:GetID(), nGrid = nGrid, nNum = nNum, nType = nType}, }

	local fnQueryCallback = function(bSucc, tSrcItemList, tPriceList) 
		if not bSucc then 
			return 
		end
		local tItemPrice = tPriceList[1]
		local nCurrType = tItemPrice.nCurrType
		local nMoney = tItemPrice.nPrice * nNum
		if nMoney < 0 then 
			print("价格错误")
			return 
		end

		local fnConfirmCallback = function(tData) 
			if tData.nSelIdx == 1 then  --取消
				return
			elseif tData.nSelIdx == 2 then  --确定
				self:ItemListSellReq(tSaleList)
			end
		end
		if nCurrType == gtCurrType.eBYuanBao then 
			if self.m_nDailySaleYuanbaoNum >= nDailySaleYuanbaoLimitNum then 
				nCurrType = gtCurrType.eYinBi
				nMoney = nMoney * gnSaleSilverRatio
			end
		end

		local sType = (nType == 1) and "出售" or "回收"
		local nCurrName = gtCurrName[nCurrType]
		if nCurrType == gtCurrType.eBYuanBao then 
			nCurrName = "绑定元宝"
		end
		local sCont = string.format("%s将获得 %d %s", sType, nMoney, nCurrName)
		local tMsg = {sCont=sCont, tOption={"取消", "确定"}, nTimeOut=30, nTimeOutSelIdx=1}
		goClientCall:CallWait("ConfirmRet", fnConfirmCallback, self.m_oRole, tMsg)
	end
	self:QueryItemListSalePrice(tSaleList, fnQueryCallback) 
end

--tItemList={{nID=, nGrid=, nNum=, nType=,}, ...} --nID主要用于验证用，防止前端数据不同步，错误出售道具
--fnCallback(bSucc, tMoneyList) 是否出售成功
--单次最多支持100个道具
function CKanpsackBase:ItemListSellReq(tItemList, fnCallback)
	assert(tItemList, "参数错误")
	local oRole = self.m_oRole
	local fnInnerCallback = function(bSucc, tRetData)
		if not bSucc then 
			if tRetData and type(tRetData) == "string" then 
				self.m_oRole:Tips(tRetData)
			end
		end
		if fnCallback then 
			fnCallback(bSucc, tRetData)
		end
	end

	if #tItemList <= 0 or #tItemList > nItemOpNumLimit then 
		fnInnerCallback(false)
		return 
	end

	tItemList = table.DeepCopy(tItemList)  --防止外层继续使用修改这个数据，导致异步回调数据不对
	local tTempItemMap = {} 
	for _, tItem in ipairs(tItemList) do 
		if tItem.nID <= 0 or tItem.nNum < 0 or tItem.nGrid <= 0 then 
			print("参数错误")
			return 
		end
		if tTempItemMap[tItem.nGrid] then 
			assert(false, "错误数据！！出售道具列表存在重复数据")
		end
		tTempItemMap[tItem.nGrid] = tItem
	end
	
	local fnPriceCallback = function(bSucc, tSrcItemList, tPriceList)
		if not bSucc then 
			fnInnerCallback(false, "价格数据错误")
			return 
		end

		if self.m_oRole:IsReleasedd() then --角色已释放，不回调相关事件
			return
		end

		local tGridPriceMap = {}
		for _, tPriceData in pairs(tPriceList) do 
			tGridPriceMap[tPriceData.nGrid] = tPriceData
		end

		for _, tItem in pairs(tItemList) do 
			local nItemID = tItem.nID
			local oItem = self.m_tGridMap[tItem.nGrid]
			--做一下必要检查，防止异步期间，道具发生变化
			if not oItem or oItem:GetID() ~= tItem.nID or oItem:GetNum() < tItem.nNum then
				fnInnerCallback(false, "出售失败")
				return 
			end
			if (tItem.nType == 1 and not oItem:CheckSaleGold())
			or (tItem.nType == 2 and not oItem:CheckSaleSilver()) then 
				fnInnerCallback(false, "出售失败")
				return 
			end
			local tPriceData = tGridPriceMap[tItem.nGrid]
			if not tPriceData or tPriceData.nPrice < 0 then 
				fnInnerCallback(false, "出售失败")
				return 
			end
		end

		local tMoneyMap = {}
		local tSubItemList = {}
		for _, tItem in pairs(tItemList) do 
			local nItemID = tItem.nID
			local oItem = self.m_tGridMap[tItem.nGrid]
			-- local sReason = "一键出售"
			-- if tItem.nType == 2 then 
			-- 	sReason = "一键回收"
			-- end
			if tItem.nNum > 0 then 
				-- self:SubGridItem(tItem.nGrid, tItem.nID, tItem.nNum, sReason)
				table.insert(tSubItemList, {nGrid = tItem.nGrid, nID = tItem.nID, nNum = tItem.nNum})
				local tPriceData = tGridPriceMap[tItem.nGrid]
				tMoneyMap[tPriceData.nCurrType] = (tMoneyMap[tPriceData.nCurrType] or 0) + (tPriceData.nPrice)*tItem.nNum
			end
		end

		if #tSubItemList <= 0 then 
			return 
		end

		if not self:SubGridItemList(tSubItemList, "一键出售") then 
			self.m_oRole:Tips("出售失败")
			return 
		end

		local tAddMap = {}  --真实添加的数量，避免多次提示前端同一种道具

		local nSaleYuanbaoRecord = self.m_nDailySaleYuanbaoNum
		local bTransYinbi = false
		for nCurrType, nMoney in pairs(tMoneyMap) do 
			if nCurrType == gtCurrType.eBYuanBao then 
				local nRemain = math.max(nDailySaleYuanbaoLimitNum - nSaleYuanbaoRecord, 0)
				if nRemain < nMoney then 
					local nSilverNum = (nMoney - nRemain) * gnSaleSilverRatio
					nMoney = nRemain
					tAddMap[gtCurrType.eYinBi] = (tAddMap[gtCurrType.eYinBi] or 0) + nSilverNum
					bTransYinbi = true
				end
				nSaleYuanbaoRecord = nSaleYuanbaoRecord + nMoney
			end
			if nMoney > 0 then 
				tAddMap[nCurrType] = (tAddMap[nCurrType] or 0) + nMoney
			end
		end

		if nSaleYuanbaoRecord > self.m_nDailySaleYuanbaoNum then --出售将获得绑定元宝
			self:AddDailySaleYuanbaoRecord(nSaleYuanbaoRecord - self.m_nDailySaleYuanbaoNum)
		end
		for nCurrType, nMoney in pairs(tAddMap) do 
			self.m_oRole:AddItem(gtItemType.eCurr, nCurrType, nMoney, "一键出售回收")
		end
		if bTransYinbi then 
			self.m_oRole:Tips("已超过每日回收可获得绑定元宝上限，已自动转换为银币")
		end
	end
	self:QueryItemListSalePrice(tItemList, fnPriceCallback)
end

function CKanpsackBase:GetDailySaleYuanbaoRemainNum()
	return math.max(nDailySaleYuanbaoLimitNum - self.m_nDailySaleYuanbaoNum, 0)
end

function CKanpsackBase:AddDailySaleYuanbaoRecord(nNum) 
	if self.m_nDailySaleYuanbaoNum >= nDailySaleYuanbaoLimitNum then 
		return 
	end
	self.m_nDailySaleYuanbaoNum = self.m_nDailySaleYuanbaoNum + nNum
	self:MarkDirty(true)
	self:SyncSaleYuanbaoRecord()
end

function CKanpsackBase:SyncSaleYuanbaoRecord() 
	local tMsg = {}
	-- tMsg.nRemain = math.max(nDailySaleYuanbaoLimitNum - self.m_nDailySaleYuanbaoNum, 0)
	tMsg.nRemain = self:GetDailySaleYuanbaoRemainNum()
	self.m_oRole:SendMsg("KnapsackSaleYuanbaoRecordRet", tMsg)
end

-- tItemList {{nID=, nGrid=, nType=, }, ...}
function CKanpsackBase:ItemSalePriceReq(tItemList) 
	if not tItemList or #tItemList <= 0 then 
		return 
	end
	local fnPriceCallback = function(bSucc, tItemList, tPriceList)
		if not bSucc or not tPriceList then 
			return 
		end
		local tMsg = {}
		tMsg.tItemPriceList = tPriceList
		self.m_oRole:SendMsg("KnapsackItemSalePriceRet", tMsg)
	end
	self:QueryItemListSalePrice(tItemList, fnPriceCallback)
end

function CKanpsackBase:GetBaseGoldPrice(nItemID)
	local tConf = ctItemConf[nItemID]
	assert(tConf)
	return tConf.nSellGoldPrice
end

function CKanpsackBase:GetBaseSilverPrice(nItemID) 
	local tConf = ctItemConf[nItemID]
	assert(tConf)
	local nSilverPrice = tConf.nSellCopperPrice
	if nSilverPrice <= 0 then --暂时不加绑定判断，默认调用此接口的都是可回收银币的
		nSilverPrice = 2000
	end
	return nSilverPrice
end

-- tItemList {{nID=, nGrid=, nType=, }, ...}
-- fnCallback(bSucc, tItemList, tPriceList)  tPriceList {{nID=, nGrid=, nType=, nCurrType=, nPrice=, }, ...}
function CKanpsackBase:QueryItemListSalePrice(tItemList, fnCallback) 
	assert(tItemList)
	local oRole = self.m_oRole
	local fnInnerCallback = function(bSucc, tRetData)
		if not bSucc then 
			if tRetData and type(tRetData) == "string" then 
				self.m_oRole:Tips(tRetData)
			end
			tRetData = nil
		end
		if fnCallback then 
			fnCallback(bSucc, tItemList, tRetData)
		end
	end

	if #tItemList <= 0 or #tItemList > nItemOpNumLimit then --单次最多100个数据
		-- print(string.format("查询数据错误, 当前查询道具数量(%d)", #tItemList))
		fnInnerCallback(false, "查询数据错误")
		return 
	end

	local tTempItemMap = {} 
	for _, tItem in ipairs(tItemList) do 
		if tTempItemMap[tItem.nGrid] then 
			assert(false, "错误数据！！出售道具列表存在重复数据")
		end
		tTempItemMap[tItem.nGrid] = tItem
	end

	local tQueryShopMap = {}
	local tQueryMarketMap = {}
	-- local tSaleGold = {}
	-- local tSaleSilver = {}
	for nGrid, tItem in pairs(tTempItemMap) do 
		local nItemID = tItem.nID
		local oItem = self.m_tGridMap[tItem.nGrid]
		if not oItem then --错误数据
			local sTipContent = "道具不存在"
			if ctItemConf[tItem.nID] then 
				sTipContent = string.format("%s不存在", ctItemConf:GetFormattedName(tItem.nID))
			end
			fnInnerCallback(false, sTipContent)
			return
		end
		if oItem:GetID() ~= tItem.nID then 
			fnInnerCallback(false, "数据错误")
			return
		end
		local bSell, sReason = oItem:CheckSale()
		if not bSell then 
			fnInnerCallback(false, sReason)
			return
		end

		if ctCommerceItem[nItemID] then 
			tQueryShopMap[tItem.nGrid] = {nGrid = tItem.nGrid, nItemID = nItemID, 
				nBuyPrice = (oItem:GetBuyPrice() or 0)}
		elseif tItem.nType == 2 and ctBourseItem[nItemID] then
			local nItemType = ctItemConf[nItemID].nType
			if nItemType == gtItemType.eEquipment or nItemType == gtItemType.eRarePrecious then 
				tQueryMarketMap[nItemID] = true
			end
		end

		if tItem.nType == 1 then --出售金币
			if not oItem:CheckSaleGold() then  --检查是否可出售为金币
				local sTipsContent = string.format("%s不可出售", oItem:GetFormattedName())
				fnInnerCallback(false, sTipsContent)
				return 
			end
			-- table.insert(tSaleGold, tItem)
		elseif tItem.nType == 2 then --回收银币
			if not oItem:CheckSaleSilver() then  --检查是否可出售为银币
				local sTipsContent = string.format("%s不可回收", oItem:GetFormattedName())
				fnInnerCallback(false, sTipsContent)
				return
			end
			-- table.insert(tSaleSilver, tItem)
		else
			assert(false, "数据错误")
		end
	end

	local tQueryMarketList = {}
	for nID, _ in pairs(tQueryMarketMap) do 
		table.insert(tQueryMarketList, nID)
	end

	local fnPriceProc = function(nSaleType, nCurrType, nPrice)
		local nSaleCurrType = nCurrType
		local nSalePrice = nPrice
		if nSaleType == 1 then
			assert(nCurrType == gtCurrType.eJinBi, "货币类型错误")
		elseif nSaleType == 2 then 
			nSaleCurrType = gtCurrType.eBYuanBao
			if nCurrType == gtCurrType.eJinBi then 
				nSalePrice = nPrice * (gnSilverRatio / gnSaleSilverRatio) // gnGoldRatio
			elseif nCurrType == gtCurrType.eYinBi then 
				nSalePrice = nPrice // gnSaleSilverRatio
			else
				assert(false, "货币类型错误")
			end
		end
		return nSaleCurrType, nSalePrice
	end

	local fnShopCallback = function(tShopResult) 
		if not tShopResult then 
			fnInnerCallback(false)
			return 
		end
		local fnMarketCallback = function(tMarketResult) 
			if not tMarketResult then 
				fnInnerCallback(false)
				return 
			end

			local tPriceList = {}  --{nID=, nGrid=, nType=, nCurrType=, nPrice=, }
			for _, tItem in ipairs(tItemList) do 
				local nID = tItem.nID
				local nGrid = tItem.nGrid
				local nType = tItem.nType
				local tPriceData = {nID = nID, nGrid = nGrid, nType = nType}
				local nCurrType
				local nPrice
				if ctCommerceItem[nID] then 
					local tItemPrice = tShopResult[tItem.nGrid]
					assert(tItemPrice, "查询商会数据错误")
					nCurrType, nPrice = fnPriceProc(nType, gtCurrType.eJinBi, tItemPrice.nSalePrice)
				elseif nType == 2 and ctBourseItem[nID] then --出售银币，且在摆摊有售的
					local nItemType = ctItemConf[nID].nType
					--需要查询摆摊价格的 
					if nItemType == gtItemType.eEquipment or nItemType == gtItemType.eRarePrecious then 
						nPrice = tMarketResult[nID] // 2
						nCurrType, nPrice = fnPriceProc(nType, gtCurrType.eYinBi, tMarketResult[nID] // 2)
					else
						nCurrType, nPrice = fnPriceProc(nType, gtCurrType.eYinBi, CKanpsackBase:GetBaseSilverPrice(nID))
					end
				else
					if nType == 1 then 
						nCurrType, nPrice = fnPriceProc(nType, gtCurrType.eJinBi, CKanpsackBase:GetBaseGoldPrice(nID))
					elseif nType == 2 then 
						nCurrType, nPrice = fnPriceProc(nType, gtCurrType.eYinBi, CKanpsackBase:GetBaseSilverPrice(nID))
					else
						assert(false)
					end
				end
				tPriceData.nCurrType = nCurrType
				tPriceData.nPrice = nPrice
				table.insert(tPriceList, tPriceData)
			end
			fnInnerCallback(true, tPriceList)
		end

		if #tQueryMarketList > 0 then 
			local nServer = oRole:GetServer()
			local nService = goServerMgr:GetGlobalService(nServer, 20)
			Network:RMCall("GetMarketBasePriceTblReq", fnMarketCallback, 
				nServer, nService, 0, tQueryMarketList)
		else
			fnMarketCallback({})
		end
	end
	if next(tQueryShopMap) then 
		local nServer = oRole:GetServer()
		local nService = goServerMgr:GetGlobalService(nServer, 20)
		Network:RMCall("QueryCommerceSalePriceTblReq", fnShopCallback, 
			nServer, nService, 0, tQueryShopMap)
	else
		fnShopCallback({})
	end

end



--整理背包请求
--@nType 1背包,2仓库
function CKanpsackBase:ArrangeReq(nType)
	local nCDTime = 0
	if nType == 1 then
		nCDTime = 30 - math.abs(os.time() - self.m_nArrangeTime)  --防止服务器更改时间
	else
		nCDTime = 30 - math.abs(os.time() - self.m_nStoArrangeTime)
	end
	if nCDTime > 0 then
		return self.m_oRole:Tips(string.format("操作过于频繁，请%d秒后再进行操作", nCDTime))
	end

	--设置整理时间
	if nType == 1 then
		self.m_nArrangeTime = os.time()
	else
		self.m_nStoArrangeTime = os.time()
	end
	self:MarkDirty(true)

	--背包类型
	local tGridMap
	if nType == 1 then
		tGridMap = self.m_tGridMap
	--仓库
	else
		tGridMap = self.m_tStorageGridMap
	end

	--找出相同的没满的道具合并
	local tSameItemMap = {}
	for _, oItem in pairs(tGridMap) do
		if not oItem:IsFull() then
			local sKey = oItem:GetID()..tostring(oItem:IsBind())
			if not tSameItemMap[sKey] then tSameItemMap[sKey] = {} end
			assert(oItem:GetNum() > 0)
			table.insert(tSameItemMap[sKey], oItem)
		end
	end
	for sKey, tItemList in pairs(tSameItemMap) do
		for k=1, #tItemList-1 do --从前往后
			local oItem1 = tItemList[k]
			if oItem1:GetNum() <= 0 then break end

			for j=#tItemList, k+1, -1 do --从后往前
				local oItem2 = tItemList[j]
				if oItem2:GetNum() > 0 then
					local nAddNum = math.min(oItem1:EmptyNum(), oItem2:GetNum())
					oItem1:AddNum(nAddNum)
					oItem2:SetNum(oItem2:GetNum()-nAddNum)
					if oItem2:GetNum() <= 0 then --被合并的清理掉
						tGridMap[oItem2:GetGrid()] = nil
					end
					if oItem1:IsFull() then
						break
					end
				end
			end
		end
	end

	--筛选排序道具
	local tFrontList = {}
	local tOtherList = {}
	for nGrid, oItem in pairs(tGridMap) do
		if oItem:GetType() <= gtItemType.eCooking then
			table.insert(tFrontList, oItem)
		else
			table.insert(tOtherList, oItem)
		end
	end
	table.sort(tFrontList, function(oItem1, oItem2)
		local nType1, nType2 = oItem1:GetType(), oItem2:GetType()
		if nType1==nType2 then return oItem1:GetID()<oItem2:GetID() end
		return nType1<nType2 
	end)
	table.sort(tOtherList, function(oItem1, oItem2) return oItem1:GetID() < oItem2:GetID() end)

	--重新放置道具
	local nGrid = 1
	local tGridMap
	if nType == 1 then
		self.m_tGridMap = {}
		tGridMap = self.m_tGridMap
	else
		self.m_tStorageGridMap = {}
		tGridMap = self.m_tStorageGridMap
	end

	for _, oItem in ipairs(tFrontList) do
		oItem:SetGrid(nGrid)
		tGridMap[nGrid] = oItem
		nGrid = nGrid + 1
	end
	for _, oItem in ipairs(tOtherList) do
		oItem:SetGrid(nGrid)
		tGridMap[nGrid] = oItem
		nGrid = nGrid + 1
	end

	--同步
	self:SynCKanpsackBaseItems()
end

--购买格子请求
--@nType 1背包,2仓库
--@nCurrType 0道具, 2元宝, 4金币, 5银币
function CKanpsackBase:BuyGridReq(nType, nCurrType)
	if nType == 1 then
		if self.m_nGridNum >= nMaxGrids then
			return self.m_oRole:Tips("已达背包容量上限，扩充失败")
		end
		assert(nMaxGrids > 0 and nMaxGrids > nInitGrids)
	else
		if self.m_nStorageGridNum >= nStoMaxGrids then
			return self.m_oRole:Tips("已达仓库容量上限，扩充失败")
		end
		assert(nStoMaxGrids > 0 and nStoMaxGrids > nStoInitGrids)
	end

	--背包
	if nType == 1 then
		local nBuyTimes = self.m_nBuyGridTimes+1
		local nItemNum = ctItemEtcConf[1].eExpandCost(nBuyTimes)
		local nLackItemNum = math.max(0, nItemNum-self.m_oRole:ItemCount(gtItemType.eItem, nExpandItem))
		local nYuanBao = nLackItemNum*ctItemConf[nExpandItem].nBuyPrice
		local nJinBi = nLackItemNum*ctItemConf[nExpandItem].nGoldPrice

		if nCurrType == gtCurrType.eYuanBao or nCurrType == gtCurrType.eAllYuanBao then
			if not self.m_oRole:CheckSubItem(gtItemType.eCurr, gtCurrType.eAllYuanBao, nYuanBao, "扩充背包格子") then
				return self.m_oRole:YuanBaoTips()
			end
			if not self.m_oRole:CheckSubItem(gtItemType.eItem, nExpandItem, nItemNum-nLackItemNum, "扩充背包格子") then
				return self.m_oRole:Tips(string.format("%s不足", self:ItemName(nExpandItem)))
			end

		elseif nCurrType == gtCurrType.eJinBi then
			if not self.m_oRole:CheckSubItem(gtItemType.eCurr, gtCurrType.eJinBi, nJinBi, "扩充背包格子") then
				return self.m_oRole:JinBiTips()
			end
			if not self.m_oRole:CheckSubItem(gtItemType.eItem, nExpandItem, nItemNum-nLackItemNum, "扩充背包格子") then
				return self.m_oRole:Tips(string.format("%s不足", self:ItemName(nExpandItem)))
			end

		elseif nCurrType == 0 then
			if not self.m_oRole:CheckSubItem(gtItemType.eItem, nExpandItem, nItemNum, "扩充背包格子") then
				return self.m_oRole:Tips(string.format("%s不足", self:ItemName(nExpandItem)))
			end

		else
			assert(false, "背包扩充格子消耗物品类型错误:"..nCurrType)
		end
		self.m_nGridNum = math.min(self.m_nGridNum + nBuyGridOnce, nMaxGrids)
		self.m_nBuyGridTimes = self.m_nBuyGridTimes + 1
		self.m_oRole:Tips("扩充背包格子成功")
		
	--仓库
	else
		local nBuyTimes = self.m_nStoBuyGridTimes+1
		local nYinBi = ctItemEtcConf[1].eStoExpandCost(nBuyTimes)
		if nCurrType == gtCurrType.eYinBi then
			if not self.m_oRole:CheckSubItem(gtItemType.eCurr, gtCurrType.eYinBi, nYinBi, "扩充仓库格子") then
				return self.m_oRole:YinBiTips()
			end
		elseif nCurrType == gtCurrType.eYuanBao or nCurrType == gtCurrType.eAllYuanBao then
			local nYuanBao = math.floor(nYinBi/10000)
			if not self.m_oRole:CheckSubItem(gtItemType.eCurr, gtCurrType.eAllYuanBao, nYuanBao, "扩充仓库格子") then
				return self.m_oRole:YuanBaoTips()
			end
		else
			assert(false, "仓库扩充格子消耗物品类型错误:"..nCurrType)
		end
		self.m_nStorageGridNum = math.min(self.m_nStorageGridNum + nBuyGridOnce, nStoMaxGrids)
		self.m_nStoBuyGridTimes = self.m_nStoBuyGridTimes + 1
		self.m_oRole:Tips("扩充仓库格子成功")

	end
	self:MarkDirty(true)

	local nGridNum = nType == 1 and self.m_nGridNum or self.m_nStorageGridNum
	local nBuyTimes = nType == 1 and self.m_nBuyGridTimes or self.m_nStoBuyGridTimes
	self.m_oRole:SendMsg("KnapsackBuyGridRet", {nType=nType, nGridNum=nGridNum, nBuyTimes=nBuyTimes})
end

--道具传送
--@bNotSync是否不同步
function CKanpsackBase:TransferItem(tItemData, bNotSync)
	--帮派神诏要特殊处理
	local tConf = ctItemConf[tItemData.m_nID]
	if not tConf then
		return self.m_oRole:Tips("道具配置不存在:"..tConf.nID)
	end
	local cClass = gtItemClass[tConf.nType]
	if not cClass then
		return self.m_oRole:Tips("道具未实现:"..tConf.nID)
	end

	local nAddNum = cClass:CheckCanAddNum(self.m_oRole, tItemData.m_nID, tItemData.m_nFold)
	if nAddNum <= 0 then
		return
	end
	tItemData.m_nFold = nAddNum

	local nFreeGrid = self:GetFreeGrid(1)
	if nFreeGrid <= 0 then --发送邮件
		CUtil:SendMail(self.m_oRole:GetServer(), "背包已满", "背包已满，请及时领取邮件", {tItemData}, self.m_oRole:GetID())
		self.m_oRole:Tips("背包空间不足，请及时清理背包")
		return 
	end
	local oItem = self:CreateItem(tItemData.m_nID, tItemData.m_nGrid)
	oItem:LoadData(tItemData)
	oItem:UpdateKey()
	oItem:SetGrid(nFreeGrid)
	self.m_tGridMap[nFreeGrid] = oItem
	self:OnItemAdded(nFreeGrid, 1, true, bNotSync)

	self:UpdateBuyPrice(tItemData.m_nID, tItemData.m_nBuyPrice or 0)
	self:MarkDirty(true)

	return self:ItemCount(oItem:GetID())
end

--取物品数据
function CKanpsackBase:GetItemData(nGrid)
	local oItem = self:GetItem(nGrid)
	if not oItem then
		return
	end
	local tItemData = oItem:SaveData()
	return tItemData 
end

--取多个道具数据
function CKanpsackBase:GetItemDataList(tList)
	local tItemData = {}
	for _, nGrid in pairs(tList) do
		local oItem = self:GetItem(nGrid)
		if oItem then
			tItemData[#tItemData+1] = oItem:SaveData()
		end
	end
	return tItemData
end

--通过ID取多个道具的数据
function CKanpsackBase:GetItemDataList(nItemID)
	local tItemData = {}
	for _, oItem in pairs(self.m_tGridMap) do
		if oItem:GetID() == nItemID then
			table.insert(tItemData, oItem:SaveData())
		end
	end
	return tItemData
end

--取宠物多个装备属性
function CKanpsackBase:KnapsacGetPetEquReq(tItemGrid)
	local tEquList = {}
	for _, tItem in pairs(tItemGrid) do
		oItem = self.m_tGridMap[tItem.nGrid]
		if oItem then
			tEquList[#tEquList+1] = oItem:GetDetailInfo(tItem.nGrid)
		end
	end
	local tMsg = {}
	tMsg.tPetEqu = tEquList
	self.m_oRole:SendMsg("KnapsacGetPetEquRet", tMsg)
end

function CKanpsackBase:GetItemByBox(nBoxType, nBoxParam)
	local oItem = nil
	if nBoxType == gtItemBoxType.eBag then
		oItem = self.m_tGridMap[nBoxParam]
	elseif nBoxType == gtItemBoxType.eEquipment then
		oItem = self.m_tWearEqu[nBoxParam]
	elseif nBoxType == gtItemBoxType.eStorage then
		oItem = self.m_tStorageGridMap[nBoxParam]
	else
		--return
	end
	return oItem
end

--CS PB协议用
function CKanpsackBase:GetItemDetailInfo(oItem, nBoxType, nBoxParam, nOtherType)
	assert(oItem, "参数错误")
	if not oItem.GetDetailInfo then
		-- self.m_oRole:Tips(string.format("道具 %s 详细信息未实现", oItem:GetName()))
		return
	end
	local nItemType = oItem:GetType()
	local tRetData = {}
	local tDetail = {}
	tDetail.nOtherType = nOtherType
	tRetData.tDetail = tDetail
	tDetail.nType = nItemType
	if nBoxType then 
		tDetail.nBoxType = nBoxType
	end
	if nBoxParam then 
		tDetail.nBoxParam = nBoxParam
	end 
	if nItemType == gtItemType.eEquipment then
		tDetail.tEqu = oItem:GetDetailInfo()
	end
	if nItemType == gtItemType.ePetEqu then
		tDetail.tPetEqu = oItem:GetDetailInfo()
	end
	if nItemType == gtItemType.eArtifact then
		tDetail.tArtifactEqu = oItem:GetDetailInfo()
	end
	return tRetData
end

--发送物品详细信息
function CKanpsackBase:SendItemDetailInfo(oItem, nBoxType, nBoxParam, nOtherType)
	local tRetData = self:GetItemDetailInfo(oItem, nBoxType, nBoxParam, nOtherType)
	if tRetData then 
		-- print("道具查询MSg", tRetData)
		return self.m_oRole:SendMsg("KnapsacItemDetailRet", tRetData)
	else
		self.m_oRole:Tips(string.format("道具 %s 详细信息未实现", oItem:GetName()))
	end
end

--获取物品详细信息
function CKanpsackBase:ItemDetailReq(nBoxType, nBoxParam, nOtherType)
	if not (nBoxType and nBoxParam) then
		return self.m_oRole:Tips("不合法的请求参数")
	end
	local oItem = self:GetItemByBox(nBoxType, nBoxParam)
	if not oItem then
		return self.m_oRole:Tips(string.format("道具不存在 boxtype:%d boxparam:%d", nBoxType, nBoxParam))
	end
	self:SendItemDetailInfo(oItem, nBoxType, nBoxParam, nOtherType)
end

function CKanpsackBase:CheckDailyReset(nTimeStamp)
	nTimeStamp = nTimeStamp or os.time()
	if os.IsSameDay(nTimeStamp, self.m_nDailyResetStamp, 0) then 
		return 
	end
	self.m_nWeddingCandyPickRecord = 0
	self.m_nOldManItemPickRecord = 0
	self.m_tItemUseRecord = {}
	self.m_nDailyResetStamp = nTimeStamp
	self.m_nDailySaleYuanbaoNum = 0
	self:MarkDirty(true)
	self:SyncSaleYuanbaoRecord()
end

function CKanpsackBase:OnHourTimer()
	self:CheckDailyReset()
end
--添加使用计数
function CKanpsackBase:AddUseCount(nItemID, nCount)
	assert(nItemID > 0 and nCount > 0, "参数错误")
	self.m_tItemUseRecord[nItemID] = (self.m_tItemUseRecord[nItemID] or 0) + nCount
	self:MarkDirty(true)
end
--获取使用计数
function CKanpsackBase:GetUseCount(nItemID)
	return self.m_tItemUseRecord[nItemID] or 0
end

function CKanpsackBase:AddPickWeddingCandyCount(nNum)
	self.m_nWeddingCandyPickRecord = self.m_nWeddingCandyPickRecord + nNum
	self:MarkDirty(true)
end

function CKanpsackBase:AddPickOldManItemCount(nNum)
	self.m_nOldManItemPickRecord = self.m_nOldManItemPickRecord + nNum
	self:MarkDirty(true)
end

function CKanpsackBase:GetPickOldManItemCount()
	return self.m_nOldManItemPickRecord
end

function CKanpsackBase:GetPickWeddingCandyCount()
	return self.m_nWeddingCandyPickRecord
end


function CKanpsackBase:IsOccupyBagGrid(nItemType, nItemID)
	if nItemType == gtItemType.eItem then 
		local tItemConf = ctItemConf[nItemID]
		if tItemConf and tItemConf.nType ~= gtItemType.eCurr then 
			return true
		end
	end
	return false
end

--外层有重新计算角色属性
function CKanpsackBase:OnRoleLevelChange(nOldLevel, nNewLevel)
	self:CheckLegendEquUpgrade()
	self:UpdateGemTips(true)
end

function CKanpsackBase:GetEquStrengthenTriggerID()
	return self.m_tStrengthenTriggerData.nTriggerID
end

function CKanpsackBase:GetEquStrengthenTriggerAttr()
	return self.m_tStrengthenTriggerData.tTriggerAttr
end

function CKanpsackBase:GetEquGemTriggerID()
	return self.m_tGemTriggerData.nTriggerID
end

function CKanpsackBase:GetEquGemTriggerAttr()
	return self.m_tGemTriggerData.tTriggerAttr
end

