

function Network.CltPBProc.yaoshoutuxiAttacReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oYaoShouTuXi:yaoshouAttacReq(tData.nYaoShouID)
end


--广播场景通知
function Network.RpcSrv2Srv.BroadcastYaoShouReq(nSrcServer, nSrcService, nTarSession, nRoleID, nYaoShouID, tYaoShouInfo)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	oRole.m_oYaoShouTuXi:BroadcastYaoShou(nYaoShouID, tYaoShouInfo)
end