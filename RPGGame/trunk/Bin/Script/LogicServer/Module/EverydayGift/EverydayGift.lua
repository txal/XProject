--每日礼包
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--这个配置，因为玩家记录了金额和道具ID， 所以当前不支持热更, 如果策划更改相关配置项，必须重启服务器
function CEverydayGift:Ctor(oRole)
    self.m_oRole = oRole
    self.m_tRewardStatus = {}   --奖励状态{[nMoney]={bCanGetReward=false, bIsReward=false}}
    self.m_nLastResetTime = os.time()   --上次重置时间
    self.m_tSelectGift = {}     --选择的物品{[nMoney]=nGiftID}          --有可能不领奖励就离线，所以要保存
    self.m_tRewardMap = {}      --奖励记录{[nMoney]={[PropID]=nTimes}}

    --??为什么要记录成 金额数量和道具ID ?????? why?
end

function CEverydayGift:LoadData(tData)
    if tData then
        self.m_tRewardStatus = tData.m_tRewardStatus or self.m_tRewardStatus
        self.m_nLastResetTime = tData.m_nLastResetTime or self.m_nLastResetTime
        self.m_tRewardMap = tData.m_tRewardMap or self.m_tRewardMap
        self.m_tSelectGift = tData.m_tSelectGift or self.m_tSelectGift
    end

    --防止策划改配置，做下兼容!!!!!
    local tRemoveList = {}
    for nMoney, _ in pairs(self.m_tRewardStatus) do 
        if not ctEverydayGiftConf[nMoney] then 
            table.insert(tRemoveList, nMoney)
        end
    end
    for _, nMoney in ipairs(tRemoveList) do 
        self.m_tRewardStatus[nMoney] = nil 
        self:MarkDirty(true)
    end

    local tRemoveList = {}
    for nMoney, _ in pairs(self.m_tSelectGift) do 
        if not ctEverydayGiftConf[nMoney] then 
            table.insert(tRemoveList, nMoney)
        end
    end
    for _, nMoney in ipairs(tRemoveList) do 
        self.m_tSelectGift[nMoney] = nil 
        self:MarkDirty(true)
    end

    local tRemoveList = {}
    for nMoney, _ in pairs(self.m_tRewardMap) do 
        if not ctEverydayGiftConf[nMoney] then 
            table.insert(tRemoveList, nMoney)
        end
    end
    for _, nMoney in ipairs(tRemoveList) do 
        self.m_tRewardMap[nMoney] = nil 
        self:MarkDirty(true)
    end

    --防止策划改配置，做下兼容!!!!!
    for nMoney, _ in pairs(ctEverydayGiftConf) do
        if not self.m_tRewardStatus[nMoney] then 
            self.m_tRewardStatus[nMoney] = {}
            self.m_tRewardStatus[nMoney].bCanGetReward = false
            self.m_tRewardStatus[nMoney].bIsReward = false
            self:MarkDirty(true)
        end
    end
end

function CEverydayGift:SaveData()
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)
    local tData = {}
    tData.m_tRewardStatus = self.m_tRewardStatus
    tData.m_nLastResetTime = self.m_nLastResetTime
    tData.m_tRewardMap = self.m_tRewardMap
    tData.m_tSelectGift = self.m_tSelectGift
    return tData
end

function CEverydayGift:GetType()
    return gtModuleDef.tEverydayGift.nID, gtModuleDef.tEverydayGift.sName
end

function CEverydayGift:OnRechargeSuccess(nMoney)
    assert(ctEverydayGiftConf[nMoney], "每日礼包配置错误,充值金额："..nMoney)
    --如果玩家多次充值呢？？？？？？ 可多次重复领取？？
    --屏蔽下, 异常玩家数据
    if not self:CanBuyAgain(nMoney) then 
        return
    end
    self.m_tRewardStatus[nMoney] = self.m_tRewardStatus[nMoney] or {}
    self.m_tRewardStatus[nMoney].bCanGetReward = true
    self.m_tRewardStatus[nMoney].bIsReward = false
    self:MarkDirty(true)
    self:SendStatusList()
end

function CEverydayGift:EverydayGiftInfoReq(nMoney)
    self:SendStatusList()
end

function CEverydayGift:SelectGift(nMoney, nGiftID)
    assert(ctEverydayGiftConf[nMoney] and nGiftID > 0, "每日礼包选择奖励错误, Money:"..nMoney.." nGiftID:"..nGiftID)
    local nRewardTimes = (self.m_tRewardMap[nMoney] and self.m_tRewardMap[nMoney][nGiftID]) or 0
    -- if nRewardTimes >= 1 then
    --     self.m_oRole:SendMsg("EverydayGiftSelectRet", {bIsCanSelect=false, nMoney=nMoney, nGiftID=nGiftID})
    --     return self.m_oRole:Tips("选择奖励的物品达到奖励次数上限")
    -- end
    local bCanSelect, sTips = self:CheckRewardCanSelect(nMoney, nGiftID)
    if not bCanSelect then 
        if sTips and type(sTips) == "string" then 
            self.m_oRole:Tips(sTips)
        end
        return 
    end
    local bIsInConf = false
    local tConf = ctEverydayGiftConf[nMoney]
    for nIndex, tGiftItem in pairs(tConf.tSelectGift) do
        if nGiftID == tGiftItem[2] then
            bIsInConf = true
        end
    end 
    if not bIsInConf then
        self.m_oRole:SendMsg("EverydayGiftSelectRet", {bIsCanSelect=false, nMoney=nMoney, nGiftID=nGiftID})
        return self.m_oRole:Tips("选择的奖励物品错误")
    end

    self.m_tSelectGift[nMoney] = nGiftID
    self.m_oRole:SendMsg("EverydayGiftSelectRet", {bIsCanSelect=true, nMoney=nMoney, nGiftID=nGiftID})
    self:MarkDirty(true)
end

function CEverydayGift:CheckRewardCanSelect(nMoney, nItemID) 
    if not nMoney or nMoney <= 0 or not nItemID or nItemID <= 0 then
        return false, "参数错误"
    end
    local tConf = ctEverydayGiftConf[nMoney]
    if not tConf then 
        return false, "参数错误"
    end

    local bValid = false
    for _, tItem in ipairs(tConf.tSelectGift) do 
        if tItem[2] > 0 and tItem[2] == nItemID then 
            bValid = true 
            break
        end
    end
    if not bValid then 
        return false, "参数错误"
    end

    local tMoneyRecord = self.m_tRewardMap[nMoney] or {}
    local nCounts = tMoneyRecord[nItemID] or 0 

    if nCounts >= 1 then 
        return false, "选择的奖励已达奖励次数上限"
    end
    return true
end

function CEverydayGift:SendExpiryReward()
    --不同天登录重置一下数据
    for nMoney, tData in pairs(self.m_tRewardStatus) do
        local tItemList = {}
        local tConf = ctEverydayGiftConf[nMoney]
        if tData.bCanGetReward and (not tData.bIsReward) and tConf then
            local nGiftID = self.m_tSelectGift[nMoney] or 0

            -- --如果没选择，默认给玩家选择一个
            -- if not nGiftID or nGiftID <= 0 then
            --     for _, tItem in ipairs(ctEverydayGiftConf[nMoney].tSelectGift) do 
            --         if self:CheckRewardCanSelect(tItem[2]) then 
            --             nGiftID = tItem[2]
            --             break
            --         end
            --     end
            -- end

            --选中的奖励
            if nGiftID and nGiftID > 0 then 
                for _, tItem in pairs(ctEverydayGiftConf[nMoney].tSelectGift) do
                    if tItem[1] > 0 and tItem[2] > 0 and tItem[3] > 0 and nGiftID == tItem[2] then
                        table.insert(tItemList, tItem)
                    end
                end
            end
            --必给的奖励
            for _, tItem in pairs(ctEverydayGiftConf[nMoney].tSureGift) do
                if tItem[1] > 0 and tItem[2] > 0 and tItem[3] > 0 then 
                    table.insert(tItemList, tItem)
                end
            end
            GF.SendMail(self.m_oRole:GetServer(), "每日礼包奖励", "每日礼包未领取奖励，现给予奖励，请查收。", tItemList, self.m_oRole:GetID())
        end
        self.m_tRewardMap[nMoney] = nil
        self.m_tRewardStatus[nMoney].bCanGetReward = false
        self.m_tRewardStatus[nMoney].bIsReward = false
    end
end

function CEverydayGift:DailyReset(nTimeStamp)
    nTimeStamp = nTimeStamp or os.time()
    self:SendExpiryReward()

    self.m_tRewardStatus = {} 
    self.m_nLastResetTime = nTimeStamp
    self.m_tSelectGift = {} 
    self.m_tRewardMap = {} 
    self:MarkDirty(true)
end

function CEverydayGift:GetEverydayGiftReq(nMoney)
    assert(ctEverydayGiftConf[nMoney], "每日礼包领取错误,礼包金额："..nMoney)
    if not (self.m_tRewardStatus[nMoney] and self.m_tRewardStatus[nMoney].bCanGetReward) then
        return self.m_oRole:Tips("请先充值")
    end
    --判断有么有领过，不同类型的物品领取
    if self.m_tRewardStatus[nMoney].bIsReward then
        return self.m_oRole:Tips("已领取过礼包")
    end

    --奖励玩家选择的奖励,这里可能会因为网络卡,连续充了几次,这种情况下自动帮选定物品
    local nGiftID = self.m_tSelectGift[nMoney]
    if (nGiftID or 0) <= 0 then
        local tRewardMap = self.m_tRewardMap[nMoney] or {}
        nGiftID = next(tRewardMap)
        if not nGiftID then
            return self.m_oRole:Tips("您没有选择要领取的奖励，请联系客服")
        end
        self.m_tSelectGift[nMoney] = nGiftID
    end

    self.m_tRewardStatus[nMoney] = self.m_tRewardStatus[nMoney] or {}
    self.m_tRewardStatus[nMoney].bIsReward = true
    self:MarkDirty(true)

    local function Reward(tItem)
        local nItemType = tItem[1]
        --奖励不包含称谓类型的
        assert(gtItemType.eNone <= nItemType and nItemType <gtItemType.eAppellation, "每日礼包配置错误，充值金额："..nMoney.." 物品类型为："..nItemType)
        if gtItemType.eProp == nItemType or gtItemType.eCurr == nItemType
            or gtItemType.ePet == nItemType or gtItemType.eFaBao == nItemType then
            self.m_oRole:AddItem(nItemType, tItem[2], tItem[3], "每日礼包奖励", false, tItem[4])
        
        elseif gtItemType.ePartner == nItemType then
            local nPartnerID = tItem[2]
            self.m_oRole.m_oPartner:AddPartner(nPartnerID, "每日礼包奖励")
        end
    end
    --必定奖励
    for _, tItem in pairs(ctEverydayGiftConf[nMoney].tSureGift) do
        Reward(tItem)
    end
    --选择奖励
    for _, tItem in pairs(ctEverydayGiftConf[nMoney].tSelectGift) do
        if nGiftID == tItem[2] then
            Reward(tItem)
            self.m_tSelectGift[nMoney] = 0
            self.m_tRewardMap[nMoney] = self.m_tRewardMap[nMoney] or {}
            self.m_tRewardMap[nMoney][nGiftID] = (self.m_tRewardMap[nMoney][nGiftID] or 0) + 1
            self:MarkDirty(true)
        end
    end

    self:SendStatusList()
end

function CEverydayGift:CanBuyAgain(nMoney)
    local tConf = assert(ctEverydayGiftConf[nMoney], "检查是否能再次购买参数错误, nMoney:"..nMoney)
    -- local bCanBuyAgain = false
    -- local tRecord = self.m_tRewardMap[nMoney] or {}
    -- for _, tItem in pairs(tConf.tSelectGift) do
    --     if (tRecord[tItem[2]] or 0) < 1 then
    --         bCanBuyAgain = true
    --     end
    -- end
    for _, tItem in pairs(tConf.tSelectGift) do 
        if self:CheckRewardCanSelect(nMoney, tItem[2]) then 
            return true  
        end
    end
    return false
end

function CEverydayGift:Online()
    --将上次没领的奖励发放
    if self.m_nLastResetTime > 0 and (not os.IsSameDay(self.m_nLastResetTime, os.time())) then
        -- --不同天登录重置一下数据
        -- for nMoney, tData in pairs(self.m_tRewardStatus) do
        --     local tItemList = {}
        --     local tConf = ctEverydayGiftConf[nMoney]
        --     if tData.bCanGetReward and (not tData.bIsReward) and tConf then
        --         --self:GetEverydayGiftReq(nMoney)
        --         local nGiftID = self.m_tSelectGift[nMoney]
        --         -- assert(nGiftID > 0, "没有奖励被选择的奖品, 选择的奖品ID:"..nGiftID)
        --         if not nGiftID or nGiftID <= 0 then --默认选择第一个
        --             nGiftID = tConf.tSelectGift[1][2]
        --         end
        --         --选中的奖励
        --         for _, tItem in pairs(ctEverydayGiftConf[nMoney].tSelectGift) do
        --             if tItem[1] > 0 and and tItem[2] > 0 and tItem[3] > 0 and nGiftID == tItem[2] then
        --                 table.insert(tItemList, tItem)
        --             end
        --         end
        --         --必给的奖励
        --         for _, tItem in pairs(ctEverydayGiftConf[nMoney].tSureGift) do
        --             if tItem[1] > 0 and and tItem[2] > 0 and tItem[3] > 0 then 
        --                 table.insert(tItemList, tItem)
        --             end
        --         end
        --         GF.SendMail(self.m_oRole:GetServer(), "每日礼包奖励", "每日礼包未领取奖励，现给予奖励，请查收。", tItemList, self.m_oRole:GetID())
        --     end
        --     self.m_tRewardMap[nMoney] = nil 
        --     self.m_tRewardStatus[nMoney].bCanGetReward = false
        --     self.m_tRewardStatus[nMoney].bIsReward = false
        -- end

        -- self.m_nLastResetTime = os.time()
        -- self:MarkDirty(true)

        self:DailyReset()
    end
    self:SendStatusList()
end

function CEverydayGift:OnHourTimer()
    if self.m_nLastResetTime > 0 and (not os.IsSameDay(self.m_nLastResetTime, os.time(), 0)) then
        -- --以记录数据为准清空数据(万一删了配置，保证旧数据也重置)
        -- for nMoney, tData in pairs(self.m_tRewardStatus) do
        --     local tItemList = {}
        --     if tData.bCanGetReward and (not tData.bIsReward) then
        --         --self:GetEverydayGiftReq(nMoney)
        --         local nGiftID = self.m_tSelectGift[nMoney] or 0
        --         --对没选择奖励物品的不奖励，做兼容
        --         --assert(nGiftID > 0, "没有奖励被选择的奖品, 选择的奖品ID:"..nGiftID)
        --         for _, tItem in pairs(ctEverydayGiftConf[nMoney].tSelectGift) do
        --             if nGiftID == tItem[2] then
        --                 table.insert(tItemList, tItem)
        --             end
        --         end

        --         for _, tItem in pairs(ctEverydayGiftConf[nMoney].tSureGift) do
        --             table.insert(tItemList, tItem)
        --         end
        --         GF.SendMail(self.m_oRole:GetServer(), "每日礼包奖励", "每日礼包未领取奖励，现给予奖励，请查收。", tItemList, self.m_oRole:GetID()) 
        --     end
        --     self.m_tRewardStatus[nMoney].bCanGetReward = false
        --     self.m_tRewardStatus[nMoney].bIsReward = false
        --     self.m_tRewardMap[nMoney] = nil
        -- end
        -- self.m_nLastResetTime = os.time()
        -- self:MarkDirty(true)
        -- self:SendStatusList()
        self:DailyReset()
        self:SendStatusList()
    end
end

function CEverydayGift:SendStatusList()
    local tMsg = {tGiftStatusList={}}
    --以配置为准显示状态(万一增删配置)
    for nMoney, tConf in pairs(ctEverydayGiftConf) do
        local tStatus = {}
        local nGiftStatus = 0
        local bCanGetReward = (self.m_tRewardStatus[nMoney] and self.m_tRewardStatus[nMoney].bCanGetReward) or false
        local bIsReward = (self.m_tRewardStatus[nMoney] and self.m_tRewardStatus[nMoney].bIsReward) or false 
        if bCanGetReward and bIsReward and (not self:CanBuyAgain(nMoney)) then
            nGiftStatus = 3         --已领取奖励(不能再次购买时)
        elseif bCanGetReward and not bIsReward then
            nGiftStatus = 2         --领取奖励(充值后还没领取奖励)
        else
            nGiftStatus = 1         --购买
        end
        tStatus.nMoney = nMoney
        tStatus.nStatus = nGiftStatus
        tStatus.tSelectGiftList = {}
        
        --以配置的数据去检查
        for nIndex, tItem in pairs(tConf.tSelectGift) do
            local nItemID = tItem[2]
            if tItem[1] > 0 and tItem[2] > 0 and tItem[3] > 0 then 
                local tItemStatus = {}
                tItemStatus.nGiftID = nItemID
                -- tItemStatus.bCanSelect = ((self.m_tRewardMap[nMoney] and self.m_tRewardMap[nMoney][tItem[2]] or 0) < 1) and true or false
                tItemStatus.bCanSelect = self:CheckRewardCanSelect(nMoney, nItemID)
                table.insert(tStatus.tSelectGiftList, tItemStatus)
            end
        end
        table.insert(tMsg.tGiftStatusList, tStatus)
    end
    self.m_oRole:SendMsg("EverydayGiftStatusRet", tMsg)
    --PrintTable(tMsg)
end