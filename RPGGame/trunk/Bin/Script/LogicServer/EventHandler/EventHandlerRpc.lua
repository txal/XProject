--服务器内部
function Srv2Srv.OnBecomeFriend(nSrcServer,nSrcService,nTarSession,nRoleID, tData)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    CEventHandler:OnBecomeFriend(oRole,{nFriendNum=tData.nFriendNum})
end

function Srv2Srv.OnCongratulate(nSrcServer,nSrcService,nTarSession,nRoleID, tData)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    CEventHandler:OnCongratulate(oRole)
end

function Srv2Srv.OnUnionSignIn(nSrcServer,nSrcService,nTarSession,nRoleID, tData)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    CEventHandler:OnUnionSignIn(oRole)
end

function Srv2Srv.OnArenaWin(nSrcServer,nSrcService,nTarSession,nRoleID, tData)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    CEventHandler:OnArenaWin(oRole, tData)
end

function Srv2Srv.OnAddFriend(nSrcServer,nSrcService,nTarSession,nRoleID, tData)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    CEventHandler:OnAddFriend(oRole,tData)
end

function Srv2Srv.OnInviteMarry(nSrcServer,nSrcService,nTarSession,nRoleID, tData)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    CEventHandler:OnMarryInvite(oRole,tData)
end
function Srv2Srv.OnMarketItemOnSale(nSrcServer,nSrcService,nTarSession,nRoleID, tData)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    CEventHandler:OnMarketItemOnSale(oRole,tData)
end

function Srv2Srv.OnChamberCoreItemOnSale(nSrcServer,nSrcService,nTarSession,nRoleID, tData)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    CEventHandler:OnChamberCoreItemOnSale(oRole,tData)
end

function Srv2Srv.OnJoinUnion(nSrcServer,nSrcService,nTarSession,nRoleID, tData)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    CEventHandler:OnJoinUnion(oRole, {})
end
