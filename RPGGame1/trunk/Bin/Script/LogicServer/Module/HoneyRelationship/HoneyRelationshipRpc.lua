------客户端服务器------
--缘分情义信息请求
function Network.CltPBProc.RoleRelationshipQingyiInfoReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    oRole.m_oHoneyRelationship:SyncQingyiData()
end

--缘分情义升级请求
function Network.CltPBProc.RoleRelationshipQingyiLevelUpReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    oRole.m_oHoneyRelationship:QingyiLevelUpReq()
end

----------------Svr2Svr-----------------




