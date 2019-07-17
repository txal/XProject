---背包系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nMaxAddOnce = 5000 	--一次最多加道具数
local nInitGrids = ctPropEtcConf[1].nInitGrids 		--背包初始格子
local nMaxGrids = ctPropEtcConf[1].nMaxGrids 		--格子上限
local nBuyGridOnce = ctPropEtcConf[1].nBuyGridOnce 	--一次购买格子数
local nExpandProp = ctPropEtcConf[1].nExpandProp 	--道具包袱道具
local nStoInitGrids = ctPropEtcConf[1].nStoInitGrids--仓库初始格子
local nStoMaxGrids = ctPropEtcConf[1].nStoMaxGrids  --仓库最大格子

local nDailySaleYuanbaoLimitNum = 1000             --每日出售获得元宝限额
local nItemOpNumLimit = 200

function CKnapsack:Ctor(oRole)
	self.m_oRole = oRole
	self.m_nKey = 0

	--背包
	self.m_tGridMap = {} 		--背包道具{[格子]=物品对象,...}
	self.m_nGridNum = nInitGrids--已开放格子数
	self.m_nArrangeTime = 0		--上次整理背包时间
	self.m_nBuyGridTimes = 0 	--购买格子次数

	--仓库
	self.m_tStoGridMap = {} 			--仓库道具
	self.m_nStoGridNum = nStoInitGrids 	--仓库开放格子数
	self.m_nStoArrangeTime = 0			--上次整理仓库时间
	self.m_nStoBuyGridTimes = 0 		--仓库购买格子次数

	--身上装备
	self.m_tWearEqu = {}	--身上装备{[部位]=物品对象,...}
	self.m_tEquGemTips = {bTips = false, tPos = {}}   --身上装备，宝石镶嵌提示，不存DB

	--神兵兑换记录
	self.m_tLegendEquExchangeRecord = {}  --{nEuqID:nCount, ...}

	--背包物品使用记录 --部分道具需要限制每天使用次数
	self.m_nDailyResetStamp = 0  --跨天重置时间戳
	self.m_tPropUseRecord = {}  --{PropID:Count, ...}
	self.m_nWeddingCandyPickRecord = 0
	self.m_nOldManItemPickRecord = 0	--月老物品拾取次数记录

	self.m_nDailySaleYuanbaoNum = 0      --道具回收获得元宝数额
	
	--装备强化等级、宝石等级，共鸣属性相关,临时数据，不存DB
	self.m_tStrengthenTriggerData = 
	{
		nTriggerID = 0,                  --装备强化共鸣ID 
		nNextLevelActiveNum = 0,         --下一等级激活数量
		tTriggerAttr = {},               --装备强化共鸣属性
	}

	self.m_tGemTriggerData = 
	{
		nTriggerID = 0,                  --装备强化共鸣ID 
		nNextLevelActiveNum = 0,         --下一等级激活数量
		tTriggerAttr = {},               --装备强化共鸣属性
	}

	self.m_tMsgCache = {[1]={}, [2]={}, [3]={}} --1增加; 2修改; 3删除: {[修改类型]={[背包类型]={}, ...}, ...}

end

function CKnapsack:GetType()
	return gtModuleDef.tKnapsack.nID, gtModuleDef.tKnapsack.sName
end

function CKnapsack:GenKey()
	self.m_nKey = self.m_nKey % 0x7fffffff + 1
	self:MarkDirty(true)
	return self.m_nKey
end

function CKnapsack:LoadData(tData)
	if not tData then
		return
	end
	self.m_nKey = tData.m_nKey or self.m_nKey  --必须先于道具load
	self.m_nGridNum = tData.m_nGridNum or self.m_nGridNum
	self.m_nArrangeTime = tData.m_nArrangeTime or self.m_nArrangeTime
	self.m_nBuyGridTimes = tData.m_nBuyGridTimes or self.m_nBuyGridTimes
	if self.m_nBuyGridTimes < 0 then 
		LuaTrace(string.format("玩家背包格子开启次数数据错误，当前次数(%d)", self.m_nBuyGridTimes))
		self.m_nBuyGridTimes = 0 
		self:MarkDirty(true)
	end

	--背包道具
	for _, tItem in pairs(tData.m_tGridMap) do
		local tConf = ctPropConf[tItem.m_nID]
		if tConf and tConf.nType ~= gtPropType.eCurr then
			local oProp = self:CreateProp(tItem.m_nID, tItem.m_nGrid)
			if oProp then
				oProp:LoadData(tItem)
				self.m_tGridMap[tItem.m_nGrid] = oProp
				if oProp:GetKey() < 1 then 
					print("请注意，道具key不正确")
					oProp:UpdateKey()
					self:MarkDirty(true)
				end
			end
		end
	end

	--身上装备
	for nPart, tItem in pairs(tData.m_tWearEqu or {}) do
		local tConf = ctPropConf[tItem.m_nID]
		if tConf and tConf.nType == gtPropType.eEquipment then
			local oProp = self:CreateProp(tItem.m_nID, tItem.m_nGrid)
			if oProp then
				oProp:LoadData(tItem)
				self.m_tWearEqu[nPart] = oProp
				if oProp:GetKey() < 1 then 
					print("请注意，道具key不正确")
					oProp:UpdateKey()
					self:MarkDirty(true)
				end
			end
		end
	end

	--仓库
	for _, tItem in pairs(tData.m_tStoGridMap or {}) do
		local tConf = ctPropConf[tItem.m_nID]
		if tConf and tConf.nType ~= gtPropType.eCurr then
			local oProp = self:CreateProp(tItem.m_nID, tItem.m_nGrid)
			if oProp then
				oProp:LoadData(tItem)
				self.m_tStoGridMap[tItem.m_nGrid] = oProp
				if oProp:GetKey() < 1 then 
					print("请注意，道具key不正确")
					oProp:UpdateKey()
					self:MarkDirty(true)
				end
			end
		end
	end
	self.m_nStoGridNum = tData.m_nStoGridNum or self.m_nStoGridNum
	self.m_nStoBuyGridTimes = tData.m_nStoBuyGridTimes or self.m_nStoBuyGridTimes
	if self.m_nStoBuyGridTimes < 0 then 
		LuaTrace(string.format("玩家仓库格子开启次数数据错误，当前次数(%d)", self.m_nStoBuyGridTimes))
		self.m_nStoBuyGridTimes = 0 
		self:MarkDirty(true)
	end
	self.m_nStoArrangeTime = tData.m_nStoArrangeTime or self.m_nStoArrangeTime

	self.m_tLegendEquExchangeRecord = tData.m_tLegendEquExchangeRecord or self.m_tLegendEquExchangeRecord
	for k, v in pairs(self.m_tLegendEquExchangeRecord) do 
		if not ctEquipmentConf[k] then 
			self.m_tLegendEquExchangeRecord[k] = nil
			self:MarkDirty(true)
		end
	end

	self.m_nDailyResetStamp = tData.m_nDailyResetStamp or self.m_nDailyResetStamp
	self.m_tPropUseRecord = tData.m_tPropUseRecord or self.m_tPropUseRecord
	self.m_nDailySaleYuanbaoNum = tData.m_nDailySaleYuanbaoNum or self.m_nDailySaleYuanbaoNum
	self.m_nWeddingCandyPickRecord = tData.m_nWeddingCandyPickRecord or self.m_nWeddingCandyPickRecord
	self.m_nOldManItemPickRecord = tData.m_nOldManItemPickRecord or self.m_nOldManItemPickRecord
	
	self.m_tStrengthenTriggerData = tData.m_tStrengthenTriggerData or self.m_tStrengthenTriggerData
	self.m_tGemTriggerData = tData.m_tGemTriggerData or self.m_tGemTriggerData
	self:UpdateGemTips(false)
end

function CKnapsack:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nKey = self.m_nKey
	tData.m_nGridNum = self.m_nGridNum
	tData.m_nArrangeTime = self.m_nArrangeTime
	tData.m_nBuyGridTimes = self.m_nBuyGridTimes

	--背包
	tData.m_tGridMap = {}
	for nGrid, oItem in pairs(self.m_tGridMap) do
		tData.m_tGridMap[nGrid] = oItem:SaveData()
	end

	--身上装备
	tData.m_tWearEqu = {}
	for nPart, oItem in pairs(self.m_tWearEqu) do
		tData.m_tWearEqu[nPart] = oItem:SaveData()
	end

	--仓库
	tData.m_tStoGridMap = {}
	for nGrid, oItem in pairs(self.m_tStoGridMap) do
		tData.m_tStoGridMap[nGrid] = oItem:SaveData()
	end
	tData.m_nStoGridNum = self.m_nStoGridNum
	tData.m_nStoBuyGridTimes = self.m_nStoBuyGridTimes
	tData.m_nStoArrangeTime = self.m_nStoArrangeTime

	tData.m_tLegendEquExchangeRecord = self.m_tLegendEquExchangeRecord

	tData.m_nDailyResetStamp = self.m_nDailyResetStamp
	tData.m_tPropUseRecord = self.m_tPropUseRecord
	tData.m_nDailySaleYuanbaoNum = self.m_nDailySaleYuanbaoNum
	tData.m_nWeddingCandyPickRecord = self.m_nWeddingCandyPickRecord
	tData.m_nOldManItemPickRecord = self.m_nOldManItemPickRecord

	tData.m_tStrengthenTriggerData = self.m_tStrengthenTriggerData
	tData.m_tGemTriggerData = self.m_tGemTriggerData

	return tData
end

--玩家上线
function CKnapsack:Online()
	self:ClearCachedMsg()
	self:CheckDailyReset()
	self:SyncKnapsackItems()
	self:UpdateGemTips(false)
	self:SyncGemTips()
	self:SyncSaleYuanbaoRecord()
	self:UpdateEquTriggerAttr(true)
	self:SyncEquTriggerAttr()
end

--通过格子取背包物品
function CKnapsack:GetItem(nGridID)
	return self.m_tGridMap[nGridID]
end

function CKnapsack:GetItemByKey(nKey) 
	for k, oProp in pairs(self.m_tGridMap) do 
		if oProp:GetKey() == nKey then 
			return oProp, gtPropBoxType.eBag, k
		end
	end
	for k, oProp in pairs(self.m_tStoGridMap) do 
		if oProp:GetKey() == nKey then 
			return oProp, gtPropBoxType.eStorage, k
		end
	end
	for k, oProp in pairs(self.m_tWearEqu) do 
		if oProp:GetKey() == nKey then 
			return oProp, gtPropBoxType.eEquipment, k
		end
	end
end

--通过物品ID取对象
function CKnapsack:GetItemByPropID(nPropID)
	for _, oProp in pairs(self.m_tGridMap) do
		if oProp:GetID() == nPropID then
			return oProp
		end
	end
end

--通过格子取仓库物品
function CKnapsack:GetStoItem(nGridID)
	return self.m_tStoGridMap[nGridID]
end

--根据道具类型创建道具对象
function CKnapsack:CreateProp(nID, nGrid, bBind, tPropExt)
	tPropExt = tPropExt or {}
	local tConf = assert(ctPropConf[nID])
	local cProp = gtPropClass[tConf.nType]
	if not cProp then
		return LuaTrace("道具未实现", tConf.sName, tConf.nType)
	end
	local oProp = cProp:new(self, nID, nGrid, bBind, tPropExt)
	return oProp
end

--取背包空闲格子数
function CKnapsack:GetFreeGridCount()
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
function CKnapsack:GetRemainCapacity(nPropID, bBind)
	bBind = bBind and true or false
	local tConf = ctPropConf[nPropID]
	if not tConf or tConf.nType == gtPropType.eCurr then
		return gtGDef.tConst.nMaxInteger
	end
	local nFreeGridCount = self:GetFreeGridCount()
	local nRemainCapacity = nFreeGridCount * tConf.nFold
	for k = 1, self.m_nGridNum do
		local oProp = self.m_tGridMap[k]
		if oProp and oProp:GetID() == nPropID and oProp:IsBind() == bBind then
			nRemainCapacity = nRemainCapacity + oProp:EmptyNum()
		end
	end
	return nRemainCapacity
end

--检查新增物品占用新格子数量
function CKnapsack:CheckNewGridOccupy(nPropID, nNum, bBind)
	assert(nPropID and nNum)
	if nNum <= 0 then 
		return 0
	end
	bBind = bBind and true or false
	local tConf = assert(ctPropConf[nPropID], "道具不存在:"..nPropID)
	if tConf.nType == gtPropType.eCurr then
		return 0
	end
	assert(tConf.nFold > 0, "配置错误，或者不是道具")
	local nRemainCapacity = 0
	for k = 1, self.m_nGridNum do
		local oProp = self.m_tGridMap[k]
		if oProp and oProp:GetID() == nPropID and oProp:IsBind() == bBind then
			nRemainCapacity = nRemainCapacity + oProp:EmptyNum()
		end
	end
	if nRemainCapacity >= nNum then 
		return 0
	end
	return math.ceil((nNum - nRemainCapacity) / tConf.nFold)
end

--取空闲格子
--@nType 1背包 2仓库
function CKnapsack:GetFreeGrid(nType)
	assert(nType==1 or nType==2, "背包类型错误")

	local nFreeGrid = 0
	if nType == 1 then
		for k = 1, self.m_nGridNum do
			if not self.m_tGridMap[k] then
				nFreeGrid = k
				break
			end
		end
	else
		for k = 1, self.m_nStoGridNum do
			if not self.m_tStoGridMap[k] then
				nFreeGrid = k
				break
			end
		end
	end
	return nFreeGrid
end

--绑定道具到容器格子
function CKnapsack:SetItemToBox(oProp, nBoxType, nGrid)
	assert(oProp and nBoxType and  (nGrid and nGrid > 0), "参数错误")
	if nBoxType == gtPropBoxType.eBag then 
		assert(nGrid <= self.m_nGridNum, "不合法的格子ID")
		assert(not self.m_tGridMap[nGrid], "当前格子已有道具")
		oProp:SetGrid(nGrid)
		self.m_tGridMap[nGrid] = oProp
	elseif nBoxType == gtPropBoxType.eEquipment then 
		assert(gtEquPartName[nGrid], "不合法的格子ID")
		assert(not self.m_tWearEqu[nGrid], "当前格子已有道具")
		oProp:SetGrid(nGrid)
		self.m_tWearEqu[nGrid] = oProp
	elseif nBoxType == gtPropBoxType.eStorage then 
		assert(nGrid <= self.m_nStoGridNum, "不合法的格子ID")
		assert(not self.m_tStoGridMap[nGrid], "当前格子已有道具")
		oProp:SetGrid(nGrid)
		self.m_tStoGridMap[nGrid] = oProp
	else
		assert(false, "不受支持的格子类型")
	end
	self:MarkDirty(true)
end

--将容器格子清空
function CKnapsack:CleanBoxGrid(nBoxType, nGrid)
	assert(nBoxType and  (nGrid and nGrid > 0), "参数错误")
	if nBoxType == gtPropBoxType.eBag then 
		-- assert(nGrid <= self.m_nGridNum, "不合法的格子ID")
		local oProp = self.m_tGridMap[nGrid] 
		if oProp then 
			oProp:SetGrid(0)
		end
		self.m_tGridMap[nGrid] = nil
	elseif nBoxType == gtPropBoxType.eEquipment then 
		-- assert(gtEquPartName[nGrid], "不合法的格子ID")
		local oProp = self.m_tWearEqu[nGrid] 
		if oProp then 
			oProp:SetGrid(0)
		end
		self.m_tWearEqu[nGrid] = nil
	elseif nBoxType == gtPropBoxType.eStorage then 
		-- assert(nGrid <= self.m_nStoGridNum, "不合法的格子ID")
		local oProp = self.m_tStoGridMap[nGrid] 
		if oProp then 
			oProp:SetGrid(0)
		end
		self.m_tStoGridMap[nGrid] = nil
	else
		assert(false, "不受支持的格子类型")
	end
	self:MarkDirty(true)
end

function CKnapsack:RemoveFromBox(oProp, nBoxType)
	local nGrid = oProp:GetGrid()
	self:CleanBoxGrid(nBoxType, nGrid)
end

--更新购买价格(商会)
function CKnapsack:UpdateBuyPrice(nPropID, nNewBuyPrice)
	if nNewBuyPrice <= 0 then
		return
	end
	local tPropList = {}
	for k, oProp in pairs(self.m_tGridMap) do 
		if oProp:GetID() == nPropID then 
			table.insert(tPropList, oProp)
		end
	end
	for k, oProp in pairs(self.m_tStoGridMap) do 
		if oProp:GetID() == nPropID then 
			table.insert(tPropList, oProp)
		end
	end
	for k, oProp in pairs(self.m_tWearEqu) do 
		if oProp:GetID() == nPropID then 
			table.insert(tPropList, oProp)
		end
	end
	if #tPropList <= 0 then	
		return
	end
	local nOldBuyPrice = tPropList[1]:GetBuyPrice()
	if nNewBuyPrice > 0 and nOldBuyPrice > 0 then
		nNewBuyPrice = math.floor((nOldBuyPrice+nNewBuyPrice)/2)
	else
		nNewBuyPrice = nNewBuyPrice>0 and nNewBuyPrice or nOldBuyPrice
	end
	for _, oProp in pairs(tPropList) do
		oProp:SetBuyPrice(nNewBuyPrice)
	end
	self:MarkDirty(true)
end

--@bBind 是否绑定
--@tPropExt 道具扩展参数
--[[
tPropExt{
	nQuality,  --指定品质(目前只装备生效)
	nSource,   --道具来源(目前只装备生效)
}
]]
function CKnapsack:AddItem(nID, nNum, bBind, tPropExt, bNotSync)
	assert(nID>0 and nNum>=0, "参数非法"..nID..":"..nNum)
	if nNum == 0 then
		return
	 end
	local nOrgNum = nNum
	bBind = bBind and true or false
	if nNum > nMaxAddOnce then
		return self.m_oRole:Tips("每次最多能加:"..nMaxAddOnce)
	end
	local tConf = ctPropConf[nID]
	if not tConf then
		return self.m_oRole:Tips("道具配置不存在:"..nID)
	end
	if tConf.nType == gtPropType.eCurr then
		return self.m_oRole:Tips("虚拟道具不能加入背包:"..nID)
	end
	local cClass = gtPropClass[tConf.nType]
	if not cClass then
		return self.m_oRole:Tips("道具未实现:"..nID)
	end
	--帮派神诏特殊处理
	local nAddNum = cClass:CheckCanAddNum(self.m_oRole, nID, nNum)
	if nAddNum <= 0 then
		return
	end
	nNum = nAddNum

	if tConf.nType == gtPropType.eGift then 
		local tGiftConf = assert(ctGiftConf[nID], "礼包配置不存在")
		if tGiftConf.bUse then --获得即直接使用的礼包
			local oTempGift = self:CreateProp(nID, 0, bBind, tPropExt) --创建一个和玩家背包关联的临时道具
			oTempGift:Open(nNum, false, bNotSync)
			-- local nOpenNum = 0
			-- for k = 1, nNum do 
			-- 	 oTempGift:Open()
			-- end
			return 
		end
	end

	--取出未满道具和空闲格子
	local tFreeGrid = {}
	local tEmptyProp = {}
	for k = 1, self.m_nGridNum do
		local oProp = self.m_tGridMap[k]
		if not oProp then
			table.insert(tFreeGrid, k)

		elseif oProp:GetID()==nID and oProp:IsBind()==bBind then
			if not oProp:IsFull() then
				table.insert(tEmptyProp, oProp)
			end

		end
	end

	--先加满未满的道具
	for _, oProp in ipairs(tEmptyProp) do
		local nAddNum = math.min(oProp:EmptyNum(), nNum)
		oProp:AddNum(nAddNum)
		self:OnItemModed(oProp:GetGrid(), tPropExt.bNoTips, bNotSync)
		nNum = nNum - nAddNum
		if nNum <= 0 then break end
	end
	--有剩余加到空闲格子
	if nNum > 0 then
		for _, nGrid in ipairs(tFreeGrid) do
			local oProp = self:CreateProp(nID, nGrid, bBind, tPropExt)
			local nAddNum = math.min(nNum, oProp:EmptyNum())
			oProp:UpdateKey()
			oProp:AddNum(nAddNum)
			-- self.m_tGridMap[nGrid] = oProp
			self:SetItemToBox(oProp, gtPropBoxType.eBag, nGrid)
			self:OnItemAdded(nGrid, 1, true, bNotSync)
			nNum = nNum - nAddNum
			if nNum <= 0 then break end
		end
	end

	--更新商会购买价格
	self:UpdateBuyPrice(nID, tPropExt.nBuyPrice or 0)
	self:MarkDirty(true)

	--背包已满
	if nNum > 0 then
		local tItemList = {{gtItemType.eProp,nID,nNum,bBind,tPropExt}} 
		CUtil:SendMail(self.m_oRole:GetServer(), "背包已满", "背包已满，请及时领取邮件", tItemList, self.m_oRole:GetID())
		self.m_oRole:Tips("背包空间不足，请及时清理背包")
	end

	--添加物品事件
	if nOrgNum ~= nNum then
		self.m_oRole.m_oPractice:OnAddItem(nPropID)
	end
	if ctGemConf[nID] then --如果是宝石
		self:UpdateGemTips(true)
	end
	return self:ItemCount(nID)
end

--背包物品个数
--@bBind true=取绑定物品个数,否则取总数(包括绑定和非绑定)
function CKnapsack:ItemCount(nID, bBind)
	local nNum = 0
	for nGrid, oProp in pairs(self.m_tGridMap or {}) do
		if oProp:GetID()==nID then
			if bBind then 
				if oProp:IsBind() then
					nNum = nNum + oProp:GetNum()
				end
			else
				nNum = nNum + oProp:GetNum()
			end
		end
	end
	return nNum
end

--仓库物品个数
--@bBind true=取绑定物品个数,否则取总数(包括绑定和非绑定)
function CKnapsack:StorageItemCount(nID, bBind)
	local nNum = 0
	for nGrid, oProp in pairs(self.m_tStoGridMap) do
		if oProp:GetID()==nID then
			if bBind then 
				if oProp:IsBind() then
					nNum = nNum+oProp:GetNum()
				end
			else
				nNum = nNum + oProp:GetNum()
			end
		end
	end
	return nNum
end

--背包、仓库、装备栏， 物品个数
--@bBind true=取绑定物品个数,否则取总数(包括绑定和非绑定)
function CKnapsack:ItemCountAll(nID, bBind) 
	local nBagNum = self:ItemCount(nID, bBind)
	local nStorageNum = self:StorageItemCount(nID, bBind) 

	local nWearNum = 0
	for k, oItem in pairs(self.m_tWearEqu) do 
		if oItem:GetID() == nID then 
			nWearNum = nWearNum + oItem:GetNum()
		end
	end

	return nBagNum + nStorageNum + nWearNum
end

--扣除物品 --优先扣除绑定道具,优先扣除格子道具数量少的格子
--@bNotSync 是否不同步
function CKnapsack:SubItem(nID, nNum,bNotSync)
	assert(nNum >= 0, "数量错误:"..nNum)
	if nNum == 0 then return end
	local fnCmp = function(tItem, tItem2) 
		return tItem:GetNum() < tItem2:GetNum()
	end

	local tNormalProp = {}  -- {nGird:oProp, ...}
	local tBindProp = {}
	--遍历扣除物品
	for k = 1, self.m_nGridNum do 
		local oProp = self.m_tGridMap[k]
		if oProp and oProp:GetID() == nID then 
			if oProp:IsBind() then
				table.insert(tBindProp, oProp)
			else
				if oProp:GetGrid() ~= k then --防止格子数据错误，错误扣除道具 
					oProp:SetGrid(k) 
				end
				table.insert(tNormalProp, oProp) --顺序插入，从前往后扣除
			end
		end
	end

	--内部根据数量大小来排序,优先扣除格子道具数量少的格子
	table.sort(tBindProp, fnCmp)
	for _, oProp in ipairs(tBindProp) do
		local nSubNum = math.min(oProp:GetNum(), nNum)
		oProp:SubNum(nSubNum)
		local nGrid = oProp:GetGrid()
		if oProp:GetNum() == 0 then
			self.m_tGridMap[nGrid] = nil
			self:OnItemRemoved(nGrid, 1, bNotSync) 
		else
			self:OnItemModed(nGrid,false, bNotSync)
		end
		nNum = nNum - nSubNum
		if nNum <= 0 then 
			break 
		end
	end

	if nNum > 0 then 
		table.sort(tNormalProp, fnCmp)
		for _, oProp in ipairs(tNormalProp) do 
			local nGrid = oProp:GetGrid()
			local nSubNum = math.min(oProp:GetNum(), nNum)
			oProp:SubNum(nSubNum)
			if oProp:GetNum() == 0 then
				self.m_tGridMap[nGrid] = nil
				self:OnItemRemoved(nGrid, 1, bNotSync) 
			else
				self:OnItemModed(nGrid,false, bNotSync)
			end
			nNum = nNum - nSubNum
			if nNum <= 0 then 
				break 
			end
		end
	end

	self:MarkDirty(true)

	if ctGemConf[nID] then --如果是宝石
		self:UpdateGemTips(true)
	end
	return self:ItemCount(nID)
end

--扣除指定格子物品
function CKnapsack:SubGridItem(nGrid, nID, nNum, sReason, bNotSync)
	assert(sReason, "请说明原因")
	nNum = math.abs(nNum)
	if nNum == 0 then
		return
	end

	local oProp = self.m_tGridMap[nGrid]
	if not oProp then
		return LuaTrace("道具不存在", nGrid)
	end

	if oProp:GetID() ~= nID then
		return LuaTrace("道具ID错误", nID)
	end

	if oProp:GetNum() < nNum then
		return LuaTrace("道具数量不足", nNum)
	end
	oProp:SubNum(nNum)
	if oProp:GetNum() <= 0 then
		self.m_tGridMap[nGrid] = nil
		self:OnItemRemoved(nGrid, 1, bNotSync)
	else
		self:OnItemModed(nGrid, false, bNotSync)
	end

	self:MarkDirty(true)
	goLogger:AwardLog(gtEvent.eSubItem, sReason, self.m_oRole, gtItemType.eProp, nID, nNum, self:ItemCount(nID)) 
	
	if ctGemConf[nID] then --如果是宝石
		self:UpdateGemTips(true)
	end
	return true
end

--tItemList {{nGrid=, nID=, nNum=,}, ...}
function CKnapsack:SubGridItemList(tItemList, sReason) 
	--先检查是否足够
	local tGridMap = {}
	for _, tGridItem in ipairs(tItemList) do 
		local nGrid = tGridItem.nGrid
		local nID = tGridItem.nID
		local nNum = tGridItem.nNum
		local oProp = self.m_tGridMap[nGrid]
		if not oProp then
			return false, "道具不存在"
		end
	
		if oProp:GetID() ~= nID then
			return false, "道具ID错误"
		end
	
		if oProp:GetNum() < nNum then
			return false, "道具数量不足"
		end
		if tGridMap[nGrid] then 
			return false, "道具重复"
		end
		tGridMap[nGrid] = tGridItem
	end

	--扣除道具
	local bGemProp = false  --是否消耗宝石道具, 计算比较多, 避免多次重复检查

	local tModedGrid = {}  --因为不允许单次出现重复扣除格子道具, 所有不考虑, 格子出现先被修改, 然后被移除此类情况
	local tRemovedGrid = {}
	for _, tGridItem in ipairs(tItemList) do 
		local nGrid = tGridItem.nGrid
		local nID = tGridItem.nID
		local nNum = tGridItem.nNum
		local oProp = self.m_tGridMap[nGrid]
		oProp:SubNum(nNum)
		if oProp:GetNum() <= 0 then
			self.m_tGridMap[nGrid] = nil
			self:OnItemRemoved(nGrid, 1, true)
			tRemovedGrid[nGrid] = true
		else
			self:OnItemModed(nGrid, false, true)
			tModedGrid[nGrid] = true
		end
		self:MarkDirty(true)
		goLogger:AwardLog(gtEvent.eSubItem, sReason, self.m_oRole, gtItemType.eProp, nID, nNum, self:ItemCount(nID)) 
		if ctGemConf[nID] then 
			bGemProp = true
		end
	end
	
	if bGemProp then
		self:UpdateGemTips(true)
	end

	--通知道具被移除
	local nBagType = 1
	local tRemoveGridList = {}
	for nGrid, _ in pairs(tRemovedGrid) do
		table.insert(tRemoveGridList, nGrid)
	end
	if #tRemoveGridList > 0 then 
		self.m_oRole:SendMsg("KnapsackItemRemoveRet", {tGrid=tRemoveGridList, nType=nBagType})
	end
	
	--通知道具被修改
	local tModedDataList = {}
	for nGrid, _ in pairs(tModedGrid) do 
		local oProp = self.m_tGridMap[nGrid]
		local tInfo = oProp:GetInfo()
		tInfo.bIsSync = true
		table.insert(tModedDataList, tInfo)
	end
	if #tModedDataList > 0 then 
		self.m_oRole:SendMsg("KnapsackItemModRet", {tItemList=tModedDataList})
	end

	--清理缓存消息
	self:ClearCachedMsg()
	return true
end


--物品添加成功
--@nType 1背包,2仓库
--@bNew 是否新获得的物品
--@bNotSync 是否不同步
function CKnapsack:OnItemAdded(nGrid, nType, bNew, bNotSync)
	local oProp
	if nType == 1 then
		oProp = self:GetItem(nGrid)
	else
		oProp = self:GetStoItem(nGrid)
	end

	local tInfo = oProp:GetInfo()
	tInfo.bNew = bNew
	tInfo.nWearTip = nil
	print("CKnapsack:OnItemAdded****", tInfo)

	if bNew and oProp:IsEquipment() and self:CheckCanWear(oProp:GetID()) then 
		local nBaseScore = oProp:GetBaseAttrScore()
		local nPartType = oProp:GetPartType()
		local oWearEqu = self:GetPropByBox(gtPropBoxType.eEquipment, nPartType)
		local nWearScore = 0
		if oWearEqu then 
			nWearScore = oWearEqu:GetBaseAttrScore()
		end
		if not oWearEqu or nWearScore < nBaseScore then 
			local nRoleLevel = self.m_oRole:GetLevel()
			local nEquLevel = oProp:GetLevel()
			if oProp:GetSource() == gtEquSourceType.eShop and nRoleLevel < 60 and nEquLevel < 60 then 
				tInfo.nWearTip = 2
			else
				tInfo.nWearTip = 1
			end
		end
	end
	if bNotSync then
		self.m_tMsgCache[1][nType] = self.m_tMsgCache[1][nType] or {}
		table.insert(self.m_tMsgCache[1][nType], tInfo)

	else
		self.m_oRole:SendMsg("KnapsackItemAddRet", {tItemList={tInfo}, nType=nType})

	end
end

--物品数量变更(只有背包有用)
--bSilent, 不做同步
--bNoTips, 是否不弹提示
function CKnapsack:OnItemModed(nGrid, bNoTips, bSilent)
	local oProp = self:GetItem(nGrid)
	local tInfo = oProp:GetInfo()
	tInfo.bIsSync = (not bNoTips) and true or false
	print("CKnapsack:OnItemModed****", tInfo)

	if bSilent then 
		self.m_tMsgCache[2][1] = self.m_tMsgCache[2][1] or {}
		table.insert(self.m_tMsgCache[2][1], tInfo)
	else
		self.m_oRole:SendMsg("KnapsackItemModRet", {tItemList={tInfo}})
	end
end

--物品删除成功
--@nType 1背包,2仓库
--@bSilent 不做同步
function CKnapsack:OnItemRemoved(nGrid, nType, bSilent)
	if bSilent then 
		self.m_tMsgCache[3][nType] = self.m_tMsgCache[3][nType] or {}
		table.insert(self.m_tMsgCache[3][nType], nGrid)
	else
		self.m_oRole:SendMsg("KnapsackItemRemoveRet", {tGrid={nGrid}, nType=nType})
	end
end

--清除消息缓存
function CKnapsack:ClearCachedMsg()
	self.m_tMsgCache = {[1]={}, [2]={}, [3]={}}
end

--同步消息缓存
function CKnapsack:SyncCachedMsg()
	--背包缓存消息同步
	for k = 1, 3 do --1增加;2修改;3删除
		for t = 1, 2 do --1背包;2仓库
			local tTmpList = self.m_tMsgCache[k][t]
			if tTmpList and #tTmpList > 0 then
				if k == 1 then
					self.m_oRole:SendMsg("KnapsackItemAddRet", {tItemList=tTmpList, nType=t})
				elseif k == 2 then
					self.m_oRole:SendMsg("KnapsackItemModRet", {tItemList=tTmpList})
				elseif k == 3 then
					self.m_oRole:SendMsg("KnapsackItemRemoveRet", {tGrid=tTmpList, nType=t})
				end
			end
		end
	end
	self:ClearCachedMsg()

	--货币缓存消息同步
	self.m_oRole:SyncCurrCachedMsg()
	--聊天频道获得物品缓存消息同步
	CUtil:SyncItemTalkCachedMsg(self.m_oRole)
end

--同步背包道具列表
function CKnapsack:SyncKnapsackItems()
	local tItemList = {}
	local tStoItemList = {}
	for nGrid, oProp in pairs(self.m_tGridMap) do
		table.insert(tItemList, oProp:GetInfo())
	end
	for nGrid, oProp in pairs(self.m_tStoGridMap) do
		table.insert(tStoItemList, oProp:GetInfo())
	end
	local tMsg = {tItemList=tItemList, nGridNum=self.m_nGridNum, nBuyTimes=self.m_nBuyGridTimes
		, tStoItemList=tStoItemList, nStoGridNum=self.m_nStoGridNum, nStoBuyTimes=self.m_nStoBuyGridTimes} 
	self.m_oRole:SendMsg("KnapsackItemListRet", tMsg)
end

--取道具名字
function CKnapsack:PropName(nID)
	local tConf = ctPropConf[nID]
	return tConf and tConf.sName or ""
end

--GM清空背包
function CKnapsack:GMClrKnapsack()
	self.m_tGridMap = {}
	self:MarkDirty(true)
	self:SyncKnapsackItems()
	self.m_oRole:Tips("清空背包成功")
	
end

--取战斗物品
function CKnapsack:GetBattlePropList()
	local tPropList = {}
	for _, oProp in pairs(self.m_tGridMap) do
		if oProp:GetPropConf().nUseScope == 2 and oProp:GetPropConf().nLogicID > 0 then
			table.insert(tPropList, oProp)
		end
	end
	return tPropList
end

--通过KEY取物品
function CKnapsack:GetPropByKey(nKey)
	for _, oProp in pairs(self.m_tGridMap) do
		if oProp:GetKey() == nKey then
			return oProp
		end
	end
end

--使用道具请求
function CKnapsack:PropUseReq(nGrid, nParam1)
	local oProp = self:GetItem(nGrid)
	if not oProp then
		return self.m_oRole:Tips("道具不存在")
	end
	if not nParam1 or nParam1 < 1 then 
		nParam1 = 1
	end
	if nParam1 > 1 and (not ctPropConf[oProp:GetID()].bBatchUseable) then
		return self.m_oRole:Tips("该道具不能批量使用")
	end
	if not oProp.Use then
		return self.m_oRole:Tips(string.format("%s不能使用", self:PropName(oProp:GetID())))
	end
	oProp:Use(nParam1)
end

--出售道具请求
function CKnapsack:PropSellReq(nGrid, nNum, nType)
	local oProp = self:GetItem(nGrid)
	if not oProp then
		return self.m_oRole:Tips("道具不存在")
	end
	-- if oProp:GetNum() < nNum then
	-- 	return self.m_oRole:Tips("道具数量不足")
	-- end
	-- --只要配了价格，不管绑不绑定都可以出售	
	-- local nSellCopperPrice = oProp:GetPropConf().nSellCopperPrice
	-- local nSellGoldPrice = oProp:GetPropConf().nSellGoldPrice
	-- if nSellCopperPrice <= 0 and nSellGoldPrice <= 0 then
	-- 	return self.m_oRole:Tips("道具不可出售(出售价格配置错误?)")
	-- end

	-- oProp:Sell(nNum, nType)

	if nNum < 0 then 
		self.m_oRole:Tips("参数错误")
		return 
	end
	if oProp:GetNum() < nNum then 
		self.m_oRole:Tips("道具数量不足")
		return 
	end

	if nType == 1 then 
		if not oProp:CheckSaleGold() then 
			self.m_oRole:Tips("该道具不可出售")
			return
		end
	elseif nType == 2 then 
		if not oProp:CheckSaleSilver() then 
			self.m_oRole:Tips("该道具不可回收")
			return
		end
	else
		self.m_oRole:Tips("参数错误")
		return
	end
	local tSaleList = {{nID = oProp:GetID(), nGrid = nGrid, nNum = nNum, nType = nType}, }

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
				self:PropListSellReq(tSaleList)
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
function CKnapsack:PropListSellReq(tItemList, fnCallback)
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

		if self.m_oRole:IsReleased() then --角色已释放，不回调相关事件
			return
		end

		local tGridPriceMap = {}
		for _, tPriceData in pairs(tPriceList) do 
			tGridPriceMap[tPriceData.nGrid] = tPriceData
		end

		for _, tItem in pairs(tItemList) do 
			local nPropID = tItem.nID
			local oProp = self.m_tGridMap[tItem.nGrid]
			--做一下必要检查，防止异步期间，道具发生变化
			if not oProp or oProp:GetID() ~= tItem.nID or oProp:GetNum() < tItem.nNum then
				fnInnerCallback(false, "出售失败")
				return 
			end
			if (tItem.nType == 1 and not oProp:CheckSaleGold())
			or (tItem.nType == 2 and not oProp:CheckSaleSilver()) then 
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
			local nPropID = tItem.nID
			local oProp = self.m_tGridMap[tItem.nGrid]
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

function CKnapsack:GetDailySaleYuanbaoRemainNum()
	return math.max(nDailySaleYuanbaoLimitNum - self.m_nDailySaleYuanbaoNum, 0)
end

function CKnapsack:AddDailySaleYuanbaoRecord(nNum) 
	if self.m_nDailySaleYuanbaoNum >= nDailySaleYuanbaoLimitNum then 
		return 
	end
	self.m_nDailySaleYuanbaoNum = self.m_nDailySaleYuanbaoNum + nNum
	self:MarkDirty(true)
	self:SyncSaleYuanbaoRecord()
end

function CKnapsack:SyncSaleYuanbaoRecord() 
	local tMsg = {}
	-- tMsg.nRemain = math.max(nDailySaleYuanbaoLimitNum - self.m_nDailySaleYuanbaoNum, 0)
	tMsg.nRemain = self:GetDailySaleYuanbaoRemainNum()
	self.m_oRole:SendMsg("KnapsackSaleYuanbaoRecordRet", tMsg)
end

-- tItemList {{nID=, nGrid=, nType=, }, ...}
function CKnapsack:ItemSalePriceReq(tItemList) 
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

function CKnapsack:GetBaseGoldPrice(nPropID)
	local tConf = ctPropConf[nPropID]
	assert(tConf)
	return tConf.nSellGoldPrice
end

function CKnapsack:GetBaseSilverPrice(nPropID) 
	local tConf = ctPropConf[nPropID]
	assert(tConf)
	local nSilverPrice = tConf.nSellCopperPrice
	if nSilverPrice <= 0 then --暂时不加绑定判断，默认调用此接口的都是可回收银币的
		nSilverPrice = 2000
	end
	return nSilverPrice
end

-- tItemList {{nID=, nGrid=, nType=, }, ...}
-- fnCallback(bSucc, tItemList, tPriceList)  tPriceList {{nID=, nGrid=, nType=, nCurrType=, nPrice=, }, ...}
function CKnapsack:QueryItemListSalePrice(tItemList, fnCallback) 
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
	for nGridID, tItem in pairs(tTempItemMap) do 
		local nPropID = tItem.nID
		local oProp = self.m_tGridMap[tItem.nGrid]
		if not oProp then --错误数据
			local sTipContent = "道具不存在"
			if ctPropConf[tItem.nID] then 
				sTipContent = string.format("%s不存在", ctPropConf:GetFormattedName(tItem.nID))
			end
			fnInnerCallback(false, sTipContent)
			return
		end
		if oProp:GetID() ~= tItem.nID then 
			fnInnerCallback(false, "数据错误")
			return
		end
		local bSell, sReason = oProp:CheckSale()
		if not bSell then 
			fnInnerCallback(false, sReason)
			return
		end

		if ctCommerceItem[nPropID] then 
			tQueryShopMap[tItem.nGrid] = {nGrid = tItem.nGrid, nItemID = nPropID, 
				nBuyPrice = (oProp:GetBuyPrice() or 0)}
		elseif tItem.nType == 2 and ctBourseItem[nPropID] then
			local nItemType = ctPropConf[nPropID].nType
			if nItemType == gtPropType.eEquipment or nItemType == gtPropType.eRarePrecious then 
				tQueryMarketMap[nPropID] = true
			end
		end

		if tItem.nType == 1 then --出售金币
			if not oProp:CheckSaleGold() then  --检查是否可出售为金币
				local sTipsContent = string.format("%s不可出售", oProp:GetFormattedName())
				fnInnerCallback(false, sTipsContent)
				return 
			end
			-- table.insert(tSaleGold, tItem)
		elseif tItem.nType == 2 then --回收银币
			if not oProp:CheckSaleSilver() then  --检查是否可出售为银币
				local sTipsContent = string.format("%s不可回收", oProp:GetFormattedName())
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
					local nItemType = ctPropConf[nID].nType
					--需要查询摆摊价格的 
					if nItemType == gtPropType.eEquipment or nItemType == gtPropType.eRarePrecious then 
						nPrice = tMarketResult[nID] // 2
						nCurrType, nPrice = fnPriceProc(nType, gtCurrType.eYinBi, tMarketResult[nID] // 2)
					else
						nCurrType, nPrice = fnPriceProc(nType, gtCurrType.eYinBi, CKnapsack:GetBaseSilverPrice(nID))
					end
				else
					if nType == 1 then 
						nCurrType, nPrice = fnPriceProc(nType, gtCurrType.eJinBi, CKnapsack:GetBaseGoldPrice(nID))
					elseif nType == 2 then 
						nCurrType, nPrice = fnPriceProc(nType, gtCurrType.eYinBi, CKnapsack:GetBaseSilverPrice(nID))
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
			Network.oRemoteCall:CallWait("GetMarketBasePriceTblReq", fnMarketCallback, 
				nServer, nService, 0, tQueryMarketList)
		else
			fnMarketCallback({})
		end
	end
	if next(tQueryShopMap) then 
		local nServer = oRole:GetServer()
		local nService = goServerMgr:GetGlobalService(nServer, 20)
		Network.oRemoteCall:CallWait("QueryCommerceSalePriceTblReq", fnShopCallback, 
			nServer, nService, 0, tQueryShopMap)
	else
		fnShopCallback({})
	end

end



--整理背包请求
--@nType 1背包,2仓库
function CKnapsack:ArrangeReq(nType)
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
		tGridMap = self.m_tStoGridMap
	end

	--找出相同的没满的道具合并
	local tSamePropMap = {}
	for _, oProp in pairs(tGridMap) do
		if not oProp:IsFull() then
			local sKey = oProp:GetID()..tostring(oProp:IsBind())
			if not tSamePropMap[sKey] then tSamePropMap[sKey] = {} end
			assert(oProp:GetNum() > 0)
			table.insert(tSamePropMap[sKey], oProp)
		end
	end
	for sKey, tPropList in pairs(tSamePropMap) do
		for k=1, #tPropList-1 do --从前往后
			local oProp1 = tPropList[k]
			if oProp1:GetNum() <= 0 then break end

			for j=#tPropList, k+1, -1 do --从后往前
				local oProp2 = tPropList[j]
				if oProp2:GetNum() > 0 then
					local nAddNum = math.min(oProp1:EmptyNum(), oProp2:GetNum())
					oProp1:AddNum(nAddNum)
					oProp2:SetNum(oProp2:GetNum()-nAddNum)
					if oProp2:GetNum() <= 0 then --被合并的清理掉
						tGridMap[oProp2:GetGrid()] = nil
					end
					if oProp1:IsFull() then
						break
					end
				end
			end
		end
	end

	--筛选排序道具
	local tFrontList = {}
	local tOtherList = {}
	for nGrid, oProp in pairs(tGridMap) do
		if oProp:GetType() <= gtPropType.eCooking then
			table.insert(tFrontList, oProp)
		else
			table.insert(tOtherList, oProp)
		end
	end
	table.sort(tFrontList, function(oProp1, oProp2)
		local nType1, nType2 = oProp1:GetType(), oProp2:GetType()
		if nType1==nType2 then return oProp1:GetID()<oProp2:GetID() end
		return nType1<nType2 
	end)
	table.sort(tOtherList, function(oProp1, oProp2) return oProp1:GetID() < oProp2:GetID() end)

	--重新放置道具
	local nGrid = 1
	local tGridMap
	if nType == 1 then
		self.m_tGridMap = {}
		tGridMap = self.m_tGridMap
	else
		self.m_tStoGridMap = {}
		tGridMap = self.m_tStoGridMap
	end

	for _, oProp in ipairs(tFrontList) do
		oProp:SetGrid(nGrid)
		tGridMap[nGrid] = oProp
		nGrid = nGrid + 1
	end
	for _, oProp in ipairs(tOtherList) do
		oProp:SetGrid(nGrid)
		tGridMap[nGrid] = oProp
		nGrid = nGrid + 1
	end

	--同步
	self:SyncKnapsackItems()
end

--购买格子请求
--@nType 1背包,2仓库
--@nCurrType 0道具, 2元宝, 4金币, 5银币
function CKnapsack:BuyGridReq(nType, nCurrType)
	if nType == 1 then
		if self.m_nGridNum >= nMaxGrids then
			return self.m_oRole:Tips("已达背包容量上限，扩充失败")
		end
		assert(nMaxGrids > 0 and nMaxGrids > nInitGrids)
	else
		if self.m_nStoGridNum >= nStoMaxGrids then
			return self.m_oRole:Tips("已达仓库容量上限，扩充失败")
		end
		assert(nStoMaxGrids > 0 and nStoMaxGrids > nStoInitGrids)
	end

	--背包
	if nType == 1 then
		local nBuyTimes = self.m_nBuyGridTimes+1
		local nPropNum = ctPropEtcConf[1].eExpandCost(nBuyTimes)
		local nLackPropNum = math.max(0, nPropNum-self.m_oRole:ItemCount(gtItemType.eProp, nExpandProp))
		local nYuanBao = nLackPropNum*ctPropConf[nExpandProp].nBuyPrice
		local nJinBi = nLackPropNum*ctPropConf[nExpandProp].nGoldPrice

		if nCurrType == gtCurrType.eYuanBao or nCurrType == gtCurrType.eAllYuanBao then
			if not self.m_oRole:CheckSubItem(gtItemType.eCurr, gtCurrType.eAllYuanBao, nYuanBao, "扩充背包格子") then
				return self.m_oRole:YuanBaoTips()
			end
			if not self.m_oRole:CheckSubItem(gtItemType.eProp, nExpandProp, nPropNum-nLackPropNum, "扩充背包格子") then
				return self.m_oRole:Tips(string.format("%s不足", self:PropName(nExpandProp)))
			end

		elseif nCurrType == gtCurrType.eJinBi then
			if not self.m_oRole:CheckSubItem(gtItemType.eCurr, gtCurrType.eJinBi, nJinBi, "扩充背包格子") then
				return self.m_oRole:JinBiTips()
			end
			if not self.m_oRole:CheckSubItem(gtItemType.eProp, nExpandProp, nPropNum-nLackPropNum, "扩充背包格子") then
				return self.m_oRole:Tips(string.format("%s不足", self:PropName(nExpandProp)))
			end

		elseif nCurrType == 0 then
			if not self.m_oRole:CheckSubItem(gtItemType.eProp, nExpandProp, nPropNum, "扩充背包格子") then
				return self.m_oRole:Tips(string.format("%s不足", self:PropName(nExpandProp)))
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
		local nYinBi = ctPropEtcConf[1].eStoExpandCost(nBuyTimes)
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
		self.m_nStoGridNum = math.min(self.m_nStoGridNum + nBuyGridOnce, nStoMaxGrids)
		self.m_nStoBuyGridTimes = self.m_nStoBuyGridTimes + 1
		self.m_oRole:Tips("扩充仓库格子成功")

	end
	self:MarkDirty(true)

	local nGridNum = nType == 1 and self.m_nGridNum or self.m_nStoGridNum
	local nBuyTimes = nType == 1 and self.m_nBuyGridTimes or self.m_nStoBuyGridTimes
	self.m_oRole:SendMsg("KnapsackBuyGridRet", {nType=nType, nGridNum=nGridNum, nBuyTimes=nBuyTimes})
end

--存入仓库请求
function CKnapsack:PutStorageReq(nGrid)
	local oProp = self:GetItem(nGrid)
	if not oProp then
		return
	end

	local nFreeGrid = self:GetFreeGrid(2)
	if nFreeGrid == 0 then
		return self.m_oRole:Tips("仓库已满，存入失败")
	end

	--清除背包格子
	self.m_tGridMap[nGrid] = nil
	self:OnItemRemoved(nGrid, 1, false)

	--放入仓库格子
	oProp:SetGrid(nFreeGrid)
	self.m_tStoGridMap[nFreeGrid] = oProp
	self:OnItemAdded(nFreeGrid, 2, false, false)
	self:MarkDirty(true)
end

--提取仓库请求
function CKnapsack:GetStorageReq(nGrid)
	local oProp = self:GetStoItem(nGrid)
	if not oProp then
		return
	end

	local nFreeGrid = self:GetFreeGrid(1)
	if nFreeGrid == 0 then
		return self.m_oRole:Tips("背包已满，提取失败")
	end

	--清除仓库格子
	self.m_tStoGridMap[nGrid] = nil
	self:OnItemRemoved(nGrid, 2, false)

	--放入背包格子
	oProp:SetGrid(nFreeGrid)
	self.m_tGridMap[nFreeGrid] = oProp
	self:OnItemAdded(nFreeGrid, 1, false, false)
	self:MarkDirty(true)

	--添加物品事件
	self.m_oRole.m_oPractice:OnAddItem(oProp:GetID())
end

--道具传送
--@bNotSync是否不同步
function CKnapsack:TransferItem(tItemData, bNotSync)
	--帮派神诏要特殊处理
	local tConf = ctPropConf[tItemData.m_nID]
	if not tConf then
		return self.m_oRole:Tips("道具配置不存在:"..tConf.nID)
	end
	local cClass = gtPropClass[tConf.nType]
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
	local oProp = self:CreateProp(tItemData.m_nID, tItemData.m_nGrid)
	oProp:LoadData(tItemData)
	oProp:UpdateKey()
	oProp:SetGrid(nFreeGrid)
	self.m_tGridMap[nFreeGrid] = oProp
	self:OnItemAdded(nFreeGrid, 1, true, bNotSync)

	self:UpdateBuyPrice(tItemData.m_nID, tItemData.m_nBuyPrice or 0)
	self:MarkDirty(true)

	return self:ItemCount(oProp:GetID())
end

--取物品数据
function CKnapsack:GetItemData(nGrid)
	local oProp = self:GetItem(nGrid)
	if not oProp then
		return
	end
	local tItemData = oProp:SaveData()
	return tItemData 
end

--取多个道具数据
function CKnapsack:GetItemDataList(tList)
	local tPropData = {}
	for _, nGrid in pairs(tList) do
		local oProp = self:GetItem(nGrid)
		if oProp then
			tPropData[#tPropData+1] = oProp:SaveData()
		end
	end
	return tPropData
end

--通过ID取多个道具的数据
function CKnapsack:GetPropDataList(nPropID)
	local tPropData = {}
	for _, oProp in pairs(self.m_tGridMap) do
		if oProp:GetID() == nPropID then
			table.insert(tPropData, oProp:SaveData())
		end
	end
	return tPropData
end

--取宠物多个装备属性
function CKnapsack:KnapsacGetPetEquReq(tItemGrid)
	local tEquList = {}
	for _, tItem in pairs(tItemGrid) do
		oProp = self.m_tGridMap[tItem.nGrid]
		if oProp then
			tEquList[#tEquList+1] = oProp:GetDetailInfo(tItem.nGrid)
		end
	end
	local tMsg = {}
	tMsg.tPetEqu = tEquList
	self.m_oRole:SendMsg("KnapsacGetPetEquRet", tMsg)
end

function CKnapsack:GetPropByBox(nBoxType, nBoxParam)
	local oProp = nil
	if nBoxType == gtPropBoxType.eBag then
		oProp = self.m_tGridMap[nBoxParam]
	elseif nBoxType == gtPropBoxType.eEquipment then
		oProp = self.m_tWearEqu[nBoxParam]
	elseif nBoxType == gtPropBoxType.eStorage then
		oProp = self.m_tStoGridMap[nBoxParam]
	else
		--return
	end
	return oProp
end

--CS PB协议用
function CKnapsack:GetPropDetailInfo(oProp, nBoxType, nBoxParam, nOtherType)
	assert(oProp, "参数错误")
	if not oProp.GetDetailInfo then
		-- self.m_oRole:Tips(string.format("道具 %s 详细信息未实现", oProp:GetName()))
		return
	end
	local nPropType = oProp:GetType()
	local tRetData = {}
	local tDetail = {}
	tDetail.nOtherType = nOtherType
	tRetData.tDetail = tDetail
	tDetail.nType = nPropType
	if nBoxType then 
		tDetail.nBoxType = nBoxType
	end
	if nBoxParam then 
		tDetail.nBoxParam = nBoxParam
	end 
	if nPropType == gtPropType.eEquipment then
		tDetail.tEqu = oProp:GetDetailInfo()
	end
	if nPropType == gtPropType.ePetEqu then
		tDetail.tPetEqu = oProp:GetDetailInfo()
	end
	if nPropType == gtPropType.eArtifact then
		tDetail.tArtifactEqu = oProp:GetDetailInfo()
	end
	return tRetData
end

--发送物品详细信息
function CKnapsack:SendPropDetailInfo(oProp, nBoxType, nBoxParam, nOtherType)
	local tRetData = self:GetPropDetailInfo(oProp, nBoxType, nBoxParam, nOtherType)
	if tRetData then 
		-- print("道具查询MSg", tRetData)
		return self.m_oRole:SendMsg("KnapsacPropDetailRet", tRetData)
	else
		self.m_oRole:Tips(string.format("道具 %s 详细信息未实现", oProp:GetName()))
	end
end

--获取物品详细信息
function CKnapsack:PropDetailReq(nBoxType, nBoxParam, nOtherType)
	if not (nBoxType and nBoxParam) then
		return self.m_oRole:Tips("不合法的请求参数")
	end
	local oProp = self:GetPropByBox(nBoxType, nBoxParam)
	if not oProp then
		return self.m_oRole:Tips(string.format("道具不存在 boxtype:%d boxparam:%d", nBoxType, nBoxParam))
	end
	self:SendPropDetailInfo(oProp, nBoxType, nBoxParam, nOtherType)
end

function CKnapsack:CheckDailyReset(nTimeStamp)
	nTimeStamp = nTimeStamp or os.time()
	if os.IsSameDay(nTimeStamp, self.m_nDailyResetStamp, 0) then 
		return 
	end
	self.m_nWeddingCandyPickRecord = 0
	self.m_nOldManItemPickRecord = 0
	self.m_tPropUseRecord = {}
	self.m_nDailyResetStamp = nTimeStamp
	self.m_nDailySaleYuanbaoNum = 0
	self:MarkDirty(true)
	self:SyncSaleYuanbaoRecord()
end

function CKnapsack:OnHourTimer()
	self:CheckDailyReset()
end
--添加使用计数
function CKnapsack:AddUseCount(nPropID, nCount)
	assert(nPropID > 0 and nCount > 0, "参数错误")
	self.m_tPropUseRecord[nPropID] = (self.m_tPropUseRecord[nPropID] or 0) + nCount
	self:MarkDirty(true)
end
--获取使用计数
function CKnapsack:GetUseCount(nPropID)
	return self.m_tPropUseRecord[nPropID] or 0
end

function CKnapsack:AddPickWeddingCandyCount(nNum)
	self.m_nWeddingCandyPickRecord = self.m_nWeddingCandyPickRecord + nNum
	self:MarkDirty(true)
end

function CKnapsack:AddPickOldManItemCount(nNum)
	self.m_nOldManItemPickRecord = self.m_nOldManItemPickRecord + nNum
	self:MarkDirty(true)
end

function CKnapsack:GetPickOldManItemCount()
	return self.m_nOldManItemPickRecord
end

function CKnapsack:GetPickWeddingCandyCount()
	return self.m_nWeddingCandyPickRecord
end


function CKnapsack:IsOccupyBagGrid(nItemType, nItemID)
	if nItemType == gtItemType.eProp then 
		local tPropConf = ctPropConf[nItemID]
		if tPropConf and tPropConf.nType ~= gtPropType.eCurr then 
			return true
		end
	end
	return false
end

--外层有重新计算角色属性
function CKnapsack:OnRoleLevelChange(nOldLevel, nNewLevel)
	self:CheckLegendEquUpgrade()
	self:UpdateGemTips(true)
end

function CKnapsack:GetEquStrengthenTriggerID()
	return self.m_tStrengthenTriggerData.nTriggerID
end

function CKnapsack:GetEquStrengthenTriggerAttr()
	return self.m_tStrengthenTriggerData.tTriggerAttr
end

function CKnapsack:GetEquGemTriggerID()
	return self.m_tGemTriggerData.nTriggerID
end

function CKnapsack:GetEquGemTriggerAttr()
	return self.m_tGemTriggerData.tTriggerAttr
end

