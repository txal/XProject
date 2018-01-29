--微服私访掉落管理器

WFSFDropMgr = class()
function WFSFDropMgr:Ctor()
	self.m_tRareList = {}                
	self.m_nTotalW = 0
	self.m_nFirstDraw = {}
	self:LoadDropConf()
end

-- 检测道具是否存在
function WFSFDropMgr:CheckProp(nType, nID)
	if nType <= 0 or nID <= 0 then
		return 
	end
	if nType == gtItemType.eProp then
		assert(ctPropConf[nID], "道具表不存:"..nID)
	else
		assert(false, "不支持物品类型:"..nType)
	end
end

--加载请安折配置
function WFSFDropMgr:LoadDropConf()
	local nPreW = 0
	for nIndex, tConf in ipairs(ctWFSFRareConf) do 
		self:CheckProp(tConf.nType, tConf.nID)
		if tConf.nKind == 0 then 
			self.m_nFirstDraw = tConf
		else
			tConf.nMinW = nPreW + 1
			tConf.nMaxW = tConf.nMinW + tConf.nWeight - 1
			self.m_nTotalW = self.m_nTotalW + tConf.nWeight
			nPreW = tConf.nMaxW
			table.insert(self.m_tRareList, tConf)
		end
	end
end

--随机1个物品
function WFSFDropMgr:GetItem(nKind)
	if nKind == 0 then 
		local tConf = self.m_nFirstDraw
		return {tConf.nType, tConf.nID, tConf.nNum}
	else
		local nRnd = math.random(1, self.m_nTotalW)
		for _, tConf in ipairs(self.m_tRareList) do 
			if nRnd >= tConf.nMinW and nRnd <= tConf.nMaxW then
				return {tConf.nType, tConf.nID, tConf.nNum}
			end
		end
	end
end
goWFSFDropMgr = WFSFDropMgr:new()
