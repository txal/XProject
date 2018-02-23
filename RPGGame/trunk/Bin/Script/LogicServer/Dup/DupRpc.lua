function CltPBProc.RoleEnterSceneReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    local tBorn = ctDupConf[tData.nDupID].tBorn[1]
    goDupMgr:EnterDupCreate(tData.nDupID, oRole:GetNativeObj(), tBorn[1], tBorn[2], -1)
end

function CltPBProc.RoleLeaveSceneReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goDupMgr:LeaveDup(tData.nMixID)
end
