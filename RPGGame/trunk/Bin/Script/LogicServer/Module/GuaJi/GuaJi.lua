local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGuaJi:Ctor(oRole)
    self.m_oRole = oRole
	self.m_nGuanQia = 1						--当前关卡
	self.m_nBattleTimes = 0					--当前关卡内战斗次数
    self.m_nLastRewardTimeStamp = 0			--上次奖励时间戳
    self.m_nLeaveGuaJiDupTime = 0           --离开时间起始时间戳
    self.m_tLeaveReward = {}                --离开收益{[nCurrType]=nValue}
    self.m_tBossRewardMap = {}              --boss关卡奖励{[nGuanQia]={}}
end

function CGuaJi:LoadData(tData)
    if tData then
        self.m_nGuanQia = tData.m_nGuanQia or self.m_nGuanQia
        self.m_nBattleTimes = tData.m_nBattleTimes or self.m_nBattleTimes
        self.m_nLastRewardTimeStamp = tData.m_nLastRewardTimeStamp or self.m_nLastRewardTimeStamp
        self.m_nLeaveGuaJiDupTime = tData.m_nLeaveGuaJiDupTime or self.m_nLeaveGuaJiDupTime
        self.m_tLeaveReward = tData.m_tLeaveReward or self.m_tLeaveReward
    end
    --首次初始化数据
    if self.m_nLastRewardTimeStamp <= 0 then
        self.m_nGuanQia = 1
        self.m_nLastRewardTimeStamp = os.time()
        self:MarkDirty(true)
        CEventHandler:ChalGuaJiGuanQia(self.m_oRole, {nGuanQia=self.m_nGuanQia})
    end
end

function CGuaJi:SaveData()
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)

    local tData = {}
    tData.m_nGuanQia = self.m_nGuanQia
    tData.m_nBattleTimes = self.m_nBattleTimes
    tData.m_nLastRewardTimeStamp = self.m_nLastRewardTimeStamp
    tData.m_nLeaveGuaJiDupTime = self.m_nLeaveGuaJiDupTime
    tData.m_tLeaveReward = self.m_tLeaveReward
    return tData
end

function CGuaJi:GetType()
    return gtModuleDef.tGuaJi.nID, gtModuleDef.tGuaJi.sName
end

function CGuaJi:GetGuanQiaAndBattleTimes()
	return self.m_nGuanQia, self.m_nBattleTimes
end

function CGuaJi:SetNextGuanQia(nCurrGuanQia)  --??? is it necessary?
    assert(nCurrGuanQia >= 0, "设置挂机关卡参数错误："..nCurrGuanQia)
    local tGuanQiaConf = ctGuaJiConf:GetGuanQiaConf(nCurrGuanQia)
    if nCurrGuanQia + 1 <= tGuanQiaConf.nMaxGuanQia or ctGuaJiConf[tGuanQiaConf.nSeq+1] then            --关卡增加
        self.m_nGuanQia = self.m_nGuanQia + 1  -- ????
        self:SendGuanQiaInfo()
        CEventHandler:ChalGuaJiGuanQia(self.m_oRole, {nGuanQia=self.m_nGuanQia})
    else
        -- if ctGuaJiConf[tGuanQia.nSeq+1] then                        --关卡seq增加
        --     self.m_nGuanQia = self.m_nGuanQia + 1
        --     self:MarkDirty(true)
        --     self:SendGuanQiaInfo()
        -- else
        --     --所有关卡打完，一直重复最后一关
        -- end
    end
    --print(">>>>>>>>>>>>>>设置当前关卡", self.m_nGuanQia)
end

function CGuaJi:SetTargetGuanQia(nTarget, nBattleTimes)
    local tGuanQiaConf = ctGuaJiConf:GetGuanQiaConf(nTarget)
    if tGuanQiaConf then            --关卡增加
        self.m_nGuanQia = nTarget
        if nBattleTimes and nBattleTimes >= 0 then 
            self:SetBattleTimes(nBattleTimes)
        end
        self:MarkDirty(true)
        -- self:SendGuanQiaInfo()
        -- CEventHandler:ChalGuaJiGuanQia(self.m_oRole, {nGuanQia=self.m_nGuanQia})
    end
end

function CGuaJi:SetBattleTimes(nTimes)
    assert(nTimes >= 0, "设置挂机战斗次数参数错误："..nTimes)
    self.m_nBattleTimes = nTimes
    self:MarkDirty(true)
end

--在非挂机场景自动奖励
function CGuaJi:AutoReward()
    local oBattleDup = goBattleDupMgr:GetBattleDup(self.m_oRole:GetBattleDupID())
    if oBattleDup and oBattleDup:GetType() == gtBattleDupType.eGuaJi then
        return false
    else
        --print(">>>>>>>>>>>>>>>>>>非挂机场景奖励")
        local nGuanQia, nBattleTimes = self:GetGuanQiaAndBattleTimes()
        self:Reward(true)
        return true
    end
    -- local nGuanQia, nBattleTimes = self:GetGuanQiaAndBattleTimes()
    -- self:Reward(true)
    -- return true
end

function CGuaJi:Reward(bNotInGuaJiDup)
    local nGuanQia, nBattleTimes = self:GetGuanQiaAndBattleTimes()
    local tGuanQiaConf = ctGuaJiConf:GetGuanQiaConf(nGuanQia)
    local nRoleExp = math.floor(tGuanQiaConf.fnRoleExpReward(tGuanQiaConf.nPatrolSec, nGuanQia))
    local nPetExp = math.floor(tGuanQiaConf.fnPetExpReward(tGuanQiaConf.nPatrolSec, nGuanQia))
    local nYinBi = math.floor(tGuanQiaConf.fnYinBiReward(tGuanQiaConf.nPatrolSec, nGuanQia))
    self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleExp, "挂机奖励", true, false, {bNoTips=bNotInGuaJiDup})
    self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nPetExp, "挂机奖励", true, false, {bNoTips=bNotInGuaJiDup})
    self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nYinBi, "挂机奖励", true, false, {bNoTips=bNotInGuaJiDup})

    local nRandNum = math.random(100)
    if nRandNum <= tGuanQiaConf.nMonRewardPre then
        local nRoleLevel = self.m_oRole:GetLevel()
        local tRewardPool = ctAwardPoolConf.GetPool(tGuanQiaConf.tMonReward[1][1], nRoleLevel, self.m_oRole:GetConfID())
        local function GetItemWeight(tConf)
            return tConf.nWeight
        end
        local tRewardItemList = CWeightRandom:Random(tRewardPool, GetItemWeight, tGuanQiaConf.tMonReward[1][2], false)
        for nIndex, tReward in pairs(tRewardItemList) do
            self.m_oRole:AddItem(gtItemType.eProp, tReward.nItemID, tReward.nItemNum, "挂机小怪奖励")
        end
    end
    --非挂机场景的才累计
    if bNotInGuaJiDup then
        self.m_tLeaveReward[gtCurrType.eExp] = (self.m_tLeaveReward[gtCurrType.eExp] or 0) + nRoleExp
        self.m_tLeaveReward[gtCurrType.ePetExp] = (self.m_tLeaveReward[gtCurrType.ePetExp] or 0) + nPetExp
        self.m_tLeaveReward[gtCurrType.eYinBi] = (self.m_tLeaveReward[gtCurrType.eYinBi] or 0) + nYinBi
    end
    self.m_nLastRewardTimeStamp = os.time()
    self:SetBattleTimes(nBattleTimes+1)
    self:MarkDirty(true)
    --PrintTable(self.m_tLeaveReward)
end

function CGuaJi:ClearLeaveRewardData()
    self.m_tLeaveReward[gtCurrType.eExp] = 0
    self.m_tLeaveReward[gtCurrType.ePetExp] = 0
    self.m_tLeaveReward[gtCurrType.eYinBi] = 0
    self:MarkDirty(true)
    --print(">>>>>>>>>>>>>>清空非挂机场景累积数据")
    --PrintTable(self.m_tLeaveReward)
end

function CGuaJi:SetLeaveTimestamp()
    self.m_nLeaveGuaJiDupTime = os.time()
    self:MarkDirty(true)
end

function CGuaJi:GetLeaveTimestamp()
    return self.m_nLeaveGuaJiDupTime
end

function CGuaJi:Online()
    --奖励离线经验
    local nOfflineTime = self.m_oRole:GetOfflineTime()   
    local nOnlineTime = self.m_oRole:GetOnlineTime()
    nOfflineTime = (nOfflineTime > 0) and nOfflineTime or nOnlineTime     --新号登录让计算的离线时间等于登录时间(其实新号是没离线时间)
    --这里处理完后
    self:MarkDirty(true)
    self:SendGuaJiRet()
    local nGuanQia = self:GetGuanQiaAndBattleTimes()
    local tGuanQiaConf = ctGuaJiConf:GetGuanQiaConf(nGuanQia)
    local nOfflineMin = math.ceil((nOnlineTime - nOfflineTime)/60)
    local nUseCalMin = (nOfflineMin > tGuanQiaConf.nMaxOfflineMin) and tGuanQiaConf.nMaxOfflineMin or nOfflineMin
    local nRoleExp = tGuanQiaConf.fnOfflineRoleExp(nUseCalMin, nGuanQia)
    local nPetExp = tGuanQiaConf.fnOfflinePetExp(nUseCalMin, nGuanQia)
    local nYinBi = tGuanQiaConf.fnOfflineYinBi(nUseCalMin, nGuanQia)
    self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleExp, "挂机离线奖励", true)
    self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nPetExp, "挂机离线奖励", true)
    self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nYinBi, "挂机离线奖励", true)
    local tRewardItemConf = self:GetOfflineRewardItemConf(nUseCalMin)
    local tData = {tItemList={}}    
    local tRewardList = {}
    if tRewardItemConf then
        for nIndex, tPoolItem in pairs(tRewardItemConf.tRewardPool) do
            local tPool = ctAwardPoolConf.GetPool(tPoolItem[1], self.m_oRole:GetLevel(), self.m_oRole:GetConfID())
            if next(tPool) then
                local function GetItemWeight(tConf)
                    return tConf.nWeight
                end
                local tRewardItemList = CWeightRandom:Random(tPool, GetItemWeight, tPoolItem[2], false)
                for nIndex, tReward in pairs(tRewardItemList) do
                    -- self.m_oRole:AddItem(gtItemType.eProp, tReward.nItemID, tReward.nItemNum, "挂机离线奖励", true, false, {bNoTips=true})
                    local tRewardItem = {}
                    tRewardItem.nType = gtItemType.eProp
                    tRewardItem.nID = tReward.nItemID
                    tRewardItem.nNum = tReward.nItemNum
                    tRewardItem.tPropExt = {bNoTips=true}
                    table.insert(tRewardList, tRewardItem)
                    table.insert(tData.tItemList, {nItemType=gtItemType.eProp, nItemID=tReward.nItemID, nItemNum=tReward.nItemNum})
                end
            end
        end
    end
    if #tRewardList > 0 then 
        self.m_oRole:AddItemList(tRewardList, "挂机离线奖励")
    end
    tData[gtCurrType.eExp] = nRoleExp
    tData[gtCurrType.ePetExp] = nPetExp
    tData[gtCurrType.eYinBi] = nYinBi
    self:SendLeaveRewardInfo(2, tData)
    self:ClearLeaveRewardData()         --上线的时候清空记录的数据，切换的时候不调用Online
    self:SendGuanQiaInfo()
    self:SetLeaveTimestamp()

    -- 5830
    -- 需求：玩家每次上线，无论在哪个场景，都触发挂机状态（不用切场景，触发即可）。
    -- 此需求需要三项目同步
    local nServerID = self.m_oRole:GetServer()
	goRemoteCall:Call("StartGuaJiAutoReward", nServerID, goServerMgr:GetGlobalService(nServerID,20), 0, self.m_oRole:GetID(), {nGuanQia=nGuanQia})
end

function CGuaJi:SendGuaJiRet()
    local function SendGuaJiStatus(bIsGuaJi)
        self.m_oRole:SendMsg("GuaJiRet", {bIsDuringGuaJi=bIsGuaJi})
    end
    local nServerID = self.m_oRole:GetServer()
    goRemoteCall:CallWait("IsGuaJi", SendGuaJiStatus, nServerID, goServerMgr:GetGlobalService(nServerID,20), 0, self.m_oRole:GetID())
end

function CGuaJi:SendGuanQiaInfo()
    local tMsg = {}
    tMsg.nCurrGuanQia = self.m_nGuanQia
    local tConf = ctGuaJiConf:GetGuanQiaConf(self.m_nGuanQia)
    tMsg.nGuanQiaSeqID = tConf.nSeq
    self.m_oRole:SendMsg("GuaJiGuanQiaRet", tMsg)
end

--离开收益(有离开场景的，离线的收益)
function CGuaJi:SendLeaveRewardInfo(nLeaveType, tData)     --离开类型：1.离开挂机场景, 2.离线
    if not self.m_oRole:IsRobot() then
        local tMsg = {tItemList={}}
        if nLeaveType == 1 then
            tMsg.nPassMin = (self.m_nLeaveGuaJiDupTime > 0) and math.ceil((os.time() - self.m_nLeaveGuaJiDupTime) / 60) or 0
        else
            local nMin = math.ceil((self.m_oRole:GetOnlineTime()-self.m_oRole:GetOfflineTime())/60)
            local nMaxMin = 8 * 60
            tMsg.nPassMin = nMin >= nMaxMin and nMaxMin or nMin
        end
        tMsg.nRoleExp = tData[gtCurrType.eExp]
        tMsg.nPetExp = tData[gtCurrType.ePetExp]
        tMsg.nYinBi = tData[gtCurrType.eYinBi]
        if tData.tItemList then
            for nIndex, tItem in pairs(tData.tItemList) do
                table.insert(tMsg.tItemList, tItem)
            end
        end
        self.m_oRole:SendMsg("RewardInfoRet", tMsg) 
        -- print(">>>>>>>>>>>>>>离开挂机的收益")
        --PrintTable(tMsg)
    end
end

function CGuaJi:GetOfflineRewardItemConf(nMin)
    for nSeq, tConf in pairs(ctGuaJiOfflineRewardConf) do
        if tConf.nMinTime <= nMin and nMin <= tConf.nMaxTime then
            return tConf
        end
    end
end



