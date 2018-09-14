------服务器内部------
function Srv2Srv.ProccessRechargeOrderReq(nSrc, nSession, sOrderID, nRechargeID)
	print("Srv2Srv.ProccessRechargeOrderReq***", nSession, sOrderID, nRechargeID)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer.m_oVIP:OnProcessRechargeOrderReq(sOrderID, nRechargeID)
end 
