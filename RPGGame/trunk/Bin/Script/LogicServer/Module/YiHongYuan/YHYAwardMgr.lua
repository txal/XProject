--怡红院奖励配置库

CYHYAwardMgr = class()
function CYHYAwardMgr:Ctor()
	self.m_nTotalW = 0  
	self:LoadDropConf()
end

-- 检测道具是否存在
function CYHYAwardMgr:CheckProp(nType, nID)
	if nType <= 0 or nID <= 0 then
		return 
	end
	if nType == gtItemType.eProp then
		assert(ctPropConf[nID], "道具表不存:"..nID)
	elseif nType == gtItemType.eGongNv then
		assert(ctGongNvConf[nID], "宫女表不存在:"..nID)	
	else
		assert(false, "不支持物品类型:"..nType)
	end
end

--加载怡红院奖励配置
function CYHYAwardMgr:LoadDropConf()
	do return end --已取消

	local nPreW = 0
	for nIndex, tConf in ipairs(ctYHYAwardConf) do 
		self:CheckProp(tConf.nType, tConf.nID)
		tConf.nMinW = nPreW + 1
		tConf.nMaxW = tConf.nMinW + tConf.nWeight - 1
		self.m_nTotalW = self.m_nTotalW + tConf.nWeight
		nPreW = tConf.nMaxW
	end
end

--随机1个物品
function CYHYAwardMgr:GetItem()
	local nRnd = math.random(1, self.m_nTotalW)
	for nIndex, tConf in ipairs(ctYHYAwardConf) do 
		if nRnd >= tConf.nMinW and nRnd <= tConf.nMaxW then
			return {tConf.nType, tConf.nID, tConf.nNum, tConf.nIndex}
		end
	end
end
goYHYAwardMgr = CYHYAwardMgr:new()