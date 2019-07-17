--帮会职务称号
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CAppellationUnionPos:Ctor(oModule, nID, nConfID, tParam, nSubKey)
    CAppellationBase.Ctor(self, oModule, nID, nConfID, tParam, nSubKey)
    self.m_nUnionID = tParam.nUnionID or 0
end

function CAppellationUnionPos:LoadData(tData)
    if not tData then 
        return 
    end
    CAppellationBase.LoadData(self, tData)
    self.m_nUnionID = tData.nUnionID
end

function CAppellationUnionPos:SaveData()
    local tData = CAppellationBase.SaveData(self)
    tData.nUnionID = self.m_nUnionID
    return tData
end

function CAppellationUnionPos:Update(tParam)
    CAppellationBase.Update(self, tParam)
    if tParam.nUnionID and tParam.nUnionID > 0 then 
        self.m_nUnionID = tParam.nUnionID
    end
end

