--副本中转场景
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CFBTransitScene:Ctor(nDupMixID, nType)
    self.m_nDupMixID = nDupMixID
    self.m_nType = nType
    self.m_tRoleMap = CUtil:WeakTable("v")
    self:Init()
end

function CFBTransitScene:Init()
    --设置回调函数
    local oDup = goDupMgr:GetDup(self.m_nDupMixID)
    -- oDup:RegObjEnterCallback(function(oLuaObj, bReconnect) self:OnObjEnter(oLuaObj, bReconnect) end)
    oDup:RegObjAfterEnterCallback(function(oLuaObj, nBattleID) self:AfterObjEnter(oLuaObj) end)
    oDup:RegObjLeaveCallback(function(oLuaObj, nBattleID) self:OnObjLeave(oLuaObj, nBattleID) end)
    oDup:RegObjLeaveCallback(function(oLuaObj) self:OnObjAfterEnter(oLuaObj) end)
end

function CFBTransitScene:Release()
    self.m_tRoleMap = {}
end

function CFBTransitScene:GetType() return self.m_nType end

-- function CFBTransitScene:OnObjEnter(oLuaObj, bReconnect)
function CFBTransitScene:AfterObjEnter(oLuaObj)
    local nObjTYpe = oLuaObj:GetObjType()
    if nObjTYpe == gtGDef.tObjType.eRole then
        self.m_tRoleMap[oLuaObj:GetID()] = oLuaObj

        --中转场景回调参加副本活动请求
        if oLuaObj:GetTeamID() > 0 and not oLuaObj:IsLeader() then
            --队员不处理
            return
        else
            local TarBattleDupType = oLuaObj:GetTarBattleDupType()
            if TarBattleDupType and gtBattleDupClass[TarBattleDupType] then
                local cClass = gtBattleDupClass[TarBattleDupType]
                oLuaObj:SetTarBattleDupType(0)
                cClass:EnterBattleDupReq(oLuaObj)
            end
        end
    end
end

function CFBTransitScene:OnObjLeave(oLuaObj, nBattleID)
    local nObjTYpe = oLuaObj:GetObjType()
    if nObjTYpe == gtGDef.tObjType.eRole then
    end
end

function CFBTransitScene:OnObjAfterEnter(oLuaObj)
end

function CFBTransitScene:EnterFBTransitScene(oRole)
    local oDup = goDupMgr:GetDup(self.m_nDupMixID)
    if not oDup then return end
    local nDupConfID = oDup:GetDupID()
    assert(ctDupConf[nDupConfID], "没有此场景配置")
    local tBornPos = ctDupConf[nDupConfID].tBorn[1]
    local nFace = ctDupConf[nDupConfID].nFace
    oRole:EnterScene(oDup:GetMixID(), tBornPos[1],  tBornPos[2], -1, nFace)
end

function CFBTransitScene:Inst()
    local nDupConfID = 0
    for nID, tConf in pairs(ctDupConf) do
        if tConf.nBattleType == gtBattleDupType.eFBTransitScene then
            nDupConfID = nID
            break
        end
    end
    local tDupConf = assert(ctDupConf[nDupConfID], "副本不存在:"..nDupConfID)
    local oDup = goDupMgr:GetDup(nDupConfID)
    if not oDup then return end
    goFBTransitScene = goFBTransitScene or CFBTransitScene:new(oDup:GetMixID(), gtBattleDupType.eFBTransitScene)        
    return goFBTransitScene
end
