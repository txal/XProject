local tPingMap = {}
function CltCmdProc.Ping(nCmd, nSrc, nSession)
    LuaTrace("Test cmd time:", os.clock() - tPingMap[nSession])
end

function CltCmdProc.KeepAlive(nCmd, nSrc, nSession, nServerTime) 
    tPingMap[nSession] = os.clock()
    local oRobot = goRobotMgr:GetRobot(nSession)
    CmdNet.Clt2Srv(oRobot:GenPacketIdx(), nSession, "Ping")
end


function CltPBProc.LoginRet(nCmd, nSrc, nSession, tData)
    local nCode = tData.nCode
    local oRobot = goRobotMgr:GetRobot(nSession)
    if oRobot then
        oRobot:OnLoginRet(nCode)
    end
end

function CltPBProc.CreateRoleRet(nCmd, nSrc, nSession, tData)
    local nCode = tData.nCode
    local oRobot = goRobotMgr:GetRobot(nSession)
    if oRobot then
        oRobot:OnCreateRoleRet(nCode)
    end
end

function CltPBProc.PlayerInitDataRet(nCmd, nSrc, nSession, tData)
    --print("PlayerInitDataRet***", tData)
end

function CltPBProc.PlayerEnterSceneRet(nCmd, nSrc, nSession, tData)
    local oRobot = goRobotMgr:GetRobot(nSession)
    if oRobot then
        oRobot:OnEnterScene(tData)
    end
end

function CltPBProc.PlayerLeaveSceneRet(nCmd, nSrc, nSession, tData)
end

function CltPBProc.PlayerEnterViewSync(nCmd, nSrc, nSession, tData)
    local tPlayerList = tData.tPlayerList
    --print("Enter:", tPlayerList)
end

function CltPBProc.MonsterEnterViewSync(nCmd, nSrc, nSession, tData)
    local tMonsterList = tData.tMonsterList
    --print("Enter:", tMonsterList)
end


function CltPBProc.ObjLeaveViewSync(nCmd, nSrc, nSession, tData)
    local tObjList = tData.tObjList
    --print("Leave:", tObjList)
end

function CltPBProc.PlayerSwitchWeaponSync(nCmd, nSrc, nSession, tData)
    --print("Leave:", tObjList)
end
