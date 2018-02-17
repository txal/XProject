function CltPBProc.VIPAwardListReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oVIP:VIPAwardListReq()
end

function CltPBProc.VIPAwardReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oVIP:VIPAwardReq(tData.nVIP)
end

function CltPBProc.RechargeListReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oVIP:RechargeListReq()
end

function CltPBProc.FirstRechargeAwardReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oVIP:FirstRechargeAwardReq()
end


------服务器内部------
function Srv2Srv.ProccessRechargeOrderReq(nSrcServer, nSrcService, nTarSession, sOrderID, nRechargeID, nTime)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oVIP:ProcessRechargeOrderReq(sOrderID, nRechargeID, nTime)
end 
