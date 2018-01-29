--服务器内部
function Srv2Srv.KeyExchangeReq(nService, nSession, nType, sCDKey, tAward)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oKeyExchange:KeyExchangeReq(nType, sCDKey, tAward)
end
