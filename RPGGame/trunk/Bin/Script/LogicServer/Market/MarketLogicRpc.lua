--摆摊逻辑服功能
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


------------Svr2Svr-------------
function Srv2Srv.MarketSellItemReq(nSrcServer, nSrcService, nTarSession, nRoleID,  tSaleItemData, tTaxList)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    local nItemID = tSaleItemData.nItemID
    local nGridNum = tSaleItemData.nGridNum
    local nNum = tSaleItemData.nNum
    assert(nItemID > 0 and nGridNum > 0 and nNum > 0, "参数错误")
    local oProp = oRole.m_oKnapsack:GetPropByBox(gtPropBoxType.eBag, tSaleItemData.nGridNum)
    if not oProp then
        oRole:Tips("物品不存在")
        return false
    end
    if oProp:GetID() ~= nItemID then  --检查商品ID一致性，主要防止客户端背包刷新问题，导致玩家错误出售商品
        oRole:Tips("物品ID不正确")
        return false
    end
    if oProp:IsBind() then
        oRole:Tips("绑定物品，无法出售")
        return false
    end
    local nGridItemNum = oProp:GetNum()
    if nGridItemNum <= 0 then
        oRole:Tips("物品不存在")
        return false
    end
    if nGridItemNum < nNum then
        oRole:Tips("物品数量不足")
        return false
    end
    if oProp:IsEquipment() then 
        if oProp:CheckGem() then 
            oRole:Tips("请先将宝石卸下")
            return false
        end
        if oProp:GetQualityLevel() ~= gtQualityColor.eWhite then 
            oRole:Tips("只能出售白色品质的装备")
            return false 
        end
    end
    local tCostList = {}
    for k, v in ipairs(tTaxList) do 
        table.insert(tCostList, {v.nType, v.nID, v.nNum})
    end
    if tCostList and #tCostList > 0 then 
        if not oRole:CheckSubShowNotEnoughTips(tCostList, "摆摊出售") then 
            return false
        end 
    end

    local tItemData = {}
    tItemData = oProp:SaveData()
    tItemData.m_nFold = nNum
    oRole.m_oKnapsack:SubGridItem(nGridNum, nItemID, nNum, "摆摊出售")
    return true, tItemData
end

function Srv2Srv.MarketSellItemListReq(nSrcServer, nSrcService, nTarSession, nRoleID,  tSaleItemList, tTaxList)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    assert(tSaleItemList and tTaxList, "参数错误")

    for k, tSaleItem in ipairs(tSaleItemList) do 
        local nItemID = tSaleItem.nItemID
        local nGridNum = tSaleItem.nGridNum
        local nNum = tSaleItem.nNum
        local oProp = oRole.m_oKnapsack:GetPropByBox(gtPropBoxType.eBag, nGridNum)
        if not oProp then
            oRole:Tips("物品不存在")
            return false
        end
        if oProp:GetID() ~= nItemID then  --检查商品ID一致性，主要防止客户端背包刷新问题，导致玩家错误出售商品
            oRole:Tips("物品ID不正确")
            return false
        end
        if oProp:IsBind() then
            oRole:Tips("绑定物品，无法出售")
            return false
        end
        local nGridItemNum = oProp:GetNum()
        if nGridItemNum <= 0 then
            oRole:Tips("物品不存在")
            return false
        end
        if nGridItemNum < nNum then
            oRole:Tips("物品数量不足")
            return false
        end
        if oProp:IsEquipment() then 
            if oProp:CheckGem() then 
                oRole:Tips("请先将宝石卸下")
                return false
            end
            if oProp:GetQualityLevel() ~= gtQualityColor.eWhite then 
                oRole:Tips("只能出售白色品质的装备")
                return false 
            end
        end
    end

    local tCostList = {}
    for k, v in ipairs(tTaxList) do 
        table.insert(tCostList, {v.nType, v.nID, v.nNum})
    end
    if tCostList and #tCostList > 0 then 
        if not oRole:CheckSubShowNotEnoughTips(tCostList, "摆摊出售") then 
            return false
        end 
    end

    -- local tItemDataList = {}
    for k, tSaleItem in ipairs(tSaleItemList) do 
        local nItemID = tSaleItem.nItemID
        local nGridNum = tSaleItem.nGridNum
        local nNum = tSaleItem.nNum
        local oProp = oRole.m_oKnapsack:GetPropByBox(gtPropBoxType.eBag, nGridNum)
        assert(oProp)
        local tItemData = oProp:SaveData()
        tItemData.m_nFold = nNum
        tSaleItem.tItemData = tItemData
        oRole.m_oKnapsack:SubGridItem(nGridNum, nItemID, nNum, "摆摊出售")
        -- table.insert(tItemDataList, tItemData)
    end
    return true, tSaleItemList
end



