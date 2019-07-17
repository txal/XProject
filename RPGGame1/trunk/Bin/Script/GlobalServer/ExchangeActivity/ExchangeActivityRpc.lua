function Network.CltPBProc.ExchangeActInfoReq(nCmd, Server, Srevice, nSession)
	local oRole = goGPlayerMgr:GetRoleBySS(Server, nSession)
    if not oRole then return end
    goExchangeActivityMgr:ExchangeInfoReq(oRole)
end

function Network.CltPBProc.ExchangeReq(nCmd, Server, Srevice, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(Server, nSession)
    if not oRole then return end
    goExchangeActivityMgr:ExchangeReq(oRole, tData.nActID, tData.nExchangeID)
end

function Network.CltPBProc.ExchangeActClickReq(nCmd, Server, Srevice, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(Server, nSession)
    if not oRole then return end
    goExchangeActivityMgr:ExchangeActClickReq(oRole, tData.nActID)
end