--试炼任务配置预处理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local _ctShiLianTaskConf = {}
local function _ShiLianTaskConfCheck()
    for nID, tConf in pairs(ctShiLianTaskConf) do
        if not _ctShiLianTaskConf[tConf.nTaskType] then
            _ctShiLianTaskConf[tConf.nTaskType] = {}
        end
        assert(ctNpcConf[tConf.nNpcID], "试炼任务配置错误，任务ID："..nID)
        if tConf.nMonsterID > 0 then
            assert(ctMonsterConf[tConf.nMonsterID], "试炼任务配置错误，任务ID："..nID)
        end
        for nIndex, tCommitID in pairs(tConf.tCommitItem) do
            if tCommitID[1] > 0 then
                assert(ctItemStaticGroup[tCommitID[1]], "试炼任务配置错误，任务ID："..nID)
            end
        end
        table.insert(_ctShiLianTaskConf[tConf.nTaskType], tConf)
    end
end
_ShiLianTaskConfCheck()

function ctShiLianTaskConf.GetPool(nType, nRoleLevel)
    assert(nType and nRoleLevel, "试炼任务抽取任务参数有误")
    local tConfList = assert(_ctShiLianTaskConf[nType], "不存在此类型试炼任务："..nType)
    local tLevelConfList = {}
    for _, tConf in pairs(tConfList) do
        if nRoleLevel >= tConf.nMinLevel and nRoleLevel <= tConf.nMaxLevel then
            table.insert(tLevelConfList, tConf)
        end
    end
    return tLevelConfList
end