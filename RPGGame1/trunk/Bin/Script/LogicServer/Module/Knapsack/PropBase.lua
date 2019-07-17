--道具基类
function CPropBase:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	self.m_oModule = oModule
	self.m_nID = nID 		--道具ID
	self.m_nKey = 0
	self.m_nGrid = nGrid 	--格子ID
	self.m_nFold = 0 		--折叠数量
	self.m_bBind = bBind and true or false 	--是否绑定
	self.m_nBuyPrice = tPropExt.nBuyPrice or 0 
end

function CPropBase:LoadData(tData)
	self.m_nID = tData.m_nID
	self.m_nKey = tData.m_nKey or self.m_oModule:GenKey()
	self.m_nGrid = tData.m_nGrid
	self.m_nFold = tData.m_nFold
	self.m_bBind = tData.m_bBind and true or false
	self.m_nBuyPrice = tData.m_nBuyPrice or self.m_nBuyPrice
end

function CPropBase:SaveData()
	local tData = {}
	tData.m_nID = self.m_nID
	tData.m_nKey = self.m_nKey
	tData.m_nGrid = self.m_nGrid
	tData.m_nFold = self.m_nFold
	tData.m_bBind = self.m_bBind
	tData.m_nBuyPrice = self.m_nBuyPrice
	return tData
end

function CPropBase:GetID() return self.m_nID end
function CPropBase:GetKey() return self.m_nKey end
function CPropBase:UpdateKey() self.m_nKey = self.m_oModule:GenKey() end
function CPropBase:GetType() return self:GetPropConf().nType end
function CPropBase:GetPropConf() return assert(ctPropConf[self.m_nID]) end
function CPropBase:GetName() return self:GetPropConf().sName end
function CPropBase:GetFormattedName()
	local nQualityLevel = self:GetQualityLevel()
	return CUtil:FormatPropQualityString(nQualityLevel, self:GetName())
end
function CPropBase:GetGrid() return self.m_nGrid end
function CPropBase:SetGrid(nGrid) self.m_nGrid = nGrid end
function CPropBase:MaxFold() return self:GetPropConf().nFold end
function CPropBase:IsBind() return self.m_bBind end
function CPropBase:SetBind(bBind) self.m_bBind = bBind end
function CPropBase:GetStar() return 0 end 
function CPropBase:GetBuyPrice() return self.m_nBuyPrice end  	--商会购买价格
function CPropBase:SetBuyPrice(nBuyPrice ) self.m_nBuyPrice = nBuyPrice end  --商会购买价格

function CPropBase:IsFull() return self.m_nFold >= self:MaxFold() end
function CPropBase:GetNum() return self.m_nFold end
function CPropBase:SetNum(nNum) self.m_nFold = nNum end
function CPropBase:AddNum(nNum) self.m_nFold = self.m_nFold + nNum end
function CPropBase:SubNum(nNum) self.m_nFold = self.m_nFold - nNum end
function CPropBase:EmptyNum() return math.max(self:MaxFold() - self.m_nFold, 0) end
function CPropBase:GetQualityLevel() return self:GetPropConf().nQuality end
function CPropBase:IsEquipment() return false end

function CPropBase:OnRemovedFromRole() end --子类改写
function CPropBase:CheckCanAddNum(oRole, nPropID, nAddNum, bMail)
	return nAddNum
end --子类有需要实现

function CPropBase:CheckSale()
	local tConf = self:GetPropConf()
	if not tConf then 
		return false, "道具不可出售"
	end
	-- M2BT 所有绑定道具都可出售
	if (not self:IsBind()) and tConf.nSellGoldPrice <= 0 and tConf.nSellCopperPrice <= 0 then
		if not ctCommerceItem[self:GetID()] then 
			return false, "道具不可出售"
		end
	end
	return true 
end

function CPropBase:CheckSaleGold()
	if self:GetPropConf().nSellGoldPrice > 0 then 
		return true 
	end
	if not ctCommerceItem[self:GetID()] then
		return false
	end
	if self:IsBind() then
		return false 
	end 
	return true
end

function CPropBase:CheckSaleSilver()
	-- if self:CheckSaleGold() then --能出售的，不能回收
	-- 	return false 
	-- end
	if self:IsBind() then 	-- M2BT 所有绑定道具都可出售
		return true 
	end 
	if self:GetPropConf().nSellCopperPrice > 0 then 
		return true 
	end
	if ctCommerceItem[self:GetID()] and self:IsBind() then 
		return true 
	end
	return false
end

function CPropBase:GetBaseSilverPrice()
	-- local nConfPrice = self:GetPropConf().nSellCopperPrice
	-- if nConfPrice <= 0 then 
	-- 	nConfPrice = 1000 --绑定的道具，如果未配置，默认1000
	-- end
	-- return nConfPrice
	return CKnapsack:GetBaseSilverPrice(self:GetID())
end

function CPropBase:GetInfo()
	local tInfo = {}
	tInfo.nID = self.m_nID
	tInfo.nType = self:GetType()
	tInfo.nGrid = self.m_nGrid
	tInfo.nFold = self.m_nFold
	tInfo.bBind = self.m_bBind
	tInfo.nBuyPrice = self.m_nBuyPrice
	tInfo.nQualityLevel = self:GetQualityLevel()
	tInfo.nKey = self:GetKey()
	return tInfo
end

-- --出售
-- function CPropBase:Sell(nNum, nType)
-- 	nNum = nNum or 0
-- 	if nNum < 1 then 
-- 		return 
-- 	end
-- 	local oRole = self.m_oModule.m_oRole
-- 	local nSellCopperPrice = self:GetPropConf().nSellCopperPrice
-- 	local nSellGoldPrice = self:GetPropConf().nSellGoldPrice
-- 	if nNum > self:GetNum() then 
-- 		oRole:Tips("非法参数")
-- 		return
-- 	end

-- 	local bSell, sReason = self:CheckSale()
-- 	if not bSell then 
-- 		if sReason then 
-- 			oRole:Tips(sReason)
-- 		end
-- 		return 
-- 	end

-- 	--1出售系统,2回收银币
-- 	if nType == 1 then
-- 		if nSellGoldPrice <= 0 then
-- 			oRole:Tips("道具不可出售(出售价格配置错误)")
-- 		end
-- 		if self.m_bBind then
-- 			local nYinBi =  nNum * nSellGoldPrice * 100
-- 			oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nYinBi, "出售道具")
-- 		else
-- 			oRole:AddItem(gtItemType.eCurr, gtCurrType.eJinBi, nSellGoldPrice*nNum, "出售道具")
-- 		end
-- 		oRole.m_oKnapsack:SubGridItem(self:GetGrid(), self:GetID(), nNum, "出售道具")
-- 	elseif nType == 2 then
-- 		if nSellCopperPrice <= 0 then
-- 			oRole:Tips("道具不可出售(出售价格配置错误)")
-- 		end
-- 		oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nSellCopperPrice*nNum, "出售道具")
-- 		oRole.m_oKnapsack:SubGridItem(self:GetGrid(), self:GetID(), nNum, "出售道具")
-- 	else
-- 		return oRole:Tips("出售类型错误")
-- 	end

-- 	-- if nSellGoldPrice > 0 then
-- 	-- 	if self.m_bBind then
-- 	-- 		local nYinBi =  nNum * nSellGoldPrice * 100
-- 	-- 		oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nYinBi, "出售道具")
-- 	-- 	else
-- 	-- 		oRole:AddItem(gtItemType.eCurr, gtCurrType.eJinBi, nSellGoldPrice*nNum, "出售道具")
-- 	-- 	end
-- 	-- 	oRole.m_oKnapsack:SubGridItem(self:GetGrid(), self:GetID(), nNum, "出售道具")

-- 	-- elseif nSellCopperPrice > 0 then
-- 	-- 	oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nSellCopperPrice*nNum, "出售道具")
-- 	-- 	oRole.m_oKnapsack:SubGridItem(self:GetGrid(), self:GetID(), nNum, "出售道具")

-- 	-- else
-- 	-- 	oRole:Tips("道具不可出售(出售价格配置错误)")
-- 	-- end
-- end