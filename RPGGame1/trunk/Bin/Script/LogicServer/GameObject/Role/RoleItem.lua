--游戏角色物品相关
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local tItemType = gtGDef.tItemType

--取货币值
function CRole:GetCurrency()
	return (self.m_tCurrencyMap[nCurrType] or 0)
end

--添加货币
function CRole:AddCurrency(nCurrType, nAddValue)
	assert(nAddValue >= 0, "参数错误")
	if nAddValue == 0 then
		return
	end
	local nOldValue = self:GetCurrency(nCurrType)
	self.m_tCurrencyMap[nCurrType] = math.max(0, math.min(gtGDef.tConst.nMaxInteger, nOldValue+nAddValue))
	self:MarkDirty(true)
	local nNewValue = self:GetCurrency(nCurrType)

	local nRealAddValue = nNewValue - nOldValue
	if nRealAddValue == 0 then
		return
	end

	--标记一下发生了改变
	self.m_tCurrencyCache[nCurrType] = 1
	return nNewValue
end

--扣除货币
function CRole:SubCurrency(nCurrType, nAddValue)
	assert(nAddValue >= 0, "参数错误")
	if nAddValue == 0 then
		return
	end
	local nOldValue = self:GetCurrency(nCurrType)
	self.m_tCurrencyMap[nCurrType] = math.max(0, math.min(gtGDef.tConst.nMaxInteger, nOldValue-nAddValue))
	local nNewValue = self:GetCurrency(nCurrType)
	self:MarkDirty(true)

	local nRealAddValue = nNewValue - nOldValue
	if nRealAddValue == 0 then
		return
	end

	--标记一下发生了改变
	self.m_tCurrencyCache[nCurrType] = 1
	return nNewValue
end

--同步货币
function CRole:SyncCurrency()
	if not next(self.m_tCurrencyCache) then
		return
	end
	local tCurrList = {}
	for nCurrType, nFlag in pairs(self.m_tCurrencyCache) do
		table.insert(tCurrList, {nType=nCurrType, nValue=self:GetCurrency(nCurrType)})
	end
	self.m_tCurrencyCache = {}
	if #tCurrList > 0 then
		self:SendMsg("CurrencySyncRet", {tList=tCurrList})
	end
end

--同步物品缓存
function CRole:SyncItemCache()
	self:SyncCurrency()
	self.m_oKnapsack:SyncItemCache()
end

--@tItemList 
--@nListType 1添加物品; 2传送物品; 3扣除物品
function CRole:_MergeItemList(tItemList, nListType)
	if tItemList.bMerged then
		return tItemList
	end

	local tItemMap = {}
	if nListType == 1 then --添加物品列表
		for _, tItem in ipairs(tItemList) do
			if ctItemConf[tItem.nID] then
				--货币类型根据物品ID区分绑定不绑定的
				local nBind = tItem.bBind and 1 or 0
				if ctItemConf[tItem.nID].nType == tItemType.eCurr then
					tItem.bBind, nBind = false, 0
				end
				local sKey = string.format("%d-%d", tItem.nID, nBind)
				if not tItemMap[sKey] then
					tItemMap[sKey] = table.DeepCopy(tItem)
				else
					tItemMap[sKey].nNum = tItemMap[sKey].nNum + tItem.nNum
				end
			else
				local sError = string.format("物品配置不存在:%d-%d", tItem.nID, nListType)
				self:Tips(sError)
				LuaTrace(sError)
			end
		end
	elseif nListType == 2 then --传输物品礼包
		for _, tItem in ipairs(tItemList) do
			if ctItemConf[tItem.m_nID] then
				assert(ctItemConf[tItem.m_nID].nType ~= tItemType.eCurr, "货币类型不能trans")
				local nBind = tItem.bBind and 1 or 0
				local sKey = string.format("%d-%d", tItem.m_nID, nBind)
				if not tItemMap[sKey] then
					tItemMap[sKey] = table.DeepCopy(tItem)
				else
					tItemMap[sKey].m_nNum = tItemMap[sKey].m_nNum + tItem.m_nNum
				end
			else
				local sError = string.format("物品配置不存在:%d-%d", tItem.nID, nListType)
				self:Tips(sError)
				LuaTrace(sError)
			end
		end
	elseif nListType == 3 then --扣除物品列表
		for _, tItem in ipairs(tItemList) do
			if ctItemConf[tItem.m_nID] then
				--货币类型根据物品ID区分绑定不绑定的	
				local nBind = tItem.nBind or 2
				if ctItemConf[tItem.nID].nType == tItemType.eCurr then
					tItem.nBind, nBind = 0, 0
				end
				local sKey = string.format("%d-%d", tItem.nID, nBind)
				if not tItemMap[sKey] then
					tItemMap[sKey] = table.DeepCopy(tItem)
				else
					tItemMap[sKey].nNum = tItemMap[sKey].nNum + tItem.nNum
				end
			else
				local sError = string.format("物品配置不存在:%d-%d", tItem.nID, nListType)
				self:Tips(sError)
				LuaTrace(sError)
			end
		end

	else
		assert(false, "物品列表类型错误")
	end
	local tMergedItemList = {bMerged=true}
	for _, tItem in pairs(tItemMap) do
		table.insert(tMergedItemList, tItem)
	end
	return tMergedItemList
end

--@tItemList {{nID=0,nNum=0,bBind=false,tItemExt={}},...}
--@bNotSync 如果为true，外层要手动调用CRole:SyncItemCache
function CRole:AddItemList(tItemList, sReason, bNotSync)
	assert(#tItemList>0 and sReason, "参数错误")
	tItemList = self:_MergeItemList(tItemList, 1)

	for _, tItem in ipairs(tItemList) do
		assert(tItem.nNum >= 0, "物品数量错误")
		local nRemains
		local tItemConf = ctItemConf[tItem.nID]
		if tItemConf.nType == tItemType.eCurr then
			nRemains = self:AddCurrency(tItemConf.nSubType, tItem.nNum)
		else
			nRemains = self.m_oKnapsack:AddItem(tItem)
		end
		--LOG
		if nRemains then
		end
	end
	if not bNotSync then
		self:SyncItemCache()
	end
end

--@tItemList {{m_nItemID=0,m_nNum=0,m_bBind=false,...},...}
--@bNotSync 同上
function CRole:TransItemList(tItemList, sReason, bNotSync)
	assert(#tItemList>0 and sReason, "参数错误")
	tItemList = self:_MergeItemList(tItemList, 2)
	for _, tItem in ipairs(tItemList) do
		local nRemains = self.m_oKnapsack:TransItem(tItem)
		--LOG
		if nRemains then
		end
	end
	if not bNotSync then
		self:SyncItemCache()
	end
end

--@tItemList {{nID=0,nNum=0,nBind=0},...} @nBind 0非绑; 1绑定; 2先绑定后非绑(全部)
function CRole:ItemCountList(tItemList)
	tItemList = self:_MergeItemList(tItemList, 3)
	local tCountList = {}
	for _, tItem in ipairs(tItemList) do
		local tItemConf = ctItemConf[tItem.nID]
		if tItemConf.nType == tItemType.eCurr then
			table.insert(tCountList, self:GetCurrency(tItemConf.nSubType))
		else
			table.insert(tCountList, self.m_oKnapsack:ItemCount(tItem.nID, tItem.nBind))
		end
	end
	return tCountList
end

--@tItemList 同上
--@bNotSync 同上
function CRole:SubItemList(tItemList, sReason, bNotSync)
	assert(#tItemList>0 and sReason, "参数错误")
	tItemList = self:_MergeItemList(tItemList, 3)
	for _, tItem in ipairs(tItemList) do
		assert(tItem.nNum >= 0, "物品数量错误")
		local nRemains --剩余数量
		local tItemConf = ctItemConf[tItem.nID]
		if tItemConf.nType == tItemType.eCurr then
			nRemains = self:SubCurrency(tItemConf.nSubType, tItem.nNum)
		else
			nRemains = self.m_oKnapsack:SubItemByID(tItem)
		end
		--LOG
		if nRemains then
		end
	end

	if not bNotSync then
		self:SyncItemCache()
	end
end

--@tItemList 同上
--@bNotSync 同上
function CRole:CheckSubItemList(tItemList, sReason, bNotSync)
	assert(#tItemList>0 and sReason, "参数错误")
	tItemList = self:_MergeItemList(tItemList, 3)
	local tCountList = self:ItemCountList(tItemList)
	assert(#tItemList == #tCountList, "数据错误")

	local tLackList = {}
	for k, tItem in ipairs(tItemList) do
		if tCountList[k] < tItem.nNum then 
			table.insert(tLackList, tItem.nID)
			break
		end
	end

	if #tLackList > 0 then
		self:PropTips(tLackList)
		return print("物品数量不足", tLackList)
	end
	self:SubItemList(tItemList, sReason, bNotSync)
end
