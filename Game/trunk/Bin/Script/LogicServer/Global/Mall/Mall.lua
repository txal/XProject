local sMallDB = "MallDB"

CMall.tMallType = 
{
	eProp = 1, 	--道具
	eArm = 2, 	--装备
}

function CMall:Ctor()
end

function CMall:LoadData()
end

function CMall:SaveData()
end

function CMall:OnRelease()
end

function CMall:GetDailyBuyTimesRemain(oPlayer, nGoodsID)
	local tConf = assert(ctMallConf[nGoodsID])
	if tConf.nDailyLimit <= 0 then
		return nMAX_INTEGER
	end
	local oMallModule = oPlayer:GetModule(CMallModule:GetType())
	local nDailyBuyTimes = oMallModule:GetDailyBuyTimes(nGoodsID)
	local nRemainTimes = math.max(0, tConf.nDailyLimit - nDailyBuyTimes)
	return nRemainTimes
end

function CMall:BuyGoodsReq(oPlayer, nGoodsID, nBuyTimes)
	assert(nBuyTimes > 0)
	local tConf = assert(ctMallConf[nGoodsID])
	local nBuyNum = tConf.nBuyNum * nBuyTimes
	if tConf.nMallType == self.tMallType.eProp or tConf.nMallType == self.tMallType.eArm then
		--判断钱
		local nCostMoney = tConf.nUnitPrice * nBuyNum
		if tConf.nMoneyType == 1 then
			if oPlayer:GetGold() < nCostMoney then
				return oPlayer:ScrollMsg(ctLang[12])
			end
		else
			if oPlayer:GetMoney() < nCostMoney then
				return oPlayer:ScrollMsg(ctLang[4])
			end
		end
		--判断每天可购买
		if self:GetDailyBuyTimesRemain(oPlayer, nGoodsID) < nBuyTimes then
			return oPlayer:ScrollMsg(ctLang[13])
		end
		if oPlayer.m_oBagModule:IsBagFull(tConf.nItemType, tConf.nItemID, nBuyNum) then
			return oPlayer:ScrollMsg(ctLang[34])
		end
		--扣钱
		if tConf.nMoneyType == 1 then
			oPlayer:SubGold(nCostMoney, gtReason.eMallBuyItem)
		else
			oPlayer:SubMoney(nCostMoney, gtReason.eMallBuyItem)
		end
		if tConf.nDailyLimit > 0 then
			oPlayer.m_oMallModule:AddDailyBuyTimes(nGoodsID, nBuyTimes)
		end
		oPlayer:AddItem(tConf.nItemType, tConf.nItemID, nBuyNum, gtReason.eMallBuyItem)

		local nRemainTimes = self:GetDailyBuyTimesRemain(oPlayer, nGoodsID)
		local tData = {nID=nGoodsID, nRemainTimes=nRemainTimes}
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "MallBuyGoodsRet", tData)
		return
	end
	assert(false, "不支持商城类型:"..tConf.nMallType)
end

--物品列表请求
function CMall:GoodsListReq(oPlayer, nMallType, nPageType, nPageIndex, nPageSize)
	if nMallType == self.tMallType.eProp or nMallType == self.tMallType.eArm then
		local tGoodsConfList = GetMallGoodsList(nMallType, nPageType)	
		local nPageCount = math.ceil(#tGoodsConfList / nPageSize)
		local tGoodsList = {}
		if nPageCount > 0 then
			nPageIndex = math.max(1, math.min(nPageCount, nPageIndex))
			local nBeg = (nPageIndex - 1) * nPageSize + 1
			local nEnd = math.min(#tGoodsConfList, nBeg + nPageSize - 1)
			for k = nBeg, nEnd do
				local tConf = tGoodsConfList[k]
				local nRemainTimes = self:GetDailyBuyTimesRemain(oPlayer, tConf.nID)
				local tGoods = {nID=tConf.nID, nRemainTimes=nRemainTimes}
				table.insert(tGoodsList, tGoods)
			end
		else
			nPageIndex = 0
		end
		local tData = {nPageIndex=nPageIndex, nPageCount=nPageCount, tGoodsList=tGoodsList}
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "MallGoodsListRet", tData)
		return
	end
	assert(false, "不支持商城类型:"..nMallType)
end

--购买金币
function CMall:BuyGoldReq(oPlayer, nID)
	local tConf = assert(ctGoldConf[nID], "找不到配置")
	local nGold, nCost = tConf.nGold, tConf.nPrice 
	if oPlayer:GetMoney() < nCost then
		return oPlayer:ScrollMsg(ctLang[4])
	end
	oPlayer:SubMoney(nCost, gtReason.eBuyGold)
	oPlayer:AddGold(nGold, gtReason.eBuyGold)
end

goMall = goMall or CMall:new()