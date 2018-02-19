local tPingMap = {}
function CltCmdProc.Ping(nCmd, nSrcServer, nSrcService, nTarSession)
    LuaTrace("Ping time:", os.clock() - tPingMap[nTarSession])
end

function CltCmdProc.KeepAlive(nCmd, nSrcServer, nSrcService, nTarSession, nServerTime) 
    tPingMap[nTarSession] = os.clock()
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    CmdNet.Clt2Srv("Ping", oRobot:PacketID(), nTarSession)
end

function CltPBProc.RoleListRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if oRobot then
        oRobot:OnRoleListRet(tData)
    end
end

function CltPBProc.RoleLoginRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if oRobot then
        oRobot:OnLoginRet(tData)
    end
end

function CltPBProc.OtherPlayerLoginRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    local sName = ""
    if oRobot then
        sName = oRobot:GetName()
    end
    print("异地登录", sName)
end


function CltPBProc.RoleInitDataRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
end


function CltPBProc.RoleEnterSceneRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if oRobot then
        oRobot:OnEnterScene(tData)
    end
end

function CltPBProc.RoleLeaveSceneRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
end

function CltPBProc.RoleEnterVieRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local tRoleList = tData.tRoleList
end

function CltPBProc.MonsterEnterViewRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local tMonsterList = tData.tMonsterList
end


function CltPBProc.ObjLeaveViewRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local tObjList = tData.tObjList
end

function CltPBProc.TipsMsgRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    print("Tips:", tData.sCont)
end
