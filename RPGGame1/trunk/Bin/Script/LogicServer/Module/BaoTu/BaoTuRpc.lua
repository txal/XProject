--客户端->服务器
function Network.CltPBProc.WaBaoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oBaoTu:WaBaoPosReq(tData.nWaBaoType)
end

function Network.CltPBProc.WaBaoStatusReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oBaoTu:WaBaoStatusReq(tData.nWaBaoType, tData.nStatusType)
end

function Network.CltPBProc.MapCompReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oBaoTu:MapCompReq(tData.bUseGold, tData.nCompNum)
end

function Network.CltPBProc.WaBaoInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oBaoTu:WaBaoInfoReq()
end

