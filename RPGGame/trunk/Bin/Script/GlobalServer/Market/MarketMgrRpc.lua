------客户端服务器------

--获取商品价格信息请求
function CltPBProc.MarketGoodsPriceDataReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
	goMarketMgr:GetItemPriceData(oRole, tData.nItemID)
end

--玩家摊位数据请求
function CltPBProc.MarketStallDataReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMarketMgr:GetStallData(oRole)
end

--商品上架销售请求
function CltPBProc.MarketItemOnSaleReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    -- goMarketMgr:SellItem(oRole, tData.nItemID, tData.nGridNum, tData.nNum, gtCurrType.eYinBi, tData.nBasePrice, tData.nPriceRatio, gnMarketItemActiveTime)
    goMarketMgr:SellItemList(oRole, tData.tItemList)
end

--商品重新上架请求
function CltPBProc.MarketItemReSaleReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMarketMgr:ReSale(oRole, tData.nPKey, tData.nBasePrice, tData.nPriceRatio)
end

--商品下架请求
function CltPBProc.MarketRemoveSaleReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    LuaTrace("商品下架")
    goMarketMgr:RemoveItemByRole(oRole, tData.nPKey)
end

--商品提现请求
function CltPBProc.MarketDrawMoneyReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMarketMgr:DrawMoney(oRole, tData.nPKey)
end

--获取交易列表刷新数据请求
function CltPBProc.MarketViewPageFlushDataReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMarketMgr:GetViewPageFlushData(oRole)
end

--获取交易页表数据请求
function CltPBProc.MarketViewPageDataReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMarketMgr:GetViewPageDataReq(oRole, tData.nPageID)
end

--刷新整个交易页表数据请求
function CltPBProc.MarketFlushViewPageReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMarketMgr:FlushViewPageReq(oRole, tData.bMoney)
end

--购买商品请求
function CltPBProc.MarketPurchaseReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMarketMgr:PurchaseItemReq(oRole, tData.nPageID, tData.nGKey)
end

--解锁摊位格子请求
function CltPBProc.MarketUnlockStallGridReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMarketMgr:UnlockStallGrid(oRole)
end

--摊位出售的商品详细信息请求
function CltPBProc.MarketStallItemDetailInfoReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMarketMgr:StallItemDetailInfoReq(oRole, tData.nPKey)
end

--摊位出售的商品详细信息请求
function CltPBProc.MarketViewItemDetailInfoReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMarketMgr:ViewItemDetailInfoReq(oRole, tData.nPageID, tData.nGKey)
end

------------- Svr2Svr ----------
--获取摆摊物品基础价格
function Srv2Srv.GetItemBasePriceReq(nSrcServer, nSrcService, nTarSession,nRoleID,nPropID)
    local oRole =  goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    return goMarketMgr:GetItemBasePrice(nPropID)
end

--获取摆摊多个物品基础价格
function Srv2Srv.GetMultipleItemBasePriceReq(nSrcServer, nSrcService, nTarSession,nRoleID,tItemList)
    local oRole =  goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    return goMarketMgr:GetMultipleItemBasePrice(tItemList)
end

function Srv2Srv.GetMarketBasePriceTblReq(nSrcServer, nSrcService, nTarSession, tItemList)
    assert(tItemList, "参数错误")
    local tPriceTbl = {}
    for k, nItemID in ipairs(tItemList) do 
        tPriceTbl[nItemID] = goMarketMgr:GetItemBasePrice(nItemID)
    end
    return tPriceTbl
end
