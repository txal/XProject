--商店系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--表预处理
local _ctShopItemMap = {} --[商店类型] =商店conf
local function _PreProcessConf()
	for nIndex, tConf in pairs(ctShopConf) do
		if not _ctShopItemMap[tConf.nShopType] then
		--	_ctShopItemMap[tConf.nShopType] = {}
		end
		--_ctShopItemMap[tConf.nShopType][tConf.nID] = tConf
	end
end
-- _PreProcessConf()

--构造函数
function CShop:Ctor(oRole)
	--print("_ctShopItemMap",_ctShopItemMap)
	--print( self:GetItemByShopTypeAndId(102, 1) )
	self.m_oRole = oRole
	self.m_tShopMap = {} --[商店类型] =商店对象
	self.m_tShopMap[gtShopType.eDrugStore] = CDrugStore:new(self)   --药店
	self.m_tShopMap[gtShopType.eDressStore] = CDressStore:new(self) --服装店
	self.m_tShopMap[gtShopType.eArmStore] = CArmStore:new(self) --武器店
	self.m_tShopMap[gtShopType.eGoldStore] = CGoldStore:new(self) --元宝商城
	self.m_tShopMap[gtShopType.eArenaScore] = CArenaScoreStore:new(self) --积分商城
end

function CShop:LoadData(tData)
	--print("CShop:加载商店数据",tData)
	if not tData then
		return
	end
	for nShopType, tShopData in pairs(tData) do
		--print("tShopData",tShopData)
		self.m_tShopMap[nShopType]:LoadData(tShopData)
	end
end

function CShop:SaveData()
	--print("CShop:保存商店数据SaveData()",self:IsDirty())
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	for nShopType, oShop in pairs(self.m_tShopMap) do
		tData[nShopType] = oShop:SaveData()
	end
	--print("CShop:保存商店数据SaveData()->tData",tData)
	return tData
end

function CShop:GetType()
	return gtModuleDef.tShop.nID, gtModuleDef.tShop.sName
end

--获取子商店
function CShop:GetSubShop(nShopType)
	return self.m_tShopMap[nShopType]
end

function CShop:Online()
end

--获取商品 不传nID则返回 此类型商店的整个物品 否则返回此类型商店的单个物品
function CShop:GetItemByShopTypeAndId(nShopType, nID)
	assert(nShopType, "缺少商店类型")
	if not nID then
		return _ctShopItemMap[nShopType]
	end
	return _ctShopItemMap[nShopType][nID]
end

--判断货币是否足够 
function CShop:CheckCurrIsEnough(tItem, nNum)
	local nHasCurr = self.m_oRole:ItemCount(gtItemType.eCurr, tItem.nMoneyType)
	local nCostCurr = tItem.nNeedNum*nNum

	if nHasCurr < nCostCurr then
		return false 
	end
	return true
end
