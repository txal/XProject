function Network.CltPBProc.PVESwitchMapReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
     local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
    if oBattleDup and oBattleDup.SwitchMapReq then
    	oBattleDup:SwitchMapReq(oRole)
    end
end