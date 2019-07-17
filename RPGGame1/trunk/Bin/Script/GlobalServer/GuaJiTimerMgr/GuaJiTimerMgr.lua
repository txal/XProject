--挂机自动奖励计时器管理器(在本地服和世界服切换不好维护计时器)
--进入副本时通知全局中的此计时器停止奖励，离开副本时通知此计时器开始奖励
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGuaJiTimerMgr:Ctor()
    self.m_tRoleTimerMap = {}       --{[nRole]=oTimer}
end

function CGuaJiTimerMgr:Release()
    for nRoleID, oGuaJiTimerObj in pairs(self.m_tRoleTimerMap) do
        oGuaJiTimerObj:Release()
    end
end

function CGuaJiTimerMgr:OnRoleRelease(oRole)
    self:ClearGuaJiTimerObj(oRole:GetID())
end

function CGuaJiTimerMgr:Offline(nRoleID)
    self:ClearGuaJiTimerObj(nRoleID)
end

function CGuaJiTimerMgr:StartGuaJiAutoReward(nRoleID, nGuanQia)
    local oGuaJiTimerObj = self:GetAutoRewardTimer(nRoleID)
    if not oGuaJiTimerObj then
        oGuaJiTimerObj = CGuaJiTimerObj:new(nRoleID)
        self.m_tRoleTimerMap[nRoleID] = oGuaJiTimerObj
    end
    if oGuaJiTimerObj then
        if oGuaJiTimerObj:IsAutoReward() then return end
        oGuaJiTimerObj:RegAutoReward(nRoleID, nGuanQia)
    end
end

function CGuaJiTimerMgr:StopGuaJiAutoReward(nRoleID)
    local oGuaJiTimerObj = self:GetAutoRewardTimer(nRoleID)
    if oGuaJiTimerObj then
        if not oGuaJiTimerObj:IsAutoReward() then return end
        oGuaJiTimerObj:ClearAutoReward()
    end
end

function CGuaJiTimerMgr:ClearGuaJiTimerObj(nRoleID)
    local oGuaJiTimerObj = self:GetAutoRewardTimer(nRoleID)
    if oGuaJiTimerObj then
        oGuaJiTimerObj:ClearAutoReward()
        self.m_tRoleTimerMap[nRoleID] = nil
    end
end

function CGuaJiTimerMgr:GetAutoRewardTimer(nRoleID)
    if not nRoleID then
		return
    end
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then
		return
    end
    return self.m_tRoleTimerMap[nRoleID]
end

function CGuaJiTimerMgr:IsGuaJi(nRoleID)
    local oGuaJiTimerObj = self:GetAutoRewardTimer(nRoleID)
    if oGuaJiTimerObj then
        return oGuaJiTimerObj:IsGuaJi()
    end
    return false
end

function CGuaJiTimerMgr:SetIsAutoBattle(nRoleID, tData)
    local oGuaJiTimerObj = self:GetAutoRewardTimer(nRoleID)
    if not oGuaJiTimerObj then
        oGuaJiTimerObj = CGuaJiTimerObj:new(nRoleID)
        self.m_tRoleTimerMap[nRoleID] = oGuaJiTimerObj
    end
    oGuaJiTimerObj:SetIsAutoBattle(tData.bAutoBattle)
end

function CGuaJiTimerMgr:GetIsAutoBattle(nRoleID)
    local oGuaJiTimerObj = self:GetAutoRewardTimer(nRoleID)
    if oGuaJiTimerObj then
        return oGuaJiTimerObj:GetIsAutoBattle()
    end
    return false
end



------------------------------------------------------------
function CGuaJiTimerObj:Ctor(nRoleID)
    self.m_nRoleID = nRoleID
    self.m_bIsAutoReward = false
    self.m_nAutoRewardTimer = nil
    self.m_bAutoBattle = false              --是否自动战斗    
end

function CGuaJiTimerObj:Release()
    self:ClearAutoReward()
end

function CGuaJiTimerObj:IsAutoReward()
    return self.m_bIsAutoReward
end

function CGuaJiTimerObj:RegAutoReward(nRoleID, nGuanQia)
    GetGModule("TimerMgr"):Clear(self.m_nAutoRewardTimer)
    local tGuanQiaConf = ctGuaJiConf:GetGuanQiaConf(nGuanQia)
    self.m_nAutoRewardTimer = GetGModule("TimerMgr"):Interval(3*tGuanQiaConf.nPatrolSec, function() self:AutoReward() end)
end

function CGuaJiTimerObj:ClearAutoReward()
    GetGModule("TimerMgr"):Clear(self.m_nAutoRewardTimer)
    self.m_nAutoRewardTimer = nil
    self.m_bAutoBattle = false
end

function CGuaJiTimerObj:AutoReward()
    --通知本地服奖励
    local oRole = goGPlayerMgr:GetRoleByID(self.m_nRoleID)
    if not oRole or not oRole:IsOnline() then
		self:ClearAutoReward()
		return
    end
    local function CallBack(bRewardSucc)
       if not bRewardSucc then
            self:ClearAutoReward()
       end
   end
    Network.oRemoteCall:CallWait("GuaJiReward", CallBack, oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID())
end

function CGuaJiTimerObj:IsGuaJi()
    if self.m_nAutoRewardTimer and self.m_nAutoRewardTimer > 0 then
        return true
    else
        return false
    end
end

function CGuaJiTimerObj:GetIsAutoBattle()
    return self.m_bAutoBattle
end

function CGuaJiTimerObj:SetIsAutoBattle(bAutoBattle)
    self.m_bAutoBattle = bAutoBattle
end
