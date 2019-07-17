------客户端服务器
function Network.CltPBProc.FriendListReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goFriendMgr:FriendListReq(oRole)
end

function Network.CltPBProc.AddFriendReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goFriendMgr:AddFriendReq(oRole, tData.nTarRoleID)
end

function Network.CltPBProc.DelFriendReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    if tData.bStranger then
        goFriendMgr:DelStranger(oRole:GetID(), tData.nTarRoleID)
    else
        goFriendMgr:DelFriendReq(oRole, tData.nTarRoleID)
    end
end

function Network.CltPBProc.SearchFriendReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goFriendMgr:SearchFriendReq(oRole, tData.sSearchKey)
end

function Network.CltPBProc.FriendSendPropReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goFriendMgr:SendPropReq(oRole, tData.nTarRoleID, tData.nGridID, tData.nNum)
end

function Network.CltPBProc.FriendTalkReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goFriendMgr:TalkReq(oRole, tData.nTarRoleID, tData.sCont, tData.bXMLMsg and true or false)
end

function Network.CltPBProc.FriendApplyReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goFriendMgr:FriendApplyReq(oRole, tData.nTarRoleID, tData.sMessage)
end

function Network.CltPBProc.FriendApplyListReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goFriendMgr:FriendApplyListReq(oRole)
end

function Network.CltPBProc.DenyFriendApplyReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goFriendMgr:DenyFriendApplyReq(oRole, tData.nTarRoleID)
end

function Network.CltPBProc.FriendHistoryTalkReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goFriendMgr:FriendHistoryTalkReq(oRole, tData.nTarRoleID)
end

--服务器内部
function Network.RpcSrv2Srv.IsFriend(nSrcServer,nSrcService,nTarSession,nRoleID,nTarRoleID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    local oFriend = goFriendMgr:IsFriend(nRoleID,nTarRoleID)
    if oFriend then
        return true
    end
    return false
end

function Network.RpcSrv2Srv.GetFriendList(nSrcServer,nSrcService,nTarSession,nRoleID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    local tFriendRoleID = goFriendMgr:GetFriendList(nRoleID)
    return tFriendRoleID
end
