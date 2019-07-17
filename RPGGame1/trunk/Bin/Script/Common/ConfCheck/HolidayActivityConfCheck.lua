--节日活动配置预处理
local _ctHolidayActivityConf = {}

local function _HolidayActivityConfCheck()
    for _, tConf in pairs(ctHolidayActivityConf) do
        if not _ctHolidayActivityConf[tConf.nMonth] then
            assert(1 <= tConf.nMonth and tConf.nMonth <= 12, "节日活动配置月份有错"..tConf.nActivityID)
            _ctHolidayActivityConf[tConf.nMonth] = {}
        end
        local tMonthList = {1, 3, 5, 7, 8, 10, 12}
        local tSplit = string.Split(tConf.sCloseTime, "/")
        if tSplit[1] == 31 then
            assert(table.InArray(tConf.nMonth, tMonthList), "节日活动关闭时间有错:"..tConf.nActivityID)
        end
        if tSplit[1] == 29 and tConf.nMonth == 2 then
            assert(os.IsLeapYear(os.time()), "节日活动关闭时间有错:"..tConf.nActivityID)
        end
       
        table.insert(_ctHolidayActivityConf[tConf.nMonth], tConf)
    end
end
_HolidayActivityConfCheck()

function ctHolidayActivityConf.GetMonthActConf(nMonth, nRoleLevel)
    assert(1 <= nMonth and nMonth <= 12, "节日活动获取配置参数有误")
    local tLevelConfList = {}
    for _, tConf in pairs(_ctHolidayActivityConf[nMonth]) do
        if nRoleLevel >= tConf.nLevelLimit then
            table.insert(tLevelConfList, tConf)
        end
    end
    return tLevelConfList
end