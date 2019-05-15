function CltPBProc.ActLCStateReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eLC)
	oAct:SyncState(oRole)
end

function CltPBProc.ActLCInfoReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eLC)
	oAct:InfoReq(oRole)
end

function CltPBProc.ActLCAwardReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eLC)
	oAct:AwardReq(oRole, tData.nID)
end



--------------服务器内部
