--成就对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert



function CAchieveObj:Ctor(nID)
    self.m_nID =nID
    self.m_nDone = 0
    self.m_nDegree = 0
end

function CAchieveObj:LoadData(tData)
    if not tData then
        return 
    end
    self.m_nDone = tData.m_nDone
    self.m_nDegree = tData.m_nDegree
end

function CAchieveObj:SaveData()
    local tData = {} 
    tData.m_nDone = self.m_nDone
    tData.m_nDegree = self.m_nDegree
    return tData
end

function CAchieveObj:IsDone()
    if self.m_nDone ~= 0 then
        return true
    end
    return false
end

function CAchieveObj:CanReward()
    if self.m_nDone == 1 then
        return true
    end
    return false
end

function CAchieveObj:IsReward()
    if self.m_nDone == 2 then
        return true
    end
    return false
end

function CAchieveObj:SignReward()
    self.m_nDone = 2
end

function CAchieveObj:GetDone()
    return self.m_nDone
end

function CAchieveObj:GetAchieveConfigData()
    local tData = ctAchievementsConf[self.m_nID]
    return tData
end

function CAchieveObj:ReachDegreeTarget()
    local tData = self:GetAchieveConfigData()
    return tData["nTarget"]
end

function CAchieveObj:AchieveType()
    local tData = self:GetAchieveConfigData()
    return tData["nType"]
end

function CAchieveObj:AddDegree(nAdd)
    if self.m_nDone ~= 0 then
        return
    end
    self.m_nDegree = self.m_nDegree + nAdd
    self:CheckReachAchieve()
end

function CAchieveObj:SetDegree(nDegree)
    if self.m_nDone ~= 0 then
        return
    end
    self.m_nDegree = nDegree
    self:CheckReachAchieve()
end

function CAchieveObj:GetDegree()
    return self.m_nDegree
end

function CAchieveObj:ClearDegree()
    if self.m_nDone ~= 0 then
        return
    end
    self.m_nDegree = 0
end

function CAchieveObj:CheckReachAchieve()
    local iTargetDegree = self:ReachDegreeTarget()
    if self.m_nDegree >= iTargetDegree then
        self.m_nDone = 1
    end
end

function CAchieveObj:PackData()
    local tData = {}
    tData.nID = self.m_nID
    tData.nDegree = self.m_nDegree
    tData.nDone = self.m_nDone
    return tData
end

function CAchieveObj:GetRewardData()
    local tData = self:GetAchieveConfigData()
    return tData["tAward"]
end

function CAchieveObj:GiveReward(oRole)
    self:SignReward()
    local tData = self:GetRewardData()
    for _,tRewardData in pairs(tData) do
        local bBind,nItemID,nNum = table.unpack(tRewardData)
        oRole:AddItem(gtItemType.eProp,nItemID,nNum,"成就奖励",false,bBind)
    end
end
