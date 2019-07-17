--角色对象中物品数量，添加物品，删除物品函数
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--取角色身上货币的函数映射表
local tCountFuncMap = {
    -- [gtCurrType.eVIP] = CRole.GetVIP,
    -- [gtCurrType.eYuanBao] = CRole.GetYuanBao,
    -- [gtCurrType.eBYuanBao] = CRole.GetBYuanBao,
    -- [gtCurrType.eJinBi] = CRole.GetJinBi,
    -- [gtCurrType.eYinBi] = CRole.GetYinBi,
    -- [gtCurrType.eVitality] = CRole.GetVitality,
    -- [gtCurrType.eExp] = CRole.GetExp,
    -- [gtCurrType.eStoreExp] = CRole.GetStoreExp,
    -- [gtCurrType.ePotential] = CRole.GetPotential,
    -- [gtCurrType.eJinDing] = CRole.GetJinDing,
    -- [gtCurrType.eFuYuan] = CRole.GetFuYuan,
    -- [gtCurrType.eChivalry] = CRole.GetChivalry,
    -- [gtCurrType.eArenaCoin] = CRole.GetArenaCoin,
    -- [gtCurrType.eLanZuan] = CRole.GetLanZuan,
}

--添加角色身上货币的函数映射表
local tAddFuncMap = {
    -- [gtCurrType.eYuanBao] = CRole.AddYuanBao,
    -- [gtCurrType.eBYuanBao] = CRole.AddBYuanBao,
    -- [gtCurrType.eJinBi] = CRole.AddJinBi,
    -- [gtCurrType.eYinBi] = CRole.AddYinBi,
    -- [gtCurrType.eVitality] = CRole.AddVitality,
    -- [gtCurrType.eExp] = CRole.AddExp,
    -- [gtCurrType.eStoreExp] = CRole.AddStoreExp,
    -- [gtCurrType.ePotential] = CRole.AddPotential,
    -- [gtCurrType.eJinDing] = CRole.AddJinDing,
    -- [gtCurrType.eFuYuan] = CRole.AddFuYuan,
    -- [gtCurrType.eChivalry] = CRole.AddChivalry,
    -- [gtCurrType.eArenaCoin] = CRole.AddArenaCoin,
    -- [gtCurrType.eLanZuan] = CRole.AddLanZuan,
    -- [gtCurrType.eActValue] = CRole.AddActValue,
    -- --[gtCurrType.eShuangBei] = CRole.AddShuangBei,
}

--是否货币
function CRole:IsCurrency(nItemType, nItemID)
    if nItemType == gtItemType.eCurr then
        return true
    end
    if nItemType == gtItemType.eProp then
        local tConf = assert(ctPropConf[nItemID], "道具不存在:"..nItemID)
        if tConf.nType == gtPropType.eCurr then
            return true
        end
    end
    return false
end

--物品数量
function CRole:ItemCount(nItemType, nItemID)
    -- print("nItemID", nItemID)
    if nItemType == gtItemType.eProp then
        local tConf = assert(ctPropConf[nItemID], "道具不存在:"..nItemID)
        if tConf.nType == gtPropType.eCurr then
            if nItemID == 1 then --1号道具消耗时走通用元宝(先绑,后非绑),增加时是非绑定
                return self:ItemCount(gtItemType.eCurr, gtCurrType.eAllYuanBao)
            end
            return self:ItemCount(gtItemType.eCurr, tConf.nSubType)
        else
            return self.m_oKnapsack:ItemCount(nItemID)
        end
    end
    if nItemType == gtItemType.eCurr then
        if nItemID == gtCurrType.ePartnerStoneGreen 
            or nItemID == gtCurrType.ePartnerStoneBlue 
            or nItemID == gtCurrType.ePartnerStonePurple 
            or nItemID == gtCurrType.ePartnerStoneOrange then
                return self.m_oPartner:GetPartnerStoneNum(nItemID)
        end
        if nItemID == gtCurrType.ePartnerStoneCollect then
            return self.m_oPartner:GetMaterialCollectCount()
        end
        if nItemID == gtCurrType.eAllYuanBao then
            return self:GetYuanBao()+self:GetBYuanBao()
        end
        if nItemID == gtCurrType.eDrawSpirit then 
            return self.m_oDrawSpirit:GetSpirit()
        end
        if nItemID == gtCurrType.eMagicPill then 
            return self.m_oDrawSpirit:GetMagicPill()
        end
        if nItemID == gtCurrType.eEvilCrystal then 
            return self.m_oDrawSpirit:GetCrystal()
        end

        local fnCountFunc = tCountFuncMap[nItemID]
        if fnCountFunc then
            return fnCountFunc(self)
        end
        assert(false, "不支持货币类型:"..nItemID)

    end
    assert(false, "不支持物品类型:"..nItemType)
end

--添加物品(数量负数表示扣除)
--@bRawExp 不受加成影响(经验) --新加调用，建议填写到 tPropExt.bRawExp 字段
--@bBind 是否绑定(道具)
--@tPropExt 道具额外信息(比如道具来源,用来生成不同初始属性的道具)
--@bNotSync 是否不同步(避免发太多包给客户端),为true则要在外层手动同步
function CRole:AddItem(nItemType, nItemID, nItemNum, sReason, bRawExp, bBind, tPropExt, bNotSync)
    assert(sReason, "添加物品原因缺失")
    tPropExt = tPropExt or {}
    if not (nItemType > 0 and nItemID > 0 and nItemNum) then
        return self:Tips("参数错误:"..nItemType..":"..nItemID..":"..nItemNum)
    end
    nItemNum = math.floor(nItemNum)
    if nItemNum == 0 then
        return
    end

    local xRes = false 
    if nItemType == gtItemType.eProp then
    --道具逻辑
        local tConf = ctPropConf[nItemID]
        if not tConf then
            return self:Tips("道具配置不存在:"..nItemID)
        end

        if tConf.nType == gtPropType.eCurr then
            if nItemID == 1 and nItemNum < 0 then --1号道具消耗时走通用元宝(先绑,后非绑),增加时是非绑定
                return self:AddItem(gtItemType.eCurr, gtCurrType.eAllYuanBao, nItemNum, sReason, bRawExp, bBind, tPropExt, bNotSync)
            end
            return self:AddItem(gtItemType.eCurr, tConf.nSubType, nItemNum, sReason, bRawExp, bBind, tPropExt, bNotSync)

        else   
            if nItemNum > 0 then
                if tConf.nType == gtPropType.eFaBao then
                    return self:AddItem(gtItemType.eFaBao, nItemID, nItemNum, sReason, bRawExp, bBind, tPropExt, bNotSync)
                else
                    CUtil:SendItemTalk(self, "getitem", {nItemID, nItemNum}, bNotSync)
                    xRes = self.m_oKnapsack:AddItem(nItemID, nItemNum, bBind, tPropExt, bNotSync)
                end
            else
                xRes = self.m_oKnapsack:SubItem(nItemID, math.abs(nItemNum), bNotSync)
            end

        end

    elseif nItemType == gtItemType.ePet then
        CUtil:SendItemTalk(self, "getpet", {nItemID, nItemNum}, bNotSync) --发送个人频道
        xRes = self.m_oPet:AddPetObj(nItemID, nItemNum, tPropExt)

    elseif nItemType == gtItemType.eFaBao then
         --getfb
        CUtil:SendItemTalk(self, "getfb", {nItemID, nItemNum}, bNotSync) --发送个人频道
        xRes = self.m_oFaBao:AddFaBao(nItemID, nItemNum, bBind, tPropExt)

    elseif nItemType == gtItemType.ePartner then
        -- CUtil:SendItemTalk(self, "getpartner", {nItemID, nItemNum}, bNotSync) --发送个人频道(策划仙侣不用)
        xRes = self.m_oPartner:AddPartner(nItemID)

    elseif nItemType == gtItemType.eCurr then
        if nItemID ~= gtCurrType.ePetExp and nItemNum > 0 then
            local nPropID = ctPropConf:GetCurrProp(nItemID)
            if nPropID then --发送个人频道 
                CUtil:SendItemTalk(self, "getitem", {nPropID, nItemNum}, bNotSync)
            end
        end

        if nItemID == gtCurrType.ePracticeExp then
            xRes = self.m_oPractice:AddItem(nItemNum)

        elseif nItemID == gtCurrType.ePetExp then
            self.m_oPet:AddExp(nItemNum, sReason, bNotSync)

        elseif nItemID == gtCurrType.ePartnerStoneGreen 
            or nItemID == gtCurrType.ePartnerStoneBlue 
            or nItemID == gtCurrType.ePartnerStonePurple 
            or nItemID == gtCurrType.ePartnerStoneOrange then
                xRes = self.m_oPartner:AddPartnerStoneNum(nItemID, nItemNum)

        elseif nItemID == gtCurrType.ePartnerStoneCollect then
            xRes = self.m_oPartner:AddMaterialCollectCount(nItemNum)

        elseif nItemID == gtCurrType.eUnionContri then
            --日志交由真正加货币的地方写
            Network.oRemoteCall:Call("AddUnionContriReq", self:GetServer(), 20, self:GetSession(), self:GetID(), nItemNum, sReason)

        elseif nItemID == gtCurrType.eUnionExp then
            --日志交由真正加货币的地方写
            Network.oRemoteCall:Call("AddUnionExpReq", self:GetServer(), 20, self:GetSession(), self:GetID(), nItemNum, sReason)

        elseif nItemID == gtCurrType.eAllYuanBao and nItemNum < 0 then
            return self:UseGoldAll(nItemNum, sReason)

        elseif nItemID == gtCurrType.eDrawSpirit then 
            xRes = self.m_oDrawSpirit:AddSpirit(nItemNum, sReason, bNotSync)
        elseif nItemID == gtCurrType.eMagicPill then 
            xRes = self.m_oDrawSpirit:AddMagicPill(nItemNum, sReason,bNotSync)
        elseif nItemID == gtCurrType.eEvilCrystal then 
            xRes = self.m_oDrawSpirit:AddCrystal(nItemNum, sReason, bNotSync)
        else 
            local tAddFunc = tAddFuncMap[nItemID]
            if tAddFunc then
                if nItemID == gtCurrType.eExp then
                    if not bRawExp then 
                        bRawExp = tPropExt.bRawExp and true or false
                    end
                    xRes = tAddFunc(self, nItemNum, bRawExp, bNotSync)
                else
                    xRes = tAddFunc(self, nItemNum, bNotSync)
                end
            else
                return self:Tips("不支持货币类型:"..nItemID)
            end
        end

    elseif nItemType == gtItemType.eAppellation then 
        local tAppeConf = assert(ctAppellationConf[nItemID], "称号配置不存在:"..nItemID)
        assert(tAppeConf.nType == 1 or tAppeConf.nType == 2, "非普通称谓，不可直接掉落")
        local tParam = nil
        local nSubKey = 0
        local tExtData = tPropExt.tAppellation
        if tExtData then 
            tParam = tExtData.tParam or {}
            nSubKey = tExtData.nSubKey or 0
        end
        xRes = self:AddAppellation(nItemID, tParam, nSubKey, sReason)
    else
        return self:Tips("不支持物品类型:"..nItemType)
    end

    self.m_oDrawSpirit:UpdateLevelUpTips(true)

    --日志
    if xRes then
        if not string.find(sReason, "挂机") then --挂机奖励日志不入库
            local nEventID = nItemNum > 0 and gtEvent.eAddItem or gtEvent.eSubItem
            goLogger:AwardLog(nEventID, sReason, self, nItemType, nItemID, math.abs(nItemNum), xRes)
        end
    end

    return xRes
end

--添加物品列表 背包满时，会打包发送邮件
--tItemList{{nType=0, nID=0, nNum=0, bBind=false, tPropExt={}}, ...}
--@bNotSync 是否不同步(避免发太多包给客户端,如果为true则要在外层手动同步)
function CRole:AddItemList(tItemList, sReason, bNotSync)
    assert(tItemList and sReason, "参数错误")
    if #tItemList < 1 then 
        return 
    end
    for _, tTempItem in ipairs(tItemList) do 
        assert(tTempItem.nType > 0 and tTempItem.nID > 0 and tTempItem.nNum >= 0, sReason..tostring(tItemList))
    end

    bNotSync = bNotSync and true or false

    local tMailList = {}
    local bMailTips = false
    for _, tItem in ipairs(tItemList) do 
        local nItemType = tItem.nType
        local nItemID = tItem.nID
        local nItemNum = tItem.nNum

        --如果不占用背包格子，直接添加
        if not self.m_oKnapsack:IsOccupyBagGrid(nItemType, nItemID) then
            self:AddItem(nItemType, nItemID, nItemNum, sReason, nil, tItem.bBind, tItem.tPropExt, bNotSync)
        else
            local nLimitNum = self.m_oKnapsack:GetRemainCapacity(nItemID, tItem.bBind) 
            local nAddNum = math.min(nLimitNum, nItemNum)
            local nMailNum = nItemNum - nAddNum
            if nAddNum > 0 then 
                self:AddItem(nItemType, nItemID, nAddNum, sReason, nil, tItem.bBind, tItem.tPropExt, bNotSync)
            end
            if nMailNum > 0 then
                local tMailItem = {nItemType, nItemID, nMailNum, tItem.bBind and true or false, tItem.tPropExt}
                table.insert(tMailList, tMailItem)
                if #tMailList >= gtGDef.tConst.nMaxMailItemLength then 
                    CUtil:SendMail(self:GetServer(), "背包已满", "背包已满，请及时领取邮件", tMailList, self:GetID())
                    tMailList = {}
                    bMailTips = true
                end
            end
        end
    end

    if #tMailList > 0 then 
        CUtil:SendMail(self:GetServer(), "背包已满", "背包已满，请及时领取邮件", tMailList, self:GetID())
        bMailTips = true
    end

    if bMailTips then 
        self:Tips("背包空间不足，请及时清理背包")
    end

    if bNotSync then
        --外层手动处理
    else
        --同步缓存的同步消息(背包,货币,聊天频道物品信息)
        self.m_oKnapsack:SyncCachedMsg()
    end
    return true
end

--直接扣除物品
--@bBind 是否绑定(道具)
--@tPropExt 道具额外信息(比如道具来源,用来生成不同初始属性的道具)
--@bNotSync 是否不同步(避免发太多包给客户端),为true则需要外层手动调用同步
function CRole:SubItem(nItemType, nItemID, nItemNum, sReason, bBind, tPropExt, bNotSync)
    assert(sReason, "扣除物品原因缺失")
    if not (nItemType > 0 and nItemID > 0 and nItemNum >= 0) then
        return self:Tips("参数错误")
    end
    if nItemNum == 0 then
        return
    end
    return self:AddItem(nItemType, nItemID, -nItemNum, sReason, nil, bBind, tPropExt, bNotSync)
end

--扣除物品列表
--@bNotSync 是否不同步(避免发太多包给客户端)，为true则需要外层手动调用同步
function CRole:SubItemList(tItemList, sReason, bNotSync)
    assert(sReason, "扣除物品原因缺失")
    for _, tItem in ipairs(tItemList) do
        self:SubItem(tItem[1], tItem[2], tItem[3], sReason, tItem.bBind, tItem.tPropExt, true)
    end

    if bNotSync then
        --外层手动处理
    else
        --同步缓存的同步消息(背包,货币,聊天频道物品信息)
        self.m_oKnapsack:SyncCachedMsg()
    end
    return true
end

--检测并扣除物品(物品不足会返回false)
function CRole:CheckSubItem(nItemType, nItemID, nItemNum, sReason)
    return self:CheckSubItemList({{nItemType, nItemID, nItemNum}}, sReason)
end

--检测并扣除物品列表(物品不足会返回false)
--@tItemList {{类型,ID,数量}, ...}
function CRole:CheckSubItemList(tItemList, sReason)
    assert(sReason, "扣除物品原因缺失")
    if #tItemList == 0 then
        return true
    end
        --先合并下，防止列表存在多个同ID道具或者货币类型道具
    local tNewItemList, tCurrMap = self:ItemListMerge(tItemList, true, true)
    if not self:CheckYuanbaoEnough(tCurrMap[gtCurrType.eYuanBao], tCurrMap[gtCurrType.eBYuanBao], 
        tCurrMap[gtCurrType.eAllYuanBao]) then 
        return false
    end
    
    for _, tItem in ipairs(tNewItemList) do
        if not (tItem[1]> 0 and tItem[2] > 0 and tItem[3] >=0) then
            self:Tips("参数错误")
            return false
        end
        if self:ItemCount(tItem[1], tItem[2]) < tItem[3] then
            return false
        end
    end
    self:SubItemList(tNewItemList, sReason)
    return true
end

--传输物品列表
--@bNotSync 是否不同步(避免发太多包给客户端)，为true则需要外层手动调用同步
function CRole:TransferItemList(tPropDataList, sReason, bNotSync)
    assert(tPropDataList and sReason, "参数错误")
    if #tPropDataList <= 0 then
        return
    end
	local tTempList = table.DeepCopy(tPropDataList) --深拷贝一下，防止外层继续使用tPropDataList导致错误
    while #tTempList > 0 and self.m_oKnapsack:GetFreeGridCount() > 0 do 
        local tPropData = tTempList[1]
        local tConf = ctPropConf[tPropData.m_nID]
        if tConf then
            assert(tConf.nType ~= gtPropType.eCurr, "道具类型错误")
            local xRes = self.m_oKnapsack:TransferItem(tPropData, true)
            goLogger:AwardLog(gtEvent.eAddItem, sReason, self, gtItemType.eProp, tPropData.m_nID, tPropData.m_nFold, xRes)
            table.remove(tTempList, 1)
        else
            LuaTrace(self:GetID(), self:GetName(),  "道具配置不存在,道具ID:", tPropData.m_nID)
        end
	end

	if #tTempList > 0 then  --打包整合一起发送邮件
		CUtil:SendMail(self:GetServer(), "背包已满", "背包已满，请及时领取邮件", tTempList, self:GetID())
		self:Tips("背包空间不足，请及时清理背包")
    end

    if bNotSync then
        --外层手动处理
    else
        --同步背包缓存的同步消息
        self.m_oKnapsack:SyncCachedMsg()
    end
    return true 
end

--使用元宝(绑定元宝优先非绑定元宝)
function CRole:UseGoldAll(nNumUsed, sReason)
    assert(nNumUsed <= 0 and sReason, "使用元宝参数错误")
    if nNumUsed == 0 then return end

    local nHadBindGold = self:ItemCount(gtItemType.eCurr, gtCurrType.eBYuanBao)
    local nHadGold = self:ItemCount(gtItemType.eCurr, gtCurrType.eYuanBao)
    local nNeedNum = math.abs(nNumUsed)
    if nNeedNum > nHadBindGold + nHadGold then
        return self:SendMsg("GoldAllNotEnoughtRet", {})
    end

    if nHadBindGold >= nNeedNum then
        self:AddItem(gtItemType.eCurr, gtCurrType.eBYuanBao, nNumUsed, sReason)
    else
        local nNeedGold = nNeedNum - nHadBindGold
        self:AddItem(gtItemType.eCurr, gtCurrType.eBYuanBao, -nHadBindGold, sReason)
        self:AddItem(gtItemType.eCurr, gtCurrType.eYuanBao, -nNeedGold, sReason)
    end
    return true
end

-- --检查使用元宝补足道具,返回值1，玩家该类道具实际消耗数量，2补足需要消耗的元宝
-- function CRole:CheckItemAddByYuanbao(nItemType, nItemID, nItemNum)
--     assert(nItemType and nItemID and nItemNum and nItemNum > 0, "参数错误")
--     assert(nItemType == gtItemType.eProp, "道具类型错误") --暂时只支持物品道具
--     local nRoleKeepNum = self:ItemCount(nItemType, nItemID)
--     if nRoleKeepNum >= nItemNum then
--         return nItemNum, 0
--     else
--         local nItemPrice = ctPropConf[nItemID].nBuyPrice
--         return nRoleKeepNum, ((nItemNum - nRoleKeepNum) * nItemPrice)
--     end
-- end

function CRole:ShowNotEnoughTips(nItemType, nItemID, nItemNum)
    assert(nItemType and nItemID and nItemID > 0, "参数错误")
    local sTipsContent = nil
    if nItemType == gtItemType.eProp then
        local sPropName = ctPropConf:GetFormattedName(nItemID)
        if nItemNum and nItemNum > 0 then
            sTipsContent = string.format("缺少%d%s", nItemNum, sPropName)
        else
            sTipsContent = string.format("%s不足", sPropName)
        end
    elseif nItemType == gtItemType.eCurr then
        if nItemID == gtCurrType.eYuanBao or nItemID == gtCurrType.eBYuanBao or nItemID == gtCurrType.eAllYuanBao then 
            self:YuanBaoTips()
        elseif nItemID == gtCurrType.eJinBi then 
            self:JinBiTips()
        elseif nItemID == gtCurrType.eYinBi then 
            self:YinBiTips()
        elseif nItemID == gtCurrType.eMagicPill then
            self:MagicPillTips()
        else
            local sCurrName = gtCurrName[nItemID]
            if not sCurrName then  --不存在的默认不提示
                print("货币ID:"..nItemID.."名称不存在")
                return 
            end
            if nItemNum and nItemNum > 0 then
                sTipsContent = string.format("缺少%d%s", nItemNum, sCurrName)
            else
                sTipsContent = string.format("%s不足", sCurrName)
            end
        end
    else
        --assert(false, "不受支持的类型:"..nItemType)
        print("不受支持的类型:"..nItemType..", ID:"..nItemID)
    end
    if sTipsContent then
        self:Tips(sTipsContent)
    end
end

--返回值, 是否有足够元宝  bool, eCurrType(不足的元宝货币类型)
--如果参数为nil, 默认作为0处理
function CRole:CheckYuanbaoEnough(nYuanbao, nBYuanbao, nAllYuanbao)
    nYuanbao = nYuanbao or 0
    nBYuanbao = nBYuanbao or 0
    nAllYuanbao = nAllYuanbao or 0
    local nRoleYuanbao = self:ItemCount(gtItemType.eCurr, gtCurrType.eYuanBao)
    local nRoleBYuanbao = self:ItemCount(gtItemType.eCurr, gtCurrType.eBYuanBao)
    local nRoleAllYuanbao = self:ItemCount(gtItemType.eCurr, gtCurrType.eAllYuanBao)
    if nRoleYuanbao < nYuanbao then --优先检查非绑定的
        return false, gtCurrType.eYuanBao
    end
    if nRoleAllYuanbao < nAllYuanbao then 
        return false, gtCurrType.eAllYuanBao
    end
    if nRoleBYuanbao < nBYuanbao then 
        return false, gtCurrType.eBYuanBao
    end

    local nRemainYuanbao = nRoleYuanbao - nYuanbao
    local nRemainBYuanbao = nRoleBYuanbao - nBYuanbao
    local nRemainAllYuanbao = nRemainYuanbao + nRemainBYuanbao  --扣除绑定和非绑定的元宝后, 还剩余的通用元宝
    if nRemainAllYuanbao < nAllYuanbao then 
        return false, gtCurrType.eAllYuanBao
    end
    return true
end

--检查消耗的时候提示，返回true，检查通过，消耗成功
--tItemList  {{ItemType, ItemID/CurrType, Num},}
--bFirstBreak，是否检查到的第一个不足的材料时直接提示并跳出，false提示所有不足的材料 --废弃，默认遇到第一个就跳出
--bNum，是否提示具体的缺少数量
--bNotSync 同上
function CRole:CheckSubShowNotEnoughTips(tItemList, sReason, bFirstBreak, bNum, bNotSync)
    assert(tItemList and sReason, "参数错误")
    if #tItemList == 0 then
        return true
    end
    --先合并下，防止列表存在多个同ID道具或者货币类型道具
    local tNewItemList, tCurrMap = self:ItemListMerge(tItemList, true, true)
   local bYuanbaoEnough, nYuanbaoType= self:CheckYuanbaoEnough(tCurrMap[gtCurrType.eYuanBao], 
        tCurrMap[gtCurrType.eBYuanBao], tCurrMap[gtCurrType.eAllYuanBao])
    if not bYuanbaoEnough then 
        self:ShowNotEnoughTips(gtItemType.eCurr, nYuanbaoType)
        return false
    end
    tItemList = tNewItemList --内部重新引用合并后的新列表

    local bEnough = true
    for _, tItem in ipairs(tItemList) do
        if tItem[3] <= 0 then 
            LuaTrace("物品数量错误")
            return false 
        end
        if self:ItemCount(tItem[1], tItem[2]) < tItem[3] then
            if bNum then
                self:ShowNotEnoughTips(tItem[1], tItem[2], tItem[3] - self:ItemCount(tItem[1], tItem[2]))
            else
                self:ShowNotEnoughTips(tItem[1], tItem[2])
            end
            -- if bFirstBreak then
            --     return false
            -- end
            -- bEnough = false
            return false
        end
    end

    if not bEnough then
        return false
    end

    self:SubItemList(tItemList, sReason, bNotSync)
    return true
end

--给玩家发送系统邮件
function CRole:SendSysMail(sTitle, sContent, tItemList, fnCallback)
    assert(sTitle and sContent and tItemList, "参数错误")
    local nServerID = self:GetServer()
    local nService = goServerMgr:GetGlobalService(nServerID, 20)
    if fnCallback then
        Network.oRemoteCall:CallWait("SendMailReq", fnCallback, nServerID, nService, 0, sTitle, sContent, tItemList, self:GetID())
    else
        Network.oRemoteCall:Call("SendMailReq", nServerID, nService, 0, sTitle, sContent, tItemList, self:GetID())
    end
end

function CRole:GetItemDetailData(nItemType, nKey)
    if nItemType == gtItemType.eProp then 
        local oItem, nBoxType, nGrid = self.m_oKnapsack:GetItemByKey(nKey)
        if not oItem then 
            return nil, "道具不存在"
        end
        local tData = self.m_oKnapsack:GetPropDetailInfo(oItem, nBoxType, nGrid)
        if tData then 
            return tData
        else
            return nil, "道具详细信息未实现"
        end
    elseif nItemType == gtItemType.ePet then 
        local oPetModule = self.m_oPet
        local oPet = oPetModule:GetPetByPos(nKey)
        if not oPet then 
            return nil, "宠物不存在"
        end
        local tPetInfo = oPetModule:PetInfoHandle(oPet)
        return tPetInfo
    else
        return nil, "不受支持的类型"
    end
end

--是否有在商会出售
function CRole:IsCommerceSale(nItemType, nItemID)
    if nItemType ~= gtItemType.eProp then 
        return false 
    end 
    return ctCommerceItem[nItemID] and true or false 
end

--查询商会出售价格
--tItemList, {{nItemType = , nItemID = }, ...}
--fnCallback(bSuccess, tItemPriceList) --{{nItemType = , nItemID = , nPrice = }, ...} 
function CRole:QueryCommercePrice(tItemList, fnCallback)
    assert(tItemList and fnCallback, "参数错误")
    for _, tItem in pairs(tItemList) do 
        assert(self:IsCommerceSale(tItem.nItemType, tItem.nItemID), "非商城出售道具"..tItem.nItemID)
    end
    local nServerID = self:GetServer()
    local nService = goServerMgr:GetGlobalService(nServerID, 20)
    Network.oRemoteCall:CallWait("QueryCommercePriceReq", fnCallback, 
        nServerID, nService, 0, tItemList)
end

--排重合并道具、转换货币类道具
function CRole:ItemListMerge(tItemList, bFilterZeroAndNegative, bTransCurrProp) 
    local tTempMap = {}
    for _, tItem in pairs(tItemList) do 
        local nItemType, nItemID, nItemNum = tItem[1], tItem[2], tItem[3]
        assert(nItemType > 0 and nItemID > 0, "参数错误")
        if (not bFilterZeroAndNegative) or nItemNum > 0 then 
            if bTransCurrProp and nItemType == gtItemType.eProp then 
                --货币类型道具转换处理
                local tPropConf = ctPropConf[nItemID]
                assert(tPropConf, "道具配置不存在"..nItemID)
                if tPropConf.nType == gtPropType.eCurr then 
                    nItemType = gtItemType.eCurr
                    nItemID = tPropConf.nSubType
                end
            end
            local tTempTbl = tTempMap[nItemType] or {} 
            tTempTbl[nItemID] = (tTempTbl[nItemID] or 0) + nItemNum
            tTempMap[nItemType] = tTempTbl
        end
    end 
    local tNewItemList = {} --参数引用新的table
    local tCurrMap = {}  --其中包含的元宝数量, 因为某些货币, 比如元宝需要单独检查
    for nItemType, tItemTbl in pairs(tTempMap) do 
        for nItemID, nItemNum in pairs(tItemTbl) do 
            table.insert(tNewItemList, {nItemType, nItemID, nItemNum})
            if nItemType == gtItemType.eCurr then 
                tCurrMap[nItemID] = (tCurrMap[nItemID] or 0) + nItemNum
            end
        end
    end
    return tNewItemList, tCurrMap
end

--tItemList {{[1]=nItemType, [2]=nItemID, [3]=nItemNum}, ...}
--bNotUseYuanbao 不使用元宝补足
--fnCallback(bSuccess, nYuanbao) --扣除道具和元宝成功，回调参数为true, nYuanbao，补足道具所消耗的元宝数量
--如果玩家道具不足，这个函数内部会进行提示, 外层或回调中无需重复提示
--只有道具类物品且可在商会购买或配置了默认价格，才会去进行元宝补足，非道具类物品，会直接提示物品数量不足
--当前不考虑道具列表重复多个或者货币类道具自动合并问题，外层使用时，需注意
function CRole:SubItemByYuanbao(tItemList, sReason, fnCallback, bNotUseYuanbao)
    assert(sReason and fnCallback, "参数错误")
    if bNotUseYuanbao then --非元宝补足
        if not self:CheckSubShowNotEnoughTips(tItemList, sReason, true) then 
            return fnCallback(false)
        end
        return fnCallback(true, 0)
    end

    local tSubList = {}
    local tYuanbaoAdd = {}
    local tQueryList = {}

    local nDefaultYuanbaoCost = 0  --价格读取默认配置的道具，补足，需要花费的元宝
    for _, tItem in ipairs(tItemList) do 
        assert(tItem[1] > 0 and tItem[2] > 0 and tItem[3] >= 0, "参数错误")
        if tItem[3] > 0 then 
            local nItemType, nItemID, nItemNum = tItem[1], tItem[2], tItem[3]
            local nKeepNum = self:ItemCount(nItemType, nItemID)
            if nKeepNum >= nItemNum then
                table.insert(tSubList, {nItemType, nItemID, nItemNum})
            else
                if nKeepNum > 0 then 
                    table.insert(tSubList, {nItemType, nItemID, nKeepNum})
                end
                local nAddNum = nItemNum - nKeepNum
                if nItemType == gtItemType.eProp or nItemType == gtItemType.eFaBao then
                    local tPropConf = ctPropConf[nItemID]
                    if self:IsCommerceSale(nItemType, nItemID) then --可在商会购买的道具
                        table.insert(tYuanbaoAdd, {nItemType, nItemID, nAddNum})
                        table.insert(tQueryList, {nItemType = nItemType, nItemID = nItemID})
                    elseif tPropConf.nBuyPrice > 0 then  --不在商会购买且配置了元宝补足价格的道具
                        local nItemPrice = math.ceil(ctPropConf[nItemID].nBuyPrice)
                        nDefaultYuanbaoCost = nDefaultYuanbaoCost + (nAddNum * nItemPrice)
                    else
                        self:ShowNotEnoughTips(nItemType, nItemID) 
                        return fnCallback(false)
                    end
                else --非道具类
                    self:ShowNotEnoughTips(nItemType, nItemID) 
                    return fnCallback(false)
                end
            end
        end
    end

    local nRoleID = self:GetID()
    local fnQueryCallback = function(bSuccess, tItemPriceList) 
        if not bSuccess then 
            return fnCallback(false) 
        end
        assert(tItemPriceList)
        if self:IsReleased() then --rpc期间，角色释放
            return fnCallback(false)
        end
        
        local nYuanbaoAddNum = nDefaultYuanbaoCost
        if #tYuanbaoAdd > 0 then 
            local fnGetPrice = function(nItemType, nItemID) 
                for k, tPriceData in pairs(tItemPriceList) do 
                    if tPriceData.nItemType == nItemType and 
                        tPriceData.nItemID == nItemID then 
                        return tPriceData.nPrice
                    end
                end
            end

            --计算花费
            local nTotalCost = 0
            for _, tItem in ipairs(tYuanbaoAdd) do 
                local nPrice = fnGetPrice(tItem[1], tItem[2])
                if not nPrice or nPrice <= 0 then --没查询到或者数据错误
                    return fnCallback(false)
                end
                nTotalCost = nTotalCost + math.ceil(nPrice * tItem[3])
            end

            if nTotalCost > 0 then 
                nYuanbaoAddNum = nYuanbaoAddNum + math.ceil(nTotalCost / gnGoldRatio)
                -- if nYuanbaoAddNum > 0 then 
                --     if self:ItemCount(gtItemType.eCurr, gtCurrType.eAllYuanBao) < nYuanbaoAddNum then 
                --         self:YuanBaoTips()
                --         return fnCallback(false)
                --     end 
                -- end
            end 
        end 
        if nYuanbaoAddNum > 0 then 
            table.insert(tSubList, {gtItemType.eCurr, gtCurrType.eAllYuanBao, nYuanbaoAddNum}) 
        end

        --需要再次检查，避免出现，循环逻辑调用或者连续操作请求，或者rpc期间其他操作引发道具变化，
        --rpc前subcheck都通过，而实际玩家道具不足
        local function _fnClientConfirm()
            if not self:CheckSubShowNotEnoughTips(tSubList, sReason, true) then 
                return fnCallback(false)
            end
            fnCallback(true, nYuanbaoAddNum)
        end
        _fnClientConfirm()
        --临时措施,客户端热更失败的 
        -- if nYuanbaoAddNum > 0 then
        --     local tOption = {"取消", "确定"}
        --     local sCont = string.format("需要消耗%d元宝", nYuanbaoAddNum)
        --     local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=30}
        --     goClientCall:CallWait("ConfirmRet", function(tData)
        --         if tData.nSelIdx == 1 then
        --             return
        --         end
        --         _fnClientConfirm()
        --     end, self, tMsg)
        -- else
        --     _fnClientConfirm()
        -- end
    end 

    if #tYuanbaoAdd > 0 then 
        self:QueryCommercePrice(tQueryList, fnQueryCallback)
    else 
        fnQueryCallback(true, {})
    end
end


--获取道具补足价格
--当前只支持道具
--tItemList {nItemType, nItemID, nCurrType} --nCurrType是需要转换的目标货币类型
--bCeil查询价格，发生货币单位转换, 是否向上取整，false则向下取整
--正常，如果是查询补足价格，都向上取整
--fnCallback(bSucc, tPriceList) --tPriceList = {{nItemType, nItemID, nCurrType, nPrice}, ...}
function CRole:QueryItemPrice(tItemList, bCeil, fnCallback)
    return CUtil:QueryItemPrice(self:GetServer(), tItemList, bCeil, fnCallback)
end

