--Get year day ID
function os.YDay(timestamp)
    assert(timestamp) 
	local tDate = os.date("*t", timestamp)	
	return tDate.yday
end

--Get week day ID [1,7]
function os.WDay(timestamp)
    assert(timestamp)
	local tDate = os.date("*t", timestamp)	
    local nWeekDay = tDate.wday - 1
    nWeekDay = nWeekDay == 0 and 7 or nWeekDay 
	return nWeekDay
end

--Make time
function os.MakeTime(year, month, day, hour, min, sec)
	local nTimestamp = os.time{year=year, month=month, day=day, hour=hour, min=min, sec=sec}
	return nTimestamp
end

--下nDay天nHour点
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
function os.WeedDayTime(nTimeStamp, nWeekDay, nSecond)
    assert(nTimeStamp > 0 and nSecond >= 0)
    local tDate = os.date("*t", nTimestamp) 
    local nHourSecond = tDate.hour * 3600 + tDate.min * 60 + tDate.sec

    local nTarTimeStamp
    local nStdWeekDay = os.WDay(nTimeStamp)
    if nWeekDay > nStdWeekDay or (nWeekDay == nStdWeekDay and nHourSecond <= nSecond) then
        local nTimeIntval = (nWeekDay - nStdWeekDay) * 3600
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
    nHour = nHour or 0
    nMin =  nMin or 0
    nSec = nSec or 0
    local nNewTime = nTimeStamp + 24*3600
    local tDate = os.date("*t", nNewTime)
    tDate.hour = nHour
    tDate.min = nMin
    tDate.sec = nSec
    return os.time(tDate) - nTimeStamp
end