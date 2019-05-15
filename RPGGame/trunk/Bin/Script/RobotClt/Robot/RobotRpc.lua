gtPingMap = {}
function CltCmdProc.Ping(nCmd, nSrcServer, nSrcService, nTarSession)
    LuaTrace("ping time:", GF.GetClockMSTime() - gtPingMap[nTarSession])
end

function CltCmdProc.KeepAlive(nCmd, nSrcServer, nSrcService, nTarSession, nServerTime) 
    --gtPingMap[nTarSession] = os.clock()
    --local oRobot = goRobotMgr:GetRobot(nTarSession)
    --CmdNet.Clt2Srv("Ping", oRobot:PacketID(), nTarSession)
end

function CltPBProc.RoleListRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if oRobot then
        oRobot:OnRoleListRet(tData)
    end
end

function CltPBProc.RoleLoginRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    print("CltPBProc.RoleLoginRet***", tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if oRobot then
        oRobot:OnLoginRet(tData)
    end
end

function CltPBProc.OtherPlaceLoginRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    local sName = ""
    if oRobot then
        sName = oRobot:GetName()
    end
    print("异地登录", sName)
end


function CltPBProc.RoleInitDataRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    -- print("CltPBProc.RoleInitDataRet***", tData)
end


function CltPBProc.RoleEnterSceneRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    -- print("CltPBProc.RoleEnterSceneRet***", tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if oRobot then
        oRobot:OnEnterScene(tData)
    end
end

function CltPBProc.RoleLeaveSceneRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    -- print("CltPBProc.RoleLeaveSceneRet***", tData)
end

function CltPBProc.RoleEnterViewRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    -- print("CltPBProc.RoleEnterViewRet***", tData)
    -- local tList = tData.tList
end

function CltPBProc.MonsterEnterViewRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    -- print("CltPBProc.MonsterEnterViewRet***", tData)
    -- local tList = tData.tList
end


function CltPBProc.ObjLeaveViewRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    -- print("CltPBProc.ObjLeaveViewRet***", tData)
    -- local tList = tData.tList
end

function CltPBProc.TipsMsgRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    print("Tips:", tData.sCont)
end


function CltPBProc.RoundBeginRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    -- print("CltPBProc.RoundBeginRet***", tData)
end

function CltPBProc.UnitInstRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    -- print("CltPBProc.UnitInstRet***", tData)
end

function CltPBProc.RoundDataRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    -- print("CltPBProc.RoundDataRet***", tData)
end

function CltPBProc.ConfirmRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    print("CltPBProc.ConfirmRet***", tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if not oRobot then return end
    oRobot:SendMsg("ConfirmReactReq", {nCallID=tData.nCallID, nService=tData.nService, nSelIdx=2})
end
