------客户端服务器------

--进入PVP活动场景请求
function CltPBProc.PVPActivityEnterReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goPVPActivityMgr:EnterReq(oRole, tData.nActivityID)
end

--PVP活动信息请求
function CltPBProc.PVPActivityInfoReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    if GF.GetServiceID() ~= goPVPActivityMgr:GetActivityServiceID(tData.nActivityID) then
        return
    end
    goPVPActivityMgr:SyncPVPActivityInfo(oRole, tData.nActivityID)
end

--PVP活动角色信息请求
function CltPBProc.PVPActivityRoleDataReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    if GF.GetServiceID() ~= goPVPActivityMgr:GetActivityServiceID(tData.nActivityID) then
        return
    end
    goPVPActivityMgr:SyncRoleData(oRole, tData.nActivityID)
end

--PVP活动排行榜数据请求
function CltPBProc.PVPActivityRankDataReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    if GF.GetServiceID() ~= goPVPActivityMgr:GetActivityServiceID(tData.nActivityID) then
        return
    end
    goPVPActivityMgr:SyncRankData(oRole, tData.nActivityID, tData.nPageNum)
end


--发起战斗请求
function CltPBProc.PVPActivityBattleReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    if GF.GetServiceID() ~= goPVPActivityMgr:GetActivityServiceID(tData.nActivityID) then
        return
    end
    goPVPActivityMgr:BattleReq(oRole, tData.nActivityID, tData.nEnemyID)
end

--离开PVP活动场景请求
function CltPBProc.PVPActivityLeaveReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goPVPActivityMgr:LeaveReq(oRole)
end

--快速匹配队伍请求
function CltPBProc.PVPActivityMatchTeamReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    if GF.GetServiceID() ~= goPVPActivityMgr:GetActivityServiceID(tData.nActivityID) then
        return
    end
    goPVPActivityMgr:MatchTeamReq(oRole, tData.nActivityID)
end

--取消匹配队伍请求
function CltPBProc.PVPActivityCancelMatchTeamReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    if GF.GetServiceID() ~= goPVPActivityMgr:GetActivityServiceID(tData.nActivityID) then
        return
    end
    goPVPActivityMgr:CancelMatchTeamReq(oRole, tData.nActivityID)
end


--------------------Svr2Svr------------------------
function Srv2Srv.PVPActivityEnterCheckReq(nSrcServer, nSrcService, nTarSession, nActivityID, nRoleID, ...)
	return goPVPActivityMgr:EnterCheckReq(nActivityID, nRoleID, ...)
end

function Srv2Srv.PVPActivityGMRestart(nSrcServer, nSrcService, nTarSession, nActivityID, nPrepareLastTime, nLastTime)
    return goPVPActivityMgr:GMRestart(nActivityID, nPrepareLastTime, nLastTime)
end

function Srv2Srv.PVPActivityCheckStatusReq(nSrcServer, nSrcService, nTarSession, nActivityID)
    return goPVPActivityMgr:CheckStatus(nActivityID), nActivityID
end
