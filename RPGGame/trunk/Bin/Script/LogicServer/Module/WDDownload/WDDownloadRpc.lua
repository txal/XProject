function CltPBProc.WDDownloadedReq(nCmd, nServer, nService, nSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oWDDownload:WDDownloadedReq()
end

function CltPBProc.WDDownloadInfoReq(nCmd, nServer, nService, nSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oWDDownload:WDDownloadInfoReq()
end

function CltPBProc.GetWDDownloadAwardReq(nCmd, nServer, nService, nSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oWDDownload:GetWDDownloadAwardReq()
end

