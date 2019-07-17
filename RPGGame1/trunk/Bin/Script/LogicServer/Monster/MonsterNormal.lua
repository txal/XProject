--普通怪物对象(会进入场景)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CMonsterNormal:Ctor(nObjID, nConfID)
    local tConf = assert(ctMonsterConf[nConfID])
    CMonsterBase.Ctor(self, gtMonType.eNormal, nObjID, nConfID) 
    self.m_oNativeObj = goCppMonsterMgr:CreateMonster(nObjID, nConfID, tConf.sName)
end

function CMonsterNormal:Release()
    CMonsterBase.Release(self)
    self.m_oNativeObj = nil --离开场景后30分钟自动回收
end

function CMonsterNormal:GetConf() return ctMonsterConf[self:GetConfID()] end
function CMonsterNormal:GetName() return self:GetConf().sName end
function CMonsterNormal:GetLevel() return 0 end

function CMonsterNormal:IsValid() return (self:GetNativeObj() and self:GetAOIID()>0) end --怪物是否有效(没有离开场景)
function CMonsterNormal:GetNativeObj() return self.m_oNativeObj end
function CMonsterNormal:GetDupObj() return goDupMgr:GetDup(self:GetDupMixID()) end
function CMonsterNormal:GetDupMixID() return self.m_oNativeObj:GetDupMixID() end
function CMonsterNormal:GetAOIID() return self.m_oNativeObj:GetAOIID() end
function CMonsterNormal:GetSpeed() return self.m_oNativeObj:GetRunSpeed() end --当前X,Y速度
function CMonsterNormal:GetTarPos() return self.m_oNativeObj:GetTarPos() end --如果跑动，目标点坐标
function CMonsterNormal:StopRun() self.m_oNativeObj:StopRun() end --停止移动
function CMonsterNormal:SetPos(nPosX, nPosY) self.m_oNativeObj:SetPos(nPosX, nPosY) end --设置坐标(瞬移)
function CMonsterNormal:RunTo(nPosX, nPosY, nSpeed) self.m_oNativeObj:RunTo(nPosX, nPosY, nSpeed) end --以nSpeed(像素/秒)速度跑动到目标点
function CMonsterNormal:GetFace() return self.m_oNativeObj:GetFace() end --当前面向
function CMonsterNormal:GetPos() return self.m_oNativeObj:GetPos() end --当前X,Y坐标
function CMonsterNormal:SetPos(nPosX, nPosY) self.m_oNativeObj:SetPos(nPosX, nPosY) end --设置坐标


--视野数据
function CMonsterNormal:GetViewData()
    --为了加快速度，缓存一下
    if not self.m_tViewData then
        self.m_tViewData = {
            nAOIID = self:GetAOIID(),
            nObjID = self:GetID(),
            nObjType = self:GetObjType(),
            nConfID = self:GetConfID(),
            sName = self:GetName(),
            nLevel = self:GetLevel(),
            nDir = self:GetFace(),
            sModel = self:GetConf().sModel,
            bBattle = self:CheckCanBattle(),
            tActData = {},
        }
    end
    local tViewData = self.m_tViewData
    tViewData.nPosX, tViewData.nPosY = self:GetPos()
    tViewData.nSpeedX, tViewData.nSpeedY = self:GetSpeed()
    tViewData.nTarPosX, tViewData.nTarPosY = self:GetTarPos()
    tViewData.tActData.nActID = self:GetActID()
    if tViewData.tActData.nActID > 0 then 
        tViewData.tActData.nTime = self:GetActTime()
    end
    return tViewData
end

--进入场景
function CMonsterNormal:OnEnterScene(nDupMixID)
    CMonsterBase.OnEnterScene(self, nDupMixID)
end

--进入场景后
function CMonsterNormal:AfterEnterScene(nDupMixID)
    CMonsterBase.AfterEnterScene(self, nDupMixID)
end

--离开场景完成
function CMonsterNormal:OnLeaveScene(nDupMixID)
    CMonsterBase.OnLeaveScene(self, nDupMixID)
end

--进入场景
function CMonsterNormal:EnterScene(nDupMixID, nPosX, nPosY, nLine)
    CMonsterBase.EnterScene(self, nDupMixID, nPosX, nPosY, nLine)
end

--离开场景
function CMonsterNormal:LeaveScene()
    CMonsterBase.LeaveScene(self)
end

--进入战斗
function CMonsterNormal:OnBattleBegin(nBattleID)
    CMonsterBase.OnBattleBegin(self, nBattleID)
end

--战斗结束
function CMonsterNormal:OnBattleEnd(tBTRes, tExtData)
    CMonsterBase.OnBattleEnd(self, tBTRes, tExtData)

end
