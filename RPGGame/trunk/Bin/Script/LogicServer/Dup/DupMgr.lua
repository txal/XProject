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
            local oDup = self:CreateDup(nDupID)
            --fix pd 测试
            goMonsterMgr:CreateMonster(1, oDup:GetMixID(), 100, 100)
        end
    end
end

--取副本对象
--@nDupMixID: 副本唯一ID, 城镇:=nDupID; 副本:=自增ID<<16|nDupID 下同
function CDupMgr:GetDup(nDupMixID)
    return self.m_tDupMap[nDupMixID]
end

--创建副本
--@nDupID: 副本配置ID 下同
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
--@nDupMixID: 同上
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
    print("CDupMgr:EnterDup***", nDupMixID, nPosX, nPosY, nLine)
    local nDupID = GF.GetDupID(nDupMixID)
    local tDupConf = assert(ctDupConf[nDupID], "副本配置不存在:"..nDupID)

    --进入新副本
    if tLogicMap[tDupConf.nLogic] then
        --城镇
        if tDupConf.nType == CDupBase.tType.eCity then
            local oDup = self:GetDup(nDupMixID)
            assert(oDup, "城镇应该是先创建好的")
            return oDup:Enter(oNativeObj, nPosX, nPosY, nLine)

        else
        --副本
            local oDup = self:GetDup(nDupMixID)
            if not oDup then
                oDup = self:CreateDup(nDupID)
            end
            return oDup:Enter(oNativeObj, nPosX, nPosY, nLine)

        end
    end

    --切换逻辑服
    assert(oNativeObj:GetObjType() == gtObjType.eRole, "只有角色才跨服务")
    self:SwitchLogic(oNativeObj:GetObjID(), oNativeObj:GetDupMixID(), nDupMixID, nPosX, nPosY, nLine)
    return 0
end

--切换逻辑服(请求)
function CDupMgr:SwitchLogic(nRoleID, nSrcDupMixID, nTarDupMixID, nPosX, nPosY, nLine)
    print("CDupMgr:SwitchLogic***", nRoleID, nRoleID, nSrcDupMixID, nTarDupMixID, nPosX, nPosY, nLine)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    goPlayerMgr:RoleOfflineReq(nRoleID, true) --把当前逻辑服的角色下了

    local nTarDupID = GF.GetDupID(nTarDupMixID)
    local tDupConf = assert(ctDupConf[nTarDupID])
    goRemoteCall:Call("SwitchLogicReq", oRole:GetServer(), tDupConf.nLogic, oRole:GetSession()
        , oRole:GetServer(), nRoleID, nSrcDupMixID, nTarDupMixID, nPosX, nPosY, nLine)
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
