--客户端->服务器
function Network.CltPBProc.WillOpenInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oWillOpen:WillOpenInfoReq()
end

function Network.CltPBProc.WillOpenRewardReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oWillOpen:GetRewardReq()
end