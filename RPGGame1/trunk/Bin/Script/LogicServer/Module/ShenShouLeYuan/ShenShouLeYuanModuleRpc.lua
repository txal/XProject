--神兽乐园挑战请求
function Network.CltPBProc.ShenShouLeYuanChalReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShenShouLeYuanModule:Opera(tData.nChalType)
end