function Network.CltPBProc.ShangJinAllTaskReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    oRole.m_oShangJinTask:AllTaskReq()
end

function Network.CltPBProc.ShangJinRefreshReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    oRole.m_oShangJinTask:TaskRefreshReq(tData.bUseGold)
end

function Network.CltPBProc.ShangJinAccepReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    oRole.m_oShangJinTask:TaskAccepReq(tData.nTaskID)
end

function Network.CltPBProc.ShangJinAttReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    oRole.m_oShangJinTask:ShangJinAttReq()
end

function Network.CltPBProc.YuanBaoCompReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    oRole.m_oShangJinTask:UseYuanBaoComp(tData.nTaskID)
end