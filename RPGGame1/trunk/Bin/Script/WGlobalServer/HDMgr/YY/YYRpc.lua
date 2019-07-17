

--------------服务器内部
function Network.RpcSrv2Srv.ActYYStateReq(nSrcServer,nSrcService,nTarSession,nRoleID,tData)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local nActivityID = tData.nID
	local oAct = goHDMgr:GetActivity(nActivityID)
	if not oAct then
		return oRole:Tips("不存在这个活动")
	end
	oAct:SyncState(oRole)
end

function Network.RpcSrv2Srv.ActYYInfoReq(nSrcServer,nSrcService,nTarSession,nRoleID,tData)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local nActivityID = tData.nID
	local nTarget = tData.nTarget
	local oAct = goHDMgr:GetActivity(nActivityID)
	if not oAct then
		return oRole:Tips("不存在这个活动")
	end
	oAct:InfoReq(oRole,nTarget)
end

function Network.RpcSrv2Srv.ActYYAwardReq(nSrcServer,nSrcService,nTarSession,nRoleID,tData)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local nActivityID = tData.nID
	local oAct = goHDMgr:GetActivity(nActivityID)
	if not oAct then
		return oRole:Tips("不存在这个活动")
	end
	oAct:AwardReq(oRole, tData.nRewardID)
end
