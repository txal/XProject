--礼包道具
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropGift:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
end

function CPropGift:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropGift:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

function CPropGift:GetGiftConf()
	return assert(ctGiftConf[self:GetID()], "礼包配置不存在:"..self:GetID())
end

--是否需要消耗
function CPropGift:ValidResume()
	if self:GetID() == gnUnionGiftBoxPropID then
		return true
	end
	return false
end

--计算开礼包需要的格子数
function CPropGift:CalcReqGrids(nNum)
	-- ceil(道具使用个数*a/b)+使用之后获得道具类型数-1
	-- a=礼包奖励中堆叠数量最小道具的获得个数（如：获得3个A，5个B，7个C，若B道具的堆叠个数最小，则a=5）
	-- b=礼包奖励中堆叠数量最小道具的堆叠数

	local oRole = self.m_oModule.m_oRole
	--计算最小堆叠数和获得道具个数
	local nPropType = 0
	local nMinFoldNum, nMinFoldAward = 0, 0
	local tGiftConf = self:GetGiftConf()
	for _, tItem in ipairs(tGiftConf.tDrop) do
		if tItem[1] == 0 or oRole:GetConfID() == tItem[1] then
			if CKnapsack:IsOccupyBagGrid(tItem[3], tItem[4]) then
				nPropType = nPropType + 1
				local tConf = ctPropConf[tItem[4]]
				if nMinFoldNum == 0 or tConf.nFold < nMinFoldNum then
					nMinFoldNum = tConf.nFold
					nMinFoldAward = tItem[5]
				end
			end
		end
	end
	if nPropType == 0 or nMinFoldNum == 0 then
		return 1
	end

	local nGrids = 1
	if tGiftConf.nType == 1 then --随机1个
		nGrids = math.ceil(nNum*nMinFoldAward/nMinFoldNum)

	elseif tGiftConf.nType == 2 then --每个随机
		nGrids = math.ceil(nNum*nMinFoldAward/nMinFoldNum)+nPropType-1

	end
	return nGrids
end

--使用道具
function CPropGift:Use(nNum)
	nNum = nNum or 1
	nNum = math.min(math.min(math.max(nNum, 1), 99), self:GetNum()) --单次限定99个
	if nNum <= 0 then 
		return false 
	end
	local oRole = self.m_oModule.m_oRole
	if self:GetNum() < nNum then 
		oRole:Tips("道具数量不足")
		return false
	end

	local nReqGrids = self:CalcReqGrids(nNum)
	if self.m_oModule:GetFreeGridCount() < nReqGrids then
		oRole:Tips(string.format("开启需要%d个背包格", nReqGrids))
		return false
	end

	if self:ValidResume() then 
		-- if not self:CheckCanUse(true) then 
		-- 	return 
		-- end
		self:UseResume(nNum)
		return --帮派礼盒因为异步,假定都失败
	else
		return self:TrueUse(nNum)
		-- for k = 1, nNum do 
		-- 	if not self:TrueUse() then 
		-- 		return
		-- 	end
		-- end
	end
end

function CPropGift:UseResume(nNum)
	if self:GetID() ~= gnUnionGiftBoxPropID then
		return
	end
	local fnCallback = function (bSucc)
		local oRole = self.m_oModule.m_oRole
		if not bSucc then
			oRole:Tips("帮贡不足,无法使用")
			return
		end
		self:TrueUse(nNum)
	end
	local oRole = self.m_oModule.m_oRole
	local nServerID = oRole:GetServer()
	local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
	local nContri = (ctUnionEtcConf[1].nOpenBoxContri or 0) * nNum
	Network:RMCall("SubUnionContri",fnCallback,nServerID,nServiceID,0,oRole:GetID(),nContri,"开启帮派礼盒")
end

--请注意，存在掉落就开启投放奖励的礼包，背包模块有使用到此接口(奖励找回也调用到数据接口请勿随意改动)
function CPropGift:Open(nNum, bReturn, bNotSync)
	local oRole = self.m_oModule.m_oRole
	local tGiftConf = self:GetGiftConf()
	local bBind = self:IsBind()

	local tItemMap = {}	

	for k = 1, nNum do
		if tGiftConf.nType == 1 then --随机一个
			local tItemList = CWeightRandom:Random(tGiftConf.tDrop, function(tItem)
					if tItem[1] == 0 or tItem[1] == oRole:GetConfID() then
						return tItem[2]
					else
						return 0
					end
				end, 1)

			for _, tItem in ipairs(tItemList) do
				local tPropExt = nil
				if tItem[6] > 0 then 
					tPropExt = {nQuality=tItem[6]}
				end
				local sKey = string.format("%d-%d-%d", tItem[3], tItem[4], tItem[6])
				if not tItemMap[sKey] then
					tItemMap[sKey] = {nType=tItem[3], nID=tItem[4], nNum=tItem[5], bBind=bBind, tPropExt=tPropExt}
				else
					tItemMap[sKey].nNum = tItemMap[sKey].nNum + tItem[5]
				end
			end

		elseif tGiftConf.nType == 2 then 	--全部随机
			for _, tItem in ipairs(tGiftConf.tDrop) do
				if tItem[1] == 0 or tItem[1] == oRole:GetConfID() then
					if math.random(100) <= tItem[2] then
						local tPropExt = nil
						if tItem[6] > 0 then 
							tPropExt = {nQuality=tItem[6]}
						end

						local sKey = string.format("%d-%d-%d", tItem[3], tItem[4], tItem[6])
						if not tItemMap[sKey] then
							tItemMap[sKey] = {nType=tItem[3], nID=tItem[4], nNum=tItem[5], bBind=bBind, tPropExt=tPropExt}
						else
							tItemMap[sKey].nNum = tItemMap[sKey].nNum + tItem[5]
						end
					end
				end
			end
		end
	end

	assert(next(tItemMap), "配置错误，道具掉落为空:"..tostring(self:GetGiftConf()))

	local tAddItemList = {}
	for sKey, tItem in pairs(tItemMap) do
		table.insert(tAddItemList, tItem)
	end

	if not bReturn then
		oRole:AddItemList(tAddItemList, "开礼包:"..self:GetID(), bNotSync)
		return true
	else
		return tAddItemList
	end
end

-- function CPropGift:CheckCanUse(bTips)
-- 	local oRole = self.m_oModule.m_oRole
-- 	local tGiftConf = self:GetGiftConf()
-- 	if tGiftConf.nType == 1 then 		--随机一个
-- 		if self.m_oModule:GetFreeGridCount() < 1 then
-- 			--检查当前礼包掉落是否包含道具实物
-- 			local bOccupyBagGrid = false
-- 			for k, tItem in ipairs(tGiftConf.tDrop) do 
-- 				if CKnapsack:IsOccupyBagGrid(tItem[3], tItem[4]) then 
-- 					bOccupyBagGrid = true 
-- 					break
-- 				end
-- 			end
-- 			if bOccupyBagGrid then
-- 				if bTips then  
-- 					oRole:Tips("背包空间不足，请先清理背包")
-- 				end
-- 				return false
-- 			end
-- 		end
-- 	elseif tGiftConf.nType == 2 then 	--全部随机
-- 		local nMaxDrop = 0
-- 		local nMaxBagGridOccupyNum = 0
-- 		local nRoleConfID = oRole:GetConfID()
-- 		for k, tItem in ipairs(tGiftConf.tDrop) do 
-- 			if (tItem[1] == 0 or tItem[1] == nRoleConfID) and tItem[2] > 0 then 
-- 				nMaxDrop = nMaxDrop + 1
-- 				if CKnapsack:IsOccupyBagGrid(tItem[3], tItem[4]) then 
-- 					nMaxBagGridOccupyNum = nMaxBagGridOccupyNum + 1
-- 				end
-- 			end
-- 		end
-- 		assert(nMaxDrop > 0, "配置错误，道具掉落为空")
-- 		if self.m_oModule:GetFreeGridCount() < nMaxBagGridOccupyNum then
-- 			if bTips then 
-- 				oRole:Tips("背包空间不足，请先清理背包")
-- 			end
-- 			return false
-- 		end
-- 	end
-- 	return true
-- end

--喜糖也有使用到此接口
function CPropGift:TrueUse(nNum)
	if self:GetNum() < nNum then --防止帮贡礼包，rpc返回时，礼包已经被使用了
		return false
	end
	-- if not self:CheckCanUse(true) then
	-- 	return false 
	-- end
	local oRole = self.m_oModule.m_oRole
	if self:Open(nNum) then 
		-- self.m_oModule:SubGridItem(self:GetGrid(), self:GetID(), 1, "开礼包")
		self.m_oModule:SubGridItem(self:GetGrid(), self:GetID(), nNum, "开礼包")
		return true
	else
		return false
	end
end
