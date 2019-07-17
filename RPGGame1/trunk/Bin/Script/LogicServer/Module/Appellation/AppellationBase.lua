--称谓对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


--[tParam]应当是一个table，用来创建时携带一些必要数据，如称号名称相关参数，称号时间戳等
function CAppellationBase:Ctor(oModule, nID, nConfID, tParam, nSubKey)
    self.m_oModule = oModule
    self.m_nID = nID
    self.m_nConfID = nConfID
    self.m_tNameParam = tParam.tNameParam or {}
    self.m_nSubKey = nSubKey
    self.m_nTimeStamp = tParam.nTimeStamp or os.time()      --获得称号的时间戳，可能结拜、情缘等称号，需要根据时间有序
end

function CAppellationBase:LoadData(tData)
    if not tData then 
        return 
    end
    self.m_nConfID = tData.nConfID
    self.m_tNameParam = tData.tNameParam or {}
    self.m_nSubKey = tData.nSubKey
    self.m_nTimeStamp = tData.nTimeStamp
end

function CAppellationBase:SaveData()
    local tData = {}
    tData.nID = self.m_nID
    tData.nConfID = self.m_nConfID
    tData.tNameParam = self.m_tNameParam
    tData.nSubKey = self.m_nSubKey
    tData.nTimeStamp = self.m_nTimeStamp
    return tData
end

function CAppellationBase:GetConf() return ctAppellationConf[self.m_nConfID] end
function CAppellationBase:GetID() return self.m_nID end
function CAppellationBase:GetConfID() return self.m_nConfID end
function CAppellationBase:GetSubKey() return self.m_nSubKey end
function CAppellationBase:GetNameParam() return self.m_tNameParam end
function CAppellationBase:GetType() return self:GetConf().nType end


function CAppellationBase:IsExpired(nTimeStamp)
    return false
end

function CAppellationBase:GetBattleAttr() 
    local tConf = self:GetConf()
    if not tConf then 
        return {}
    end
    local tAttrList = {}
    for k, v in ipairs(tConf.tAttr) do
        if v[1] > 0 and v[2] ~= 0 then  
            tAttrList[v[1]] = v[2]
        end
    end
    return tAttrList
end

function CAppellationBase:IsEquiped()
    local oAppeObj = self.m_oModule:GetDisplayAppellation()
    if not oAppeObj then 
        return false
    end
    if oAppeObj:GetID() == self:GetID() then 
        return true
    end
    return false
end

-- function CAppellationBase:GetName()
--     local tConf = self:GetConf()
--     local sName= string.format(tConf.sName, table.unpack(self.m_tNameParam))
--     return sName
-- end

function CAppellationBase:Update(tParam)
    assert(tParam and (type(tParam) == "table"))
    if tParam.tNameParam then 
        self.m_tNameParam = tParam.tNameParam
    end
    -- if tParam.nTimeStamp then 
    --     self.m_nTimeStamp = tParam.nTimeStamp
    -- end
end

--生成返回protobuf协议数据
function CAppellationBase:GetPBData()
    local tData = {}
    tData.nID = self:GetID()
    tData.nConfID = self:GetConfID()
    tData.tNameParam = self:GetNameParam()
    tData.nTimeStamp = self.m_nTimeStamp
    if self.m_nExpiryTime and self.m_nExpiryTime > 0 then 
        tData.nExpiryTime = self.m_nExpiryTime
    end
    return tData
end


