gtPingMap = {}
function Network.CltCmdProc.Ping(nCmd, nSrcServer, nSrcService, nTarSession)
    LuaTrace("ping time:", CUtil:GetClockMSTime() - gtPingMap[nTarSession])
end

function Network.CltCmdProc.KeepAlive(nCmd, nSrcServer, nSrcService, nTarSession, nServerTime) 
    --gtPingMap[nTarSession] = os.clock()
    --local oRobot = goRobotMgr:GetRobot(nTarSession)
    --Network.BsrCmdProc
Network.Clt2Srv("Ping", oRobot:PacketID(), nTarSession)
end

function Network.CltPBProc.RoleListRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if oRobot then
        oRobot:OnRoleListRet(tData)
    end
end

function Network.CltPBProc.RoleLoginRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    print("Network.CltPBProc.RoleLoginRet***", tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if oRobot then
        oRobot:OnLoginRet(tData)
    end
end

function Network.CltPBProc.OtherPlaceLoginRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    local sName = ""
    if oRobot then
        sName = oRobot:GetName()
    end
    print("异地登录", sName)
end


function Network.CltPBProc.RoleInitDataRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    -- print("Network.CltPBProc.RoleInitDataRet***", tData)
end


function Network.CltPBProc.RoleEnterSceneRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    -- print("Network.CltPBProc.RoleEnterSceneRet***", tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if oRobot then
        oRobot:OnEnterScene(tData)
    end
end

function Network.CltPBProc.RoleLeaveSceneRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    -- print("Network.CltPBProc.RoleLeaveSceneRet***", tData)
end

function Network.CltPBProc.RoleEnterViewRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    -- print("Network.CltPBProc.RoleEnterViewRet***", tData)
    -- local tList = tData.tList
end

function Network.CltPBProc.MonsterEnterViewRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    -- print("Network.CltPBProc.MonsterEnterViewRet***", tData)
    -- local tList = tData.tList
end


function Network.CltPBProc.ObjLeaveViewRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    -- print("Network.CltPBProc.ObjLeaveViewRet***", tData)
    -- local tList = tData.tList
end

function Network.CltPBProc.TipsMsgRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    print("Tips:", tData.sCont)
end


function Network.CltPBProc.RoundBeginRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    -- print("Network.CltPBProc.RoundBeginRet***", tData)
end

function Network.CltPBProc.UnitInstRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    -- print("Network.CltPBProc.UnitInstRet***", tData)
end

function Network.CltPBProc.RoundDataRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    -- print("Network.CltPBProc.RoundDataRet***", tData)
end

function Network.CltPBProc.ConfirmRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    print("Network.CltPBProc.ConfirmRet***", tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if not oRobot then return end
    oRobot:SendMsg("ConfirmReactReq", {nCallID=tData.nCallID, nService=tData.nService, nSelIdx=2})
end
