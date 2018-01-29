CDropMgr = class()

function CDropMgr:Ctor()
	self.m_tDropConf = {}
	self:LoadDropConf()
end

--检测道具是否存在
function CDropMgr:CheckProp(nType, nID)
	if nType <= 0 or nID <= 0 then
		return 
	end
	if nType == gtItemType.eProp then
		assert(ctPropConf[nID], "道具表不存在道具:"..nID)
	else
		assert(false, "不支持物品类型:"..nType)
	end
end

--加载集中掉落配置
function CDropMgr:LoadDropConf()
	for nID, tConf in pairs(ctDropConf) do
		local nPreWeight = 0
		tConf.nTotalWeight = 0
		for _, tItem in ipairs(tConf.tAward or {}) do
			if tItem[1] > 0 then
				self:CheckProp(tItem[2], tItem[3])
				tItem.nMinWeight = nPreWeight + 1
				tItem.nMaxWeight = tItem.nMinWeight + tItem[1] - 1
				tConf.nTotalWeight = tConf.nTotalWeight + tItem[1]
				nPreWeight = tItem.nMaxWeight
			end
		end
		self.m_tDropConf[nID] = tConf
	end
end

--根据掉落ID取掉落组
function CDropMgr:GetDropConf(nDropID)
	return self.m_tDropConf[nDropID]
end

--根据掉落ID得到物品
function CDropMgr:GetDropItem(nDropID)
	local tItemList = {}
	if nDropID <= 0 then
		return tItemList
	end

	local tDropConf = assert(self.m_tDropConf[nDropID], "找不到掉落组")
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
