--时间管理对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
--CToday记录当天玩法信息次数
--CThisWeek记录每周玩法信息次数
--CThisTemp记录一段时间内玩法信息次数
--CSeveralDay记录诺干天内玩法信息次数
--基础类放在common/Time下

--时间管理
function CTime:Ctor(oRole)
    self.m_oRole = oRole
    self:Init()
end

function CTime:Init()
    local nID = self.m_oRole:GetID()
    self.m_oToday = CToday:new(nID)
    self.m_oThisWeek = CThisWeek:new(nID)
    self.m_oThisTemp = CThisTemp:new(nID)
    self.m_oSeveralDay = CSeveralDay:new(nID)
    local tTimeList = {
        ["today"] = self.m_oToday,
        ["week"] = self.m_oThisWeek,
        ["temp"] = self.m_oThisTemp,
        ["severalday"] = self.m_oSeveralDay
    }
    self.m_tList = tTimeList
end

function CTime:GetType(oRole)
    return gtModuleDef.tTimeData.nID, gtModuleDef.tTimeData.sName
end

function CTime:Online()
end

function CTime:SaveData()
    if not self:IsDirty() then
        return
    end
    self:UnDirty()
    local tSaveData = {}
    local tData = {}
    for sKey,oSaveObj in pairs(self.m_tList) do
        tData[sKey] = oSaveObj:SaveData()
    end
    tSaveData["data"]  = tData
    return tSaveData
end

function CTime:LoadData(tData)
    tData = tData or {}
    local tLoadData = tData["data"] or {}
    for sKey,tTimeData in pairs(tLoadData) do
        local oTimeObj = self.m_tList[sKey]
        if oTimeObj then
            oTimeObj:LoadData(tTimeData)
        end
    end
end

function CTime:GetTimeObj(sName)
    return self.m_tList[sName]
end

function CTime:IsDirty()
    for _,oObj in pairs(self.m_tList) do
        if oObj:IsDirty() then
            return true
        end
    end
    return false
end

function CTime:UnDirty()
    for _,oObj in pairs(self.m_tList) do
        if oObj:IsDirty() then
            oObj:MarkDirty(false)
        end
    end
end



