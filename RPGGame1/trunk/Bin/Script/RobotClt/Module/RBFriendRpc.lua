function Network.CltPBProc.FriendListRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if not oRobot then return end
    oRobot.m_tModuleMap["friend"]:FriendListRet(tData)
end


function Network.CltPBProc.SearchFriendRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if not oRobot then return end
    oRobot.m_tModuleMap["friend"]:SearchFriendRet(tData)
end


function Network.CltPBProc.FriendApplyListRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if not oRobot then return end
    oRobot.m_tModuleMap["friend"]:FriendApplyListRet(tData)
end