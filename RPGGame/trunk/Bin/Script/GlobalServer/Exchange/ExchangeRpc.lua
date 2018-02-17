--兑换码兑换
function CltPBProc.ExchangeReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	goExchange:ExchangeReq(oRole, tData.sCDKey)
end

------服务器内部------
