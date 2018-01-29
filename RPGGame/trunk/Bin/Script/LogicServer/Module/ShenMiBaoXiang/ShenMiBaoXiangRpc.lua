--服务器内部
function Srv2Srv.SMBXExchangeReq(nService, nSession, nType, sCDKey, tAward)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oShenMiBaoXiang:ExchangeReq(nType, sCDKey, tAward)
end
