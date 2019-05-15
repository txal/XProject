
--商品列表请求
function CltPBProc.ShopItemListReq(nCmd, Server, Srevice, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oSubShop = oRole.m_oShop:GetSubShop(tData.nShopType)
	oSubShop:ItemListReq(tData.nShopType  )
end

--购买请求
function CltPBProc.ShopBuyReq( nCmd, Server, Srevice, nSession, tData )
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oSubShop = oRole.m_oShop:GetSubShop(tData.nShopType)
	oSubShop:BuyReq(tData.nShopType , tData.nID , tData.nNum )
end