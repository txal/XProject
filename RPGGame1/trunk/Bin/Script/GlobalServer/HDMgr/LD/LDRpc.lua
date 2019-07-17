function Network.CltPBProc.ActLDStateReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eLD)
	oAct:SyncState(oRole)
end

function Network.CltPBProc.ActLDInfoReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eLD)
	oAct:InfoReq(oRole)
end

function Network.CltPBProc.ActLDAwardReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eLD)
	oAct:AwardReq(oRole, tData.nID)
end
