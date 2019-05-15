--客户端->服务器
function CltPBProc.GuaJiReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goBattleDupMgr:EnterBattleDupReq(oRole, gtBattleDupType.eGuaJi)
end

function CltPBProc.GuaJiAutoBattleOperaReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    if oBattleDup and oBattleDup.SetAutoBattle then
        oBattleDup:SetAutoBattle(oRole, tData.bIsAutoBattle)
    end
end

function CltPBProc.GuaJiChalBossReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    if oBattleDup and oBattleDup.ChallengeBoss then
        oBattleDup:ChallengeBoss(oRole)
    end
end

function CltPBProc.GuaJiBattleEndNoticeReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    if oBattleDup and oBattleDup.GuaJiBattleEndNoticeReq then
        oBattleDup:GuaJiBattleEndNoticeReq(oRole)
    end
end

function CltPBProc.StartNoticReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    if oBattleDup and oBattleDup.StartNoticReq then
        oBattleDup:StartNoticReq(oRole)
    end
end

----------------------------------------------
function Srv2Srv.GuaJiReward(nSrcServer,nSrcService,nTarSession,nRoleID, tData)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole or not oRole:IsOnline() then
        return false
    end
    return oRole.m_oGuaJi:AutoReward()
end