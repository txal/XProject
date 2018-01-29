--选秀掉落管理器

CXDropMgr = class()
function CXDropMgr:Ctor()
	self.m_tFirstItem = {} 		--首次抽奖

	self.m_tTiLiItem = {} 		--体力抽奖
	self.m_nTotalTiLiW = 0 		--体力总权重

	self.m_tYuanBaoItem = {} 	--元宝抽奖
	self.m_nTotalYuanBaoW = 0 	--元宝总权重

	self.m_tTiLiRareItem = {} 	--体力珍稀库
	self.m_nTiLiTotalRareW = 0 	--体力珍稀库总权重

	self.m_tYuanBaoRareItem = {} 	--体力珍稀库
	self.m_nYuanBaoTotalRareW = 0 	--体力珍稀库总权重

	self.m_nBaoDiTotalW = 0 		--保底库总权重
	self.m_tBaoDiItem = {} 			--保底库

	self:LoadDropConf()
end

--检测道具是否存在
function CXDropMgr:CheckProp(nType, nID)
	if nType <= 0 or nID <= 0 then
		return 
	end
	if nType == gtItemType.eProp then
		assert(ctPropConf[nID], "道具表不存:"..nID)
	else
		assert(false, "不支持物品类型:"..nType)
	end
end

--加载选秀妃子配置
function CXDropMgr:LoadDropConf()
	local nPreW1, nPreW2, nPreR1, nPreR2, nPreBD = 0, 0, 0, 0, 0
	for nIndex, tConf in pairs(ctSSDCJConf) do
		self:CheckProp(tConf.nType, tConf.nID)
		if tConf.nKind == 0 then
			self.m_tFirstItem = tConf

		elseif tConf.nKind == 1 then
			tConf.nMinW = nPreW1 + 1
			tConf.nMaxW = tConf.nMinW + tConf.nWeight - 1
			self.m_nTotalTiLiW = self.m_nTotalTiLiW + tConf.nWeight
			nPreW1 = tConf.nMaxW
			table.insert(self.m_tTiLiItem, tConf)

		elseif tConf.nKind == 2 then
			tConf.nMinW = nPreW2 + 1
			tConf.nMaxW = tConf.nMinW + tConf.nWeight - 1
			self.m_nTotalYuanBaoW = self.m_nTotalYuanBaoW + tConf.nWeight
			nPreW2 = tConf.nMaxW
			table.insert(self.m_tYuanBaoItem, tConf)

		end
		if tConf.bZhenXi then
			if tConf.nKind == 1 then
				tConf.nMinRW = nPreR1 + 1
				tConf.nMaxRW = tConf.nMinRW + tConf.nWeight - 1
				self.m_nTiLiTotalRareW = self.m_nTiLiTotalRareW + tConf.nWeight
				nPreR1 = tConf.nMaxRW
				table.insert(self.m_tTiLiRareItem, tConf)

			elseif tConf.nKind == 2 then
				tConf.nMinRW = nPreR2 + 1
				tConf.nMaxRW = tConf.nMinRW + tConf.nWeight - 1
				self.m_nYuanBaoTotalRareW = self.m_nYuanBaoTotalRareW + tConf.nWeight
				nPreR2 = tConf.nMaxRW
				table.insert(self.m_tYuanBaoRareItem, tConf)
				
			end

		end
		if tConf.bBaoDi then
			tConf.nMinBDW = nPreBD + 1
			tConf.nMaxBDW  = tConf.nMinBDW + tConf.nWeight - 1
			self.m_nBaoDiTotalW = self.m_nBaoDiTotalW + tConf.nWeight
			nPreBD = tConf.nMaxBDW
			table.insert(self.m_tBaoDiItem, tConf)
		end
	end
end

--随机1个物品(0首次/1体力/2元宝/3体力珍稀/4元宝珍稀/5保底)
function CXDropMgr:GetItem(nKind)
	if nKind == 0 then
		local tConf = self.m_tFirstItem
		return {tConf.nType, tConf.nID, tConf.nNum}, tConf

	elseif nKind == 1 then
		local nRnd = math.random(1, self.m_nTotalTiLiW)
		for _, tConf in pairs(self.m_tTiLiItem) do
			if nRnd >= tConf.nMinW and nRnd <= tConf.nMaxW then
				return {tConf.nType, tConf.nID, tConf.nNum}, tConf
			end
		end

	elseif nKind == 2 then
		local nRnd = math.random(1, self.m_nTotalYuanBaoW)
		for _, tConf in pairs(self.m_tYuanBaoItem) do
			if nRnd >= tConf.nMinW and nRnd <= tConf.nMaxW then
				return {tConf.nType, tConf.nID, tConf.nNum}, tConf
			end
		end

	elseif nKind == 3 then
		local nRnd = math.random(1, self.m_nTiLiTotalRareW)
		for _, tConf in pairs(self.m_tTiLiRareItem) do
			if nRnd >= tConf.nMinRW and nRnd <= tConf.nMaxRW then
				return {tConf.nType, tConf.nID, tConf.nNum}, tConf
			end
		end

	elseif nKind == 4 then
		local nRnd = math.random(1, self.m_nYuanBaoTotalRareW)
		for _, tConf in pairs(self.m_tYuanBaoRareItem) do
			if nRnd >= tConf.nMinRW and nRnd <= tConf.nMaxRW then
				return {tConf.nType, tConf.nID, tConf.nNum}, tConf
			end
		end

	elseif nKind == 5 then
		local nRnd = math.random(1, self.m_nBaoDiTotalW)
		for _, tConf in pairs(self.m_tBaoDiItem) do
			if nRnd >= tConf.nMinBDW and nRnd <= tConf.nMaxBDW then
				return {tConf.nType, tConf.nID, tConf.nNum}, tConf
			end
		end

	else
		assert(false, "不支持KIND类型:", nKind)
	end
end

goCXDropMgr = CXDropMgr:new()
