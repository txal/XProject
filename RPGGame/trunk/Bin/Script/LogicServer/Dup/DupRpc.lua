function CltPBProc.RoleEnterSceneReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end

    local oTarRole = goPlayerMgr:GetRoleByID(tData.nRoleID)
    if not oTarRole then
    	return oRole:Tips("目标角色不存在")
    end

    local nDupID = GF.GetDupID(tData.nDupMixID)
    local tBorn = ctDupConf[nDupID].tBorn[1]
    goDupMgr:EnterDup(tData.nDupMixID, oTarRole:GetNativeObj(), tBorn[1], tBorn[2], -1)
end

function CltPBProc.RoleLeaveSceneReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goDupMgr:LeaveDup(tData.nDupMixID)
end
