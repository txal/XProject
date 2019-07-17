function Network.CltPBProc.lifeskillListReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oAssistedSkill:ListReq()
end

function Network.CltPBProc.lifeskillUpgradeReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oAssistedSkill:UpgradeReq(tData.nID, tData.nUpdateLv)
end

function Network.CltPBProc.lifeskillManufactureItemReq(nCmd, nServer, Service, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oAssistedSkill:SkillManufactureItem(tData.nID, tData.nItemID, tData.nNum)
end

function Network.CltPBProc.lifeskillVitalityPagReq(nCmd, nServer, Service, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oAssistedSkill:VitalityPagReq()
end

function Network.CltPBProc.lifeskillVitalityMakeReq(nCmd, nServer, Service, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oAssistedSkill:VitalityMakeReq(tData.nSkillID, tData.nItemID)
end

function Network.CltPBProc.lifeskillAddVitalityReq(nCmd, nServer, Service, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oAssistedSkill:AddVitalityReq()
end


function Network.RpcSrv2Srv.ChangeUnionContri(nSrcServer,nSrcService,nTarSession, nRoleID, nPropID)
	 local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then
        return 
    end
    oRole.m_oAssistedSkill:ChangeUnionContri(nPropID)
end