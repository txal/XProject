function Network.CltPBProc.ActYYStateReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local oAct = goHDMgr:GetActivity(tData.nID)
	if oAct then
		oAct:SyncState(oRole)
	-- else
	-- 	--全服团购首充
	-- 	if tData.nID == gtHDDef.eTC then
	-- 		Network:RMCall("ActYYStateReq", nil, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0,oRole:GetID(),tData)
	-- 	end
	end
end

function Network.CltPBProc.ActYYInfoReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if oAct then
		oAct:InfoReq(oRole, tData.nTarget)
	-- else
	-- 	if tData.nID == gtHDDef.eTC then
	-- 		Network:RMCall("ActYYInfoReq", nil, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0,oRole:GetID(),tData)
	-- 	end
	end
end

function Network.CltPBProc.ActYYAwardReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if oAct then
		oAct:AwardReq(oRole, tData.nRewardID)
	-- else
		-- if tData.nID == gtHDDef.eTC then
		-- 	Network:RMCall("ActYYAwardReq", nil, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0,oRole:GetID(),tData)
		-- end
	end
end



--------------服务器内部
