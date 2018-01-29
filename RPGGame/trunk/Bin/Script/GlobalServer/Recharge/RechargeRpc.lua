------服务器内部------
function Srv2Srv.ProccessRechargeOrderRet(nSrc, nSession, sOrderID, nRechargeID)
	local oPlayer = goGPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goRecharge:OnProccessRechargeOrderRet(oPlayer, sOrderID, nRechargeID)	
end
