--任务战斗NPC,战斗时创建,不会进入场景
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

CMonsterTaskNpc.tOnBattleEndType = 
{
    eTaskSystem = 1,
    eShiMenTask = 2,
}

function CMonsterTaskNpc:Ctor(nObjID, nTaskType, nConfID)
    CMonsterBase.Ctor(self, gtMonType.eTaskNpc, nObjID, nConfID) 

    self.m_nTaskType = nTaskType
    self.m_tOnBattleEndTable = {}       --不同模块触发函数集合
    self:RegisterOnBattleEnd()
end

function CMonsterTaskNpc:OnRelease()
    CMonsterBase.OnRelease(self)
end

function CMonsterTaskNpc:GetConf()
    if self.m_nTaskType == CMonsterTaskNpc.tOnBattleEndType.eTaskSystem then
        return ctTaskSystemConf[self:GetConfID()]
    elseif self.m_nTaskType == CMonsterTaskNpc.tOnBattleEndType.eShiMenTask then
        return ctShiMenTaskConf[self:GetConfID()]
    end
end

function CMonsterTaskNpc:GetName() return self:GetConf().sName end
function CMonsterTaskNpc:GetLevel() return 0 end
function CMonsterTaskNpc:GetNativeObj() return nil end

--进入战斗
function CMonsterTaskNpc:OnBattleBegin(nBattleID)
    CMonsterBase.OnBattleBegin(self, nBattleID)  
end

--战斗结束
function CMonsterTaskNpc:OnBattleEnd(tBTRes, tExtData)
    CMonsterBase.OnBattleEnd(self, tBTRes)
    local oRole = goPlayerMgr:GetRoleByID(tBTRes.nLeaderID1)
	if not oRole then return end
    
    local fnOnBattleEnd = self.m_tOnBattleEndTable[tExtData.tBattleFromModule]
    fnOnBattleEnd(self, oRole, tBTRes)
end

function CMonsterTaskNpc:RegisterOnBattleEnd()
    local tOnBattleEndTab = self:GetOnEndTable()

    for k, v in pairs(tOnBattleEndTab) do
        self.m_tOnBattleEndTable[v[1]] = v[2]
    end
end

function CMonsterTaskNpc:GetOnEndTable()
    return {
        {CMonsterTaskNpc.tOnBattleEndType.eTaskSystem, self.TaskSysBattleEnd},
        {CMonsterTaskNpc.tOnBattleEndType.eShiMenTask, self.ShiMenBattleEnd},
    }
end

function CMonsterTaskNpc:TaskSysBattleEnd(oRole, tBTRes)
    oRole.m_oTaskSystem:OnBattleEnd(not tBTRes.bWin)
end

function CMonsterTaskNpc:ShiMenBattleEnd(oRole, tBTRes)
    oRole.m_oShiMenTask:OnBattleEnd(not tBTRes.bWin)
end