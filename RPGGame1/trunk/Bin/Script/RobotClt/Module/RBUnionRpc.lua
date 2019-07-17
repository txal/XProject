function Network.CltPBProc.UnionInfoRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if not oRobot then return end
    oRobot.m_tModuleMap["union"]:UnionInfoRet(tData)
end

function Network.CltPBProc.UnionListRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if not oRobot then return end
    oRobot.m_tModuleMap["union"]:UnionListRet(tData)
end

function Network.CltPBProc.MemberListRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if not oRobot then return end
    oRobot.m_tModuleMap["union"]:MemberListRet(tData)
end
