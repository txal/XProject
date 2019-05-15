--兑换活动
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

CExchangeActivity.tState = 
{
    eInit = 0,          --初始状态
    eBegin = 1,         --开启中
    eEnd = 2,           --结束中
}
function CExchangeActivity:Ctor(nID)
    self.m_nID = nID
    self.m_nBeginTimestamp = 0
    self.m_nEndTimestamp = 0
    self.m_nState = CExchangeActivity.tState.eInit

    self.m_tRoleInfoMap = {}        --{[RoleID]={[ExchangeID]=times, bIsClick=false}
    self.m_tRoleJoinTimeMap = {}    --{[RoleID]=JoinTimestamp}
    self:Init()
end

function CExchangeActivity:Init()
    --计算开始时间、结束时间
    assert(ctExchangeOpenConf[self.m_nID], "没有此兑换活动开启关闭配置")
    local tConf = ctExchangeOpenConf[self.m_nID]
    local bIsForever = tConf.bIsForever
    if bIsForever then
        self.m_nState = CExchangeActivity.tState.eBegin         --永久的设置开启
    else
        self.m_nBeginTimestamp = os.Str2Time(tConf.sOpenTime)
        self.m_nEndTimestamp = os.Str2Time(tConf.sCloseTime)
        self:MarkDirty(true) 
    end
end

function CExchangeActivity:LoadData(tData)
    if tData then
        --上次活动结束后开启结束时间设置为0，这里使用读配置新的开启关闭时间
        self.m_nBeginTimestamp = tData.m_nBeginTimestamp > 0 and tData.m_nBeginTimestamp or self.m_nBeginTimestamp
        self.m_nEndTimestamp = tData.m_nEndTimestamp > 0 and tData.m_nEndTimestamp or self.m_nEndTimestamp
        self.m_tRoleInfoMap = tData.m_tRoleInfoMap or {}
    end
    self:CheckState()
end

function CExchangeActivity:SaveData()
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)
    local tData = {}
    tData.m_tRoleInfoMap = self.m_tRoleInfoMap
    tData.m_nBeginTimestamp = self.m_nBeginTimestamp
    tData.m_nEndTimestamp = self.m_nEndTimestamp
    return tData
end

function CExchangeActivity:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CExchangeActivity:IsDirty() return self.m_bDirty end

function CExchangeActivity:OnHourTimer()
    self:CheckState()
end

function CExchangeActivity:CheckState()
    --更新状态
    --print(">>>>>>>>>>>>>>>>>>>>>>>检查状态："..self.m_nID)
    -- print(">>>>>>>>>>>>>开启时间", os.date("%c", self.m_nBeginTimestamp))
    -- print(">>>>>>>>>>>>>关闭时间", os.date("%c", self.m_nEndTimestamp))
    
    local tConf = ctExchangeOpenConf[self.m_nID]
    local bIsForever = tConf.bIsForever
    if bIsForever then return end
    local nNowSec = os.time()
    if 0 < self.m_nBeginTimestamp and nNowSec < self.m_nBeginTimestamp then
        if self.m_nState ~= CExchangeActivity.tState.eInit then
            self.m_nState = CExchangeActivity.tState.eInit
        end
    elseif 0 < self.m_nBeginTimestamp and 0 < self.m_nEndTimestamp and self.m_nBeginTimestamp <= nNowSec and nNowSec < self.m_nEndTimestamp then
        if self.m_nState ~= CExchangeActivity.tState.eBegin then
            self.m_nState = CExchangeActivity.tState.eBegin
            --print(">>>>>>>>>>>>>>>>>>>>>>兑换活动开启: "..self.m_nID)
            self:SendStateChangeNotic()
        end
    elseif 0 < self.m_nBeginTimestamp and 0 < self.m_nEndTimestamp and self.m_nBeginTimestamp < nNowSec and self.m_nEndTimestamp <= nNowSec then
        if self.m_nState ~= CExchangeActivity.tState.eEnd then
            self.m_nState = CExchangeActivity.tState.eEnd
            --print(">>>>>>>>>>>>>>>>>>>>>>兑换活动关闭: "..self.m_nID)
            self.m_nBeginTimestamp = 0
            self.m_nEndTimestamp = 0
            self:SendStateChangeNotic()
        end
    end
end

function CExchangeActivity:GetState()
    return self.m_nState
end

function CExchangeActivity:Online(oRole)
    if self.m_nState == CExchangeActivity.tState.eBegin then
        local nRoleID = oRole:GetID()
        local nLastJoinTime = self.m_tRoleJoinTimeMap[nRoleID] or 0
        if not self:IsInActOpenTime(nLastJoinTime) then
            local tActConf = ctExchangeActivityConf.GetActConf(self.m_nID)
            self.m_tRoleInfoMap[nRoleID] = self.m_tRoleInfoMap[nRoleID] or {}
            for nExchangeID, tConf in pairs(tActConf) do
                self.m_tRoleInfoMap[nRoleID][nExchangeID] = 0       --清空数据
            end
            self:SetIsClick(nRoleID, false)
            self:MarkDirty(true)
        end
    end
end

function CExchangeActivity:IsInActOpenTime(nJoinTimestamp)
    if ctExchangeOpenConf[self.m_nID].bIsForever then
        return true
    else
        if 0 < self.m_nBeginTimestamp and 0 < self.m_nEndTimestamp and self.m_nBeginTimestamp <= nJoinTimestamp and nJoinTimestamp < self.m_nEndTimestamp then
            return true
        else
            return false
        end
    end
end

function CExchangeActivity:UpdateExchangeTimes(nRoleID, nExchangeID)
    self.m_tRoleInfoMap[nRoleID][nExchangeID] = self.m_tRoleInfoMap[nRoleID][nExchangeID] + 1
    self:MarkDirty(true)
end

function CExchangeActivity:UpdateJoinTimestamp(nRoleID, nJoinTimestamp)
    self.m_tRoleJoinTimeMap[nRoleID] = self.m_tRoleJoinTimeMap[nRoleID] or 0
    if not self:IsInActOpenTime(self.m_tRoleJoinTimeMap[nRoleID]) then        --记录的参加时间戳不在本次活动开启内才记录
        self.m_tRoleJoinTimeMap[nRoleID] = nJoinTimestamp
    end
    self:MarkDirty(true)
end

function CExchangeActivity:SetIsClick(nRoleID, bState)
    self.m_tRoleInfoMap[nRoleID] = self.m_tRoleInfoMap[nRoleID] or {}
    self.m_tRoleInfoMap[nRoleID].bIsClick = bState
    self:MarkDirty(true)
end

function CExchangeActivity:GetIsClick(nRoleID)
    self.m_tRoleInfoMap[nRoleID] = self.m_tRoleInfoMap[nRoleID] or {}
    return self.m_tRoleInfoMap[nRoleID].bIsClick or false
end

function CExchangeActivity:GetExchangeTimes(nRoleID, nExchangeID)
    self.m_tRoleInfoMap[nRoleID] = self.m_tRoleInfoMap[nRoleID] or {}
    local nTimes = self.m_tRoleInfoMap[nRoleID][nExchangeID]
    return nTimes ~= nil and nTimes or 0
end

function CExchangeActivity:GetRoleData(nRoleID)

    self.m_tRoleInfoMap[nRoleID] = self.m_tRoleInfoMap[nRoleID] or {}
    return self.m_tRoleInfoMap[nRoleID]
end

function CExchangeActivity:SendStateChangeNotic()
    local tMsg = {}
    tMsg.nActID = self.m_nID
    tMsg.nState = self.m_nState

    local tSessionMap = goGPlayerMgr:GetRoleSSMap()
    for nSession, oTmpRole in pairs(tSessionMap) do
        oTmpRole:SendMsg("ActStateChangeNoticRet", tMsg)
    end
end

