--请安折掉落管理器

CQAZDropMgr = class()
function CQAZDropMgr:Ctor()
	self.m_tGroupMap = {}   --{[1]={},[2]={},...}爵位奖励表
	self:LoadDropConf()
end

-- 检测道具是否存在
function CQAZDropMgr:CheckProp(nType, nID)
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
function CQAZDropMgr:LoadDropConf()
	for nXID, tConf in pairs(ctQingAnZheGiftConf) do    --遍历献礼表
		self:CheckProp(tConf.nType, tConf.nID)          --检测
		local nJueWei = tConf.nJueWei
		self.m_tGroupMap[nJueWei] = self.m_tGroupMap[nJueWei] or {}
		table.insert(self.m_tGroupMap[nJueWei], tConf)
	end

	for nJueWei, tConfList in pairs(self.m_tGroupMap) do
		local nPreW, nTotalW = 0, 0
		for _, tConf in ipairs(tConfList) do
			tConfList.nTotalW = (tConfList.nTotalW or 0) + tConf.nWeight
			tConf.nMinW = nPreW + 1
			tConf.nMaxW = tConf.nMinW + tConf.nWeight - 1
			nPreW = tConf.nMaxW
		end
	end
end

--随机1个物品  
function CQAZDropMgr:GetItem(nJueWei)
	local tConfList = self.m_tGroupMap[nJueWei]
	if not tConfList then
		LuaTrace("对应爵位奖励不存在:", nJueWei)
		return {0, 0, 0}
	end
	local nRnd = math.random(1, tConfList.nTotalW)
	for _, tConf in ipairs(tConfList) do
		if nRnd >= tConf.nMinW and nRnd <= tConf.nMaxW then
			return {tConf.nType, tConf.nID, tConf.nNum}
		end
	end
end

-- goQAZDropMgr = CQAZDropMgr:new()
