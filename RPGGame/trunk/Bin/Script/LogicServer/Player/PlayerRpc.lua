

---------------服务器内部----------------
--角色上线通知(登录服务)
function Srv2Srv.RoleOnlineReq(nSrcServer, nSrcService, nTarSession, nAccountID, nRoleID)
	return goPlayerMgr:RoleOnlineReq(nSrcServer, nTarSession, nAccountID, nRoleID)
end

--角色下线通知(登录服务)
function Srv2Srv.RoleOfflineReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	return goPlayerMgr:RoleOfflineReq(nRoleID)
end

--角色断线通知(登录服务)
function Srv2Srv.RoleDisconnectReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    return goPlayerMgr:RoleDisconnectReq(nRoleID)
end


--道具数量请求([W]GLOBAL服务)
function Srv2Srv.RoleItemCountReq(nSrcServer, nSrcService, nTarSession, nAccountID, nType, nID)
    local oRole = goPlayerMgr:GetRoleByAccountID(nAccountID)
    if not oRole then return end
    return oRole:ItemCount(nType, nID)
end

--道具数量增减([W]GLOBAL服务)
function Srv2Srv.RoleAddItemReq(nSrcServer, nSrcService, nTarSession, nAccountID, tItemList, sReason)
    local oRole = goPlayerMgr:GetRoleByAccountID(nAccountID)
    if not oRole then return end
    for _, tItem in ipairs(tItemList) do
        oRole:AddItem(tItem.nType, tItem.nID, tItem.nNum, sReason)
    end
    return true
end

--切换逻辑服请求([W]LOGIC服务)
--@nSrcServer: 源服务器ID(可能是世界服)
function Srv2Srv.SwitchLogicReq(nSrcServer, nSrcService, nTarSession, nAccountServer, nAccountID, nRoleID, nSrcDupID, nTarDupID, nPosX, nPosY, nLine)
    print("切换逻辑服:", nSrcDupID.."->"..nTarDupID, nPosX, nPosY, nLine)
    goPlayerMgr:OnlineReq(nAccountServer, nTarSession, nAccountID, nRoleID, true)
    local oRole = goPlayerMgr:GetRoleByAccountID(nAccountID)
    goDupMgr:EnterDupCreate(nTarDupID, oRole:GetNativeObj(), nPosX, nPosY, nLine)
end
