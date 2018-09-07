CDropMgr = class()

function CDropMgr:Ctor()
	self.m_tDispDropConf = {}	--分散式掉落配置
	self.m_tCollDropConf = {}	--集中式掉落配置
	self:LoadDispDropConf()
	self:LoadCollDropConf()
end

--检测道具是否存在
function CDropMgr:CheckProp(nItemType, nItemID)
	if nItemType <= 0 or nItemID <= 0 then
		return 
	end
	if nItemType == gtItemType.eArm then
		assert(ctArmConf[nItemID], "drop.xml: 装备 "..nItemID.." 不存在")

	elseif nItemType == gtItemType.eProp then
		assert(ctPropConf[nItemID], "drop.xml: 道具 "..nItemID.." 不存在")

	elseif nItemType == gtItemType.eWSProp then
		assert(ctWSPropConf[nItemID], "drop.xml: 工坊道具 "..nItemID.." 不存在")

	else
		assert(false, "drop.xml: 不支持物品类型 "..nItemType)
	end
end

--加载分散掉落配置
function CDropMgr:LoadDispDropConf()
	for _, tConf in pairs(ctDispDropConf) do
		self:CheckProp(tConf.nItemType, tConf.nItemID)
		local nDropID = tConf.nDropID
		local nGroupID = tConf.nGroupID
		if not self.m_tDispDropConf[nDropID] then
			self.m_tDispDropConf[nDropID] = {}
		end
		if not self.m_tDispDropConf[nDropID][nGroupID] then
			self.m_tDispDropConf[nDropID][nGroupID] = {}
		end
		local nIndex = #self.m_tDispDropConf[nDropID][nGroupID] + 1
		self.m_tDispDropConf[nDropID][nGroupID][nIndex] = tConf
	end
end

--加载集中掉落配置
function CDropMgr:LoadCollDropConf()
	for nDropID, tConf in pairs(ctCollDropConf) do
		local nPreWeight = 0
		tConf.nTotalWeight = 0
		for _, tItem in ipairs(tConf.tAward or {}) do
			assert(tItem[1] > 0, "不要配置权重为0的物品")
			self:CheckProp(tItem[2], tItem[3])
			tItem.nMinWeight = nPreWeight + 1
			tItem.nMaxWeight = tItem.nMinWeight + tItem[1] - 1
			nPreWeight = tItem.nMaxWeight
			tConf.nTotalWeight = tConf.nTotalWeight + tItem[1]
		end
		self.m_tCollDropConf[nDropID] = tConf
	end
end

--根据掉落ID取掉落组
function CDropMgr:GetDispDropConf(nDropID)
	return self.m_tDispDropConf[nDropID]
end

--根据掉落ID取掉落组
function CDropMgr:GetCollDropConf(nDropID)
	return self.m_tCollDropConf[nDropID]
end

--根据掉落ID得到物品
function CDropMgr:GenDispDropItem(nDropID)
	local tItemList = {}
	if nDropID <= 0 then
		return tItemList
	end
	
	local tDropGroup = assert(self.m_tDispDropConf[nDropID], "早不到Disp掉落组")
	for nGroupID, tConfs in pairs(tDropGroup) do
		if not tConfs.nTotalWeight then
			local nPreWeight = 0
			tConfs.nTotalWeight = 0
			for k, v in ipairs(tConfs) do
				assert(v.nWeight > 0, "不要配置权重为0的物品")
				v.nMinWeight = nPreWeight + 1
				v.nMaxWeight = v.nMinWeight + v.nWeight - 1
				nPreWeight = v.nMaxWeight
				tConfs.nTotalWeight = tConfs.nTotalWeight + v.nWeight
			end
		end
		if tConfs.nTotalWeight > 0 then
			local nRnd = math.random(1, tConfs.nTotalWeight)
			for k, v in ipairs(tConfs) do
				if nRnd >= v.nMinWeight and nRnd <= v.nMaxWeight then
					local nCount = math.random(v.nMinCount, v.nMaxCount)
					if nCount >= 0 then
						table.insert(tItemList, {v.nItemType, v.nItemID, nCount})
					end
					break
				end
			end
		end
	end
	return tItemList
end

--根据掉落ID得到物品
function CDropMgr:GenCollDropItem(nDropID)
	local tItemList = {}
	if nDropID <= 0 then
		return tItemList
	end

	local tDropConf = assert(self.m_tCollDropConf[nDropID], "找不到Coll掉落组")
	if not tDropConf or tDropConf.nTotalWeight <= 0 then
		return tItemList
	end

	--随机一个
	if tDropConf.nType == 1 then
		local nRnd = math.random(1, tDropConf.nTotalWeight)	
		for _, tItem in ipairs(tDropConf.tAward or {}) do
			if nRnd >= tItem.nMinWeight and nRnd <= tItem.nMaxWeight then
				table.insert(tItemList, {tItem[2], tItem[3], tItem[4]})
				break
			end
		end

	--分别随机
	elseif tDropConf.nType == 2 then
		for _, tItem in ipairs(tDropConf.tAward or {}) do
			local nRnd = math.random(1, tDropConf.nTotalWeight)	
			if nRnd >= tItem.nMinWeight and nRnd <= tItem.nMaxWeight then
				table.insert(tItemList, {tItem[2], tItem[3], tItem[4]})
			end
		end
	end
	return tItemList
end

goDropMgr = CDropMgr:new()
