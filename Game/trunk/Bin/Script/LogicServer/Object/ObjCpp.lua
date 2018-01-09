--角色死亡
function OnActorDead(sObjID, nObjType, sAtkerID, nAtkerType, nArmID, nArmType)
    if nObjType == gtObjType.ePlayer then
        local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sObjID)   
        if not oPlayer then
            print("死亡玩家找不到", sObjID)
            return
        end
        local oBattle = oPlayer:GetModule(CBattle:GetType())
        oBattle:OnPlayerDead(sAtkerID, nAtkerType, nArmID, nArmType)

    elseif nObjType == gtObjType.eMonster then
        local oMonster = goLuaMonsterMgr:GetMonster(sObjID)   
        if not oMonster then
            print("死亡怪物找不到", sObjID)
            return
        end
        oMonster:OnMonsterDead(sAtkerID, nAtkerType, nArmID, nArmType)

    elseif nObjType == gtObjType.eRobot then
        local oSRobot = goLuaSRobotMgr:GetRobot(sObjID)   
        if not oSRobot then
            print("死亡机器人找不到", sObjID)
            return
        end
        oSRobot:OnRobotDead(sAtkerID, nAtkerType, nArmID, nArmType)

    end
end

--角色对象过期收集
function OnObjCollected(sObjID, sObjType)
    print("OnObjCollected", sObjID, sObjType)
    if sObjType == gtObjType.eMonster then
        goLuaMonsterMgr:OnMonsterCollected(sObjID)
    elseif sObjType == gtObjType.eRobot then
        goLuaSRobotMgr:OnRobotCollected(sObjID)
    elseif sObjType == gtObjType.eSceneDrop then
        goLuaDropItemMgr:OnDropItemCollected(sObjID)
    else
        assert(false, "对象收集不支持类型:"..sObjType)
    end
end

--角色身上BUFF过期
function OnActorBuffExpired(sObjID, nObjType, nBuffID)
    if nObjType == gtObjType.ePlayer then
        local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sObjID)
        if oPlayer then
            oPlayer:GetModule(CBattle:GetType()):OnBuffExpired(nBuffID)
        end
    elseif nObjType == gtObjType.eMonster then
        local oMonster = goLuaMonsterMgr:GetMonster(sObjID)
        if oMonster then
            oMonster:OnBuffExpired(nBuffID)
        end
    elseif nObjType == gtObjType.eRobot then
        local oSRobot = goLuaSRobotMgr:GetRobot(sObjID)
        if oSRobot then
            oSRobot:OnBuffExpired(nBuffID)
        end
    else
        assert(false, "BUFF过期不支持类型:"..nObjType)
    end
end

--机器人切换武器
function RobotSwitchWeapon(sObjID, nArmID)
    local oSRobot = goLuaSRobotMgr:GetRobot(sObjID)
    if oSRobot then
        oSRobot:OnSwitchWeapon(nArmID)
    end
end