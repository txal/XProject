local tPingMap = {}
function CltCmdProc.Ping(nCmd, nSrcService, nTarSession)
    LuaTrace("Test cmd time:", os.clock() - tPingMap[nTarSession])
end

function CltCmdProc.KeepAlive(nCmd, nSrcService, nSession, nServerTime) 
    tPingMap[nSession] = os.clock()
    -- local oRobot = goRobotMgr:GetRobot(nSession)
    -- CmdNet.Clt2Srv(oRobot:GenPacketIdx(), nSession, "Ping")
end


function CltPBProc.LoginRet(nCmd, nSrcService, nSession, tData)
    local nCode = tData.nCode
    local oRobot = goRobotMgr:GetRobot(nSession)
    if oRobot then
        oRobot:OnLoginRet(nCode)
    end
end

function CltPBProc.CreateRoleRet(nCmd, nSrcService, nSession, tData)
    local nCode = tData.nCode
    local oRobot = goRobotMgr:GetRobot(nSession)
    if oRobot then
        oRobot:OnCreateRoleRet(nCode)
    end
end

function CltPBProc.PlayerInitDataSync(nCmd, nSrcService, nSession, tData)
    --print("PlayerInitDataSync***", tData)
end

function CltPBProc.PlayerEnterSceneRet(nCmd, nSrcService, nSession, tData)
    local oRobot = goRobotMgr:GetRobot(nSession)
    if oRobot then
        oRobot:OnEnterScene(tData)
    end
end

function CltPBProc.PlayerLeaveSceneRet(nCmd, nSrcService, nSession, tData)
end

function CltPBProc.PlayerEnterViewSync(nCmd, nSrcService, nSession, tData)
    local tPlayerList = tData.tPlayerList
    --print("Enter:", tPlayerList)
end

function CltPBProc.MonsterEnterViewSync(nCmd, nSrcService, nSession, tData)
    local tMonsterList = tData.tMonsterList
    --print("Enter:", tMonsterList)
end


function CltPBProc.ObjLeaveViewSync(nCmd, nSrcService, nSession, tData)
    local tObjList = tData.tObjList
    --print("Leave:", tObjList)
end

function CltPBProc.PlayerSwitchWeaponSync(nCmd, nSrcService, nSession, tData)
    --print("Leave:", tObjList)
end

function CltPBProc.TipsMsgRet(nCmd, nSrcService, nSession, tData)
    print(tData.sCont)
end
