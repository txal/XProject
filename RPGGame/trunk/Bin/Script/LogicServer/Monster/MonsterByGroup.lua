--通过战斗组产生的怪物，仅仅用于战斗，战斗时创建，不会进入场景
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CMonsterByGroup:Ctor(nObjID, nConfID, tModuleConf)
    assert(tModuleConf and tModuleConf[nConfID], "根据战斗组产生的怪物传参错误", nConfID)
    CMonsterBase.Ctor(self, gtMonType.eCreateByGroup, nObjID, nConfID)
    self.tModuleConf = tModuleConf  --模块配置
end

function CMonsterByGroup:OnRelease()
    CMonsterBase.OnRelease(self)
end

function CMonsterByGroup:GetName() return ctBattleGroupConf[self:GetConf().nBattleGroup].nID end
function CMonsterByGroup:GetNativeObj() return nil end
function CMonsterByGroup:GetLevel() return 0 end

function CMonsterByGroup:GetConf()
    return self.tModuleConf[self:GetConfID()]
end

function CMonsterByGroup:OnBattleBegin(nBattleID)
    CMonsterBase.OnBattleBegin(self, nBattleID)
end

function CMonsterByGroup:OnBattleEnd(tBTRes, tExtData)
    CMonsterBase.OnBattleEnd(self, tBTRes, tExtData)
end