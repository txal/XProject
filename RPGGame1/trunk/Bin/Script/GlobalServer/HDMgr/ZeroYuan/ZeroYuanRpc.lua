function Network.CltPBProc.ZYActStateReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eZeroYuan)
	if oAct then
		oAct:SyncState(oRole)
	end
end


function Network.CltPBProc.ZYActInfoReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eZeroYuan)
	if oAct then
		oAct:InfoReq(oRole)
	end
end

function Network.CltPBProc.ZYActAwardReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eZeroYuan)
	if oAct then
		oAct:AwardReq(oRole, tData.nID)
	end
end

function Network.CltPBProc.ZYBuyQualificattionsReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eZeroYuan)
	if oAct then
		oAct:BuyQualificattionsReq(oRole, tData.nID)
	end
end