function CltPBProc.ShangJinAllTaskReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    oRole.m_oShangJinTask:AllTaskReq()
end

function CltPBProc.ShangJinRefreshReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    oRole.m_oShangJinTask:TaskRefreshReq(tData.bUseGold)
end

function CltPBProc.ShangJinAccepReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    oRole.m_oShangJinTask:TaskAccepReq(tData.nTaskID)
end

function CltPBProc.ShangJinAttReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    oRole.m_oShangJinTask:ShangJinAttReq()
end

function CltPBProc.YuanBaoCompReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    oRole.m_oShangJinTask:UseYuanBaoComp(tData.nTaskID)
end