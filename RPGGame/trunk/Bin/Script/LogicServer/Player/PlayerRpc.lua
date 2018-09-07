

---------------服务器内部----------------
--角色上线通知(LOGIN)
function Srv2Srv.RoleOnlineReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	return goPlayerMgr:RoleOnlineReq(nSrcServer, nTarSession, nRoleID)
end

--角色下线通知(LOGIN)
function Srv2Srv.RoleOfflineReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	return goPlayerMgr:RoleOfflineReq(nRoleID)
end

--角色断线通知(LOGIN)
function Srv2Srv.RoleDisconnectReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    return goPlayerMgr:RoleDisconnectReq(nRoleID)
end

--物品数量请求([W]GLOBAL)
function Srv2Srv.RoleItemCountReq(nSrcServer, nSrcService, nTarSession, nRoleID, nType, nID)
    local oRole = goPlayerMgr:GetRoleID(nAccountID)
    if not oRole then return end
    return oRole:ItemCount(nType, nID)
end

--物品数量增加([W]GLOBAL)
function Srv2Srv.RoleAddItemReq(nSrcServer, nSrcService, nTarSession, nRoleID, tItemList, sReason)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    for _, tItem in ipairs(tItemList) do
        oRole:AddItem(tItem.nType, tItem.nID, tItem.nNum, sReason)
    end
    return true
end

--物品数量扣除([W]GLOBAL)
function Srv2Srv.RoleSubItemReq(nSrcServer, nSrcService, nTarSession, nRoleID, tItemList, sReason)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    for _, tItem in ipairs(tItemList) do
        local nNum = oRole:ItemCount(tItem.nType, tItem.nID)
        if nNum < tItem.nNum then
            return
        end
    end
    for _, tItem in ipairs(tItemList) do
        oRole:SubItem(tItem.nType, tItem.nID, tItem.nNum, sReason)
    end
    return true
end

--切换逻辑服请求([W]LOGIC)
--@nSrcServer: 来源服务器ID(可能是世界服过来,所以要带上角色自己服务器ID)
--@nTarSession: 目标角色会话ID
function Srv2Srv.SwitchLogicReq(nSrcServer, nSrcService, nTarSession, ...)
    goPlayerMgr:OnSwitchLogicReq(nTarSession, ...)
end
