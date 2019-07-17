--时间管理对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
--CToday 记录当天玩法信息次数
--CThisWeek 记录每周玩法信息次数
--CThisTemp 记录一段时间内玩法信息次数
--CSeveralDay 记录诺干天内玩法信息次数

--2017/1/2 0:0:0 (不能改)
local nStandTime = 1483286400

local function _GetDayNo(nSecs)
    local nSecs = nSecs or os.time()
    local nTime = nSecs - nStandTime
    local nDayNo = math.floor(nTime // (3600*24))
    return nDayNo
end

function _GetWeekNo(nSec)
    local nSec = nSec or os.time()
    local nTime = nSec - nStandTime
    local nWeekNo = math.floor(nTime//(7*3600*24))
    return nWeekNo
end

-------------------------------------------------------------------------------当天次数
function CToday:Ctor(nID)
    self.m_nID = nID
    self.m_tData = {}
    self.m_tKeepList = {}
end

function CToday:LoadData(tData)
    tData = tData or {}
    self.m_tData = tData["data"] or {}
    self.m_tKeepList = tData["keeplist"] or {}
end

function CToday:SaveData()
    local tData = {}
    tData["data"] = self.m_tData
    tData["keeplist"] = self.m_tKeepList
    return tData
end

function CToday:_SetData(k, v)
    if not self.m_tData then
        self.m_tData = {}
    end
    self.m_tData[k] = v
end

function CToday:_GetData(k, rDefault)
    if not self.m_tData then
        self.m_tData = {}
    end
    return self.m_tData[k] or rDefault
end

function CToday:_GetTimeNo()
    return _GetDayNo()
end

function CToday:_Validate(key)
    local nDayNo = self.m_tKeepList[key]
    if not nDayNo then
        return
    end
    if nDayNo >= self:_GetTimeNo() then
        return
    end
    self:_SetData(key,nil)
    self.m_tKeepList[key] = nil
end

function CToday:Add(key,nValue)
    self:_Validate(key)
    local nOldValue = self:_GetData(key,0)
    nOldValue = nOldValue + nValue
    self:_SetData(key,nOldValue)
    self.m_tKeepList[key] = self:_GetTimeNo()
end

function CToday:Set(key,nValue)
    self:_Validate(key)
    self:_SetData(key,nValue)
    self.m_tKeepList[key] = self:_GetTimeNo()
end

function CToday:Query(key,rDefault)
    self:_Validate(key)
    return self:_GetData(key,rDefault)
end

function CToday:Delete(key)
    if not self:_GetData(key) then
        return
    end
    self:_SetData(key,nil)
    self.m_tKeepList[key] =nil
end

function CToday:ClearData()
    self.m_tKeepList = {}
    self.m_tData = {}
end

---------------------------------------------------------------------------一周内
function CThisWeek:Ctor(nID)
    CToday.Ctor(self,oModule, nID)
    self.m_nID = nID
    self.m_tData = {}
    self.m_tKeepList = {}
end

function CThisWeek:_GetTimeNo()
    return _GetWeekNo()
end


--------------------------------------------------------------------------连续一段时间内次数
function CThisTemp:Ctor(nID)
    self.m_nID = nID
    self.m_tData = {}
    self.m_tKeepList = {}
end

function CThisTemp:LoadData(tData)
    tData = tData or {}
    self.m_tData = tData["data"] or self.m_tData
    self.m_tKeepList = tData["keeplist"] or self.m_tKeepList
end

function CThisTemp:SaveData()
    local tData = {}
    tData["data"] =self.m_tData
    tData["keeplist"] = self.m_tKeepList
    return tData
end

function CThisTemp:_SetData(k, v)
    if not self.m_tData then
        self.m_tData = {}
    end
    self.m_tData[k] = v
end

function CThisTemp:_GetData(k, rDefault)
    if not self.m_tData then
        self.m_tData = {}
    end
    return self.m_tData[k] or rDefault
end

function CThisTemp:_GetTimeNo()
    return os.time()
end

function CThisTemp:_Validate(key)
    local nSecs = self.m_tKeepList[key]
    if not nSecs then
        return
    end
    if nSecs >= self:_GetTimeNo() then
        return
    end
    self:_SetData(key,nil)
    self.m_tKeepList[key] = nil
end

function CThisTemp:Add(key,value,nSecs)
    self:_Validate(key)
    nSecs = nSecs or 30
    local nValue = self:_GetData(key)
    if not nValue then
        self:_SetData(key,value)
        self.m_tKeepList[key] = nSecs + self:_GetTimeNo()
    else
        nValue = nValue + value
        self:_SetData(key,nValue)
    end
end

function CThisTemp:Set(key,value,nSecs)
    self:_Validate(key)
    nSecs = nSecs or 30
    local nValue = self:_GetData(key)
    if not nValue then
        self:_SetData(key,value)
        self.m_tKeepList[key] = nSecs + self:_GetTimeNo()
    else
        self:_SetData(key,value)
    end
end

function CThisTemp:Delete(key)
    if not self:_GetData(key) then
        return
    end
    self:_SetData(key,nil)
    self.m_tKeepList[key] =nil
end

function CThisTemp:Delay(key,nSecs)
    self:_Validate()
    local nEndTime = self.m_tKeepList[key]
    if not nEndTime then
        return
    end
    nEndTime = nEndTime + nSecs
     self.m_tKeepList[key] = nEndTime
end

function CThisTemp:Query(key,rDefault)
    self:_Validate(key)
    return self:_GetData(key,rDefault)
end

function CThisTemp:QueryLeftTime(key)
    self:_Validate(key)
    local nSecs = self.m_tKeepList[key]
    if not nSecs  then return 0 end
    return nSecs - self:_GetTimeNo()
end

--------------------------------------------------------------------------------------连续诺干天
function CSeveralDay:Ctor(nID)
    self.m_nID = nID
    self.m_tData = {}
    self.m_tKeepList = {}
end

function CSeveralDay:SaveData()
    local tData = {}
    tData["data"] = self.m_tData
    tData["daylist"] = self.m_tDayList
    return tData
end

function CSeveralDay:LoadData(tData)
    tData = dtDataata or {}
    self.m_tData = tData["data"] or self.m_tData
    self.m_tDayList = tData["daylist"] or self.m_tDayList
end

function CSeveralDay:_GetTimeNo()
    return _GetDayNo()
end

function CSeveralDay:_SetData(k, v)
    if not self.m_tData then
        self.m_tData = {}
    end
    self.m_tData[k] = v
end

function CSeveralDay:_GetData(k, rDefault)
    if not self.m_tData then
        self.m_tData = {}
    end
    return self.m_tData[k] or rDefault
end

function CSeveralDay:_Validate(key)
    local tData = self:_GetData(key)
    if not tData then
        return
    end
    local nKeepDay = self.m_tDayList[key] or 7
    local nNowDay = self:_GetTimeNo()
    local bUpdate = false
    for nDayNo,iValue in pairs(tData) do
        if nNowDay - nDayNo >= nKeepDay then
            tData[nDayNo] = nil
            bUpdate = true
        end
    end

    if table.Count(tData) == 0 then
        self:_SetData(key, nil)
        self.m_tDayList[key] = nil
    else
        if bUpdate then
          self:_SetData(key, tData)
        end
    end
end

function CSeveralDay:Add(key,nValue,nKeepDay)
    self:_Validate()
    nKeepDay = nKeepDay or 7
    local nDayNo = self:_GetTimeNo()
    local tData = self:_GetData(key)
    if not tData then
        tData = {}
        tData[nDayNo] = nValue
        self.m_tDayList[key] = nKeepDay
    else
        local nOldValue = tData[nDayNo] or 0
        nOldValue = nOldValue + nValue
        tData[nDayNo] = nOldValue
    end
    self:_SetData(key,tData)
end

function CSeveralDay:Set(key,nValue,nKeepDay)
    self:_Validate()
    nKeepDay = nKeepDay or 7
    local nDayNo = self:_GetTimeNo()
    local tData = self:_GetData(key)
    if not tData then
        tData = {}
        tData[nDayNo] =nValue
        self.m_tDayList[key] = nKeepDay
    else
        tData[nDayNo] = nValue
    end
    self:_SetData(key,tData)
end

function CSeveralDay:Delete(key)
    if not self:_GetData(key) then
        return
    end
    self:_SetData(key,nil)
    self.m_tDayList[key] = nil
end

function CSeveralDay:GetDataList(key)
    self:_Validate()
    return self:_GetData(key,{})
end

function CSeveralDay:QueryRecent(key,nDay)
    self:_Validate(key)
    local tDataList = self:_GetData(key,{})
    local nNowDay = self:_GetTimeNo()
    local nSum = 0
    for nDayNo,nValue in pairs(tDataList) do
        if nNowDay - nDayNo < nDay then
            nSum = nSum + nValue
        end
    end
    return nSum
end

function CSeveralDay:Delay(key,nDay)
    self:_Validate(key)
    local tData = self:_GetData(key)
    if not tData or not nDay then
        return
    end
    local nKeepDay = self.m_tDayList[key]
    if not nKeepDay then
        return
    end
    self.m_tDayList[key] = self.m_tDayList[key] + nDay
end
