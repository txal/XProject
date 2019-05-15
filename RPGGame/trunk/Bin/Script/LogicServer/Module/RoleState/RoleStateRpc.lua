--客户端通讯
function CltPBProc.RoleStateBuyBaoShiReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oRoleState:BuyBaoShiTimesReq()
end

function CltPBProc.RoleStateMarriageSuitSetReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oRoleState:MarriageSuitActiveSet(tData.bActive)
end


