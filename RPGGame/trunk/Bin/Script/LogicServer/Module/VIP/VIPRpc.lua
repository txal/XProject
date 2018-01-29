function CltPBProc.VIPAwardListReq(nCmd, nSrc, nSession, tData)     
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oVIP:VIPAwardListReq()
end

function CltPBProc.VIPAwardReq(nCmd, nSrc, nSession, tData)     
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oVIP:VIPAwardReq(tData.nVIP)
end

function CltPBProc.RechargeListReq(nCmd, nSrc, nSession, tData)     
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oVIP:RechargeListReq()
end

function CltPBProc.FirstRechargeAwardReq(nCmd, nSrc, nSession, tData)     
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oVIP:FirstRechargeAwardReq()
end


------服务器内部------
function Srv2Srv.ProccessRechargeOrderReq(nSrc, nSession, sOrderID, nRechargeID, nTime)
	print("Srv2Srv.ProccessRechargeOrderReq***", nSession, sOrderID, nRechargeID, nTime)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oVIP:OnProcessRechargeOrderReq(sOrderID, nRechargeID, nTime)
end 
