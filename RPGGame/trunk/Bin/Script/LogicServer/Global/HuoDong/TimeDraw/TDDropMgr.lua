--限时选秀掉落管理器

CTDDropMgr = class()
function CTDDropMgr:Ctor()
	self.m_nTotalWeight = 0 	--总权重
	self.m_nTotalRareW = 0 		--珍稀库总权重	
	self.m_nTotalBaoDi = 0 		--保底总权重
	self.m_tRareItem = {}		--珍稀表
	self.m_tBaoDi = {}			--保底奖励
	self:LoadDropConf()
end

--检测道具是否存在
function CTDDropMgr:CheckProp(nType, nID)
	if nType <= 0 then
		return 
	end
	if nType == gtItemType.eProp then
		if nID ~= -1 then 
			assert(ctPropConf[nID], "道具表不存:"..nID)
		end
	elseif nType == gtItemType.eGongNv then
		assert(ctGongNvConf[nID], "宫女表不存在:"..nID)	
	else
		assert(false, "不支持物品类型:"..nType)
	end
end

--加载选秀配置
function CTDDropMgr:LoadDropConf()
	local nPreW, nPreWR, nPreWB = 0, 0, 0
	for nIndex, tConf in pairs(ctTimeDrawDropConf) do 
		self:CheckProp(tConf.nType, tConf.nID)
		tConf.nMinW = nPreW + 1
		tConf.nMaxW = tConf.nMinW + tConf.nWeight - 1
		self.m_nTotalWeight = self.m_nTotalWeight + tConf.nWeight
		nPreW = tConf.nMaxW

		if tConf.bZhenXi then 
			tConf.nMinRW = nPreWR + 1
			tConf.nMaxRW = tConf.nMinRW + tConf.nWeight - 1
			self.m_nTotalRareW = self.m_nTotalRareW + tConf.nWeight
			nPreWR = tConf.nMaxRW
			table.insert(self.m_tRareItem, tConf)
		end

		if tConf.bBaoDi then 
			tConf.nMinBW = nPreWB + 1
			tConf.nMaxBW = tConf.nMinBW + tConf.nWeight - 1
			self.m_nTotalBaoDi = self.m_nTotalBaoDi + tConf.nWeight
			nPreWB = tConf.nMaxBW
			table.insert(self.m_tBaoDi, tConf)
		end
	end
end

--随机物品(1元宝，2珍稀库, 3保底奖励)
function CTDDropMgr:GetItem(nType)
	assert(nType == 1 or nType == 2 or nType==3, "参数有误")
	if nType == 1 then 
		local nRnd = math.random(1, self.m_nTotalWeight)
		for _, tConf in pairs(ctTimeDrawDropConf) do
			if nRnd >= tConf.nMinW and nRnd <= tConf.nMaxW then
				return {tConf.nType, tConf.nID, tConf.nNum}, tConf
			end
		end
	elseif nType == 2 then
		local nRnd = math.random(1, self.m_nTotalRareW)
		for _, tConf in pairs(self.m_tRareItem) do
			if nRnd >= tConf.nMinRW and nRnd <= tConf.nMaxRW then
				return {tConf.nType, tConf.nID, tConf.nNum}, tConf
			end
		end
	else
		local nRnd = math.random(1, self.m_nTotalBaoDi)
		for _, tConf in pairs(self.m_tBaoDi) do 
			if nRnd >= tConf.nMinBW and nRnd <= tConf.nMaxBW then 
				return {tConf.nType, tConf.nID, tConf.nNum}, tConf
			end
		end
	end
end

goTDDropMgr = CTDDropMgr:new()