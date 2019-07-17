--个人节日活动基类(只将状态保存在内存，重启重新计算状态)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CHolidayActivityBase:Ctor(nActID, nActType)
    self.m_nActID = nActID
    self.m_nActType = nActType
    self.m_nBeginTimestamp = 0
    self.m_nEndTimestamp = 0
    self.m_bIsActBegin = false
    self.m_bIsActEnd = false
    self.m_bCanJoin = false

    self:InitStatus()
end

function CHolidayActivityBase:InitStatus()
    local tConf = ctHolidayActivityConf[self.m_nActID]    
    local tDate = os.date("*t", os.time())    
    local sDate = tDate.year.."-"..tDate.month.."-"

    if tDate.day < tConf.nOpenDay then
        --还没到活动期间开始时间为下一次开启时间
        if tConf.bManyOpen then
            local sOpenTime = sDate..tConf.nOpenDay.." "..tConf.tManyOpenList[1][1]..":".."00"
            self.m_nBeginTimestamp = os.Str2Time(sOpenTime)
            self.m_nEndTimestamp = nStartTimestamp + ctHolidayActivityConf[self.m_nActID].nContinueTime*60
        else
            local sOpenTime = sDate..tConf.nOpenDay.." "..tConf.sOpenTime..":".."00"
            local sCloseTime = sDate..tConf.nOpenDay.." "..tConf.sCloseTime..":".."00"
            self.m_nBeginTimestamp = os.Str2Time(sOpenTime)
            self.m_nEndTimestamp = os.Str2Time(sCloseTime)
        end

    elseif tonumber(tConf.nOpenDay) <= tDate.day and tDate.day < tConf.nCloseDay then
        --如果是在活动期间开启时间是每天的开启时间
        if tConf.bManyOpen then
            for nIndex, tTime in ipairs(tConf.tManyOpenList) do
                local sTimeTmp = sDate..tDate.day.." "..tTime[1]..":".."00"
                local nStartTimestamp = os.Str2Time(sTimeTmp)
                local nEndTimestamp = nStartTimestamp + ctHolidayActivityConf[self.m_nActID].nContinueTime*60
                if os.time() <= nStartTimestamp or (nStartTimestamp <= os.time() and os.time() < nEndTimestamp) then
                    self.m_nBeginTimestamp = nStartTimestamp
                    self.m_nEndTimestamp = nEndTimestamp
                    break
                end
            end
        else
            local sOpenTime = sDate..tConf.nOpenDay.." "..tConf.sOpenTime..":".."00"
            local sCloseTime = sDate..tDate.day.." "..tConf.sCloseTime..":".."00"
            self.m_nBeginTimestamp = os.Str2Time(sOpenTime)
            self.m_nEndTimestamp = os.Str2Time(sCloseTime)
        end
    end
    self:CheckStatus()
end

function CHolidayActivityBase:GetActIsBegin() return self.m_bIsActBegin end
function CHolidayActivityBase:GetActIsEnd() return self.m_bIsActEnd end
function CHolidayActivityBase:GetBeginTimestamp() return self.m_nBeginTimestamp end
function CHolidayActivityBase:GetEndTimestamp() return self.m_nEndTimestamp end
function CHolidayActivityBase:GetCanJoin() return self.m_bCanJoin end
function CHolidayActivityBase:GetActType() return self.m_nActType end
function CHolidayActivityBase:GetActID() return self.m_nActID end
function CHolidayActivityBase:GetConf() return ctHolidayActivityConf[self:GetActID()] end

function CHolidayActivityBase:OnMinTimer()
    self:CheckStatus()
end

function CHolidayActivityBase:CheckStatus()
    --检查发现状态改变调用改变函数
    local tDate = os.date("*t", os.time())
    if 0 < self.m_nBeginTimestamp and self.m_nBeginTimestamp <= os.time() and os.time() < self.m_nEndTimestamp and self.m_nEndTimestamp > 0 then
        if self.m_bIsActBegin then return end
        self:ChangeStatus(true, false)

    elseif 0 < self.m_nBeginTimestamp and self.m_nBeginTimestamp <= os.time() and self.m_nEndTimestamp <= os.time() and self.m_nEndTimestamp > 0 then
        if self.m_bIsActEnd then return end
        self:ChangeStatus(false, true)

    elseif tDate.day > ctHolidayActivityConf[self.m_nActID].nCloseDay then
        self:ChangeStatus(false, true)
    end
end

function CHolidayActivityBase:ChangeStatus(bIsBegin, bIsEnd)
    self.m_bIsActBegin = bIsBegin
    self.m_bIsActEnd = bIsEnd
end

function CHolidayActivityBase:OnChangeJoinStatus()
end
