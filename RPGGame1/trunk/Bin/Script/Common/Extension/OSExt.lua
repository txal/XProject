--距离某个时间点的第几天
local nStandTime = 1483286399 --2017/1/1 23:59:59(不能改)
function os.DayNo(timestamp)
    assert(timestamp) 
    local nTime = timestamp - nStandTime
    local nDayNo = math.ceil(nTime/(3600*24))
    return nDayNo
end

--一年的第几天(可能超过1年的就用os.DayNo)
function os.YDay(timestamp)
    assert(timestamp) 
	local tDate = os.date("*t", timestamp)	
	return tDate.yday
end

--周几[1,7]
function os.WDay(timestamp)
    assert(timestamp)
	local tDate = os.date("*t", timestamp)	
    local nWeekDay = tDate.wday - 1
    nWeekDay = nWeekDay == 0 and 7 or nWeekDay 
	return nWeekDay
end

--从19701月1日(星期4)早上8点算的到现今周数
--以nSecond作为分界线,如4点刷新(则传入4*60*60)
function os.WeekNumber(nSecond)
    --标准时间是从19701月1日(星期4)早上8点算的
    --604800表示一周的秒数(7*24*60*60)
    --288000表示从星期1到星期4早上8点过的秒数(3*24*60*60+8*60*60)，仅限于东8区，要修改成全球通用，动态
    --259200三天秒数(3*24*60*60)
    local tOffsetTime = os.date("*t", 0)
    local nOffsetTime = 259200 + tOffsetTime.hour * 3600
    return math.floor((os.time()+nOffsetTime-nSecond)/604800)
end

function os.Hour(timestamp)
    timestamp = timestamp or os.time()
    local tDate = os.date("*t", timestamp)  
    return tDate.hour
end

--生成时间戳
function os.MakeTime(year, month, day, hour, min, sec)
	local nTimestamp = os.time{year=year, month=month, day=day, hour=hour, min=min, sec=sec}
	return nTimestamp
end

--某个时间戳的0点
function os.ZeroTime(nTime)
    local tDate = os.date("*t", nTime)
    tDate.hour, tDate.min, tDate.sec = 0, 0, 0
    return os.time(tDate)
end

--下nDays天nHour点
function os.MakeDayTime(nTime, nDays, nHour, nMin, nSec)
    local tDate = os.date("*t", nTime)  
    tDate.day = tDate.day + nDays
    tDate.hour = nHour or 0
    tDate.min = nMin or 0
    tDate.sec = nSec or 0
    return os.time(tDate)
end

--是否是同1天,以nSecond作为分界线,如4点刷新(则传入4*60*60)
function os.IsSameDay(nTime1, nTime2, nSecond)
    assert(nTime1 and nTime2)
    nSecond = nSecond or 0
    assert(nSecond >= 0 and nSecond < 86400)
    --这里有几个常数:标准时间不是从0时开始算的,而是从早上8点开始
    --86400表示一天的秒数(24*60*60)
    --28800表示8个小时的秒数(8*60*60)，仅限于东8区，要修改成全球通用，动态
    --3600表示一个小时的秒数(60*60)
    local tOffsetTime = os.date("*t", 0)
    local nOffsetTime = tOffsetTime.hour * 3600
    if math.floor((nTime1+nOffsetTime-nSecond)/86400) == math.floor((nTime2+nOffsetTime-nSecond)/86400) then
        return true
    end
    return false
end

--是否是同一周，以nSecond作为分界线，如星期1早上4点刷新(则传入(1-1)*24*60*60+4*60*60)，每周第1天取星期1
function os.IsSameWeek(nTime1, nTime2, nSecond)
    assert(nTime1 and nTime2)
    nSecond = nSecond or 0
    assert(nSecond >= 0 and nSecond < 604800)
    --标准时间是从19701月1日(星期4)早上8点算的
    --604800表示一周的秒数(7*24*60*60)
    --288000表示从星期1到星期4早上8点过的秒数(3*24*60*60+8*60*60)，仅限于东8区，要修改成全球通用，动态
    --259200三天秒数(3*24*60*60)
    local tOffsetTime = os.date("*t", 0)
    local nOffsetTime = 259200 + tOffsetTime.hour * 3600
    if math.floor((nTime1+nOffsetTime-nSecond)/604800) == math.floor((nTime2+nOffsetTime-nSecond)/604800) then
        return true
    end
end

--两个时间相差多少天,以nSecond作为分界线
function os.PassDay(nTime1, nTime2, nSecond)
    assert(nTime1 and nTime2)
    nSecond = nSecond or 0
    assert(nSecond >= 0 and nSecond < 86400)
    local tOffsetTime = os.date("*t", 0)
    local nOffsetTime = tOffsetTime.hour * 3600
    local nDay1 = math.floor((nTime1+nOffsetTime-nSecond) / 86400)
    local nDay2 = math.floor((nTime2+nOffsetTime-nSecond) / 86400)
    return math.abs(nDay2 - nDay1)
end

--是否闰年
function os.IsLeapYear(nTime)
    local tDate = os.date("*t", nTime)  
    local nYear = tDate.year
    if (nYear % 4 == 0  and nYear % 100 ~= 0) or (nYear % 400 == 0) then
        return true
    end
end

--1年有多少天
function os.YearDays(nTime)
    if os.IsLeapYear(nTime) then
        return 366
    end
    return 365
end

--秒分割时/分/秒
function os.SplitTime(nSecond)
    local nHour = math.floor(nSecond / 3600)
    local nMin = math.floor((nSecond % 3600) / 60)
    local nSec = nSecond % 60
    return nHour, nMin, nSec
end

--取到从nTimeStamp开始到下个nWeekDay[1,7]的时间戳, nSecond为下个nWeekDay的时间点(秒数)
function os.WeekDayTime(nTimeStamp, nWeekDay, nSecond)
    assert(nTimeStamp > 0 and nSecond >= 0)
    local tDate = os.date("*t", nTimestamp) 
    local nHourSecond = tDate.hour * 3600 + tDate.min * 60 + tDate.sec

    local nTarTimeStamp
    local nStdWeekDay = os.WDay(nTimeStamp)
    if nWeekDay > nStdWeekDay or (nWeekDay == nStdWeekDay and nHourSecond <= nSecond) then
        local nTimeIntval = (nWeekDay - nStdWeekDay) * 24 * 3600
        nTarTimeStamp = nTimeStamp + nTimeIntval
    else
        local nTimeIntval = (nWeekDay - nStdWeekDay + 7) * 24 * 3600
        nTarTimeStamp = nTimeStamp + nTimeIntval
    end
    assert(nTarTimeStamp > 0)
    local tDate = os.date("*t", nTarTimeStamp)
    return os.MakeTime(tDate.year, tDate.month, tDate.day, 0, 0, 0) + nSecond
end

--nTimeStamp距离下1天某时刻的时间(秒)
function os.NextDayTime(nTimeStamp, nHour, nMin, nSec)
    assert(nTimeStamp, "时间戳为空")
    nHour, nMin, nSec = nHour or 0,  nMin or 0, nSec or 0
    local nNewTime = nTimeStamp + 24*3600
    local tDate = os.date("*t", nNewTime)
    tDate.hour, tDate.min, tDate.sec = nHour, nMin, nSec
    return os.time(tDate) - nTimeStamp
end

--nTimeStamp距离下1整点时间(秒)
function os.NextHourTime(nTimeStamp)
    assert(nTimeStamp, "时间戳为空")
    local tDate = os.date("*t", nTimeStamp)
    tDate.hour, tDate.min, tDate.sec = tDate.hour+1, 0, 0
    return os.time(tDate) - nTimeStamp
end

--nTimeStamp距离下1整分钟时间(秒)
function os.NextMinTime(nTimeStamp)
    assert(nTimeStamp, "时间戳为空")
    local tDate = os.date("*t", nTimeStamp)
    tDate.min, tDate.sec = tDate.min+1, 0
    local nNextTime = os.time(tDate)
    return nNextTime - nTimeStamp
end

--是否同一月，分界线为每月1号的nSecond秒, 如4点刷新(则传入4*60*60)
function os.IsSameMonth(nTime1, nTime2, nSecond)
    assert(nSecond >= 0 and nSecond <= 86400)
    nTime1 = nTime1 - nSecond
    nTime2 = nTime2 - nSecond
    local tDate1 = os.date("*t", nTime1) 
    local tDate2 = os.date("*t", nTime2)
    if tDate1.year == tDate2.year and tDate1.month == tDate2.month then
        return true
    end
    return false
end

--某一月有多少天，nTime为那一个月的任意一个时间戳
function os.MonthDays(nTime)
    local tDate = os.date("*t", nTime)
    tDate.month = tDate.month + 1
    tDate.day = 1
    local nTmpTime = os.time(tDate)
    nTmpTime = nTmpTime - 24*3600
    tDate = os.date("*t", nTmpTime)
    return tDate.day
end

--字符串日期转时间戳，例: 2017-6-8 16:00:00
function os.Str2Time(sDate)
    local tSplit = string.Split(sDate, " ")
    local nYear, nMonth, nDay, nHour, nMin, nSec = 0, 0, 0, 0, 0, 0
    if tSplit[1] then
        local tSplitDate = string.Split(tSplit[1], "-")
        assert(#tSplitDate == 3, "日期格式错误:"..sDate)
        nYear, nMonth, nDay = tonumber(tSplitDate[1]), tonumber(tSplitDate[2]), tonumber(tSplitDate[3])
    end
    if tSplit[2] then
        local tSplitTime = string.Split(tSplit[2], ":")
        assert(#tSplitTime >= 2, "时间格式错误:"..sDate)
        nHour, nMin, nSec = tonumber(tSplitTime[1]), tonumber(tSplitTime[2]), (tonumber(tSplitTime[3]) or 0)
    end
    assert(nYear > 0 and nMonth > 0 and nDay > 0, "日期格式错误:"..sDate)
    return os.MakeTime(nYear, nMonth, nDay, nHour, nMin, nSec)
end

--距离下一nHour整点时间
function os.NextHourTime1(nHour)
    local nNowSec = os.time()
    local tDate = os.date("*t", nNowSec)  
    if tDate.hour < nHour then
        tDate.hour = nHour
        tDate.min = 0
        tDate.sec = 0
        return (os.time(tDate) - nNowSec)
    end
    local nNextDayTime = nNowSec + 24*3600
    local tDate = os.date("*t", nNextDayTime)
    tDate.hour = nHour
    tDate.min = 0
    tDate.sec = 0
    return (os.time(tDate) - nNowSec)
end