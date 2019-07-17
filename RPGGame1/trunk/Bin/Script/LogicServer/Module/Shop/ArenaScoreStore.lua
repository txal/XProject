--积分商城
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CArenaScoreStore:Ctor(oModule)
	--print("CArenaScoreStore:Ctor(oModule)")
	self.m_oModule = oModule
	self.m_tAllreadyBuy = {} 
	self.m_tFirstBuyTime = {} --限购物品 第一次购买时间

	-- 1 日限购 ，2 周限购 ，3 月限购 
	for nLimBuyType=1,3  do
		self.m_tAllreadyBuy[nLimBuyType] = {} --[nID] = nNum 日(周/月)限购物品 已购买的
		self.m_tFirstBuyTime[nLimBuyType] = 0 --日(周/月)限购 第一次购买时间
	end
end

function CArenaScoreStore:LoadData(tData)
	print("CArenaScoreStore:LoadData( tData )",tData)
	self.m_tAllreadyBuy = tData.m_tAllreadyBuy 
	self.m_tFirstBuyTime = tData.m_tFirstBuyTime 
end

function CArenaScoreStore:SaveData()
	local tData = {}
	tData.m_tAllreadyBuy = self.m_tAllreadyBuy
	tData.m_tFirstBuyTime = self.m_tFirstBuyTime
	return tData
end

function CArenaScoreStore:MarkDirty(bMark)
	self.m_oModule:MarkDirty(bMark)
end

--记录限购物品 已购买个数
function CArenaScoreStore:RecordLimItemBuyNum(tItem, nNum)
	if tItem.nLimBuyType == 0 then --非限购
		return
	end
	if  self.m_tFirstBuyTime[tItem.nLimBuyType] == 0 then
		self.m_tFirstBuyTime[tItem.nLimBuyType] = os.ZeroTime(os.time())
		print("第一次购买 类型"..tItem.nLimBuyType , self.m_tFirstBuyTime)
	end

	local nAllreadyBuy = self.m_tAllreadyBuy[tItem.nLimBuyType][tItem.nID] or 0
	self.m_tAllreadyBuy[tItem.nLimBuyType][tItem.nID] = nAllreadyBuy + nNum
	self:MarkDirty(true)
end

--重置限购表
function CArenaScoreStore:ResetRecordLimBuyNum()
	if self.m_tFirstBuyTime[1]~=0 and not os.IsSameDay( os.time() , self.m_tFirstBuyTime[1] , 0 )  then --每天限购 不是同一天且已经购买过
		self.m_tAllreadyBuy[1] = {}
		self.m_tFirstBuyTime[1] = 0
		self:MarkDirty(true)
	end

	if self.m_tFirstBuyTime[2]~=0 and not os.IsSameWeek( os.time() , self.m_tFirstBuyTime[2] , 0 )  then --每周限购
		self.m_tAllreadyBuy[2] = {}
		self.m_tFirstBuyTime[2] = 0
		self:MarkDirty(true)
	end

	if self.m_tFirstBuyTime[3]~=0 and not os.IsSameMonth( os.time() , self.m_tFirstBuyTime[3] , 0 ) then --每月限购
		self.m_tAllreadyBuy[3] = {}
		self.m_tFirstBuyTime[3] = 0
		self:MarkDirty(true)
	end
end

--获取限购物品 已购买个数
function CArenaScoreStore:GetLimItemBuyNum(tItem)
	self:ResetRecordLimBuyNum()  --获取已购买个数之前 要判断是否重置 
	return self.m_tAllreadyBuy[tItem.nLimBuyType][tItem.nID] or 0
end

--购买请求
function CArenaScoreStore:BuyReq(nShopType, nID, nNum)
	if nNum >200 then
		return self.m_oModule.m_oRole:Tips("单次最多购买200个！")
	end

	if nNum == 0 then 
		return self.m_oModule.m_oRole:Tips("请选择商品数目！")
	end

	local tItem = self.m_oModule:GetItemByShopTypeAndId( nShopType , nID )
	if not tItem then
		print("商品不存在,nShopType,nID",nShopType,nID)
		return self.m_oModule.m_oRole:Tips("商品不存在")
	end

	if not tItem.bUpFrame then
		return self.m_oModule.m_oRole:Tips("商品未上架")
	end

	if tItem.nLimBuyType ~= 0 then --限购物品
		if self:GetLimItemBuyNum( tItem )+nNum > tItem.nLimNum then
			return self.m_oModule.m_oRole:Tips("剩余商品不足！")
		end
	end

	if not self.m_oModule:CheckCurrIsEnough( tItem , nNum) then --货币是否够
		return self.m_oModule.m_oRole:Tips("货币不足！")
	end

	self:MarkDirty(true)
	--扣除货币
	self.m_oModule.m_oRole:SubItem(gtItemType.eCurr, tItem.nMoneyType, tItem.nNeedNum*nNum, gtShopName[nShopType].."购物扣除") 	
	--增加物品
	self.m_oModule.m_oRole:AddItem(gtItemType.eProp, tItem.nID, nNum, gtShopName[nShopType].."购物增加")
	
	if tItem.nLimBuyType ~= 0 then --限购物品
		--记录已购买次数
		self:RecordLimItemBuyNum(tItem, nNum) 
	end
	
	self.m_oModule.m_oRole:SendMsg("ShopBuyRet", {nID=nID, nNum=nNum})
end

--物品列表请求
function CArenaScoreStore:ItemListReq(nShopType)
	local _ctShopConf = self.m_oModule:GetItemByShopTypeAndId(nShopType)
	local tMsg = {}
	tMsg.nShopType = nShopType
	tMsg.tList = {}
	for nID, tConf in pairs(_ctShopConf) do
		local nRemainNum = -1
		if tConf.nLimBuyType ~= 0 then --是限购物品
			assert(tConf.nLimNum>0, string.format("限购物品的限购数填的是0？nID=%d",nID))
			nRemainNum = tConf.nLimNum - self:GetLimItemBuyNum(tConf)
		end
		table.insert(tMsg.tList, {nID=nID, nRemainNum=nRemainNum}) 
	end
	self.m_oModule.m_oRole:SendMsg("ShopItemListRet", tMsg)
end