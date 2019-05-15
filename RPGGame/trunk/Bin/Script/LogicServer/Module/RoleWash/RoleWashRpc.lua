---客户端通讯
function CltPBProc.RWPlanInfoReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oRoleWash:PlanInfoReq(tData.nPlan)
end

function CltPBProc.RWSavePlanReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oRoleWash:SavePlanReq(tData.tPotenAttr)
end

function CltPBProc.RWUsePlanReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oRoleWash:UsePlanReq(tData.nPlan)
end

function CltPBProc.RWResetInfoReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oRoleWash:ResetInfoReq()
end

function CltPBProc.RWResetReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oRoleWash:ResetReq(tData.nAttrType, tData.bYuanBao)
end

function CltPBProc.RWSetRecommandPlanReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oRoleWash:SetRecommandPlanReq(tData.tRecommandPlan, tData.nRecommandPlan, tData.bAutoAddPoten)
end
