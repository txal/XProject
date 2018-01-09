function CNewbieGuid:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nStep = 0
end

function CNewbieGuid:LoadData(tData)
	self.m_nStep = tData.nStep or 0
end

function CNewbieGuid:SaveData()
	local tData = {}
	tData.nStep = m_nStep
	return tData
end

function CNewbieGuid:GetType()
	return gtModuleDef.tNewbieGuid.nID, gtModuleDef.tNewbieGuid.sName
end

function CNewbieGuid:GetGuidStepReq()
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "NewbieGuidStepRet", {nStep=self.m_nStep})
end

function CNewbieGuid:SetGuidStepReq(nStep)
	self.m_nStep = nStep
end