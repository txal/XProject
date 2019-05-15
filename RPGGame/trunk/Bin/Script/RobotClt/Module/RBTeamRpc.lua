function CltPBProc.TeamRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if not oRobot then return end
    oRobot.m_tModuleMap["team"]:OnTeamRet(tData)
end