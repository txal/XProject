--怪物对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CMonster:Ctor(nObjID, nConfID)
	local tConf = assert(ctMonsterConf[nConfID])
    self.m_nObjID = nObjID
    self.m_nConfID = nConfID
    self.m_oNativeObj = goCppMonsterMgr:CreateMonster(nObjID, nConfID, tConf.sName)
end

function CMonster:Release()
    self.m_oNativeObj = nil
end

function CMonster:GetNativeObj() return self.m_oNativeObj end
function CMonster:GetID() return self.m_nObjID end
function CMonster:GetConf() return ctMonsterConf[self.m_nConfID] end
function CMonster:GetLevel() return self:GetConf().nLevel end
function CMonster:GetMoveSpeed() return self:GetConf().nMoveSpeed end
function CMonster:GetSpeed() return self.m_oNativeObj:GetRunSpeed() end
function CMonster:GetDupMixID() return self.m_oNativeObj:GetDupMixID() end
function CMonster:GetAOIID() return self.m_oNativeObj:GetAOIID() end

--进入场景
function CMonster:OnEnterScene(nDupMixID)
    print("CMonster:OnEnterScene***", nDupMixID)
end

--进入场景后
function CMonster:AfterEnterScene(nDupMixID)
end

--离开场景完成
function CMonster:OnLeaveScene(nDupMixID)
	goLuaMonsterMgr:RemoveMonster(self.m_nObjID)
end

--进入场景
function CMonster:EnterScene(nDupMixID, nPosX, nPosY, nLine)
    local oDup = goDupMgr:GetDup(nDupMixID)
    if not oDup then
        return LuaTrace("副本不存在", nDupMixID)
    end
    oDup:Enter(self.m_oNativeObj, nPosX, nPosY, nLine)
end

--离开场景
function CMonster:LeaveScene()
    local nDupMixID = self.m_oNativeObj:GetDupMixID()
    local oDup = goDupMgr:GetDup(nDupMixID)
    oDup:Leave(self:GetAOIID())
end

--怪物
function CMonster:OnMonsterDead()
	self:LeaveScene()
end

function CMonster:GetViewData()
    local tViewData = {}
    return tViewData
end
