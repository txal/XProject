--副本/场景管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--本服的逻辑服映射
local tLogicMap= {}
for k, tConf in pairs(gtServerConf.tLogicService) do
    tLogicMap[tConf.nID] = tConf
end

function CDupMgr:Ctor()
    self.m_tDupMap = {}
end

function CDupMgr:Init()
    for nDupID, tConf in pairs(ctDupConf) do
        if tConf.nType == CDupBase.tType.eCity and tLogicMap[tConf.nLogic] then
            self:CreateDup(nDupID)
        end
    end
end

--取副本对象
--@nDupMixID: 副本唯一ID, 城镇:dupid 副本:autoid<<16|dupid 下同
function CDupMgr:GetDup(nDupMixID)
    return self.m_tDupMap[nDupMixID]
end

--创建副本
function CDupMgr:CreateDup(nDupID)
    print("CDupMgr:CreateDup***", nDupID)
    local tDupConf = assert(ctDupConf[nDupID], "副本不存在:"..nDupID)
    if not tLogicMap[tDupConf.nLogic] then
        assert(false, "不能创建非本逻辑服副本:"..nDupID)
    end
    local oDup = CDupBase:new(nDupID)
    self.m_tDupMap[oDup:GetMixID()] = oDup
    return oDup
end

--移出副本
--@nDupMixID: 副本唯一ID, 城镇:dupid 副本:autoid<<16|dupid 下同
function CDupMgr:RemoveDup(nDupMixID)
    print("CDupMgr:RemoveDup***", nDupMixID)
    local oDup = self:GetDup(nDupMixID)
    assert(oDup, "副本不存在:"..nDupMixID)
    oDup:OnRelease()
    self.m_tDupMap[nDupMixID] = nil
end

--进入副本,不存在则失败
--@nDupMixID: 同上
--@oNativeObj: C++对象
--@nPosX,nPosY: 坐标
--@分线: 0公共线; -1自动
--返回值: AOIID, 大于0成功; 小于等于0失败
function CDupMgr:EnterDup(nDupMixID, oNativeObj, nPosX, nPosY, nLine)
    print("CDupMgr:EnterDup***", GF.GetDupID(nDupMixID), nPosX, nPosY, nLine)
    --先离开旧副本
    local nCurrMixID = oNativeObj:GetDupMixID()
    if nCurrMixID > 0 then
        self:LeaveDup(nCurrMixID, oNativeObj:GetAOIID())
    end

    --进入新副本
    local nDupID = GF.GetDupID(nDupMixID)
    local tDupConf = assert(ctDupConf[nDupID], "副本配置不存在:"..nDupID)
    if tLogicMap[tDupConf.nLogic] then
        local oDup = self:GetDup(nDupMixID)
        assert(oDup, "副本不存在:"..nDupMixID)
        return oDup:Enter(oNativeObj, nPosX, nPosY, nLine)
    end

    --切换逻辑服
    assert(oNativeObj:GetObjType() == gtObjType.eRole, "只有角色才跨服务")
    self:SwitchLogic(oNativeObj:GetObjID(), oNativeObj:GetConfID(), GF.GetDupID(nCurrMixID), nDupID, nPosX, nPosY, nLine)
    return 0
end

--进入副本,不存在则创建
--@nDupID: 副本配置ID
--@oNativeObj: 同上
--@nPosX,nPosY: 同上
--@分线: 同上
--返回值: AOIID, 大于0成功; 小于等于0失败
function CDupMgr:EnterDupCreate(nDupID, oNativeObj, nPosX, nPosY, nLine)
    print("CDupMgr:EnterDupCreate***", nDupID, oNativeObj, nPosX, nPosY, nLine)
    --先离开旧副本
    local nCurrMixID = oNativeObj:GetDupMixID()
    if nCurrMixID > 0 then
        self:LeaveDup(nCurrMixID, oNativeObj:GetAOIID())
    end

    --进入新副本
    local tDupConf = assert(ctDupConf[nDupID], "副本配置不存在")
    if tLogicMap[tDupConf.nLogic] then
        if tDupConf.nType == CDupBase.tType.eCity then
            if GF.GetDupID(nCurrMixID) == nDupID then
                return LuaTrace("角色已经在副本:", nDupID)
            end
            local oDup = self:GetDup(nDupID)
            assert(oDup, "城镇应该是先创建好的")
            return oDup:Enter(oNativeObj, nPosX, nPosY, nLine)
        else
            local oDup = self:CreateDup(nDupID)
            return oDup:Enter(oNativeObj, nPosX, nPosY, nLine)
        end
    end

    --切换逻辑服
    assert(oNativeObj:GetObjType() == gtObjType.eRole, "只有角色才跨服务")
    self:SwitchLogic(oNativeObj:GetObjID(), oNativeObj:GetConfID(), GF.GetDupID(nCurrMixID), nDupID, nPosX, nPosY, nLine)
    return 0
end

--切换逻辑服
function CDupMgr:SwitchLogic(nAccountID, nRoleID, nSrcDupID, nTarDupID, nPosX, nPosY, nLine)
    print("CDupMgr:SwitchLogic***", nAccountID, nRoleID, nSrcDupID, nTarDupID, nPosX, nPosY, nLine)
    local oAccount = goPlayerMgr:GetAccountByID(nAccountID)
    goPlayerMgr:OfflineReq(nAccountID, true) --把当前逻辑服的帐号下了
    local tDupConf = ctDupConf[nTarDupID]
    goRemoteCall:Call("SwitchLogicReq", oAccount:GetServer(), tDupConf.nLogic, oAccount:GetSession()
        , oAccount:GetServer(), nAccountID, nRoleID, nSrcDupID, nTarDupID, nPosX, nPosY, nLine)
end

--离开副本
function CDupMgr:LeaveDup(nDupMixID, nAOIID)
    print("CDupMgr:LeaveDup***", nDupMixID, nAOIID)
    if nDupMixID == 0 then return end
    local oDup = self:GetDup(nDupMixID)
    assert(oDup, "副本不存在:"..nDupMixID)
    oDup:Leave(nAOIID)
end

--副本被回收
function CDupMgr:OnDupCollected(nDupMixID)
    print("CDupMgr:OnDupCollected***", GF.GetDupID(nDupMixID))
    local oDup = self:GetDup(nDupMixID)
    if not oDup then
        return
    end
    oDup:OnRelease()
    self.m_tDupMap[nDupMixID] = nil
end


goDupMgr = goDupMgr or CDupMgr:new()
goNativeDupMgr = GlobalExport.GetDupMgr()
