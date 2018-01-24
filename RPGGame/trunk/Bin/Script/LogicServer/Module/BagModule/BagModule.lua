local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CBagModule:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nAutoInc = 0
	self.m_tGridItemMap = {}
	self.m_tSlotArmMap = {}
	self.m_nCurrItem = 0
	self.m_nOpenGrid = ctBagConf[1].nInitGrid
end

function CBagModule:GetSlotArmMap()
	return self.m_tSlotArmMap
end

function CBagModule:GetGridItemMap()
	return self.m_tGridItemMap
end

function CBagModule:Online()
	if not next(self.m_tSlotArmMap) then
		for _, tArm in pairs(ctPlayerInitConf[1].tInitArm) do
			local tArmList = self.m_oPlayer:AddItem(gtObjType.eArm, tArm[1], 1, gtReason.ePlayerInit)
			if #tArmList > 0 then
				self:PutOnArm(tArmList[1][1])
			end
		end
	end
end

function CBagModule:GetType()
	return gtModuleDef.tBagModule.nID, gtModuleDef.tBagModule.sName
end

function CBagModule:GenAutoID()
	self.m_nAutoInc = self.m_nAutoInc % nMAX_INTEGER + 1
	return self.m_nAutoInc
end

function CBagModule:LoadData(tData)
	self.m_nCurrItem = tData.nCurrItem or 0
	self.m_nOpenGrid = tData.nOpenGrid or ctBagConf[1].nInitGrid
	self.m_nAutoInc = tData.nAutoInc or 0

	local tSlotMap = tData.tSlotMap or {}
	for nSlotID, tArmData in pairs(tSlotMap) do
		local nConfID = tArmData.nConfID
		if ctArmConf[nConfID] then
			local oArm = CArmItem:new(self)
			oArm:Load(tArmData)
			self.m_tSlotArmMap[nSlotID] = oArm
		end
	end

	local nCurrItem = 0
	local tBagMap = tData.tBagMap or {}
	for nGridID, tItemData in pairs(tBagMap) do
		local nConfID = tItemData.nConfID
		if tItemData.nObjType == gtObjType.eArm then
			if ctArmConf[nConfID] then
				local oArm = CArmItem:new(self)
				oArm:Load(tItemData)
				self.m_tGridItemMap[nGridID] = oArm
				nCurrItem = nCurrItem + 1
			end

		elseif tItemData.nObjType == gtObjType.eProp then
			if ctPropConf[nConfID] then
				local oProp = CPropItem:new(self)
				oProp:Load(tItemData)
				self.m_tGridItemMap[nGridID] = oProp
				nCurrItem = nCurrItem + 1
			end

		else
			assert(false, "类型不支持 "..tItemData.nObjType)
		end
	end
	self.m_nCurrItem = nCurrItem
end

function CBagModule:SaveData()
	local tSlotMap = {}
	for nSlotID, oArm in pairs(self.m_tSlotArmMap) do
		tSlotMap[nSlotID] = oArm:Pack()
	end
	local tBagMap = {}
	for nGridID, oItem in pairs(self.m_tGridItemMap) do
		tBagMap[nGridID] = oItem:Pack()
	end
	local tData = {}
	tData.tSlotMap = tSlotMap
	tData.tBagMap = tBagMap
	tData.nCurrItem = self.m_nCurrItem
	tData.nOpenGrid = self.m_nOpenGrid
	tData.nAutoInc = self.m_nAutoInc
	return tData
end

function CBagModule:GetFreeGridNum()
	return self.m_nOpenGrid - self.m_nCurrItem
end

function CBagModule:GetFreeGridID(nItemType, nItemID)
	assert(nItemType and nItemID)
	if nItemType == gtObjType.eArm then
		if self:GetFreeGridNum() <= 0 then
			return 0 
		end
		for i = 1, self.m_nOpenGrid do
			if not self.m_tGridItemMap[i] then
				return i
			end
		end

	elseif nItemType == gtObjType.eProp then
		local nEmptyGrid = 0
		for i = 1, self.m_nOpenGrid do
			local oItem = self.m_tGridItemMap[i]
			if not oItem and nEmptyGrid == 0 then
				nEmptyGrid = i
			elseif oItem and oItem:GetObjType() == nItemType and oItem:GetConfID() == nItemID and not oItem:IsFull() then
				return i
			end
		end
		return nEmptyGrid

	else
		assert(false, "类型不支持 "..nItemType)
	end
	return 0
end

--装备信息
function CBagModule:_arm_item_info(oArm)
	assert(oArm:GetObjType() == gtObjType.eArm)
	local tInfo = {}
	tInfo.nAutoID = oArm:GetAutoID()
	tInfo.nItemID = oArm:GetConfID()
	tInfo.nObjType = oArm:GetObjType()
	tInfo.nNum = oArm:GetCount()
	tInfo.nLevel = oArm:GetLevel()
	tInfo.nColor = oArm:GetColor()
	tInfo.bVariation = oArm:GetVariation()
	tInfo.nTotalStar = oArm:CalcQuality()
	tInfo.nInitStar = oArm:InitStar()
	tInfo.nGrowStar = oArm:GrowStar()
	tInfo.tFeature = {}
	local tFeature = oArm:GetFeature()
	for k, v in ipairs(tFeature) do
		tInfo.tFeature[k] = {nID=v[1], nType=v[2]}
	end
end

--道具信息
function CBagModule:_prop_item_info(oItem)
	assert(oItem:GetObjType() == gtObjType.eProp)
	local tInfo = {}
	tInfo.nAutoID = oItem:GetAutoID()
	tInfo.nItemID = oItem:GetConfID()
	tInfo.nObjType = oItem:GetObjType()
	tInfo.nNum = oItem:GetCount()
	tInfo.nColor = oItem:GetConf().nColor
	return tInfo
end

function CBagModule:_bag_item_info(nGridID, oItem)
	local tBagItem = {nGridID=nGridID}
	local nObjType = oItem:GetObjType()
	if nObjType == gtObjType.eArm then
		tBagItem.tItem = self:_arm_item_info(oItem)

	elseif nObjType == gtObjType.eProp then
		tBagItem.tItem = self:_prop_item_info(oItem)

	else
		assert(false, "类型不支持:"..nObjType)

	end
	return tBagItem
end

function CBagModule:_slot_arm_info(nSlotID, oArm)
	assert(oArm:GetObjType() == gtObjType.eArm)
	local tSlotItem = {nSlotID=nSlotID}
	tSlotItem.tItem = self:_arm_item_info(oArm)
	return tSlotItem
end

--判断背包是否满
function CBagModule:IsBagFull(nObjType, nItemID, nItemNum)
	if nObjType == gtObjType.eArm then
		local nFreeGridNum = self:GetFreeGridNum() 
		if nFreeGridNum < nItemNum then
			return true
		end
	elseif nObjType == gtObjType.eProp then
		local tConf = assert(ctPropConf[nItemID])
		if tConf.nCollapse == 1 then --不能折叠的道具
			local nFreeGridNum = self:GetFreeGridNum() 
			if nFreeGridNum < nItemNum then
				return true
			end
		else
			local nGridID = self:GetFreeGridID(nObjType, nItemID) 
			if nGridID == 0 then
				return true
			end
		end
	else
		assert(false, "类型不支持 "..nObjType)
	end
end

--添加物品
function CBagModule:AddItem(nObjType, nItemID, nItemNum)
	assert(nItemNum >= 0)
	if nItemNum == 0 then
		return
	end
	
	if nObjType == gtObjType.eArm then
		local nFreeGridNum = self:GetFreeGridNum() 
		if nFreeGridNum < nItemNum then
			LuaTrace("背包已满", self.m_oPlayer:GetCharID(), nObjType, nItemID, nItemNum)
			self.m_oPlayer:ScrollMsg(ctLang[34])
			return
		end
		return self:CreateArm(nItemID, nItemNum)

	elseif nObjType == gtObjType.eProp then
		local tConf = ctPropConf[nItemID]
		assert(tConf.nType ~= gtPropType.eCurrency, "不能添加货币到背包")
		if tConf.nCollapse == 1 then --不能折叠的道具
			local nFreeGridNum = self:GetFreeGridNum() 
			if nFreeGridNum < nItemNum then
				LuaTrace("背包已满", self.m_oPlayer:GetCharID(), nObjType, nItemID, nItemNum)
				self.m_oPlayer:ScrollMsg(ctLang[34])
				return
			end
			local tItemList = {}
			for k = 1, nItemNum do	
				local nGridID = self:GetFreeGridID(nObjType, nItemID) 
				assert(not self.m_tGridItemMap[nGridID])
				local oProp = CPropItem:new(self)
				oProp:Init(self:GenAutoID(), nItemID, 1)
				self.m_tGridItemMap[nGridID] = oProp
				self.m_nCurrItem = self.m_nCurrItem + 1
				table.insert(tItemList, {nGridID, oProp})
			end
			self:OnBagItemAdded(tItemList)
			return tItemList

		else
			local nGridID = self:GetFreeGridID(nObjType, nItemID) 
			if nGridID == 0 then
				LuaTrace("背包已满", self.m_oPlayer:GetCharID(), nObjType, nItemID, nItemNum)
				self.m_oPlayer:ScrollMsg(ctLang[34])
				return
			end
			local tItemList = {}
			local oProp = self.m_tGridItemMap[nGridID]
			if not oProp then
				oProp = CPropItem:new(self)
				oProp:Init(self:GenAutoID(), nItemID, nItemNum)
				self.m_tGridItemMap[nGridID] = oProp
				self.m_nCurrItem = self.m_nCurrItem + 1
				table.insert(tItemList, {nGridID, oProp})
				self:OnBagItemAdded(tItemList)

			else
				oProp:AddNum(nItemNum)
				table.insert(tItemList, {nGridID, oProp})
			    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "BagItemCountSync", {nGridID=nGridID, nCount=oProp:GetCount()})

			end
			return tItemList

		end

	end
	assert(false, "类型不支持 "..nObjType)
end

--取背包物品个数
function CBagModule:GetItemCount(nObjType, nItemID)
	if nObjType == gtObjType.eProp or nObjType == gtObjType.eArm  then
		for nGridID, oItem in pairs(self.m_tGridItemMap) do
			if oItem:GetObjType() == nObjType and oItem:GetConfID() == nItemID then
				return oItem:GetCount()
			end
		end
		return 0
	end
	assert(false, "类型不支持 "..nObjType)
end

--扣除物品
function CBagModule:SubItem(nObjType, nItemID, nItemNum, nReason)
	assert(nItemNum > 0)
	assert(nObjType == gtObjType.eProp, "扣除物品类型不支持 "..nObjType)
	for nGridID, oItem in pairs(self.m_tGridItemMap) do
		if oItem:GetObjType() == gtObjType.eProp and oItem:GetConfID() == nItemID then
			if oItem:GetCount() < nItemNum then
				return
			end
			oItem:SubNum(nItemNum)
			if oItem:GetCount() <= 0 then
				self:ClearBagItem(nGridID, nReason)

			else
			    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "BagItemCountSync", {nGridID=nGridID, nCount=oItem:GetCount()})
			    
			end
		    goLogger:AwardLog(gtEvent.eSubItem, nReason, self.m_oPlayer, nObjType, nItemID, nItemNum, oItem:GetCount())
			return true
		end
	end
end

--物品添加成功
function CBagModule:OnBagItemAdded(tItemList)
	for _, tAddItem in ipairs(tItemList) do
		local nGridID, oItem = tAddItem[1], tAddItem[2]
		local tItemInfo = self:_bag_item_info(nGridID, oItem)
		local tMsg = {nCurrItem=self.m_nCurrItem, nOpenGrid=self.m_nOpenGrid, tItem=tItemInfo}
	    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "BagItemAddSync", tMsg)
	end
	self.m_oPlayer:SyncBagContainer()
end

--物品删除成功
function CBagModule:OnBagItemRemoved(tGridList)
	for _, nGridID in ipairs(tGridList) do
		local tMsg = {nGridID=nGridID, nCurrItem=self.m_nCurrItem, nOpenGrid=self.m_nOpenGrid}
	    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "BagItemRemoveSync", tMsg)
	end
	self.m_oPlayer:SyncBagContainer()
end

--取背包栏物品
function CBagModule:GetBagItem(nGridID)
	return self.m_tGridItemMap[nGridID]
end

--清除背包物品
function CBagModule:ClearBagItem(nGridID, nReason)
	local oItem = self:GetBagItem(nGridID)
	if not oItem then
		return
	end
	local nObjType = oItem:GetObjType()
	if nObjType == gtObjType.eArm then
		self:RemoveArm(nGridID, nReason)

	elseif nObjType == gtObjType.eProp then
		self.m_tGridItemMap[nGridID] = nil
		self.m_nCurrItem = self.m_nCurrItem - 1	
		self:OnBagItemRemoved({nGridID})

	else
		assert(false, "类型不支持 "..nObjType)
	end
end

--背包信息
function CBagModule:SyncBagInfo()
	local tBagInfo = {nCurrItem=self.m_nCurrItem, nOpenGrid=self.m_nOpenGrid, nMaxGrid=ctBagConf[1].nMaxGrid, tItemList={}, tSlotList={}}
	tBagInfo.tOpenSlot = self:GetOpenSlot()
	
	local tItemList, tSlotList = tBagInfo.tItemList, tBagInfo.tSlotList
	--右侧列表
	for nGridID, oItem in pairs(self.m_tGridItemMap) do
		local tBagItem =  self:_bag_item_info(nGridID, oItem)
		table.insert(tItemList, tBagItem)
	end
	--左侧列表
	for nSlot, oArm in pairs(self.m_tSlotArmMap) do
		local tSlotItem = self:_slot_arm_info(nSlot, oArm)
		table.insert(tSlotList, tSlotItem)
	end
    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "BagInfoRet", tBagInfo)
end

--请求背包信息
function CBagModule:OnBagInfoReq()
	self:SyncBagInfo()
end

--请求物品详细信息
function CBagModule:OnItemDetailReq(nPosType, nPosID)
	local oItem
	if nPosType == 1 then 
	--装备孔
		oItem = self:GetSlotArm(nPosID)

	elseif nPosType == 2 then
	--背包栏
		oItem = self:GetBagItem(nPosID)
	end
	if not oItem then
		return
	end
	local nObjType = oItem:GetObjType()
	if nObjType == gtObjType.eArm then
		self:SyncArmDetailInfo(oItem)
	else
		assert(false, "道具没有详细信息")
	end
end

--同步装备详细信息
function CBagModule:SyncArmDetailInfo(oArm)
	local tDetail = oArm:GetDetail()
	--print("SyncArmDetailInfo***", tDetail)
	if oArm:GetType() == gtArmType.eDecoration then
	    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "DecorationDetailRet", tDetail)
	else
	    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ArmDetailRet", tDetail)
	end
end

--删除所有背包物品
function CBagModule:RemoveAllBagItem()
	for nGridID, oItem in pairs(self.m_tGridItemMap) do
		self:ClearBagItem(nGridID, gtReason.eNone)
	end
end

--使用道具
function CBagModule:UseProp(nGridID)
	local oItem = self.m_tGridItemMap[nGridID]
	if not oItem or oItem:GetObjType() ~= gtObjType.eProp or oItem:GetCount() <= 0 then
		return 
	end
	local nPropID = oItem:GetConfID()
	local tConf = ctPropConf[nPropID]
	if tConf.nUseLevel < 0 then
		return self.m_oPlayer:ScrollMsg(ctLang[31])
	end
	local nLevel = self.m_oPlayer:GetLevel()
	if nLevel < tConf.nUseLevel then
		return self.m_oPlayer:ScrollMsg(string.format(ctLang[32], tConf.nUseLevel))
	end
	if tConf.nType == gtPropType.eGift then
		if not gtPropUse:UseGift(self.m_oPlayer, nPropID) then
			return
		end
	elseif gtPropUse[nPropID] then
		if not gtPropUse[nPropID](self.m_oPlayer) then
			return
		end
	else
		return LuaTrace("道具:"..nPropID.." 未定义使用函数")
	end
	self:SubItem(gtObjType.eProp, nPropID, 1, gtReason.eUseProp)
end

--出售
function CBagModule:SellProp(nGridID, nSellNum)
	if nSellNum <= 0 then
		return
	end
	local oItem = self:GetBagItem(nGridID)
	if not oItem then
		return 
	end
	local nObjType, nConfID, nCount = oItem:GetObjType(), oItem:GetConfID(), oItem:GetCount()
	if nObjType ~= gtObjType.eProp or nCount <= 0 then
		return
	end
	nSellNum = math.min(nSellNum, nCount)
	self:SubItem(nObjType, nConfID, nSellNum, gtReason.eSellProp)

	local tPropConf = ctPropConf[oItem:GetConfID()]
	for _, tItem in ipairs(tPropConf.tSell) do
		local nType , nID, nNum = table.unpack(tItem)
		if nType > 0 and nID > 0 and nNum > 0 then
			self.m_oPlayer:AddItem(nType, nID, nNum*nSellNum, gtReason.eSellProp)
		end
	end
end

--购买容量
function CBagModule:BuyGridReq()
	local tConf = ctBagConf[1]
	local nCostMoney = tConf.nGridBuy * tConf.nGridPrice
	if self.m_oPlayer:GetMoney() < nCostMoney then
		return self.m_oPlayer:ScrollMsg(ctLang[4])
	end
	if self.m_nOpenGrid >= tConf.nMaxGrid then
		return self.m_oPlayer:ScrollMsg(ctLang[5])
	end
	self.m_oPlayer:SubMoney(nCostMoney, gtReason.eBuyBagCap)
	self.m_nOpenGrid = math.min(self.m_nOpenGrid + tConf.nGridBuy, tConf.nMaxGrid)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "BuyBagGridRet", {nOpenGrid=self.m_nOpenGrid})
end
