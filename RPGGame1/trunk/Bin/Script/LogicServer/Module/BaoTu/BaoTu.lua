--宝图
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

CBaoTu.tWaBao =
{
    eNormal = 1,        --普通藏宝图
    eSpecial = 2,       --高级藏宝图
}

CBaoTu.tStatus =
{
    eStart = 1,         --开始挖宝
    eStop = 2,          --停止挖宝
}

function CBaoTu:Ctor(oRole)
    self.m_oRole = oRole
    self.m_tNormalPos = {}      --普通挖宝位置
    self.m_tSpecailPos = {}     --高级挖宝位置
    self.m_nCompTimes = 0       --今天完成次数
    self.m_nLastResetTimeStamp = 0  --上次重置数据时间戳

    --不保存
    self.m_nWaBaoStartTimeStamp = 0 --挖宝开始时间戳
    self.m_nCurrWaBaoType = 0       --当前挖宝类型
end

function CBaoTu:LoadData(tData)
    if tData then
        self.m_tNormalPos = tData.m_tNormalPos or self.m_tNormalPos
        self.m_tSpecailPos =  tData.m_tSpecailPos or  self.m_tSpecailPos
        self.m_nCompTimes = tData.m_nCompTimes or self.m_nCompTimes
        self.m_nLastResetTimeStamp = tData.m_nLastResetTimeStamp or self.m_nLastResetTimeStamp
    end
end

function CBaoTu:SaveData(oRole)
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)

    local tData = {}
    tData.m_tNormalPos = self.m_tNormalPos
    tData.m_tSpecailPos =  self.m_tSpecailPos
    tData.m_nCompTimes = self.m_nCompTimes
    tData.m_nLastResetTimeStamp = self.m_nLastResetTimeStamp
    return tData
end

function CBaoTu:GetType(oRole)
    return gtModuleDef.tBaoTu.nID, gtModuleDef.tBaoTu.sName
end

function CBaoTu:ClearPos(nWaBaoType)
    if nWaBaoType == CBaoTu.tWaBao.eNormal then
        for nKey, _ in pairs(self.m_tNormalPos) do
            self.m_tNormalPos[nKey] = nil
        end
    elseif nWaBaoType == CBaoTu.tWaBao.eSpecial then
        for nKey, _ in pairs(self.m_tSpecailPos) do
            self.m_tSpecailPos[nKey] = nil
        end
    end
    self:MarkDirty(true)
end

--界面信息请求
function CBaoTu:WaBaoInfoReq()
    self:SendBaoTuPosList()
end

--挖宝坐标请求
function CBaoTu:WaBaoPosReq(nWaBaoType)
    -- if self.m_oRole:GetLevel() < ctDailyActivity[gtDailyID.eBaoTu].nLevelLimit then
    --     return self.m_oRole:Tips(string.format("等级不足%d级不能参加宝图任务", ctDailyActivity[gtDailyID.eBaoTu].nLevelLimit))
    -- end

    if not self.m_oRole.m_oSysOpen:IsSysOpen(70, true) then       --70系统开放ID
        return
    end

    if nWaBaoType == CBaoTu.tWaBao.eNormal then
        if next(self.m_tNormalPos) then
            self:SendBaoTuPosList()
            return
        end
    elseif nWaBaoType == CBaoTu.tWaBao.eSpecial then
        if next(self.m_tSpecailPos) then
            self:SendBaoTuPosList()
            return
        end
    end
    --判断,重新产生坐标
    local bCanWaBao = false
    local nItemIDCost = 0
    local nNumCost = 0
    if nWaBaoType == CBaoTu.tWaBao.eNormal then
        nItemIDCost = ctBaoTuConf[1].tNormalCost[1][1]
        nNumCost = ctBaoTuConf[1].tNormalCost[1][2]
        local bHadTimes = self.m_nCompTimes < ctBaoTuConf[1].nFreeTimes
        local bHadItem = nNumCost <= self.m_oRole:ItemCount(gtItemType.eProp, nItemIDCost)
        if bHadTimes or bHadItem then
            bCanWaBao = true
        end

    elseif nWaBaoType == CBaoTu.tWaBao.eSpecial then
        nItemIDCost = ctBaoTuConf[1].tSpecailCost[1][1]
        nNumCost = ctBaoTuConf[1].tSpecailCost[1][2]
        if nNumCost <= self.m_oRole:ItemCount(gtItemType.eProp, nItemIDCost) then
            bCanWaBao = true
        end

    else
        return self.m_oRole:Tips("挖宝类型错误")
    end
    if not bCanWaBao then
        return self.m_oRole:Tips("你没有藏宝图哦。每天零点会获得10次挖宝次数哦")
    end

    --随机抽取
    if self.m_nCompTimes < ctBaoTuConf[1].nFreeTimes and nWaBaoType == CBaoTu.tWaBao.eNormal then
        self.m_nCompTimes = self.m_nCompTimes + 1
    else
        self.m_oRole:AddItem(gtItemType.eProp, nItemIDCost, -nNumCost, "宝图任务消耗")
    end

    local function GetPosWeight()
        return 100
    end
    local tPosConf = ctRandomPoint.GetPool(ctBaoTuConf[1].nRandPosType, self.m_oRole:GetLevel())
    local tResult = CWeightRandom:Random(tPosConf, GetPosWeight, 1, false)

    --保存
    if nWaBaoType == CBaoTu.tWaBao.eNormal then
        self.m_tNormalPos[1] = tResult[1].nDupID
        self.m_tNormalPos[2] = tResult[1].tPos[1][1]
        self.m_tNormalPos[3] = tResult[1].tPos[1][2]

    elseif nWaBaoType == CBaoTu.tWaBao.eSpecial then
        self.m_tSpecailPos[1] = tResult[1].nDupID
        self.m_tSpecailPos[2] = tResult[1].tPos[1][1]
        self.m_tSpecailPos[3] = tResult[1].tPos[1][2]
    end
    self:MarkDirty(true)
    self:SendBaoTuPosList()
    self.m_oRole:PushAchieve("寻宝次数",{nValue = 1})

end

--高级藏宝图合成请求
function CBaoTu:MapCompReq(bUseGold, nCompNum)
    assert(nCompNum > 0, "合成数量有错")
    local bStuffEnought = true
    local nGoldCost = 0
    local nYuanBaoType = 0

    local function CompItem(bCostSucc)
        if bCostSucc then
            local tCompItem = ctBaoTuConf[1].tCompItem
            self.m_oRole:AddItem(gtItemType.eProp, tCompItem[1][1], tCompItem[1][2]*nCompNum, "高级挖宝合成")
            self.m_oRole:Tips(string.format("恭喜合成成功%s*%d", ctPropConf[tCompItem[1][1]].sName, tCompItem[1][2]))
            self:MarkDirty(true)
        end
    end

    local tStuffList = {}
    for _, tStuff in ipairs(ctBaoTuConf[1].tCompStuff) do
        -- local nCount = self.m_oRole:ItemCount(gtItemType.eProp, tStuff[1])
        -- if nCount < tStuff[2]*nCompNum then  --判断材料是否足够，如果使用元宝需要多少元宝
        --     bStuffEnought = false
        --     nGoldCost = nGoldCost + (tStuff[2]*nCompNum-nCount)*ctPropConf[tStuff[1]].nBuyPrice
        --     nYuanBaoType = ctPropConf[tStuff[1]].nYuanBaoType
        -- end

        local tNeedStuff = {gtItemType.eProp, tStuff[1], tStuff[2]*nCompNum}
        table.insert(tStuffList, tNeedStuff)
    end

    -- if not bStuffEnought and not bUseGold then
    --     return self.m_oRole:Tips("合成材料不足")
    -- end

    -- local nHadGold = self.m_oRole:ItemCount(gtItemType.eCurr, gtCurrType.eAllYuanBao)
    -- if bUseGold and nHadGold < nGoldCost then
    --     return self.m_oRole:SendMsg("GoldAllNotEnoughtRet", {})
    -- end

    --消耗道具
    --if bUseGold then    --材料元宝混合使用合成
        -- for _, tCost in ipairs(ctBaoTuConf[1].tCompStuff) do
        --     local nCount = self.m_oRole:ItemCount(gtItemType.eProp, tCost[1])
        --     local nNumCost = nCount > tCost[2]*nCompNum and tCost[2]*nCompNum or nCount
        --     self.m_oRole:AddItem(gtItemType.eProp, tCost[1], -nNumCost, "高级挖宝合成消耗")
        -- end
        -- if nGoldCost > 0 and nYuanBaoType > 0 then
        --     self.m_oRole:AddItem(gtItemType.eCurr, nYuanBaoType, -nGoldCost, "使用元宝合成高级宝图")
        -- end

    -- else
    --     for _, tCost in ipairs(ctBaoTuConf[1].tCompStuff) do
    --         self.m_oRole:AddItem(gtItemType.eProp, tCost[1], -tCost[2]*nCompNum, "高级挖宝合成消耗")
    --     end
    -- end

    self.m_oRole:SubItemByYuanbao(tStuffList, "高级挖宝合成消耗", CompItem, not bUseGold)
end

function CBaoTu:WaBaoStatusReq(nWaBaoType, nStatus)
    assert(nWaBaoType and nStatus, "挖宝状态请求参数错误")

    if nStatus == CBaoTu.tStatus.eStart then
        local tTargetPos = nil
        if nWaBaoType == CBaoTu.tWaBao.eNormal then
            tTargetPos = self.m_tNormalPos
        elseif nWaBaoType == CBaoTu.tWaBao.eSpecial then
            tTargetPos = self.m_tSpecailPos
        else
            return self.m_oRole:Tips("挖宝类型错误")
        end
        if not next(tTargetPos) then return end
        local nRolePosX, nRolePosY = self.m_oRole:GetPos()
        local nDisX = math.abs(nRolePosX - tTargetPos[2])
        local nDisY = math.abs(nRolePosY - tTargetPos[3])
        if nDisX^2 + nDisY^2 > 100^2 then
            --print(">>>>>>>>>>>>>>>>挖宝坐标:",nRolePosX, nRolePosY, "目标坐标:", tTargetPos[2], tTargetPos[3])
            return self.m_oRole:Tips("不在藏宝图位置上"..nRolePosX .. nRolePosY)
        end
        self.m_nCurrWaBaoType = nWaBaoType
        self.m_nWaBaoStartTimeStamp = os.time()
        return

    elseif nStatus == CBaoTu.tStatus.eStop and nWaBaoType == self.m_nCurrWaBaoType then
        local nWaBaoTime = ctBaoTuConf[1].nTime
        --网络传递放宽到6秒
        if os.time() < self.m_nWaBaoStartTimeStamp or os.time() >= (self.m_nWaBaoStartTimeStamp+ctBaoTuConf[1].nTime*4) then
            --print(">>>>>>>>>>>>>>>>挖宝开始时间", self.m_nWaBaoStartTimeStamp, "挖宝结束时间", os.time())
            return self.m_oRole:Tips("挖宝失败，请重新挖宝")
        end

    else
        return self.m_oRole:Tips("挖宝操作非法")
    end

    local nRewardPoolID = 0
    local nRoleLevel = self.m_oRole:GetLevel()
    local nTreasureScore = 0   --挖宝积分
    if nWaBaoType == CBaoTu.tWaBao.eNormal then
        nRewardPoolID = ctBaoTuConf[1].nNorReward
        nTreasureScore = 1
    else
        nRewardPoolID = ctBaoTuConf[1].nSpeReward
        nTreasureScore = 30
    end
    local function GetWeight(tNode)
        return tNode.nWeight
    end
    assert(nRewardPoolID > 0, "奖励库ID有误")
    local tRewardList = ctAwardPoolConf.GetPool(nRewardPoolID, nRoleLevel, self.m_oRole:GetConfID())
    local tRewardConf = CWeightRandom:Random(tRewardList, GetWeight, 1, false)  --奖励一种物品
    local tMsg = {}
    tMsg.nItemID = tRewardConf[1].nItemID
    tMsg.nNum = tRewardConf[1].nItemNum
    self.m_oRole:SendMsg("WaBaoResultRet", tMsg)
    self.m_oRole:AddItem(gtItemType.eProp, tRewardConf[1].nItemID, tRewardConf[1].nItemNum, "挖宝奖励")
     --系统传闻
    --  if tRewardConf[1].sNotice ~= "" then
    --     local sItemName = nWaBaoType == CBaoTu.tWaBao.eNormal and "藏宝图" or "乾坤宝图"
    --     local sName = ctPropConf[tRewardConf[1].nItemID].sName
    --     CUtil:SendSystemTalk("传闻", string.format("%s通过%s获得了%s", self.m_oRole:GetName(), sItemName, sName))
    --  end
     self:ClearPos(nWaBaoType)
     self.m_oRole:AddActGTTreasureSearchScore(nTreasureScore)

     --挖宝相关事件
     local tWaBaoInfo = {}
     tWaBaoInfo.bIsHearsay = true
     tWaBaoInfo.nWaBaoType = nWaBaoType
     tWaBaoInfo.nItemID = tRewardConf[1].nItemID
     CEventHandler:OnCompBaoTu(self.m_oRole, tWaBaoInfo)
end

function CBaoTu:OnHourTimer()
    if not os.IsSameDay(self.m_nLastResetTimeStamp, os.time(), 0) then
        self.m_nCompTimes = 0
        self:ClearPos(CBaoTu.tWaBao.eNormal)
        self.m_nLastResetTimeStamp = os.time()
        self:MarkDirty(true)
    end
end

function CBaoTu:Online()
    if not os.IsSameDay(self.m_nLastResetTimeStamp, os.time(), 0) then
        self.m_nCompTimes = 0
        self:ClearPos(CBaoTu.tWaBao.eNormal)
        self.m_nLastResetTimeStamp = os.time()
        self:MarkDirty(true)
    end
end

function CBaoTu:SendBaoTuPosList()
    local tMsg = {PosList = {}}
    local tNorPos = {}
    tNorPos.nDupID = self.m_tNormalPos[1] or 0
    tNorPos.nPosX = self.m_tNormalPos[2] or 0
    tNorPos.nPosY = self.m_tNormalPos[3] or 0
    tNorPos.nWaBaoType = CBaoTu.tWaBao.eNormal
    table.insert(tMsg.PosList, tNorPos)
    local tSpePos = {}
    tSpePos.nDupID = self.m_tSpecailPos[1] or 0
    tSpePos.nPosX = self.m_tSpecailPos[2] or 0
    tSpePos.nPosY = self.m_tSpecailPos[3] or 0
    tSpePos.nWaBaoType = CBaoTu.tWaBao.eSpecial
    table.insert(tMsg.PosList, tSpePos)
    tMsg.bActShouHu = false --lkx todo 还没实现守护模块
    tMsg.nFreeTimes = ctBaoTuConf[1].nFreeTimes - self.m_nCompTimes
    self.m_oRole:SendMsg("WaBaoPosRet", tMsg)
end