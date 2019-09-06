--客户端服务器
function Network.CltPBProc.CreateTeamReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goTeamMgr:CreateTeamReq(oRole)
end

function Network.CltPBProc.TeamReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
    if oTeam then
    	oTeam:SyncTeam(oRole)
    else
    	CTeam:SyncTeamEmpty(oRole:GetID())
    end
end
function Network.CltPBProc.TeamQuitReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
    if oTeam then
    	oTeam:QuitReq(oRole)
    end
end
function Network.CltPBProc.TeamReturnReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
    if oTeam then
    	oTeam:ReturnTeamReq(oRole)
    end
end
function Network.CltPBProc.TeamLeaveReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
    if oTeam then
    	oTeam:LeaveTeamReq(oRole)
    end
end
function Network.CltPBProc.TeamFriendReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
    if oTeam then
    	oTeam:FriendListReq(oRole)
    else
        oRole:Tips("请先创建队伍")
    end
end
function Network.CltPBProc.TeamUnionMemberReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
    if oTeam then
    	oTeam:UnionMemberListReq(oRole)
    else
        oRole:Tips("请先创建队伍")
    end
end
function Network.CltPBProc.TeamInviteReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
    if oTeam then
    	oTeam:InviteReq(oRole, tData.nRoleID)
    end
end
function Network.CltPBProc.TeamApplyJoinReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oTeam = goTeamMgr:GetTeamByID(tData.nTeamID)
    if oTeam then
    	oTeam:JoinApplyReq(oRole)
    else
        oRole:Tips("队伍已经解散或不存在")
    end
end
function Network.CltPBProc.TeamApplyListReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
    if oTeam then
    	oTeam:ApplyListReq(oRole)
    end
end
function Network.CltPBProc.TeamAgreeJoinReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
    if oTeam then
    	oTeam:AgreeJoinReq(oRole, tData.nRoleID)
    end
end
function Network.CltPBProc.TeamExchangePosReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
    if oTeam then
    	oTeam:ExchangeReq(oRole, tData.nIndex1, tData.nIndex2)
    end
end
function Network.CltPBProc.TeamCallReturnReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
    if oTeam then
    	oTeam:CallReturnReq(oRole)
    end
end
function Network.CltPBProc.TeamKickMemberReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
    if oTeam then
    	oTeam:KickReq(oRole, tData.nRoleID)
    end
end
function Network.CltPBProc.TeamTransferLeaderReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
    if oTeam then
    	oTeam:TransferLeaderReq(oRole, tData.nRoleID)
    end
end
function Network.CltPBProc.TeamApplyLeaderReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
    if oTeam then
    	oTeam:ApplyLeaderReq(oRole)
    end
end
function Network.CltPBProc.TeamClearApplyListReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
    if oTeam then
        oTeam:TeamClearApplyListReq(oRole)
    end
end
function Network.CltPBProc.TeamMatchReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oTeamMatch = goTeamMgr:GetMatchMgr()
    if not oTeamMatch then 
        return 
    end
    -- if not oTeamMatch:CheckCanMatchByClient(tData.nGameType) then 
    --     oRole:Tips("不合法的匹配类型")
    --     return
    -- end
    -- local sGameName = oTeamMatch:GetGameNameByType(tData.nGameType)
    -- goTeamMgr:MatchTeamReq(oRole:GetID(), tData.nGameType, sGameName)
    oTeamMatch:ClientJoinMatchReq(oRole:GetID(), tData.nGameType)
end

function Network.CltPBProc.TeamMatchInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goTeamMgr:SyncTeamMatchInfo(oRole:GetID())
end

function Network.CltPBProc.CancelTeamMatchReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goTeamMgr:CancelTeamMatchReq(oRole:GetID())
end


------服务器内部
--GATEWAY
function Network.SrvCmdProc.ClientLastPacketTimeRet(nCmd, nSrcServer, nSrcService, nTarSession, nRoleID, nLastPacketTime)
	goTeamMgr:LeaderActivityCheck(nRoleID, nLastPacketTime)
end

--发起队长发呆投票[W]LOGIC
function Network.SrvCmdProc.LuanchLeaderActivityVoteReq(nCmd, nSrcServer, nSrcService, nTarSession, nTeamID)
    local oTeam = goTeamMgr:GetTeamByID(nTeamID)
    if oTeam then
        oTeam:LaunchLeaderActivityVote()
    end
end

--[W]LOGIC
function Network.RpcSrv2Srv.TeamQueryInfoReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    return goTeamMgr:TeamQueryInfoReq(nRoleID)
end

--[W]LOGIC
function Network.RpcSrv2Srv.TeamBattleInfoReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    return goTeamMgr:TeamBattleInfoReq(nRoleID)
end

--[W]LOGIC
function Network.RpcSrv2Srv.WCreateTeamReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    goTeamMgr:CreateTeamReq(oRole)
    local nTeamID, tTeam = goTeamMgr:TeamBattleInfoReq(nRoleID)
    return nTeamID, Team
end

--[W]LOGIC
function Network.RpcSrv2Srv.WQuitTeamReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then 
        return
    end
    local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
    if not oTeam then
        return true
    end
    return oTeam:QuitReq(oRole, false)
end

--[W]LOGIC
function Network.RpcSrv2Srv.WUpdateTeamDataReq(nSrcServer, nSrcService, nTarSession, nRoleID, bAll)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then 
        return
    end
    goTeamMgr:SyncTeamCache(nRoleID, bAll)
end

--[W]LOGIC
function Network.RpcSrv2Srv.TeamListBattleInfoReq(nSrcServer, nSrcService, nTarSession, tRoleIDList) --tRoleIDList有序列表
    local tRetData = {}
    for k, nRoleID in ipairs(tRoleIDList) do
        local tTeamData = {}
        tTeamData[1] = nRoleID
        tTeamData[2], tTeamData[3] = goTeamMgr:TeamBattleInfoReq(nRoleID)
        table.insert(tRetData, tTeamData)
    end
    return tRetData
end

--[W]LOGIC
function Network.RpcSrv2Srv.KickFromTeamReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
    if oTeam then
        oTeam:QuitReq(oRole, false)
    end
    return true
end

--[W]LOGIC
function Network.RpcSrv2Srv.LeaveTeamAndKickReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
    if oTeam then
        oTeam:QuitReq(oRole, true)
    end
    return true
end

--[W]LOGIC
function Network.RpcSrv2Srv.WMatchTeamReq(nSrcServer, nSrcService, nTarSession, nRoleID, nGameType, sGameName, bSys)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    goTeamMgr:MatchTeamReq(nRoleID, nGameType, sGameName, bSys)
end

--[W]LOGIC
function Network.RpcSrv2Srv.WCancelMatchTeamReq(nSrcServer, nSrcService, nTarSession, nRoleID, nGameType, sGameName)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    goTeamMgr:CancelTeamMatchReq(oRole:GetID())
end

--[W]LOGIC
function Network.RpcSrv2Srv.BecomeTeamLeaderReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID) 
    local oTeam = goTeamMgr:GetTeamByRoleID(nRoleID)    
    nOldLeaderID = oTeam.m_tRoleList[1].nRoleID    
    local oOldLeader = goGPlayerMgr:GetRoleByID(nOldLeaderID)    
    if not oOldLeader then return end
    if oTeam then
        local nNewLeaderID = 0
        if oRole:GetID() == nOldLeaderID then
            nNewLeaderID = oTeam.m_tRoleList[2].nRoleID        
        else
            nNewLeaderID = oRole:GetID()
        end
    	oTeam:TransferLeaderReq(oOldLeader, nNewLeaderID)
    end
end

function Network.RpcSrv2Srv.GotoLeader(nSrcServer, nSrcService, nTarSession, nRoleID, tData)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID) 
    if not oRole then return end
    local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
    if oTeam then
        local tLeader = oTeam:GetLeader()
        local oLeader = goGPlayerMgr:GetRoleByID(tLeader.nRoleID)
        local function CallBack(nDupMixID, nLine, nPosX, nPosY, nBattleDupType)
            if tData.nBattleDupType == nBattleDupType then
    	        oTeam:ReturnTeamReq(oRole)
            else
                return oRole:Tips("请求进入的副本跟队长所在副本不一致")
            end
        end
        Network:RMCall("GetRoleCurrDupInfoReq", CallBack, oLeader:GetStayServer(), oLeader:GetLogic(), oLeader:GetSession(), oLeader:GetID())
    end
end

function Network.RpcSrv2Srv.CancelTeamMatch(nSrcServer, nSrcService, nTarSession, nRoleID, nGameType)
    goTeamMgr:CancelSpecifyTeamMatchReq(nRoleID, nGameType)
end

function Network.RpcSrv2Srv.RobotJoinTeamMatchReq(nSrcServer, nSrcService, nTarSession, nRoleID, nGameType)
    goTeamMgr:GetMatchMgr():RobotJoinTeamMatch(nRoleID, nGameType)
end

function Network.RpcSrv2Srv.RobotCancelTeamMatchReq(nSrcServer, nSrcService, nTarSession, nRoleID, nGameType)
    goTeamMgr:GetMatchMgr():RobotCancelTeamMatch(nRoleID, nGameType)
end

--返回值true有可合并队伍, false没有可合并的队伍
function Network.RpcSrv2Srv.CheckJoinMergeTeamReq(nSrcServer, nSrcService, nTarSession, nTeamID, nGameType)
    return goTeamMgr:GetMatchMgr():CheckJoinMergeTeam(nTeamID, nGameType)
end

--返回值true合并成功, false合并失败
function Network.RpcSrv2Srv.JoinMergeTeamReq(nSrcServer, nSrcService, nTarSession, nTeamID, nGameType)
    return goTeamMgr:GetMatchMgr():JoinMergeTeam(nTeamID, nGameType)
end
