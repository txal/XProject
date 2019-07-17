--功能预告配置检查
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local function _WillOpenConfCheck()
    for nSeq, tConf in pairs(ctWillOpenConf) do
        if tConf.nNext ~= 0 then
            assert(ctWillOpenConf[tConf.nNext], "功能预告配置错误，Seq:",nSeq, "系统ID:", tConf.nSysID)
        end
        assert(ctSysOpenConf[tConf.nSysID], "功能预告配置错误，Seq:",nSeq, "系统ID:", tConf.nSysID)
        if tConf.bOpen then
            assert(ctSysOpenConf[tConf.nSysID].bOpen, "功能预告配置错误，Seq:",nSeq, "系统ID:", tConf.nSysID)
        end
        for _, tReward in pairs(tConf.tItemReward) do
            assert(ctPropConf[tReward[2]], "功能预告配置错误，Seq:", nSeq, "物品ID:", tReward[2])
        end
    end
end
_WillOpenConfCheck()
