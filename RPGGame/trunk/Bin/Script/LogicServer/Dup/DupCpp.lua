--C++结构
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--对象进入场景
function OnObjEnterScene(nDupMixID, oNativeObj)
    local nObjID = oNativeObj:GetObjID()
    local nObjType = oNativeObj:GetObjType()

    local oLuaObj
   if nObjType == gtObjType.eRole then  
        oLuaObj = goPlayerMgr:GetRoleByID(nObjID)

    elseif nObjType == gtObjType.eMonster then
        oLuaObj = goMonsterMgr:GetMonster(nObjID)

    else
        assert(false, "objid:"..nObjID..",objtype:"..nObjType)
    end
    if not oLuaObj then
        return LuaTrace("对象不存在", nObjID, nObjType)
    end
    oLuaObj:OnEnterScene(nDupMixID)
end

--对象进入场景完成
function AfterObjEnterScene(nDupMixID, oNativeObj)
    local nObjID = oNativeObj:GetObjID()
    local nObjType = oNativeObj:GetObjType()

    local oLuaObj
   if nObjType == gtObjType.eRole then  
        oLuaObj = goPlayerMgr:GetRoleByID(nObjID)

    elseif nObjType == gtObjType.eMonster then
        oLuaObj = goMonsterMgr:GetMonster(nObjID)

    else
        assert(false, "objid:"..nObjID..",objtype:"..nObjType)
    end
    if not oLuaObj then
        return LuaTrace("对象不存在", nObjID, nObjType)
    end
    oLuaObj:AfterEnterScene(nDupMixID)
end

--对象离开场景
function OnObjLeaveScene(nDupMixID, oNativeObj)
    local nObjID = oNativeObj:GetObjID()
    local nObjType = oNativeObj:GetObjType()

    local oLuaObj
    if nObjType == gtObjType.eRole then  
        oLuaObj = goPlayerMgr:GetRoleByID(nObjID)

    elseif nObjType == gtObjType.eMonster then  
        oLuaObj = goMonsterMgr:GetMonster(nObjID)

    else
        assert(false, "objid:"..nObjID..",objtype:"..nObjType)
    end
    if not oLuaObj then
        return LuaTrace("对象不存在", nObjID, nObjType)
    end
    oLuaObj:OnLeaveScene(nDupMixID)
end

--场景对象进入对象
function OnObjEnterObj(nDupMixID, tObserver, tObserved)
    for i = 1, #tObserver do
        local oNativeObj = tObserver[i]
        local nObjType = oNativeObj:GetObjType()
        if nObjType == gtObjType.eRole then
            local nObjID = oNativeObj:GetObjID()
            local oRole = goPlayerMgr:GetRoleByID(nObjID)
            oRole:OnObjEnterObj(tObserved)
            
        end
    end
end

--场景对象离开对象
function OnObjLeaveObj(nDupMixID, tObserver, tObserved)
    local tSSList = {}
    for i = 1, #tObserver do
        local oNativeObj = tObserver[i]
        local nObjID = oNativeObj:GetObjID()
        local nObjType = oNativeObj:GetObjType()

        if nObjType == gtObjType.eRole then
            local oRole = goPlayerMgr:GetRoleByID(nObjID)
            local nServer = oRole:GetServer()
            local nSession = oRole:GetSession()
            table.insert(tSSList, nServer)
            table.insert(tSSList, nSession)
        end
    end
    local tList = {}
    for i = 1, #tObserved do
        table.insert(tList, tObserved[i]:GetAOIID())
    end
    CmdNet.PBBroadcastExter("ObjLeaveViewRet", tSSList, {tList=tList}) 
end

--场景被收集
function OnDupCollected(nDupMixID)
    goDupMgr:OnDupCollected(nDupMixID)
end
