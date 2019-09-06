--商会
local nMaxAddOnce = 5000 	--一次最多加道具数
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
function CChamberCore:Ctor(oModule)
	self.m_oModule = oModule

	--保存数据库
	self.m_tShotList = {}
	self.m_tPlayers = {}		--玩家数据 self.m_tPlayers[PlayerId] = {}
	self:init()

end
function CChamberCore:LoadData(tData)
	self.m_tShotList = tData.m_tShotList or {}
	self.m_tPlayers = tData.m_tPlayers or {}

	self:init()
end

function CChamberCore:SaveData()
	print("保存商会数据------>")
	local tData = {}
	tData.m_tShotList = self.m_tShotList or {}
	tData.m_tPlayers = self.m_tPlayers or {}
	return tData
end

function CChamberCore:MarkDirty(bMark)
	self.m_oModule:MarkDirty(bMark)
end

function CChamberCore:init()
	print("初始化数据")
	if #self.m_tShotList == 0 then
		self:InitShop()
	end
	self:ShopCheck()
	self:AddChamberCoreItem()
	self:AllmodifyPropParice()
end

function CChamberCore:InitShop()
	for _, tConf in pairs(ctCommerceItem) do
		self.m_tShotList[#self.m_tShotList+1] = {nID = tConf.nId,  nStatus = 2, nChange = 0,
		 nPrice = tConf.nBasePrice, nBasicPrice = tConf.nBasePrice, nConstBasePrice = tConf.nBasePrice}
	end
	self:MarkDirty(true)
end

--检查存盘的道具是否有删除(保持稳定,使用一个中间容器)
function CChamberCore:ShopCheck()
	local tTempList = {}
	for _, tShop in ipairs(self.m_tShotList) do
		if ctCommerceItem[tShop.nID] then
			table.insert(tTempList, tShop)
		else
			LuaTrace(string.format("商会道具已经从配置表删除<%d>:", tShop.nID))
		end
	end
	self.m_tShotList = tTempList
	self:MarkDirty(true)
end

function CChamberCore:GetShopInfo(nID)
	for _, tShop in ipairs(self.m_tShotList) do
		if tShop.nID == nID then
			return tShop
		end
	end
end

--零点刷新
function CChamberCore:ZeroUpdate()
	for i =1, #self.m_tShotList, 1 do
		self.m_tShotList[i].nChange = 0
		self.m_tShotList[i].nStatus = 2
		self.m_tShotList[i].nBasicPrice = self.m_tShotList[i].nPrice
	end
	self:AddChamberCoreItem()
	self.m_tPlayers = {}
	self:MarkDirty(true)
end

--增加道具跟删除道具一起
function CChamberCore:AddChamberCoreItem()
	local tTempList = {}
	local tShopList = {}
	for _, tItem in ipairs(self.m_tShotList) do
		tTempList[tItem.nID] = true
		--检测一下这个道具是否在配置表删除
		if ctCommerceItem[tItem.nID] then
			table.insert(tShopList, tItem)
		else
			LuaTrace(string.format("商会道具已经从配置表删除<%d>", tItem.nID))
		end
	end
	for _, tConfItem in pairs(ctCommerceItem) do
		if not tTempList[tConfItem.nId] then
			tShopList[#tShopList+1] = {nID = tConfItem.nId,  nStatus = 2, nChange = 0,
			nPrice = tConfItem.nBasePrice, nBasicPrice = tConfItem.nBasePrice, 
			nConstBasePrice = tConfItem.nBasePrice}
			LuaTrace(string.format("商会添加新的道具<%d>", tConfItem.nId))
		end
	end
	self.m_tShotList = tShopList
	self:MarkDirty(true)
end

function CChamberCore:FindItem(nTradeMenuId)
	for _, tItem in ipairs(self.m_tShotList) do
		if self:GetConfInfo(tItem.nID) and  self:GetConfInfo(tItem.nID).nTradeMenuId == nTradeMenuId then
		end
	end
end

function CChamberCore:GetChamberCoreProp(nPropID)
	for _, tItem in ipairs(self.m_tShotList) do
		if tItem.nID == nPropID then
			return tItem
		end
	end
end

function CChamberCore:GetConfInfo(nId)
	if nId <= 0 then
		return 
	end
	return ctCommerceItem[nId]
end

--修改单个商品价格
function CChamberCore:modifyPropParice(nPropID)
	local tPropCfg = ctCommerceItem[nPropID]
	if not tPropCfg then return  end
	local tProp
	for _, tItem in ipairs(self.m_tShotList) do
		if tItem.nID == nPropID then
			tProp = tItem
			break
		end
	end
	if not tProp then return end
	tProp.nStatus = 2
	tProp.nChange = 0
	tProp.nPrice = tPropCfg.nBasePrice
	tProp.nBasicPrice = tPropCfg.nBasePrice
	self:MarkDirty(true)
end

--价格刷新检测
function CChamberCore:AllmodifyPropParice()
	for _, tItem in ipairs(self.m_tShotList) do
		local tProp = ctCommerceItem[tItem.nID]
		if tProp then
			if not tItem.nConstBasePrice or tItem.nConstBasePrice ~= tProp.nConstBasePrice then
				tItem.nStatus = 2
				tItem.nChange = 0
				tItem.nPrice = tProp.nBasePrice
				tItem.nBasicPrice = tProp.nBasePrice
				tItem.nConstBasePrice = tProp.nBasePrice
			end
		end
	end
	self:MarkDirty(true)
end

--物品列表请求
function CChamberCore:ItemListReq(nShopType, oRole, nTradeMenuId)
	local tMsg = {tList = {}, nShopType = nShopType, nTradeMenuId = nTradeMenuId, nServerLv = goServerMgr:GetServerLevel(oRole:GetServer())}
	for i = 1, #self.m_tShotList, 1 do
		local nID = self.m_tShotList[i].nID
		--策划要求加等级限制,根据服务器等级来限制
		if ctCommerceItem[nID] and goServerMgr:GetServerLevel(oRole:GetServer()) >= ctCommerceItem[nID].nGameServerGrade then
			if self:GetConfInfo(nID) and  self:GetConfInfo(nID).nTradeMenuId == nTradeMenuId then
				if self:GetConfInfo(nID).nBuyCount ~= 1 then
					if self.m_tPlayers[oRole:GetID()] and  self.m_tPlayers[oRole:GetID()][nID]then
						self:MallInfoHdanle(tMsg, oRole, 1, nID, i)
					else
						self:MallInfoHdanle(tMsg, oRole, 2, nID, i)
					end
				else
					self:MallInfoHdanle(tMsg, oRole, 2, nID, i)				
				end
			end
		end
	end
	oRole:SendMsg("SystemMallItemListRet", tMsg)
end

function CChamberCore:MallInfoHdanle(tMsg, oRole, nType, nID, nIndex)
	if nType == 1 then
		local nRemainNum =  self.m_tPlayers[oRole:GetID()][nID].nNum
		local nStatus =  self.m_tShotList[nIndex].nStatus
		local nChange =  self.m_tShotList[nIndex].nChange
		local nUnitPrice = math.floor(self.m_tShotList[nIndex].nPrice)
		local tConf = self:GetConfInfo(nID)
		if not tConf then
			return 
		end
		nRemainNum = tConf.nBuyCount - nRemainNum
		tMsg.tList[#tMsg.tList+1] = {nID =nID,  nRemainNum = nRemainNum,nStatus = nStatus, nChange =nChange, nUnitPrice = nUnitPrice}
	elseif nType == 2 then
		local nRemainNum = self:GetConfInfo(nID).nBuyCount
		local nStatus =  self.m_tShotList[nIndex].nStatus
		local nChange =  self.m_tShotList[nIndex].nChange
		local nUnitPrice = self.m_tShotList[nIndex].nPrice
		tMsg.tList[#tMsg.tList+1] = {nID =nID,  nRemainNum = nRemainNum,nStatus = nStatus, nChange =nChange, nUnitPrice = nUnitPrice}
	end
end


--购买请求
--sFuncBack 快速购买标记，sFuncBack为true不入背包
function CChamberCore:BuyReq(nShopType, nID, nNum, oRole, nShopSubType, sFuncBack)
	if not oRole:IsSysOpen(18, true) then
		return
	end
	local tConf = self:GetConfInfo(nID)
	if not tConf then
		return oRole:Tips("商品不存在")
	end

	 if goServerMgr:GetServerLevel(oRole:GetServer()) < tConf.nGameServerGrade then
	 	return oRole:Tips(string.format("服务器等级%d级商会开放此商品买卖", tConf.nGameServerGrade))
	 end

	local tShop = self:GetShopInfo(nID)
	if not tShop then
	 	return oRole:Tips("商品不存在")
	end

	local nTNum = nNum 		--nTNum 保存购买数量,因为下文会引用到nNum这个值
	if not nTNum or nTNum <= 0 then
		return oRole:Tips("购买数量错误")
	end
	if nMaxAddOnce < nNum then return oRole:Tips("单次最多买" .. nMaxAddOnce .. "份") end
	local tProp = ctPropConf[nID]
	if not tProp then 
		return oRole:Tips("配置错误")
	 end
	--当前物品数量
	local fnGetOverFoldNumCallBack = function (nCurNum)
		--快速购买的物品不进入背包,不做背包检查
		if not nCurNum then return end
		if not sFuncBack then
			if nCurNum < nTNum then
				return oRole:Tips("背包空间不足,清理后再买")
			end
		end
		local nPropID = nID
		--每购买一个商品的涨价值为(标准系数/当前服务器上限等级)*服务器开放等级*当前价格/10000*涨价系数						
		if tConf.nBuyCount ~= -1 then
			if not self.m_tPlayers[oRole:GetID()] then
				self.m_tPlayers[oRole:GetID()] = {}
			end
			if not self.m_tPlayers[oRole:GetID()][nPropID] then
				self.m_tPlayers[oRole:GetID()][nPropID] = {nID = nPropID, nNum = 0, nSellNum = 0}
			end
			local nCount = tConf.nBuyCount
			local nLastCount =  nCount - self.m_tPlayers[oRole:GetID()][nPropID].nNum
			if nLastCount < nTNum then
				oRole:Tips("购买次数不足")
				return 
			end
			--@tItemList {{nType=0,nID=0,nNum=0},...}
			local nValue = 0
			local tItemList = {}
			tItemList[#tItemList+1] = {nType = gtItemType.eCurr, nID = gtCurrType.eJinBi, nNum =math.floor(self:GetShopInfo(nPropID).nPrice) *nTNum}
			local nValue = 0
			local fnFlushCostCallBack = function (bRet)
				if not bRet then
					oRole:Tips("货币不足")
					return
				end

				--@tItemList {{nType=0,nID=0,nNum=0,bBind=false,tPropExt={}},...}
				--快速购买使用不用进背包
				if not sFuncBack then
					local tList = {}
					local bBind = false
					if tConf.nBagType == gtItemType.eFaBao then
						bBind = true
					end
					tList[#tList+1] = {nType = tConf.nBagType, nID = nPropID, nNum = nTNum, bBind = bBind, tPropExt= {nBuyPrice = tShop.nPrice}}
					oRole:AddItem(tList, "商会购买获得")
				end
				self.m_tPlayers[oRole:GetID()][nPropID].nNum = self.m_tPlayers[oRole:GetID()][nPropID].nNum + nTNum
				if tConf.nRiseFactor ~= 0 then
					if tShop.nPrice < self:GetConfInfo(tShop.nID).nMaxSalePrice then
						self:Calculate(self:GetShopInfo(nPropID), nTNum, oRole, 1)
					end
				end
				local nBuyCount = self.m_tPlayers[oRole:GetID()][nPropID].nNum
				local tMsg =  {nID = nPropID, nNum = nTNum, nRemainNum = tConf.nBuyCount - nBuyCount, nStatus = self:GetShopInfo(nPropID).nStatus,
				 nChange = self:GetShopInfo(nPropID).nChange, nUnitPrice = self:GetShopInfo(nPropID).nPrice}
				oRole:SendMsg("SystemMalluyRet", tMsg)
				--print("商会购买消息返回", tMsg)
				if type(sFuncBack) == "string" then
					tItemList = {}
					local tMsg = {}
					tItemList[#tItemList+1] = {nID = nPropID,  nPrice = self:GetShopInfo(nPropID).nPrice}
					tMsg.ShopList = tItemList
					tMsg.nShopType = nShopType
					tMsg.nTradeMenuId = self:GetConfInfo(nPropID).nTradeMenuId
					oRole:SendMsg("SystemMallFastBuyListRet", tMsg)
					Network.oRemoteCall:Call(sFuncBack, oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), nPropID)
				end
				self:MarkDirty(true)
			end

			oRole:SubItem(tItemList, "商城购买消耗",fnFlushCostCallBack)
		else
			local tShop = self:GetShopInfo(nPropID)
			if not tShop then	
				return 
			end
			if not self.m_tPlayers[oRole:GetID()] then
				self.m_tPlayers[oRole:GetID()] = {}
			end

			if not self.m_tPlayers[oRole:GetID()][nPropID] then
				self.m_tPlayers[oRole:GetID()][nPropID] = {nID = nPropID, nNum = 0, nSellNum = 0}
			end

			local tItemList ={}
			tItemList[#tItemList+1] = {nType = gtItemType.eCurr, nID = gtCurrType.eJinBi, nNum = math.floor(self:GetShopInfo(nPropID).nPrice) * nTNum}
			local fnFlushCostCallBack = function (bRet)
				if not bRet then
					oRole:Tips("货币不足")
					return
				end
				if not sFuncBack then		
					local tList = {}
					local bBind = false
					if tConf.nBagType == gtItemType.eFaBao then
						bBind = true
					end
					tList[#tList+1] = {nType = tConf.nBagType, nID = nPropID, nNum = nTNum, bBind = bBind,  tPropExt= {nBuyPrice = tShop.nPrice} }
					oRole:AddItem(tList, "商会购买获得")
				end
				if tConf.nRiseFactor ~= 0 then
					if tShop.nPrice < self:GetConfInfo(tShop.nID).nMaxSalePrice then
						self:Calculate(tShop, nTNum, oRole, 1)
					end
				end
				local nBuyCount = self.m_tPlayers[oRole:GetID()][nPropID].nNum
				local tMsg =  {nID = nPropID, nNum = nTNum, nStatus = self:GetShopInfo(nPropID).nStatus,nRemainNum = -1,
				 nChange = self:GetShopInfo(nPropID).nChange, nUnitPrice = self:GetShopInfo(nPropID).nPrice}
				oRole:SendMsg("SystemMalluyRet", tMsg)
				self:MarkDirty(true)
				if type(sFuncBack) == "string" then
					tItemList = {}
					tItemList[#tItemList+1] = {nID = nPropID,  nPrice = self:GetShopInfo(nPropID).nPrice}
					local tMsg = {}
					tMsg.ShopList = tItemList
					tMsg.nShopType = nShopType
					tMsg.nTradeMenuId = self:GetConfInfo(nPropID).nTradeMenuId
					oRole:SendMsg("SystemMallFastBuyListRet", tMsg)
					if type(sFuncBack) == "string" then
						Network.oRemoteCall:Call(sFuncBack, oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), nPropID)
					end	
				end
			end
			oRole:SubItem(tItemList, "商城购买消耗", fnFlushCostCallBack)
		end
	end
	oRole:KnapsackRemainCapacity(nID, false, fnGetOverFoldNumCallBack, tConf.nBagType)
end

function CChamberCore:Calculate(tShop, nNum, oRole, nType)
	if not tShop then
		print("商品不存在")
		return 
	end

	local tConf = self:GetConfInfo(tShop.nID)	
	if not tConf then
		return oRole:Tips("商品不存在")
	end
	local nServerLv = goServerMgr:GetServerLevel(oRole:GetServer())
	if nServerLv > tConf.nMaxGameServerGrade then
		nServerLv = tConf.nMaxGameServerGrade
	end
	if nType == 1 then	
		--每购买一个商品的涨价值为(标准系数/当前服务器上限等级)*服务器开放等级*当前价格/10000*涨价系数	
		local bFlag = false
		for i = 1, nNum, 1 do
			  local nFaPrice= (tConf.nFactor/nServerLv )*
			 tConf.nGameServerGrade * tShop.nPrice/10000 * tConf.nRiseFactor
			 tShop.nPrice = tShop.nPrice + nFaPrice

			--判断每天最大的涨价
			 if math.floor(tShop.nPrice) > (math.floor(tShop.nBasicPrice) * (tConf.nPriceLimit/10000) + math.floor(tShop.nBasicPrice)) then
			 	 tShop.nPrice = (math.floor(tShop.nBasicPrice) * (tConf.nPriceLimit/10000) + math.floor(tShop.nBasicPrice))
			 	 bFlag = true
			 end

			 --判断物品最高价格
			 if math.floor(tShop.nPrice) >= tConf.nMaxSalePrice then
			 	tShop.nPrice = tConf.nMaxSalePrice
			 	bFlag = true
			 end

			if math.floor(tShop.nPrice + 0.5) > math.floor(tShop.nPrice) then
				tShop.nPrice = math.floor(tShop.nPrice + 0.5)
			end

			tShop.nChange =((tShop.nPrice) - (tShop.nBasicPrice))/(tShop.nBasicPrice)
			--tShop.nChange =(math.floor(tShop.nPrice) - math.floor(tShop.nBasicPrice))/(math.floor(tShop.nBasicPrice))
			if bFlag then
				break
			end
		end
	else
		--每卖入一个商品的跌价值为(标准系数/当前服务器上限等级)*服务器开放等级*当前价格/10000
		tShop.nPrice = tShop.nPrice - (tConf.nFactor/nServerLv ) *  tConf.nGameServerGrade * tShop.nPrice/10000 * nNum

		--每天最大跌价值
		 if math.floor(tShop.nPrice) < (math.floor(tShop.nBasicPrice) - math.floor(tShop.nBasicPrice) * (tConf.nPriceLimit/10000)) then
		 	 tShop.nPrice = (math.floor(tShop.nBasicPrice) - math.floor(tShop.nBasicPrice) * (tConf.nPriceLimit/10000))
		 	 bFlag = true
		end
		tShop.nChange =((tShop.nPrice) - (tShop.nBasicPrice))/(tShop.nBasicPrice)
	end
	local nValue = tShop.nChange * 10000
	local nChange = math.floor(nValue+ 0.5)
	 if nChange > 0 then
	 	 tShop.nStatus = 1
	 elseif nChange == 0 then
	 	 tShop.nStatus = 2
	 else
	 	 tShop.nStatus = 3
	 end
	 self:MarkDirty(true)
end

--是否可出售，以及当前可出售的最大数量
function CChamberCore:CheckSell(nPropID) 
	if not oRole:IsSysOpen(18) then
		return false, 0, oRole:SysOpenTips(18)
	end
	local nSellPrice = 0
	local tConf = ctCommerceItem[nPropID]
	if not tConf then
		local sTips = "无法出售给商会"
		if ctPropConf[nPropID] then 
			sTips = string.format("%s无法出售给商会", ctPropConf:PropName(nPropID))
		end
		return false, 0, sTips
	end

	if goServerMgr:GetServerLevel(oRole:GetServer()) < tConf.nGameServerGrade then
		return false, 0, string.format("服务器等级%d级商会开放此商品买卖", tConf.nGameServerGrade)
	end

	local nRecordNum = 0
	local tRoleRecordInfo = self.m_tPlayers[oRole:GetID()]
	if tRoleRecordInfo then 
		nRecordNum = tRoleRecordInfo[nPropID] or 0
	end
	local nRemain = self:GetConfInfo(nPropID).nSellCount - nRecordNum
	if nRemain <= 0 then 
		return false, 0, string.format("%s 今日剩余出售数量为0次", ctPropConf:PropName(nPropID))
	end
	return true, nRemain
end

function CChamberCore:SellReq(nID, nGrid, nNum,oRole)
	if not oRole:IsSysOpen(18, true) then
		return
	end
	local nSellPrice = 0
	local tConf = ctCommerceItem[nID]
	if not tConf then
		return oRole:Tips("配置文件不存在")
	end

	if goServerMgr:GetServerLevel(oRole:GetServer()) < tConf.nGameServerGrade then
		return oRole:Tips(string.format("服务器等级%d级商会开放此商品买卖", tConf.nGameServerGrade))
	end
	local nTNum = nNum
	local bSell = false
	local nOverSellNum = 0
	local tShop = self:GetShopInfo(nID)
	local fnGetKnapsackCallBack = function(nBet)
		local tItem = nBet
		if not tItem then
			return 
		end
		tItem.m_nFold = tItem.m_nFold or 1
		if tItem.m_nFold < nNum then
			return oRole:Tips("没有足够的商品出售")
		end
		if not self.m_tPlayers[oRole:GetID()] then
			self.m_tPlayers[oRole:GetID()] = {}
		end

		if not self.m_tPlayers[oRole:GetID()][nID] then
			self.m_tPlayers[oRole:GetID()][nID] = {nID = nID, nNum = 0, nSellNum = 0}
		end

		if self:GetConfInfo(nID).nSellCount ~= -1 then
			 bSell = true
			 local sTips = "出售数量过多,今日剩余出售次数为%d次"
			local sPropName = ctPropConf[nID].sName
			 if self.m_tPlayers[oRole:GetID()][nID].nSellNum >= self:GetConfInfo(nID).nSellCount then
		 		return oRole:Tips("出售数量不足。今日剩余出售数量为0次")
			 end
			 if self:GetConfInfo(nID).nSellCount - self.m_tPlayers[oRole:GetID()][nID].nSellNum < nTNum then
			 	local nOverSellNum = self:GetConfInfo(nID).nSellCount - self.m_tPlayers[oRole:GetID()][nID].nSellNum
			 	return oRole:Tips(string.format(sTips,nOverSellNum))
			 end
		end
		local nSellJinBi = 0
		local nSellYinBi = 0
	
		--@tItemList {{nType=0,nID=0,nNum=0},...}
		local tItemList1 = {{nGrid = nGrid, nID = nID, nNum =nTNum}}
		local fnGetSaleYuanbaoCallback = function(nRemainYuanbao) 
			if not nRemainYuanbao then 
				return 
			end
			local fnFlushCostCallBack = function (bRet)
				if not bRet then
					return oRole:Tips("没有足够的商品出售")
				end
				local nJinBi, nYinBi= self:PriceHandle(tShop, tItem, nID, nNum, tConf)
				nSellYinBi = nSellYinBi + nYinBi
				nSellJinBi = nSellJinBi + nJinBi
				if nSellJinBi > 0 then
					local tItemList = {}
					tItemList[#tItemList+1] = {nType = gtItemType.eCurr, nID =gtCurrType.eJinBi, nNum = nSellJinBi,  bBind = false, tPropExt = {}}
					oRole:AddItem(tItemList, "商会卖出获得")
				end

				if nSellYinBi > 0 then
					local tItemList = {}
					-- tItemList[#tItemList+1] = {nType = gtItemType.eCurr, nID =gtCurrType.eYinBi, nNum = nSellYinBi,  bBind = false, tPropExt = {}}
					local nYuanBaoNum = nSellYinBi // gnSaleSilverRatio
					if nYuanBaoNum > 0 then 
						local nTransSilerNum = 0
						if nYuanBaoNum > nRemainYuanbao then --做2次转换, 以当前元宝为基准
							nTransSilerNum = (nYuanBaoNum - nRemainYuanbao) * gnSaleSilverRatio
							nYuanBaoNum = nRemainYuanbao
						end
						if nYuanBaoNum > 0 then 
							tItemList[#tItemList+1] = {nType = gtItemType.eCurr, nID =gtCurrType.eBYuanBao, nNum = nYuanBaoNum}
						end
						if nTransSilerNum > 0 then 
							tItemList[#tItemList+1] = {nType = gtItemType.eCurr, nID =gtCurrType.eYinBi, nNum = nTransSilerNum}
						end
						oRole:AddItem(tItemList, "商会卖出获得")
						if nYuanBaoNum > 0 then 
							Network:RMCall("KnapsackAddSaleYuanbaoRecordReq", nil, oRole:GetStayServer(), 
								oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), nYuanBaoNum)
						end
						if nTransSilerNum > 0 then 
							oRole:Tips("已超过每日回收可获得绑定元宝上限，已自动转换为银币")
						end
					end
				end

				if tConf.nRiseFactor ~= 0 then
					if tShop.nPrice > self:GetConfInfo(tShop.nID).nMinSalePrice then
						self:Calculate(tShop, nTNum, oRole, 2)
					end
				end

				self.m_tPlayers[oRole:GetID()][nID].nSellNum = self.m_tPlayers[oRole:GetID()][nID].nSellNum + nNum
				nRemainNum = tConf.nBuyCount - self.m_tPlayers[oRole:GetID()][nID].nNum
				self:MarkDirty(true)
				local tMsg =  {nID = nID, nNum = nNum, nStatus = self:GetShopInfo(nID).nStatus,
				nChange = self:GetShopInfo(nID).nChange, nUnitPrice = self:GetShopInfo(nID).nPrice, nRemainNum = nRemainNum}
				oRole:SendMsg("SystemMalluyRet", tMsg)
				if bSell then
					nOverSellNum = self:GetConfInfo(nID).nSellCount - self.m_tPlayers[oRole:GetID()][nID].nSellNum
					local sTips = "出售成功,今日剩余出售次数为%d次"
					local sPropName = ctPropConf[nID].sName
					oRole:Tips(string.format(sTips, nOverSellNum))
				Network:RMCall("OnChamberCoreItemOnSale", nil, oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), {})
				end
				print("商会出售消息返回", tMsg)
			end
			oRole:SubPropByGrid(tItemList1, "商会出售消耗",fnFlushCostCallBack, tConf.nBagType) 
		end
		Network:RMCall("KnapsackGetSaleYuanbaoRemainNumReq", fnGetSaleYuanbaoCallback, oRole:GetStayServer(), 
			oRole:GetLogic(), oRole:GetSession(), oRole:GetID())
	 end
	 oRole:GetPropData(nGrid,fnGetKnapsackCallBack, tConf.nBagType)
end

function CChamberCore:CalcSalePrice(nID, nBuyPrice) 
	assert(nID > 0, "参数错误")
	local tConf = ctCommerceItem[nID]
	assert(tConf, "配置不存在"..nID)
	if not nBuyPrice or nBuyPrice <= 0 then 
		nBuyPrice = self:GetItemPrice(nID, 1)
	end
	local tShop = self:GetShopInfo(nID)
	local nSalePrice = tShop.nPrice
	if nSalePrice > nBuyPrice then 
		nSalePrice = nBuyPrice
	end
	nSalePrice = math.floor(nSalePrice * (1 - tConf.nTaxRate/10000))
	return nSalePrice
end

function CChamberCore:PriceHandle(tShop, tProp, nID, nNum, tConf)
	local nSellJinBi = 0
	local nSellYinBi = 0
	local nBuyPrice = tProp.m_nBuyPrice
	local nSellPrice = 0
	-- if nBuyPrice <= 0 then
	-- 	--return oRole:Tips("购买价格为零")
	-- 	nBuyPrice = self:GetItemPrice(nID, 1)
	-- 	if nBuyPrice == 0 then
	-- 		return oRole:Tips("商会没有此商品")
	-- 	end
	-- end
	-- if tShop.nPrice > nBuyPrice then
	-- 	nSellPrice = nBuyPrice
	-- else
	-- 	nSellPrice = tShop.nPrice
	-- end
	-- nSellPrice = math.floor(nSellPrice * (1 - tConf.nTaxRate/10000))
	nSellPrice = self:CalcSalePrice(nID, nBuyPrice)
	local nSellNum = nNum
	if tProp.m_bBind then
		--绑定的进行转换为银币
		nSellYinBi = nSellYinBi + nSellPrice * gnGold2SilverRatio * (nSellNum or 1)
	else
		nSellJinBi = nSellJinBi +  nSellPrice * (nSellNum or 1)
	end
	return nSellJinBi, nSellYinBi
end

function CChamberCore:GetItemPrice(nID, nNum)
	if nID <= 0 then return end
	for _, tShop in pairs(self.m_tShotList) do
		if tShop.nID == nID then
			local nBuyPrice = math.floor(tShop.nPrice) * 0.9 * nNum
			return math.floor(nBuyPrice)
		end
	end
end

--快速购买列表请求
function CChamberCore:FastBuyListReq(oRole, nShopType, nTradeMenuId)
	local tItemList = {}
	for _, tItem in pairs(self.m_tShotList) do
		if self:GetConfInfo(tItem.nID) and self:GetConfInfo(tItem.nID).nTradeMenuId == nTradeMenuId then
			tItemList[#tItemList+1] = {nID = tItem.nID,  nPrice = tItem.nPrice}
		end
	end
	local tMsg = {}
	tMsg.ShopList = tItemList
	tMsg.nShopType = nShopType
	tMsg.nTradeMenuId = nTradeMenuId
	oRole:SendMsg("SystemMallFastBuyListRet", tMsg)
 end 

--宠物技能书快速购买(学习)  
 function CChamberCore:FastBuyReq(oRole,nPropID, nPos)
	local nPrice =  math.floor(self:GetChamberCoreProp(nPropID).nPrice)
	Network:RMCall("PetFastLearnSkillReq", nil, oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), nPropID, nPos, nPrice)
 end

 function CChamberCore:GetShopPrice(oRole, nPropID)
 	local tShop = self:GetChamberCoreProp(nPropID)
 	if not tShop then
 		return oRole:Tips("商品不存在")
 	end
 	local tItem = {}
 	local nYuanBao
 	local nAddYuanBao
 	nYuanBao, nAddYuanBao = math.modf(math.floor(tShop.nPrice)/100)
 	tItem.nYuanBao = nYuanBao + math.ceil(nAddYuanBao)
 	tItem.nYinBi = math.floor(tShop.nPrice) * 10000
 	tItem.nJinBi = math.floor(tShop.nPrice)
 	return tItem
 end

 
function CChamberCore:GetPrice(nPropID)
	local tShop = self:GetShopInfo(nPropID)
	assert(tShop, "商会无此道具出售" .. nPropID)
	return math.floor(tShop.nPrice)
end


function CChamberCore:ShopPriceReq(oRole, nPropID, nGrid, nNum)
	local tConf = ctCommerceItem[nPropID]
	local tShop = self:GetChamberCoreProp(nPropID)
	if not tShop or not tConf then
		return oRole:Tips("商品不存在")
	end
	local fnGetKnapsackCallBack = function(tItem)
		local tItem = tItem
		if not tItem then
			return 
		end
		local nBuyPrice = tItem.m_nBuyPrice
		if nBuyPrice <= 0 then
			--return oRole:Tips("购买价格为零")
			nBuyPrice = self:GetItemPrice(nPropID, 1)
			if nBuyPrice == 0 then
				return oRole:Tips("商会没有此商品")
			end
		end
		local nSellPrice = 0
		if tShop.nPrice > nBuyPrice then
			nSellPrice = nBuyPrice
		else
			nSellPrice = tShop.nPrice
		end
		nSellPrice = math.floor(nSellPrice * (1 - tConf.nTaxRate/10000))
		local nYinBiPrice = nSellPrice * gnGold2SilverRatio
		local tMsg = {nYinBi = nYinBiPrice * nNum, nJinBi = nSellPrice * nNum}
		oRole:SendMsg("SystemGetShopPriceRet", tMsg)
	end
	 oRole:GetPropData(nGrid,fnGetKnapsackCallBack, tConf.nBagType)
	
end

--出售道具,如果绑定就按照1-100的比例给玩家换算成银币
function CChamberCore:YinBiExchange(oRole,nValue)
	local nYinBi = nValue * 100
	local tItemList = {}
	tItemList[#tItemList+1] = {nType = gtItemType.eCurr, nID = gtCurrType.eYinBi, nNum = nYinBi,  bBind = false, tPropExt = {}}
	oRole:AddItem(tItemList, "商会卖出获得")
end

function CChamberCore:ShopPropPriceReq(oRole, tItemList, nClientFlag)
	local tItemPriceList = {}
	for _, tItem in pairs(tItemList) do
		if self:GetChamberCoreProp(tItem.nPropID) then
			local tItemInfo = {}
			tItemInfo.nPropID = tItem.nPropID
			tItemInfo.nJinBi = math.floor(self:GetChamberCoreProp(tItem.nPropID).nPrice)
			tItemInfo.nYuanBao = math.ceil(tItemInfo.nJinBi/gnGoldRatio)
			tItemInfo.nYinBi = tItemInfo.nYuanBao * gnSilverRatio
			table.insert(tItemPriceList, tItemInfo)
		else
			--商会如果没有出售的情况下，那么我就读配置表
			local tProp = ctPropConf[tItem.nPropID]
			assert(tProp, "道具配置错误")
			local tItemInfo = {}
			tItemInfo.nPropID = tItem.nPropID
			tItemInfo.nYuanBao =  tProp.nBuyPrice
			tItemInfo.nJinBi = tProp.nBuyPrice * gnGoldRatio
			tItemInfo.nYinBi = tProp.nBuyPrice * gnSilverRatio
			table.insert(tItemPriceList, tItemInfo)
		end
	end
	local tMsg = {tItemList = tItemPriceList, nClientFlag=nClientFlag}
	oRole:SendMsg("SystemGetPropPriceRet", tMsg)
end


--取宠物技能
function CChamberCore:GetSkill()
	--TODD ..默认低级技能书
	local nTradeMenuId = 1101
	local tShopList = {}
	for _, tItem in ipairs(self.m_tShotList) do
		local tProp = ctCommerceItem[tItem.nID]
		if tProp then
			if tProp.nTradeMenuId == nTradeMenuId or tProp.nTradeMenuId == 1102 then
				tShopList[tItem.nID] = {nID = tItem.nID, nPrice = tItem.nPrice}
			end
		end
	end

	return tShopList
end