--Social Relationship 玩家社会关系
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


--请求玩家结拜数据
function CltPBProc.BrotherInfoReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goBrotherRelationMgr:SyncBrotherData(oRole)
end

--结拜条件检查请求
function CltPBProc.BrotherSwearCheckReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goBrotherRelationMgr:BrotherSwearCheckReq(oRole, tData.nTarRoleID)
end

--结拜请求
function CltPBProc.BrotherSwearReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goBrotherRelationMgr:BrotherSwearReq(oRole, tData.nTarRoleID)
end

--解除结拜请求
function CltPBProc.BrotherDeleteReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goBrotherRelationMgr:DeleteBrotherReq(oRole, tData.nTarID)
end

-----------------------------------------------------------
--玩家情缘数据请求
function CltPBProc.LoverInfoReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goLoverRelationMgr:SyncLoverData(oRole)
end

--情缘条件检查请求
function CltPBProc.LoverTogetherCheckReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goLoverRelationMgr:LoverTogetherCheckReq(oRole, tData.nTarRoleID)
end

--情缘请求
function CltPBProc.LoverTogetherReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goLoverRelationMgr:BeLoverReq(oRole, tData.nTarRoleID)
end

--解除情缘请求
function CltPBProc.LoverDeleteReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goLoverRelationMgr:DeleteLoverReq(oRole, tData.nTarID)
end

-----------------------------------------------------------
--师徒关系检查请求
function CltPBProc.MentorshipCheckReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:MentorshipCheckReq(oRole, tData.nTarRoleID, tData.bTarMaster)
end

--拜师请求
function CltPBProc.MentorshipDealMasterReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:MentorshipDealMasterReq(oRole, tData.nTarRoleID)
end

--收徒请求
function CltPBProc.MentorshipDealApprentReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:MentorshipDealApprentReq(oRole, tData.nTarRoleID)
end

--开除徒弟请求
function CltPBProc.DeleteApprenticeReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:DeleteApprenticeReq(oRole, tData.nRoleID)
end

--叛离师父请求
function CltPBProc.DeleteMasterReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:DeleteMasterReq(oRole)
end

--徒弟晋级(出师)检查请求
function CltPBProc.MentorshipUpgradeCheckReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:UpgradeCheckReq(oRole)
end

--徒弟晋级(出师)请求
function CltPBProc.MentorshipUpgradeReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:UpgradeReq(oRole)
end

--玩家师徒数据请求
function CltPBProc.MentorshipInfoReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:SyncRoleMentorshipData(oRole:GetID())
end

--获取师徒任务信息列表请求
function CltPBProc.MentorshipTaskDataListReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:SyncMentorshipTaskData(oRole:GetID())
end

--刷新师徒任务请求
function CltPBProc.MentorshipFlushTaskReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:FlushApprenticeTaskReq(oRole, tData.nRoleID)
end

--发布师徒任务请求
function CltPBProc.MentorshipTaskPublishReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:PublishApprenticeTaskReq(oRole, tData.nRoleID)
end

--接取师徒任务请求
function CltPBProc.MentorshipTaskAcceptReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:AcceptTaskReq(oRole, tData.nTaskID)
end

--师徒任务战斗请求
function CltPBProc.MentorshipTaskBattleReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:TaskBattleReq(oRole)
end

--徒弟领取任务奖励请求
function CltPBProc.MentorshipTaskRewardReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:ReceiveTaskRewardReq(oRole, tData.nTaskID)
end

--师父领取任务奖励请求
function CltPBProc.MentorshiTaskMasterRewardReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:ReceiveTaskMasterRewardReq(oRole, tData.nRoleID, tData.nTaskID)
end

--徒弟领取活跃度奖励请求
function CltPBProc.MentorshipActiveRewardReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:GetApprenticeActiveReward(oRole, tData.nConfID)
end

--师父领取活跃度奖励请求
function CltPBProc.MentorshipMasterActiveRewardReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:GetMasterActiveReward(oRole, tData.nRoleID, tData.nConfID)
end

--给师父请安请求
function CltPBProc.MentorshipGreetMasterReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:GreetMasterReq(oRole, tData.bOffline)
end

--指点徒弟请求
function CltPBProc.MentorshipTeachApprenticeReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:TeachApprenticeReq(oRole, tData.nTarID)
end

--指点徒弟请求
function CltPBProc.MentorshipPublishTaskRemindReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMentorshipMgr:PublishTaskRemindReq(oRole)
end

-----------------------------------------------------------
--有缘简要数据请求
function CltPBProc.BriefRelationshipDataReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    local nRoleID = oRole:GetID()
    local tMsg = {}
    --婚姻简要数据
    local tMarriageData = {}
    local oCouple = goMarriageMgr:GetCoupleByRoleID(nRoleID)
    if oCouple then 
        local nSpouseID = oCouple:GetSpouseID(nRoleID)
        assert(nSpouseID)
        local oSpouseRole = goGPlayerMgr:GetRoleByID(nSpouseID)
        if oSpouseRole then 
            tMarriageData.sSpouseName = oSpouseRole:GetName()
        end
    end
    tMsg.tMarriage = tMarriageData
    --师徒简要数据
    local tMentorshipData = {}
    local oRoleMentData = goMentorshipMgr:GetRoleMentorship(nRoleID)
    assert(oRoleMentData)
    local oMaster = oRoleMentData:GetMaster()
    if oMaster then 
        local oMasterRole = goGPlayerMgr:GetRoleByID(oMaster:GetID())
        if oMasterRole then
            tMentorshipData.sMasterName = oMasterRole:GetName()
        end
    end
    tMentorshipData.nApprenticeNum = oRoleMentData:GetFreshApprenticeCount()
    tMsg.tMentorship = tMentorshipData
    --结拜简要数据
    local tBrotherData = {}
    tBrotherData.tBrotherName = {}
    local oRoleBrother = goBrotherRelationMgr:GetRoleBrotherData(nRoleID)
    assert(oRoleBrother)
    local tBrotherList = oRoleBrother:GetBrotherList()
    if next(tBrotherList) then 
        for k, v in ipairs(tBrotherList) do 
            local nTempID = v:GetBrotherID()
            local oTempRole = goGPlayerMgr:GetRoleByID(nTempID)
            if oTempRole then 
                table.insert(tBrotherData.tBrotherName, oTempRole:GetName())
            end
        end
    end
    tMsg.tBrother = tBrotherData
    --情缘简要数据
    local tLoverData = {}
    tLoverData.tLoverName = {}
    local oRoleLover = goLoverRelationMgr:GetRoleLoverData(nRoleID)
    assert(oRoleLover)
    local tLoverList = oRoleLover:GetLoverList()
    if next(tLoverList) then 
        for k, v in ipairs(tLoverList) do 
            local nTempID = v:GetLoverID()
            local oTempRole = goGPlayerMgr:GetRoleByID(nTempID)
            if oTempRole then 
                table.insert(tLoverData.tLoverName, oTempRole:GetName())
            end
        end
    end
    tMsg.tLover = tLoverData

    oRole:SendMsg("BriefRelationshipDataRet", tMsg)
end

--玩家关系招募喊话请求
function CltPBProc.RoleRelationshipInviteTalkReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    if not tData or not tData.nType then 
        return oRole:Tips("参数错误") 
    end
    local nType = tData.nType
    if nType == 1 then 
        goMarriageMgr:InviteTalkReq(oRole)
    elseif nType == 2 then 
        goBrotherRelationMgr:InviteTalkReq(oRole)
    elseif nType == 3 then 
        goLoverRelationMgr:InviteTalkReq(oRole)
    elseif nType == 4 then 
        goMentorshipMgr:MasterInviteTalkReq(oRole)
    elseif nType == 5 then 
        goMentorshipMgr:ApprenticeInviteTalkReq(oRole)
    else
        return oRole:Tips("参数错误")
    end
end

------------------ Svr2Svr --------------------
function Srv2Srv.MentorshipTaskBattleEndReq(nSrcServer, nSrcService, nTarSession, nRoleID, tData)
    --tData { nTaskID = , bWin = }
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    goMentorshipMgr:OnTaskBattleEnd(oRole, tData.nTaskID, tData.bWin, tData.nTimeStamp)
end

--同步结拜数据到逻辑服
function Srv2Srv.SyncBrotherCacheReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    goBrotherRelationMgr:SyncLogicCache(nRoleID, nSrcServer, nSrcService, nTarSession)
end

--同步情缘数据到逻辑服
function Srv2Srv.SyncLoverCacheReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    goLoverRelationMgr:SyncLogicCache(nRoleID, nSrcServer, nSrcService, nTarSession)
end

--同步师徒数据到逻辑服
function Srv2Srv.SyncMentorshipCacheReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    goMentorshipMgr:SyncLogicCache(nRoleID, nSrcServer, nSrcService, nTarSession)
end



