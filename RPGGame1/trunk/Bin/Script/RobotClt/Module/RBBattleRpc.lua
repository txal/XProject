function Network.CltPBProc.BattleStartRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if not oRobot then return end
    oRobot.m_tModuleMap["battle"]:OnBattleStartRet(tData)
end

function Network.CltPBProc.BattleEndRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if not oRobot then return end
    oRobot.m_tModuleMap["battle"]:OnBattleEndRet(tData)
end