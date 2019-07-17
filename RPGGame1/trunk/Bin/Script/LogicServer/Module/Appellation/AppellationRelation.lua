--玩家称谓
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CAppellationRelation:Ctor(oModule, nID, nConfID, tParam, nSubKey)
    CAppellationBase.Ctor(self, oModule, nID, nConfID, tParam, nSubKey)
end

function CAppellationRelation:LoadData(tData)
    if not tData then 
        return 
    end
    CAppellationBase.LoadData(self, tData)
end

function CAppellationRelation:SaveData()
    local tData = CAppellationBase.SaveData(self)
    return tData
end
