

------------------ Svr2Svr -----------------
function Srv2Srv.RoleLoverUpdateReq(nSrcServer, nSrcService, nTarSession, nRoleID, tData)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    return oRole.m_oLover:UpdateData(tData)
end

