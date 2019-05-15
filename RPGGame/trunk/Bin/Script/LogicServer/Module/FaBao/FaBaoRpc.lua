
function CltPBProc.FaBaoAttrPageReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFaBao:FaBaoAttrPageReq()
end

function CltPBProc.FaBaoWearReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFaBao:FaBaoWearReq(tData.nGrid, tData.nType)
end

function CltPBProc.FaBaoTakeOffReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFaBao:FaBaoTakeOffReq(tData.nGrid)
end

function CltPBProc.FaBaoFeastReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFaBao:FaBaoFeastReq(tData.nGrid)
end

function CltPBProc.FaBaoCompositeReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFaBao:FaBaoCompositeReq(tData.tCompositeList, tData.bFlag)

end

function CltPBProc.FaBaoResetReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFaBao:FaBaoResetReq(tData.tResetList)
end

function CltPBProc.FaBaoFalgReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFaBao:FaBaoFalgReq(tData.bFlag, nGrid)
end

function CltPBProc.FaBaoOnekeyUpgradeReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFaBao:OnekeyUpgradeReq()
end

function Srv2Srv.FaBaoKnapsackRemainCapacityReq(nSrcServer,nSrcService,nTarSession, nRoleID, nPropID)
	 local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then
        return LuaTrace("FaBaoKnapsackRemainCapacityReq角色不存在", nRoleID)
    end
    return oRole.m_oFaBao:GetOverNum(nPropID)
end

function Srv2Srv.RoleSubFaBaoByGridReq(nSrcServer,nSrcService,nTarSession, nRoleID, tItemList, sReason)
	 local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then
        return LuaTrace("RoleSubFaBaoByGridReq角色不存在", nRoleID)
    end
    for _, tItem in ipairs(tItemList) do
    	local bRet = oRole.m_oFaBao:SubGridItem(tItem.nGrid, sReason,false)
    	if bRet then
	    	return true
	    end
    end
end

function Srv2Srv.FaBaoItemDataReq(nSrcServer,nSrcService,nTarSession, nRoleID, nGrid)
	 local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then
        return LuaTrace("FaBaoKnapsackRemainCapacityReq角色不存在", nRoleID)
    end
    return oRole.m_oFaBao:GetFaBao(nGrid)
end



function Srv2Srv.FaBaoItemListDataReq(nSrcServer,nSrcService,nTarSession, nRoleID, nPropID)
	 local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then
        return LuaTrace("FaBaoKnapsackRemainCapacityReq角色不存在", nRoleID)
    end
    return oRole.m_oFaBao:GetFaBaoListData(nPropID)
end


function Srv2Srv.FaBaoSubItem(nSrcServer,nSrcService,nTarSession, nRoleID, tItemList, sReason)
	 local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then
        return LuaTrace("FaBaoKnapsackRemainCapacityReq角色不存在", nRoleID)
    end
    return oRole.m_oFaBao:CheckSubFaBao(tItemList, sReason)
end