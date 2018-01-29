---国库系统---
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

CGuoKu.nMaxFoldNum = 999 --最大折叠数

function CGuoKu:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self:Init()
end

function CGuoKu:GetType()
	return gtModuleDef.tGuoKu.nID, gtModuleDef.tGuoKu.sName
end

function CGuoKu:Init()
	self.m_tGridMap = {} 	--格子到1组道具映射
	self.m_tGroupMap = {} 	--同1道具可能有多组,1组对应1个格子
	self.m_nMaxGrid = 16 	--初始容量
end

function CGuoKu:LoadData(tData)
	if tData then
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
end

function CGuoKu:SaveData()
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

function CGuoKu:Online()
	self:SyncGuoKuItem()
end

function CGuoKu:CreateProp(nSysID, nGrid)
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
		--随机属性宝箱
			oProp = CPropAttrBx:new(self, nSysID, nGrid)
		else
		--普通宝箱
			oProp = CPropBX:new(self, nSysID, nGrid)
		end

	--消耗道具
	elseif tConf.nType == gtPropType.eXiaoHao then
		oProp = CPropXH:new(self, nSysID, nGrid)

	else
		self.m_oPlayer:Tips("道具未实现:"..nSysID)
		--assert(false, "不支持道具类型:"..tConf.nType)
	end
	return oProp
end

function CGuoKu:AddItem(nSysID, nCount)
	-- print("CGuoKu:AddItem***", nSysID, nCount)
	assert(nSysID>0 and nCount>0, "参数非法:"..nSysID..":"..nCount)
	if nCount > CGuoKu.nMaxFoldNum then
		return self.m_oPlayer:Tips("国库道具1次最多加:"..CGuoKu.nMaxFoldNum)
	end
	local tConf = assert(ctPropConf[nSysID], "道具表不存在道具:"..nSysID)
	assert(tConf.nType ~= gtPropType.eCurr, "货币类道具不能加入国库:"..nSysID)
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
			if nCount <= 0 then break end
		end
	end
	local nGrid = 1
	while nCount > 0 and nGrid <= self.m_nMaxGrid do
		if not self.m_tGridMap[nGrid] then
			local oProp = self:CreateProp(nSysID, nGrid)
			if oProp then
				local nSetNum = math.min(nCount, CGuoKu.nMaxFoldNum)
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
	return self:GetItemCount(nSysID)
end

--取物品个数
function CGuoKu:GetItemCount(nSysID)
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
function CGuoKu:SubItem(nSysID, nNum)
	nNum = math.abs(nNum)
	if nNum == 0 then return end
	local tGroup = self.m_tGroupMap[nSysID]
	if not tGroup then return end

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
	return self:GetItemCount(nSysID)
end

--扣除指定格子物品
function CGuoKu:SubGridItem(nSysID, nGrid, nNum, sReason)
	assert(sReason, "请说明原因")
	nNum = math.abs(nNum)
	if nNum == 0 then return end
	local tGroup = self.m_tGroupMap[nSysID]
	if not tGroup or #tGroup == 0 then return end

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
	goLogger:AwardLog(gtEvent.eSubItem, sReason, self.m_oPlayer, gtItemType.eProp, nSysID, nNum, true) 
	return true
end

--物品添加成功
function CGuoKu:OnItemAdded(nGrid)
	local oProp = self:GetItem(nGrid)
	local tInfo = oProp:GetInfo()
    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "GuoKuItemAddRet", {tItemList={tInfo}})
end

--物品删除成功
function CGuoKu:OnItemRemoved(nGrid)
    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "GuoKuItemRemoveRet", {tGrid={nGrid}})
end

--物品数量变更
function CGuoKu:OnItemModed(nGrid)
	local oProp = self:GetItem(nGrid)
	local tInfo = oProp:GetInfo()
    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "GuoKuItemModRet", {tItemList={tInfo}})
end

--取背包物品
function CGuoKu:GetItem(nGridID)
	return self.m_tGridMap[nGridID]
end

--同步国库道具列表
function CGuoKu:SyncGuoKuItem()
	local tItemList = {}
	for nGrid, oProp in pairs(self.m_tGridMap) do
		table.insert(tItemList, oProp:GetInfo())
	end
    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "GuoKuItemListRet", {tItemList=tItemList})
end

--出售道具
function CGuoKu:SellItemReq(nGrid, nNum)
	local oProp = self:GetItem(nGrid)
	if not oProp then
		return self.m_oPlayer:Tips("道具不存在")
	end
	if not oProp.Sell then
		return self.m_oPlayer:Tips("道具不可出售")
	end
	if oProp:Sell(nNum) then
		return self.m_oPlayer:Tips("出售道具成功")
	end
end

--使用道具
function CGuoKu:UseItemReq(nGrid, nNum)
	assert(nNum > 0)
	local oProp = self:GetItem(nGrid)
	if not oProp then
		return self.m_oPlayer:Tips("道具不存在")
	end
	if not oProp.Use then
		return self.m_oPlayer:Tips("该道具不可使用")
	end
	local tConf = oProp:GetConf()
	if tConf.nType == gtPropType.eXiaoHao then
	--消耗类特殊处理
		if self.m_oPlayer:GetItemCount(gtItemType.eProp, tConf.nID) < nNum then
			return self.m_oPlayer:Tips("道具数量不足")
		end

		local tAwardMap
		repeat 
			local tGroup = self.m_tGroupMap[tConf.nID]
			local nGrid = tGroup[1]
			if not nGrid then break end
			local oProp = self.m_tGridMap[nGrid]
			local nUseNum = math.min(oProp:GetNum(), nNum)
			tAwardMap = oProp:UseRaw(nUseNum, tAwardMap)
			nNum = nNum - nUseNum
			if nNum <= 0 then
				break
			end
		until (false)

		local tAwardList = {}
		for _, tItem in pairs(tAwardMap) do
			self.m_oPlayer:AddItem(tItem.nType, tItem.nID, tItem.nNum, "使用道具")
			table.insert(tAwardList, tItem)
		end
		CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "GuoKuUseItemRet", {nPropID=tConf.nID, nPropNum=nNum, tAwardList=tAwardList})

	else

		oProp:Use(nNum)
	end
end

--取道具名字
function CGuoKu:PropName(nID)
	local tConf = ctPropConf[nID]
	if not tConf then
		return "null"
	end
	return tConf.sName
end

--合成道具
function CGuoKu:ComposeItemReq(nID)
	local tConf = assert(ctComposeConf[nID], "合成道具不存在")
	local tCaiLiao = tConf.tCaiLiao
	for _, tItem in ipairs(tCaiLiao) do
		if tItem[1] > 0 then
			if self.m_oPlayer:GetItemCount(tItem[1], tItem[2]) < tItem[3] then
				return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(tItem[2])))
			end
		end
	end
	local sName = CGuoKu:PropName(nID) .. "合成"
	for _, tItem in ipairs(tCaiLiao) do
		self.m_oPlayer:SubItem(tItem[1], tItem[2], tItem[3], sName)
	end
	self.m_oPlayer:AddItem(gtItemType.eProp, tConf.nID, tConf.nNum, sName)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "GuoKuComposeRet", {nType=gtItemType.eProp, nID=tConf.nID, nNum=tConf.nNum})
end

--取知己珍宝道具列表
function CGuoKu:GetMCPropMap(nSubType)
	local tPropMap = {}
	for nGrid, oProp in pairs(self.m_tGridMap) do
		local nID = oProp:GetSysID()
		local tConf = oProp:GetConf()
		if tConf.nDetType == gtDetType.eMCZhenBao and tConf.nSubType == nSubType then
			tPropMap[nID] = (tPropMap[nID] or 0) + oProp:GetNum()
		end
	end
	return tPropMap
end

--取知己送礼具列表
function CGuoKu:GetFZPropMap()
	local tPropMap = {}
	for nGrid, oProp in pairs(self.m_tGridMap) do
		local nID = oProp:GetSysID()
		local tConf = oProp:GetConf()
		if tConf.nDetType == gtDetType.eFZZhenBao then
			tPropMap[nID] = (tPropMap[nID] or 0) + oProp:GetNum()
		end
	end
	return tPropMap
end

--GM清空国库
function CGuoKu:GMClrGuoKu()
	self:Init()
	self:MarkDirty(true)
	self.m_oPlayer:Tips("清空国库成功")
	self:SyncGuoKuItem()
end
