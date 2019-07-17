--开服目标折扣商店


function CGrowthTargetShop:Ctor() 
    --为了方便热更和策划修改配置，不单独记录商品数据
    --所有商品，实时读取配置表配置计算
    self.m_tItemRecordMap = {}  --{nIndexID:{nRoleID:tRecord, ...}, ...}
    self.m_tActItemConfMap = {}  --{nActID:{nItemID:tItemData, ...}, ...}

    self.m_tActMap = {}  --当前开启的活动
    self.m_bDirty = false
    self:ConfInit()
end

--reload时，也需要调用这个重新生成
function CGrowthTargetShop:ConfInit()
    self.m_tActItemConfMap = {}

    for nIndexID, tConf in pairs(ctGrowthTargetShopConf) do 
        for _, tActID in ipairs(tConf.tActList) do 
            local nActID = tActID[1]
            if nActID > 0 then 
                local tActItem = self.m_tActItemConfMap[nActID] or {}
                tActItem[nIndexID] = true
                -- table.insert(tActItem, nIndexID)
                self.m_tActItemConfMap[nActID] = tActItem
            end
        end
    end
end

function CGrowthTargetShop:LoadData()
    print("加载开服目标活动商店数据")
	local sData = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID()):HGet(gtDBDef.sGrowthTargetActDB, "GrowthTargetShop") 
    if sData ~= "" then 
        local tData = cjson.decode(sData)
        self.m_tItemRecordMap = tData.m_tItemRecordMap
        self.m_tActMap = tData.m_tActMap

        --清理下无效数据
        local tInvalidIndex = {}
        for nIndexID, _ in pairs(self.m_tItemRecordMap) do 
            if not ctGrowthTargetShopConf[nIndexID] then 
                table.insert(tInvalidIndex, nIndexID)
            end
        end
        for _, nIndexID in ipairs(tInvalidIndex) do 
            self.m_tItemRecordMap[nIndexID] = nil
            self:MarkDirty(true)
        end
    end

    self:UpdateActData()
end

--更新活动数据
--暂时不能放在活动事件回调中处理
--服务器开启时，活动管理器数据加载，会触发活动更新事件
--此时, 开服目标活动等相关数据并未加载
function CGrowthTargetShop:UpdateActData()
    local tOpenActList = goGrowthTargetMgr:GetOpenActList()
    self.m_tActMap = {}
    for _, nActID in pairs(tOpenActList) do 
        self.m_tActMap[nActID] = true
    end
    self:MarkDirty(true)

    local tRemoveList = {}
    for nIndexID, tRecord in pairs(self.m_tItemRecordMap) do 
        local tConf = ctGrowthTargetShopConf[nIndexID]
        local bActive = false
        for _, tActID in pairs(tConf.tActList) do 
            if self.m_tActMap[tActID[1]] then
                bActive = true 
                break 
            end 
        end
        if not bActive then 
            table.insert(tRemoveList, nIndexID)
        end
    end
    for _, nIndexID in ipairs(tRemoveList) do 
        self.m_tItemRecordMap[nIndexID] = nil
        self:MarkDirty(true)
    end
end

function CGrowthTargetShop:OnMinuTimer()
    -- self:UpdateActData() --防止数据错误，一分钟检查更新一次
end

function CGrowthTargetShop:SaveData()
    if not self:IsDirty() then 
        return 
    end

    local tData = {}
    tData.m_tItemRecordMap = self.m_tItemRecordMap
    tData.m_tActMap = self.m_tActMap

	goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID()):HSet(gtDBDef.sGrowthTargetActDB, "GrowthTargetShop", cjson.encode(tData))
	self:MarkDirty(false)
end

function CGrowthTargetShop:IsDirty()
    return self.m_bDirty
end

function CGrowthTargetShop:MarkDirty(bDirty)
    self.m_bDirty = bDirty
end

function CGrowthTargetShop:GetItemIndexMap()
    local tItemMap = {}
    for nActID, v in pairs(self.m_tActMap) do 
        local tActItem = self.m_tActItemConfMap[nActID]
        if tActItem then --可能对应活动没配置折扣道具
            for nItemIndex, _ in pairs(tActItem) do 
                tItemMap[nItemIndex] = true
            end
        end
    end
    return tItemMap
end

function CGrowthTargetShop:OnActStart(nActID) 
    self.m_tActMap[nActID] = true
    self:MarkDirty(true)
end

function CGrowthTargetShop:OnActAward(nActID)
    -- do something
    -- self:UpdateActData()
end

function CGrowthTargetShop:OnActClose(nActID)
    self.m_tActMap[nActID] = nil
    -- 检查此活动关联的道具是否还有其他开启的活动
    -- 如果没有，则清除 self.m_tItemRecordMap 数据
    local tActItem = self.m_tActItemConfMap[nActID]
    if tActItem then 
        for nIndexID, _ in pairs(tActItem) do 
            local tConf = ctGrowthTargetShopConf[nIndexID]
            for k, nTempActID in ipairs(tConf.tActList) do 
                if not self.m_tActMap[nTempActID] then 
                    self.m_tItemRecordMap[nIndexID] = nil
                end
            end
        end
        self:MarkDirty(true)
    end
end

function CGrowthTargetShop:GetItemRecordNum(nRoleID, nIndexID)
    local tIndexRecord = self.m_tItemRecordMap[nIndexID]
    if not tIndexRecord then 
        return 0
    end
    return tIndexRecord[nRoleID] or 0
end

function CGrowthTargetShop:AddItemRecordNum(nRoleID, nIndexID, nNum) 
    assert(ctGrowthTargetShopConf[nIndexID], "数据错误")
    local tItemRecord = self.m_tItemRecordMap[nIndexID] or {}
    tItemRecord[nRoleID] = (tItemRecord[nRoleID] or 0) + nNum
    self.m_tItemRecordMap[nIndexID] = tItemRecord
    self:MarkDirty(true)
end

function CGrowthTargetShop:IsNumLimit(nIndexID)
    local tConf = ctGrowthTargetShopConf[nIndexID]
    if tConf.nLimitNum > 0 then 
        return true, tConf.nLimitNum
    end
    return false, 0
end

function CGrowthTargetShop:CheckActPermit(nRoleID, nIndexID)
    local tConf = ctGrowthTargetShopConf[nIndexID]
    local bPermit = true 
    local sReason = nil
    for _, tActLimit in ipairs(tConf.tActLimit) do 
        local nActID = tActLimit[1]
        local nLimitVal = tActLimit[2]
        if nActID > 0 and nLimitVal > 0 then --只有配置了有效数据的才判断是否达到购买条件
            oAct = goHDMgr:GetActivity(nActID)
            if oAct and oAct:IsOpen() then 
                --任意一个满足即可
                if oAct:GetRoleActValue(nRoleID) >= nLimitVal then 
                    return true 
                else
                    bPermit = false
                    sReason = string.format("需要%s活动积分达到%d", oAct:GetName(), nLimitVal)
                end
            else
                bPermit = false
            end
        end
    end
    return bPermit, sReason
end

function CGrowthTargetShop:CheckCanBuyItem(nRoleID, nIndexID)
    local tItemMap = self:GetItemIndexMap()
    if not tItemMap or not tItemMap[nIndexID] then 
        return false, "当前无法购买"
    end

    local tConf = ctGrowthTargetShopConf[nIndexID]
    -- if tConf.nLimitNum > 0 and tConf.nLimitNum <= self:GetItemRecordNum(nRoleID, nIndexID) then 
    --     return false, "已达可购买数量上限"
    -- end
    local bNumLimit, nLimitNum = self:IsNumLimit(nIndexID)
    if bNumLimit and nLimitNum <= self:GetItemRecordNum(nRoleID, nIndexID) then 
        return false, "已达可购买数量上限"
    end
    --判断是否有购买条件限制，查询相关活动，是否满足条件
    local bPermit, sReason = self:CheckActPermit(nRoleID, nIndexID)
    if not bPermit then 
        return false, sReason
    end
    return bPermit
end

function CGrowthTargetShop:PurchaseItemReq(oRole, nIndexID, nNum) 
    -- assert(nIndexID > 0 and nNum > 0)
    if nIndexID <= 0 or nNum <= 0 then 
        oRole:Tips("参数错误")
        return 
    end
    local nRoleID = oRole:GetID()
    local bCanBuy, sReason = self:CheckCanBuyItem(oRole:GetID(), nIndexID)
    if not bCanBuy then 
        if sReason then 
            oRole:Tips(sReason)
        end
        return 
    end

    local bNumLimit, nLimitNum = self:IsNumLimit(nIndexID)
    if bNumLimit then
        nNum = math.min(nNum, nLimitNum - self:GetItemRecordNum(nRoleID, nIndexID)) 
    end
    if nNum <= 0 then 
        oRole:Tips("已达到可购买数量上限")
        return 
    end

    local tConf = ctGrowthTargetShopConf[nIndexID]
    assert(tConf and tConf.nItemID)
    local fnCostCallback = function(bSucc) 
        if not bSucc then 
            oRole:Tips("购买失败")
            return 
        end
        self:AddItemRecordNum(nRoleID, nIndexID, nNum)
        local tAddItem = {}
        table.insert(tAddItem, 
            {nType = gtItemType.eProp, nID = tConf.nItemID, nNum = nNum, bBind = true, })
        oRole:AddItem(tAddItem, "开服目标折扣商店购买")
        self:SyncShopInfo(oRole)
        oRole:Tips("购买成功")
    end

    --计算消耗，扣除道具
    local tCost = {}
    table.insert(tCost, 
        {nType = gtItemType.eCurr, nID = tConf.nCurrType, nNum = nNum*tConf.nDiscountPrice})
    oRole:SubItem(tCost, "开服目标折扣商店购买", fnCostCallback)
end

function CGrowthTargetShop:SyncShopInfo(oRole) 
    if not oRole or not oRole:IsOnline() then 
        return 
    end
    
    local nRoleID = oRole:GetID()
    local tMsg = {}
    local tShopItemList = {}

    local tItemIndexMap = self:GetItemIndexMap()
    for nIndexID, _ in pairs(tItemIndexMap) do 
        local tShopItem = {}
        local tConf = ctGrowthTargetShopConf[nIndexID]
        tShopItem.nIndexID = nIndexID
        tShopItem.nItemID = tConf.nItemID
        tShopItem.nCurrType = tConf.nCurrType
        tShopItem.nSrcPrice = tConf.nSrcPrice
        tShopItem.nDiscountRatio = tConf.nDiscountRatio
        tShopItem.nDiscountPrice = tConf.nDiscountPrice
        tShopItem.bNumLimit = tConf.nLimitNum > 0 and true or false
        if tShopItem.bNumLimit then 
            tShopItem.nLimitNum = tConf.nLimitNum
        end
        tShopItem.nRecordNum = self:GetItemRecordNum(nRoleID, nIndexID)
        --检查活动购买资格
        tShopItem.bActPermit = self:CheckActPermit(nRoleID, nIndexID)
        tShopItem.tActPermitVal = {}
        if not tShopItem.bActPermit then 
            --查询解锁购买资格所需条件
            local tConf = ctGrowthTargetShopConf[nIndexID]
            for _, tActLimit in ipairs(tConf.tActLimit) do 
                local nActID = tActLimit[1]
                local nLimitVal = tActLimit[2]
                if nActID > 0 and nLimitVal > 0 then
                    oAct = goHDMgr:GetActivity(nActID)
                    if oAct and oAct:IsOpen() then 
                        local tActPermit = {}
                        tActPermit.nActID = nActID
                        tActPermit.nVal = nLimitVal
                        tActPermit.nCurVal = oAct:GetRoleActValue(nRoleID)
                        table.insert(tShopItem.tActPermitVal, tActPermit)
                    end
                end
            end
        end

        table.insert(tShopItemList, tShopItem)
    end

    tMsg.tItemList = tShopItemList
    oRole:SendMsg("GrowthTargetActShopRet", tMsg)
    -- print("GrowthTargetActShopRet", tMsg)
end


