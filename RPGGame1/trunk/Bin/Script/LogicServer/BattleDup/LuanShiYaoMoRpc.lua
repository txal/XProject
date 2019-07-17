--客户端->服务器
function Network.CltPBProc.AttackMonsterReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    oBattleDup:TouchMonsterReq(oRole, tData.nMonObjID)
end