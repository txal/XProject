function Network.CltPBProc.DailyActivityReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    oRole.m_oDailyActivity:Operation(tData)
end


function Network.RpcSrv2Srv.CheckJoinDailyActReq(nSrcServer, nSrcService, nTarSession, nRoleID, nActID)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    --只需要关注类型1，及日常活动，非限时活动类型，即可
    local bIsCanJoin = oRole.m_oDailyActivity:CheckCanJoinAct(nActID)
    assert(bIsCanJoin == true or bIsCanJoin == false, "检查日常活动是否能参加出错")
    return bIsCanJoin, not bIsCanJoin and "未能参加该活动，不能归队"
end


function Network.RpcSrv2Srv.ReturnTeamJoinPVEActCheckReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    local bCanJoin = goPVEActivityMgr:JoinActConditionCheck(oRole)
    local sReason = nil 
    -- if not bCanJoin then
    --     local nActID =  CPVEActivityMgr:GetActivityID()
    --     local tActData = ctDailyActivity[nActID]
    --     if tActData then 
    --         sReason = string.format("队长正在参与%s，您无法参与该活动，归队失败", tActData.sActivityName)
    --     else 
    --         sReason = "队长正在参与限时活动，无法归队"
    --     end
    -- end
    return bCanJoin, sReason
end

function Network.CltPBProc.ShareGameStatusReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    oRole.m_oDailyActivity:ShareGameStatusReq()
end

function Network.CltPBProc.ShareGameSuccessReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    oRole.m_oDailyActivity:ShareGameSuccessReq()
end

function Network.CltPBProc.ShareGameRewardReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    oRole.m_oDailyActivity:GetShareGameRewardReq()
end

function Network.CltPBProc.ClickCanJoinActButtonReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    --oRole.m_oDailyActivity:JoinActRecord(tData.nActID)
end


