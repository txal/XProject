---客户端通讯

function Network.CltPBProc.PetAttrListReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:AttrListReq()
end


function Network.CltPBProc.PetEquitListReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:EquitListReq()
end


function Network.CltPBProc.PetSynthesisReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:SynthesisReq(tData.nZID, tData.nFID, tData.nZPos, tData.nFPos, tData.nBDType, tData.bFlag, tData.bYuanBaoBuy)
end


function Network.CltPBProc.PetEquitCptReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:PetEquitCptReq(tData.nZGrid, tData.nFGrid)
end


function Network.CltPBProc.PetTalismanResetReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:PetTalismanResetReq(tData.nID, tData.nPos, tData.bFlag, tData.nType, tData.nUseType)
end

function Network.CltPBProc.PetReleaseReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:ReleaseReq(tData.nID, tData.nPos)
end

function Network.CltPBProc.PetRenamedReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:RenamedReq(tData.nID, tData.nPos, tData.sNewName)
end


function Network.CltPBProc.PetCombatReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:CombatReq(tData.nID, tData.nPos, tData.nFlag)
end

function Network.CltPBProc.PetAddPointReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:AddPointReq(tData.nID, tData.nPos, tData.tList)
end

function Network.CltPBProc.PetWashPointReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:WashPointReq(tData.nID, tData.nPos, tData.nProId, tData.nType)
end

function Network.CltPBProc.PetSillLearnReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:SillLearnReq(tData.nID, tData.nPos, tData.nProId, tData.nType)
end


function Network.CltPBProc.PetSkillRememberReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:SkillRememberReq(tData.nID, tData.nPos, tData.nProId, tData.nType)
end



function Network.CltPBProc.PetCancelSkillRememberReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:CancelSkillRememberReq(tData.nID, tData.nPos, tData.nSkillID)
end

function Network.CltPBProc.PetLianGuReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:LianGuReq(tData.nID, tData.nPos, tData.nProId, tData.nType, tData.nNum)
end


function Network.CltPBProc.PetAddExpReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:AddExpReq(tData.nPos, tData.nProIdType)
end

function Network.CltPBProc.PetAddLifeReq(nCmd, nServer, nService, nSession, tData)
	print("++++++++++++++++*************************************")
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:AddLifeReq(tData.nID, tData.nPos, tData.tItem)
end

function Network.CltPBProc.PetAddGUReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:AddGUReq(tData.nID, tData.nPos)
end


function Network.CltPBProc.PetCarryEpReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:CarryEpReq()
end



function Network.CltPBProc.PetXiSuiReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:XiSuiReq( tData.nID, tData.nPos, tData.nType)
end

function Network.CltPBProc.PetWearEquitReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:WearEquitReq(tData.nPos, tData.nGrid)
end

function Network.CltPBProc.PetAdvancedReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:AdvancedReq(tData.nPos, tData.nType)
end

function Network.CltPBProc.PetXiSuiSavaReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:PetXiSuiSavaReq(tData.nType)
end

function Network.CltPBProc.PetXiSuiPetReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:PetXiSuiPetReq()
end

function Network.CltPBProc.PetSkipTipsReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:PetSkipTipsReq(tData.bFlag)
end

function Network.CltPBProc.PetBuyReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:PetBuyReq(tData.nID)
end

function Network.CltPBProc.PetTalismanPBReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:PetTalismanPBReq(tData.nGrid1, tData.nGrid2)
end

function Network.CltPBProc.PetAutoAddPointReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:PetAutoAddPointReq(tData.nState, tData.nPos, tData.tList)
end

function Network.CltPBProc.PetPlanInfoReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:PetPlanInfoReq(tData.nPos, tData.nPlan)
end

function Network.CltPBProc.PetPropUSEReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:PetPropUSEReq(tData.nPropID)
end

function Network.CltPBProc.PetSavaRecruitReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:PetSavaRecruitReq(tData.nRecruitLevel)
end

function Network.CltPBProc.PetYuShouInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oPet:SyncYuShouData()
end

function Network.CltPBProc.PetYuShouLevelUpReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oPet:YuShouLevelUpReq()
end

function Network.CltPBProc.PetReviveLevelUpReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oPet:ReviveLevelUpReq(tData.nPetPos, tData.nPropID, tData.nPropNum)
end

------------服务器内部
--宠物快速学习技能
function Network.RpcSrv2Srv.PetFastLearnSkillReq(nSrcServer, nSrcService, nTarSession, nRoleID, nPropID, nPetPos, nPrice)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	return oRole.m_oPet:FastLearnSkillReq(nPropID, nPetPos, nPrice)
end

function Network.RpcSrv2Srv.PetSomeMethodSkillReq(nSrcServer, nSrcService, nTarSession, nRoleID, nPropID)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	return oRole.m_oPet:SomeMethod(nPropID)
end

function Network.RpcSrv2Srv.GMGetPetInfoReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return {} end
	return oRole.m_oPet:GMGetAllPetInfo()
end

function Network.RpcSrv2Srv.GMDeletePetReq(nSrcServer, nSrcService, nTarSession, nRoleID, nPos)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return false end
	return oRole.m_oPet:GMDeletePet(nPos)
end


