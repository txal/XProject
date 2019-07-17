--客户端->服务器
function Network.CltPBProc.AttackMonsterReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    oBattleDup:TouchMonsterReq(oRole, tData.nMonObjID)
end

function Network.CltPBProc.EnterReadyDupReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goPVEActivityMgr:EnterReadyDupReq(oRole)
end

function Network.CltPBProc.PVEOnObjLeaveReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goPVEActivityMgr:OnObjLeave(oRole)
end

function Network.CltPBProc.PVEMatchTeamReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goPVEActivityMgr:MatchTeamReq(oRole,tData.nType)
end

function Network.CltPBProc.PVEEnterBattleDupReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goPVEActivityMgr:EnterBattleDupReq(oRole)
end

-- function Network.CltPBProc.PVESwitchMapReq(nCmd, nServer, nService, nSession, tData)
--     local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
--     if not oRole then return end
--      oBattleDup::SwitchMapReq(oRole)
-- end
--服务器内部调用
--------------------Svr2Svr------------------------
function Network.RpcSrv2Srv.PVEActivityEnterCheckReq(nSrcServer, nSrcService, nTarSession, nRoleLevel)
	return goPVEActivityMgr:EnterCheckReq(nRoleLevel)
end


function Network.RpcSrv2Srv.PVEGetSettlementActDataReq(nSrcServer, nSrcService, nTarSession, nRoleID, nTeamID, tActData)
    return goPVEActivityMgr:GetSettlementActData(nTeamID, tActData)
end

function Network.RpcSrv2Srv.PVESetSettlementActDataReq(nSrcServer, nSrcService, nTarSession, nRoleID,nTeamID, tActData)
    return goPVEActivityMgr:SettlementActData(nTeamID, tActData)
end

function Network.RpcSrv2Srv.PVEDataChangeReq(nSrcServer, nSrcService, nTarSession, nRoleID, nTeamID, tActData)
    return goPVEActivityMgr:PVEDataChange(nTeamID, tActData)
end

function Network.RpcSrv2Srv.PVEDataCheckReq(nSrcServer, nSrcService, nTarSession, nRoleID, nTeamID, tActData)
        goPVEActivityMgr:PVEDataCheckReq(nTeamID, tActData)
end

function Network.RpcSrv2Srv.PVEActivityCheckStatusReq(nSrcServer, nSrcService, nTarSession, nRoleID)
       return goPVEActivityMgr:PVEActivityCheckStatusReq()
end

function Network.RpcSrv2Srv.PVEActivityISGMOpenActReq(nSrcServer, nSrcService, nTarSession, nRoleID)
       return goPVEActivityMgr:GetISGMOpenAct()
end

function Network.RpcSrv2Srv.PVEOpenActReq(nSrcServer, nSrcService, nTarSession, nRoleID, nActivityID,nReadyTime, nEndTime)
    return goPVEActivityMgr:OpenAct(nActivityID, nReadyTime, nEndTime)
end

function Network.RpcSrv2Srv.PVECloseActReq(nSrcServer, nSrcService, nTarSession,nActivityID)
    return goPVEActivityMgr:CloseAct(nActivityID)
end

function Network.RpcSrv2Srv.PVEReturnTeamCheckReq(nSrcServer, nSrcService, nTarSession,nRoleLevel)
    return goPVEActivityMgr:ReturnTeamCheck(nRoleLevel)
end