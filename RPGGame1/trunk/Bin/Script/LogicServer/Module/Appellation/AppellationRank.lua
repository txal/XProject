--排行榜临时称谓
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--tParam{nExpiryTime} 过期字段必须指定
function CAppellationRank:Ctor(oModule, nID, nConfID, tParam, nSubKey)
    CAppellationBase.Ctor(self, oModule, nID, nConfID, tParam, nSubKey)
    self.m_nExpiryTime = tParam.nExpiryTime or 0
end

function CAppellationRank:LoadData(tData)
    if not tData then 
        return 
    end
    CAppellationBase.LoadData(self, tData)
    self.m_nExpiryTime = tData.nExpiryTime or self.m_nExpiryTime
end

function CAppellationRank:SaveData()
    local tData = CAppellationBase.SaveData(self)
    tData.nExpiryTime = self.m_nExpiryTime
    return tData
end

function CAppellationRank:IsExpired(nTimeStamp)
    nTimeStamp = nTimeStamp or os.time()
    if self.m_nExpiryTime <= nTimeStamp then
        return true
    end
    return false
end
