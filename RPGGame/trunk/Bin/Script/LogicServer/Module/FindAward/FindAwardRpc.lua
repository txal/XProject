function CltPBProc.FindAwardInfoReq(nCmd, nServer, nService, nSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFindAward:FindAwardInfoReq(tData.nTarType)
end

function CltPBProc.FindAwardGetAwardReq(nCmd, nServer, nService, nSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFindAward:FindAwardGetAwardReq(tData.nTarType, tData.nType, tData.bUseZY, tData.bYB)
end

function CltPBProc.OneKeyFindAwardReq(nCmd, nServer, nService, nSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFindAward:OneKeyFindAwardReq(tData.bUseZY, tData.nTarType)
end