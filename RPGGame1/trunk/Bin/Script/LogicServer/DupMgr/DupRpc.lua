--客户端-服务器
function Network.CltPBProc.RoleEnterSceneReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = GetGModule("RoleMgr"):GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    oRole:EnterScene(tData)
end

------服务器内部
function Network.RpcSrv2Srv.RoleObserverListReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    local oRole = GetGModule("RoleMgr"):GetRoleByID(nRoleID)
    if not oRole then return end
    return GetGModule("DupMgr"):RoleObserverListReq(oRole)
end

function Network.RpcSrv2Srv.CreateDupReq(nSrcServer, nSrcService, nTarSession, nDupID, tParams)
    local oDup = GetGModule("DupMgr"):CreateDupReq(nDupConfID, tParams)
    local tDupSceneInfo = oDup:GetDupSceneInfo()
    return tDupSceneInfo
end

function Network.RpcSrv2Srv.BeforeEnterSceneCheckReq(nSrcServer, nSrcService, nTarSession, tGameObjParams, tDupInfo)
    return GetGModule("DupMgr"):BeforeEnterSceneCheckReq(tGameObjParams, tDupInfo)
end


