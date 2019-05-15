--竞技场
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


--请求玩家竞技场数据
function CltPBProc.ArenaRoleInfoReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
	goArenaMgr:GetRoleArenaDataReq(oRole)
end

--请求竞技场排行榜数据
function CltPBProc.ArenaRankDataReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
	goArenaMgr:SyncRankData(oRole, tData.nPageNum)
end

--请求刷新匹配玩家
function CltPBProc.ArenaFlushMatchReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
	goArenaMgr:FlushMatchReq(oRole)
end

--请求战斗
function CltPBProc.ArenaBattleReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
	goArenaMgr:BattleReq(oRole, tData.nEnemyID)
end

--领取竞技场奖励请求
function CltPBProc.ArenaRewardReceiveReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goArenaMgr:GetArenaReward(oRole, tData.nRewardType)
end

--元宝购买竞技场挑战次数
function CltPBProc.ArenaAddChallengeReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goArenaMgr:PurchaseChallengeReq(oRole, tData.nAddNum)
end


------------------ Svr2Svr --------------------
function Srv2Srv.ArenaBattleEndReq(nSrcServer, nSrcService, nTarSession, nRoleID, tResult)
    --tResult { nEnemyID, nArenaSeason, bWin, ...}
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    goArenaMgr:OnRoleBattleEnd(oRole, tResult.nEnemyID, tResult.nArenaSeason, tResult.bWin)
end

--返回值bool
function Srv2Srv.ArenaAddChallPreCheckReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    return goArenaMgr:AddChallengePreCheck(oRole)
end

--返回值bool
function Srv2Srv.ArenaAddChallReq(nSrcServer, nSrcService, nTarSession, nRoleID, nNum)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    assert(nNum and type(nNum) == "number", "参数错误")
    return goArenaMgr:AddChallengeReq(oRole, nNum)
end

function Srv2Srv.JoinArenaBattleReq(nSrcServer, nSrcService, nTarSession, nRoleID, nEnemyID) 
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    goArenaMgr:BattleReq(oRole, nEnemyID)
end

