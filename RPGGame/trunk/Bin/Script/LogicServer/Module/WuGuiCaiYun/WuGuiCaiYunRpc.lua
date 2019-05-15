function CltPBProc.WuGuiCaiYunInfoReq(nCmd, nServer, nService, nSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oWGCY:WuGuiCaiYunInfoReq()
end 

function CltPBProc.GetWuGuiCaiYunAwardReq(nCmd, nServer, nService, nSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oWGCY:GetWuGuiCaiYunAwardReq(tData.nID)
end

