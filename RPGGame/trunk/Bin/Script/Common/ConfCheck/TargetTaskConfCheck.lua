--目标任务配置检查
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local function _TargetTaskConfCheck()
    for nTaskID, tConf in pairs(ctTargetTaskConf) do
        assert(0 < tConf.nTaskType and tConf.nTaskType <= 47, "目标任务配置有错，任务ID："..nTaskID)
        if tConf.nNext > 0 then
            assert(ctTargetTaskConf[tConf.nNext], "目标任务配置有错，任务ID："..nTaskID)
        end
        if tConf.nAwardPoolID > 0 then
            assert(ctAwardPoolConf.IsPoolExist(tConf.nAwardPoolID), "目标任务配置有错，任务ID："..nTaskID)
        end
    end
end

_TargetTaskConfCheck()