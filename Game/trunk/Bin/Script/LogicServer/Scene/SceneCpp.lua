local _random, _insert, _floor, _max, _min, _time = _random, table.insert, math.floor, math.max, math.min, os.time
--------------------scene cpp call --------------------

--对象进入场景
function OnObjEnterScene(nSceneIndex, oCppGameObj)
    local sGameObjID = oCppGameObj:GetObjID()
    local nGameObjType = oCppGameObj:GetObjType()
    local oLuaGameObj
   if nGameObjType == gtObjType.ePlayer then  
        oLuaGameObj = goLuaPlayerMgr:GetPlayerByCharID(sGameObjID)

    elseif nGameObjType == gtObjType.eMonster then
        oLuaGameObj = goLuaMonsterMgr:GetMonster(sGameObjID)

    elseif nGameObjType == gtObjType.eRobot then
        oLuaGameObj = goLuaSRobotMgr:GetRobot(sGameObjID)

    elseif nGameObjType == gtObjType.eSceneDrop then
        oLuaGameObj = goLuaDropItemMgr:GetDropItem(sGameObjID)

    else
        assert(false, "objid:"..sGameObjID..",objtype:"..nGameObjType)
    end
    assert(oLuaGameObj, "objid:"..sGameObjID..",objtype:"..nGameObjType)
    oLuaGameObj:OnEnterScene(nSceneIndex)
end

--对象进入场景完成
function AfterObjEnterScene(nSceneIndex, oCppGameObj)
    local sGameObjID = oCppGameObj:GetObjID()
    local nGameObjType = oCppGameObj:GetObjType()
    local oLuaGameObj
   if nGameObjType == gtObjType.ePlayer then  
        oLuaGameObj = goLuaPlayerMgr:GetPlayerByCharID(sGameObjID)

    elseif nGameObjType == gtObjType.eMonster then
        oLuaGameObj = goLuaMonsterMgr:GetMonster(sGameObjID)

    elseif nGameObjType == gtObjType.eRobot then
        oLuaGameObj = goLuaSRobotMgr:GetRobot(sGameObjID)

    elseif nGameObjType == gtObjType.eSceneDrop then
        oLuaGameObj = goLuaDropItemMgr:GetDropItem(sGameObjID)

    else
        assert(false, "objid:"..sGameObjID..",objtype:"..nGameObjType)
    end
    assert(oLuaGameObj, "objid:"..sGameObjID..",objtype:"..nGameObjType)
    oLuaGameObj:AfterEnterScene(nSceneIndex)
end

--对象离开场景
function OnObjLeaveScene(nSceneIndex, oCppGameObj)
    local sGameObjID = oCppGameObj:GetObjID()
    local nGameObjType = oCppGameObj:GetObjType()
    local oLuaGameObj
    if nGameObjType == gtObjType.ePlayer then  
        oLuaGameObj = goLuaPlayerMgr:GetPlayerByCharID(sGameObjID)

    elseif nGameObjType == gtObjType.eMonster then  
        oLuaGameObj = goLuaMonsterMgr:GetMonster(sGameObjID)

    elseif nGameObjType == gtObjType.eRobot then  
        oLuaGameObj = goLuaSRobotMgr:GetRobot(sGameObjID)

    elseif nGameObjType == gtObjType.eSceneDrop then  
        oLuaGameObj = goLuaDropItemMgr:GetDropItem(sGameObjID)

    else
        assert(false, "objid:"..sGameObjID..",objtype:"..nGameObjType)
    end
    assert(oLuaGameObj, "objid:"..sGameObjID..",objtype:"..nGameObjType)
    oLuaGameObj:OnLeaveScene(nSceneIndex)
end

--场景对象进入对象
function OnObjEnterObj(nSceneIndex, tObserver, tObserved)
    for i = 1, #tObserver do
        local oCppGameObj = tObserver[i]
        local nGameObjType = oCppGameObj:GetObjType()
        if nGameObjType == gtObjType.ePlayer then
            local sGameObjID = oCppGameObj:GetObjID()
            local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sGameObjID)
            oPlayer:OnObjEnterObj(tObserved)
            
        end
    end
end

--场景对象离开对象
function OnObjLeaveObj(nSceneIndex, tObserver, tObserved)
    local tSessionList = {}
    for i = 1, #tObserver do
        local oCppGameObj = tObserver[i]
        local sGameObjID = oCppGameObj:GetObjID()
        local nGameObjType = oCppGameObj:GetObjType()
        if nGameObjType == gtObjType.ePlayer then
            local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sGameObjID)
            local nSessionID = oPlayer:GetSession()
            _insert(tSessionList, nSessionID)
        end
    end
    local tObjList = {}
    for i = 1, #tObserved do
        _insert(tObjList, tObserved[i]:GetAOIID())
    end
    CmdNet.PBBroadcastExter(tSessionList, "ObjLeaveViewSync", {tObjList=tObjList}) 
end

--场景被收集
function OnSceneCollected(nSceneIndex)
    print("OnSceneCollected***", nSceneIndex)
    goLuaSceneMgr:OnSceneRelease(nSceneIndex)
end
