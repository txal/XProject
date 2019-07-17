--师门任务配置预处理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

-- 预处理数据结构
-- _ctShiMenTaskConf = 
-- { 
--     按师门分类
--     [nShiMenType] = 
--     {
--         按等级范围分类
--         [sLvLimit] = 
--         {
--             按类型分类
--             [nTaskType] = {}
--         }
--     }
-- }
_ctShiMenTaskConf = {}
local function _PreProShiMenConf()
    for nID, tConf in pairs(ctShiMenTaskConf) do
        --按师门类型分类
        local nMinLimit = tConf.nMinLimit
        local nMaxLimit = tConf.nMaxLimit
        local sLvLimit = nMinLimit .. ":" .. nMaxLimit

        if not _ctShiMenTaskConf[tConf.nShiMenType] then
            _ctShiMenTaskConf[tConf.nShiMenType] = {}
        end

        if not _ctShiMenTaskConf[tConf.nShiMenType][sLvLimit] then
            _ctShiMenTaskConf[tConf.nShiMenType][sLvLimit] = {}
        end

        if not _ctShiMenTaskConf[tConf.nShiMenType][sLvLimit][tConf.nTaskType] then
            _ctShiMenTaskConf[tConf.nShiMenType][sLvLimit][tConf.nTaskType] = {}
        end

        assert(1 <= tConf.nShiMenType and tConf.nShiMenType <= 5, "师门任务配置错误，任务ID: "..nID)
        assert(0 <= tConf.nTaskType and tConf.nTaskType <= 4, "师门任务配置错误，任务ID: "..nID)
        assert(ctNpcConf[tConf.nNpcID], "师门任务配置错误，任务ID: "..nID)
        if tConf.nTaskType == 2 or tConf.nTaskType == 4 then
            assert(tConf.nRandPosType == 2, "师门任务配置错误，任务ID: "..nID)
        end
        if tConf.nTaskType == 2 then
            assert(ctBattleGroupConf[tConf.nBattleGroup], "师门任务配置错误，任务ID: "..nID)
        end
        table.insert(_ctShiMenTaskConf[tConf.nShiMenType][sLvLimit][tConf.nTaskType], tConf)
    end
end

_ctTaskItemConf = {}
local function _PreProTaskItemConf()
    for nItemID, tConf in pairs(ctShiMenItemWeight) do
        local nMinLimit = tConf.nMinLimit
        local nMaxLimit = tConf.nMaxLimit
        local sLvLimit = nMinLimit .. ":" .. nMaxLimit

        if not _ctTaskItemConf[sLvLimit] then
            _ctTaskItemConf[sLvLimit] = {}
        end
        table.insert(_ctTaskItemConf[sLvLimit], tConf)
    end
end

--按结构保存配置，方便搜索
_PreProShiMenConf()
_PreProTaskItemConf()