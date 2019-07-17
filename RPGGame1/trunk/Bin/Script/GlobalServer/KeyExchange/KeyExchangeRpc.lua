--兑换码兑换
function Network.CltPBProc.KeyExchangeReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	goKeyExchange:ExchangeReq(oRole, tData.sCDKey)
end

------服务器内部------
