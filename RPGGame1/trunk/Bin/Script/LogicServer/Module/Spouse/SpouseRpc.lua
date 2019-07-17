

------------------ Svr2Svr -----------------
function Network.RpcSrv2Srv.RoleSpouseUpdateReq(nSrcServer, nSrcService, nTarSession, nRoleID, tData)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    return oRole.m_oSpouse:UpdateData(tData)
end
