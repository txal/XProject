function Network.CltPBProc.ActFBStateReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eFB)
	oAct:SyncState(oRole)
end
