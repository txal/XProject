
--商品列表请求
function Network.CltPBProc.SystemMallItemListReq(nCmd, Server, Srevice, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(Server, nSession)
	if not oRole then return end
	local oSubShop = goMallMar:GetSubShop(tData.nShopType)
	oSubShop:ItemListReq(tData.nShopType, oRole, tData.nTradeMenuId)
end

--购买请求
function Network.CltPBProc.SystemMallBuyReq( nCmd, Server, Srevice, nSession, tData )
	local oRole = goGPlayerMgr:GetRoleBySS(Server, nSession)
	if not oRole then return end
	local oSubShop = goMallMar:GetSubShop(tData.nShopType)
	oSubShop:BuyReq(tData.nShopType , tData.nID , tData.nNum, oRole, tData.nShopSubType, false)
end


--商品出售
function Network.CltPBProc.SystemMallSellReq( nCmd, Server, Srevice, nSession, tData)
	print("商品出售了,快点来买")
	local oRole = goGPlayerMgr:GetRoleBySS(Server, nSession)
	if not oRole then return end
	local oSubShop = goMallMar:GetSubShop(tData.nShopType)
	oSubShop:SellReq(tData.nID, tData.nGrid, tData.nNum, oRole)
end

--更新
function Network.CltPBProc.SystemMallUpdateReq( nCmd, Server, Srevice, nSession, tData )
	local oRole = goGPlayerMgr:GetRoleBySS(Server, nSession)
	if not oRole then return end
	local oSubShop = goMallMar:GetSubShop(tData.nShopType)
	oSubShop:UpdateReq(tData.nShopType, oRole)
end


--购买金币银币请求
function Network.CltPBProc.SystemMallGoidBuyReq( nCmd, Server, Srevice, nSession, tData )
	local oRole = goGPlayerMgr:GetRoleBySS(Server, nSession)
	if not oRole then return end
	local oSubShop = goMallMar:GetSubShop(gtShopType.eCBuy)
	oSubShop:GoidBuyReq(tData.nID, oRole)
end

--快速购买
function Network.CltPBProc.SystemMallFastBuyListReq( nCmd, Server, Srevice, nSession, tData )
	local oRole = goGPlayerMgr:GetRoleBySS(Server, nSession)
	if not oRole then return end
	local oSubShop = goMallMar:GetSubShop(tData.nShopType)
	oSubShop:FastBuyListReq(oRole, tData.nShopType, tData.nTradeMenuId)
end

function Network.CltPBProc.SystemMallFastBuyReq( nCmd, Server, Srevice, nSession, tData )
	local oRole = goGPlayerMgr:GetRoleBySS(Server, nSession)
	if not oRole then return end
	local oSubShop = goMallMar:GetSubShop(tData.nShopType)
	print("tData----", tData)
	oSubShop:FastBuyReq(oRole,tData.PropID,tData.nPetPos)
end

function Network.CltPBProc.SystemUnionContriAmountReq(nCmd,Server,Srevice,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(Server,nSession)
	if not oRole then return end
	local oSubShop = goMallMar:GetSubShop(gtShopType.eCBuy)
	oSubShop:UnionContriDataReq(oRole)
end

function Network.CltPBProc.SystemGetShopPriceReq(nCmd,Server,Srevice,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(Server,nSession)
	if not oRole then return end
	local oSubShop = goMallMar:GetSubShop(gtShopType.eChamberCore)
	if tData.nNum == 0 then
		tData.nNum = 1
	end
	oSubShop:ShopPriceReq(oRole,tData.nID, tData.nGrid, tData.nNum)
end

function Network.CltPBProc.SystemGetPropPriceReq(nCmd,Server,Srevice,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(Server,nSession)
	if not oRole then return end
	local oSubShop = goMallMar:GetSubShop(gtShopType.eChamberCore)
	oSubShop:ShopPropPriceReq(oRole, tData.tItemList, tData.nClientFlag)
end

function Network.CltPBProc.systemMallMoneyConvertReq(nCmd,Server,Srevice,nSession,tData)
	local oRole = goGPlayerMgr:GetRoleBySS(Server,nSession)
	if not oRole then return end
	local oSubShop = goMallMar:GetSubShop(gtShopType.eCBuy)
	oSubShop:MoneyConvertReq(tData.nID, tData.nNum,oRole)
end


------------服务器内部
--获取道具价格
function Network.RpcSrv2Srv.GetShopPriceReq(nSrcServer, nSrcService, nTarSession, nRoleID,nPropID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oSubShop = goMallMar:GetSubShop(gtShopType.eChamberCore)
	if not oSubShop then return end
	return oSubShop:GetShopPrice(oRole, nPropID)
end

--远程购买-
function Network.RpcSrv2Srv.BuyShopPriceReq(nSrcServer, nSrcService, nTarSession, nRoleID, nShopType, nPropID, nBuyNum, sFuncBackReq)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oSubShop = goMallMar:GetSubShop(nShopType)
	if not oSubShop then return end
	local nRet = oSubShop:BuyReq(nShopType, nPropID, nBuyNum, oRole, true, sFuncBackReq)
	return
end

--查询商会购买价格
function Network.RpcSrv2Srv.QueryCommercePriceReq(nSrcServer, nSrcService, nTarSession, tItemList) 
	assert(tItemList)
	local oShop = goMallMar:GetSubShop(gtShopType.eChamberCore)
	assert(oShop)
	local tData = {}
	for _, tItem in ipairs(tItemList) do 
		local nItemType, nItemID = tItem.nItemType, tItem.nItemID
		assert(nItemType == gtItemType.eProp, "参数错误") --暂时写死只支持道具类型
		local nPrice = oShop:GetPrice(nItemID)
		assert(nPrice and nPrice > 0, "获取价格错误")
		table.insert(tData, {nItemType = nItemType, nItemID = nItemID, nPrice = nPrice})
	end
	return true, tData
end

--查询商会购买价格
function Network.RpcSrv2Srv.QueryCommercePriceTblReq(nSrcServer, nSrcService, nTarSession, tItemList) 
	assert(tItemList)
	local oShop = goMallMar:GetSubShop(gtShopType.eChamberCore)
	assert(oShop)
	local tData = {}
	for _, nItemID in pairs(tItemList) do 
		local nPrice = oShop:GetPrice(nItemID)
		assert(nPrice and nPrice > 0, "获取价格错误")
		tData[nItemID] = nPrice
	end
	return tData
end

--tItemList {nGrid:{nGrid, nItemID, nBuyPrice}, ...}
function Network.RpcSrv2Srv.QueryCommerceSalePriceTblReq(nSrcServer, nSrcService, nTarSession, tItemList) 
	assert(tItemList)
	local oShop = goMallMar:GetSubShop(gtShopType.eChamberCore)
	assert(oShop)
	local tData = {}
	for nGrid, tItem in pairs(tItemList) do 
		local nPrice = oShop:CalcSalePrice(tItem.nItemID, tItem.nBuyPrice)
		assert(nPrice and nPrice >= 0, "获取价格错误")
		tItem.nSalePrice = nPrice
		tData[nGrid] = tItem
	end
	return tData
end


function Network.RpcSrv2Srv.GetChamberCoreSkillReq(nSrcServer, nSrcService, nTarSession)
	local oSubShop = goMallMar:GetSubShop(gtShopType.eChamberCore)
	if not oSubShop then return end
	local tSkill = oSubShop:GetSkill()
	return tSkill
end
