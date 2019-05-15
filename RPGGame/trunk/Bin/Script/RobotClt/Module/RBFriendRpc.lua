function CltPBProc.FriendListRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if not oRobot then return end
    oRobot.m_tModuleMap["friend"]:FriendListRet(tData)
end


function CltPBProc.SearchFriendRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if not oRobot then return end
    oRobot.m_tModuleMap["friend"]:SearchFriendRet(tData)
end


function CltPBProc.FriendApplyListRet(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRobot = goRobotMgr:GetRobot(nTarSession)
    if not oRobot then return end
    oRobot.m_tModuleMap["friend"]:FriendApplyListRet(tData)
end