--主线任务配置预处理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

_ctTaskSystemConf = {}
local function _PreProcessConf()
    for nID, tConf in pairs(ctTaskSystemConf) do
        if not _ctTaskSystemConf[tConf.nTaskType] then
            _ctTaskSystemConf[tConf.nTaskType] = {}
        end
        --检查配置字段的正确性
        assert(1 <= tConf.nTaskType and tConf.nTaskType <= 2, "主支线任务配置错误，任务ID："..nID)
        assert(1 <= tConf.nTargetType and tConf.nTargetType <= 4, "主支线任务配置错误，任务ID："..nID)
        assert(ctNpcConf[tConf.nParam1], "主支线任务配置错误, npc不存在, 任务ID："..nID.." NpcID:"..tConf.nParam1)
        local nNpcPosDupID = ctNpcConf[tConf.nParam1].nDupID
        assert(ctDupConf[nNpcPosDupID].nType == 1, "主支线任务NPC错误,任务ID："..nID.."NPCid:"..tConf.nParam1.."NPC所在场景:"..nNpcPosDupID)
        if tConf.nTaskType == 1 or tConf.nTaskType == 2 or tConf.nTaskType == 3 then
            assert(ctNpcConf[tConf.nParam1].nType == 5, "主支线任务配置错误, Npc类型跟任务类型不一致, 任务ID:"..nID.." NPCid:"..tConf.nParam1)
        -- elseif tConf.nTaskType == 2 then
        --     assert(ctNpcConf[tConf.nParam1].nType == 5, "主支线任务配置错误,Npc类型跟任务类型不一致,任务ID:"..nID.."NPCid:"..tConf.nParam1)            
        -- elseif tConf.nTaskType == 3 then
        --     assert(ctNpcConf[tConf.nParam1].nType == 5, "主支线任务配置错误,Npc类型跟任务类型不一致,任务ID:"..nID.."NPCid:"..tConf.nParam1) 
        elseif tConf.nTaskType == 4 then
            assert(ctNpcConf[tConf.nParam1].nType == 6, "主支线任务配置错误, Npc类型跟任务类型不一致, 任务ID:"..nID.." NPCid:"..tConf.nParam1)
        end
        if tConf.nTargetType == 1 then
            assert(ctBattleGroupConf[tConf.nBattleGroup], "主支线任务配置战斗组错误, 任务ID："..nID)
        end
        if tConf.nNextTask > 0 then
            assert(ctTaskSystemConf[tConf.nNextTask], "主支线任务配置错误,下个任务不存在, 任务ID："..nID)
        end
        for nIndex, tReward in pairs(tConf.tTaskReward) do
            if tReward[2] == gtItemType.eProp then
                assert(ctPropConf[tReward[3]], "主支线任务配置错误，任务ID："..nID)
            end
        end
        table.insert(_ctTaskSystemConf[tConf.nTaskType], tConf)
    end
    for nTaskType, tTaskList in pairs(_ctTaskSystemConf) do
        table.sort(tTaskList, function(t1, t2) return t1.nTaskId<t2.nTaskId end)
    end
end
_PreProcessConf()