--客户端->服务器
function Network.CltPBProc.AttackMonsterReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    print("攻击怪物请求---------------++")
    if oBattleDup and oBattleDup.TouchMonsterReq then
        print("攻击怪物请求---------------++")
        oBattleDup:TouchMonsterReq(oRole, tData.nMonObjID)
    end
end

--玩家点击翻牌
function Network.CltPBProc.PVEClickRewardReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    if oBattleDup and oBattleDup.ClickFlopReq then
         oBattleDup:ClickFlopReq(oRole, tData.nID)
    end
end

--玩家点击创建怪物
function Network.CltPBProc.PVECreateMonsterReq(nCmd, nServer, nService, nSession, tData)
    print("玩家点击创建怪物**************")
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    if oBattleDup then
         oBattleDup:CreateMonsterReq(oRole)
    end
end


-- function Network.CltPBProc.PVEMatchTeamReq(nCmd, nServer, nService, nSession, tData)
--     local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
--     if not oRole then return end
--     local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
--     print("oBattleDup便捷组队**************", oBattleDup)
--    	--oBattleDup:MatchTeamReq(oRole,tData.nType)
-- end

--玩家点击破解机关请求
function Network.CltPBProc.PVEClickCrackOrganReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    if oBattleDup and oBattleDup.ClickCrackOrganReq then
        oBattleDup:ClickCrackOrganReq(oRole)
    end
end

--玩家点击破解机关结果返回请求
function Network.CltPBProc.PVEPinTuResuitReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    if oBattleDup and oBattleDup.PinTuResuitReq then
        oBattleDup:PinTuResuitReq(oRole, tData.nResuit)
    end
end

--------服务器内部
--进入决战九霄副本
function Network.RpcSrv2Srv.EnterBattleDupReq(nSrcServer, nSrcService, nTarSession, sTitle, sContent, tItemList, nTarRoleID)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcService, nTarSession)
	if not oRole then return end
	CJueZhanJiuXiao:EnterBattleDup(oRole)
end