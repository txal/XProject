function CNewbieGuide:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nStep = 0
end

function CNewbieGuide:LoadData(tData)
	self.m_nStep = tData.nStep or 0
end

function CNewbieGuide:SaveData()
	local tData = {}
	tData.nStep = self.m_nStep
	return tData
end

function CNewbieGuide:GetType()
	return gtModuleDef.tNewbieGuide.nID, gtModuleDef.tNewbieGuide.sName
end

function CNewbieGuide:GetGuideStepReq()
	print("CNewbieGuide:GetGuideStepReq***", self.m_nStep)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "NewbieGuideStepRet", {nStep=self.m_nStep})
end

function CNewbieGuide:SetGuideStepReq(nStep)
	print("CNewbieGuide:SetGuideStepReq***", nStep)
	self.m_nStep = nStep
end