--客户端->服务器
function CltPBProc.ZhenYaoCreateMonsterReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    if oBattleDup and oBattleDup.CreateMonsterReq then
        oBattleDup:CreateMonsterReq(oRole)
    end
end

function CltPBProc.CreateMonsterReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    if oBattleDup and oBattleDup.CreateMonsterReq then
        oBattleDup:CreateMonsterReq(oRole)
    end
end

function CltPBProc.AttackMonsterReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    if oBattleDup and oBattleDup.TouchMonsterReq then
        oBattleDup:TouchMonsterReq(oRole, tData.nMonObjID)
    end
end

function CltPBProc.DupBuffOperaReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    if not oBattleDup or not oBattleDup.ExpBuffOpera then return end
    oBattleDup:ExpBuffOpera(oRole, tData.nOperaType)
    --print("CltPBProc.DupBuffOperaReq***", oRole:GetID(), oRole:GetName())
end

function CltPBProc.ZhenYaoMatchTeamReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    if not oBattleDup or not oBattleDup.MatchTeamReq then return end
    oBattleDup:MatchTeamReq(oRole)
end


