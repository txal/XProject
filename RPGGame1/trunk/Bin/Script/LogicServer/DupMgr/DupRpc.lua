--客户端-服务器
function Network.CltPBProc.RoleEnterSceneReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = GetGModule("RoleMgr"):GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    local tSceneInfo = {nDupID=tData.nDupID, nSceneID=tData.nSceneID}
    oRole:EnterScene(tSceneInfo)
end

------服务器内部
--远程创建副本
function Network.RpcSrv2Srv.CreateDupReq(nSrcServer, nSrcService, nTarSession, nDupID, tParams)
    local oDupMgr = GetGModule("DupMgr")
    local tDupSceneInfo
    oDupMgr:CreateDup(nDupConfID, tParams, function(tResult)
        tDupSceneInfo = tResult
    end)
    return tDupSceneInfo
end

--远程移除副本
function Network.RpcSrv2Srv.RemoteDupReq(nSrcServer, nSrcService, nTarSession, nDupID)
    GetGModule("DupMgr"):RemoteDup(nDupID)
end

--进入副本前检测
function Network.RpcSrv2Srv.BeforeEnterSceneCheckReq(nSrcServer, nSrcService, nTarSession, tSceneInfo, tGameObjParams)
    local bCanEnter, sError
    GetGModule("DupMgr"):BeforeEnterSceneCheck(tSceneInfo, tGameObjParams, function(bRet, sErr)
        bCanEnter, sError = bRet, sErr
    end)
    return bCanEnter, sError
end

--根据副本ID查询副本信息
function Network.RpcSrv2Srv.QueryDupSceneByDupIDReq(nSrcServer, nSrcService, nTarSession, nDupID)
    local tDupSceneInfo
    GetGModule("DupMgr"):QueryDupSceneByDupID(nDupID, function(tResult)
        tDupSceneInfo = tResult
    end)
    return tDupSceneInfo
end

--根据配置ID查询城镇是否存在
function Network.RpcSrv2Srv.QueryCityByDupConfIDReq(nSrcServer, nSrcService, nTarSession, nDupConfID)
    return GetGModule("DupMgr"):QueryCityByDupConfID(nDupConfID)
end

--取角色观察者列表
function Network.RpcSrv2Srv.RoleObserverListReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    local oRole = GetGModule("RoleMgr"):GetRoleByID(nRoleID)
    if not oRole then return end
    return GetGModule("DupMgr"):GetRoleObserverList(oRole)
end


