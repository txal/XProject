-- 客户端->服务器
function CltPBProc.ShenMoZhiMatchTeamReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    if oBattleDup then
         oBattleDup:BattleDupMatchTeam(oRole)
    end
end

function CltPBProc.OpenShenMoZhiReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShenMoZhiData:OpenShenMoZhiReq(tData)
end

function CltPBProc.ShenMoZhiFightReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    local nGuanQiaID = tData.nID
    if oBattleDup and oBattleDup.ChallengeStart then
        oBattleDup:ChallengeStart(oRole,nGuanQiaID)
    end
end

function CltPBProc.ShenMoZhiStarRewardReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	oRole.m_oShenMoZhiData:ShenMoZhiStarRewardReq(tData)
end