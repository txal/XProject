--功能预告
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CWillOpen:Ctor(oRole)
    self.m_oRole = oRole
    self.m_nCurrSeq = 1             --初始化第一个功能预告
    self.m_bGetReward = false
end

function CWillOpen:LoadData(tData)
    if tData then
        self.m_nCurrSeq = tData.m_nCurrSeq or 1
        self.m_bGetReward = tData.m_bGetReward or false
    end

    --配置设置不开启后设置成下一个
    if not ctWillOpenConf[self.m_nCurrSeq].bOpen then
        --遍历到下一个开启的
        local nNextOpen = ctWillOpenConf[self.m_nCurrSeq].nNext
        while (not ctWillOpenConf[nNextOpen].bOpen) do
            nNextOpen = ctWillOpenConf[nNextOpen].nNext
            if nNextOpen == 0 then
                break
            end
        end

        --如果存在开启的下一个就设置新的序列号，如果不存在就不设置每次登陆都检查
        if nNextOpen ~= 0 then
            self.m_nCurrSeq = nNextOpen
            self.m_bGetReward = false
            self:MarkDirty(true)
        end
    end
end

function CWillOpen:SaveData()
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)
    local tData = {}
    tData.m_nCurrSeq = self.m_nCurrSeq
    tData.m_bGetReward = self.m_bGetReward
    return tData
end

function CWillOpen:GetType()
    return gtModuleDef.tWillOpen.nID, gtModuleDef.tWillOpen.sName
end

function CWillOpen:Online()
    --先检查要不要设置下一个(有可能追加)
    if self.m_bGetReward then
        self:SetNextWillOpen()
    else
        self:SendWillOpenInfo()
    end
end

function CWillOpen:WillOpenInfoReq()
    -- local nNextSeq = ctWillOpenConf[self.m_nCurrSeq].nNext
    -- if not ctWillOpenConf[nNextSeq] and self.m_bGetReward then      --当前的奖励领了并且没有下一个了
    --     return
    -- else
    --     self:SendWillOpenInfo()
    -- end

    --领了最后一个奖励但是没下线要展示界面
    self:SendWillOpenInfo()
end

function CWillOpen:GetRewardReq()
    if self.m_bGetReward then
        return self.m_oRole:Tips("奖励已领取过")
    end

    local tConf = ctWillOpenConf[self.m_nCurrSeq]
    if tConf and self.m_oRole.m_oSysOpen:IsSysOpen(tConf.nSysID) and not self.m_bGetReward then
        for _, tItem in pairs(tConf.tItemReward) do
            local nItemType = tItem[1]
            assert(gtItemType.eNone <= nItemType and nItemType <=gtItemType.eAppellation, "功能预告配置错误，序号："..self.m_nCurrSeq)
            if gtItemType.eProp == nItemType or gtItemType.eCurr == nItemType then
                self.m_oRole:AddItem(nItemType, tItem[2], tItem[3], "功能预告奖励", false, tItem[4])
            elseif gtItemType.ePet == nItemType then
                self.m_oRole:AddItem(nItemType, tItem[2], tItem[3], "功能预告奖励", false, tItem[4])
            elseif gtItemType.ePartner == nItemType then
                local nPartnerID = tItem[2]
                self.m_oRole.m_oPartner:AddPartner(nPartnerID, "功能预告奖励")
            elseif gtItemType.eFaBao == nItemType then
                self.m_oRole.m_oFaBao:AddFaBao(tItem[2], tItem[3], tItem[4])
            elseif gtItemType.eAppellation == nItemType then
                local nAppeID = tItem[2]
                local tParam = {}
                local nNowTime = os.time()
                tParam.nExpiryTime = nNowTime + tItem[5] * 24 * 3600
                self.m_oRole:AddAppellation(nAppeID, tParam, 0, "功能预告奖励")
            end
        end
        self.m_bGetReward = true
        self:SetNextWillOpen()
        self:MarkDirty(true)
    else
        return self.m_oRole:Tips("未达到条件，不能领取")
    end
end

function CWillOpen:SetNextWillOpen()
    if not self.m_bGetReward then
        return
    end

    local nNextOpen = ctWillOpenConf[self.m_nCurrSeq].nNext
    if nNextOpen == 0 then return end       --已达到最后开启的功能时不处理
    while (not ctWillOpenConf[nNextOpen].bOpen) do
        nNextOpen = ctWillOpenConf[nNextOpen].nNext
        if nNextOpen == 0 then
            break
        end
    end

    if nNextOpen ~= 0 then
        self.m_nCurrSeq = nNextOpen
        self.m_bGetReward = false
        self:MarkDirty(true) 
        self:SendWillOpenInfo()       
    end
end

--有发协议客户就显示按钮，没发协议客户端就不显示按钮
function CWillOpen:SendWillOpenInfo()
    local tConf = ctWillOpenConf[self.m_nCurrSeq]
    if tConf.bOpen then
        local tMsg = {}
        tMsg.nSeq = self.m_nCurrSeq
        tMsg.bCanReward = self.m_oRole.m_oSysOpen:IsSysOpen(tConf.nSysID) and not self.m_bGetReward or false
        self.m_oRole:SendMsg("WillOpenInfoRet", tMsg)
        --print(">>>>>>>>>>>>>功能预告信息", tMsg)
    end
end

--当前功能预告开放时及时发送状态客户端提示红点
function CWillOpen:OnSysOpen(nSysID)
    local tConf = ctWillOpenConf[self.m_nCurrSeq]
    if tConf and not self.m_bGetReward and tConf.nSysID == nSysID then
        self:SendWillOpenInfo()
    end
end
