--节日活动江湖历练任务预处理
local _ctHolidayActExpTaskConf = {}

local function _HolidayActExpTaskConfCheck()
end
_HolidayActExpTaskConfCheck()

function ctExperienceTaskConf.GetTaskPool(nRoleLevel)
    assert(nRoleLevel, "江湖历练选取任务参数错误")
    local tLevelConfList = {}
    for _, tConf in pairs(ctExperienceTaskConf) do
        if tConf.nMinLimit <= nRoleLevel and nRoleLevel <= tConf.nMaxLimit then
            table.insert(tLevelConfList, tConf)
        end
    end
    return tLevelConfList
end