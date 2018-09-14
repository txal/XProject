---背包系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

CKnapsack.nMaxFoldNum = 999 --最大折叠数
function CKnapsack:Ctor(oRole)
	self.m_oRole = oRole
	self:Init()
end

function CKnapsack:GetType()
	return gtModuleDef.tKnapsack.nID, gtModuleDef.tKnapsack.sName
end

function CKnapsack:Init()
	self.m_tGridMap = {} 	--格子到1组道具映射
	self.m_tGroupMap = {} 	--同1道具可能有多组,1组对应1个格子
	self.m_nMaxGrid = 16 	--初始容量
end

function CKnapsack:LoadData(tData)
	if not tData then
		return
	end
	
	self.m_nMaxGrid = tData.m_nMaxGrid
	for _, tItem in pairs(tData.m_tGridMap) do
		if ctPropConf[tItem.m_nSysID] and tItem.m_nGrid then
			local oProp = self:CreateProp(tItem.m_nSysID, tItem.m_nGrid)
			if oProp then
				oProp:LoadData(tItem)
				self.m_tGridMap[tItem.m_nGrid] = oProp;
				self.m_tGroupMap[tItem.m_nSysID] = self.m_tGroupMap[tItem.m_nSysID] or {}
				table.insert(self.m_tGroupMap[tItem.m_nSysID], tItem.m_nGrid)
			end
		end
	end
end

function CKnapsack:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nMaxGrid = self.m_nMaxGrid

	tData.m_tGridMap = {}
	for nGrid, oItem in pairs(self.m_tGridMap) do
		tData.m_tGridMap[nGrid] = oItem:SaveData()
	end
	return tData
end

function CKnapsack:Online()
	self:SyncKnapsackItem()
end

function CKnapsack:CreateProp(nSysID, nGrid)
	local oProp
	local tConf = assert(ctPropConf[nSysID])
	--特殊道具
	if tConf.nType == gtPropType.eTeShu then
		oProp = CPropTS:new(self, nSysID, nGrid)

	--材料道具
	elseif tConf.nType == gtPropType.eCaiLiao then
		oProp = CPropCL:new(self, nSysID, nGrid)

	--宝箱道具
	elseif tConf.nType == gtPropType.eBaoXiang then
		if tConf.nSubType > 0 then
		--属性宝箱
			oProp = CPropAttrBx:new(self, nSysID, nGrid)
		else
		--普通宝箱
			oProp = CPropBX:new(self, nSysID, nGrid)
		end

	--消耗道具
	elseif tConf.nType == gtPropType.eXiaoHao then
		oProp = CPropXH:new(self, nSysID, nGrid)

	else
		self.m_oRole:Tips("道具未实现:"..nSysID)

	end
	return oProp
end

function CKnapsack:AddItem(nSysID, nCount)
	assert(nSysID>0 and nCount>0, "参数非法:"..nSysID..":"..nCount)
	if nCount > CKnapsack.nMaxFoldNum then
		return self.m_oRole:Tips("背包道具1次最多加:"..CKnapsack.nMaxFoldNum)
	end

	local tConf = assert(ctPropConf[nSysID], "道具表不存在道具:"..nSysID)
	assert(tConf.nType ~= gtPropType.eCurr, "货币类道具不能加入背包:"..nSysID)

	if self.m_tGroupMap[nSysID] then
		for _, nGrid in ipairs(self.m_tGroupMap[nSysID]) do
			local oProp = self.m_tGridMap[nGrid]
			if not oProp:IsFull() then
				local nEmpyNum = oProp:EmptyNum()
				local nAddNum = math.min(nEmpyNum, nCount)
				oProp:AddNum(nAddNum)
				nCount = nCount - nAddNum
				self:OnItemModed(nGrid)
			end
			if nCount <= 0 then
				break
			end
		end
	end

	local nGrid = 1
	while nCount > 0 and nGrid <= self.m_nMaxGrid do
		if not self.m_tGridMap[nGrid] then
			local oProp = self:CreateProp(nSysID, nGrid)
			if oProp then
				local nSetNum = math.min(nCount, CKnapsack.nMaxFoldNum)
				oProp:SetNum(nSetNum)
				self.m_tGridMap[nGrid] = oProp
				self.m_tGroupMap[nSysID] = self.m_tGroupMap[nSysID] or {}
				table.insert(self.m_tGroupMap[nSysID], nGrid)
				nCount = nCount - nSetNum
				self:OnItemAdded(nGrid)
			else
				break
			end
		end
		nGrid = nGrid + 1
		if nCount > 0 and nGrid > self.m_nMaxGrid then
			self.m_nMaxGrid = self.m_nMaxGrid + 1
		end
	end
	self:MarkDirty(true)
	return self:ItemCount(nSysID)
end

--取物品个数
function CKnapsack:ItemCount(nSysID)
	if not self.m_tGroupMap[nSysID] then
		return 0
	end
	local nCount = 0
	for _, nGrid in ipairs(self.m_tGroupMap[nSysID]) do
		local oProp = self.m_tGridMap[nGrid]
		nCount = nCount + oProp:GetNum()
	end
	return nCount
end

--扣除物品
function CKnapsack:SubItem(nSysID, nNum)
	assert(nNum >= 0)
	if nNum == 0 then
		return
	end

	local tGroup = self.m_tGroupMap[nSysID]
	if not tGroup then
		return
	end

	local tGroupDel = {}
	for _, nGrid in ipairs(tGroup) do
		local oProp = self.m_tGridMap[nGrid]
		local nPropNum = oProp:GetNum()
		local nSubNum = math.min(nPropNum, nNum)
		oProp:SubNum(nSubNum)
		nNum = nNum - nSubNum
		if oProp:GetNum() <= 0 then
			tGroupDel[nGrid] = nGrid
			self.m_tGridMap[nGrid] = nil
			self:OnItemRemoved(nGrid)
		else
			self:OnItemModed(nGrid)
		end
		if nNum <= 0 then
			break
		end
	end

	if next(tGroupDel) then
		local tGroupNew = {}
		for _, nGrid in ipairs(tGroup) do
			if not tGroupDel[nGrid] then
				table.insert(tGroupNew, nGrid)
			end
		end
		self.m_tGroupMap[nSysID] = tGroupNew
	end
	self:MarkDirty(true)

	return self:ItemCount(nSysID)
end

--扣除指定格子物品
function CKnapsack:SubGridItem(nSysID, nGrid, nNum, sReason)
	assert(sReason, "请说明原因")
	assert(nNum >0)
	if nNum == 0 then
		return
	end

	local tGroup = self.m_tGroupMap[nSysID]
	if not tGroup or #tGroup == 0 then
		return
	end

	for nIndex, nTmpGrid in ipairs(tGroup) do
		if nTmpGrid == nGrid then
			local oProp = self.m_tGridMap[nGrid]
			local nPropNum = oProp:GetNum()
			local nSubNum = math.min(nPropNum, nNum)
			oProp:SubNum(nSubNum)
			if oProp:GetNum() <= 0 then
				self.m_tGridMap[nGrid] = nil
				table.remove(tGroup, nIndex)
				self:OnItemRemoved(nGrid)
			else
				self:OnItemModed(nGrid)
			end
		end
	end
	self:MarkDirty(true)
	goLogger:AwardLog(gtEvent.eSubItem, sReason, self.m_oRole, gtItemType.eProp, nSysID, nNum, true) 
	return true
end

--物品添加成功
function CKnapsack:OnItemAdded(nGrid)
	local oProp = self:GetItem(nGrid)
	local tInfo = oProp:GetInfo()
    CmdNet.PBSrv2Clt("KnapsackItemAddRet", self.m_oRole:GetServer(), self.m_oRole:GetSession(), {tItemList={tInfo}})
end

--物品删除成功
function CKnapsack:OnItemRemoved(nGrid)
    CmdNet.PBSrv2Clt("KnapsackItemRemoveRet", self.m_oRole:GetServer(), self.m_oRole:GetSession(), {tGrid={nGrid}})
end

--物品数量变更
function CKnapsack:OnItemModed(nGrid)
	local oProp = self:GetItem(nGrid)
	local tInfo = oProp:GetInfo()
    CmdNet.PBSrv2Clt("KnapsackItemModRet", self.m_oRole:GetServer(), self.m_oRole:GetSession(), {tItemList={tInfo}})
end

--取背包物品
function CKnapsack:GetItem(nGridID)
	return self.m_tGridMap[nGridID]
end

--同步背包道具列表
function CKnapsack:SyncKnapsackItem()
	local tItemList = {}
	for nGrid, oProp in pairs(self.m_tGridMap) do
		table.insert(tItemList, oProp:GetInfo())
	end
    CmdNet.PBSrv2Clt("KnapsackItemListRet", self.m_oRole:GetServer(), self.m_oRole:GetSession(), {tItemList=tItemList})
end

--出售道具
function CKnapsack:SellItemReq(nGrid, nNum)
	local oProp = self:GetItem(nGrid)
	if not oProp then
		return self.m_oRole:Tips("道具不存在")
	end
	if not oProp.Sell then
		return self.m_oRole:Tips("道具不可出售")
	end
	if oProp:Sell(nNum) then
		return self.m_oRole:Tips("出售道具成功")
	end
end

--使用道具
function CKnapsack:UseItemReq(nGrid, nNum)
	assert(nNum > 0)
	local oProp = self:GetItem(nGrid)
	if not oProp then
		return self.m_oRole:Tips("道具不存在")
	end
	if not oProp.Use then
		return self.m_oRole:Tips("该道具不可使用")
	end
	oProp:Use(nNum)
end

--取道具名字
function CKnapsack:PropName(nID)
	local tConf = ctPropConf[nID]
	if not tConf then
		return ""
	end
	return tConf.sName
end

--取战斗道具 fix pd
function CKnapsack:GetBattlePropMap()
	local tPropMap = {}
	return tPropMap
end

--GM清空背包
function CKnapsack:GMClrKnapsack()
	self:Init()
	self:MarkDirty(true)
	self:SyncKnapsackItem()
	self.m_oRole:Tips("清空背包成功")
end

