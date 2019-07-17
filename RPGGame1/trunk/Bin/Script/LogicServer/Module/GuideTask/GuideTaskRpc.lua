function Network.CltPBProc.GuideTaskInfoReq(nCmd, nServer, nService, nSession, tData)
end

function Network.CltPBProc.GuideTaskRewardReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oGuideTask:GetReward(tData.nTaskID)
end