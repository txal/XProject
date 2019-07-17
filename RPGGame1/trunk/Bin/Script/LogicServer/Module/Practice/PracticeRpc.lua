function Network.CltPBProc.PracticeInfoReq(nCmd, nServer, Srevice, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPractice:InfoReq(tData.nID)
end

function Network.CltPBProc.PracticeLearnReq(nCmd, nServer, Srevice, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPractice:LearnReq(tData.nID, tData.nTimes)
end

function Network.CltPBProc.PracticeUsePropReq(nCmd, nServer, Srevice, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPractice:UsePropReq(tData.nID, tData.nPropID, tData.nUseNum)
end

function Network.CltPBProc.PracticeSetDefaultReq(nCmd, nServer, Srevice, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPractice:SetDefaultReq(tData.nID)
end
