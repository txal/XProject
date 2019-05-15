--客户端->服务器
function CltPBProc.AttackMonsterReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    oBattleDup:TouchMonsterReq(oRole, tData.nMonObjID)
end

function CltPBProc.EnterReadyDupReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goPVEActivityMgr:EnterReadyDupReq(oRole)
end

function CltPBProc.PVEOnObjLeaveReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goPVEActivityMgr:OnObjLeave(oRole)
end

function CltPBProc.PVEMatchTeamReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goPVEActivityMgr:MatchTeamReq(oRole,tData.nType)
end

function CltPBProc.PVEEnterBattleDupReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goPVEActivityMgr:EnterBattleDupReq(oRole)
end

-- function CltPBProc.PVESwitchMapReq(nCmd, nServer, nService, nSession, tData)
--     local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
--     if not oRole then return end
--      oBattleDup::SwitchMapReq(oRole)
-- end
--服务器内部调用
--------------------Svr2Svr------------------------
function Srv2Srv.PVEActivityEnterCheckReq(nSrcServer, nSrcService, nTarSession, nRoleLevel)
	return goPVEActivityMgr:EnterCheckReq(nRoleLevel)
end


function Srv2Srv.PVEGetSettlementActDataReq(nSrcServer, nSrcService, nTarSession, nRoleID, nTeamID, tActData)
    return goPVEActivityMgr:GetSettlementActData(nTeamID, tActData)
end

function Srv2Srv.PVESetSettlementActDataReq(nSrcServer, nSrcService, nTarSession, nRoleID,nTeamID, tActData)
    return goPVEActivityMgr:SettlementActData(nTeamID, tActData)
end

function Srv2Srv.PVEDataChangeReq(nSrcServer, nSrcService, nTarSession, nRoleID, nTeamID, tActData)
    return goPVEActivityMgr:PVEDataChange(nTeamID, tActData)
end

function Srv2Srv.PVEDataCheckReq(nSrcServer, nSrcService, nTarSession, nRoleID, nTeamID, tActData)
        goPVEActivityMgr:PVEDataCheckReq(nTeamID, tActData)
end

function Srv2Srv.PVEActivityCheckStatusReq(nSrcServer, nSrcService, nTarSession, nRoleID)
       return goPVEActivityMgr:PVEActivityCheckStatusReq()
end

function Srv2Srv.PVEActivityISGMOpenActReq(nSrcServer, nSrcService, nTarSession, nRoleID)
       return goPVEActivityMgr:GetISGMOpenAct()
end

function Srv2Srv.PVEOpenActReq(nSrcServer, nSrcService, nTarSession, nRoleID, nActivityID,nReadyTime, nEndTime)
    return goPVEActivityMgr:OpenAct(nActivityID, nReadyTime, nEndTime)
end

function Srv2Srv.PVECloseActReq(nSrcServer, nSrcService, nTarSession,nActivityID)
    return goPVEActivityMgr:CloseAct(nActivityID)
end

function Srv2Srv.PVEReturnTeamCheckReq(nSrcServer, nSrcService, nTarSession,nRoleLevel)
    return goPVEActivityMgr:ReturnTeamCheck(nRoleLevel)
end