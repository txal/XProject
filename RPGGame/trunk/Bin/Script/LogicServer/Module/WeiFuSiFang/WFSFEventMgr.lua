--微服私访事件处理

--微服私访建筑预处理
local _WFSFBuildEventsConf = {}                             
local function PreProcessBuildsConf()
	for _, tConf in pairs(ctWFSFBuildEventConf) do
		_WFSFBuildEventsConf[tConf.nBuildID] = _WFSFBuildEventsConf[tConf.nBuildID] or {}
		table.insert(_WFSFBuildEventsConf[tConf.nBuildID], tConf)
	end
end
PreProcessBuildsConf()

WFSFEventMgr = class()
function WFSFEventMgr:Ctor()
	self.m_tBuildTotalW = {} 		--建筑总权重
	self.m_nBlankTotalW = 0 		--空格总权重

	--名士奖励
	self.m_tAward1 = {}
	self.m_tAward2 = {}
	self.m_tAwardTotalW1 = {} 		--名士奖励总权重1
	self.m_tAwardTotalW2 = {} 		--名士奖励总权重2

	self.m_tBlankAwardTotalW = {} 	--空格事件奖励权重

	self:LoadDropConf()
end

-- 检测建筑物是否存在
function WFSFEventMgr:CheckBuild(nID)
	if nID <= 0 then
		return 
	end
	assert(ctWFSFBuildConf[nID], "建筑物表不存:"..nID)
end

--加载微服私访事件配置
function WFSFEventMgr:LoadDropConf()
	for nBuildID, tConf in ipairs(_WFSFBuildEventsConf) do 
		self:CheckBuild(nBuildID)
		local nPreW = 0
		for _, tBuild in ipairs(tConf) do 
			tBuild.nMinW = nPreW + 1 
			tBuild.nMaxW = tBuild.nMinW + tBuild.nWeight - 1
			self.m_tBuildTotalW[nBuildID] = (self.m_tBuildTotalW[nBuildID] or 0) + tBuild.nWeight
			nPreW = tBuild.nMaxW

			--妃子事件
			if tBuild.nType == 1 then
				self.m_tAward1[tBuild.nID] = self.m_tAward1[tBuild.nID] or {}
				self.m_tAward2[tBuild.nID] = self.m_tAward2[tBuild.nID] or {}
				self.m_tAward1[tBuild.nID][1] = tBuild.tAward1[1]
				self.m_tAward2[tBuild.nID][1] = tBuild.tAward2[1]
			
			--名士事件
			elseif tBuild.nType == 2 then
				local nPreW1, nPreW2 = 0, 0
				for _, tAward in ipairs(tBuild.tAward1) do 
					tAward.nMinW = nPreW1 + 1
					tAward.nMaxW = tAward.nMinW + tAward[1] - 1
					self.m_tAwardTotalW1[tBuild.nID] = (self.m_tAwardTotalW1[tBuild.nID] or 0) + tAward[1]
					nPreW1 = tAward.nMaxW
					self.m_tAward1[tBuild.nID] = self.m_tAward1[tBuild.nID] or {}
					table.insert(self.m_tAward1[tBuild.nID], tAward)
				end
				for _, tAward in ipairs(tBuild.tAward2) do 
					tAward.nMinW = nPreW2 + 1
					tAward.nMaxW = tAward.nMinW + tAward[1] - 1
					self.m_tAwardTotalW2[tBuild.nID] = (self.m_tAwardTotalW2[tBuild.nID] or 0) + tAward[1]
					nPreW2 = tAward.nMaxW
					self.m_tAward2[tBuild.nID] = self.m_tAward2[tBuild.nID] or {}
					table.insert(self.m_tAward2[tBuild.nID], tAward)
				end
			end
		end  
	end

	local nPreW1 = 0
	for _, tConf in pairs(ctWFSFBlankEventConf) do 
		tConf.nMinW = nPreW1 + 1
		tConf.nMaxW = tConf.nMinW + tConf.nWeight - 1
		self.m_nBlankTotalW = self.m_nBlankTotalW + tConf.nWeight
		nPreW1 = tConf.nMaxW

		if tConf.nType == 6 or tConf.nType == 7 then --时装碎片和商城物品
			local nPreW = 0
			for _, tAward in ipairs(tConf.tProp) do
				tAward.nMinW = nPreW + 1 
				tAward.nMaxW = tAward.nMinW + tAward[1] - 1 
				self.m_tBlankAwardTotalW[tConf.nID] = (self.m_tBlankAwardTotalW[tConf.nID] or 0) + tAward[1]
				nPreW = tAward.nMaxW
			end 
		end
	end
end

--根据繁荣度重新计算建筑权重
function WFSFEventMgr:RecalcBuildWeight(tBuildList, nFR)
	local nPreW = 0
	self.m_tBuildTotalW = {}
	for _, tBuild in ipairs(tBuildList) do 
		if nFR >= tBuild.nFlourish then
			tBuild.nMinW = nPreW + 1 
			tBuild.nMaxW = tBuild.nMinW + tBuild.nWeight - 1
			self.m_tBuildTotalW[tBuild.nBuildID] = (self.m_tBuildTotalW[tBuild.nBuildID] or 0) + tBuild.nWeight
			nPreW = tBuild.nMaxW
		end
	end
end

--根据繁荣度重新计算空格权重
function WFSFEventMgr:RecalcBlankWeight(nFR)
	local nPreW = 0
	self.m_nBlankTotalW = 0
	for _, tConf in pairs(ctWFSFBlankEventConf) do 
		if nFR >= tConf.nFlourish then
			tConf.nMinW = nPreW + 1 
			tConf.nMaxW = tConf.nMinW + tConf.nWeight - 1
			self.m_nBlankTotalW = self.m_nBlankTotalW + tConf.nWeight
			nPreW = tConf.nMaxW
		end
	end
end

--取随机事件
function WFSFEventMgr:GetEvent(nBuildID, nFR)
	print("随机事件传参", nBuildID, nFR)

	nBuildID = nBuildID or 0
	--建筑事件
	if nBuildID > 0 then
		local tBuildList = _WFSFBuildEventsConf[nBuildID]
		self:RecalcBuildWeight(tBuildList, nFR)

		if not self.m_tBuildTotalW[nBuildID] then --没有激活的NPC
			print("建筑事件", nil)
			return
		end

		local nRnd = math.random(1, self.m_tBuildTotalW[nBuildID])
		for _, tConf in ipairs(tBuildList) do 
			if nFR >= tConf.nFlourish then
				if nRnd >= tConf.nMinW and nRnd <= tConf.nMaxW then
					print("建筑事件", tConf)
					return tConf
				end
			end
		end

	--空格事件
	else
		self:RecalcBlankWeight(nFR)
		if self.m_nBlankTotalW == 0 then
			print("空格事件", nil)
			return
		end
		local nRnd = math.random(1, self.m_nBlankTotalW)
		for _, tConf in pairs(ctWFSFBlankEventConf) do 
			if nFR >= tConf.nFlourish then
				if nRnd >= tConf.nMinW and nRnd <= tConf.nMaxW then
					print("空格事件", tConf)
					return tConf
				end
			end
		end

	end
end

--随机1个物品(名士奖励:nSelect=1选项1，nSelect==2选项2)
function WFSFEventMgr:GetItem(nBuildID, nEventID, nSelect)
	print("随机物品传参", nBuildID, nEventID, nSelect)

	nBuildID = nBuildID or 0

	--建筑事件
	if nBuildID > 0 then
		assert(nSelect==1 or nSelect==2, "参数错误")
		local tEventConf = ctWFSFBuildEventConf[nEventID]
		if nSelect == 1 then
			--妃子事件
			if tEventConf.nType == 1 then
				return self.m_tAward1[nEventID][1]
			end

			--名士事件	
			local nRnd = math.random(1, self.m_tAwardTotalW1[nEventID])
			for _, tAward in ipairs(self.m_tAward1[nEventID]) do 
				if nRnd >= tAward.nMinW and nRnd <= tAward.nMaxW then 
					return tAward
				end
			end
		else
			--妃子事件
			if tEventConf.nType == 1 then
				return self.m_tAward2[nEventID][1]
			end

			--名士事件	
			local nRnd = math.random(1, self.m_tAwardTotalW2[nEventID])
			for _, tAward in ipairs(self.m_tAward2[nEventID]) do 
				if nRnd >= tAward.nMinW and nRnd <= tAward.nMaxW then 
					return tAward
				end
			end
		end 

	--空格事件
	else
		local tEventConf = ctWFSFBlankEventConf[nEventID]
		--银两,文化,兵力不需要随机
		if tEventConf.nType == 3 or tEventConf.nType == 4 or tEventConf.nType == 5 then
			return tEventConf.tProp[1]
		end

		local nRnd = math.random(1, self.m_tBlankAwardTotalW[nEventID])
		for _, tItem in ipairs(tEventConf.tProp) do 
			if nRnd >= tItem.nMinW and nRnd <= tItem.nMaxW then
				return tItem 
			end
		end
	end
end

--指定建筑已激活NPC列表
function WFSFEventMgr:GetNPCList(nBuildID, nFR)
	local tNPCList = {}
	local tBuildList = _WFSFBuildEventsConf[nBuildID]
	for _, tBuild in ipairs(tBuildList) do
		if nFR >= tBuild.nFlourish then
			table.insert(tNPCList, {nEventID=tBuild.nID, nEventType=tBuild.nType, sNPCID=tBuild.sNPCID})
		end
	end
	return tNPCList
end

goWFSFEventMgr = WFSFEventMgr:new()
