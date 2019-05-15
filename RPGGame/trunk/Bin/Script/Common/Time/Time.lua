--时间管理对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
--CToday记录当天玩法信息次数
--CThisWeek记录每周玩法信息次数
--CThisTemp记录一段时间内玩法信息次数
--CSeveralDay记录诺干天内玩法信息次数

--2017/1/2(不能改)
nStandTime = 1483286400

function GetDayNo(nSecs)
    local nSecs = nSecs or os.time()
    local nTime = nSecs - nStandTime
    local nDayNo = math.floor(nTime // (3600*24))
    return nDayNo
end

function GetWeekNo(nSec)
    local nSec = nSec or os.time()
    local nTime = nSec - nStandTime
    local nWeekNo = math.floor(nTime//(7*3600*24))
    return nWeekNo
end

--当天次数
function CToday:Ctor(nID)
    self.m_nID = nID
    self.m_bDirty = false
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

function CToday:SetData(k, v)
    if not self.m_tData then
        self.m_tData = {}
    end
    self.m_tData[k] = v
    self:MarkDirty(true)
end

function CToday:GetData(k, rDefault)
    self:Validate(k)
    if not self.m_tData then
        self.m_tData = {}
    end
    return self.m_tData[k] or rDefault
end

function CToday:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CToday:IsDirty() return self.m_bDirty end

function CToday:Add(key,nValue)
    self:Validate(key)
    local nOldValue = self:GetData(key,0)
    nOldValue = nOldValue + nValue
    self:SetData(key,nOldValue)
    self.m_tKeepList[key] = self:GetTimeNo()
end

function CToday:Set(key,nValue)
    self:Validate(key)
    self:SetData(key,nValue)
    self.m_tKeepList[key] = self:GetTimeNo()
end

function CToday:Query(key,rDefault)
    self:Validate(key)
    return self:GetData(key,rDefault)
end

function CToday:Delete(key)
    if not self:GetData(key) then
        return
    end
    self:MarkDirty(true)
    self:SetData(key,nil)
    self.m_tKeepList[key] =nil
end

function CToday:Validate(key)
    local nDayNo = self.m_tKeepList[key]
    if not nDayNo then
        return
    end
    if nDayNo >= self:GetTimeNo() then
        return
    end
    self:SetData(key,nil)
    self.m_tKeepList[key] = nil
end

function CToday:ClearData()
    self:MarkDirty(true)
    self.m_tKeepList = {}
    self.m_tData = {}
end

function CToday:GetTimeNo()
    return GetDayNo()
end

--一周内
function CThisWeek:Ctor(nID)
    CToday.Ctor(self,oModule, nID)
    self.m_nID = nID
    self.m_tData = {}
    self.m_tKeepList = {}
end

function CThisWeek:GetTimeNo()
    return GetWeekNo()
end


--连续一段时间内次数
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

function CThisTemp:SetData(k, v)
    if not self.m_tData then
        self.m_tData = {}
    end
    self.m_tData[k] = v
    self:MarkDirty(true)
end

function CThisTemp:GetData(k, rDefault)
    if not self.m_tData then
        self.m_tData = {}
    end
    return self.m_tData[k] or rDefault
end

function CThisTemp:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CThisTemp:IsDirty() return self.m_bDirty end

function CThisTemp:Add(key,value,nSecs)
    self:Validate(key)
    nSecs = nSecs or 30
    local nValue = self:GetData(key)
    if not nValue then
        self:SetData(key,value)
        self.m_tKeepList[key] = nSecs + self:GetTimeNo()
    else
        nValue = nValue + value
        self:SetData(key,nValue)
    end
end

function CThisTemp:Set(key,value,nSecs)
    self:Validate(key)
    nSecs = nSecs or 30
    local nValue = self:GetData(key)
    if not nValue then
        self:SetData(key,value)
        self.m_tKeepList[key] = nSecs + self:GetTimeNo()
    else
        self:SetData(key,value)
    end
end

function CThisTemp:Delete(key)
    if not self:GetData(key) then
        return
    end
    self:MarkDirty(true)
    self:SetData(key,nil)
    self.m_tKeepList[key] =nil
end

function CThisTemp:Delay(key,nSecs)
    self:Validate()
    local nEndTime = self.m_tKeepList[key]
    if not nEndTime then
        return
    end
    self:MarkDirty(true)
    nEndTime = nEndTime + nSecs
     self.m_tKeepList[key] = nEndTime
end

function CThisTemp:Query(key,rDefault)
    self:Validate(key)
    return self:GetData(key,rDefault)
end

function CThisTemp:Validate(key)
    local nSecs = self.m_tKeepList[key]
    if not nSecs then
        return
    end
    if nSecs >= self:GetTimeNo() then
        return
    end
    self:SetData(key,nil)
    self.m_tKeepList[key] = nil
end

function CThisTemp:QueryLeftTime(key)
    self:Validate(key)
    local nSecs = self.m_tKeepList[key]
    if not nSecs  then return 0 end
    return nSecs - self:GetTimeNo()
end

function CThisTemp:GetTimeNo()
    return os.time()
end

--连续诺干天
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

function CSeveralDay:SetData(k, v)
    if not self.m_tData then
        self.m_tData = {}
    end
    self.m_tData[k] = v
    self:MarkDirty(true)
end

function CSeveralDay:GetData(k, rDefault)
    if not self.m_tData then
        self.m_tData = {}
    end
    return self.m_tData[k] or rDefault
end

function CSeveralDay:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CSeveralDay:IsDirty() return self.m_bDirty end

function CSeveralDay:Add(key,nValue,nKeepDay)
    self:MarkDirty(true)
    self:Validate()
    nKeepDay = nKeepDay or 7
    local nDayNo = self:GetTimeNo()
    local tData = self:GetData(key)
    if not tData then
        tData = {}
        tData[nDayNo] = nValue
        self.m_tDayList[key] = nKeepDay
    else
        local nOldValue = tData[nDayNo] or 0
        nOldValue = nOldValue + nValue
        tData[nDayNo] = nOldValue
    end
    self:SetData(key,tData)
end

function CSeveralDay:Set(key,nValue,nKeepDay)
    self:Validate()
    self:MarkDirty(true)
    nKeepDay = nKeepDay or 7
    local nDayNo = self:GetTimeNo()
    local tData = self:GetData(key)
    if not tData then
        tData = {}
        tData[nDayNo] =nValue
        self.m_tDayList[key] = nKeepDay
    else
        tData[nDayNo] = nValue
    end
    self:SetData(key,tData)
end

function CSeveralDay:Delete(key)
    if not self:GetData(key) then
        return
    end
    self:MarkDirty(true)
    self:SetData(key,nil)
    self.m_tDayList[key] = nil
end

function CSeveralDay:GetDataList(key)
    self:Validate()
    return self:GetData(key,{})
end

function CSeveralDay:QueryRecent(key,nDay)
    self:Validate(key)
    local tDataList = self:GetData(key,{})
    local nNowDay = self:GetTimeNo()
    local nSum = 0
    for nDayNo,nValue in pairs(tDataList) do
        if nNowDay - nDayNo < nDay then
            nSum = nSum + nValue
        end
    end
    return nSum
end

function CSeveralDay:Delay(key,nDay)
    self:Validate(key)
    local tData = self:GetData(key)
    if not tData or not nDay then
        return
    end
    local nKeepDay = self.m_tDayList[key]
    if not nKeepDay then
        return
    end
    self:MarkDirty(true)
    self.m_tDayList[key] = self.m_tDayList[key] + nDay
end

function CSeveralDay:Validate(key)
    local tData = self:GetData(key)
    if not tData then
        return
    end
    local nKeepDay = self.m_tDayList[key] or 7
    local nNowDay = self:GetTimeNo()
    local bUpdate = false
    for nDayNo,iValue in pairs(tData) do
        if nNowDay - nDayNo >= nKeepDay then
            tData[nDayNo] = nil
            bUpdate = true
        end
    end

    if table.Count(tData) == 0 then
        self:SetData(key,nil)
        self.m_tDayList[key] = nil
    else
        if bUpdate then
          self:SetData(key,tData)
        end
    end
end

function CSeveralDay:GetTimeNo()
    return GetDayNo()
end