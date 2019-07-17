function Network.CltPBProc.TimeAwardStateReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eTimeAward)
	oAct:SyncState(oRole)
end

function Network.CltPBProc.TimeAwardProgressReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eTimeAward)
	local oSubAct = oAct:GetAct(tData.nID)
	if not oSubAct then
		return
	end
	oSubAct:ProgressReq(oRole)
end

function Network.CltPBProc.TimeAwardRankingReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eTimeAward)
	local oSubAct = oAct:GetAct(tData.nID)
	if not oSubAct then
		return oRole:Tips("活动未开启")
	end
	oSubAct:RankingReq(oRole, tData.nRankNum)
end

function Network.CltPBProc.TimeAwardAwardReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eTimeAward)
	local oSubAct = oAct:GetAct(tData.nID)
	if not oSubAct then
		return oRole:Tips("活动未开启")
	end
	oSubAct:AwardReq(oRole, tData.nAwardID)
end




--------------------服务器内部
function Network.RpcSrv2Srv.OnTAYBReq(nSrcServer, nSrcService, nTarSession, nRoleID, nVal)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eTimeAward)
	oAct:UpdateVal(oRole:GetID(), gtTAType.eYB, math.abs(nVal))
end
function Network.RpcSrv2Srv.OnTAJBReq(nSrcServer, nSrcService, nTarSession, nRoleID, nVal)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eTimeAward)
	oAct:UpdateVal(oRole:GetID(), gtTAType.eJB, math.abs(nVal))
end
function Network.RpcSrv2Srv.OnTAZZDReq(nSrcServer, nSrcService, nTarSession, nRoleID, nVal)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eTimeAward)
	oAct:UpdateVal(oRole:GetID(), gtTAType.eZZD, math.abs(nVal))
end
function Network.RpcSrv2Srv.OnTADZReq(nSrcServer, nSrcService, nTarSession, nRoleID, nVal)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eTimeAward)
	oAct:UpdateVal(oRole:GetID(), gtTAType.eDJ, math.abs(nVal))
end
function Network.RpcSrv2Srv.OnTAHYDReq(nSrcServer, nSrcService, nTarSession, nRoleID, nVal)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eTimeAward)
	oAct:UpdateVal(oRole:GetID(), gtTAType.eHYD, nVal)
end
function Network.RpcSrv2Srv.OnTAHLReq(nSrcServer, nSrcService, nTarSession, nRoleID, nVal)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eTimeAward)
	oAct:UpdateVal(oRole:GetID(), gtTAType.eHL, math.abs(nVal))
end
function Network.RpcSrv2Srv.OnTAJJCReq(nSrcServer, nSrcService, nTarSession, nRoleID, nVal)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eTimeAward)
	oAct:UpdateVal(oRole:GetID(), gtTAType.eJJC, nVal)
end
function Network.RpcSrv2Srv.OnTATZSReq(nSrcServer, nSrcService, nTarSession, nRoleID, nVal)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eTimeAward)
	oAct:UpdateVal(oRole:GetID(), gtTAType.eTZS, math.abs(nVal))
end
function Network.RpcSrv2Srv.OnTATBReq(nSrcServer, nSrcService, nTarSession, nRoleID, nVal)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eTimeAward)
	oAct:UpdateVal(oRole:GetID(), gtTAType.eTB, math.abs(nVal))
end
function Network.RpcSrv2Srv.OnTAXYXReq(nSrcServer, nSrcService, nTarSession, nRoleID, nVal)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eTimeAward)
	oAct:UpdateVal(oRole:GetID(), gtTAType.eXYX, math.abs(nVal))
end
function Network.RpcSrv2Srv.OnTAXDReq(nSrcServer, nSrcService, nTarSession, nRoleID, nVal)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(gtHDDef.eTimeAward)
	oAct:UpdateVal(oRole:GetID(), gtTAType.eXD, math.abs(nVal))
end