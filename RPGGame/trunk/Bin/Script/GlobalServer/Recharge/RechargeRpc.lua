function CltPBProc.ProductListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goGPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goRecharge:ProductListReq(oPlayer)
end

function CltPBProc.MakeOrderReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goGPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goRecharge:MakeOrderReq(oPlayer, tData.nRechargeID)
end


------服务器内部------
function Srv2Srv.ProccessRechargeOrderRet(nSrc, nSession, sOrderID, nRechargeID)
	local oPlayer = goGPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goRecharge:OnProccessRechargeOrderRet(oPlayer, sOrderID, nRechargeID)	
end
