function Network.CltPBProc.FindAwardInfoReq(nCmd, nServer, nService, nSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFindAward:FindAwardInfoReq(tData.nTarType)
end

function Network.CltPBProc.FindAwardGetAwardReq(nCmd, nServer, nService, nSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFindAward:FindAwardGetAwardReq(tData.nTarType, tData.nType, tData.bUseZY, tData.bYB)
end

function Network.CltPBProc.OneKeyFindAwardReq(nCmd, nServer, nService, nSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFindAward:OneKeyFindAwardReq(tData.bUseZY, tData.nTarType)
end