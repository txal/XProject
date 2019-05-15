--公共NPC
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPublicNpc:Ctor(nObjID, nConfID)
    local tConf = assert(ctMonsterConf[nConfID])
	CMonsterBase.Ctor(self, gtMonType.ePublicNpc, nObjID, nConfID)
    self.m_oNativeObj = goCppMonsterMgr:CreateMonster(nObjID, nConfID, tConf.sName)

end

function CPublicNpc:OnRelease()
    CMonsterBase.OnRelease(self)
    self.m_oNativeObj = nil --离开场景后30分钟自动回收
end

function CPublicNpc:GetConf() return ctMonsterConf[self:GetConfID()] end
function CPublicNpc:GetName() return self:GetConf().sName end
function CPublicNpc:GetLevel() return 0 end

function CPublicNpc:GetNativeObj() return self.m_oNativeObj end
function CPublicNpc:GetDupObj() return goDupMgr:GetDup(self:GetDupMixID()) end
function CPublicNpc:GetDupMixID() return self.m_oNativeObj:GetDupMixID() end
function CPublicNpc:GetAOIID() return self.m_oNativeObj:GetAOIID() end
function CPublicNpc:GetSpeed() return self.m_oNativeObj:GetRunSpeed() end --当前X,Y速度
function CPublicNpc:StopRun() self.m_oNativeObj:StopRun() end --停止移动
function CPublicNpc:GetFace() return self.m_oNativeObj:GetFace() end --当前面向
function CPublicNpc:GetPos() return self.m_oNativeObj:GetPos() end --当前X,Y坐标
function CPublicNpc:SetPos(nPosX, nPosY) self.m_oNativeObj:SetPos(nPosX, nPosY) end --设置坐标

function CPublicNpc:GetBattleGroupConf()
	if self:GetConf().nBattleGroup <= 0 then
        -- assert(false, "该NPC没有战斗组")
        return
	end
	return CMonsterBase.GetBattleGroupConf(self)
end

--视野数据
function CPublicNpc:GetViewData()
    local tInfo = {}
    tInfo.nObjID = self:GetID()
    tInfo.nAOIID = self:GetAOIID()
    tInfo.nObjType = self:GetObjType()
    tInfo.nConfID = self:GetConfID()
    tInfo.sName = self:GetName()
    tInfo.nLevel = self:GetLevel()
    tInfo.nPosX, tInfo.nPosY = self:GetPos()
    tInfo.nSpeedX, tInfo.nSpeedY = self:GetSpeed()
    tInfo.nTarPosX, tInfo.nTarPosY = 0, 0
    tInfo.nDir = self:GetFace()
    tInfo.sModel = self:GetConf().sModel
    tInfo.nObjSubType = self:GetMonType()
    tInfo.tActData = {}
    tInfo.tActData.nActID = self:GetActID()
    if tInfo.tActData.nActID > 0 then 
        tInfo.tActData.nTime = self:GetActTime()
    end
    tInfo.bBattle = self:CheckCanBattle()
    print("CPublicNpc:GetViewData***", tInfo)
    return tInfo
end

