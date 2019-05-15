--仅仅用于战斗，战斗时创建，不会进入场景
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CMonsterInvisible:Ctor(nObjID, nConfID)
    local tConf = assert(ctMonsterConf[nConfID])
    CMonsterBase.Ctor(self, gtMonType.eInvisible, nObjID, nConfID) 
end

function CMonsterInvisible:OnRelease()
    CMonsterBase.OnRelease(self)
end

function CMonsterInvisible:GetConf() return ctMonsterConf[self:GetConfID()] end
function CMonsterInvisible:GetName() return self:GetConf().sName end
function CMonsterInvisible:GetLevel() return 0 end
function CMonsterInvisible:GetNativeObj() return nil end

function CMonsterInvisible:OnBattleBegin(nBattleID)
    CMonsterBase.OnBattleBegin(self, nBattleID)
end

function CMonsterInvisible:OnBattleEnd(tBTRes, tExtData)
    CMonsterBase.OnBattleEnd(self, tBTRes, tExtData)
end