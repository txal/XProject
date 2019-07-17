--竞技场称谓
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CAppellationArena:Ctor(oModule, nID, nConfID, tParam, nSubKey)
    CAppellationBase.Ctor(self, oModule, nID, nConfID, tParam, nSubKey)
    -- self.m_nArenaSeason = tParam.nArenaSeason or 1    --称号所属竞技场赛季 --废弃
end

function CAppellationArena:LoadData(tData)
    if not tData then 
        return 
    end
    CAppellationBase.LoadData(self, tData)
    -- self.m_nArenaSeason = tData.nArenaSeason
end

function CAppellationArena:SaveData()
    local tData = CAppellationBase.SaveData(self)
    -- tData.nArenaSeason = self.m_nArenaSeason
    return tData
end


