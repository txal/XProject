--摄魂系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--道具ID
local nPropSpiritID = 14          --灵气
local nMagicPillID = 15           --内丹
local nCrystalID = 16             --妖晶
local nRedSoulStoneID = 10020     --红魂石
local nBuleSoulStoneID = 10021    --蓝魂石
local nYellowSoulStoneID = 10022  --黄魂石
local nGreenSoulStoneID = 10023   --绿魂石

gnMaxDrawSpiritConfLevel = 0
for nLevel, tConf in ipairs(ctDrawSpiritConf) do 
    if nLevel > gnMaxDrawSpiritConfLevel then 
        gnMaxDrawSpiritConfLevel = nLevel
    end
end 

gtDrawSpiritRewardRationConf = {}
--Reload，也是调用的main，按照main中required顺序重新加载的，此时ctDrawSpiritRatioRewardConf已经更新
for k, v in pairs(ctDrawSpiritRatioRewardConf) do 
    table.insert(gtDrawSpiritRewardRationConf, v)
end
table.sort(gtDrawSpiritRewardRationConf, 
function(tL, tR)
    if tL.nRatio > tR.nRatio then 
        return true 
    else
        return false
    end
end)


--摄魂功能
function CDrawSpirit:Ctor(oRole)
    self.m_oRole = oRole
    self.m_nLevel = 1           --摄魂等级
    self.m_nSpirit = 0          --灵气值
    self.m_nCrystal = 0         --妖晶
    self.m_nMagicPill = 0       --内丹

    self.m_nTriggerLevel = 0       --当前灵气消耗等级

    self.m_tLianhunData = {}                   --炼魂数据
	self.m_tLianhunData.nLevel = 0
	self.m_tLianhunData.nExp = 0
    self.m_tLianhunData.tAttrList = {}
    
    self.m_tFazhenData = {}                   --法阵数据
	self.m_tFazhenData.nLevel = 0
	self.m_tFazhenData.nExp = 0
	self.m_tFazhenData.tAttrList = {}



    self.m_tAttr = {}           --属性值，不存DB，每次加载重新计算
    self.m_bDirty = false 

    self.m_bLevelUpTips = false   --是否提示升级

    self:UpdateTriggerLevel()
    self:UpdateAttr()
end

function CDrawSpirit:LoadData(tData)
    if not tData then 
        return 
    end
    self.m_nLevel = tData.nLevel
    self.m_nSpirit = tData.nSpirit
    self.m_nCrystal = tData.nCrystal
    self.m_nMagicPill = tData.nMagicPill
    self.m_nTriggerLevel = tData.nTriggerLevel
    self.m_tLianhunData = tData.tLianhunData or self.m_tLianhunData
    self.m_tFazhenData = tData.tFazhenData or self.m_tFazhenData

    self:UpdateLianhunAttr()
    self:UpdateFazhenAttr()
    self:UpdateTriggerLevel()
    self:UpdateAttr()
end

function CDrawSpirit:SaveData()
    if not self:IsDirty() then 
        return 
    end
    local tData = {}
    tData.nLevel = self.m_nLevel
    tData.nSpirit = self.m_nSpirit
    tData.nCrystal = self.m_nCrystal
    tData.nMagicPill = self.m_nMagicPill
    tData.nTriggerLevel = self.m_nTriggerLevel
    tData.tLianhunData = self.m_tLianhunData
    tData.tFazhenData = self.m_tFazhenData
    self:MarkDirty(false)
    return tData
end

function CDrawSpirit:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CDrawSpirit:IsDirty() return self.m_bDirty end
function CDrawSpirit:GetType() 
    return gtModuleDef.tDrawSpirit.nID, gtModuleDef.tDrawSpirit.sName
end
function CDrawSpirit:Online()
    self:UpdateLevelUpTips()
    self:SyncDrawSpiritData() 
end

function CDrawSpirit:GetSpirit() return self.m_nSpirit end
function CDrawSpirit:AddSpirit(nNum, sReason, bNotSync)
    self.m_nSpirit = math.min(math.max(self.m_nSpirit + nNum, 0), gtGDef.tConst.nMaxInteger)
    self:MarkDirty(true)
    if not bNotSync then
        if sReason and sReason == "摄魂" then 
            self.m_oRole:SyncCurrency(gtCurrType.eDrawSpirit, self.m_nSpirit, 1)
        else
            self.m_oRole:SyncCurrency(gtCurrType.eDrawSpirit, self.m_nSpirit)
            self:SetTriggerLevelMax()
        end
    end
    return self.m_nSpirit
end
function CDrawSpirit:IsSysOpen(bTips)
    return self.m_oRole.m_oSysOpen:IsSysOpen(55, bTips)
end
function CDrawSpirit:OnSysOpen()
    self:UpdateLevelUpTips(true)
    self:SetTriggerLevelReq(1)
end

function CDrawSpirit:GetMagicPill() return self.m_nMagicPill end
function CDrawSpirit:AddMagicPill(nNum, sReason, bNotSync)
    self.m_nMagicPill = math.min(math.max(self.m_nMagicPill + nNum, 0), gtGDef.tConst.nMaxInteger)
    self:MarkDirty(true)
    if not bNotSync then
        if sReason and sReason == "摄魂" then 
            self.m_oRole:SyncCurrency(gtCurrType.eMagicPill, self.m_nMagicPill, 1)
        else
            self.m_oRole:SyncCurrency(gtCurrType.eMagicPill, self.m_nMagicPill)
        end
    else
        self.m_oRole:CacheCurrMsg(gtCurrType.eMagicPill,self.m_nMagicPill)
    end 
    return self.m_nMagicPill
end
function CDrawSpirit:GetCrystal() return self.m_nCrystal end
function CDrawSpirit:AddCrystal(nNum, sReason, bNotSync)
    self.m_nCrystal = math.min(math.max(self.m_nCrystal + nNum, 0), gtGDef.tConst.nMaxInteger)
    self:MarkDirty(true)
    if not bNotSync then
        if sReason and sReason == "摄魂" then 
            self.m_oRole:SyncCurrency(gtCurrType.eEvilCrystal, self.m_nCrystal, 1)
        else
            self.m_oRole:SyncCurrency(gtCurrType.eEvilCrystal, self.m_nCrystal)
        end
    else
         self.m_oRole:CacheCurrMsg(gtCurrType.eEvilCrystal,self.m_nCrystal)
    end
    return self.m_nCrystal
end

function CDrawSpirit:GetSpiritLevel() return self.m_nLevel end
function CDrawSpirit:GetTriggerLevel() return self.m_nTriggerLevel end
function CDrawSpirit:SetTriggerLevel(nLevel) self.m_nTriggerLevel = nLevel end
function CDrawSpirit:GetSpiritCostByTriggerLevel(nLevel)
    if nLevel <= 0 then 
        return 0
    end
    local tLevelConf = self:GetLevelConf(nLevel)
    assert(tLevelConf)
    return tLevelConf.nCostNum
end
function CDrawSpirit:IsActive()
    return self:GetTriggerLevel() > 0
end

function CDrawSpirit:GetMaxConfLevel() 
    -- local nMaxConfLevel = 0
    -- for nLevel, tConf in ipairs(ctDrawSpiritConf) do 
    --     if nLevel > nMaxConfLevel then 
    --         nMaxConfLevel = nLevel
    --     end
    -- end 
    -- return nMaxConfLevel
    assert(gnMaxDrawSpiritConfLevel and gnMaxDrawSpiritConfLevel > 0)
    return gnMaxDrawSpiritConfLevel
end 
function CDrawSpirit:GetLevelConf(nLevel) 
    nLevel = nLevel or self.m_nLevel
    return ctDrawSpiritConf[nLevel] 
end

--获取当前灵气值可以设置的最大等级
function CDrawSpirit:GetLimitLevel() 
    local nSpiritLevel = self:GetSpiritLevel()
    local nSpirit = self:GetSpirit()
    local tConf = self:GetLevelConf(nSpiritLevel)
    assert(tConf)
    if tConf.nCostNum <= nSpirit then 
        return nSpiritLevel
    end
    local nMaxLimitLevel = 0
    for k, v in ipairs(ctDrawSpiritConf) do 
        if v.nCostNum <= nSpirit and v.nLevel > nMaxLimitLevel and v.nLevel <= nSpiritLevel then 
            nMaxLimitLevel = v.nLevel
        end
    end
    return math.max(math.min(nMaxLimitLevel, nSpiritLevel), 0)
end

--自动更新灵气消耗等级
function CDrawSpirit:UpdateTriggerLevel(bNotSync)
    local nLimitLevel = self:GetLimitLevel()
    if self.m_nTriggerLevel > nLimitLevel then 
        self.m_nTriggerLevel = nLimitLevel
        self:MarkDirty(true)
        if bNotSync then 
            self:SyncTriggerLevel()
        end
    end
end

function CDrawSpirit:CheckCanLevelUp()
    if self.m_nLevel >= self:GetMaxConfLevel() then
        return false, "已达最大等级"
    end
    local tNextLevelConf = self:GetLevelConf(self.m_nLevel + 1)
    assert(tNextLevelConf)
    if self.m_oRole:GetLevel() < tNextLevelConf.nRoleLevel then 
        return false, string.format("需等级达到%d级", tNextLevelConf.nRoleLevel)
    end 
    return true
end

--bNotSync一键升级的时候不用时时同步
function CDrawSpirit:LevelUp(nLevel, bNotSync)
    local nOldLevel = self.m_nLevel
    local nMaxConfLevel = self:GetMaxConfLevel()
    if self.m_nLevel >= nMaxConfLevel then --配置修改引发？？？
        return 
    end
    self.m_nLevel = math.max(math.min(self.m_nLevel + nLevel, nMaxConfLevel), 0)
    self:OnLevelChange(nOldLevel, bNotSync)
    self:MarkDirty(true)
end

function CDrawSpirit:OnLevelChange(nOldLevel, bNotSync)
    if not bNotSync then
        self:UpdateAttr()
        self.m_oRole:UpdateAttr() --连带引发角色属性变化
        self:UpdateLevelUpTips(true)
    end
    self.m_oRole:UpdateActGTDrawSpiritLv()
end

function CDrawSpirit:GetAttrFixParam()
	return ctRoleModuleAttrFixParamConf[103].nFixParam
end

function CDrawSpirit:UpdateAttr()
    self.m_tAttr= {}
    local nSpiritLevel = self:GetSpiritLevel()
    -- for k, v in pairs(ctDrawSpiritAttrConf) do 
    --     if v.nAttrID > 0 and v.fnAttrVal then 
    --         self.m_tAttr[k] = math.floor(v.fnAttrVal(nSpiritLevel))
    --     end
    -- end

    -- local nParam = math.floor(nSpiritLevel*1000*self:GetAttrFixParam())
    local nParam = self:CalcAttrScore()
    self.m_tAttr = self.m_oRole:CalcModuleGrowthAttr(nParam)
end 

function CDrawSpirit:GetBattleAttr()
    if not self:IsSysOpen() then 
        return {}
    end
    return self.m_tAttr
end

function CDrawSpirit:CalcAttrScore()
    -- local nScore = 0
    -- local tAttrList = self:GetBattleAttr()
    -- for nAttrID, nAttrVal in pairs(tAttrList) do 
	-- 	nScore = nScore + CUtil:CalcAttrScore(nAttrID, nAttrVal)
	-- end
    -- return nScore
    local nSpiritLevel = self:GetSpiritLevel()
    return math.floor(nSpiritLevel*1000*self:GetAttrFixParam())
end

--bNotSync 一键升级的时候不时时同步
function CDrawSpirit:DoLevelUp(bNotSync)
    local bSuccess = false
    local nRate = math.random(100)
    local tLevelConf = self:GetLevelConf(self:GetSpiritLevel())
    assert(tLevelConf)
    if nRate <= tLevelConf.nProbability then 
        bSuccess = true
    end
    if bSuccess then 
        self:LevelUp(1, bNotSync)
        if not bNotSync then
            if tLevelConf.nSpirit > 0 then 
                self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eDrawSpirit, tLevelConf.nSpirit, "摄魂升级")
            end
            self:UpdateLevelUpTips()
            self:SyncDrawSpiritData()
        end
    end
    return bSuccess,tLevelConf.nSpirit
end

--nLevel 当前等级
function CDrawSpirit:CheckLevelUpMaterial(nLevel)
    assert(nLevel)
    local tLevelConf = self:GetLevelConf(nLevel)
    assert(tLevelConf)
    local tCost = {}
    if tLevelConf.nMagicPill > 0 then 
        table.insert(tCost, {gtItemType.eCurr, gtCurrType.eMagicPill, tLevelConf.nMagicPill})
    end
    for k, v in ipairs(tLevelConf.tMaterial) do 
        if v[1] > 0 and v[2] > 0 then 
            table.insert(tCost, {gtItemType.eProp, v[1], v[2]})
        end
    end
    if #tCost > 0 then 
        for k, tData in pairs(tCost) do 
            --ItemCount中，因摄魂升级材料需要摄魂模块相关数据，会再次访问oRole.m_oDrawspirit模块
            --所以，这个不能在load中调用
            if self.m_oRole:ItemCount(tData[1], tData[2]) < tData[3] then 
                return false
            end
        end
    end
    return true
end

--注意，不能在Load中调用
function CDrawSpirit:UpdateLevelUpTips(bNotSync)
    local oRole = self.m_oRole
    local bPreState = self.m_bLevelUpTips
    local bNewState = false

    if self:IsSysOpen() then 
        local bCanLevelUp = self:CheckCanLevelUp()
        if bCanLevelUp then 
            if self:CheckLevelUpMaterial(self:GetSpiritLevel()) then 
                bNewState = true 
            end
        end
    end
    self.m_bLevelUpTips = bNewState
    if bNotSync and bPreState ~= self.m_bLevelUpTips then 
        self:SyncDrawSpiritData()
    end
end

--------------------------------------------------------
--同步摄魂模块数据
function CDrawSpirit:SyncDrawSpiritData()
    local tMsg = {}
    tMsg.nLevel = self:GetSpiritLevel()
    tMsg.nSpirit = self:GetSpirit()
    tMsg.nCrystal = self:GetCrystal()
    tMsg.nMagicPill = self:GetMagicPill()
    tMsg.nTriggerLevel = self:GetTriggerLevel()
    tMsg.nTriggerNum = self:GetSpiritCostByTriggerLevel(tMsg.nTriggerLevel)
    --tMsg.nPower = self:CalcAttrScore()
    tMsg.tAttrList = {}
    for k, v in pairs(self.m_tAttr) do 
        table.insert(tMsg.tAttrList, {nAttrID = k, nAttrVal = v})
    end
    tMsg.bLevelUpTips = self.m_bLevelUpTips
    self.m_oRole:SendMsg("DrawSpiritDataRet", tMsg)
end

--同步灵气数量
function CDrawSpirit:SyncSpiritNum()
    local tMsg = {}
    tMsg.nSpiritNum = self:GetSpirit()
    self.m_oRole:SendMsg("DrawSpiritCurSpiritNumRet", tMsg)
end

--同步消耗等级
function CDrawSpirit:SyncTriggerLevel()
    local tMsg = {}
    tMsg.nTriggerLevel = self:GetTriggerLevel()
    tMsg.nTriggerNum = self:GetSpiritCostByTriggerLevel(tMsg.nTriggerLevel)
    self.m_oRole:SendMsg("DrawSpiritSetTriggerLevelRet", tMsg)
end

--------------------------------------------------------
--暂时保留,以防策划请求改回去
function CDrawSpirit:LevelUpReq()
    if not self:IsSysOpen(true) then 
        -- self.m_oRole:Tips("摄魂功能未开启")
        return 
    end
    local bCanLevelUp, sReason = self:CheckCanLevelUp()
    if not bCanLevelUp then 
        if sReason then 
            self.m_oRole:Tips(sReason)
        end
        return 
    end
    local nSpiritLevel = self:GetSpiritLevel()
    local tLevelConf = self:GetLevelConf(nSpiritLevel)
    assert(tLevelConf)
    local tCost = {}
    if tLevelConf.nMagicPill > 0 then 
        table.insert(tCost, {gtItemType.eCurr, gtCurrType.eMagicPill, tLevelConf.nMagicPill})
    end
    for k, v in ipairs(tLevelConf.tMaterial) do 
        if v[1] > 0 and v[2] > 0 then 
            table.insert(tCost, {gtItemType.eProp, v[1], v[2]})
        end
    end
    if #tCost > 0 then 
        if not self.m_oRole:CheckSubShowNotEnoughTips(tCost, "摄魂升级", true) then 
            return 
        end
    end

    local bSuccess = self:DoLevelUp()
    
    local tMsg = {}
    tMsg.bSuccess = bSuccess
    tMsg.nOldLevel = nSpiritLevel
    tMsg.nCurLevel = self:GetSpiritLevel()
    self.m_oRole:SendMsg("DrawSpiritLevelUpRet", tMsg)
    local tData = {}
    tData.nLevel = self:GetSpiritLevel()
    CEventHandler:OnDrawSpriritUpLevel(self.m_oRole, tData)
end

--一键升级
function CDrawSpirit:OnKeyLevelUpReq()
    if not self:IsSysOpen(true) then 
        -- self.m_oRole:Tips("摄魂功能未开启")
        return 
    end
    local bFlag = true
    local nSumSpirit = 0
    local bTempSuccess = false
    local nTempLevel = self:GetSpiritLevel()
    while (bFlag) do
        local bCanLevelUp, sReason = self:CheckCanLevelUp()
        if not bCanLevelUp then 
            if sReason then 
                self.m_oRole:Tips(sReason)
            end
            break
        end
        local nSpiritLevel = self:GetSpiritLevel()
        local tLevelConf = self:GetLevelConf(nSpiritLevel)
        assert(tLevelConf)
        local tCost = {}
        if tLevelConf.nMagicPill > 0 then 
            table.insert(tCost, {gtItemType.eCurr, gtCurrType.eMagicPill, tLevelConf.nMagicPill})
        end
        for k, v in ipairs(tLevelConf.tMaterial) do 
            if v[1] > 0 and v[2] > 0 then 
                table.insert(tCost, {gtItemType.eProp, v[1], v[2]})
            end
        end
        if #tCost > 0 then 
            if not self.m_oRole:CheckSubShowNotEnoughTips(tCost, "摄魂升级", true, false, true) then 
                break
            end
            local bSuccess, nSpirit = self:DoLevelUp(true)
             if bSuccess then
                if not bTempSuccess then
                    bTempSuccess = bSuccess
                end
                nSumSpirit = nSumSpirit + nSpirit
            end
        else
            break
        end
    end
    
    self.m_oRole.m_oKnapsack:SyncCachedMsg()
    
    local tMsg = {}
    tMsg.bSuccess = bTempSuccess
    tMsg.nOldLevel = nTempLevel
    tMsg.nCurLevel = self:GetSpiritLevel()
    self.m_oRole:SendMsg("DrawSpiritLevelUpRet", tMsg)

    if nTempLevel ~= self:GetSpiritLevel() then
        local tData = {}
        tData.nLevel = self:GetSpiritLevel()
        CEventHandler:OnDrawSpriritUpLevel(self.m_oRole, tData)
        if nSumSpirit > 0 then
             self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eDrawSpirit, nSumSpirit, "摄魂升级")
        end

        --同步摄魂相关数据
        self:OnLevelChange(nTempLevel)
        self:UpdateLevelUpTips()
        self:SyncDrawSpiritData()
        self.m_oRole:SyncCurrency(gtCurrType.eMagicPill, self.m_nMagicPill)
    end
end

--将摄魂触发等级调整至当前可设置的最大等级
function CDrawSpirit:SetTriggerLevelMax()
    if not self:IsSysOpen() then 
        return 
    end
    self.m_nTriggerLevel = self:GetSpiritLevel()
    self:UpdateTriggerLevel()
    self:SyncDrawSpiritData()
end

function CDrawSpirit:SetTriggerLevelReq(nLevel)
    if not self:IsSysOpen(true) then 
        -- self.m_oRole:Tips("摄魂功能未开启")
        return 
    end
    assert(nLevel and nLevel >= 0)
    if nLevel > self:GetSpiritLevel() then 
        return self.m_oRole:Tips("已超过当前摄魂等级")
    end
    if nLevel > self:GetLimitLevel() then 
        return self.m_oRole:Tips("灵气不足")
    end
    self:SetTriggerLevel(nLevel)
    self:MarkDirty(true)
    self:SyncTriggerLevel()
end

--战斗触发
--返回值{bActive, {{nID=nRewardID, nNum=nRewardNum,}, ...} } --是否开启，掉落了哪些道具，数量分别多少
function CDrawSpirit:BattleTrigger()
    if not self:IsActive() then 
        return false
    end
    
    local nTriggerLevel = self:GetTriggerLevel()
    local nCostNum = self:GetSpiritCostByTriggerLevel(nTriggerLevel)
    if nCostNum > 0 then 
        if not self.m_oRole:CheckSubItem(gtItemType.eCurr, gtCurrType.eDrawSpirit, nCostNum, "摄魂") then 
            self:UpdateTriggerLevel() --未知原因，消耗失败
            return false
        end
    end

    --扣除物品数值
    local tSubList = {{nID=nPropSpiritID, nNum=nCostNum}}
    --扣除后的数值
    local tCurList = {
        {nID=nPropSpiritID, nNum=self.m_oRole:ItemCount(gtItemType.eCurr, gtCurrType.eDrawSpirit)},
        {nID=nMagicPillID, nNum=self.m_oRole:ItemCount(gtItemType.eCurr, gtCurrType.eMagicPill)},
        {nID=nCrystalID, nNum=self.m_oRole:ItemCount(gtItemType.eCurr, gtCurrType.eEvilCrystal)},
    } 

    local tAddList = {}

    --灵气奖励
    local nSpiritNum = 0
    local nRandom = math.random(10000)
    local tRewardConf = nil 
    for _, tConf in ipairs(gtDrawSpiritRewardRationConf) do 
        if tConf.nProbability > 0 then 
            nRandom = nRandom - tConf.nProbability
            if nRandom <= 0 then 
                tRewardConf = tConf
                break
            end
        end
    end

    local oRole = self.m_oRole
    if tRewardConf and tRewardConf.nRatio > 0 then 
        nSpiritNum = math.floor(nCostNum * tRewardConf.nRatio)
        if tRewardConf.nRatio >= 20 and nSpiritNum > 0 and not oRole:IsRobot() then 
            local tTalkConf = ctTalkConf["shehun"]
            if tTalkConf then 
                local sBroadcastContent = string.format(tTalkConf.sContent, 
                    oRole:GetName(), nSpiritNum)
                CUtil:SendHearsayMsg(sBroadcastContent)
            end
        end
    end
    if nSpiritNum > 0 then 
        table.insert(tAddList, {nID=nPropSpiritID, nNum=nSpiritNum})

        --触发掉落灵气的情况下，才会掉落其他道具
        local tRewardConf = ctDrawSpiritRewardConf[nTriggerLevel]
        assert(tRewardConf)
        --内丹掉落
        local nMagicPillNum = 0
        if tRewardConf.tMagicPillProbability[1][1] > 0 then 
            local nRandom = math.random(100)
            if nRandom <= tRewardConf.tMagicPillProbability[1][1] then 
                nMagicPillNum = math.random(tRewardConf.tMagicPillProbability[1][2], 
                tRewardConf.tMagicPillProbability[1][3])  
            end
        end
        if nMagicPillNum > 0 then 
            table.insert(tAddList, {nID=nMagicPillID, nNum=nMagicPillNum})
        end

        --妖晶掉落
        local nCrystalNum = 0
        if tRewardConf.tCrystalProbability[1][1] > 0 then 
            local nRandom = math.random(100)
            if nRandom <= tRewardConf.tCrystalProbability[1][1] then 
                nCrystalNum = math.random(tRewardConf.tCrystalProbability[1][2], 
                tRewardConf.tCrystalProbability[1][3])  
            end
        end
        if nCrystalNum > 0 then 
            table.insert(tAddList, {nID=nCrystalID, nNum=nCrystalNum})
        end

        --魂石掉落
        --红、蓝、黄、绿四种魂石随机掉落
        if tRewardConf.tSoulStoneProbability[1][1] > 0 then 
            local nRandom = math.random(100)
            if nRandom <= tRewardConf.tSoulStoneProbability[1][1] then 
                local nTotalNum = math.random(tRewardConf.tSoulStoneProbability[1][2], 
                tRewardConf.tSoulStoneProbability[1][3])  
                if nTotalNum > 0 then 
                    local tStoneWeigth = {[nRedSoulStoneID] = 100, [nBuleSoulStoneID] = 100, 
                        [nYellowSoulStoneID] = 100, [nGreenSoulStoneID] = 100}
                    local fnGetWeight = function(tNode) return tNode end
                    local nSplitNum = math.max(math.floor(nTotalNum / 100), 1)  --防止奖励大数值
                    local tStoneList = CWeightRandom:WeightSplit(tStoneWeigth, fnGetWeight, nTotalNum, nSplitNum)
                    for nStoneID, nStoneNum in pairs(tStoneList) do 
                        if nStoneNum > 0 then 
                            table.insert(tAddList, {nID = nStoneID, nNum = nStoneNum})
                        end
                    end
                end
            end
        end
    end
    
    --增加奖励
    if #tAddList > 0 then 
        for k, v in ipairs(tAddList) do 
            self.m_oRole:AddItem(gtItemType.eProp, v.nID, v.nNum, "摄魂")
        end
    end
    --增加了奖励后的数值
    local tCurList1 = {
        {nID=nPropSpiritID, nNum=self.m_oRole:ItemCount(gtItemType.eCurr, gtCurrType.eDrawSpirit)},
        {nID=nMagicPillID, nNum=self.m_oRole:ItemCount(gtItemType.eCurr, gtCurrType.eMagicPill)},
        {nID=nCrystalID, nNum=self.m_oRole:ItemCount(gtItemType.eCurr, gtCurrType.eEvilCrystal)},
    } 
    -- print("tAddList", tAddList)
    self:UpdateTriggerLevel() --每次触发摄魂后，检查下剩余灵气是否足够
    --CEventHandler:OnUseDrawSpirit(self.m_oRole)
    if nSpiritNum > 0 then 
        self.m_oRole:AddActGTDrawSpiritScore(nSpiritNum)
    end
    return true, tSubList, tCurList, tAddList, tCurList1
end

---------------------------------------------------
--摄魂炼魂
function CDrawSpirit:GetLianhunGrowthID()
	return 6
end

function CDrawSpirit:IsLianhunSysOpen(bTips)
	return self.m_oRole:IsSysOpen(95, bTips)
end

function CDrawSpirit:GetLianhunLevel()
	return self.m_tLianhunData and self.m_tLianhunData.nLevel or 0
end

function CDrawSpirit:GetLianhunLimitLevel()
	local nID = self:GetLianhunGrowthID()
	return math.min(self.m_oRole:GetLevel() * 8, ctRoleGrowthConf.GetConfMaxLevel(nID))
end

function CDrawSpirit:SetLianhunLevel(nLevel)
	local nID = self:GetLianhunGrowthID()
	assert(nLevel > 0 and nLevel <= ctRoleGrowthConf.GetConfMaxLevel(nID))
	self.m_tLianhunData.nLevel = nLevel
	self:MarkDirty(true)
end

function CDrawSpirit:GetLianhunExp()
	return self.m_tLianhunData and self.m_tLianhunData.nExp or 0
end

function CDrawSpirit:GetLianhunAttr()
	if not self:IsLianhunSysOpen() then 
		return {} 
	end
	return self.m_tLianhunData.tAttrList or {}
end

function CDrawSpirit:GetLianhunAttrRatio()
	local nID = self:GetLianhunGrowthID()
	local tConf = ctRoleGrowthConf[nID]
	return tConf.nRatio or 1
end

function CDrawSpirit:GetLianhunScore()
	if not self:IsLianhunSysOpen() then 
		return 0 
	end
	return math.floor(self:GetLianhunLevel()*1000*self:GetLianhunAttrRatio())
end

function CDrawSpirit:UpdateLianhunAttr()
	-- local nParam = self:GetLianhunLevel()*1000*1
	local nParam = self:GetLianhunScore()
	self.m_tLianhunData.tAttrList = self.m_oRole:CalcModuleGrowthAttr(nParam) or {}
end

function CDrawSpirit:OnLianhunLevelChange()
	self:UpdateLianhunAttr()
	self.m_oRole:UpdateAttr()
end

function CDrawSpirit:AddLianhunExp(nAddExp)
	local nID = self:GetLianhunGrowthID()
	local nCurLevel = self:GetLianhunLevel()
	local nLimitLevel = self:GetLianhunLimitLevel()
	local nCurExp = self:GetLianhunExp()
	local nTarLevel, nTarExp = ctRoleGrowthConf.AddExp(nID, nCurLevel, nLimitLevel, nCurExp, nAddExp)
	self:SetLianhunLevel(nTarLevel)
	self.m_tLianhunData.nExp = nTarExp
	self:MarkDirty(true)
	if nCurLevel ~= nTarLevel then 
		self:OnLianhunLevelChange()
	end
end

function CDrawSpirit:SyncLianhunData()
	local tMsg = {}
	tMsg.nLevel = self.m_tLianhunData.nLevel
	tMsg.nExp = self.m_tLianhunData.nExp
	tMsg.tAttrList = {}
	for nAttrID, nAttrVal in pairs(self.m_tLianhunData.tAttrList) do 
		table.insert(tMsg.tAttrList, {nAttrID = nAttrID, nAttrVal = nAttrVal})
	end
	tMsg.nScore = self:GetLianhunScore()
	self.m_oRole:SendMsg("DrawSpiritLianhunInfoRet", tMsg)
end

function CDrawSpirit:LianhunLevelUpReq()
	if not self:IsLianhunSysOpen(true) then 
		return 
	end
	local oRole = self.m_oRole
	local nGrowthID = self:GetLianhunGrowthID()
	local nCurLevel = self:GetLianhunLevel()
	local nLimitLevel = self:GetLianhunLimitLevel()
	local nCurExp = self:GetLianhunExp()
	if nCurLevel >= ctRoleGrowthConf.GetConfMaxLevel(nGrowthID) then 
		oRole:Tips("当前已达最高等级")
		return 
	end
	if nCurLevel >= nLimitLevel then 
		oRole:Tips("已达到当前限制等级，请先提升角色等级")
		return 
	end

	local nMaxAddExp = ctRoleGrowthConf.GetMaxAddExp(nGrowthID, nCurLevel, nLimitLevel, nCurExp)
	if nMaxAddExp <= 0 then 
		oRole:Tips("当前已达最高等级")
		return 
	end
	local tCost = ctRoleGrowthConf.GetExpItemCost(nGrowthID, nMaxAddExp)
	assert(next(tCost))
	local nItemType = tCost[1]
	local nItemID = tCost[2]
	local nMaxItemNum = tCost[3]
	assert(nItemType > 0 and nItemID > 0 and nMaxItemNum > 0)
	local nKeepNum = oRole:ItemCount(nItemType, nItemID)
	if nKeepNum <= 0 then 
		oRole:Tips("材料不足，无法升级")
		return 
	end
	local nCostNum = math.min(nKeepNum, nMaxItemNum)
	local nAddExp = ctRoleGrowthConf.GetItemExp(nGrowthID, nItemType, nItemID, nCostNum)
	assert(nAddExp and nAddExp > 0)

	local tCost = {{nItemType, nItemID, nCostNum}, }
	if not oRole:CheckSubShowNotEnoughTips(tCost, "摄魂炼魂升级", true) then 
		return 
	end
	self:AddLianhunExp(nAddExp)
	self:SyncLianhunData()

	local nResultLevel = self:GetLianhunLevel()
	local sContent = nil 
	local sModuleName = "炼魂"
	local sPropName = ctPropConf:GetFormattedName(nItemID) --暂时只支持道具
	if nResultLevel > nCurLevel then 
		local sTemplate = "消耗%d个%s, %s等级提升到%d级"
		sContent = string.format(sTemplate, nCostNum, sPropName, sModuleName, nResultLevel)
	else
		local sTemplate = "消耗%d个%s, %s增加%d经验"
		sContent = string.format(sTemplate, nCostNum, sPropName, sModuleName, nAddExp)
	end
	if sContent then 
		oRole:Tips(sContent)
	end


	local tMsg = {}
	tMsg.nOldLevel = nCurLevel
	tMsg.nCurLevel = self:GetLianhunLevel()
	oRole:SendMsg("DrawSpiritLianhunLevelUpRet", tMsg)
end

---------------------------------------------------
--摄魂法阵
function CDrawSpirit:GetFazhenGrowthID()
	return 7
end

function CDrawSpirit:IsFazhenSysOpen(bTips)
	return self.m_oRole:IsSysOpen(96, bTips)
end

function CDrawSpirit:GetFazhenLevel()
	return self.m_tFazhenData and self.m_tFazhenData.nLevel or 0
end

function CDrawSpirit:GetFazhenLimitLevel()
	local nID = self:GetFazhenGrowthID()
	return math.min(self.m_oRole:GetLevel() * 8, ctRoleGrowthConf.GetConfMaxLevel(nID))
end

function CDrawSpirit:SetFazhenLevel(nLevel)
	local nID = self:GetFazhenGrowthID()
	assert(nLevel > 0 and nLevel <= ctRoleGrowthConf.GetConfMaxLevel(nID))
	self.m_tFazhenData.nLevel = nLevel
	self:MarkDirty(true)
end

function CDrawSpirit:GetFazhenExp()
	return self.m_tFazhenData and self.m_tFazhenData.nExp or 0
end

function CDrawSpirit:GetFazhenAttr()
	if not self:IsFazhenSysOpen() then 
		return {} 
	end
	return self.m_tFazhenData.tAttrList or {}
end

function CDrawSpirit:GetFazhenAttrRatio()
	local nID = self:GetFazhenGrowthID()
	local tConf = ctRoleGrowthConf[nID]
	return tConf.nRatio or 1
end

function CDrawSpirit:GetFazhenScore()
	if not self:IsFazhenSysOpen() then 
		return 0 
	end
	return math.floor(self:GetFazhenLevel()*1000*self:GetFazhenAttrRatio())
end

function CDrawSpirit:UpdateFazhenAttr()
	-- local nParam = self:GetFazhenLevel()*1000*1
	local nParam = self:GetFazhenScore()
	self.m_tFazhenData.tAttrList = self.m_oRole:CalcModuleGrowthAttr(nParam) or {}
end

function CDrawSpirit:OnFazhenLevelChange()
	self:UpdateFazhenAttr()
	self.m_oRole:UpdateAttr()
end

function CDrawSpirit:AddFazhenExp(nAddExp)
	local nID = self:GetFazhenGrowthID()
	local nCurLevel = self:GetFazhenLevel()
	local nLimitLevel = self:GetFazhenLimitLevel()
	local nCurExp = self:GetFazhenExp()
	local nTarLevel, nTarExp = ctRoleGrowthConf.AddExp(nID, nCurLevel, nLimitLevel, nCurExp, nAddExp)
	self:SetFazhenLevel(nTarLevel)
	self.m_tFazhenData.nExp = nTarExp
	self:MarkDirty(true)
	if nCurLevel ~= nTarLevel then 
		self:OnFazhenLevelChange()
	end
end

function CDrawSpirit:SyncFazhenData()
	local tMsg = {}
	tMsg.nTotalLevel = self.m_tFazhenData.nLevel
	tMsg.nExp = self.m_tFazhenData.nExp
	tMsg.tAttrList = {}
	for nAttrID, nAttrVal in pairs(self.m_tFazhenData.tAttrList) do 
		table.insert(tMsg.tAttrList, {nAttrID = nAttrID, nAttrVal = nAttrVal})
	end
	tMsg.nScore = self:GetFazhenScore()
	self.m_oRole:SendMsg("DrawSpiritFazhenInfoRet", tMsg)
end

function CDrawSpirit:FazhenLevelUpReq()
	if not self:IsFazhenSysOpen(true) then 
		return 
	end
	local oRole = self.m_oRole
	local nGrowthID = self:GetFazhenGrowthID()
	local nCurLevel = self:GetFazhenLevel()
	local nLimitLevel = self:GetFazhenLimitLevel()
	local nCurExp = self:GetFazhenExp()
	if nCurLevel >= ctRoleGrowthConf.GetConfMaxLevel(nGrowthID) then 
		oRole:Tips("当前已达最高等级")
		return 
	end
	if nCurLevel >= nLimitLevel then 
		oRole:Tips("已达到当前限制等级，请先提升角色等级")
		return 
	end

	local nMaxAddExp = ctRoleGrowthConf.GetMaxAddExp(nGrowthID, nCurLevel, nLimitLevel, nCurExp)
	if nMaxAddExp <= 0 then 
		oRole:Tips("当前已达最高等级")
		return 
	end
	local tCost = ctRoleGrowthConf.GetExpItemCost(nGrowthID, nMaxAddExp)
	assert(next(tCost))
	local nItemType = tCost[1]
	local nItemID = tCost[2]
	local nMaxItemNum = tCost[3]
	assert(nItemType > 0 and nItemID > 0 and nMaxItemNum > 0)
	local nKeepNum = oRole:ItemCount(nItemType, nItemID)
	if nKeepNum <= 0 then 
		oRole:Tips("材料不足，无法升级")
		return 
	end
	local nCostNum = math.min(nKeepNum, nMaxItemNum)
	local nAddExp = ctRoleGrowthConf.GetItemExp(nGrowthID, nItemType, nItemID, nCostNum)
	assert(nAddExp and nAddExp > 0)

	local tCost = {{nItemType, nItemID, nCostNum}, }
	if not oRole:CheckSubShowNotEnoughTips(tCost, "摄魂法阵升级", true) then 
		return 
	end
	self:AddFazhenExp(nAddExp)
	self:SyncFazhenData()

	local nResultLevel = self:GetFazhenLevel()
	local sContent = nil 
	local sModuleName = "法阵"
	local sPropName = ctPropConf:GetFormattedName(nItemID) --暂时只支持道具
	if nResultLevel > nCurLevel then 
		local sTemplate = "消耗%d个%s, %s等级提升到%d级"
		sContent = string.format(sTemplate, nCostNum, sPropName, sModuleName, nResultLevel)
	else
		local sTemplate = "消耗%d个%s, %s增加%d经验"
		sContent = string.format(sTemplate, nCostNum, sPropName, sModuleName, nAddExp)
	end
	if sContent then 
		oRole:Tips(sContent)
	end


	local tMsg = {}
	tMsg.nOldLevel = nCurLevel
	tMsg.nCurLevel = self:GetFazhenLevel()
	oRole:SendMsg("DrawSpiritFazhenLevelUpRet", tMsg)
end

