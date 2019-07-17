--客户端->服务器

function Network.CltPBProc.GetAchieveRewardReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oAchieve:GetAchieveRewardReq(tData.nAchieveID)
end

function Network.CltPBProc.OpeneAchieveReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	oRole.m_oAchieve:OpenTypeAchieveReq(tData.nType)
end

function Network.CltPBProc.OpenAchieveMain(nCmd,nServer,nService,nSession,tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	oRole.m_oAchieve:SyncAchieveList()
end

------服务器之间-------
function Network.RpcSrv2Srv.PushAchieve(nSrcServer, nSrcService, nTarSession, nRoleID,sEvent,tData)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	oRole.m_oAchieve:PushAchieve(sEvent,tData)
end
