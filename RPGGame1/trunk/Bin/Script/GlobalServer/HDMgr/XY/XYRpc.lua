function Network.CltPBProc.XYStateReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if not oAct then return oRole:Tips("活动不存在"..tData.nID) end
	oAct:SyncState(oRole)
end

function Network.CltPBProc.XYPropListReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if not oAct then return oRole:Tips("活动不存在"..tData.nID) end
	oAct:PropListReq(oRole)
end

function Network.CltPBProc.XYBuyPropReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if not oAct then return oRole:Tips("活动不存在"..tData.nID) end
	oAct:BuyPropReq(oRole, tData.nPropID)
end

function Network.CltPBProc.XYUsePropReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if not oAct then return oRole:Tips("活动不存在"..tData.nID) end
	oAct:UsePropReq(oRole, tData.nPropID)
end

function Network.CltPBProc.XYAwardInfoReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if not oAct then return oRole:Tips("活动不存在"..tData.nID) end
	oAct:AwardInfoReq(oRole)
end

function Network.CltPBProc.XYAwardReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if not oAct then return oRole:Tips("活动不存在"..tData.nID) end
	oAct:AwardReq(oRole)
end

function Network.CltPBProc.XYExchangeListReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if not oAct then return oRole:Tips("活动不存在"..tData.nID) end
	oAct:ExchangeListReq(oRole)
end

function Network.CltPBProc.XYExchangeReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if not oAct then return oRole:Tips("活动不存在"..tData.nID) end
	oAct:ExchangeReq(oRole, tData.nPropID)
end

function Network.CltPBProc.XYRankingReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if not oAct then return oRole:Tips("活动不存在"..tData.nID) end
	if tData.nType == 1 then
		oAct:RoleRankingReq(oRole, tData.nRankNum)
	elseif tData.nType == 2 then
		oAct:UnionRankingReq(oRole, tData.nRankNum)
	end
end

function Network.CltPBProc.XYRankAwardInfoReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if not oAct then return oRole:Tips("活动不存在"..tData.nID) end
	if tData.nType == 1 then
		oAct:RoleRankAwardInfoReq(oRole)
	elseif tData.nType == 2 then
		oAct:UnionRankAwardInfoReq(oRole)
	end
end

function Network.CltPBProc.XYRankAwardReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if not oAct then return oRole:Tips("活动不存在"..tData.nID) end
	if tData.nType == 1 then
		oAct:PlayerRankAwardReq(oRole)
	elseif tData.nType == 2 then
		oAct:UnionRankAwardReq(oRole)
	end
end

function Network.CltPBProc.XYDayAwardReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAct = goHDMgr:GetActivity(tData.nID)
	if not oAct then return oRole:Tips("活动不存在"..tData.nID) end
	oAct:DayAwardReq(oRole)
end



