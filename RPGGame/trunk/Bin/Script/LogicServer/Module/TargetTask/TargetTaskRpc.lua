function CltPBProc.TargetTaskInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oTargetTask:SendTargetTaskInfo(oRole.m_oTargetTask.m_bIsComplete)
end

function CltPBProc.TargetTaskRewardReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oTargetTask:GetReward()
end

function CltPBProc.TargetTaskBattleReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oTargetTask:BattleTrainReq()
end
