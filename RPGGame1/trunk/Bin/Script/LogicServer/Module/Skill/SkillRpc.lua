function Network.CltPBProc.SkillListReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oSkill:ListReq()
end

function Network.CltPBProc.SkillUpgradeReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oSkill:UpgradeReq(tData.nID)
end

function Network.CltPBProc.SkillOnekeyUpgradeReq(nCmd, nServer, Service, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oSkill:OnekeyUpgradeReq()
end

function Network.CltPBProc.SkillManufactureItemReq(nCmd, nServer, Service, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oSkill:ManufactureItemReq(tData.nSkillID)
end
