---客户端通讯
function Network.CltPBProc.RWPlanInfoReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oRoleWash:PlanInfoReq(tData.nPlan)
end

function Network.CltPBProc.RWSavePlanReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oRoleWash:SavePlanReq(tData.tPotenAttr)
end

function Network.CltPBProc.RWUsePlanReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oRoleWash:UsePlanReq(tData.nPlan)
end

function Network.CltPBProc.RWResetInfoReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oRoleWash:ResetInfoReq()
end

function Network.CltPBProc.RWResetReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oRoleWash:ResetReq(tData.nAttrType, tData.bYuanBao)
end

function Network.CltPBProc.RWSetRecommandPlanReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oRoleWash:SetRecommandPlanReq(tData.tRecommandPlan, tData.nRecommandPlan, tData.bAutoAddPoten)
end
